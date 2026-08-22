# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""
plugins=(git)
[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

export EDITOR='nvim'

# ---------------------------------------------------------------------------
# Core aliases
# ---------------------------------------------------------------------------
alias nv='nvim'
alias lg='lazygit'
alias ldo='lazydocker'
alias pn=pnpm
alias dokku="ssh dokku@xn--wxa.xyz"
alias wgi="ssh dokku@webglowit.services"
alias zpd="ssh dokku@zpd.webglowit.services"

# ---------------------------------------------------------------------------
# Platform-specific
# ---------------------------------------------------------------------------
case "$(uname -s)" in
  Darwin)
    # macOS

    # Homebrew
    [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

    # pnpm
    export PNPM_HOME="$HOME/Library/pnpm"
    case ":$PATH:" in
      *":$PNPM_HOME:"*) ;;
      *) export PATH="$PNPM_HOME:$PATH" ;;
    esac

    # Bun
    export PATH="$HOME/.bun/bin:$PATH"
    [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

    # Ruby (chruby)
    if [[ -f /opt/homebrew/opt/chruby/share/chruby/chruby.sh ]]; then
      source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
      source /opt/homebrew/opt/chruby/share/chruby/auto.sh
      chruby ruby-3.4.4
    fi

    # Go Version Manager
    [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

    # PostgreSQL
    export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

    # tfenv
    export PATH="$HOME/.tfenv/bin:$PATH"
    ;;

  Linux)
    # fd on Debian/Ubuntu
    command -v fdfind &>/dev/null && alias fd=fdfind

    # Go (if installed via tar to /usr/local/go)
    [[ -d /usr/local/go/bin ]] && export PATH="$PATH:/usr/local/go/bin"

    # NPM global
    export PATH="$HOME/.npm-global/bin:$PATH"
    ;;
esac

# ---------------------------------------------------------------------------
# Common PATH additions
# ---------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

# ---------------------------------------------------------------------------
# Machine-local secrets
# ---------------------------------------------------------------------------
export NANOBANANA_MODEL="gemini-3-pro-image-preview"
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"