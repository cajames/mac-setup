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

The script is rerunnable. Existing unmanaged dotfile targets are moved to a timestamped directory under `~/.config-backups/` before being replaced with symlinks to this repo. Source repositories, including oh-my-zsh and local Neovim plugins, are cloned under `~/repos/`.

`setup_mac.sh` remains as a compatibility wrapper and delegates to `setup.sh`.

## Installed on both platforms

- Zsh and oh-my-zsh
- Starship
- Neovim and LazyVim configuration
- GitHub CLI
- ripgrep, fzf, fd, zoxide, eza
- lazygit and lazydocker
- `dev-share` helper for private Tailscale Serve links
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

Common links update immediately when the checked-out repo changes:

- `.zshrc`
- `.config/git/ignore`
- `.config/nvim`
- `.config/starship.toml`

macOS also links `.aerospace.toml`, `.config/sketchybar`, `.config/zed`, and the Caps Lock LaunchAgent.

Utility scripts are installed into `~/.local/bin`, which the managed `.zshrc` adds to `PATH`.

## Sharing a local development server

When Tailscale is installed and connected, expose a localhost HTTP server privately to the tailnet:

```sh
dev-share 3000
```

The helper uses Tailscale Serve and prints the private HTTPS URL. It does not use Tailscale Funnel or expose the server publicly.

```sh
dev-share status  # Show the current mapping
dev-share off     # Remove the mapping
```

Running `dev-share` with another port switches the root Serve mapping to that local port.

## Local secrets

Machine-local credentials belong in `~/.zshrc.local`, which is not tracked. The setup script creates it from `dotfiles/.zshrc.local.example` when missing.
