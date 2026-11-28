# adb-record

Record the screen of an Android device. When you stop, the video is pulled to your Mac and deleted from the device.

```bash
adb-record checkout-crash
```

Press **Enter** (or **Ctrl+C**) to stop. The video lands at `~/Desktop/checkout-crash.mp4`.

## Usage

```
adb-record [-T] [-l seconds] [-o dir] [name]
```

| Option | What it does | Default |
| --- | --- | --- |
| `name` | Filename for the video. `.mp4` is added if missing. | `screenrecord-<model>-<timestamp>.mp4` |
| `-T` | Don't show taps for this recording. | Taps shown |
| `-l seconds` | Stop automatically after this many seconds (max 180). `0` means no limit. | `0` (no limit) |
| `-o dir` | Folder to save the video in. | `~/Desktop` |
| `-h` | Show help. | |

Options go before the name: `adb-record -T -o ~/Movies basket-bug`. Quote names with spaces: `adb-record "login freeze"`.

## Examples

```bash
adb-record                      # timestamped name on the Desktop
adb-record search-empty-state   # ~/Desktop/search-empty-state.mp4
adb-record -l 30 splash-delay   # stops by itself after 30 seconds
adb-record -T -o ~/Movies demo  # no tap circles, saved to ~/Movies
```

## How it works

1. **Picks a device.** One device attached: it's used automatically. More than one: you choose from a list showing model name and serial. With [fzf](../README.md#4-fzf-optional) installed you type to filter and press Enter; without it you get a numbered menu (or set `ANDROID_TOOLS_NO_FZF=1` to keep the numbered menu). Esc cancels.
2. **Turns on Show taps** (unless `-T`), so every touch appears as a circle in the video. Your previous setting is restored when the script exits, even after Ctrl+C.
3. **Records** with `adb shell screenrecord` to `/sdcard/screenrecord-<timestamp>.mp4`.
4. **Stops cleanly.** Enter or Ctrl+C sends an interrupt to `screenrecord` on the device, which lets it finish writing the MP4. Killing it abruptly would leave a file that won't play.
5. **Pulls** the video to your Mac. Names are never overwritten: if the file exists you get `name-2.mp4`, `name-3.mp4`, and so on.
6. **Deletes** the copy on the device, but only if the pull succeeded. If the pull fails, the script prints where the video is on the device.

## Changing the defaults

The built-in defaults are the block at the top of the script:

```bash
show_taps=1             # 1 = show taps while recording, 0 = don't
limit=0                 # seconds, max 180; 0 = unlimited (Android 14+, else 180)
outdir="$HOME/Desktop"  # where videos are saved
```

To change them for good, use the config file below. Don't edit the script: your edits get in the way when you update. Command-line options override both for a single run.

## Config file

adb-record reads `~/.config/android-tools/adb-record.conf` after its built-in defaults, or the same path under `$XDG_CONFIG_HOME` if you set it. `adb-record -h` prints the exact path. The file is optional, and updates and `install.sh` never create, change or remove it.

```
# ~/.config/android-tools/adb-record.conf
limit=60
outdir=~/Movies/bugs
```

- One `NAME=value` per line. Blank lines and lines starting with `#` are skipped. Comments go on their own line, not after a value.
- Names are the ones in the block above. Anything else is an error.
- Quotes around a value are optional. `~/`, `$HOME/` or `${HOME}/` at the start of a value means your home folder. Nothing else is expanded, and the file is never run as a script.
- A bad line stops adb-record with a message naming the file, the line and the setting.

## Notes and limits

- **No time limit needs Android 14 (API 34) or later.** On older devices the script prints a note and records for up to 180 seconds instead.
- **No audio.** `screenrecord` captures video only.
- **Protected content records as black.** Apps that block screen capture (DRM video, banking screens) show as black frames. This is the app's doing, not the script's.
- **Foldables:** `screenrecord` records the screen that's in use.
- **Requirements:** `adb` on your PATH and USB debugging turned on for the device.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `adb not found on PATH` | Add `$ANDROID_HOME/platform-tools` to PATH (see the [Toolbox README](../README.md#setup)). |
| `No devices connected` | Run `adb devices`. If it says `unauthorized`, unlock the phone and accept the USB debugging prompt. |
| Video won't play | The recording was killed before it finished writing. Stop with Enter or Ctrl+C, not by unplugging the phone or closing the terminal. |
| Taps stayed on afterwards | The script was killed hard (closing the terminal window). Run `adb shell settings put system show_touches 0`. |
