#!/usr/bin/env bash
# install.sh — detect OS family, install missing packages, link dotfiles.
#
# Contract:
#   * Safe to re-run: every step checks before acting; second run = no-op.
#   * Never pipes "Y" answers into a package manager; uses --noconfirm / -y.
#   * Never writes machine-specific values (usernames, home paths, emails)
#     into anything that gets committed. Anything not derivable from
#     $HOME/$USER belongs in git-ignored local.sh, recreated per machine.
#   * On any failed step, prints which step failed and exits non-zero
#     instead of continuing with a half-finished install.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$REPO/manifests"
FAILED_STEPS=()
# detect_os() result (arch|ubuntu|popos|wsl|macos|unknown), set by main(). link()'s
# per-file OS tags match against this.
OS_ID=""
# SDOTS_YES=1 or --yes skips the interactive package-install confirmation.
ASSUME_YES="${SDOTS_YES:-0}"

log()  { printf '[install] %s\n' "$*"; }
warn() { printf '[install][WARN] %s\n' "$*" >&2; }
fail() { printf '[install][FAIL] %s\n' "$*" >&2; FAILED_STEPS+=("$*"); }

# confirm "prompt" — Y default; reads from the terminal so it works even if
# stdout is piped. Returns 0 on yes, 1 on no/EOF. Honours ASSUME_YES.
confirm() {
  [[ "$ASSUME_YES" == 1 ]] && return 0
  if ! : 2>/dev/null < /dev/tty; then
    warn "no terminal available — cannot confirm; re-run with --yes to force install"
    return 1
  fi
  local reply
  printf '%s [Y/n] ' "$1" > /dev/tty
  IFS= read -r reply < /dev/tty || return 1   # EOF/Ctrl-D => decline
  case "$reply" in ''|y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------- OS detect
detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos; return ;;
    Linux)  ;;
    *) echo unknown; return ;;
  esac
  if grep -qi microsoft /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    echo wsl; return
  fi
  local id=""
  [[ -r /etc/os-release ]] && id="$(. /etc/os-release && echo "${ID:-}")"
  case "$id" in
    arch|antergos|garuda|reborn|endeavouros|cachyos|manjaro) echo arch ;;
    pop)  echo popos ;;   # Pop!_OS 22.04 is Ubuntu-based => apt family
    ubuntu|debian|elementary|linuxmint) echo ubuntu ;;
    *)    echo unknown ;;
  esac
}

pkg_family() {  # arch | apt | brew | none
  case "$1" in
    arch)  echo arch ;;
    ubuntu|popos|wsl) echo apt ;;
    macos) echo brew ;;
    *)     echo none ;;
  esac
}

# ------------------------------------------------------- package install
manifest_for() { case "$1" in arch) echo arch;; popos) echo popOS;; ubuntu|wsl) echo "$1";; macos) echo macos;; esac; }

