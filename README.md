# Toolbox

A set of simple quality of life Android helper tools.

## Tools

| Tool | What it does | Quick use |
| --- | --- | --- |
| [adb-record](adb-record/README.md) | Record an Android screen with taps shown, then pull the video to your Mac. | `adb-record checkout-crash`, then press Enter to stop |
| [adb-shot](adb-shot/README.md) | Screenshot an Android screen to your Mac and the clipboard. | `adb-shot basket-overlap` |
| [vid-tool](vid-tool/README.md) | Fix, shrink, compress and trim a video, for example to get a screen recording under an upload limit. | `vid-tool`, then pick a video and what to do |
| [doc-tool](doc-tool/README.md) | Find out-of-date Markdown pages in a git folder, such as a wiki, by when git says each was last edited, and open them in glow. | `doc-tool ~/wiki`, then pick what to see |

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

vid-tool                       # pick a video from the Desktop, then pick from a menu
vid-tool -f clip.mp4           # fix slow-motion playback; saved as clip-fixed.mp4
vid-tool -w clip.mp4           # small WebM, no audio; saved as clip.webm
vid-tool -c clip.mov           # compress to MP4; saved as clip-compressed.mp4
vid-tool -s 10 clip.mp4        # MP4 under 10 MB
vid-tool -t 0:15-1:05 clip.mp4 # keep only 0:15 to 1:05
vid-tool -i                    # show what this machine's ffmpeg can do
vid-tool -w -s 8 -t 0:15-1:05 -W 480 -o ~/Movies "login freeze.mp4"   # most options at once: options first, file last
vid-tool -f -r 60 -q 20 clip.mp4                                      # the rest: -r is for -f only, and -q is not used with -s

doc-tool ~/wiki                # menu: pages oldest/newest first, who edits them, or a status report
doc-tool -a ~/wiki             # pages oldest first, then pick one to open in glow
doc-tool -u ~/wiki/android     # who has edited the pages in a subfolder
doc-tool -r ~/wiki             # status summary for the whole folder; copied and saved on the Desktop
doc-tool -R ~/wiki             # full report: the summary plus every stale page, by folder
doc-tool -a -O 1y -s gradle -b ann -g -x '^chore' ~/wiki   # filters: older than 1 year, mentions gradle, edited by ann, all editors gone, bulk commits skipped
doc-tool -r -O 6m -C -f ~/Desktop/wiki.txt -l ~/wiki    # the rest: -C don't copy, -f save there instead, -l never offer the picker
doc-tool -n -m 10 -l ~/wiki    # the 10 most recently edited pages (default 20; -m 0 for all)
```

## Setup

### 1. Android SDK tools on your PATH

The `adb-` tools need `adb`. Add these lines to `~/.zshrc`:

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/build-tools/36.0.0"
```

Then open a new terminal tab, or run `source ~/.zshrc`.

> **Maintain the build-tools version by hand.** `build-tools/36.0.0` is the version installed when this was written. Your SDK may not have it, or may have a newer one, and the path doesn't update itself. Check what you have with `ls "$ANDROID_HOME/build-tools"` and put that version in the line above. Only `aapt2`, `apksigner`, `zipalign` and `d8` come from build-tools; the tools in this folder only need `platform-tools` (for `adb`).

### 2. ffmpeg (for vid-tool only)

```bash
brew install ffmpeg
```

If you can't use Homebrew, put your own build of `ffmpeg` on your PATH. vid-tool checks what your build supports each time it runs. See it with `vid-tool -i`, once the tools are installed.

### 3. glow (for doc-tool only)

```bash
brew install glow
```

doc-tool opens pages in glow. Without it, doc-tool still lists pages, authors and reports; only opening a page needs glow.

### 4. Install the tools

```bash
./install.sh
```

This links each tool into `~/.local/bin`, which must be on your PATH. Because they're links, edits to the scripts here take effect straight away.

### 5. Device

Turn on **Developer options** (tap **Settings → About phone → Build number** 7 times), then **USB debugging**. Plug the phone in and accept the prompt. Check with `adb devices`.

## Layout

```
.
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
5. Add tests in `my-tool/tests/run`. See [docs/testing.md](docs/testing.md).
6. Run `./install.sh` to put it on your PATH.

## Licence

[Apache 2.0](LICENSE). Use, change and share these tools however you like, including in paid or closed software. Keep the licence and copyright notice with any copy.
