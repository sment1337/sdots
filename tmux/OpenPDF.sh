#!/usr/bin/zsh

echo "choose option: 1 - reference manuals; 2 - analog design books"
read numeric_value

# Perform a case check based on the numeric value
case $numeric_value in
  1)
    echo "Reference manuals it is"
    var0="EE Design Books"
    clear;
    echo $var0
    ;;
  2)
    echo "Analog design books it is"
    var0="analog design"
    clear;
    echo $var0
    ;;
  *)
    echo "Invalid selection. Please enter a value between 1 and 2."
    ;;
esac

echo 'type search keyword or regexp (/!\ Note: use -e ASDASD to do or search):'
read var1

#var2=$(pdfgrep --recursive --page-number $var1 "/home/sment/resilio/folders/DripBox/iCloudDocs/Literature/EE Design Books" | fzf) #| cut -d":" -f1,2 
var2=$(pdfgrep --recursive --page-number $var1 "/home/sment/DripBox/iCloudDocs/Literature/$var0" | fzf --preview-window 'right,1%' --bind "enter:preview(sh $HOME/sdots/tmux/preview.sh {} $var1),ctrl-/:change-preview-window(hidden)") #| cut -d":" -f1,2
