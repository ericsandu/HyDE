#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")

# Prompt for power management
read -p "Do you want to install and configure TLP for maximum power savings? (Useful for laptops) [y/N]: " install_tlp
install_tlp=${install_tlp:-N}

# Stage package blacklist
cp -f "${scrDir}/Custom/pkg_black.lst" "${scrDir}/Scripts/pkg_black.lst"

# Run main HyDE installer with custom packages
"${scrDir}/Scripts/install.sh" "$@" "${scrDir}/Custom/pkg_custom.lst"

# Set Thunar as default file manager
if command -v xdg-mime >/dev/null 2>&1; then
  xdg-mime default thunar.desktop inode/directory
fi

# Install custom Neovim configuration
NVIM_CONFIG_REPO="https://github.com/ericsandu/lazyvim"
if [ -n "${NVIM_CONFIG_REPO}" ]; then
  rm -rf "${HOME}/.config/nvim"
  git clone "${NVIM_CONFIG_REPO}" "${HOME}/.config/nvim"
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
if [ -f "${scrDir}/Custom/dotfiles/.gtkrc-2.0" ]; then
  cp -f "${scrDir}/Custom/dotfiles/.gtkrc-2.0" "${HOME}/.gtkrc-2.0"
fi
if [ -f "${scrDir}/Custom/dotfiles/.zshenv" ]; then
  cp -f "${scrDir}/Custom/dotfiles/.zshenv" "${HOME}/.zshenv"
fi

# Compile Waybar custom configuration
if command -v waybar.py >/dev/null 2>&1; then
  waybar.py --update || true
elif [ -f "${HOME}/.local/lib/hyde/waybar.py" ]; then
  "${HOME}/.local/lib/hyde/waybar.py" --update || true
fi

# Deploy TLP if requested
if [[ "$install_tlp" =~ ^[Yy]$ ]]; then
  echo ":: Installing and configuring TLP for power management..."
  yay -S --noconfirm tlp
  if [ -f "${scrDir}/Custom/tlp.conf" ]; then
    sudo mkdir -p /etc/tlp.d
    sudo cp -f "${scrDir}/Custom/tlp.conf" /etc/tlp.d/99-custom.conf
  fi
  sudo systemctl enable tlp.service
  sudo tlp start || true
fi
