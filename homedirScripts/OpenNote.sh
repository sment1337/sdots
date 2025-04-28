#!/usr/bin/zsh

echo 'type search keyword or regexp (/!\ Note: you can use -e ASDASD to or multiple words):'

read var1

echo $var1

#var2=$(grep -rnwI '/Users/tcharisoulis/Library/CloudStorage/GoogleDrive-tcharisoulis@meta.com/My Drive/notes' -e $var1 | fzf) #| cut -d":" -f1,2 
var2=$(egrep --recursive --with-filename --line-number --binary-files=without-match "$var1" '/Users/tcharisoulis/Library/CloudStorage/GoogleDrive-tcharisoulis@meta.com/My Drive/notes' | fzf) #| cut -d":" -f1,2 


#echo var2 is $var2.
if [ -z "$var2" ]; then
	echo "empty, quitting"
else
	path=$(echo $var2 | cut -d":" -f1)
	line=$(echo $var2 | cut -d":" -f2)

	vimCmd="vim -u ~/.vim/.vimrc"

	eval $vimCmd +$line \"$path\"
fi
