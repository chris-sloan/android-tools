# Toolbox

Small command-line tools for testing mobile apps and capturing evidence of bugs.

## Tools

| Tool | What it does | Quick use |
| --- | --- | --- |
| [adb-record](adb-record/README.md) | Record an Android screen with taps shown, then pull the video to your Mac. | `adb-record checkout-crash`, then press Enter to stop |
| [adb-shot](adb-shot/README.md) | Screenshot an Android screen to your Mac and the clipboard. | `adb-shot basket-overlap` |

Every tool prints its options with `-h`. Each tool's README has the full details.

## Quick reference

```bash
adb-record                     # record until Enter; taps shown; saved to Desktop
adb-record -l 30 splash-delay  # stop after 30 seconds
adb-record -T demo             # no tap circles

adb-shot                       # screenshot to Desktop and clipboard
adb-shot -d 5 menu-clipped     # 5-second countdown first
adb-shot -n 4 checkout-steps   # numbered series, Enter for each shot
```

Both tools:
- pick the device automatically, or ask if more than one is attached
- save to `~/Desktop` (change with `-o dir`)
- take an optional filename and never overwrite an existing file

## Setup

### 1. Android SDK tools on your PATH

The Android tools need `adb`. Add these lines to `~/.zshrc`:

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/build-tools/36.0.0"
```

Then open a new terminal tab, or run `source ~/.zshrc`.

### 2. Install the tools

```bash
./install.sh
```

This links each tool into `~/.local/bin`, which must be on your PATH. Because they're links, edits to the scripts here take effect straight away.

### 3. Device

Turn on **Developer options** (tap **Settings → About phone → Build number** 7 times), then **USB debugging**. Plug the phone in and accept the prompt. Check with `adb devices`.

## Layout

```
Tools/
├── README.md          this file
├── install.sh         links every tool into ~/.local/bin
├── adb-record/
│   ├── adb-record     the script
│   └── README.md      full docs
└── adb-shot/
    ├── adb-shot
    └── README.md
```

## Adding a tool

1. Make a folder named after the tool, with an executable script of the same name inside: `my-tool/my-tool`.
2. Start the script with a defaults block and a `-h` help message, like the existing tools.
3. Add a `README.md` in its folder: a one-line summary, usage, examples, how it works, and troubleshooting.
4. Add a row to the **Tools** table above.
5. Run `./install.sh` to put it on your PATH.
