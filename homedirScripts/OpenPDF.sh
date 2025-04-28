#!/usr/bin/zsh

default_path="/Users/tcharisoulis/Desktop/PDKdir/gn22fdx+"
path=${1:-$default_path}
echo $path

echo 'type search keyword or regexp:'

read var1

#var2=$(pdfgrep --recursive --page-number $var1 "/home/sment/resilio/folders/DripBox/iCloudDocs/Literature/EE Design Books" | fzf) #| cut -d":" -f1,2 
var2=$(pdfgrep --recursive --page-number $var1 $path | fzf --preview-window 'right,1%' --bind "enter:preview(sh $HOME/preview.sh {} $var1),ctrl-/:change-preview-window(hidden)") #| cut -d":" -f1,2
