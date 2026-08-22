#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM="$(uname -s)"
ARCH="$(uname -m)"
TMP_DIR="$(mktemp -d)"
HOMEBREW_INSTALL_COMMIT="b9990527570f7e07d5393f37447b8293ec0a78de"
GVM_INSTALL_COMMIT="dd652539fa4b771840846f8319fad303c7d0a8d2"
STARSHIP_VERSION="1.26.0"
NEOVIM_VERSION="0.12.4"
LAZYGIT_VERSION="0.64.1"
LAZYDOCKER_VERSION="0.25.2"
EZA_VERSION="0.23.5"
NODE_VERSION="22.23.2"
PNPM_VERSION="11.22.0"
OPENCODE_VERSION="1.18.21"
trap 'rm -rf "$TMP_DIR"' EXIT

case "$PLATFORM" in
Darwin) PLATFORM="macos" ;;
Linux) PLATFORM="linux" ;;
*)
  printf 'Unsupported OS: %s\n' "$PLATFORM" >&2
  exit 1
  ;;
esac

if [[ $EUID -eq 0 ]]; then
  SUDO=()
elif command -v sudo >/dev/null; then
  SUDO=(sudo)
else
  printf 'sudo is required when setup is not run as root.\n' >&2
  exit 1
fi

section() {
  printf '\n=== %s ===\n' "$1"
}

download() {
  local url="$1"
  local destination="$2"

  curl --retry 3 --retry-delay 2 --retry-all-errors -fsSL "$url" -o "$destination"
}

append_once() {
  local line="$1"
  local file="$2"

  touch "$file"
  grep -Fqx "$line" "$file" || printf '%s\n' "$line" >>"$file"
}

link_dotfile() {
  local relative_path="$1"
  local source="$SCRIPT_DIR/dotfiles/$relative_path"
  local target="$HOME/$relative_path"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    printf '  skip (already linked): %s\n' "$relative_path"
  elif [[ -e "$target" || -L "$target" ]]; then
    printf '  skip (target exists):  %s\n' "$relative_path"
  else
    ln -s "$source" "$target"
    printf '  linked: %s\n' "$relative_path"
  fi
}

github_asset_sha256() {
  local repository="$1"
  local version="$2"
  local asset="$3"

  curl --retry 3 --retry-delay 2 --retry-all-errors -fsSL "https://api.github.com/repos/$repository/releases/tags/v${version}" |
    jq --exit-status --raw-output --arg asset "$asset" \
      '.assets[] | select(.name == $asset) | .digest | select(.) | sub("^sha256:"; "")'
}

verify_sha256() {
  local file="$1"
  local expected="$2"

  printf '%s  %s\n' "$expected" "$(basename "$file")" |
    (cd "$(dirname "$file")" && sha256sum --check --status)
}

install_dotfiles() {
  section "Dotfiles"

  link_dotfile ".zshrc"
  link_dotfile ".config/git/ignore"
  link_dotfile ".config/nvim"
  link_dotfile ".config/starship.toml"

  if [[ "$PLATFORM" == "macos" ]]; then
    link_dotfile ".aerospace.toml"
    link_dotfile ".config/sketchybar"
    link_dotfile ".config/zed"
    link_dotfile "Library/LaunchAgents/com.cajames.capslock-control.plist"
  fi

  if [[ ! -e "$HOME/.zshrc.local" && ! -L "$HOME/.zshrc.local" ]]; then
    cp "$SCRIPT_DIR/dotfiles/.zshrc.local.example" "$HOME/.zshrc.local"
    chmod 600 "$HOME/.zshrc.local"
    printf '  created: .zshrc.local\n'
  else
    printf '  skip: .zshrc.local already exists\n'
  fi
}