install_from_manifest() { # $1 = os name, $2 = manifest basename
  local os="$1" base="$2" file="$MANIFESTS/$2.txt" pkg missing=() family
  file="$MANIFESTS/$2.txt"
  family="$(pkg_family "$os")"
  [[ -r "$file" ]] || { warn "no manifest $file — skipping package install"; return 0; }
  local line pkg cmd
  while read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    if [[ "$line" == *:* ]]; then pkg="${line%%:*}"; cmd="${line##*:}"
    else pkg="$line"; cmd="$line"; fi
    case "$pkg" in */*) warn "$pkg is a tap package — install manually"; continue ;; esac
    case "$family" in
      brew) brew list --formula --versions "$pkg" 2>/dev/null | grep -q . || missing+=("$pkg") ;;
      *)    command -v "$cmd" >/dev/null 2>&1 || missing+=("$pkg") ;;
    esac
  done < "$file"
  if [[ ${#missing[@]} -eq 0 ]]; then
    log "$2: everything already installed"
    return 0
  fi
  case "$family" in
    arch)
      if command -v yay >/dev/null 2>&1; then
        local aur_pkgs=()
        [[ -r "$MANIFESTS/arch-aur.txt" ]] && \
          mapfile -t aur_pkgs < <(grep -vE '^[[:space:]]*(#|$)' "$MANIFESTS/arch-aur.txt")
        log "packages missing on this machine:"
        printf '  repo: %s\n' "${missing[*]}"
        [[ ${#aur_pkgs[@]} -gt 0 ]] && printf '  aur:  %s\n' "${aur_pkgs[*]}"
        if ! confirm "Install these packages?"; then
          log "arch: package install declined — skipping"
          return 0
        fi
        log "yay: installing ${missing[*]}"
        yay -S --needed --noconfirm "${missing[@]}" || fail "yay install failed (${missing[*]})"
        if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
          yay -S --needed --noconfirm "${aur_pkgs[@]}" \
            || warn "aur manifest needs manual review if any name is wrong"
        fi
      else
        warn "yay not found; install yay manually, then re-run (skipping: ${missing[*]})"
      fi ;;
    apt)
      if [[ "$(id -u)" -eq 0 ]] || sudo -n true 2>/dev/null; then
        log "apt: installing ${missing[*]}"
        sudo -n apt-get update && sudo -n apt-get install -y --no-install-recommends "${missing[@]}" \
          || fail "apt install failed (${missing[*]})"
      else
        warn "need sudo: install manually: ${missing[*]}"
      fi ;;
    brew)
      if command -v brew >/dev/null 2>&1; then
        log "brew: installing ${missing[*]}"
        brew install "${missing[@]}" || fail "brew install failed (${missing[*]})"
      else
        warn "brew not found; install Homebrew, then re-run (skipping: ${missing[*]})"
      fi ;;
    none)
      warn "unknown OS '$os' — cannot install packages automatically; missing: ${missing[*]}" ;;
  esac
}

# ------------------------------------------- version-pinned tool upstream ships
# fzf — .zshrc does `source <(fzf --zsh)`, but the `--bash/--zsh` flags only exist
# in fzf >= 0.48: apt on ubuntu/popOS/WSL ships 0.44, which aborts with
# "unknown option: --zsh" and silently leaves key bindings + completion unloaded
# (your _fzf_comprun, preview-page-down and --border=rounded all need >= 0.48 too).
# We shadow the distro binary instead of patching .zshrc with a version probe; both
# ~/.profile:26 and ~/.zshrc:16 already put ~/.local/bin first on $path.
install_latest_fzf() {
  local dst="$HOME/.local/bin/fzf" os arch ver tag tmp sys
  case "$(uname -s)" in
    Linux)  os=linux ;;
    Darwin) os=darwin ;;
    *) warn "no fzf release for $(uname -s) — install fzf >= 0.48 manually"; return 0 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64)   arch=amd64 ;;
    aarch64|arm64)  arch=arm64 ;;
    *) warn "no fzf release for $(uname -m) — install fzf >= 0.48 manually"; return 0 ;;
  esac

  # Capability probe, not version arithmetic: what .zshrc needs is the `--zsh` flag.
  if [[ -x "$dst" ]] && "$dst" --help 2>&1 | grep -q -- '--zsh'; then
    log "fzf $("$dst" --version | awk '{print $1}') already managed here — nothing to do"
    return 0
  fi
  sys="$(command -v fzf 2>/dev/null || true)"
  if [[ -n "$sys" && "$sys" != "$dst" ]] && "$sys" --help 2>&1 | grep -q -- '--zsh'; then
    log "fzf on PATH ($("$sys" --version | awk '{print $1}')) already supports --zsh — nothing to do"
    return 0
  fi

  ver="$(curl -fsSL --max-time 20 https://api.github.com/repos/junegunn/fzf/releases/latest 2>/dev/null \
          | sed -n 's/.*"tag_name":[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/p' | head -1)" || ver=""
  if [[ -z "$ver" ]]; then
    fail "could not resolve the latest fzf release (offline? GitHub API limit?) — .zshrc needs fzf >= 0.48, installed: ${sys:-none}"
    return 0
  fi

  # Upstream publishes no checksums for these assets, so verification is running it.
  tmp="$(mktemp -d)"
  if curl -fsSL --max-time 60 \
       "https://github.com/junegunn/fzf/releases/download/v${ver}/fzf-${ver}-${os}_${arch}.tar.gz" \
     | tar -xzC "$tmp" fzf \
     && mkdir -p "$(dirname "$dst")" \
     && install -m 755 "$tmp/fzf" "$dst"; then
    if "$dst" --help 2>&1 | grep -q -- '--zsh'; then
      log "installed fzf $("$dst" --version | awk '{print $1}') -> ${dst#$HOME/} (shadows ${sys:-nothing})"
    else
      fail "downloaded fzf $ver still lacks --zsh — inspect $dst"
    fi
  else
    fail "could not fetch fzf v${ver} for ${os}_${arch}"
  fi
  rm -rf "$tmp"
}

# ---------------------------------------------------- dotfile link (OS-scoped)
# wanted_by <tag...> — does THIS machine want the file? Tags are detect_os ids
# (arch, ubuntu, popos, wsl, macos) plus two aliases: "linux" = any Linux family,
# "any" = every OS. An untagged link() call means "any", so portable files
# (.zshrc, .vim, tmux, mc) stay untagged and read exactly as before.
wanted_by() {
  local t
  for t in "$@"; do
    case "$t" in
      any) return 0 ;;
      linux) [[ ",arch,ubuntu,popos,wsl," == *","$OS_ID","* ]] && return 0 ;;
      *)     [[ "$t" == "$OS_ID" ]] && return 0 ;;
    esac
  done
  return 1
}

# link <repo-relative source> <dest under $HOME> [os tags...]
link() { # $3+ = which OS families want it; omitted = all (see wanted_by)
  local rel_s="$1" rel_d="$2" src="$REPO/$1" dst="$HOME/$2"; shift 2
  [[ -e "$src" ]] || { warn "missing source $src — skipping"; return 0; }
  # A file nothing on this OS parses isn't a config, it's litter. The check runs
  # BEFORE mkdir too, so ~/.config stays as empty as the platform's tooling is.
  if [[ $# -gt 0 ]] && ! wanted_by "$@"; then
    log "$rel_d not used on $OS_ID — skipping"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ "$(readlink "$dst" 2>/dev/null || true)" == "$src" ]]; then
      log "$rel_d already linked -> $rel_s"
    else
      warn "$rel_d already exists and is not our symlink — leaving it alone"
    fi
  else
    ln -sfn "$src" "$dst"
    log "linked $rel_d -> $rel_s"
  fi
}

main() {
  local os family arg
  for arg in "$@"; do
    case "$arg" in
      -y|--yes) ASSUME_YES=1 ;;
      *) warn "unknown argument: $arg (supported: --yes)" ;;
    esac
  done
  os="$(detect_os)"
  OS_ID="$os"
  log "detected OS family: $os (pkg family: $(pkg_family "$os"))"

  # 1. Packages from the matching manifest.
  install_from_manifest "$os" "$(manifest_for "$os")"

  # 1b. Tools whose distro build is too old for our dotfiles (fzf). Re-runs are a
  #     no-op; to force an upgrade again: rm ~/.local/bin/fzf && ./install.sh
  install_latest_fzf

  # 2. Dotfiles — each link is tagged with the OS families that actually parse it;
  #    untagged = wanted everywhere (see wanted_by). To bring one to macOS later
  #    (e.g. `brew install ranger`), append `macos` to its tag list and nothing else changes.
  link ".zshrc"              ".zshrc"
  link ".vim"                ".vim"
  link "tmux"                ".tmux"            # scripts referenced as $HOME/sdots/tmux/...
  link "tmux/.tmux.conf"     ".tmux.conf"
  link "i3"                  ".config/i3"                linux
  link "polybar"             ".config/polybar"          linux
  link "rofi"                ".config/rofi"              linux
  link "nitrogen"            ".config/nitrogen"         linux
  link "htop"                ".config/htop"             linux   # macOS runs btop (see macos.txt)
  link "mc"                  ".config/mc"                          # untagged: mc reads $XDG_CONFIG_HOME on any OS
  link "picom"               ".config/picom"              linux
  link "terminator"          ".config/terminator"        linux
  link "dconf/user"          ".config/dconf/user"        linux   # no gsettings database on macOS
  link "ranger"              ".config/ranger"            linux   # not in macos.txt yet — add `macos` if that changes
  link "inkscape"            ".config/inkscape"          linux   # macOS Inkscape prefs live in ~/Library/Preferences/org.inkscape.Inkscape/
  link "gtk-2.0"             ".config/gtk-2.0"           linux
  link "mimeapps.list"      ".config/mimeapps.list"      linux   # no xdg-open / shared-mime-info here
  link "user-dirs.dirs"     ".config/user-dirs.dirs"     linux   # nothing on macOS parses XDG dirs
  link "user-dirs.locale"   ".config/user-dirs.locale"    linux
  link "pavucontrol.ini"    ".config/pavucontrol.ini"    linux   # PulseAudio-only mixer
  # conky configs exist on arch/ubuntu only (per decision); macOS/popOS never
  # installed conky, so the link was pure litter there:
  link "conky"               ".config/conky"             linux
  # TigerVNC (1.16+ layout: config in ~/.config/tigervnc; password is a
  # machine-local file there too — created once with `vncpasswd`)
  link "vnc/config"           ".config/tigervnc/config"   linux

  # 3. Plugin managers.
  #  3a. tmux plugins: clone every `set -g @plugin 'user/repo'` from
  #      .tmux.conf into ~/.tmux/plugins/<repo>. (tpm's own install_plugins
  #      can't run here: it reads TMUX_PLUGIN_MANAGER_PATH via
  #      `tmux start-server`, which never sources .tmux.conf, so the
  #      variable is undefined and it aborts.)
  if command -v git >/dev/null 2>&1 && [[ -r "$REPO/tmux/.tmux.conf" ]]; then
    while read -r plug; do
      [[ -z "$plug" || "$plug" == \#* ]] && continue
      name="${plug##*/}"
      dest="$HOME/.tmux/plugins/$name"
      if [[ -d "$dest/.git" ]]; then
        log "tmux plugin $name already cloned"
      else
        log "cloning $plug -> $dest"
        mkdir -p "$(dirname "$dest")"
        git clone --depth 1 --single-branch "https://github.com/$plug" "$dest" \
          || fail "clone failed for $plug — run prefix+I inside tmux to install it"
      fi
    done < <(grep -E "^[[:space:]]*set(-option)?[[:space:]]+-g[[:space:]]+@plugin" "$REPO/tmux/.tmux.conf" \
             | sed -E "s/.*@plugin[[:space:]]+'([^']+)'.*/\1/" | sort -u)
  else
    warn "git or tmux config missing — install tmux plugins manually"
  fi

  if command -v vim >/dev/null 2>&1; then
    log "installing vim plugins (vim-plug)"
    # Headless normal mode (not -es/-Es Ex mode: vim-plug's s:prepare errors
    # there with E31) + --sync so PlugInstall waits for jobs/hooks, and stdin
    # closed so nothing waits on a tty. timeout bounds any hook stall.
    #
    # NB: redirect stderr AS WELL AS stdout (2>&1). Vim only honours our closed
    # stdin while it has no console to fall back on: if fd 2 is still the pty,
    # vim's console setup opens /dev/tty and dup2's it over fd 0 — so </dev/null
    # silently stops applying, and the hit-enter prompt that PlugInstall's own
    # progress output ("Installing plugins", fzf's installer, markdown-preview's
    # curl bar) raises blocks on a keyboard read. Since vim also moves itself into
    # its own process group (mch_init), that pgrp is a *background* pgrp of the
    # terminal and the read earns it SIGTTIN: state T in `ps`, invisible stall
    # until timeout fires. With no tty on any stdio fd vim stays fully dumb.
    timeout 600 vim -u "$REPO/.vim/.vimrc" -n -i NONE --not-a-term \
      +"set nomore" +"PlugInstall --sync" +"qa!" </dev/null >/dev/null 2>&1 \
      || warn "PlugInstall failed — open vim and run :PlugInstall manually"
  fi

  #  3c. native-pack vim plugins: unlike vim-plug these are NOT fetched by
  #      :PlugInstall, they live under .vim/pack/<ns>/start/<repo> where vim
  #      loads them automatically. They cannot be committed the normal way,
  #      and a plain "git add" of a clone there stores only an embed-gitlink
  #      (mode 160000) that materialises as an EMPTY dir in fresh clones —
  #      which is exactly how vim-gitgutter vanished from new machines. So we
  #      keep them out of git entirely (.gitignore) and clone here; an
  #      existing checkout (e.g. the original Mac clone) is left alone.
  for plug in "airblade/vim-gitgutter"; do
    name="${plug##*/}"
    dest="$REPO/.vim/pack/${plug%/*}/start/$name"
    if [[ -d "$dest/.git" ]]; then
      log "vim pack plugin $name already cloned"
    elif [[ -e "$dest" && -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
      warn "$dest exists but is not a git clone — inspect manually (rm it and re-run to fetch)"
    else
      log "cloning $plug -> ${dest#"$REPO/"}"
      mkdir -p "$(dirname "$dest")"
      git clone --depth 1 --single-branch "https://github.com/$plug" "$dest" \
        || fail "clone failed for $plug — run: git clone https://github.com/$plug '$dest'"
    fi
  done

  # 4. systemd user units — Linux only, and only with a usable systemctl --user.
  if [[ "$os" == wsl ]]; then
    log "WSL detected — skipping systemd user units (no systemd in WSL)"
  elif systemctl --user -q is-system-running >/dev/null 2>&1 || command -v systemctl >/dev/null 2>&1; then
    link "systemd/user"      ".config/systemd/user"
    systemctl --user daemon-reload 2>/dev/null || warn "units linked; run: systemctl --user daemon-reload && enable --user <units>"
  else
    log "no systemd here — skipping user units"
  fi

  # 4b. pacman hook — Arch only. tmux/scripts/sysstats.sh reads Intel iGPU
  #     utilisation via intel_gpu_top, which needs CAP_PERFMON as a *file*
  #     capability; upgrades replace the binary and drop it, so a libalpm hook
  #     re-applies it. Needs root to place (/etc is not $HOME-linkable), hence
  #     `install` with sudo -n rather than the link() helper.
  if [[ "$os" == arch ]]; then
    hook_src="$REPO/pacman/hooks/intel-gpu-top-perfmon.hook"
    hook_dst="/etc/pacman.d/hooks/intel-gpu-top-perfmon.hook"
    if [[ ! -r "$hook_src" ]]; then
      warn "pacman hook source missing — skipping"
    elif [[ -f "$hook_dst" ]] && cmp -s "$hook_src" "$hook_dst"; then
      log "pacman hook already installed ($hook_dst)"
    elif sudo -n true 2>/dev/null; then
      sudo -n install -D -m 644 "$hook_src" "$hook_dst" \
        && log "installed pacman hook -> $hook_dst" \
        || fail "could not install pacman hook to $hook_dst"
    else
      warn "no passwordless sudo; install the hook manually: sudo install -Dm644 '$hook_src' '$hook_dst'"
    fi
  fi

  # 4c. TigerVNC + noVNC system setup — Arch only. Makes the browser-VNC
  #     desktop reproducible: systemd-managed Xvnc :1 (vncserver@:1) plus a
  #     websockify bridge (websock@$USER -> novnc on :6080). /etc files are
  #     root-owned policy, installed via sudo -n like the pacman hook.
  #     NB: ~/.config/tigervnc/passwd is machine-local — create once with
  #     `vncpasswd`. Full background: vnc/README.md.
  if [[ "$os" == arch ]] && command -v systemctl >/dev/null 2>&1; then
    mand_src="$REPO/vnc/vncserver-config-mandatory"
    mand_dst="/etc/tigervnc/vncserver-config-mandatory"
    ws_src="$REPO/vnc/websock@.service"
    ws_dst="/etc/systemd/system/websock@.service"
    users_file="/etc/tigervnc/vncserver.users"
    if ! sudo -n true 2>/dev/null; then
      warn "no passwordless sudo — VNC system setup skipped; see vnc/README.md for manual steps"
    else
      if [[ -f "$mand_dst" ]] && cmp -s "$mand_src" "$mand_dst"; then
        log "vncserver-config-mandatory already installed"
      else
        sudo -n install -D -m 644 "$mand_src" "$mand_dst" \
          && log "installed $mand_dst" \
          || fail "could not install $mand_dst"
      fi
      if [[ -f "$ws_dst" ]] && cmp -s "$ws_src" "$ws_dst"; then
        log "websock@.service already installed"
      else
        sudo -n install -D -m 644 "$ws_src" "$ws_dst" \
          && sudo -n systemctl daemon-reload \
          && log "installed $ws_dst (+daemon-reload)" \
          || fail "could not install $ws_dst"
      fi
      if ! grep -qx ":1=$USER" "$users_file" 2>/dev/null; then
        echo ":1=$USER" | sudo -n tee -a "$users_file" >/dev/null \
          && log "added :1=$USER to $users_file" \
          || fail "add ':1=$USER' to $users_file manually"
      else
        log "$users_file already maps :1=$USER"
      fi
      for u in "vncserver@:1.service" "websock@$USER.service"; do
        if sudo -n systemctl is-enabled -q "$u" 2>/dev/null; then
          log "$u already enabled"
        else
          sudo -n systemctl enable --now "$u" \
            && log "enabled $u" \
            || fail "enable failed for $u"
        fi
      done
      [[ -f "$HOME/.config/tigervnc/passwd" ]] \
        || log "reminder: run 'vncpasswd' once to create ~/.config/tigervnc/passwd"
    fi
  fi

  # 5. Reminders.
  if command -v zsh >/dev/null 2>&1 && [[ "${SHELL:-}" != *zsh* ]]; then
    log "reminder: set login shell: chsh -s $(command -v zsh)"
  fi

  if [[ ${#FAILED_STEPS[@]} -gt 0 ]]; then
    printf '[install] %d step(s) FAILED:\n' "${#FAILED_STEPS[@]}" >&2
    printf '  - %s\n' "${FAILED_STEPS[@]}" >&2
    exit 1
  fi
  log "done."
}

main "$@"
