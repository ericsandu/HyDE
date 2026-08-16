#!/usr/bin/env bash
# The fork's wrapper has to keep Configs/ and Scripts/ byte-identical to
# upstream, so every behavioural difference is applied to the working tree
# at run time and reverted afterwards. This case runs the wrapper against a
# throwaway clone and home to check the whole contract:
#
#   - the manifests deez is handed carry the fork patches (fork git urls,
#     skipped tarball sections, injected and blacklisted packages,
#     clean_target gone, grimblast post-command, --deploy all)
#   - the clone is left clean afterwards
#   - the destructive steps stay inside the sandbox: user files under
#     .local survive, nvim survives the config cleanup, the sudo log shows
#     no removals
#   - the Custom overlay lands on top and the fixed-size wallbash icon
#     hooks are dropped from the deployed home
#   - the standard rofi theme lookup path points at the deployed themes
#
# The deployer is always a stub here on purpose: the real deez cannot be
# isolated with HOME/XDG environment overrides. It resolves the XDG roots
# from /etc/passwd and uninstalls whatever its registry points at, so a
# "sandboxed" run against a live machine both writes outside the sandbox
# and deletes registry paths. Only OS-level isolation (a throwaway user)
# can safely run the real deployer.

_failures=0

fail() {
    _failures=$((_failures + 1))
    printf '    fail: %s\n' "$1"
}

finish() {
    if [ "$_failures" -ne 0 ]; then
        printf '    %d failure(s)\n' "$_failures"
        exit 1
    fi
    exit 0
}

TESTS_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=${REPO_ROOT:-$(CDPATH='' cd -- "$TESTS_DIR/../.." && pwd)}

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

repo_dir="$work_dir/repo"
home_dir="$work_dir/home"
stub_dir="$work_dir/stubs"
snaps_dir="$work_dir/snaps"
mkdir -p "$repo_dir" "$home_dir" "$stub_dir" "$snaps_dir"

git clone -q "$REPO_ROOT" "$repo_dir" || fail "could not clone the checkout"

# ---- the fake home: what a long-lived install looks like ---------------

# Files the deploy must never cost the user.
mkdir -p "$home_dir/.local/lib/hyde" "$home_dir/.local/share/wallpapers/mytrip"
printf '#!/usr/bin/env sh\n' >"$home_dir/.local/lib/hyde/my_custom_script.sh"
printf 'fake\n' >"$home_dir/.local/share/wallpapers/mytrip/photo.png"
mkdir -p "$home_dir/.config/nvim"
printf 'vim config\n' >"$home_dir/.config/nvim/init.lua"

# Files the wrapper is expected to replace or remove.
mkdir -p "$home_dir/.config/hypr"
printf 'stale\n' >"$home_dir/.config/hypr/hyprland.lua"
printf 'stale\n' >"$home_dir/.config/hypr/OLDFILE"
mkdir -p "$home_dir/.local/share/wallbash/always/00-icons"
printf 'height="120px"\n' >"$home_dir/.local/share/wallbash/always/00-icons/vol-50.dcol"

# State the seed step must not overwrite.
mkdir -p "$home_dir/.local/state/hyde"
printf 'WAYBAR_LAYOUT_NAME=mine\n' >"$home_dir/.local/state/hyde/staterc"

# ---- stubs: everything the wrapper and installer reach for -------------

write_stub() {
    {
        printf '#!/usr/bin/env sh\n'
        printf 'printf "%%s\\n" "$*" >>"%s"\n' "$stub_dir/$1.log"
        printf 'exit 0\n'
    } >"$stub_dir/$1"
    chmod +x "$stub_dir/$1"
}
for cmd in sudo yay paru xdg-mime waybar.py hyprctl systemctl fc-cache luarocks; do
    write_stub "$cmd"
done

# The package sorter asks pacman which repo a package is in.
{
    printf '#!/usr/bin/env sh\n'
    printf 'case "$1" in -Si) case "$2" in\n'
    printf 'thunar|gvfs|tumbler|neovim|file-roller|zathura|zathura-pdf-poppler|bat|fd|mpv|yt-dlp|imv|btop|vim|ttf-*)\n'
    printf '    echo "Repository      : extra" ; exit 0 ;;\n'
    printf 'esac ;; esac\n'
    printf 'printf "%%s\\n" "pacman $*" >>"%s"\n' "$stub_dir/pacman.log"
    printf 'exit 0\n'
} >"$stub_dir/pacman"
chmod +x "$stub_dir/pacman"

