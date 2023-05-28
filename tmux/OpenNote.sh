#!/usr/bin/zsh

echo 'type search keyword or regexp:'

read var1

var2=$(grep -rnw 'resilio/folders/DripBox/QownNotes' -e $var1 | fzf) #| cut -d":" -f1,2 

path=$(echo $var2 | cut -d":" -f1)
line=$(echo $var2 | cut -d":" -f2)

vimCmd="vim -u ~/.vim/.vimrc"

eval $vimCmd +$line \"$path\"
