#!/usr/bin/env bash
# Install or update dtime on this computer:
#
#   curl -fsSL https://github.com/mfbaltaza/dtime-releases/releases/latest/download/install.sh | bash
#
# Everything goes into your home folder; nothing needs root. Run it again to
# update. Your tracked time, token and goals are kept.
#
#   bash install.sh --uninstall   remove the app, keep your data
#   DTIME_VERSION=vX.Y.Z          install that release instead of the latest
#   DTIME_NO_START=1              install without starting or opening anything
#   DTIME_RELEASE_BASE            where the files are downloaded from
set -euo pipefail
# The whole script is one function, called on the last line, so a download
# that stops halfway runs nothing.
main() {
release_tag='v0.1.3' # The release builder stamps this value.
repo=mfbaltaza/dtime-releases
base=${DTIME_RELEASE_BASE:-https://github.com/$repo/releases}
bundle=dtime.tar.gz
port=8787
url=http://127.0.0.1:$port
share=${XDG_DATA_HOME:-$HOME/.local/share}
conf=${XDG_CONFIG_HOME:-$HOME/.config}
bin=$HOME/.local/bin
data=$share/dtime
app=$data/app
config=$conf/dtime
unit=$conf/systemd/user/dtime.service
launcher=$share/applications/dtime.desktop
icon=$share/icons/hicolor/scalable/apps/dtime.svg
autostart=$conf/autostart/dtime-tray.desktop
no_start=${DTIME_NO_START:-0}
die() { printf 'dtime: %s\n' "$*" >&2; exit 1; }
[[ $(uname -s) == Linux ]] || die 'This installer requires Linux.'
if [[ ${1:-} == --uninstall ]]; then
  if [[ $no_start != 1 ]]; then systemctl --user disable --now dtime.service >/dev/null 2>&1 || true; fi
  rm -f "$bin/dtime" "$bin/dtime-open" "$bin/dtime-tray" "$unit" "$launcher" "$icon" "$autostart"
  rm -rf "$app" "$data/extension"
  if [[ $no_start != 1 ]]; then systemctl --user daemon-reload || true; fi
  printf 'dtime removed. Your tracked time stays in %s, your token and goals in %s\n' "$data" "$config"
  for file in "$conf"/chromium-flags.conf "$conf"/brave-flags.conf "$conf"/chrome-flags.conf; do
    if [[ -f $file ]] && grep -qF "$data/extension" "$file"; then
      printf 'Your browser still lists %s in %s. Remove that path if you never want it back.\n' "$data/extension" "$file"
    fi
  done
  exit 0
fi
[[ $# == 0 ]] || die 'Supported argument: --uninstall'
for tool in curl tar sha256sum python3; do command -v "$tool" >/dev/null || die "Install $tool first."; done
python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))' || die 'Python 3.9 or newer is required.'
if [[ $no_start != 1 ]]; then
  command -v systemctl >/dev/null || die 'A systemd user session is required.'
  systemctl --user show-environment >/dev/null || die 'Run this in your desktop user session.'
fi
command -v hyprctl >/dev/null || printf 'note: Hyprland was not found. dtime reads the active window from Hyprland, so no time will be tracked here.\n'
if [[ $release_tag == @* ]]; then
  release_tag=${DTIME_VERSION:-}
  if [[ -z $release_tag ]]; then
    effective=$(curl -fsSL -o /dev/null -w '%{url_effective}' "$base/latest")
    release_tag=${effective##*/}
  fi
fi
[[ $release_tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]] || die 'Could not resolve a release. Set DTIME_VERSION=vX.Y.Z.'
mkdir -p "$data"
stage=$(mktemp -d "$data/.install.XXXXXX")
replacing=0
restore() {
  if [[ $no_start != 1 ]]; then systemctl --user stop dtime.service >/dev/null 2>&1 || true; fi
  rm -rf "$app"
  if [[ -d $stage/backup/app ]]; then mv "$stage/backup/app" "$app"; fi
  if [[ -f $stage/backup/dtime.service ]]; then cp -p "$stage/backup/dtime.service" "$unit"; else rm -f "$unit"; fi
  if [[ $no_start != 1 ]]; then
    systemctl --user daemon-reload || true
    if [[ -f $stage/backup/dtime.service ]]; then systemctl --user start dtime.service || true; fi
  fi
}
cleanup() { local status=$?; if ((replacing && status != 0)); then restore; printf 'Previous installation restored.\n' >&2; fi; rm -rf "$stage"; }
trap cleanup EXIT
curl -fsSL "$base/download/$release_tag/$bundle" -o "$stage/$bundle"
curl -fsSL "$base/download/$release_tag/SHA256SUMS" -o "$stage/SHA256SUMS"
expected=$(awk -v name="$bundle" '$2 == name { print $1 }' "$stage/SHA256SUMS")
[[ $expected =~ ^[a-fA-F0-9]{64}$ ]] || die 'The checksum manifest must contain exactly one entry for the download.'
actual=$(sha256sum "$stage/$bundle"); actual=${actual%% *}
[[ ${actual,,} == "${expected,,}" ]] || die 'Checksum mismatch. Existing installation was not changed.'
tar -xzf "$stage/$bundle" -C "$stage"
[[ -f $stage/dtime/dtime.py ]] || die 'The download is not a dtime release.'
# Asked with its own folders so the check itself leaves nothing behind.
got=$(XDG_CONFIG_HOME="$stage/probe" XDG_DATA_HOME="$stage/probe" python3 "$stage/dtime/dtime.py" --version)
[[ $got == "$release_tag" ]] || die 'The downloaded app has the wrong version.'
# The dtime service is replaced below. Anything else on the port is not ours to stop.
if [[ $no_start != 1 ]] && ! systemctl --user is-active --quiet dtime.service && curl -fsS --max-time 2 -o /dev/null "$url/" 2>/dev/null; then
  die "Port $port is in use by another program (a dtime started by hand counts). Stop it and run this again."
fi
mkdir -p "$stage/backup" "$bin" "$config" "$(dirname "$unit")" "$(dirname "$launcher")" "$(dirname "$icon")" "$(dirname "$autostart")"
if [[ -f $unit ]]; then cp -p "$unit" "$stage/backup/dtime.service"; fi
replacing=1
if [[ $no_start != 1 && -f $stage/backup/dtime.service ]]; then systemctl --user stop dtime.service; fi
if [[ -d $app ]]; then mv "$app" "$stage/backup/app"; fi
mv "$stage/dtime" "$app"
# Goals are edited from the dashboard, so they live with the token and an update never resets them.
[[ -f $config/goals.json ]] || cp "$app/goals.json" "$config/goals.json"
ln -sfn "$app/dtime.py" "$bin/dtime"
ln -sfn "$app/bin/dtime-open" "$bin/dtime-open"
ln -sfn "$app/bin/dtime-tray" "$bin/dtime-tray"
cp "$app/assets/dtime.svg" "$icon"
desktop_quote() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//\$/\\\$}; s=${s//\`/\\\`}; s=${s//%/%%}; printf '"%s"' "$s"; }
sed "s|^Exec=.*|Exec=$(desktop_quote "$bin/dtime-open" | sed 's/[&|\\]/\\&/g')|" "$app/packaging/dtime.desktop" > "$launcher"
# The tray needs the system GTK bindings. Without them the dashboard still does everything.
if python3 -c 'import gi; gi.require_version("AyatanaAppIndicator3", "0.1"); gi.require_version("Gtk", "3.0")' 2>/dev/null; then
  sed "s|^Exec=.*|Exec=$(desktop_quote "$bin/dtime-tray" | sed 's/[&|\\]/\\&/g')|" "$app/packaging/dtime-tray-autostart.desktop" > "$autostart"
  tray=1
else
  rm -f "$autostart"
  tray=0
fi
systemd_quote() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//%/%%}; printf '"%s"' "$s"; }
{
  printf '[Unit]\nDescription=dtime self-hosted time tracker\nAfter=graphical-session.target\n\n[Service]\nExecStart=/usr/bin/env python3 '
  systemd_quote "$app/dtime.py"
  printf ' --host 127.0.0.1 --port %s\nEnvironment=' "$port"
  systemd_quote "XDG_CONFIG_HOME=$conf"
  printf '\nEnvironment='
  systemd_quote "XDG_DATA_HOME=$share"
  printf '\nRestart=on-failure\n\n[Install]\nWantedBy=default.target\n'
} > "$unit"
# The extension gets a copy at a path that stays the same across updates,
# because the browser remembers where it was loaded from.
rm -rf "$data/extension"
cp -r "$app/extension" "$data/extension"
# Chromium-family browsers on Arch and Omarchy read extra flags from a file,
# which is the only way to load an extension without clicking through
# chrome://extensions. Arch's Chromium reads the file even when it is absent
# so far, so it is created there.
added=() running=()
for entry in chromium:chromium-flags.conf:Chromium:chromium/chromium brave:brave-flags.conf:Brave:/brave google-chrome-stable:chrome-flags.conf:Chrome:/chrome/chrome; do
  IFS=: read -r program file label process <<<"$entry"
  file=$conf/$file
  if [[ ! -f $file ]]; then
    [[ $program == chromium && -f /etc/arch-release ]] && command -v chromium >/dev/null || continue
    : > "$file"
  fi
  if ! grep -qF "$data/extension" "$file"; then
    [[ ! -s $file ]] || cp -p "$file" "$file.pre-dtime"
    python3 - "$file" "$data/extension" <<'PY'
import sys
from pathlib import Path
path, ext = Path(sys.argv[1]), sys.argv[2]
lines = path.read_text().splitlines()
for i, line in enumerate(lines):
    if line.startswith('--load-extension='):
        lines[i] = line + ',' + ext
        break
else:
    lines.append('--load-extension=' + ext)
path.write_text('\n'.join(lines) + '\n')
PY
  fi
  added+=("$label")
  if pgrep -f "$process( |\$)" >/dev/null 2>&1; then running+=("$label"); fi
done
if command -v gtk-update-icon-cache >/dev/null; then gtk-update-icon-cache -q -t -f "${icon%/scalable/apps/*}" >/dev/null 2>&1 || true; fi
if command -v update-desktop-database >/dev/null; then update-desktop-database "$(dirname "$launcher")" >/dev/null 2>&1 || true; fi
if [[ $no_start != 1 ]]; then
  systemctl --user daemon-reload
  systemctl --user enable dtime.service >/dev/null 2>&1 || true
  systemctl --user restart dtime.service
  ready=0
  for ((i=0;i<50;i++)); do
    if systemctl --user is-active --quiet dtime.service && curl -fsS --max-time 1 -o /dev/null "$url/" 2>/dev/null; then ready=1; break; fi
    sleep 0.2
  done
  ((ready)) || die 'Startup failed. Inspect journalctl --user -u dtime.'
fi
replacing=0
printf 'dtime %s installed.\n' "$release_tag"
manual() { printf '  open chrome://extensions, turn on Developer mode, choose "Load unpacked" and pick\n  %s\n' "$data/extension"; }
if ((${#added[@]})); then
  printf 'Browser extension: set to load in %s.\n' "${added[*]}"
  if ((${#running[@]})); then
    printf '  %s is running and only reads this when it starts. Quit it completely, web apps included\n  (pkill %s), and open it again.\n' "${running[*]}" "$(tr 'A-Z' 'a-z' <<<"${running[0]}")"
  fi
  printf '  If the dashboard still says the extension never reported (Google Chrome ignores this setting):\n'
  manual
else
  printf 'Browser extension: this browser has to be told by hand. In Chromium, Chrome or Brave,\n'
  manual
fi
printf '  Without it, time in the browser is tracked but not which site.\n'
((tray)) || printf 'Tray icon: skipped, the AyatanaAppIndicator3 bindings are not installed.\n'
case ":$PATH:" in *":$bin:"*) ;; *) printf 'note: %s is not on your PATH, so type %s/dtime-open where these lines say dtime-open.\n' "$bin" "$bin";; esac
if [[ $no_start == 1 ]]; then printf 'Nothing was started.\n'; return; fi
printf 'Open dtime from your app launcher, or run: dtime-open\n'
if [[ -n ${WAYLAND_DISPLAY:-}${DISPLAY:-} ]]; then
  if ((tray)); then (setsid "$bin/dtime-tray" >/dev/null 2>&1 </dev/null &) || true; fi
  (setsid "$bin/dtime-open" >/dev/null 2>&1 </dev/null &) || true
fi
}
main "$@"
