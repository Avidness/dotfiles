# dotfiles

1. Install [Homebrew](https://brew.sh):

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install the prerequisites:

   ```sh
   brew install git
   brew install --cask iterm2
   ```

   `init.sh` installs Node with brew if you don't already have it (an existing
   install from nvm, fnm, Volta or brew is kept).

   `init.sh` links the Claude Code config but does not install Claude Code. If you
   want it: `curl -fsSL https://claude.ai/install.sh | bash`. The optional AI dev
   toolchain is in the `Brewfile`: `brew bundle --file ~/projects/dotfiles/Brewfile`.

3. Clone the repo (it must live at `~/projects/dotfiles`):

   ```sh
   mkdir -p ~/projects
   git clone https://github.com/Avidness/dotfiles ~/projects/dotfiles
   ```

4. Run the setup script before opening iTerm for the first time:

   ```sh
   bash ~/projects/dotfiles/init.sh
   ```

5. Open iTerm. If the "Dotfiles" profile is not the default, go to Settings > Profiles, select it, then Other Actions > Set as Default.
