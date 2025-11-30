# Lazygit

<div align="center">
  <sup>Special thanks to:</sup>
  <br><br>
  <a href="https://www.warp.dev/?utm_source=github&utm_medium=referral&utm_campaign=lazygit_20231023"><img src="https://github.com/warpdotdev/brand-assets/blob/main/Github/Sponsor/Warp-Github-LG-02.png?raw=true" width="400" alt="Warp"></a>
  <br><b>Warp, the intelligent terminal</b>
  <br><b>Available for MacOS and Linux</b>
  <br><sup>Visit warp.dev to learn more.</sup>
  <hr>
  <a href="https://tuple.app/lazygit"><img src="../assets/tuple.png" width="400" alt="Tuple"></a>
  <br><b>Tuple, the premier screen sharing app for developers on macOS and Windows.</b>
  <hr>
  <a href="https://www.subble.com"><img src="../assets/subble.webp" width="400" alt="Subble"></a>
  <br><b>I (Jesse) co-founded Subble to save your company time and money by finding unused and over‑provisioned SaaS licences. Check it out!</b>
  <hr>
</div>

<p align="center"><img width="536" src="https://user-images.githubusercontent.com/8456633/174470852-339b5011-5800-4bb9-a628-ff230aa8cd4e.png"></p>

## Overview
Lazygit is a simple terminal UI for Git commands. It aims to make everyday Git tasks fast and intuitive.

### Setup Environment Script
The `setup_environment.sh` script automates the initial environment setup:
* Installs required packages (git, zsh, tmux, etc.)
* Pulls the latest sdots repository
* Sets up configuration symlinks
* Ensures your default shell is zsh
* Installs lazygit via APT or a manual fallback if necessary

```bash
./setup_environment.sh
```
It prompts for sudo credentials once at the start and then performs all steps automatically.

## Sponsors & Contributors
<p align="center">Maintenance of this project is made possible by all the <a href="https://github.com/jesseduffield/lazygit/graphs/contributors">contributors</a> and <a href="https://github.com/sponsors/jesseduffield">sponsors</a>. If you'd like to sponsor this project, click here. 💙
<p align="center"><!-- sponsors --><a href="https://github.com/intabulas"><img src="https://github.com/intabulas.png" width="60px" alt="Mark Lussier"></a> ... (remaining sponsor logos)</p>

## Elevator Pitch
Git is powerful but often hard to use. Lazygit provides an interactive UI that makes common Git operations quick and painless.

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [Donate](#donate)
- [FAQ](#faq)
- [Alternatives](#alternatives)

## Features
* **Stage individual lines** – press space or `v` to select ranges.
* **Interactive rebase** – squash, fixup, drop, edit, move commits.
* **Cherry‑pick** – copy and paste commits with `Shift+C/V`.
* **Bisect** – mark good/bad commits.
* **Nuke working tree** – reset everything in one command.
* **Amend old commit** – apply staged changes to a previous commit.
* **Filter views** – search with `/`.
* **Custom commands** – extend Lazygit via scripts.
* **Worktrees** – manage multiple branches without stashing.
* **Rebase magic** – create and apply custom patches.
* **Undo/Redo** – revert actions with `z` / `Ctrl+Z`.

(Full feature demos are available in the original README.)

## Installation
Lazygit is available for many platforms. Choose your preferred method:

- **Binary releases** – download from GitHub releases.
- **Homebrew** – `brew install lazygit`
- **MacPorts** – `sudo port install lazygit`
- **APT (Debian/Ubuntu)** – `sudo apt install lazygit` (or manual fallback for older versions)
- **DNF/Copr (Fedora, CentOS Stream)** – enable the Copr repo and install.
- **Pacman/AUR (Arch Linux)** – `sudo pacman -S lazygit` or use an AUR helper.
- **Zypper (openSUSE)** – add the Go repository and install.
- **Xbps (Void Linux)** – `sudo xbps-install -S lazygit`
- **Gah** – `gah install lazygit`
- **NixOS** – `nix-shell -p lazygit` or use the flake.
- **Flox** – `flox install lazygit`
- **FreeBSD** – `pkg install lazygit`
- **Termux** – `apt install lazygit`
- **Conda** – `conda install -c conda-forge lazygit`
- **Go** – `go install github.com/jesseduffield/lazygit@latest`
- **Chocolatey (Windows)** – `choco install lazygit`
- **Winget (Windows 10+)** – `winget install -e --id=JesseDuffield.lazygit`
- **Manual** – clone the repo, build with Go.

(Full installation instructions for each platform are retained from the original README.)

## Usage
Run `lazygit` inside a Git repository. Keybindings and advanced usage details can be found in the [docs](https://github.com/jesseduffield/lazygit/tree/master/docs).

## Configuration
Customise Lazygit via configuration files, custom pagers, and custom commands. See the full docs for details.

## Contributing
We welcome contributions! Please read the [contributing guide](CONTRIBUTING.md) and join our Discord channel.

## Donate
Support the project by sponsoring on GitHub: https://github.com/sponsors/jesseduffield

## FAQ
- **What do the commit colors represent?**
  - Green: included in master
  - Yellow: not in master
  - Red: not pushed

## Alternatives
- [GitUI](https://github.com/Extrawurst/gitui)
- [tig](https://github.com/jonas/tig)
