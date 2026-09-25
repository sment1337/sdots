# sment's dot files

My personal development environment: the shell, editor and terminal-multiplexer
setup I carry between machines, plus the window-manager/desktop config for my
Linux workstation.

The repo is the single source of truth; files are **symlinked** out of it into
`$HOME`, so editing a file here (or editing `~/.tmux.conf` directly — it's the
same file) takes effect immediately.

## Targets

| Machine | What's active |
|---|---|
| **macOS** (daily driver, `mac` branch) | zsh + vim + tmux, note/PDF search workflows, fzf |
| **Arch Linux** (workstation) | i3 + polybar + rofi + picom + sddm, plus the same shell/editor stack |

Everything Linux-only (window manager, compositor, login manager, bar) lives in
this repo too but is inert on the Mac.

## Layout

| Path | Purpose |
|---|---|
| `.zshrc` | Shell: aliases, PATH, fzf bindings/preview, `EDITOR`, prompt. Sources `~/.local.zshrc` at the end. |
| `.vim/` | Vim config (`.vimrc`), plugin bundles (`pack/`, `plugged/` — both untracked/gitignored). Always invoked as `vim -u ~/.vim/.vimrc`. |
| `tmux/` | `.tmux.conf` + the helper scripts behind its keybindings. |
| `tmux/scripts/sysstats.sh` | Daemon that renders the live status bar (CPU/GPU sparklines, RAM, battery) and rewrites tmux's `status-right` every 5s. macOS-native data sources (`top`, `ioreg`, `vm_stat`, `pmset`). |
| `tmux/OpenNote.sh`, `OpenPDF.sh`, `preview.sh`, `pdfPreview.sh` | Full-text search over notes (`egrep` + fzf + vim preview) and over PDF literature (`pdfgrep` + fzf → zathura at the matching page). Bound to `prefix C-o` and `prefix O`. |
| `tmux/prompt.sh` | Small wrapper for local LLM chat (`lms`) with streaming output and copy-to-clipboard. |
| `tmux/scripts/fzf-window.sh` | `prefix W` window picker. Kept as a script because tmux.conf expands `"$var"` at parse time (see its header comment). |
| `homedirScripts/` | Standalone helpers meant to be symlinked **directly into `$HOME`** and used outside tmux. Overlaps `tmux/` in purpose but never in code — see [`homedirScripts/README.md`](homedirScripts/README.md). |
| `i3/`, `polybar/`, `rofi/`, `picom/`, `terminator/`, `nitrogen/`, `systemd/` | Linux desktop: window manager, bar, app launcher, compositor, terminal, wallpaper, units. |
| `ranger/`, `htop/`, `bottom/`, `mc/`, `dconf/`, `gtk-2.0/`, `GIMP/`, `inkscape/`, `mimeapps.list`, `user-dirs.*` | Per-application preferences. |
| `lnkScript.sh` | **First-run bootstrap for a fresh Arch box**: installs packages (pacman + AUR/yay), symlinks the dotfiles, configures the Sugar-Candy sddm theme. Destructive — guarded by a typed `YES` confirmation, and it refuses to run on non-Linux hosts or without a TTY. |
| `.ssh/` | SSH client config. |

## Installation

* **macOS** — symlink what you need, e.g.
  `ln -s ~/sdots/tmux/.tmux.conf ~/.tmux.conf` (same pattern for `.zshrc` and `.vim`),
  then install tmux plugins with `prefix + I` (tpm).
* **Arch Linux** — run `./lnkScript.sh` on a *fresh* machine only.

Machine-specific values (note paths, PDK paths, anything private) belong in
`~/.local.zshrc`, which is **not tracked by git** and is sourced automatically.

## Highlights

* **tmux status bar** — live CPU/GPU sparklines, RAM and battery-with-time-left,
  in fixed-width fields so nothing shifts as digits change; sampling is throttled
  to stay cheap, and `right-click the clock` collapses the bar and stops sampling.
* **Search-driven workflows** — jump to a note line or a PDF page from inside tmux,
  with fzf previews, opening in vim/zathura at the match.
* **Path-preserving splits** — every tmux split/new-window inherits the current pane's directory.

## Caveats / next steps

1. Use a Makefile for installation (`make install` / `make clean`) instead of hand-run
   symlinks — with explicit targets for both the dotfiles and `homedirScripts/`.
2. Retire the remaining Linux-era bindings (`prefix C-i` runs `iftop` on an iface name
   this machine doesn't have, and it needs `sudo`) or gate them behind a host check.