# The deployer records its arguments and snapshots every manifest it was
# handed, so the case can inspect the patched state itself saw.
deez_exe="$home_dir/.local/state/hyde/python_env/bin/deez"
mkdir -p "$(dirname "$deez_exe")"
{
    printf '#!/usr/bin/env sh\n'
    printf 'n=$(ls "%s" 2>/dev/null | wc -l)\n' "$snaps_dir"
    printf 'd="%s/$n"; mkdir -p "$d"\n' "$snaps_dir"
    printf 'cp -r "%s/Scripts/dots" "%s/Scripts/dots-groups" "%s/Scripts/install.sh" "$d/" 2>/dev/null\n' \
        "$repo_dir" "$repo_dir" "$repo_dir"
    printf 'printf "%%s\\n" "$*" >>"%s"\n' "$stub_dir/deez.log"
    printf 'exit 0\n'
} >"$deez_exe"
chmod +x "$deez_exe"
ln -sf "$(command -v python3)" "$(dirname "$deez_exe")/python"

# The installer's own neighbours are stubs, as in tests/test_install_restore.sh.
for stub in install_pre install_aur install_pst restore_thm restore_svc; do
    printf '#!/usr/bin/env sh\nexit 0\n' >"$repo_dir/Scripts/$stub.sh"
    chmod +x "$repo_dir/Scripts/$stub.sh"
