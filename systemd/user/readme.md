**As also found in Linux CheatSheet**

### Running tunnel as a systemd service
<https://gist.github.com/drmalex07/c0f9304deea566842490>

#### secure-tunnel@smac.service
1. `$ sudo cp sdots/systemd/user/secure-tunnel@.service /etc/systemd/user/secure-tunnel@smac.service`
2. `$ echo 'TARGET=smac' | sudo tee /etc/default/secure-tunnel@smac`
3. `$ systemctl --user start secure-tunnel@smac.service`
4. `$ systemctl --user enable secure-tunnel@smac.service`

#### websock.service
1. `$ sudo cp sdots/systemd/user/websock.service /etc/systemd/system/websock.service`
2. `$ sudo chmod -x websock.service`
3. `$ systemctl daemon-reload`
4. `$ sudo systemctl start websock.service`
