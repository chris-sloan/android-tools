# Toolbox

A set of simple quality of life Android helper tools.

## Tools

| Tool | What it does | Quick use |
| --- | --- | --- |
| [adb-record](adb-record/README.md) | Record an Android screen with taps shown, then pull the video to your Mac. | `adb-record checkout-crash`, then press Enter to stop |
| [adb-shot](adb-shot/README.md) | Screenshot an Android screen to your Mac and the clipboard. | `adb-shot basket-overlap` |

Every tool prints its options with `-h`. Each tool's README has the full details.

## Quick reference

```bash
adb-record                     # record until Enter; taps shown; saved to Desktop
adb-record login-freeze        # saved as ~/Desktop/login-freeze.mp4
adb-record -l 30 splash-delay  # stop after 30 seconds
adb-record -T demo             # no tap circles
adb-record -T -l 60 -o ~/Movies "checkout crash"   # every option: options first, name last

adb-shot                       # screenshot to Desktop and clipboard
adb-shot basket-overlap        # saved as ~/Desktop/basket-overlap.png
adb-shot -d 5 menu-clipped     # 5-second countdown first
adb-shot -n 4 checkout-steps   # numbered series, Enter for each shot
adb-shot -L                    # list screen IDs (foldables), for use with -D
adb-shot -d 3 -n 2 -o ~/Pictures -D <id> -C -p "menu clipped"   # every option: options first, name last
```

## Setup

### 1. Android SDK tools on your PATH

The Android tools need `adb`. Add these lines to `~/.zshrc`:

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/build-tools/36.0.0"
```

Then open a new terminal tab, or run `source ~/.zshrc`.

> **Maintain the build-tools version by hand.** `build-tools/36.0.0` is the version installed when this was written. Your SDK may not have it, or may have a newer one, and the path doesn't update itself. Check what you have with `ls "$ANDROID_HOME/build-tools"` and put that version in the line above. Only `aapt2`, `apksigner`, `zipalign` and `d8` come from build-tools; the tools in this folder only need `platform-tools` (for `adb`).

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
└── <tool>/
    ├── <tool>         the script
    └── README.md      full docs
```

## Adding a tool

1. Make a folder named after the tool, with an executable script of the same name inside: `my-tool/my-tool`.
2. Start the script with a defaults block and a `-h` help message, like the existing tools.
3. Add a `README.md` in its folder: a one-line summary, usage (including argument order), defaults, examples, how it works, and troubleshooting. Keep it self-contained; don't describe one tool's behaviour in terms of another's.
4. Add a row to the **Tools** table and a few lines to the **Quick reference** above, including one example that uses every option.
5. Run `./install.sh` to put it on your PATH.