install_oh_my_zsh() {
  local repository="$HOME/repos/ohmyzsh"

  if [[ -r "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    printf '  oh-my-zsh already installed\n'
    return
  fi
  if [[ -e "$HOME/.oh-my-zsh" || -L "$HOME/.oh-my-zsh" ]]; then
    printf 'Existing ~/.oh-my-zsh is incomplete; remove or repair it, then rerun.\n' >&2
    return 1
  fi

  mkdir -p "$HOME/repos"
  if [[ -e "$repository" && ! -r "$repository/oh-my-zsh.sh" ]]; then
    printf 'Existing %s is incomplete; remove or repair it, then rerun.\n' "$repository" >&2
    return 1
  elif [[ ! -d "$repository/.git" ]]; then
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$repository"
  fi
  ln -s "$repository" "$HOME/.oh-my-zsh"
}

install_cask() {
  local cask="$1"
  shift

  if brew list --cask "$cask" &>/dev/null; then
    printf '  skip %s: already installed by Homebrew\n' "$cask"
    return
  fi

  local app applications_dir
  for app in "$@"; do
    for applications_dir in /Applications "$HOME/Applications"; do
      if compgen -G "$applications_dir/$app" >/dev/null; then
        printf '  skip %s: %s already exists\n' "$cask" "$app"
        return
      fi
    done
  done

  brew install --cask "$cask"
}

install_mas_app() {
  local id="$1"
  local name="$2"

  if mas list | awk '{print $1}' | grep -qx "$id"; then
    printf '  skip %s: already installed\n' "$name"
  else
    mas install "$id" || printf '  skip %s: sign into the App Store, then rerun\n' "$name"
  fi
}

setup_macos() {
  if [[ "$ARCH" != "arm64" ]]; then
    printf 'This macOS setup currently supports Apple Silicon only (found %s).\n' "$ARCH" >&2
    exit 1
  fi

  section "macOS settings"

  /usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}' >/dev/null
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write com.apple.finder AppleShowAllFiles YES
  defaults write com.apple.finder CreateDesktop -bool false
  defaults write -g ApplePersistence -bool false
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-time-modifier -float 1
  defaults write com.apple.dock static-only -bool true
  killall Finder 2>/dev/null || true
  killall Dock 2>/dev/null || true

  section "Homebrew"

  if [[ ! -x /opt/homebrew/bin/brew ]]; then
    download "https://raw.githubusercontent.com/Homebrew/install/${HOMEBREW_INSTALL_COMMIT}/install.sh" "$TMP_DIR/homebrew-install.sh"
    NONINTERACTIVE=1 /bin/bash "$TMP_DIR/homebrew-install.sh"
  fi
  # shellcheck disable=SC2016 # Keep the command literal in .zprofile.
  append_once 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"

  section "Shell and CLI tools"

  brew install \
    zsh zsh-completions starship \
    gh neovim ripgrep fzf fd zoxide eza lazygit lazydocker \
    go npm pnpm n oven-sh/bun/bun \
    chruby ruby-install postgresql@17 tfenv opencode herdr

  install_oh_my_zsh

  if [[ ! -x "$HOME/.rubies/ruby-3.4.4/bin/ruby" ]]; then
    ruby-install ruby 3.4.4
  fi
  if [[ ! -d "$HOME/.gvm" ]]; then
    download "https://raw.githubusercontent.com/moovweb/gvm/${GVM_INSTALL_COMMIT}/binscripts/gvm-installer" "$TMP_DIR/gvm-installer.sh"
    bash "$TMP_DIR/gvm-installer.sh"
  fi

  section "Window management"

  brew tap FelixKratz/formulae
  brew install FelixKratz/formulae/sketchybar FelixKratz/formulae/borders

  section "Applications"

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
  install_cask font-ia-writer-quattro
  install_cask font-hack-nerd-font

  section "App Store"

  brew install mas
  install_mas_app 775737590 "iA Writer"
  install_mas_app 904280696 "Things"
}

linux_asset_arch() {
  case "$ARCH" in
  x86_64) printf 'x86_64\n' ;;
  aarch64 | arm64) printf 'arm64\n' ;;
  *)
    printf 'Unsupported Linux architecture: %s\n' "$ARCH" >&2
    return 1
    ;;
  esac
}

install_starship_linux() {
  if command -v starship >/dev/null; then
    printf '  starship already installed\n'
    return
  fi

  local arch version asset archive checksum
  arch="$(linux_asset_arch)"
  version="$STARSHIP_VERSION"

  case "$arch" in
  x86_64) arch="x86_64-unknown-linux-musl" ;;
  arm64) arch="aarch64-unknown-linux-musl" ;;
  esac

  asset="starship-${arch}.tar.gz"
  archive="$TMP_DIR/$asset"
  checksum="$(github_asset_sha256 starship/starship "$version" "$asset")"
  download "https://github.com/starship/starship/releases/download/v${version}/${asset}" "$archive"
  verify_sha256 "$archive" "$checksum"
  tar -xzf "$archive" -C "$TMP_DIR" starship
  "${SUDO[@]}" install -m 0755 "$TMP_DIR/starship" /usr/local/bin/starship
  printf '  installed starship %s\n' "$version"
}

