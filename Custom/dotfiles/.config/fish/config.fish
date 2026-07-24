# All User Configs goes here

# Environment Variables
set -gx CFLAGS "-g -O2 -march=native -pipe"
set -gx CXXFLAGS "-g -O2 -march=native -pipe"
set -gx EDITOR nvim
set -gx CUPS_SERVER "192.168.1.32:631"
set -gx GAMEID 0
set -gx PROTONPATH "$HOME/.steam/steam/compatibilitytools.d/GE-Proton10-28/"
set -gx WINEPREFIX "$HOME/.wine"

# Path additions
fish_add_path ~/wine-ge/bin
fish_add_path ~/.local/bin
fish_add_path ~/.local/share/bin

set -gx ZEPHYR_SDK_INSTALL_DIR "/opt/zephyr-sdk-1.0.1"
set -gx ZEPHYR_TOOLCHAIN_VARIANT zephyr

# Aliases
# (Note: standard list directory and navigate aliases are already in hyde.fish)
alias pc='yay -Sc'
alias po='yay -Qtdq | yay -Rns -'
alias ssh='kitten ssh'
alias nf='fastfetch'
alias neofetch='fastfetch'

# Shell Enhancements
# Enable Fish Vi Mode (equivalent to zsh-vi-mode plugin)
fish_vi_key_bindings

# Startup command integrations
if type -q thefuck
    thefuck --alias | source
end
