# VNC desktop (browser access) — Arch / systemd

Headless i3 desktop served to any browser: **Xvnc → websockify → noVNC**.

```
systemd ── vncserver@:1.service ── Xvnc :1        (localhost-only, 5901)
          websock@$USER.service ── websockify     (0.0.0.0:6080 -> 127.0.0.1:5901)
browser ── http://<host>:6080/vnc.html?autoconnect=true   (asks for vncpasswd)
```

## Install — automated

`install.sh` does all of this idempotently (needs passwordless sudo):
- `/etc/tigervnc/vncserver-config-mandatory`  ← `vnc/vncserver-config-mandatory`
- `/etc/systemd/system/websock@.service`      ← `vnc/websock@.service`
- appends `:1=$USER` to `/etc/tigervnc/vncserver.users`
- enables/starts `vncserver@:1.service` and `websock@$USER.service`

Then once per machine: `vncpasswd` (writes `~/.config/tigervnc/passwd`).

## Gotchas learned the hard way (do not "fix" these back)

- **Options must live in `/etc/tigervnc/vncserver-config-mandatory`.**
  The user config (`~/.config/tigervnc/config`, symlinked from sdots `vnc/config`)
  is NOT reliably parsed when vncsession drops privileges — options there are
  silently ignored (geometry/localhost were).
- **Never run picom with the glx backend inside Xvnc.** GLX compositing draws
  around TigerVNC's RFB scanout: input works, clients get stale frames and no
  incremental updates. i3 auto-selects `--backend xrender` on VNC displays and
  full glx glass on real monitors — see the comment in i3/config.
- **Don't resize Xvnc with external `xrandr` while clients are attached** — it
  wedges incremental update tracking; use noVNC remote-resize or restart the
  service (`sudo systemctl restart vncserver@:1`).
- TigerVNC ≥1.16 also has its own freeze regressions upstream
  (TigerVNC/tigervnc#2148); if updates stop with NO compositor running, test
  `x11vnc -display :1 -localhost -forever -shared -rfbport 5902` as an
  alternate server before deeper debugging.
- noVNC on a HiDPI display + "Remote resizing" makes the browser request
  framebuffer = CSS size × devicePixelRatio (a Retina laptop asked for 6 MP);
  leave remote resizing off, geometry is pinned at 1920x1080 server-side.

## Manual steps (if install.sh skipped this section)

```bash
sudo install -Dm644 vnc/vncserver-config-mandatory /etc/tigervnc/vncserver-config-mandatory
sudo install -Dm644 vnc/websock@.service /etc/systemd/system/websock@.service
echo ":1=$USER" | sudo tee -a /etc/tigervnc/vncserver.users
sudo systemctl daemon-reload
sudo systemctl enable --now vncserver@:1.service "websock@$USER.service"
vncpasswd   # once per machine
```

## Day-2 commands

```bash
sudo systemctl restart vncserver@:1.service      # restart desktop (all apps)
sudo systemctl restart websock@$USER.service     # restart browser bridge only
journalctl -u vncserver@:1 -f                    # server-side log
```

Security note: 5901 is localhost-only; 6080 listens on all interfaces as
plain HTTP (VNC password still required) — for untrusted networks bind
websock@ to 127.0.0.1 and tunnel: `ssh -L 6080:localhost:6080 host`.
