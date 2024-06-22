#!/usr/bin/zsh

path=$(echo $1 | /usr/bin/cut -d":" -f1)
line=$(echo $1 | /usr/bin/cut -d":" -f2)

Cmd="bat "
PageArgs="--line-range"
SearchArgs="-p "

eval $Cmd $PageArgs $line: \"$path\"
#echo $Cmd $PageArgs$line  $SearchArgs $2 \"$path\"
