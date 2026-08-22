# mac-setup

Bootstrap a development machine and link personal dotfiles.

Supported platforms:

- Apple Silicon macOS
- Debian or Ubuntu Linux on x86_64 or ARM64

## Run

```sh
git clone https://github.com/cajames/mac-setup.git ~/repos/mac-setup
cd ~/repos/mac-setup
./setup.sh
```

The script is rerunnable. It skips existing dotfile targets rather than overwriting them. Source repositories, including oh-my-zsh and local Neovim plugins, are cloned under `~/repos/`.

`setup_mac.sh` remains as a compatibility wrapper and delegates to `setup.sh`.

## Installed on both platforms

- Zsh and oh-my-zsh
- Starship
- Neovim and LazyVim configuration
- GitHub CLI
- ripgrep, fzf, fd, zoxide, eza
- lazygit and lazydocker
- Go, Node.js, npm, pnpm, and OpenCode

Linux installs system packages with `apt-get`. Release binaries and npm tools are pinned to reviewed versions. Downloaded Node and GitHub release archives are verified against upstream SHA-256 records before installation.

## macOS-only setup

- Homebrew
- AeroSpace, SketchyBar, and borders
- Desktop applications and fonts
- App Store applications
- Finder, Dock, keyboard repeat, and Caps Lock settings
- Zed configuration

## Dotfiles

Common links:

- `.zshrc`
- `.config/git/ignore`
- `.config/nvim`
- `.config/starship.toml`

macOS also links `.aerospace.toml`, `.config/sketchybar`, `.config/zed`, and the Caps Lock LaunchAgent.

## Local secrets

Machine-local credentials belong in `~/.zshrc.local`, which is not tracked. The setup script creates it from `dotfiles/.zshrc.local.example` when missing.