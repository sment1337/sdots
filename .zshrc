# ~/.zshrc file for zsh interactive shells.
# see /usr/share/doc/zsh/examples/zshrc for examples

setopt autocd              # change directory just by typing its name
#setopt correct            # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

WORDCHARS=${WORDCHARS//\/} # Don't consider certain characters part of the word

# Put user-local binaries first so they shadow distro versions (e.g. fzf)
typeset -U path  # keep path array free of duplicates
path=("$HOME/.local/bin" $path)

# _zsh_ext <pkg-dir-name> — locate an optional zsh extension wherever this machine
# installed it: Debian/Ubuntu /usr/share, Arch /usr/share/zsh/plugins, Homebrew on Apple
# Silicon /opt/homebrew/share, Intel Macs /usr/local/share, vendored copies under
# Intel Macs /usr/local/share, vendored copies ~/.local/share/zsh. Prints the file and
# returns 0 when found; callers must treat "not found" as normal (see _gnu below for
# why hardcoding one layout silently disabled a feature on other platforms).
_zsh_ext() {
    local n="$1" d
    for d in /usr/share /usr/share/zsh/plugins /opt/homebrew/share /usr/local/share "$HOME/.local/share/zsh"; do
        [[ -f "$d/$n/$n.zsh" ]] && { printf '%s' "$d/$n/$n.zsh"; return 0; }
    done
    return 1
}

# hide EOL sign ('%')
PROMPT_EOL_MARK=""

# configure key keybindings
bindkey -e                                        # emacs key bindings
bindkey ' ' magic-space                           # do history expansion on space
bindkey '^U' backward-kill-line                   # ctrl + U
bindkey '^[[3;5~' kill-word                       # ctrl + Supr
bindkey '^[[3~' delete-char                       # delete
bindkey '^[[1;5C' forward-word                    # ctrl + ->
bindkey '^[[1;5D' backward-word                   # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history    # page up
bindkey '^[[6~' end-of-buffer-or-history          # page down
bindkey '^[[H' beginning-of-line                  # home
bindkey '^[[F' end-of-line                        # end
bindkey '^[[Z' undo                               # shift + tab undo last action

# enable completion features
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' rehash true
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# History configurations
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
#setopt share_history         # share command history data

# force zsh to show the complete history
alias history="history 0"

# configure `time` format
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

configure_prompt() {
    prompt_symbol=㉿
    # Skull emoji for root terminal
    #[ "$EUID" -eq 0 ] && prompt_symbol=💀
    case "$PROMPT_ALTERNATIVE" in
        twoline)
            PROMPT=$'%F{%(#.blue.green)}┌──${debian_chroot:+($debian_chroot)─}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))─}(%B%F{%(#.red.blue)}%n'$prompt_symbol$'%m%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]\n└─%B%(#.%F{red}#.%F{blue}$)%b%F{reset} '
            # Right-side prompt with exit codes and background processes
            #RPROMPT=$'%(?.. %? %F{red}%B⨯%b%F{reset})%(1j. %j %F{yellow}%B⚙%b%F{reset}.)'
            ;;
        oneline)
            PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{%(#.red.blue)}%n@%m%b%F{reset}:%B%F{%(#.blue.green)}%~%b%F{reset}%(#.#.$) '
            RPROMPT=
            ;;
        backtrack)
            PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{red}%n@%m%b%F{reset}:%B%F{blue}%~%b%F{reset}%(#.#.$) '
            RPROMPT=
            ;;
    esac
    unset prompt_symbol
}

# The following block is surrounded by two delimiters.
# These delimiters must not be modified. Thanks.
# START KALI CONFIG VARIABLES
PROMPT_ALTERNATIVE=twoline
NEWLINE_BEFORE_PROMPT=yes
# STOP KALI CONFIG VARIABLES

if [ "$color_prompt" = yes ]; then
    # override default virtualenv indicator in prompt
    VIRTUAL_ENV_DISABLE_PROMPT=1

    configure_prompt

    # enable syntax-highlighting (location probed — see _zsh_ext). This plugin wraps ZLE
    # widgets, so upstream wants it sourced LAST: capture the path here and source it at the
    # bottom of this file. The style table below is plain array assignment, order-independent.
    if _ZSH_HL="$(_zsh_ext zsh-syntax-highlighting)"; then
        # Declared here because the style table below now runs BEFORE the plugin is sourced
        # (it wraps ZLE widgets, so upstream wants sourcing last). Without this, assigning to
        # an undeclared assoc array dies with "assignment to invalid subscript range" and
        # silently aborts the rest of .zshrc — including the source at the bottom.
        typeset -gA ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
        ZSH_HIGHLIGHT_STYLES[default]=none
        ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=white,underline
        ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
        ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[global-alias]=fg=green,bold
        ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[path]=bold
        ZSH_HIGHLIGHT_STYLES[path_pathseparator]=
        ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=
        ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[command-substitution]=none
        ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[process-substitution]=none
        ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=green
        ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=green
        ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
        ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[assign]=none
        ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
        ZSH_HIGHLIGHT_STYLES[named-fd]=none
        ZSH_HIGHLIGHT_STYLES[numeric-fd]=none
        ZSH_HIGHLIGHT_STYLES[arg0]=fg=cyan
        ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
        ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
    fi
else
    PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%(#.#.$) '
fi
unset color_prompt force_color_prompt

toggle_oneline_prompt(){
    if [ "$PROMPT_ALTERNATIVE" = oneline ]; then
        PROMPT_ALTERNATIVE=twoline
    else
        PROMPT_ALTERNATIVE=oneline
    fi
    configure_prompt
    zle reset-prompt
}
zle -N toggle_oneline_prompt
#bindkey ^P toggle_oneline_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty)
    TERM_TITLE=$'\e]0;${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%n@%m: %~\a'
    ;;
*)
    ;;
esac

precmd() {
    # Print the previously configured title
    print -Pnr -- "$TERM_TITLE"

    # Print a new line before the prompt, but only if it is not the first line
    if [ "$NEWLINE_BEFORE_PROMPT" = yes ]; then
        if [ -z "$_NEW_LINE_BEFORE_PROMPT" ]; then
            _NEW_LINE_BEFORE_PROMPT=1
        else
            print ""
        fi
    fi
}

# enable color support of ls, less and man, and also add handy aliases.
# Probe per TOOL instead of assuming a GNU userland: `--color` is a GNU long option,
# and BSD builds abort on it with "ls: illegal option -- -" — which is exactly what
# every `ll` did before this probe existed. Probing the tool's OWN banner beats both a
# uname check (Apple ships GNU grep) and an exit-code check (grep exits 1 on no match).
# BSD ls colours with -G + LSCOLORS instead, and a tool that isn't installed here at
# all simply gets no alias.
_gnu() { # 0 = this build is the GNU one, so it accepts GNU long options
    command -v "$1" >/dev/null 2>&1 || return 1
    "$1" --version 2>&1 | head -1 | grep -qiE 'GNU|iproute2'
}

_ls_opt=$(_gnu ls && printf '%s' '--color=auto' || printf '%s' '-G')   # BSD ls: -G + LSCOLORS
alias ls="ls $_ls_opt"
#alias dir="dir $_ls_opt"
#alias vdir="vdir $_ls_opt"
for _t in grep fgrep egrep diff ip; do
    _gnu "$_t" && alias "$_t=$_t --color=auto"
done; unset _t

_dc="$(command -v dircolors 2>/dev/null || command -v gdircolors 2>/dev/null)"   # GNU-only, absent on macOS
if [ -n "$_dc" ]; then
    test -r ~/.dircolors && eval "$("$_dc" -b ~/.dircolors)" || eval "$("$_dc" -b)"
    export LS_COLORS="$LS_COLORS:ow=30;44:" # fix ls color for folders with 777 permissions
fi; unset _dc

export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

# Take advantage of $LS_COLORS for completion as well — only if we actually have a
# palette (a BSD box without dircolors has none, and an empty split would set nothing).
if [ -n "${LS_COLORS:-}" ]; then
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
fi

# some more ls aliases
alias ll="ls -ltrah $_ls_opt"   # _ls_opt chosen by the probe above
alias vi='vim -u ~/.vim/.vimrc'
alias la='ls -A'
alias l='ls -CF'
alias cht='f() { curl cht.sh/$1 };f'
# These helpers wrap tools that only exist on some platforms; defining them blindly meant a
# Linux-only alias errored on the Mac. Same probe-as-you-go rule as _gnu above: no tool, no
# alias — and nothing shadowed when the tool shows up later.
command -v upower >/dev/null 2>&1 && alias power='upower -i /org/freedesktop/UPower/devices/battery_BAT0'
[ -w /sys/class/leds/smc::kbd_backlight/brightness ] && alias bl='f() { echo $1 | sudo tee /sys/class/leds/smc::kbd_backlight/brightness };f'
alias pfzf="fzf --preview='less {}' --bind pgdn:preview-page-down,pgup:preview-page-up"
command -v nmap >/dev/null 2>&1 && command -v dig >/dev/null 2>&1 && alias port='f() {sudo nmap -sU $(dig -4 +short myip.opendns.com @resolver1.opendns.com) -p $1}; f'

# enable auto-suggestions based on the history (location probed — see _zsh_ext)
if _ext="$(_zsh_ext zsh-autosuggestions)"; then
    . "$_ext"
    # change suggestion color
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi

# enable command-not-found if installed
if [ -f /etc/zsh_command_not_found ]; then
    . /etc/zsh_command_not_found
fi

for aj in /opt/homebrew/etc/profile.d/autojump.sh /usr/share/autojump/autojump.zsh; do
  [ -f "$aj" ] && { . "$aj"; break; }
done; unset aj

export RANGER_LOAD_DEFAULT_RC="FALSE"

#bindkey -v

# Set up fzf key bindings and fuzzy completion
fb="$(command -v fzf 2>/dev/null)"
[ -n "$fb" ] && source <("$fb" --zsh)

# To have preview in fzf
_fzf_comprun() {
  local command=$1
  shift

  local batbin
  batbin="$(command -v bat || command -v batcat)"
  case "$command" in
    cd)           fzf "$@" --preview 'tree {} -C -L 1 -a' ;;
    *)            fzf "$@" --preview="$batbin {}" --bind pgdn:preview-page-down,pgup:preview-page-up --border=rounded ;;
  esac
}
for p in /opt/homebrew/bin /usr/local/ffmpeg/bin; do
  case ":$PATH:" in *":$p:"*) ;; *) [ -d "$p" ] && PATH="$p:$PATH" ;; esac
done; unset p
export PATH="$PATH:$HOME/.lmstudio/bin"



# Sourced last on purpose: it wraps widgets created by the autosuggestion plugin above.
[[ -n "${_ZSH_HL:-}" ]] && . "$_ZSH_HL"

# Local machine-specific overrides (not tracked by git)
[ -f "$HOME/.local.zshrc" ] && source "$HOME/.local.zshrc"

# XQuartz xauth sync (macOS only; DISPLAY itself belongs in ~/.local.zshrc
# if a machine needs it — never hardcode DISPLAY in a tracked file)
if command -v pgrep >/dev/null 2>&1 && pgrep -x Xquartz >/dev/null 2>&1; then
    xauth add $(xauth list 2>/dev/null | head -1) 2>/dev/null
fi

export EDITOR='vim'
export VIMINIT='source ~/.vim/.vimrc'
