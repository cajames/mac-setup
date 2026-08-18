# mac-setup

Bootstrap an Apple Silicon Mac with Homebrew, development tools, applications, and personal dotfiles.

## Run

```sh
git clone <repo-url> ~/mac-setup
cd ~/mac-setup
./setup_mac.sh
```

The script is rerunnable. Existing applications and configuration targets are skipped.

## Included dotfiles

- AeroSpace
- Git global ignore
- Neovim/LazyVim
- SketchyBar
- Starship
- Zed
- ZSH

Dotfiles are symlinked from `dotfiles/` into `$HOME`.

## Secrets

Secrets belong in `~/.zshrc.local`, which is not tracked. Use `dotfiles/.zshrc.local.example` as a template. Rotate credentials before moving them to a new Mac.
