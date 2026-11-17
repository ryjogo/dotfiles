#!/usr/bin/env bash
# Bootstrap a new Mac: Homebrew, packages, Oh My Zsh, then link the dotfiles.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew bundle --file="$DOTFILES/Brewfile"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Stow refuses to overwrite existing files, so move them aside first.
mkdir -p "$HOME/.config"
cd "$DOTFILES"
for pkg in zsh git aliases starship; do
    stow --dotfiles --restow -t "$HOME" "$pkg"
done

# iTerm2 loads its preferences straight from this repo.
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
