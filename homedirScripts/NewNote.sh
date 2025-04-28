#!/usr/bin/zsh

echo 'Type title: '
read title
path='/Users/USERNAME/Library/CloudStorage/GoogleDrive-20616301+sment1337@users.noreply.github.com/My Drive/notes/'
vimCmd="vim -u ~/.vim/.vimrc"

echo $var1
echo $path$(date +"%Y%m%d")\_$title\.md


eval $vimCmd \"$path$(date +"%Y%m%d")\_$title\.md\"

