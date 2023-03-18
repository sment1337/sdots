sudo pacman -S terminator i3-wm i3status sddm
sudo systemctl enable nitrogen polybar upower python-pip wget sddm.service
pip install bs4
rm -rf .zshrc
ln -s sdots/.zshrc ./.zshrc
ln -s sdots/.tmux.conf ./.tmux.conf
rm -rf .config/i3
ln -s /home/USERNAME/sdots/i3 .config/i3
ln -s /home/USERNAME/sdots/polybar .config/polybar
ln -s /home/USERNAME/sdots/nitrogen/ .config/nitrogen
sudo reboot now
