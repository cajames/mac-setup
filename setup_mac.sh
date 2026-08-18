#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

append_once() {
  local line="$1"
  local file="$2"

  touch "$file"
  grep -Fqx "$line" "$file" || printf '%s\n' "$line" >>"$file"
}

install_cask() {
  local cask="$1"
  shift

  if brew list --cask "$cask" &>/dev/null; then
    echo "Skipping $cask: already installed by Homebrew."
    return
  fi

  local app
  local applications_dir
  for app in "$@"; do
    for applications_dir in "/Applications" "$HOME/Applications"; do
      if compgen -G "$applications_dir/$app" >/dev/null; then
        echo "Skipping $cask: $app already exists."
        return
      fi
    done
  done

  brew install --cask "$cask"
}

link_dotfile() {
  local relative_path="$1"
  local source="$SCRIPT_DIR/dotfiles/$relative_path"
  local target="$HOME/$relative_path"

  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    echo "Skipping $relative_path: already linked."
    return
  fi
  if [[ -e "$target" || -L "$target" ]]; then
    echo "Skipping $relative_path: target already exists."
    return
  fi

  ln -s "$source" "$target"
}

install_dotfiles() {
  link_dotfile ".aerospace.toml"
  link_dotfile ".zshrc"
  link_dotfile ".config/git/ignore"
  link_dotfile ".config/nvim"
  link_dotfile ".config/sketchybar"
  link_dotfile ".config/starship.toml"
  link_dotfile ".config/zed"
}

create_local_zshrc() {
  local target="$HOME/.zshrc.local"

  if [[ -e "$target" || -L "$target" ]]; then
    echo "Skipping .zshrc.local: already exists."
    return
  fi

  cp "$SCRIPT_DIR/dotfiles/.zshrc.local.example" "$target"
  chmod 600 "$target"
}

install_dotfiles
create_local_zshrc

# Script to setup a new Mac

# Fix up the key repeat issues on MacOS Sierra. Need the key repeats for VIM!
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Finder should show dotfiles but hide all Desktop icons
defaults write com.apple.finder AppleShowAllFiles YES
defaults write com.apple.finder CreateDesktop -bool false
killall Finder 2>/dev/null || true

# Disable default Mac behaviour to reopen everything on startup from previous shut down.
defaults write -g ApplePersistence -bool FALSE
defaults write com.apple.dock show-recents -bool FALSE

# Defaults Mojave Dark Mode
# defaults write -g AppleInterfaceStyle Dark;

# Auto-hide the dock.
defaults write com.apple.dock autohide -float 1
defaults write com.apple.dock autohide-time-modifier -float 1
# Only show active programs in the dock. Nothing else.
defaults write com.apple.dock static-only -bool TRUE
# Reset Dock
killall Dock 2>/dev/null || true

# Install Brew
if [[ ! -x /opt/homebrew/bin/brew ]]; then
  sudo -v
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
append_once 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile"
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install and change to ZSH before writing ~/.zshrc
brew install zsh zsh-completions
if [[ "$SHELL" != "/bin/zsh" ]]; then
  chsh -s /bin/zsh
fi
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Gotta go
brew install go

# Node + NPM + PNPM.. Cuz Node.
brew install npm
brew install pnpm
brew install n
brew install oven-sh/bun/bun

# Install additional development runtimes and tools
brew install chruby ruby-install postgresql@17 tfenv opencode
if [[ ! -x "$HOME/.rubies/ruby-3.4.4/bin/ruby" ]]; then
  ruby-install ruby 3.4.4
fi

# Run Github Commands from Terminal
brew install gh

# Install Neovim; its config is included in this repository
brew install neovim
append_once "export EDITOR='nvim'" "$HOME/.zshrc"
append_once "alias nv='nvim'" "$HOME/.zshrc"
brew install ripgrep
brew install fzf
brew install fd
brew install zoxide
brew install eza

# Install window management UI used by AeroSpace config
brew tap FelixKratz/formulae
brew install FelixKratz/formulae/sketchybar
brew install FelixKratz/formulae/borders

# Install all useful Apps
install_cask nikitabobko/tap/aerospace "AeroSpace.app"
install_cask google-chrome "Google Chrome.app"
install_cask zed "Zed.app"
install_cask 1password "1Password.app"
install_cask dropbox "Dropbox.app"
install_cask spotify "Spotify.app"
install_cask nordvpn "NordVPN.app"
install_cask obsidian "Obsidian.app"
install_cask git-credential-manager
install_cask ghostty "Ghostty.app"
install_cask beeper "Beeper Desktop.app"
install_cask zoom "zoom.us.app"
install_cask raycast "Raycast.app"
install_cask cleanshot "CleanShot X.app"
install_cask fantastical "Fantastical.app"
install_cask superhuman "Superhuman.app"
install_cask zen "Zen.app"
install_cask datagrip "DataGrip.app"
install_cask notion "Notion.app"

# Docker and git management
brew install lazydocker
append_once "alias ldo='lazydocker'" "$HOME/.zshrc"
brew install lazygit
append_once "alias lg='lazygit'" "$HOME/.zshrc"

# Install Coding Font
# Note: homebrew/cask-fonts was deprecated in 2024, fonts are now in the main cask
install_cask font-ia-writer-quattro
install_cask font-hack-nerd-font

# App Store CLI
brew install mas

# Need to have logged into the App Store on the mac for these to work
install_mas_app() {
  local id="$1"
  local name="$2"

  if mas list | awk '{print $1}' | grep -qx "$id"; then
    echo "Skipping $name: already installed."
    return
  fi

  mas install "$id" || echo "Skipping $name: sign into the App Store, then rerun."
}

install_mas_app 775737590 "iA Writer"
install_mas_app 904280696 "Things"

# Install starship
brew install starship
append_once 'eval "$(starship init zsh)"' "$HOME/.zshrc"

# Install GVM to manage go
if [[ ! -d "$HOME/.gvm" ]]; then
  bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
fi

# Finished
printf '\n\nFinished! 🎉 Now log out and log back in for changes to take effect.\n'
