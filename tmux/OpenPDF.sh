#!/usr/bin/zsh

echo 'type search keyword or regexp:'

read var1

var2=$(pdfgrep --recursive --page-number $var1 "$HOME/DripBox/iCloudDocs/Literature/EE Design Books" | fzf --preview-window 'right,1%' --bind "enter:preview(sh $HOME/sdots/tmux/pdfPreview.sh {} $var1),ctrl-/:change-preview-window(hidden)")

path=$(echo $var2 | cut -d":" -f1)
line=$(echo $var2 | cut -d":" -f2)

Cmd="zathura -P "

eval $Cmd $line \"$path\"
