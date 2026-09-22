#!/usr/bin/zsh

echo 'Type title: '
read title
path="$NOTES_DIR/"
vimCmd="vim -u ~/.vim/.vimrc"

echo $var1
echo $path$(date +"%Y%m%d")\_$title\.md


eval $vimCmd \"$path$(date +"%Y%m%d")\_$title\.md\"

