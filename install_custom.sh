#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")

# Stage package blacklist
cp -f "${scrDir}/Custom/pkg_black.lst" "${scrDir}/Scripts/pkg_black.lst"

# Run main HyDE installer with custom packages
"${scrDir}/Scripts/install.sh" "$@" "${scrDir}/Custom/pkg_custom.lst"

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

# Deploy custom dotfiles
if [ -d "${scrDir}/Custom/dotfiles/.config" ]; then
  mkdir -p "${HOME}/.config"
  cp -rf "${scrDir}/Custom/dotfiles/.config"/* "${HOME}/.config/"
fi
if [ -d "${scrDir}/Custom/dotfiles/.local" ]; then
  mkdir -p "${HOME}/.local"
  cp -rf "${scrDir}/Custom/dotfiles/.local"/* "${HOME}/.local/"
fi

# Install custom Neovim configuration
NVIM_CUSTOM_REPO=${NVIM_CUSTOM_REPO:-"https://github.com/ericsandu/lazyvim"}
if [ -n "${NVIM_CUSTOM_REPO}" ]; then
  if [ -d "${HOME}/.config/nvim" ] && [ "$(ls -A "${HOME}/.config/nvim" 2>/dev/null)" ]; then
    read -p ":: Directory ~/.config/nvim is not empty. Remove contents and install custom Neovim configuration? [y/N]: " nvim_confirm
    nvim_confirm=${nvim_confirm:-N}
  else
    nvim_confirm="Y"
  fi

  if [[ "$nvim_confirm" =~ ^[Yy]$ ]]; then
    echo ":: Installing custom Neovim configuration..."
    rm -rf "${HOME}/.config/nvim"
    git clone "${NVIM_CUSTOM_REPO}" "${HOME}/.config/nvim"
  else
    echo ":: Skipping custom Neovim configuration."
  fi
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
