#!/bin/zsh

# Extract file path and page number from fzf output (format: "path:number:text")
raw="$1"
term="$2"   # OpenPDF.sh already passes the search term here as the 2nd arg
path=$(echo "$raw" | cut -d":" -f1)
pagenum=$(echo "$raw" | cut -d":" -f2)

# Open with zathura at the specified page. --find also highlights/locates the
# matched phrase on that page (feature carried over from the old
# homedirScripts/preview.sh, which this superseded).
if [[ -n "$term" ]]; then
  zathura --page "$pagenum" --find "$term" "$path"
else
  zathura --page "$pagenum" "$path"
fi
