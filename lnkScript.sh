rm -rf .vim .zshrc .tmux.conf .config
printf '1\nY\n' | sudo pacman -S terminator i3-wm xorg-xrandr i3status polybar upower python-pip base-devel wget sddm nitrogen
sudo systemctl enable sddm.service
git clone https://aur.archlinux.org/yay.git
cd yay
printf 'Y\nY\n' | makepkg -si
cd ~
printf 'Y\nN\nN\nY\n' | yay -S ttf-jetbrains-mono-nerd autojump sddm-theme-sugar-candy-git
pip install bs4
ln -s sdots/.vim ./.vim
ln -s sdots/.zshrc ./.zshrc
ln -s sdots/.tmux.conf ./.tmux.conf
mkdir /home/sment/.config
ln -s /home/sment/sdots/i3 .config/i3
ln -s /home/sment/sdots/polybar .config/polybar
ln -s /home/sment/sdots/nitrogen/ .config/nitrogen

# Theme stuff. First make Sugar Candy Backgrounds folder open to write images
sudo chmod -R 777 /usr/share/sddm/themes/Sugar-Candy/Backgrounds
# Substituting Sugar Candy for sddm
cat /usr/lib/sddm/sddm.conf.d/default.conf | sed 's/^Current=/Current=Sugar-Candy/g' | sudo tee /usr/lib/sddm/sddm.conf.d/default.conf
# Substituting BG in sugar candy
cat /usr/share/sddm/themes/Sugar-Candy/theme.conf | sed '/^Background/d' | sed '/General/a Background='\"'Backgrounds/BG.jpg'\"'' | sudo tee /usr/share/sddm/themes/Sugar-Candy/theme.conf.user
python .config/nitrogen/scraper.py
sudo chown root:root /usr/share/sddm/themes/Sugar-Candy/Backgrounds/BG.jpg
sudo chmod -R 777 /usr/share/sddm/themes/Sugar-Candy/Backgrounds/BG.jpg

# fixing the netowrk scripts
wlaneth=$(ip a | grep BROADCAST | awk '{print $2}' | sed 's/://g')
sed -i "s/wlp3s0b1/$wlaneth/g" .config/polybar/config.ini
sed -i "s/enp2s0f0/$wlaneth/g" .config/polybar/scripts/ip

#sudo reboot now
