#!/usr/bin/zsh
nvidia-smi | grep -Eo '[0-9]+%[ ]+Default' | grep -Eo '[0-9]+%' | grep -Eo '[0-9]+'