install_neovim_linux() {
  local installed_minor=0
  if command -v nvim >/dev/null; then
    installed_minor="$(nvim --version | sed -nE '1s/.*v0\.([0-9]+).*/\1/p')"
    installed_minor="${installed_minor:-0}"
  fi
  if ((installed_minor >= 10)); then
    printf '  neovim already recent enough\n'
    return
  fi

  local arch version asset archive checksum extracted
  arch="$(linux_asset_arch)"
  version="$NEOVIM_VERSION"
  asset="nvim-linux-${arch}.tar.gz"
  archive="$TMP_DIR/$asset"
  checksum="$(github_asset_sha256 neovim/neovim "$version" "$asset")"
  extracted="${asset%.tar.gz}"

  download "https://github.com/neovim/neovim/releases/download/v${version}/${asset}" "$archive"
  verify_sha256 "$archive" "$checksum"
  tar -xzf "$archive" -C "$TMP_DIR"
  "${SUDO[@]}" cp -R "$TMP_DIR/$extracted/"* /usr/local/
  printf '  installed neovim %s\n' "$version"
}

install_lazygit_linux() {
  if command -v lazygit >/dev/null; then
    printf '  lazygit already installed\n'
    return
  fi

  local arch version asset archive checksums checksum
  arch="$(linux_asset_arch)"
  version="$LAZYGIT_VERSION"

  case "$arch" in
  x86_64) arch="x86_64" ;;
  arm64) arch="arm64" ;;
  esac

  asset="lazygit_${version}_linux_${arch}.tar.gz"
  archive="$TMP_DIR/$asset"
  checksums="$TMP_DIR/lazygit-checksums.txt"
  download "https://github.com/jesseduffield/lazygit/releases/download/v${version}/checksums.txt" "$checksums"
  checksum="$(awk -v asset="$asset" '$2 == asset { print $1; exit }' "$checksums")"
  [[ -n "$checksum" ]]
  download "https://github.com/jesseduffield/lazygit/releases/download/v${version}/${asset}" "$archive"
  verify_sha256 "$archive" "$checksum"
  tar -xzf "$archive" -C "$TMP_DIR" lazygit
  "${SUDO[@]}" install -m 0755 "$TMP_DIR/lazygit" /usr/local/bin/lazygit
  printf '  installed lazygit %s\n' "$version"
}

install_lazydocker_linux() {
  if command -v lazydocker >/dev/null; then
    printf '  lazydocker already installed\n'
    return
  fi

  local arch version asset archive checksum
  arch="$(linux_asset_arch)"
  version="$LAZYDOCKER_VERSION"

  case "$arch" in
  x86_64) arch="x86_64" ;;
  arm64) arch="arm64" ;;
  esac

  asset="lazydocker_${version}_Linux_${arch}.tar.gz"
  archive="$TMP_DIR/$asset"
  checksum="$(github_asset_sha256 jesseduffield/lazydocker "$version" "$asset")"
  download "https://github.com/jesseduffield/lazydocker/releases/download/v${version}/${asset}" "$archive"
  verify_sha256 "$archive" "$checksum"
  tar -xzf "$archive" -C "$TMP_DIR" lazydocker
  "${SUDO[@]}" install -m 0755 "$TMP_DIR/lazydocker" /usr/local/bin/lazydocker
  printf '  installed lazydocker %s\n' "$version"
}

