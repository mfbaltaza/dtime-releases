# dtime

See where your time on the computer goes: which apps, which sites, how much of it was
productive, and whether you met the goals you set. dtime runs on your own computer and
keeps everything on your disk. No account and no cloud. This repository contains the
installer and the releases.

dtime runs on Linux desktops (Hyprland) and on Windows 10 and 11. Same app, same
dashboard, same data on your disk.

## Install on Linux

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

## Install on Windows

1. Download <https://github.com/mfbaltaza/dtime-releases/releases/latest/download/dtime-windows.zip>
2. Right-click the file, choose **Extract All**, and open the extracted `dtime` folder.
3. Double-click `packaging\windows\install.cmd`.

No administrator, no settings to edit.

The installer needs Python 3.9 or newer. If Python is missing it prints the
python.org link and stops; tick **Add python.exe to PATH** while installing it,
then run the file again. Everything lands in `%LOCALAPPDATA%\dtime`, the tracker
starts hidden (no console window), the dashboard opens
(http://127.0.0.1:8787/), and dtime starts again at logon. If a scheduled task
is blocked by policy the installer falls back to the Startup folder, and it says
which one it used.

One step is left on purpose, because browsers allow it only by hand: open
`chrome://extensions` (or `edge://extensions`), turn on **Developer mode**,
choose **Load unpacked** and pick `%LOCALAPPDATA%\dtime\extension`. Without it
dtime knows you were in a browser but not on which site. The extension opens
its options page and confirms the connection; it needs no token on the same PC.

Built to stay out of the way while you game: the tracker runs under
`pythonw.exe`, below normal priority, and only calls Windows functions (no
helper programs), sampling every 5 seconds.

Three files sit next to the installer copy:
`doctor.cmd` prints one paste-friendly block (python, tracker, auto-start,
port, last log lines) when something looks wrong, `dtime-open.cmd` opens the
dashboard and starts the tracker if needed, and `uninstall.cmd` removes the app
while keeping your tracked time.

## Browser extension

Without the extension dtime knows you were in the browser, but not on which site.

On Arch and Omarchy the installer sets Chromium and Brave to load the extension. The
browser only reads that setting when it starts, so quit it completely, web apps
included (`pkill chromium`), and open it again.

Google Chrome ignores that setting, and other distributions do not have it. There,
open `chrome://extensions`, turn on **Developer mode**, choose **Load unpacked** and
pick `~/.local/share/dtime/extension`. It needs no token or settings on the same
computer.

The dashboard shows a warning when the extension has never reported or has gone quiet.

## Update

Run the install command again. Your tracked time, your goals and your token are kept.
The version you are running is shown under **Settings** in the dashboard, and by
`dtime --version`. On Windows, download `dtime-windows.zip` again, extract it, and
double-click `packaging\windows\install.cmd` from the new `dtime` folder; your data
and token are kept.

## Remove

On Linux:
```sh
curl -fsSL https://github.com/mfbaltaza/dtime-releases/releases/latest/download/install.sh | bash -s -- --uninstall
```
On Windows run `uninstall.cmd` from the app folder.

Both leave your data in place. To delete the data as well, remove
`~/.local/share/dtime` and `~/.config/dtime` on Linux, or
`%LOCALAPPDATA%\dtime` and `%APPDATA%\dtime` on Windows.

## Where things are

| What | Linux | Windows |
| --- | --- | --- |
| Tracked time | `~/.local/share/dtime/dtime.db` | `%LOCALAPPDATA%\dtime\dtime.db` |
| Goals | `~/.config/dtime/goals.json` (edit them in the dashboard) | `%APPDATA%\dtime\goals.json` |
| Token for other devices | `~/.config/dtime/token`, or run `dtime --print-token` | `%APPDATA%\dtime\token` |
| The app itself | `~/.local/share/dtime/app` (replaced on update) | `%LOCALAPPDATA%\dtime\app` |
| Extension folder | `~/.local/share/dtime/extension` | `%LOCALAPPDATA%\dtime\extension` |

To change how apps and sites are categorised, copy `rules.json` or `names.json` from
the app folder into the config folder, edit the copy, and restart the tracker
(`systemctl --user restart dtime` on Linux, or rerun the tracker on Windows). An
update leaves your copy alone. On Windows, app rules and names match the
executable name without `.exe` (`chrome`, `steam`, `explorer`).

## If something is wrong

- **The install says startup failed (Linux):** run `journalctl --user -u dtime -n 50`.
- **Windows, nothing is tracked:** run `doctor.cmd` and share the whole output. The
  dashboard Settings panel shows the platform, the sample interval and when the
  tracker last wrote, and warns when that goes stale.
- **Port 8787 is in use:** another program has it. Stop that program and install again.
- **No time is tracked (Linux):** dtime reads the active window from Hyprland. Other
  Linux desktops are not supported yet.
- **No tray icon:** the tray needs the AyatanaAppIndicator3 GTK bindings and runs on
  Linux only. The dashboard works everywhere and is the Windows interface.
