#!/usr/bin/env bash
# setup_environment.sh – Automates the environment setup you performed in your history.
# It installs packages, runs installer scripts via curl, creates symlinks,
# and switches the default shell to zsh.  The script prompts for sudo
# credentials once at the start.

set -euo pipefail

# Ask for sudo password up front – this will cache it for the duration of the script.
sudo -v || { echo "Unable to obtain sudo privileges."; exit 1; }

# Update package lists and upgrade existing packages.
sudo apt update && sudo apt upgrade -y

# Install core utilities via APT.
sudo apt install -y git
sudo apt install -y zsh tmux btop autojump vim fzf

# Install uv (Python package manager) using the official installer script.
# Install uv if not present
if ! command -v uv &>/dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    echo "uv already installed, skipping."
fi

# Install opencode.ai CLI exactly as you did: pipe to bash.
# Install opencode.ai CLI if not present
if ! command -v opencode &>/dev/null; then
    echo "Installing opencode.ai..."
    curl -fsSL https://opencode.ai/install | bash
else
    echo "opencode.ai already installed, skipping."
fi

# Clone sdots repository if not present
if [ ! -d "$HOME/sdots" ]; then
    echo "Cloning sdots repository..."
    git clone https://github.com/sment1337/sdots.git "$HOME/sdots"
else
    echo "sdots repository already exists. Pulling latest changes..."
    (cd "$HOME/sdots" && git pull)
fi

# Install lazygit via APT if available
if ! command -v lazygit &>/dev/null; then
    echo "Installing lazygit via apt..."
    sudo apt install -y lazygit || { echo "apt install failed, falling back to manual install." ;
        # Manual fallback (same as previous logic)
        if command -v lsb_release &>/dev/null; then
            OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        else
            source /etc/os-release 2>/dev/null || true
            OS=${ID:-$(uname -s | tr '[:upper:]' '[:lower:]')}
        fi
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64|amd64) ARCH="amd64";;
            aarch64|arm64) ARCH="arm64";;
            armv7l) ARCH="armhf";;
            *) echo "Unsupported architecture: $ARCH"; exit 1;;
        esac
        LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": *"v\K[^"]*')
        FILE="lazygit_${LAZYGIT_VERSION}_linux_${ARCH}.tar.gz"
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/${FILE}"
        tar -xzf lazygit.tar.gz
        DIR="lazygit_${LAZYGIT_VERSION}_linux_${ARCH}"
        sudo mv "$DIR/lazygit" /usr/local/bin/
        rm -rf "$DIR"
        rm lazygit.tar.gz
    }
else
    echo "lazygit already installed, skipping."
fi

# Create symbolic links for configuration files.
ln -sf "$HOME/sdots/.zshrc" "$HOME/.zshrc"
ln -sf "$HOME/sdots/tmux/.tmux.conf" "$HOME/.tmux.conf"
ln -sf "$HOME/sdots/.vim/" "$HOME/.vim"

# Change the default shell to zsh.
chsh -s "$(which zsh)"

echo "Setup complete.  You may need to log out and back in for the shell change to take effect."