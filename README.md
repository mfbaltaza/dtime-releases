# dtime

See where your time on the computer goes: which apps, which sites, how much of it was
productive, and whether you met the goals you set. dtime runs on your own computer and
keeps everything on your disk. No account and no cloud. This repository contains the
installer and the releases.

## Install

Use a Linux desktop running Hyprland with systemd (Omarchy works out of the box). Run
this as your normal user, not as root:

```sh
curl -fsSL https://github.com/mfbaltaza/dtime-releases/releases/latest/download/install.sh | bash
```

The installer needs curl, tar, sha256sum and Python 3.9 or newer. Everything goes into
your home folder, so it never asks for a password. dtime starts as a user service,
starts again when you sign in, and the dashboard opens when the install finishes.

Later, open **dtime** in your app launcher, run `dtime-open`, or visit
<http://127.0.0.1:8787>.

## Browser extension

Without the extension dtime knows you were in the browser, but not on which site.

On Omarchy the installer adds the extension to Chromium for you. Restart Chromium once.

On other setups, open `chrome://extensions`, turn on **Developer mode**, choose
**Load unpacked** and pick `~/.local/share/dtime/extension`. It needs no token or
settings on the same computer.

The dashboard shows a warning when the extension has never reported or has gone quiet.

## Update

Run the install command again. Your tracked time, your goals and your token are kept.
The version you are running is shown under **Settings** in the dashboard, and by
`dtime --version`.

## Remove

```sh
curl -fsSL https://github.com/mfbaltaza/dtime-releases/releases/latest/download/install.sh | bash -s -- --uninstall
```

This removes the app and leaves your data in place. To delete the data as well, remove
`~/.local/share/dtime` and `~/.config/dtime`.

## Where things are

| What | Where |
| --- | --- |
| Tracked time | `~/.local/share/dtime/dtime.db` |
| Goals | `~/.config/dtime/goals.json` (edit them in the dashboard) |
| Token for other devices | `~/.config/dtime/token`, or run `dtime --print-token` |
| The app itself | `~/.local/share/dtime/app` (replaced on update) |

To change how apps and sites are categorised, copy `rules.json` or `names.json` from
the app folder into `~/.config/dtime/`, edit the copy, and run
`systemctl --user restart dtime`. An update leaves your copy alone.

## If something is wrong

- **The install says startup failed:** run `journalctl --user -u dtime -n 50`.
- **Port 8787 is in use:** another program has it. Stop that program and install again.
- **No time is tracked:** dtime reads the active window from Hyprland. Other desktops
  are not supported yet.
- **No tray icon:** the tray needs the AyatanaAppIndicator3 GTK bindings. The dashboard
  works without it.
