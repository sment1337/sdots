#!/usr/bin/zsh
nvidia-smi | grep -Eo '[0-9]+W' | head -n1 | grep -Eo '[0-9]+'
