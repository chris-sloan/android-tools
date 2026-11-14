# vid-tool

Fix, shrink, compress and trim videos with `ffmpeg`, without remembering any ffmpeg options. The original file is never changed.

```bash
vid-tool
```

With no arguments it lists the newest videos on your Desktop, you pick one, then pick what to do from a menu. When it finishes it prints the one-line command that does the same thing, so the options are easy to learn.

## What it can do

| You have | Run | You get |
| --- | --- | --- |
| A video that plays in slow motion in places | `vid-tool -f clip.mp4` | `clip-fixed.mp4`, rebuilt at a constant frame rate |
| A video to drop into a pull request or chat | `vid-tool -w clip.mp4` | `clip.webm`, small, no audio, at most 720px wide |
| A big `.mov` or `.mp4` | `vid-tool -c clip.mov` | `clip-compressed.mp4`, smaller, audio kept |
| A file over an upload limit | `vid-tool -s 10 clip.mp4` | `clip-compressed.mp4`, under 10 MB |
| A long video where only part matters | `vid-tool -t 0:15-1:05 clip.mp4` | `clip-compressed.mp4`, only that part |

## Usage

```
vid-tool [-f | -w | -c] [-s MB] [-t start-end] [-r fps] [-q crf] [-W width] [-o dir] [-i] [file]
```

| Option | What it does | Default |
| --- | --- | --- |
| `file` | The video to work on. | Pick from the newest videos in `~/Desktop` |
| `-f` | Fix slow-motion playback: rebuild at a constant frame rate. | |
| `-w` | Make a small WebM. No audio. | |
| `-c` | Compress to MP4. Keeps audio. | |
| `-s MB` | Keep the result under this many MB. Works with `-c` and `-w`. | No limit |
| `-t start-end` | Keep only part of the video. Works with every mode. | Whole video |
| `-r fps` | Frame rate for `-f`. | `30` |
| `-q crf` | Quality, 0 to 63. Lower is better and bigger. Not used with `-s`. | `-f` 18, `-w` 33, `-c` 23 |
| `-W width` | Scale down to at most this many pixels wide. Never scales up. | `-w` 720, others no scaling |
| `-o dir` | Folder to save in. | Next to the original |
| `-i` | Show what this machine's ffmpeg can do, then exit. | |
| `-h` | Show help. | |

Options go before the file: `vid-tool -c -s 10 clip.mov`. Quote names with spaces: `vid-tool -w "login freeze.mp4"`.

Pick one of `-f`, `-w` and `-c`. If you give none, a menu asks. If you give `-s` or `-t` and no mode, `-c` is used.

Trim times are seconds (`90`), `M:SS` (`1:30`) or `H:MM:SS`. `0:15-` runs to the end. `-1:05` starts at the beginning.

## Examples

```bash
vid-tool                           # pick a video from the Desktop, then pick from a menu
vid-tool clip.mp4                  # menu for this file
vid-tool -f clip.mp4               # fix slow-motion playback
vid-tool -f -r 60 clip.mp4         # fix, at 60 fps
vid-tool -w clip.mp4               # small WebM
vid-tool -w -W 480 clip.mp4        # smaller still: at most 480px wide
vid-tool -c clip.mov               # compress to MP4
vid-tool -c -q 28 clip.mov         # compress harder
vid-tool -s 10 clip.mp4            # MP4 under 10 MB
vid-tool -w -s 8 clip.mp4          # WebM under 8 MB
vid-tool -t 0:15-1:05 clip.mp4     # keep 0:15 to 1:05
vid-tool -s 10 -t 2:00- clip.mp4   # from 2:00 to the end, under 10 MB
vid-tool -i                        # what can this ffmpeg do?
```

## How it works

