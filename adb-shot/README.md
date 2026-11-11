# adb-shot

Take a screenshot of an Android device and save it to your Mac. The image is also copied to the clipboard, ready to paste into a ticket or Slack.

```bash
adb-shot basket-overlap
```

The image lands at `~/Desktop/basket-overlap.png`.

## Usage

```
adb-shot [-d seconds] [-n count] [-o dir] [-D display] [-c|-C] [-p] [-L] [name]
```

| Option | What it does | Default |
| --- | --- | --- |
| `name` | Filename. `.png` is added if missing. | `screenshot-<model>-<timestamp>.png` |
| `-d seconds` | Count down before taking the shot, so you can get the screen ready. | `0` |
| `-n count` | Take a numbered series, one shot per Enter press. | `1` |
| `-o dir` | Folder to save in. | `~/Desktop` |
| `-c` / `-C` | Copy / don't copy the image to the clipboard. | Copy |
| `-p` | Open the image(s) in Preview afterwards. | Off |
| `-D id` | Capture a specific screen on a multi-screen device. | The screen that's switched on |
| `-L` | List the device's screen IDs and exit. | |
| `-h` | Show help. | |

Options go before the name. Quote names with spaces.

## Examples

```bash
adb-shot                         # timestamped name, copied to clipboard
adb-shot -d 5 menu-clipped       # 5-second countdown to open a menu first
adb-shot -n 4 checkout-steps     # checkout-steps-1.png ... checkout-steps-4.png
adb-shot -p -C hero-crop         # open in Preview, leave the clipboard alone
```

## Step-by-step series (`-n`)

`-n` is for repro steps. The script prompts `Shot 1/4: press Enter to capture...`, so you can move through the app on the phone and press Enter at each step. Files are numbered `name-1.png`, `name-2.png`, and so on. The last shot is copied to the clipboard.

## Foldables and multi-screen devices

Phones like the Pixel Fold have more than one screen. The script captures whichever screen is switched on, so folded and unfolded both work without options.

To capture a particular screen, list the IDs and pass one with `-D`:

```bash
adb-shot -L
adb-shot -D 4619827677550801153 inner-screen
```

## How it works

1. **Picks a device**, the same way as `adb-record`: automatically if there's one, from a list if there are several.
2. **Finds the active screen** from `dumpsys SurfaceFlinger` (the display whose power mode is On), unless you passed `-D`.
3. **Captures** with `adb exec-out screencap -p`, which streams the PNG straight to your Mac. Nothing is saved on the device, so there's nothing to clean up.
4. **Checks the file.** Any text Android prints before the image data is stripped, and the file must start with a PNG signature. If not, the script deletes it and reports an error, so you never get a file that won't open.
5. **Never overwrites:** if the file exists you get `name-2.png`, `name-3.png`, and so on.
6. **Copies** the image to the clipboard with `osascript`.

## Changing the defaults

Edit the block at the top of the script:

```bash
outdir="$HOME/Desktop"  # where screenshots are saved
copy=1                  # 1 = also copy the image to the clipboard
open_after=0            # 1 = open the image in Preview afterwards
delay=0                 # seconds to wait before taking the shot
```

## Notes and limits

- **No tap circles.** Android only draws them while a finger is on the screen. Use `adb-record` to show where to tap, or mark up the image afterwards.
- **Protected content captures as black.** Apps that block screen capture (DRM video, banking screens) come out black.
- **Requirements:** `adb` on your PATH and USB debugging turned on for the device.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `adb not found on PATH` | Add `$ANDROID_HOME/platform-tools` to PATH (see the [Toolbox README](../README.md#setup)). |
| `No devices connected` | Run `adb devices`. If it says `unauthorized`, unlock the phone and accept the USB debugging prompt. |
| Image is black | Either the app blocks capture, or the wrong screen was captured on a foldable. Run `adb-shot -L` and try `-D`. |
| `the device didn't return a PNG` | Usually a bad `-D` display ID. Check it with `-L`. |
