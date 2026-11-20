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

# Keep iTerm2 pointed at the Nerd Font by postscript name. Family names are
# not consistently recognized across iTerm2 releases and macOS font caches.
ITERM_PROFILE="$DOTFILES/iterm2/com.googlecode.iterm2.plist"
/usr/bin/python3 - "$ITERM_PROFILE" <<'PY'
import plistlib
import sys

profile_path = sys.argv[1]
with open(profile_path, "rb") as profile_file:
    profile = plistlib.load(profile_file)

default_profile = profile["New Bookmarks"][0]
default_profile["Normal Font"] = "HackNFM-Regular 12"
default_profile["Non Ascii Font"] = "HackNFM-Regular 12"
default_profile["Use Non-ASCII Font"] = True

with open(profile_path, "wb") as profile_file:
    plistlib.dump(profile, profile_file, fmt=plistlib.FMT_BINARY)
PY

# Seed iTerm2's active preferences before enabling custom-folder syncing.
defaults import com.googlecode.iterm2 "$ITERM_PROFILE"
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

if pgrep -x iTerm2 >/dev/null 2>&1; then
    echo "Quit and reopen iTerm2 to apply the imported profile."
fi

# Match this Mac's pointer and keyboard repeat settings.
defaults write -g com.apple.mouse.scaling -float 3
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
echo "Keyboard repeat preferences were saved; sign out and back in for macOS to apply them."