1. **Checks your ffmpeg.** It reads the encoder list from `ffmpeg -encoders` and works out which modes this build supports. See [What your ffmpeg can do](#what-your-ffmpeg-can-do).
2. **Picks a file.** Given a file, it uses it. Given none, it lists up to 15 videos (`mp4`, `mov`, `webm`, `m4v`, `mkv`) from `~/Desktop`, newest first, with size and date.
3. **Reads the video's details** (length, picture size, audio) from `ffmpeg -i`. It does not need `ffprobe`.
4. **Asks what to do** if you gave no mode. Modes this ffmpeg can't do are marked with the reason.
5. **Checks the trim range** against the video's length before encoding anything.
6. **Encodes to a new file.** Names are never overwritten: if `clip-fixed.mp4` exists you get `clip-fixed-2.mp4`, and so on.
7. **Cleans up on failure.** If ffmpeg fails, or you press Ctrl+C, the half-written file is deleted. A file that exists afterwards is a finished one.

### The three modes

| Mode | Video | Audio | Picture size |
| --- | --- | --- | --- |
| `-f` | H.264, quality 18, resampled to a constant 30 fps | Copied if already AAC, otherwise re-encoded to AAC | Unchanged |
| `-w` | VP9, quality 33 | Removed | At most 720px wide |
| `-c` | H.264, quality 23 | AAC, 128 kb/s | Unchanged |

Slow-motion playback comes from a variable frame rate: the gaps between frames are uneven and some players get the timing wrong. `-f` resamples to evenly spaced frames, which removes the problem.

### Size limit (`-s`)

`-s 10` means the result will be under 10 MB.

1. It divides the size by the video's length to get a bitrate, takes off the audio, and holds back 4% for file overhead.
2. It encodes in two passes, which hits a size far more exactly than one.
3. It checks the result. If it is over, it tries once more at a lower bitrate. If it is still over, it deletes the file and says so. You never get an oversized file that looks finished.

A few details:

- **1 MB is 1,000,000 bytes.** Some services count 1,048,576. Using the smaller one means the file passes either way.
- **Already under the limit?** If the file is already small enough, in the right format, and you asked for no trim or scaling, it says so and does nothing.
- **It never aims above the original's bitrate.** A 2 MB video with `-s 10` stays about 2 MB.

**When the limit is too tight.** A long video and a small limit leaves too little bitrate, and the picture goes blocky. vid-tool stops before encoding and tells you, with numbers:

```
To fit 10 MB, 4:00 of video gets about 320 kb/s.
At 1080x2400 that is likely to look blocky (about 777 kb/s is the least that looks OK).
At this picture size, about 1:38 of video fits.

  1) Scale down to 540px wide (whole frame kept; small text gets softer)
  2) Trim to a shorter part
  3) Encode anyway
  4) Cancel
```

Scaling down keeps the whole frame but softens small text. Trimming keeps full quality for the part you keep. Trim when you can.

The "least that looks OK" figure is a rough rule (300 kb/s per million pixels), not a measurement. Screen recordings often look fine well below it, so the warning only appears when the bitrate is under that figure and also under half of the original's.

When there is no terminal to ask (a script, a pipe), it exits with the same explanation and the flags to pass.

### Trim (`-t`)

The range is checked before any encoding starts:

| You give | What happens |
| --- | --- |
| A start past the end of the video | Stops: "The trim starts at 0:40 but the video is only 0:12 long." |
| An end past the end of the video | Carries on, trimmed to the real end, with a note |
| An end before the start | Stops, and says which is which |
| Something that isn't a time | Stops, with an example of the format |
| A range under a fifth of a second | Stops |

In the menu, a bad range asks again and does not exit.

## What your ffmpeg can do

Not every ffmpeg is built the same. A Homebrew install has everything. A hand-built one may be missing encoders. vid-tool checks at the start of every run and adapts:

| Missing | What vid-tool does |
| --- | --- |
| `libx264` | Uses Apple's `h264_videotoolbox` for `-f` and `-c`, and says so. It has no quality setting, so `-q` does nothing and a bitrate is picked from the original (about the same for `-f`, about half for `-c`). `-s` is single pass and less exact. |
| `libx264` and `h264_videotoolbox` | `-f` and `-c` are unavailable. |
| `libvpx-vp9` | `-w` is unavailable. |
| `aac` | Tries `aac_at`. With neither, audio is kept only when the original is already AAC. Otherwise it is dropped, with a note. |
| `ffprobe` | Nothing. It isn't used. |

It checks for the features themselves and ignores the version number, because custom builds often report versions that don't compare (`N-118234-gabc123`).

Run `vid-tool -i` to see the result for your machine:

```
ffmpeg: /opt/homebrew/bin/ffmpeg
        ffmpeg version 8.1.2 Copyright (c) 2000-2026 the FFmpeg developers

  -f  Fix slow motion   yes, using libx264
  -w  Small WebM        yes, using libvpx-vp9
  -c  Compress to MP4   yes, using libx264
      Audio in MP4      re-encoded with aac
  -s  Size limit        two-pass for MP4 and WebM
  -t  Trim              yes
```

## Changing the defaults

Edit the block at the top of the script:

```bash
indir="$HOME/Desktop"   # folder the file picker lists when no file is given
pick_max=15             # how many recent videos the picker shows
fix_fps=30              # -f: output frame rate
fix_crf=18              # -f: quality (lower = better and bigger)
webm_crf=33             # -w: quality
webm_maxw=720           # -w: widest output in pixels (never scales up)
mp4_crf=23              # -c: quality
audio_kbps=128          # -c: audio bitrate, kb/s
size_audio_kbps=64      # -c with -s: audio bitrate, kb/s
size_overhead=4         # -s: percent of the limit held back for file overhead
min_kbps_per_mpx=300    # -s: ask first if the video gets less than this many
                        #     kb/s per million pixels (a rough quality floor)
```

Command-line options override these for a single run.

## Notes and limits

- **WebM output has no audio.** Use `-c` when you need sound.
- **`-s` does not work with `-f`.** Fix first, then run `-c -s` on the fixed file.
- **`-w` is slow.** VP9 encodes at well under real time for large frames. `-c` is much faster.
- **`h264_videotoolbox` has a bitrate floor.** For a given picture size it won't go below a certain bitrate, so a tight `-s` can fail on a build without `libx264`. Scale down with `-W` and it works.
- **Output is always 4:2:0 colour with even dimensions**, so the file plays everywhere. A 541px-wide video comes out 540px wide.
- **Subtitle and data tracks are dropped.**
- **macOS only** for the file picker's date column. Everything else is plain bash 3.2 and ffmpeg.
- **Requirements:** `ffmpeg` on your PATH.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `ffmpeg not found on PATH` | `brew install ffmpeg`, or add the folder holding your own build to PATH in `~/.zshrc`. |
| `Can't do that here: this ffmpeg has no ... encoder` | Your ffmpeg was built without it. Run `vid-tool -i` to see what works. Rebuild ffmpeg with the encoder, or use a different mode. |
| `No videos found in ~/Desktop` when there are some | macOS may be blocking your terminal from the Desktop. Allow it in **System Settings → Privacy & Security → Files and Folders**, or pass the file path. |
| `ffmpeg can't find any video in: ...` | The file isn't a video, or is damaged. The line after it is ffmpeg's own reason. |
| `Couldn't get under N MB` | The limit is too tight for this length and picture size. Trim with `-t` or scale down with `-W`. |
| `Couldn't read the video's length` with `-s` | The file stores no length and ffmpeg couldn't work one out. Run `-c` first, then `-s` on the result. |
| The result is bigger than the original | The original was already well compressed. Raise `-q` (try 28), or set a size with `-s`. |
| Still plays in slow motion after `-f` | Try the frame rate the video was recorded at, for example `-r 60`. |

## History

vid-tool started in January 2026 as `videoTool.sh` in a separate `video-tools` repository. It was a menu of three ffmpeg commands: fix slow motion, shrink to WebM, and (from July 2026) compress MOV to MP4.

In November 2026 it moved into this repository, since Android screen recordings were what it was written for. The move was also a redesign. The old script was hard to use: it had no help, the menu named the mechanism ("Fix VFR -> CFR") and not the problem, its settings were undocumented environment variables, and its README had fallen behind the code.

These features did not exist in `videoTool.sh`. Each came out of the planning conversation for the move:

| New in the move | Why |
| --- | --- |
| **Size limit (`-s`)** | Chat and code review tools reject files over a set size. Asking for "under 10 MB" is easier than guessing a quality number and retrying. |
| **Trim (`-t`)** | Came out of the size limit discussion. Scaling a video down to fit a limit can lose the detail that matters, such as small UI text. Cutting to the part that matters keeps full quality. |
| **Trim range checks** | A range that doesn't fit the video should give a clear message before any work starts, not an ffmpeg error or an empty file. |
| **Low-quality warning** | The same concern: when a size limit can't be met at a watchable quality, stop and offer choices. Don't quietly produce something unreadable. |
| **Runtime ffmpeg checks and `-i`** | The machine this runs on most has a hand-built ffmpeg, installed without admin rights. What it supports can only be known at run time. |
| **No `ffprobe` dependency** | For the same reason. A hand-built install often has no ffprobe, so the details are read from ffmpeg itself and every machine runs the same code. |
| **File picker** | With no file given, list recent videos from a default folder. Saves finding and typing a path. |
| **Mode flags (`-f`, `-w`, `-c`)** | The old script was menu only, so it couldn't be run in one line or recalled from shell history. The menu stays as the fallback. |
| **The one-line command printed after a menu run** | So the menu teaches the flags. |
| **`-h` help, and a menu worded by problem** | The original complaint: not knowing what the tool could do or how to use it. |

Changed in the move:

- **Never overwrites.** The old script stopped at ffmpeg's overwrite prompt.
- **Compress accepts any video**, not only `.mov`.
- **Settings are flags** (`-r`, `-q`, `-W`), not the `FPS`, `CRF` and `MAXW` environment variables.
- **Output names** use hyphens: `-fixed`, `-compressed` and `-small` replace `_cfr`, `_compressed` and `_tiny`.
- **The frame-rate fix uses ffmpeg's `fps` filter**, not the `-vsync` option. `-vsync` is deprecated in newer ffmpeg versions, and the filter behaves the same on every version, so there is nothing to detect.
- **bash, not zsh**, to match the other tools here. It runs on the bash 3.2 that macOS ships.
