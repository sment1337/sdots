#!/usr/bin/zsh

echo 'type search keyword or regexp:'

read var1

var2=$(pdfgrep --recursive --page-number $var1 "/home/sment/resilio/folders/DripBox/iCloudDocs/Literature/spice manuals and Books" | fzf) #| cut -d":" -f1,2 

path=$(echo $var2 | cut -d":" -f1)
line=$(echo $var2 | cut -d":" -f2)

Cmd="zathura -P "

eval $Cmd $line \"$path\"
