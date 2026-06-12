#!/bin/zsh

# Extract file path and page number from fzf output (format: "path:number:text")
raw="$1"
path=$(echo "$raw" | cut -d":" -f1)
pagenum=$(echo "$raw" | cut -d":" -f2)

# Open with zathura at the specified page
zathura --page "$pagenum" "$path"