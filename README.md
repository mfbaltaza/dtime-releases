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

Windows 10 and 11 need Python 3.10 or newer from python.org. Use the full installer and
tick **Add python.exe to PATH** on its first screen. Python from the Microsoft Store is
refused. The Store version keeps registry changes in a private copy, so the sign-in entry
dtime needs may not start it. The installer says so and stops.

1. Download <https://github.com/mfbaltaza/dtime-releases/releases/latest/download/dtime-windows.zip>
2. Right-click the file, choose **Extract All**, and open the extracted `dtime` folder.
3. Double-click `packaging\windows\install.cmd`.

No administrator rights are needed, and nothing needs editing. Run the installer from the
extracted folder. It needs the other files beside it. If they are missing, for example
because you ran it from inside the zip, it stops before it changes anything.

The installer:

- Copies the app to `%LOCALAPPDATA%\dtime\app`. It stages the new copy in a per-run
  `install-*` folder under `%LOCALAPPDATA%\dtime`, beside your current copy in `old`.
  A completed install deletes that folder.
- Waits until the installed copy records a sample of its own before it reports success.
  Time recorded earlier, by another copy of dtime, does not count.
- If the install fails after it has stopped the tracker, it puts back the `app` folder,
  the files beside it (`doctor.cmd`, `uninstall.cmd`, `dtime-open.cmd`, and the extension
  folder), and the sign-in entry, and starts the previous copy again if it was running.
  A rollback is not guaranteed. If the new tracker will not stop, or a restore step
  fails, the installer keeps the `install-*` folder with the previous copy and the
  outside-file copies, prints that path as the recovery copy, and does not claim the old
  copy is back.
- Adds a sign-in entry named `dtime` under `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`.
  At sign-in, Windows starts `pythonw.exe` with `app\dtsupervise.py`. That starts the
  tracker with no console window and starts it again if it crashes.
- Opens <http://127.0.0.1:8787/> once the tracker is recording. If the tracker does not
  start, the installer exits with an error and names `doctor.cmd`.
- Stops and changes nothing when port 8787 answers from something that is not dtime's own
  tracker.

One step stays manual, because browsers load extensions only from their own settings
page. Open `chrome://extensions` (or `edge://extensions`), turn on **Developer mode**,
choose **Load unpacked**, and pick `%LOCALAPPDATA%\dtime\extension`. The folder keeps the
same path across updates, so you load it once. Without the extension, dtime knows you
were in a browser but not which site. The dashboard warns you while the extension has not
reported.

You do not paste a token on this PC. The dashboard fills in the token itself. A token is
needed only from another device.

`doctor.cmd` prints one block you can paste into a message. It shows the Python version
and path, the install folder, the sign-in entry, and the Task Manager startup setting for
dtime. The tracker line gives its state. `tracking` means dtime is recording. `impostor`
means the server on port 8787 answered, but not as dtime's own tracker. doctor reports
only that the answer was not dtime. The block ends with the last lines of the logs.

Built to stay out of the way while you game: the tracker runs under `pythonw.exe`, below
normal priority, and only calls Windows functions. It samples every 5 seconds and starts no
helper programs.

## Update

Run `install.cmd` from the new `dtime` folder, as in the first install. Your tracked time,
goals and token are kept. The version you are running is shown under **Settings** in the
dashboard, and by `dtime --version`.

On Linux, run the install command again.

Updating from v0.1.2 also removes the old scheduled task named `dtime`, the Startup folder
entry `dtime-run.vbs`, and the old VBScript helper files. The sign-in entry replaces them.
The installer removes those entries only after the new tracker is recording. If the
removal fails, it keeps its legacy marker in place, says which entry remains, and asks you
to run `install.cmd` again. That run retries the removal instead of treating the old
install as gone.

## Remove

On Linux:
```sh
curl -fsSL https://github.com/mfbaltaza/dtime-releases/releases/latest/download/install.sh | bash -s -- --uninstall
```

On Windows, run `uninstall.cmd` from `%LOCALAPPDATA%\dtime`. It stops the tracker, removes
the sign-in entry, the app and the extension folder, and keeps your data. If a file is
held open, it stops partway, keeps `uninstall.cmd` and the files it needs, and says to run
it again. Remove dtime from `chrome://extensions` (or `edge://extensions`) too, because the
browser still lists the deleted folder.

The install root keeps `uninstall.cmd`, `dtsetup.py`, `dtinstance.py`, and `dtplatform.py`
so a later retry can run even after the app folder is gone. An incomplete rollback also
keeps its `install-*` recovery folder and `RECOVERY.json`. `doctor.cmd` lists these
recovery folders while the installed doctor is available.

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
| Sign-in entry | user service `~/.config/systemd/user/dtime.service` | `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`, value `dtime` |
| Lock file | `~/.local/share/dtime/dtime.db.lock` | `%LOCALAPPDATA%\dtime\dtime.db.lock` |
| Crash log | `journalctl --user -u dtime` | `%LOCALAPPDATA%\dtime\dtime-crash.log` |

The lock file is empty. The tracker holds it while it runs, so leave it in place.

To change how apps and sites are categorised, copy `rules.json` or `names.json` from
the app folder into the config folder, edit the copy, and restart the tracker
(`systemctl --user restart dtime` on Linux, or run `install.cmd` again on Windows). An
update leaves your copy alone. On Windows, app rules and names match the executable name
without `.exe` (`chrome`, `steam`, `explorer`).

## If something is wrong

- **The install says startup failed (Linux):** run `journalctl --user -u dtime -n 50`.
- **The Linux service exits with code 3:** another copy already tracks this database.
  Stop that copy, then run `systemctl --user restart dtime`. To find a copy you started by
  hand, run `pgrep -af dtime.py`.
- **Windows, nothing is tracked:** run `doctor.cmd` and share the whole output.
- **Windows, the installer refuses Python:** the Python it found comes from the Microsoft
  Store. Install the full installer from python.org, then run `install.cmd` again.
- **Port 8787 is in use:** something that is not dtime's own tracker answers on it. Stop
  that server and install again.
- **Windows, dtime is missing from the sign-in list:** open Task Manager, go to the
  **Startup** tab, and enable dtime. `doctor.cmd` reports whether it is turned off.
- **No time is tracked (Linux):** dtime reads the active window from Hyprland. Other
  Linux desktops are not supported yet.
- **No tray icon:** the tray needs the AyatanaAppIndicator3 GTK bindings and runs on
  Linux only. The dashboard works everywhere and is the Windows interface.

## Known limits on Windows

- This Windows build has not run on a real PC. The installer and the tracker were tested
  on Linux with a fake Windows layer. If you try it, send the `doctor.cmd` output whether
  it works or not.
- Two Windows accounts on one PC share port 8787. While the first account's tracker runs,
  the second account's tracker cannot start, so it does not track.
- The update from v0.1.2 stops the old copies by matching their command line. That step
  has not run on a real PC.
- A rollback can fail. If the new tracker will not stop, the installer cannot put the
  previous copy back while that process runs. It keeps the recovery folder and prints its
  path, then asks you to run `doctor.cmd`.
