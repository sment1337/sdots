#!/usr/bin/zsh

echo 'type search keyword or regexp (/!\ Note: use -e ASDASD to do or search):'

read var1

var2=$(grep -rnw 'DripBox/QownNotes' -e $var1 | fzf --preview-window 'right,40%' --bind "ctrl-p:preview(sh $HOME/sdots/tmux/preview.sh {}),ctrl-/:change-preview-window(hidden)")

path=$(echo $var2 | cut -d":" -f1)
line=$(echo $var2 | cut -d":" -f2)

vimCmd="vim -u ~/.vim/.vimrc"

eval $vimCmd +$line \"$path\"
