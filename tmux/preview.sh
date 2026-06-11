#!/bin/zsh

path=$(echo $1 | cut -d":" -f1)
line=$(echo $1 | cut -d":" -f2)

Cmd="vim -n -u ~/.vim/.vimrc"
CmdArgs="+"

eval $Cmd $CmdArgs$line \"$path\"

#Cmd="bat"
#eval $Cmd \"$path\"
