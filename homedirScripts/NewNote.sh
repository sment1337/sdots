#!/usr/bin/zsh

echo 'Type title: '
read title
path='/Users/tcharisoulis/Library/CloudStorage/GoogleDrive-tcharisoulis@meta.com/My Drive/notes/'
vimCmd="vim -u ~/.vim/.vimrc"

echo $var1
echo $path$(date +"%Y%m%d")\_$title\.md


eval $vimCmd \"$path$(date +"%Y%m%d")\_$title\.md\"

