#!/usr/bin/env bash
# sysstats.sh — feed tmux status bar sparklines (macOS + Linux)
# usage: sysstats.sh cpu|gpu|ram|bat
#
# History lives in $HOME/.cache/tmux-sysstats/{cpu,gpu}.hist (one value per line).
# Each sampler dispatches on `uname`: the Darwin code paths are unchanged, the
# Linux ones read /proc, /sys and vendor CLIs. Unknown OS => plain "n/a".

set -u
HIST_DIR="$HOME/.cache/tmux-sysstats"
BARS=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
OS_TAG="$(uname -s)"

# A probe that cannot know the answer must say so explicitly (a bare "n/a" on a
# machine with a GPU is just noise), and keep the fixed 12-cell field width so
# the status bar never shifts. The bar already prints the "gpu" label, so these
# strings are reasons only.
na() { # na <reason>
  case "$1" in
    no-tool) printf '%-12s' 'n/a:no-smi' ;;   # NVIDIA tool missing / unusable
    igfx)    printf '%-12s' 'n/a:igfx' ;;     # Intel/AMD iGPU, no readable ctr
    *)       printf '%-12s' 'n/a' ;;
  esac
}

# The battery text contains emoji, which are one character but TWO terminal
# columns. Display width therefore equals (character count + number of emoji),
# which is what pad_bat computes — but only if the shell counts characters, so
# make sure we run in a UTF-8 locale when one exists (else ${#var} counts bytes
# and every padded field degenerates). BAT_CELLS is the historical width.
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *[Uu][Tt][Ff]*8*) : ;;
  *) for __l in C.UTF-8 en_US.UTF-8; do
       if locale -a 2>/dev/null | grep -qixF "$__l"; then export LC_ALL="$__l"; break; fi
     done ;;
esac
BAT_CELLS=15

# Sampling interval, in seconds. The daemon re-reads the tmux user option on
# every round; garbage/unset values fall back to the 5s default.
refresh_secs() {
  local s
  s="$(tmux show -gqv @status_refresh 2>/dev/null)"
  case "$s" in ''|*[!0-9]*) s=5 ;; esac
  (( s < 1 || s > 300 )) && s=5
  echo "$s"
}

