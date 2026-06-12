#!/usr/bin/zsh

# Choose literature folder
echo "Select literature folder:"
echo "1) EE Design Books"
echo "2) analog design"
echo "3) All (entire Literature directory)"
read choice

if [[ $choice == "1" ]]; then
    var1="$HOME/DripBox/iCloudDocs/Literature/EE Design Books"
elif [[ $choice == "2" ]]; then
    var1="$HOME/DripBox/iCloudDocs/Literature/analog design"
elif [[ $choice == "3" ]]; then
    var1="$HOME/DripBox/iCloudDocs/Literature"
fi

echo 'type search keyword or regexp:'

read var2

var3=$(pdfgrep --recursive --page-number "$var2" "$var1" | fzf --preview-window 'right,1%,hidden' --bind "enter:preview(sh $HOME/sdots/tmux/pdfPreview.sh {} $var2),ctrl-/:change-preview-window(hidden)")

path=$(echo "$var3" | cut -d":" -f1)
line=$(echo "$var3" | cut -d":" -f2)

zathura -P "$line" "$path"
