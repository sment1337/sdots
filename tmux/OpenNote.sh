#!/usr/bin/zsh

echo 'type search keyword or regexp (/!\ Note: use -e ASDASD to do or search):'

read var1

#var2=$(grep -rnw 'resilio/folders/DripBox/QownNotes' -e $var1 | fzf) #| cut -d":" -f1,2 
var2=$(egrep --recursive --with-filename --line-number --binary-files=without-match "$var1" '/mnt/d/DripBox/QownNotes' | fzf --preview-window 'right,70%' --bind "ctrl-p:preview(sh ~/sdots/tmux/preview.sh {}),ctrl-/:change-preview-window(hidden),pgdn:preview-page-down,pgup:preview-page-up")

if [ -z "$var2" ]; then
	echo "empty, quitting"
else
	path=$(echo $var2 | cut -d":" -f1)
	line=$(echo $var2 | cut -d":" -f2)

	vimCmd="vim -u ~/.vim/.vimrc"

	eval $vimCmd +$line \"$path\"
fi