install_eza_linux() {
  if command -v eza >/dev/null; then
    printf '  eza already installed\n'
    return
  fi

  local arch version asset archive checksum
  arch="$(linux_asset_arch)"
  version="$EZA_VERSION"

  case "$arch" in
  x86_64) arch="x86_64" ;;
  arm64) arch="aarch64" ;;
  esac

  asset="eza_${arch}-unknown-linux-gnu.tar.gz"
  archive="$TMP_DIR/$asset"
  checksum="$(github_asset_sha256 eza-community/eza "$version" "$asset")"
  download "https://github.com/eza-community/eza/releases/download/v${version}/${asset}" "$archive"
  verify_sha256 "$archive" "$checksum"
  tar -xzf "$archive" -C "$TMP_DIR"
  "${SUDO[@]}" install -m 0755 "$TMP_DIR/eza" /usr/local/bin/eza
  printf '  installed eza %s\n' "$version"
}

install_node_linux() {
  local installed_major=0
  if command -v node >/dev/null; then
    installed_major="$(node --version | sed -nE 's/^v([0-9]+).*/\1/p')"
    installed_major="${installed_major:-0}"
  fi
  if ((installed_major >= 22)); then
    printf '  node already recent enough\n'
    return
  fi

  local arch filename archive checksums extracted
  arch="$(linux_asset_arch)"
  case "$arch" in
  x86_64) arch="x64" ;;
  arm64) arch="arm64" ;;
  esac

  checksums="$TMP_DIR/node-SHASUMS256.txt"
  download "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" "$checksums"
  filename="$(awk -v asset="linux-${arch}.tar.xz" '$2 ~ asset "$" { print $2; exit }' "$checksums")"
  if [[ -z "$filename" ]]; then
    printf 'Unable to find a Node.js archive for %s.\n' "$arch" >&2
    return 1
  fi

  archive="$TMP_DIR/$filename"
  extracted="${filename%.tar.xz}"
  download "https://nodejs.org/dist/v${NODE_VERSION}/$filename" "$archive"
  (cd "$TMP_DIR" && grep " $filename\$" "$checksums" | sha256sum --check --status)
  tar -xJf "$archive" -C "$TMP_DIR"
  "${SUDO[@]}" cp -R "$TMP_DIR/$extracted/"* /usr/local/
  printf '  installed node %s\n' "$(/usr/local/bin/node --version)"
}

setup_linux() {
  if ! command -v apt-get >/dev/null; then
    printf 'Linux support currently requires Debian or Ubuntu (apt-get).\n' >&2
    exit 1
  fi

  section "System packages"

  "${SUDO[@]}" apt-get update
  "${SUDO[@]}" apt-get install -y \
    build-essential ca-certificates curl fd-find fzf gh git golang-go jq \
    ripgrep xz-utils zoxide zsh

  install_node_linux

  if ! command -v pnpm >/dev/null; then
    "${SUDO[@]}" npm install --global "pnpm@${PNPM_VERSION}"
  fi
  if ! command -v opencode >/dev/null; then
    "${SUDO[@]}" npm install --global "opencode-ai@${OPENCODE_VERSION}"
  fi

  section "Shell"
  install_oh_my_zsh

  section "Starship"
  install_starship_linux

  section "Neovim"
  install_neovim_linux

  section "Terminal tools"
  install_eza_linux
  install_lazygit_linux
  install_lazydocker_linux

  section "Neovim local plugins"
  mkdir -p "$HOME/repos"
  if [[ -r "$HOME/repos/copy-reference.nvim/lua/copy-reference/init.lua" ]]; then
    printf '  copy-reference.nvim already cloned\n'
  elif [[ -e "$HOME/repos/copy-reference.nvim" ]]; then
    printf 'Existing ~/repos/copy-reference.nvim is incomplete; remove or repair it, then rerun.\n' >&2
    return 1
  else
    git clone https://github.com/cajames/copy-reference.nvim "$HOME/repos/copy-reference.nvim"
  fi
}

printf 'Setting up %s on %s...\n' "$PLATFORM" "$ARCH"

if [[ "$PLATFORM" == "macos" ]]; then
  setup_macos
else
  setup_linux
fi

install_dotfiles

printf '\nFinished.\n'
if [[ "$PLATFORM" == "macos" ]]; then
  if [[ "$SHELL" != "/bin/zsh" ]]; then
    printf 'Run: chsh -s /bin/zsh\n'
  fi
  printf 'Log out and back in for system changes to take effect.\n'
elif [[ "$SHELL" != "$(command -v zsh)" ]]; then
  printf "Run: chsh -s '%s'\n" "$(command -v zsh)"
fi
