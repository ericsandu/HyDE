#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")

# Dynamically strip blacklisted packages and inject custom packages into TOML manifests
if [ -s "${scrDir}/Custom/pkg_black.lst" ]; then
  echo ":: Patching upstream manifests to exclude blacklisted packages..."
  grep -vE '^\s*#|^\s*$' "${scrDir}/Custom/pkg_black.lst" | awk '{print $1}' | while read -r pkg_name; do
    sed -i -E "/[\"']${pkg_name}[\"']/d" "${scrDir}/Scripts/dots/"*.toml
  done
fi

if [ -s "${scrDir}/Custom/pkg_custom.lst" ]; then
  echo ":: Patching upstream manifests to include custom packages..."
  pacman_pkgs=""
  yay_pkgs=""
  while read -r pkg_name; do
    repo=$(pacman -Si "$pkg_name" 2>/dev/null | grep -i "^Repository" | awk -F': ' '{print $2}' | tr -d ' ' | tr -d '\r')
    if [ -z "$repo" ] || [ "$repo" = "chaotic-aur" ]; then
      yay_pkgs="${yay_pkgs}\"${pkg_name}\", "
    else
      pacman_pkgs="${pacman_pkgs}\"${pkg_name}\", "
    fi
  done < <(grep -vE '^\s*#|^\s*$' "${scrDir}/Custom/pkg_custom.lst" | awk '{print $1}')
  
  cat <<EOF >> "${scrDir}/Scripts/dots/deps.toml"

[[global.dependency]]
pacman = [ ${pacman_pkgs} ]
yay = [ ${yay_pkgs} ]
paru = [ ${yay_pkgs} ]
EOF
fi

# Run main HyDE installer
# We pre-install lua and luarocks to bypass a bug in upstream's deez installer
# where it silently swallows pacman errors, causing lua_env.py to crash later.
if ! command -v luarocks >/dev/null 2>&1; then
  echo ":: Pre-installing luarocks to prevent lua_env.py crash..."
  sudo pacman -S --needed --noconfirm lua luarocks
fi

KEEP_CONFIG=0
DOTS_ONLY=0
for arg in "$@"; do
  if [ "$arg" = "-i" ] || [ "$arg" = "--install" ]; then
    KEEP_CONFIG=1
  fi
  if [ "$arg" = "--dots" ]; then
    DOTS_ONLY=1
  fi
done