done
rm -f "$repo_dir/Scripts/migrations"/*.sh
printf '#!/usr/bin/env sh\nexit 0\n' >"$repo_dir/Scripts/migrations/v99.9.9.sh"
chmod +x "$repo_dir/Scripts/migrations/v99.9.9.sh"
mkdir -p "$repo_dir/Configs/.local/lib/hyde/pyutils"
printf 'import sys\nsys.exit(0)\n' >"$repo_dir/Configs/.local/lib/hyde/pyutils/lua_env.py"
printf 'import sys\nsys.exit(0)\n' >"$repo_dir/Configs/.local/lib/hyde/pyutils/python_env.py"

# Helpers the restore calls directly in the home it is restoring.
mkdir -p "$home_dir/.local/lib/hyde/wallpaper"
for helper in "wallpaper/cache.sh" "theme.switch.sh" "waybar.py"; do
    printf '#!/usr/bin/env sh\nexit 0\n' >"$home_dir/.local/lib/hyde/$helper"
    chmod +x "$home_dir/.local/lib/hyde/$helper"
done

run_wrapper() {
    : >"$stub_dir/sudo.log"
    : >"$stub_dir/pacman.log"
    : >"$stub_dir/deez.log"
    rm -rf "$work_dir/state" "$work_dir/cache"
    (
        cd "$repo_dir" &&
            PATH="$stub_dir:$PATH" &&
            export PATH &&
            env -u HYPRLAND_INSTANCE_SIGNATURE \
                HOME="$home_dir" \
                XDG_STATE_HOME="$work_dir/state" \
                XDG_CACHE_HOME="$work_dir/cache" \
                CLONE_DIR="$repo_dir" \
                ./install_custom.sh "$@" <<<"n
n
n
n"
    ) >"$work_dir/out.log" 2>&1
}

# ---- the run ------------------------------------------------------------

run_wrapper -r -s
status=$?

[ "$status" -eq 0 ] || fail "the wrapper exited with $status: $(tail -n 5 "$work_dir/out.log")"

# The clone is left as it was found, modulo the stubs this case installed
# next to the installer.
git -C "$repo_dir" diff --quiet -- Scripts/dots Scripts/dots-groups Scripts/install.sh ||
    fail "the wrapper left the manifests or installer modified:
$(git -C "$repo_dir" status --porcelain -- Scripts/dots Scripts/dots-groups Scripts/install.sh)"

# The deployer ran with the patched, non-interactive invocations.
grep -q 'dots-groups/core.toml.*--deploy all' "$stub_dir/deez.log" ||
    fail "the core dots were not deployed wholesale"
grep -q 'dots-groups/extra.toml.*--deploy all' "$stub_dir/deez.log" ||
    fail "the extra dots were not deployed wholesale (install.sh patch did not apply)"

# What the deployer was handed: the fork patches, all present at once.
snap=$(ls "$snaps_dir" | sort -n | tail -1)
snap="$snaps_dir/$snap"
grep -q '^\[icon-wallbash\]$' "$snap/dots/archives.toml" ||
    fail "the icon theme archive was filtered out"
! grep -qE '^\[(font|cursor|hyprcursor)-' "$snap/dots/archives.toml" ||
    fail "font or cursor tarball sections reached the deployer"
grep -q 'github.com/ericsandu/HyDE.git' "$snap/dots-groups/extra.toml" ||
    fail "the extra group still points at upstream"
! grep -q 'dots/dolphin.toml' "$snap/dots-groups/extra.toml" ||
    fail "the dolphin dot group was deployed"
grep -q '"xsettingsd", "dconf"' "$snap/dots/hyde.toml" ||
    fail "the dconf profile was not deployed"
! grep -q 'clean_target' "$snap/dots/hyde.toml" ||
    fail "clean_target survived: a deploy would wipe user files under .local"
grep -q "slurp -o" "$snap/dots/hyde.toml" ||
    fail "the grimblast double-slurp patch was not applied"
grep -q '"vim"' "$snap/dots/deps.toml" ||
    fail "vim did not reach the dependency list"
grep -q '"bibata-cursor-theme-bin"' "$snap/dots/deps.toml" ||
    fail "the bibata cursor package did not reach the dependency list"
grep -q '"ttf-cascadia-code-nerd"' "$snap/dots/deps.toml" ||
    fail "the caskaydia font package did not reach the dependency list"
! grep -qE '^\s*(pacman|yay|paru|dnf) *= *\[[^]]*"(firefox|ark)"' "$snap/dots/deps.toml" ||
    fail "a blacklisted package reached the dependency list"
grep -q -- '--deploy all' "$snap/install.sh" ||
    fail "the installer snapshot does not carry the wholesale extra deploy"

# The destructive steps stayed inside the sandbox home.
[ -e "$home_dir/.local/lib/hyde/my_custom_script.sh" ] ||
    fail "a user script under .local/lib was wiped by the deploy"
[ -e "$home_dir/.local/share/wallpapers/mytrip/photo.png" ] ||
    fail "user wallpapers were wiped by the deploy"
[ -e "$home_dir/.config/nvim/init.lua" ] ||
    fail "the nvim config did not survive the pre-install cleanup"
! grep -q 'rm' "$stub_dir/sudo.log" ||
    fail "sudo was asked to remove something: $(cat "$stub_dir/sudo.log")"

# The overlay landed and took effect.
cmp -s "$home_dir/.config/hypr/hyprland.lua" "$repo_dir/Custom/dotfiles/.config/hypr/hyprland.lua" ||
    fail "the Custom hyprland config was not deployed on top"
[ ! -e "$home_dir/.config/hypr/OLDFILE" ] ||
    fail "the stale config file survived the cleanup"
[ ! -e "$home_dir/.local/share/wallbash/always/00-icons/vol-50.dcol" ] ||
    fail "the fixed-size wallbash icon hook survived"
[ "$(readlink "$home_dir/.local/share/rofi/themes")" = "$home_dir/.local/share/hyde/rofi/themes" ] ||
    fail "the rofi theme lookup path does not point at the deployed themes"
[ "$(grep -c WAYBAR_LAYOUT_NAME "$home_dir/.local/state/hyde/staterc")" -eq 1 ] ||
    fail "the state seed duplicated an existing entry"

# ---- keep-config mode leaves an existing home alone ---------------------

printf 'stale\n' >"$home_dir/.config/hypr/hyprland.lua"
run_wrapper -i -r -s
status=$?

[ "$status" -eq 0 ] || fail "keep-config mode exited with $status: $(tail -n 5 "$work_dir/out.log")"
grep -q 'stale' "$home_dir/.config/hypr/hyprland.lua" ||
    fail "keep-config mode replaced an existing config"

# ---- dots-only updates go through the same patches ----------------------

mkdir -p "$home_dir/.local/share/wallbash/always/00-icons"
printf 'height="120px"\n' >"$home_dir/.local/share/wallbash/always/00-icons/vol-50.dcol"
run_wrapper --dots
status=$?

[ "$status" -eq 0 ] || fail "dots-only mode exited with $status: $(tail -n 5 "$work_dir/out.log")"
grep -q 'dots-groups/core.toml.*--deploy all' "$stub_dir/deez.log" ||
    fail "dots-only mode stopped deploying the core dots"
git -C "$repo_dir" diff --quiet -- Scripts/dots Scripts/dots-groups Scripts/install.sh ||
    fail "dots-only mode left the manifests modified"
cmp -s "$home_dir/.config/hypr/hyprland.lua" "$repo_dir/Custom/dotfiles/.config/hypr/hyprland.lua" ||
    fail "dots-only mode did not redeploy the Custom overlay"
[ ! -e "$home_dir/.local/share/wallbash/always/00-icons/vol-50.dcol" ] ||
    fail "dots-only mode left the fixed-size icon hook in place"
[ "$(readlink "$home_dir/.local/share/rofi/themes")" = "$home_dir/.local/share/hyde/rofi/themes" ] ||
    fail "dots-only mode lost the rofi theme lookup link"

finish
