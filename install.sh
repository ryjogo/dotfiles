#!/usr/bin/env bash
# Bootstrap a new Mac: Homebrew, packages, Oh My Zsh, then link the dotfiles.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v brew >/dev/null 2>&1; then
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ -x /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
fi

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew was installed but is not available on PATH." >&2
    exit 1
fi

# The Sidero formulas are in a third-party tap and require Homebrew trust.
brew tap siderolabs/tap >/dev/null 2>&1 || true
if brew trust --help >/dev/null 2>&1; then
    brew trust --tap siderolabs/tap
fi

brew bundle --file="$DOTFILES/Brewfile"

mkdir -p "$HOME/.config"

# Stow refuses to overwrite existing files. Back up real files and directories,
# but leave links that already point into this dotfiles repository.
BACKUP_DIR="$HOME/.dotfiles-backup"
mkdir -p "$BACKUP_DIR"
backup_existing() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            local link_target
            link_target="$(readlink "$target")"
            case "$link_target" in
                "$DOTFILES"/*|src/dotfiles/*) return ;;
            esac
        fi
        mv "$target" "$BACKUP_DIR/"
    fi
}

cd "$DOTFILES"
for target in \
    "$HOME/.zshrc" \
    "$HOME/.zprofile" \
    "$HOME/.gitconfig" \
    "$HOME/.aliases" \
    "$HOME/.config/starship.toml"; do
    backup_existing "$target"
done

for pkg in zsh git aliases starship; do
    stow --dotfiles --restow -t "$HOME" "$pkg"
done

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Seed iTerm2's active preferences before enabling custom-folder syncing.
defaults import com.googlecode.iterm2 "$DOTFILES/iterm2/com.googlecode.iterm2.plist"
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

if pgrep -x iTerm2 >/dev/null 2>&1; then
    echo "Quit and reopen iTerm2 to apply the imported profile."
fi
