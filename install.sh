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

log()  { printf '[install] %s\n' "$*"; }
warn() { printf '[install][WARN] %s\n' "$*" >&2; }
fail() { printf '[install][FAIL] %s\n' "$*" >&2; FAILED_STEPS+=("$*"); }

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
  local os="$1" base="$2" file="$MANIFESTS/$2.txt" pkg missing=()
  [[ -r "$file" ]] || { warn "no manifest $file — skipping package install"; return 0; }
  while read -r pkg; do
    case "$pkg" in ''|\#*) continue ;; esac
    command -v "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done < "$file"
  if [[ ${#missing[@]} -eq 0 ]]; then
    log "$2: everything already installed"
    return 0
  fi
  case "$(pkg_family "$os")" in
    arch)
      if command -v yay >/dev/null 2>&1; then
        log "yay: installing ${missing[*]}"
        yay -S --needed --noconfirm "${missing[@]}" || fail "yay install failed (${missing[*]})"
        [[ -r "$MANIFESTS/arch-aur.txt" ]] && \
          yay -S --needed --noconfirm $(grep -v '^#' "$MANIFESTS/arch-aur.txt" | grep -v '^$' || true) \
          || warn "aur manifest needs manual review if any name is wrong"
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

# ------------------------------------------------------------ dotfile link
link() { # $1 = repo-relative source, $2 = destination under $HOME
  local src="$REPO/$1" dst="$HOME/$2"
  [[ -e "$src" ]] || { warn "missing source $src — skipping"; return 0; }
  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ "$(readlink -f "$dst" 2>/dev/null || true)" == "$(readlink -f "$src" 2>/dev/null || true)" ]]; then
      log "$2 already linked -> $1"
    else
      warn "$2 already exists and is not our symlink — leaving it alone"
    fi
  else
    ln -sfn "$src" "$dst"
    log "linked $2 -> $1"
  fi
}

main() {
  local os family
  os="$(detect_os)"
  log "detected OS family: $os (pkg family: $(pkg_family "$os"))"

  # 1. Packages from the matching manifest.
  install_from_manifest "$os" "$(manifest_for "$os")"

  # 2. Dotfiles.
  link ".zshrc"              ".zshrc"
  link ".vim"                ".vim"
  link "tmux"                ".tmux"            # scripts referenced as $HOME/sdots/tmux/...
  link "tmux/.tmux.conf"     ".tmux.conf"
  link "i3"                  ".config/i3"
  link "polybar"             ".config/polybar"
  link "rofi"                ".config/rofi"
  link "nitrogen"            ".config/nitrogen"
  link "htop"                ".config/htop"
  link "mc"                  ".config/mc"
  link "picom"               ".config/picom"
  link "terminator"          ".config/terminator"
  link "dconf/user"          ".config/dconf/user"
  link "ranger"              ".config/ranger"
  link "inkscape"            ".config/inkscape"
  link "gtk-2.0"             ".config/gtk-2.0"
  link "mimeapps.list"      ".config/mimeapps.list"
  link "user-dirs.dirs"     ".config/user-dirs.dirs"
  link "user-dirs.locale"   ".config/user-dirs.locale"
  link "pavucontrol.ini"    ".config/pavucontrol.ini"   # verify per-distro placement
  # conky configs exist on arch/ubuntu only (per decision); install.sh on
  # popOS/WSL/macOS still links them if present — harmless either way:
  link "conky"               ".config/conky"

  # 3. systemd user units — Linux only, and only with a usable systemctl --user.
  if [[ "$os" == wsl ]]; then
    log "WSL detected — skipping systemd user units (no systemd in WSL)"
  elif systemctl --user -q is-system-running >/dev/null 2>&1 || command -v systemctl >/dev/null 2>&1; then
    link "systemd/user"      ".config/systemd/user"
    systemctl --user daemon-reload 2>/dev/null || warn "units linked; run: systemctl --user daemon-reload && enable --user <units>"
  else
    log "no systemd here — skipping user units"
  fi

  # 4. Reminders.
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
