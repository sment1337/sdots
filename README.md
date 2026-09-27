# sment's dot files

One branch (`master`/`main` — everything lives on `master` now), one entry
point: **`install.sh`**. The old per-OS branches (`arch mac popOS ubuntu wsl`)
are archived as tags (`archive/<os>`) and then deleted; their content was
merged forward onto `master`, newest copy first, so nothing was lost by
dropping the branches.

## How to use this repo

```sh
git clone <this-repo> ~/sdots && cd ~/sdots
./install.sh            # detects OS, installs missing packages, links dotfiles
./install.sh            # second run is a no-op — safe to re-run
```

`install.sh` detects the OS family (`Darwin` → brew; Pop!_OS → **apt** —
Pop!_OS 22.04 is Ubuntu-based; `arch` → pacman + yay; `ubuntu`/`wsl` → apt;
WSL → apt, headless subset) and installs only what's missing according to
`manifests/<os>.txt`. It then symlinks configs into place:

| Source in repo | Linked to |
|---|---|
| `.zshrc` | `~/.zshrc` |
| `.vim` | `~/.vim` |
| `tmux/` | `~/.tmux` + `~/.tmux.conf` (scripts reference `$HOME/sdots/...`) |
| `i3 polybar rofi nitrogen htop mc picom terminator ranger inkscape gtk-2.0 conky` | `~/.config/<name>` |
| `dconf/user` | `~/.config/dconf/user` (dconf doesn't follow symlinks — verify on first run) |
| `systemd/user` | `~/.config/systemd/user` (Linux only, skipped on WSL) |

## Layout

- `install.sh` — the installer described above.
- `manifests/` — plain package lists per OS family (`arch-aur.txt` is
  AUR-only, installed via `yay` if present). `macos.txt` was seeded from
  `brew leaves` on the Mac — regenerate it if you change what you keep installed.
- `legacy/` — the old hand-written installers (`lnkScript.sh`,
  `setup_environment.sh`). Kept for reference only; **do not run them** —
  `install.sh` replaces both.
- `systemd/user/secure-tunnel@.service` — intentionally references an
  age-encrypted SSH config; it is not a leak. `websock.service` was purged
  during the September 2026 security cleanup — do not resurrect it.
- `tmux/`, `i3/`, `polybar/`, … — configs are linked by `install.sh` as
  described above; edit them here, not in `~/.config`.

## Rules

1. Nothing machine-specific (usernames, home paths, emails, drive-account
   names) may be committed — generate it from `$HOME`/`$USER` or keep it in
   a git-ignored `local.sh`.
2. `install.sh` must stay idempotent: check before installing, `ln -sfn`
   before linking, never `rm -rf`, never pipe `Y`/`N` answers into a
   package manager.
3. Commit with `git config user.email` set to
   `20616301+sment1337@users.noreply.github.com` on every machine — the
   whole point of the history rewrite was to stop attributing commits to
   personal identities.