if [ $DOTS_ONLY -eq 1 ]; then
  echo ":: Updating dotfiles only..."
  python_env_dir="${HOME}/.local/state/hyde/python_env"
  deez_exe="${python_env_dir}/bin/deez"

  echo ":: Bypassing fonts and cursors..."
  sed -i 's/"..\/dots\/archives.toml",//g' "${scrDir}/Scripts/dots-groups/core.toml"

  if [ -f "${deez_exe}" ]; then
    "${deez_exe}" --source "${scrDir}" --config "${scrDir}/Scripts/dots-groups/core.toml" dots --skip-git --no-deps-checks --deploy all
    "${deez_exe}" --source "${scrDir}" --config "${scrDir}/Scripts/dots-groups/extra.toml" dots --skip-git --no-deps-checks --deploy all
  else
    echo ":: deez-dots not found. Ensure the Python environment is set up."
  fi

  git -C "${scrDir}" restore Scripts/dots-groups/core.toml 2>/dev/null || true
  if [ -d "${scrDir}/Custom/dotfiles/.config" ]; then
    cp -rf "${scrDir}/Custom/dotfiles/.config"/* "${HOME}/.config/"
  fi
  if [ -d "${scrDir}/Custom/dotfiles/.local" ]; then
    cp -rf "${scrDir}/Custom/dotfiles/.local"/* "${HOME}/.local/"
  fi
  if [ -n "$XDG_RUNTIME_DIR" ] || [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
    if command -v waybar.py >/dev/null 2>&1; then
      waybar.py --update || true
    elif [ -f "${HOME}/.local/lib/hyde/waybar.py" ]; then
      "${HOME}/.local/lib/hyde/waybar.py" --update || true
    fi
  fi
  exit 0
fi

if [ $KEEP_CONFIG -eq 0 ]; then
  echo ":: Cleaning up existing configurations before install to prevent stow conflicts..."
  if [ -d "${scrDir}/Custom/dotfiles/.config" ]; then
    find "${scrDir}/Custom/dotfiles/.config" -mindepth 1 -maxdepth 1 -printf "%f\n" 2>/dev/null | while read -r f; do
      if [ "$f" = "nvim" ]; then
        echo ":: Skipping cleanup for nvim to preserve user configuration..."
        continue
      fi
      rm -rf "${HOME}/.config/$f"
    done
  fi
  # We intentionally DO NOT clean up ~/.local here to avoid catastrophically deleting ~/.local/share, ~/.local/lib, etc.
  # The final cp -rf will safely overwrite the necessary files in ~/.local without breaking the system.
else
  echo ":: Keep configs flag passed. Skipping pre-install cleanup of existing dotfiles."
fi

"${scrDir}/Scripts/install.sh" "$@"
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo ":: Installer failed with exit code $EXIT_CODE. Aborting."
  git -C "${scrDir}" restore Scripts/dots/*.toml 2>/dev/null || true
  exit $EXIT_CODE
fi

# Restore the TOML manifests to their original state to keep the git tree clean
git -C "${scrDir}" restore Scripts/dots/*.toml 2>/dev/null || true


# Set Thunar as default file manager
if command -v xdg-mime >/dev/null 2>&1; then
  xdg-mime default thunar.desktop inode/directory
fi

# Deploy TLP if requested
read -p ":: Do you want to install and configure TLP for maximum power savings? (Useful for laptops) [y/N]: " install_tlp
install_tlp=${install_tlp:-N}

if [[ "$install_tlp" =~ ^[Yy]$ ]]; then
  echo ":: Installing and configuring TLP for power management..."
  yay -S --noconfirm tlp
  if [ -f "${scrDir}/Custom/tlp.conf" ]; then
    sudo mkdir -p /etc/tlp.d
    sudo cp -f "${scrDir}/Custom/tlp.conf" /etc/tlp.d/99-custom.conf
  fi
  if ! sudo systemctl enable tlp.service 2>/dev/null; then
    echo ":: Warning: DBUS/systemctl unavailable. The script will continue."
    echo ":: ACTION REQUIRED: Please run 'sudo systemctl enable --now tlp.service' manually after rebooting."
  else
    sudo tlp start || echo ":: Warning: Failed to start TLP immediately. It will start on next boot."
  fi
else
  echo ":: Skipping TLP power management installation."
fi

# Install custom Neovim configuration
NVIM_CUSTOM_REPO=${NVIM_CUSTOM_REPO:-"https://github.com/ericsandu/lazyvim"}
if [ -n "${NVIM_CUSTOM_REPO}" ]; then
  if [ -e "${HOME}/.config/nvim" ]; then
    read -p ":: Path ~/.config/nvim already exists. Remove contents and install custom Neovim configuration? [y/N]: " nvim_confirm
  else
    read -p ":: Do you want to install the custom Neovim configuration? [y/N]: " nvim_confirm
  fi
  nvim_confirm=${nvim_confirm:-N}

  if [[ "$nvim_confirm" =~ ^[Yy]$ ]]; then
    echo ":: Installing custom Neovim configuration..."
    rm -rf "${HOME}/.config/nvim"
    git clone "${NVIM_CUSTOM_REPO}" "${HOME}/.config/nvim"
    # Ensure the directories exists for Wallbash to generate colorschemes
    mkdir -p "${HOME}/.config/nvim/colors"
    mkdir -p "${HOME}/.config/nvim/lua/lualine/themes/"
  else
    echo ":: Skipping custom Neovim configuration."
  fi
fi

# Flush stale wallbash caches to force regeneration with current templates
echo ":: Flushing wallbash theme caches..."
rm -rf "${HOME}/.cache/hyde/wallbash"

# Cleanup legacy HyDE configs to prevent conflicts with the new Lua engine
read -p ":: Do you want to clean up legacy HyDE v1 configuration files? (Recommended if upgrading to the new Lua engine) [Y/n]: " clean_legacy
clean_legacy=${clean_legacy:-Y}

if [[ "$clean_legacy" =~ ^[Yy]$ ]]; then
  echo ":: Cleaning up legacy .conf files and bash scripts..."
  # Remove deprecated hyprland conf overrides (now handled in Lua)
  rm -f "${HOME}/.config/hypr/userprefs.conf"
  rm -f "${HOME}/.config/hypr/windowrules.conf"
  rm -f "${HOME}/.config/hypr/keybindings.conf"
  rm -f "${HOME}/.config/hypr/animations.conf"
  rm -f "${HOME}/.config/hypr/monitors.conf"
  
  # Upstream replaced hyprland.conf with hyprland.lua
  rm -f "${HOME}/.config/hypr/hyprland.conf"
  
  # Remove deprecated legacy scripts (like shaders.sh) to prevent stow conflicts
  rm -f "${HOME}/.local/lib/hyde/shaders.sh"
  
  # Remove legacy global icon/cursor themes that crash the V2 installer
  [ -d "/usr/local/share/icons/Bibata-Modern-Ice" ] && sudo rm -rf /usr/local/share/icons/Bibata-Modern-Ice 2>/dev/null || true
  
  echo ":: Legacy configurations removed."
fi

if [ $KEEP_CONFIG -eq 0 ]; then
  echo ":: Deploying custom dotfiles..."
  if [ -d "${scrDir}/Custom/dotfiles/.config" ]; then
    mkdir -p "${HOME}/.config"
    cp -rf "${scrDir}/Custom/dotfiles/.config"/* "${HOME}/.config/"
  fi
  if [ -d "${scrDir}/Custom/dotfiles/.local" ]; then
    mkdir -p "${HOME}/.local"
    cp -rf "${scrDir}/Custom/dotfiles/.local"/* "${HOME}/.local/"
  fi
  # Create blank stubs for files sourced by configs (prevents globbing errors if upstream hasn't deployed them)
  touch "${HOME}/.config/hypr/workflows.conf"
  mkdir -p "${HOME}/.local/share/hypr"
  [ -f "${HOME}/.local/share/hypr/hyprlock.conf" ] || touch "${HOME}/.local/share/hypr/hyprlock.conf"

  # Seed HyDE state with our preferred defaults
  mkdir -p "${HOME}/.local/state/hyde"
  STATE_FILE="${HOME}/.local/state/hyde/staterc"
  # Only seed values that aren't already set (don't overwrite on re-installs)
  grep -q "WAYBAR_LAYOUT_NAME" "$STATE_FILE" 2>/dev/null || {
    echo 'WAYBAR_LAYOUT_PATH='"${HOME}"'/.local/share/waybar/layouts/mine.jsonc' >> "$STATE_FILE"
    echo 'WAYBAR_LAYOUT_NAME=mine' >> "$STATE_FILE"
  }
  grep -q "WAYBAR_STYLE_PATH" "$STATE_FILE" 2>/dev/null || {
    echo 'WAYBAR_STYLE_PATH='"${HOME}"'/.local/share/waybar/styles/defaults.css' >> "$STATE_FILE"
  }
else
  echo ":: Keep configs flag passed. Skipping custom dotfile deployment to preserve personal configurations."
fi


# Compile Waybar custom configuration
# We check for DBus/XDG_RUNTIME_DIR to prevent the script from hanging or crashing
# when waybar.py tries to connect to the user session bus during an offline install.
if [ -n "$XDG_RUNTIME_DIR" ] || [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
  if command -v waybar.py >/dev/null 2>&1; then
    waybar.py --update || true
  elif [ -f "${HOME}/.local/lib/hyde/waybar.py" ]; then
    "${HOME}/.local/lib/hyde/waybar.py" --update || true
  fi
else
  echo ":: DBUS not active. Skipping Waybar live update (will run on next boot)."
fi

