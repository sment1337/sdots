#!/usr/bin/env bash
# sysstats.sh — feed tmux status bar sparklines (macOS)
# usage: sysstats.sh cpu|gpu|ram|bat
#
# History lives in $HOME/.cache/tmux-sysstats/{cpu,gpu}.hist (one value per line).

set -u
HIST_DIR="$HOME/.cache/tmux-sysstats"
BARS=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

spark() { # spark <histfile> <value>
  local file="$1" val="$2" hist idx out
  mkdir -p "$HIST_DIR"
  { echo "$val"; tail -n 8 "$file" 2>/dev/null | head -n 7; } > "$file.tmp" && mv "$file.tmp" "$file"
  hist=()
  while read -r v; do hist+=("$v"); done < "$file"
  out=""
  for v in "${hist[@]}"; do
    idx=$(( (v * 8 + 50) / 100 ))
    (( idx > 7 )) && idx=7
    out+="${BARS[$idx]}"
  done
  echo "$out $val%"
}

case "${1:-}" in
  cpu)
    # top -l1 samples for ~1s; CPU usage = 100 - idle (aggregate 0-100%)
    val=$(top -l1 -n0 | awk -F',' '/CPU usage/{n=split($3,a," "); id=a[1]; sub(/%/,"",id); v=100-id; if (v<0||v>100) v=0; printf "%d", v}')
    [[ -z "$val" ]] && val=0
    spark "$HIST_DIR/cpu.hist" "$val"
    ;;
  gpu)
    # Preferred: ioreg PerformanceStatistics on Apple Silicon (no sudo,
    # ~20ms). "Device Utilization %" is the aggregate GPU busy percentage.
    val=$(ioreg -r -d 2 -c AGXAccelerator -l -w 0 2>/dev/null \
          | grep -oE '"Device Utilization %"=[0-9]+' | head -1 | cut -d= -f2)
    # Fallback: sudo powermetrics, if passwordless sudo exists
    if [[ -z "$val" ]] && sudo -n true 2>/dev/null; then
      val=$(sudo -n powermetrics --samplers gpu_util -i 1000 -n 1 2>/dev/null \
            | grep -oE 'GPU core utilization: [0-9.]+ %' | head -1 | awk -F'[:%]' '{printf "%d", $2}')
    fi
    if [[ -n "$val" ]]; then
      spark "$HIST_DIR/gpu.hist" "$val"
    else
      echo "n/a"
    fi
    ;;
  ram)
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
    # pad to a fixed 15 display cells so the centred bar doesn't shift;
    # emoji/⏳/⚡ occupy 2 cells each
    wide=$(printf '%s' "$out" | grep -oE '(🔋|🪫|🔌|⚡|⏳)' | wc -l | tr -d ' ')
    cells=$(( ${#out} + wide ))
    pad=$(( 15 - cells )); (( pad < 0 )) && pad=0
    printf '%s%*s' "$out" "$pad" ''
    ;;
  daemon)
    # Started by tmux.conf via: run-shell -b '... sysstats.sh daemon'
    # One loop per 5s; cpu every tick, gpu/ram every 2 ticks, bat every 6.
    mkdir -p "$HIST_DIR"
    # don't start a second daemon on config reload
    pidfile="$HIST_DIR/daemon.pid"
    if [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null; then
      exit 0
    fi
    echo $$ > "$pidfile"
    cpu="-"; gpu="-"; ram="-"; bat="-"; n=0
    while :; do
      n=$(( n + 1 ))
      # top -l1 is the only expensive sample (~0.4 CPU-s); run it every
      # other tick so the cpu graph updates at 10s resolution
      if (( n % 2 == 0 )); then cpu=$("$0" cpu); fi
      gpu=$("$0" gpu)                     # cheap unless passwordless sudo exists
      ram=$("$0" ram)
      bat=$("$0" bat)
      # status-right goes through strftime(3), so literal % must be %%
      local_cpu=${cpu//%/%%}; local_gpu=${gpu//%/%%}; local_ram=${ram//%/%%}; local_bat=${bat//%/%%}
      # pad each value to a fixed width so the centred bar doesn't shift
      # when numbers grow/shrink (bat is already padded by its subcommand)
      local_cpu=$(printf '%12s' "$local_cpu"); local_gpu=$(printf '%12s' "$local_gpu")
      local_ram=$(printf '%12s' "$local_ram")
      tmux set -g status-right \
        "#[fg=colour191,bold]%I:%M %p  #[fg=colour240]cpu #[fg=colour39]${local_cpu}#[fg=colour245] | #[fg=colour240]gpu #[fg=colour208]${local_gpu}#[fg=colour245] | #[fg=colour240]ram #[fg=colour117]${local_ram}#[fg=colour245] | #[fg=colour114]${local_bat}" 2>/dev/null
      sleep 5
    done
    ;;
  *)
    echo "usage: $0 cpu|gpu|ram|bat|daemon" >&2
    exit 1
    ;;
esac
