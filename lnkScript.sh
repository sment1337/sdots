sudo pacman -S terminator i3-wm i3status polybar upower python-pip base-devel wget sddm nitrogen 
sudo systemctl enable sddm.service
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ~
yay -S ttf-jetbrains-mono-nerd autojump
pip install bs4
rm -rf .zshrc
ln -s sdots/.zshrc ./.zshrc
ln -s sdots/.tmux.conf ./.tmux.conf
rm -rf .config/i3
ln -s /home/USERNAME/sdots/i3 .config/i3
ln -s /home/USERNAME/sdots/polybar .config/polybar
ln -s /home/USERNAME/sdots/nitrogen/ .config/nitrogen
sudo reboot now