pad_bat() { # pad_bat <varname> — right-pad battery text to $BAT_CELLS cells
  local __out="${!1}" __wide __cells __pad
  __wide=$(printf '%s' "$__out" | grep -oE '(🔋|🪫|🔌|⚡|⏳)' | wc -l | tr -d ' ')
  __cells=$(( ${#__out} + __wide ))
  __pad=$(( BAT_CELLS - __cells )); (( __pad < 0 )) && __pad=0
  printf '%s%*s' "$__out" "$__pad" ''
}

spark() { # spark <histfile> <value>
  local file="$1" val="$2" hist idx out
  mkdir -p "$HIST_DIR"
  # keep newest + 6 previous = 7 lines total (7 bars)
  { echo "$val"; tail -n 7 "$file" 2>/dev/null | head -n 6; } > "$file.tmp" && mv "$file.tmp" "$file"
  hist=()
  while read -r v; do hist+=("$v"); done < "$file"
  # oldest -> newest, so the graph grows left-to-right toward the value
  out=""
  for (( i=${#hist[@]}-1; i>=0; i-- )); do
    v="${hist[i]}"
    idx=$(( (v * 8 + 50) / 100 ))
    (( idx > 7 )) && idx=7
    out+="${BARS[$idx]}"
  done
  # value left-aligned in a fixed 4-wide slot ("100%" max) right after the
  # graph: snug for small values, and 1->2->3 digits never shift the bars
  # (total field is always 7 bars + 1 + 4 = 12 cells)
  printf '%s %-4s' "$out" "${val}%"
}

sparkview() { # sparkview <histfile> — render current history, no new sample
  local file="$1" hist out v
  [[ -s "$file" ]] || { printf '%-12s' '-'; return; }
  hist=()
  while read -r v; do hist+=("$v"); done < "$file"
  out=""
  for (( i=${#hist[@]}-1; i>=0; i-- )); do
    v="${hist[i]}"
    idx=$(( (v * 8 + 50) / 100 ))
    (( idx > 7 )) && idx=7
    out+="${BARS[$idx]}"
  done
  printf '%s %-4s' "$out" "${hist[0]}%"
}

# ------------------------------------------------------------ Linux samplers
linux_cpu() { # two /proc/stat reads 0.2s apart -> aggregate busy %
  local a i b idle tot
  read -r _ a[0] a[1] a[2] a[3] a[4] a[5] a[6] a[7] _ < /proc/stat
  sleep 0.2
  read -r _ b[0] b[1] b[2] b[3] b[4] b[5] b[6] b[7] _ < /proc/stat
  idle=$(( (b[3]+b[4]) - (a[3]+a[4]) ))   # idle + iowait
  tot=0
  for (( i=0; i<8; i++ )); do tot=$(( tot + b[i] - a[i] )); done
  (( tot <= 0 )) && { echo 0; return; }
  awk -v t="$tot" -v i="$idle" 'BEGIN{v=(t-i)*100/t; if (v<0) v=0; if (v>100) v=100; printf "%d", v}'
}

linux_gpu() { # echoes 0-100 on success; empty when no probe works
  local val="" f c
  # 1. NVIDIA proprietary driver (same signal as conky/getGPUpct.sh)
  if command -v nvidia-smi >/dev/null 2>&1; then
    local csv=""
    csv=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
    val=$(printf '%s' "$csv" | tr -dc '0-9')
    # a bogus nvidia-smi in $PATH (or GPU powered off) must not yield 0%/garbage
    # 10# forces base 10 so a zero-padded reading ("08") is not read as octal
    if [[ "$val" =~ ^[0-9]+$ ]] && (( 10#$val <= 100 )); then echo "$((10#$val))"; return; fi
    na no-tool; return   # tool present but no reading -> generic placeholder
  fi
  # 2. amdgpu (and newer i915) atomics: sysfs busy percentage (no sudo, ~0ms)
  for f in /sys/class/drm/card[0-9]*/device/gpu_busy_percent; do
    [[ -r "$f" ]] || continue
    val=$(<"$f")
    if [[ "$val" =~ ^[0-9]+$ ]]; then echo "$val"; return; fi
  done
  # 3. Intel iGPU: intel_gpu_top (package intel-gpu-tools) render-engine
  #    residency. Reading the PMU needs CAP_PERFMON: either grant it to the
  #    binary once (sudo setcap cap_perfmon+ep $(command -v intel_gpu_top), note
  #    package upgrades drop it again) or rely on passwordless sudo fallback.
  #    Cached ~20s because each sampling run takes about a second.
  # Debian/Ubuntu install it as /usr/sbin/intel_gpu_top, which is typically not
  # in a user's PATH, so look there explicitly.
  local IGT=""
  IGT="$(command -v intel_gpu_top 2>/dev/null)"
  [[ -z "$IGT" ]] && for c in /usr/bin/intel_gpu_top /usr/sbin/intel_gpu_top; do
    [[ -x "$c" ]] && { IGT="$c"; break; }
  done
  if [[ -n "$IGT" ]]; then
    local cf="$HIST_DIR/intel.val" out="" raw="" txt="" age now
    mkdir -p "$HIST_DIR"
    now=$(date +%s)
    age=$(( now - $(stat -c %Y "$cf" 2>/dev/null || echo 0) ))
    if [[ -f "$cf" ]] && (( age < 20 )); then
      out=$(<"$cf")
    else
      # JSON, one sample set then exit: running time = (n-1) * period.
      # NB: do NOT pass -l here — in current builds it forces the text layout
      # and suppresses JSON. Text output has no stable per-engine label.
      raw=$(timeout 4 "$IGT" -J -n 2 -s 600 -o /dev/stdout 2>/dev/null)
      if [[ -z "$raw" ]] && sudo -n true 2>/dev/null; then
        raw=$(sudo -n timeout 4 "$IGT" -J -n 2 -s 600 -o /dev/stdout 2>/dev/null)
      fi
      # Layout: "engines" (older builds: "classes") -> "Render/3D": {"busy": N}
      # -n 2 prints a short first period plus one full period; keep the LAST
      # busy reading so the partial warm-up sample is not used.
      out=$(printf '%s\n' "$raw" | awk '
        /"engines"|"classes"/ {inb=1; got=0}          # a new period sample starts
        inb && !got && /"Render/ {get=1}              # its Render engine entry
        get && /"busy"[^0-9]*[0-9]/ {   # capture ONCE per sample, before
          t=$0; sub(/.*"busy"[^0-9]*/, "", t)   # the digits after "busy" are
          if (match(t,/[0-9]+/)) v=substr(t,RSTART,RLENGTH)  # the value only —
          get=0; got=1                          # NOT the 3 in "Render/3D"
        }
        END { if (v != "") print int(v) }')
      [[ "$out" =~ ^[0-9]+$ ]] && printf '%s\n' "$out" > "$cf"
    fi
    [[ "$out" =~ ^[0-9]+$ ]] && { echo "$out"; return; }
  fi
  # 4. No probe answered. Distinguish "integrated Intel/AMD iGPU with no
  #    readable counter" from "no vendor tool installed at all".
  local d dclass seen=0 nvidia=0
  for d in /sys/bus/pci/devices/*; do
    dclass="$(cat "$d/class" 2>/dev/null)"
    case "$dclass" in
      0x0300*|0x0302*)                       # VGA or 3D controller
        seen=1
        [[ "$(cat "$d/vendor" 2>/dev/null)" == 0x10de ]] && nvidia=1 ;;
    esac
  done
  if (( seen )) && (( ! nvidia )); then na igfx; else na no-tool; fi
}

linux_ram() { # same shape as btop/htop: used = MemTotal - MemAvailable
  local t a
  t=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
  a=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
  [[ -z "$t" ]] && { echo "0/0 GiB"; return; }
  awk -v t="$t" -v a="${a:-$t}" \
    'BEGIN{printf "%.1f/%.1f GiB", (t-a)/1048576, t/1048576}'
}

linux_bat() { # /sys/class/power_supply/BAT*, upower preferred for time-left
  local b pct="" st="" out icon left mins dir=/sys/class/power_supply f
  [[ -d "$dir" ]] || { out='🔌 AC'; pad_bat out; return; }
  for b in "$dir"/BAT*; do
    [[ -e "$b" ]] || continue
    # cat, not $(<file): some kernels expose BAT0 as a symlink/dir, and an
    # unreadable attribute must abort this entry instead of emitting "0%"
    pct="$(cat "$b/capacity" 2>/dev/null | tr -dc '0-9')"
    [[ "$pct" =~ ^[0-9]+$ ]] || continue
    st="$(cat "$b/status" 2>/dev/null)"
    mins=""
    # older kernels: time_to_empty_now (minutes), if present and plausible
    f="$b/time_to_empty_now"
    [[ -r "$f" ]] && mins="$(cat "$f" 2>/dev/null | tr -dc '0-9')"
    break
  done
  if [[ ! "$pct" =~ ^[0-9]+$ ]]; then out='🔌 AC'; pad_bat out; return; fi
  # time-to-empty/full from upower (more reliable than sysfs on laptops);
  # avoid `local $(cmd)` — that would re-declare the whole local list
  if command -v upower >/dev/null 2>&1; then
    local up="" key="Time to empty"
    [[ "$st" == *Charg* ]] && key="Time to full"
    up=$(upower -i "$(upower -e 2>/dev/null | grep -i bat | head -1)" 2>/dev/null \
         | awk -F'[: ]+' -v k="$key" '$0 ~ k {print $2; exit}')
    [[ "$up" =~ ^[0-9]+$ ]] && (( up > 0 )) && mins="$up"
  fi
  (( pct <= 20 )) && icon="🪫" || icon="🔋"
  case "$st" in
    Discharging)
      if [[ "$mins" =~ ^[0-9]+$ ]] && (( mins > 0 )); then
        left=" ⏳$(printf '%d:%02d' $((mins/60)) $((mins%60)))"
      else left=""; fi
      out="$icon $pct%$left" ;;
    'Full'|'Not charging')
      out="$icon $pct% ⚡" ;;
    *) # Charging (or status unknown but battery present)
      if [[ "$mins" =~ ^[0-9]+$ ]] && (( mins > 0 )); then
        left=" ↑$(printf '%d:%02d' $((mins/60)) $((mins%60)))"
      else left=" ↑"; fi
      out="$icon $pct%$left" ;;
  esac
  pad_bat out
}

case "${1:-}" in
  cpu)
    if [[ "$OS_TAG" == Darwin ]]; then
      # top -l1 samples for ~1s; CPU usage = 100 - idle (aggregate 0-100%)
      val=$(top -l1 -n0 | awk -F',' '/CPU usage/{n=split($3,a," "); id=a[1]; sub(/%/,"",id); v=100-id; if (v<0||v>100) v=0; printf "%d", v}')
    else
      val=$(linux_cpu)
    fi
    [[ -z "$val" ]] && val=0
    spark "$HIST_DIR/cpu.hist" "$val"
    ;;
  gpu)
    if [[ "$OS_TAG" == Darwin ]]; then
      # Preferred: ioreg PerformanceStatistics on Apple Silicon (no sudo,
      # ~20ms). "Device Utilization %" is the aggregate GPU busy percentage.
      val=$(ioreg -r -d 2 -c AGXAccelerator -l -w 0 2>/dev/null \
            | grep -oE '"Device Utilization %"=[0-9]+' | head -1 | cut -d= -f2)
      # Fallback: sudo powermetrics, if passwordless sudo exists
      if [[ -z "$val" ]] && sudo -n true 2>/dev/null; then
        val=$(sudo -n powermetrics --samplers gpu_util -i 1000 -n 1 2>/dev/null \
              | grep -oE 'GPU core utilization: [0-9.]+ %' | head -1 | awk -F'[:%]' '{printf "%d", $2}')
      fi
    else
      val=$(linux_gpu)
      # linux_gpu prints a formatted placeholder when it has no answer
      [[ "$val" == gpu\ * || "$val" == n/a* ]] && { printf '%-12s' "$val"; exit 0; }
    fi
    if [[ -n "$val" ]]; then
      spark "$HIST_DIR/gpu.hist" "$val"
    else
      printf '%-12s' "n/a"
    fi
    ;;
  ram)
    if [[ "$OS_TAG" != Darwin ]]; then linux_ram; exit 0; fi
    # match btop (macOS): used = active + wired + compressed (inactive/
    # speculative/purgeable are reclaimable, not counted as used);
    # compressor counted at logical (stored) size
    psz=$(sysctl -n hw.pagesize)
    total_b=$(sysctl -n hw.memsize)
    read -r act wcd comp <<<"$(vm_stat | awk '/^Pages active:/{a=$NF} /^Pages wired down:/{w=$NF} /^Pages stored in compressor:/{c=$NF} END{print a+0, w+0, c+0}')"
    used=$(awk -v a="$act" -v w="$wcd" -v c="$comp" -v ps="$psz" \
      'BEGIN{u=(a+w+c)*ps; if (u<0) u=0; printf "%.0f", u/1073741824}')
    total=$(awk -v t="$total_b" 'BEGIN{printf "%.0f", t/1073741824}')
    echo "$used/$total GiB"
    ;;
  bat)
    [[ "$OS_TAG" != Darwin ]] && { linux_bat; exit 0; }
    line=$(pmset -g batt | tail -1)
    pct=$(echo "$line" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
    if [[ -z "$pct" ]]; then
      out="🔌 AC" # no battery
    else
      # battery emoji by level
      if (( pct <= 20 )); then icon="🪫"; else icon="🔋"; fi
      if [[ "$line" == *discharging* ]]; then
        left=$(echo "$line" | grep -oE '[0-9]+:[0-9]+ remaining' | head -1 | awk '{print $1}')
        [[ -n "$left" ]] && out="$icon $pct% ⏳$left" || out="$icon $pct%"
      elif [[ "$line" == *"AC attached"* ]]; then
        out="$icon $pct% ⚡" # on AC, full or charging
      else # charging, not full
        left=$(echo "$line" | grep -oE '[0-9]+:[0-9]+ remaining' | head -1 | awk '{print $1}')
        [[ -n "$left" ]] && out="$icon $pct% ↑$left" || out="$icon $pct% ↑"
      fi
    fi
    pad_bat out
    ;;
  tick)
    # One sampling+render pass (daemon runs this every 5s; the click-to-hide
    # toggle runs it once for an instant update).
    # hidden mode: right side shrinks to just the clock, no sampling at all
    if [[ "$(tmux show -gqv @status_hidden 2>/dev/null)" == "1" ]]; then
      tmux set -g status-right '#[fg=colour191,bold]%I:%M %p' 2>/dev/null
      exit 0
    fi
    # tick counter in a file (tick may run as a fresh process each time);
    # top -l1 is the expensive sample (~0.4 CPU-s), so it runs every other
    # tick — the cpu graph then updates at 10s resolution
    nfile="$HIST_DIR/n"
    n=$(( $(cat "$nfile" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$nfile"
    if (( n % 2 == 0 )); then cpu=$("$0" cpu); else cpu=$(sparkview "$HIST_DIR/cpu.hist"); fi
    gpu=$("$0" gpu)                     # ioreg / sysfs, ~20ms
    ram=$("$0" ram)
    bat=$("$0" bat)
    # status-right goes through strftime(3), so literal % must be %%
    local_cpu=${cpu//%/%%}; local_gpu=${gpu//%/%%}; local_ram=${ram//%/%%}; local_bat=${bat//%/%%}
    # fixed-width fields (12 cells each for cpu/gpu incl. their value
    # slots; ram left-aligned to 11) so digit changes never shift the bar
    local_ram=$(printf '%-11s' "$local_ram")
    tmux set -g status-right \
      "#[fg=colour191,bold]%I:%M %p  #[fg=colour240]cpu #[fg=colour39]${local_cpu}#[fg=colour245] | #[fg=colour240]gpu #[fg=colour208]${local_gpu}#[fg=colour245] | #[fg=colour240]ram #[fg=colour117]${local_ram}#[fg=colour245] | #[fg=colour114]${local_bat}" 2>/dev/null
    exit 0
    ;;
  refresh)
    # print the current sampling interval (seconds)
    refresh_secs
    ;;
  daemon)
    # Started by tmux.conf via: run-shell -b '... sysstats.sh daemon'
    mkdir -p "$HIST_DIR"
    # don't start a second daemon on config reload
    pidfile="$HIST_DIR/daemon.pid"
    if [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null; then
      exit 0
    fi
    echo $$ > "$pidfile"
    # The interval is a user option (@status_refresh, default 5s); the
    # right-click menu flips it between 1 and 5. Re-read EVERY round so a
    # change applies at once — except that we may already be mid-sleep of the
    # old value (worst case: one old-length sleep). Clicking a menu entry also
    # runs 'tick' directly, so the bar updates immediately regardless.
    while :; do "$0" tick; sleep "$(refresh_secs)"; done
    ;;
  *)
    echo "usage: $0 cpu|gpu|ram|bat|refresh|tick|daemon" >&2
    exit 1
    ;;
esac
