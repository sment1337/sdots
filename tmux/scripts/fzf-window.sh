#!/usr/bin/env zsh
# fzf-window.sh — fuzzy window switcher behind `prefix W`.
#
# Lives in a script on purpose: tmux.conf's own parser expands "$var" inside
# double-quoted command strings before the shell ever sees it, which is what
# silently broke the previous inline one-liner (its ${PWD%%/*} "session"
# placeholder always expanded to an empty string, so select-window was handed
# the target " 1" and did nothing).
#
# The session is taken from TMUX_PANE, which tmux exports into run-shell
# commands, so the picked index is always applied to the session the prefix was
# pressed in — never to whichever session the server considers "current".

sess=$(tmux display-message -p -t "${TMUX_PANE}" '#{session_name}' 2>/dev/null)

# list as "<index> <name>"; fzf shows only the name (--with-nth 2..) so names
# containing spaces stay readable, while field 1 remains the index we cut out
win=$(tmux list-windows -t "${sess}" -F '#I #{window_name}' 2>/dev/null \
      | fzf --height=40% --delimiter=' ' --with-nth 2.. \
      | cut -d' ' -f1)

# aborted (ctrl-c / esc) -> nothing selected -> do nothing
[[ -z "${win}" ]] && exit 0

if [[ -n "${sess}" ]]; then
  tmux select-window -t "${sess}:${win}"
else
  tmux select-window -t "${win}"
fi
