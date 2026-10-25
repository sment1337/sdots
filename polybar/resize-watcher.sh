#!/bin/bash
# restart polybar whenever the X screen size changes.
# noVNC "remote resizing" resizes the Xvnc screen (ExtendedDesktopSize), but
# polybar can't reflow on a randr resize — so we watch and restart it.
# Started from i3 (exec_always); single instance enforced via pidfile.
PIDFILE=/tmp/polybar-resize-watcher.pid
if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    kill "$(cat "$PIDFILE")"
fi
echo "$$" > "$PIDFILE"

screen_size() {
    xrandr --query 2>/dev/null | grep -m1 ' current ' | sed -E 's/.*current ([0-9]+) x ([0-9]+).*/\1x\2/'
}

last=$(screen_size)
while sleep 2; do
    cur=$(screen_size)
    [[ -n "$cur" && "$cur" != "$last" ]] || continue
    last=$cur
    sleep 1    # let i3 settle into the new geometry first
    killall -q polybar
    "$HOME/.config/polybar/launch.sh"
done
