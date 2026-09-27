#!/usr/bin/env bash
# lnkScript.sh -- first-run bootstrap for a FRESH ARCH LINUX box.
# Installs i3 / polybar / rofi / picom / sddm, links the sdots dotfiles, and
# sets up the Sugar-Candy login theme. See README.md.
#
# ⚠ DESTRUCTIVE and NOT idempotent: it deletes ~/.vim, ~/.zshrc, ~/.tmux.conf
#   and ~/.config before re-linking them. Never run it on your daily machine.

# ---- confirmation gate -----------------------------------------------
# Require a real terminal and an explicitly typed YES before touching anything.
if [[ ! -t 0 ]]; then
  echo "lnkScript.sh: refusing to run with no interactive TTY (typed confirmation is required)." >&2
  exit 1
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "lnkScript.sh: this is an Arch Linux bootstrap (pacman/yay/systemd). Running on $(uname -s) would fail halfway through." >&2
  exit 1
fi

cat >&2 <<'WARN'
========================================================================
  lnkScript.sh -- Arch Linux dotfiles bootstrap

  This will, WITHOUT asking again:
    * install packages via pacman and yay (AUR clone + makepkg)
    * enable sddm.service
    * DELETE and re-link: ~/.vim  ~/.zshrc  ~/.tmux.conf  ~/.config
    * rewrite the system Sugar-Candy sddm theme files (with sudo)
========================================================================
WARN

read -r -p "Type YES to continue, anything else to abort: " answer
if [[ "${answer}" != "YES" ]]; then
  echo "Aborted -- nothing was changed."
  exit 1
fi
# -----------------------------------------------------------------------

rm -rf .vim .zshrc .tmux.conf .config
printf '1\nY\n' | sudo pacman -S terminator i3-wm i3status xorg-xrandr picom polybar upower python-pip base-devel wget sddm nitrogen rofi
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
mkdir /home/USERNAME/.config
ln -s /home/USERNAME/sdots/i3 .config/i3
ln -s /home/USERNAME/sdots/polybar .config/polybar
ln -s /home/USERNAME/sdots/nitrogen/ .config/nitrogen
ln -s /home/USERNAME/sdots/rofi/ .config/rofi

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
wlaneth=$(ip a | grep BROADCAST | awk '{print $2}' | sed 's/://g' | tail -1)
sed -i "s/wlp3s0b1/$wlaneth/g" .config/polybar/config.ini
sed -i "s/enp2s0f0/$wlaneth/g" .config/polybar/scripts/ip

#sudo reboot now
