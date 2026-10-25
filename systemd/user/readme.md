**As also found in Linux CheatSheet**

### Running tunnel as a systemd service
<https://gist.github.com/drmalex07/c0f9304deea566842490>

#### secure-tunnel@smac.service
1. `$ sudo cp sdots/systemd/user/secure-tunnel@.service /etc/systemd/user/secure-tunnel@smac.service`
2. `$ echo 'TARGET=smac' | sudo tee /etc/default/secure-tunnel@smac`
3. `$ systemctl --user start secure-tunnel@smac.service`
4. `$ systemctl --user enable secure-tunnel@smac.service`

#### VNC / noVNC units
Moved: the websockify bridge is a **system** unit now, installed and
documented by `sdots/install.sh` + `sdots/vnc/README.md`.
