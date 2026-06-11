#!/usr/bin/zsh

echo 'type search keyword or regexp (/!\ Note: use -e ASDASD to do or search):'

read var1

#var2=$(grep -rnw ~/DripBox/QownNotes -e $var1 | fzf --preview-window 'right,40%' --bind "ctrl-p:preview(sh $HOME/sdots/tmux/preview.sh {}),ctrl-z:change-preview-window(hidden)")
# If user aborts with ctrl+c, fzf returns non-zero and script exits entirely
if ! var2=$(egrep -rnI \
  --exclude-dir=__pycache__ \
  --exclude-dir=site-packages \
  --exclude-dir=.git \
  --exclude-dir=venv \
  --exclude-dir=.venv \
  "$var1" ~/DripBox/QownNotes | fzf --preview-window 'right,40%' --bind "ctrl-p:preview(sh $HOME/sdots/tmux/preview.sh {}),ctrl-z:change-preview-window(hidden)") 
then 
    echo "Search cancelled"
    return 0 2>/dev/null || exit 0
fi


path=$(echo $var2 | cut -d":" -f1)
line=$(echo $var2 | cut -d":" -f2)

vimCmd="vim -u ~/.vim/.vimrc"

eval $vimCmd +$line \"$path\"
