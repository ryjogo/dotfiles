# dotfiles

Personal macOS setup, managed with [GNU Stow](https://www.gnu.org/software/stow/) and a Homebrew `Brewfile`.

## Contents

| Path | Purpose |
| --- | --- |
| `zsh/` | `~/.zshrc`, `~/.zprofile` (Oh My Zsh, Go) |
| `starship/` | `~/.config/starship.toml` (Starship prompt) |
| `git/` | `~/.gitconfig` |
| `aliases/` | `~/.aliases`, sourced from `.zshrc` |
| `iterm2/` | iTerm2 preferences, loaded via "Load preferences from a custom folder" |
| `Brewfile` | CLI tools, casks and fonts |
| `install.sh` | Bootstrap script |

Each top-level folder is a Stow *package*. Files named `dot-<name>` are linked into `$HOME` as `.<name>` (via `stow --dotfiles`).

## Bootstrap a new Mac

1. Install the Xcode command line tools:
   ```sh
   xcode-select --install
   ```
2. Clone the repo:
   ```sh
   git clone https://github.com/ryjogo/dotfiles.git ~/src/dotfiles
   ```
3. Move any existing dotfiles out of the way (Stow won't overwrite them):
   ```sh
   mkdir -p ~/.dotfiles-backup
   mv ~/.zshrc ~/.zprofile ~/.gitconfig ~/.aliases ~/.dotfiles-backup/ 2>/dev/null
   ```
4. Run the installer:
   ```sh
   ~/src/dotfiles/install.sh
   ```
   It installs Homebrew (if missing), runs `brew bundle`, installs Oh My Zsh, and stows the `zsh`, `git`, `aliases` and `starship` packages, and points iTerm2 at `iterm2/`.
5. Open a new terminal.

## Day to day

```sh
# Add a tool
brew install <x>              # then add `brew "<x>"` to Brewfile

# Add a dotfile
mv ~/.foo zsh/dot-foo         # or another package
stow --dotfiles -t ~ zsh

# Add a new package
mkdir nvim && mv ~/.config/nvim nvim/...   # mirror the path under $HOME
stow --dotfiles -t ~ nvim

# Apply or re-link after pulling changes
stow --dotfiles --restow -t ~ zsh git aliases starship

# Remove a package's links
stow --dotfiles -D -t ~ aliases

# Install everything in the Brewfile / see what's missing
brew bundle --file=Brewfile
brew bundle check --verbose --file=Brewfile
```

If you add a new package, also add it to the `for pkg in ...` loop in `install.sh`.
