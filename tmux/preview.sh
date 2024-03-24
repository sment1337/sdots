path=$(echo $1 | cut -d":" -f1)
line=$(echo $1 | cut -d":" -f2)

Cmd="zathura -P "
CmdArgs="-f "

eval $Cmd $line $CmdArgs $2 \"$path\"
