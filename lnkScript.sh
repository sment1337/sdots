rm -rf .vim .zshrc .tmux.conf .config
printf '1\nY\n' | sudo pacman -S terminator i3-wm i3status polybar upower python-pip base-devel wget sddm nitrogen
sudo systemctl enable sddm.service
git clone https://aur.archlinux.org/yay.git
cd yay
printf 'Y\nY\n' | makepkg -si
cd ~
printf 'Y\n' | yay -S ttf-jetbrains-mono-nerd autojump
pip install bs4
ln -s sdots/.vim ./.vim
ln -s sdots/.zshrc ./.zshrc
ln -s sdots/.tmux.conf ./.tmux.conf
mkdir /home/sment/.config
ln -s /home/sment/sdots/i3 .config/i3
ln -s /home/sment/sdots/polybar .config/polybar
ln -s /home/sment/sdots/nitrogen/ .config/nitrogen
sudo reboot now