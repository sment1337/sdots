#!/usr/bin/zsh

default_path="/Users/USERNAME/Desktop//REDACTED-PDK/gn22fdx+"
path=${1:-$default_path}
echo $path

echo 'type search keyword or regexp:'

read var1

#var2=$(pdfgrep --recursive --page-number $var1 "/home/USERNAME/resilio/folders/DripBox/iCloudDocs/Literature/EE Design Books" | fzf) #| cut -d":" -f1,2 
var2=$(pdfgrep --recursive --page-number $var1 $path | fzf --preview-window 'right,1%' --bind "enter:preview(sh $HOME/preview.sh {} $var1),ctrl-/:change-preview-window(hidden)") #| cut -d":" -f1,2
