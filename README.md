# Repository Purpose
This repository is my personal **sdots** collection used across various Linux distributions. It contains configuration files, scripts, and dotfiles that I maintain and share.

## Quick Install with curl
You can bootstrap a fresh system by running the following one‑liner:
```bash
curl -fsSL https://raw.githubusercontent.com/sment1337/sdots/master/setup_environment.sh | bash
```
The script will prompt for sudo once, update your package lists, install required tools, clone this repo into `$HOME/sdots`, set up symlinks and switch your default shell to Zsh.

## `setup_environment.sh`

This lightweight Bash script automates the initial environment setup for the **sdots** project and its dependencies.

## What it does
1. **Privilege check** – Prompts once for sudo credentials and caches them for the duration of the run.
2. **System update** – Updates package lists and upgrades installed packages (`apt update && apt upgrade`).
3. **Core utilities** – Installs Git, Zsh, tmux, btop, autojump, Vim and fzf via APT.
4. **Python tooling** – Installs the `uv` Python package manager if it is not already present.
5. **CLI tools** – Installs the `opencode.ai` CLI using its official installer script.
6. **Repository clone** – Clones or updates the local copy of the `sdots` repository (`$HOME/sdots`).
7. **Lazygit** – Tries to install Lazygit via APT; if that fails it falls back to downloading the latest release from GitHub, extracting it and moving the binary to `/usr/local/bin/`.
8. **Configuration symlinks** – Creates symlinks for `.zshrc`, `.tmux.conf` and the Vim configuration so they are used by default.
9. **Shell switch** – Changes the user’s login shell to Zsh.
10. **Completion message** – Prints a friendly notice that the setup is finished.

## Usage
```bash
# Make sure the script is executable
chmod +x setup_environment.sh

# Run it (you will be prompted for sudo once)
./setup_environment.sh
```
After running, you may need to log out and back in for the shell change to take effect.

## Notes
- The script assumes an Ubuntu/Debian‑based system with `apt`. For other distributions, modify the package manager commands accordingly.
- If you already have Lazygit installed, the script will skip its installation step.
- All downloads are performed over HTTPS and verified via GitHub’s API for the latest release tag.
