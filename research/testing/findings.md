# Findings: automated testing and CI for the tools in this repo

Research done on 2026-11-15 for issue #4. It goes stale: runner images, ffmpeg and the docs all move.

**How to read this.** Each finding is marked:

- **Docs**: read in the linked page on 2026-11-15.
- **Tried**: I ran it. The command and the relevant output are here, and the scripts are in commit [`7df2d92`](https://github.com/chris-sloan/android-tools/commit/7df2d923013469e62957876977bbcd9a0889c220) on the `research/testing-ci` branch (folder `research/testing/`, workflow `.github/workflows/research-testing.yml`).
- **Assumed**: not checked. Treat as a guess.

The hosted-runner results come from one workflow run, executed twice: [attempt 1](https://github.com/chris-sloan/android-tools/actions/runs/43755844435/attempts/1) and [attempt 2](https://github.com/chris-sloan/android-tools/actions/runs/43755844435/attempts/2). Action logs are deleted after a retention period, so the output that matters is pasted below. Timings are two samples each, written `first / second`.

**Terms used here that the README doesn't use**

- **Runner**: the virtual machine GitHub Actions starts to run a job. A **hosted** runner is one GitHub provides. `macos-latest` and `ubuntu-latest` are labels that pick a runner image.
- **Fake**: a small script with the same name as a real program (`adb`, `osascript`), put first on `PATH` during a test. It prints canned output and logs how it was called.
- **expect**: a program that runs a command inside a pretend terminal and types answers when it sees given text. Ships with macOS at `/usr/bin/expect`.
- **Terminal (tty)**: what a script is attached to when a person runs it in a terminal window. In CI there isn't one. `[[ -t 0 ]]` tests for it, and `/dev/tty` reads from it directly.

## The repo as I found it

At `origin/main` commit `76d326c`:

- Three tools: `adb-record`, `adb-shot`, `vid-tool`. Plus `install.sh`.
- **Tests already exist for one tool.** The issue says there are none, but `vid-tool/tests/run` (160 lines of plain bash) and `vid-tool/tests/prompts.exp` (110 lines of expect) were added in commit `732500f`. They are marked "provisional" in their header. They make their own clips with ffmpeg, use a wrapping fake `ffmpeg` to hide encoders, and drive the menus with expect. 55 checks, all passing on my Mac in 60 seconds.
- No tests for `adb-record`, `adb-shot` or `install.sh`.
- No workflows. `.github/` held only `CODEOWNERS`. Actions is enabled for the repo and it had never run a workflow.

## Versions

| Where | OS and image | bash | ffmpeg | shellcheck | expect | bats |
| --- | --- | --- | --- | --- | --- | --- |
| My Mac (Apple silicon) | macOS 26.6.2 | 3.2.57 | 8.1.2 (Homebrew) | not installed | present | not installed |
| `macos-latest` | macOS 26.7.2 arm64, image `macos26` 20261102.0473.1, 3 cores, 7 GB | 3.2.57, the only bash on `PATH` | 9.0.2 (brew, not preinstalled) | 0.11.0 (brew, not preinstalled) | 5.45, preinstalled | 1.14.0 (brew) |
| `macos-15` | macOS 15.8.2 arm64, image 20261104.0514.1 | 3.2.57 | 9.0.2 (brew) | 0.11.0 (brew) | 5.45 | 1.14.0 (brew) |
| `macos-26-intel` | macOS 26.6.1 x86_64, image 20260824.0517.1 | 3.2.57 | 9.0.1 (brew) | 0.11.0 (brew) | 5.45 | 1.14.0 (brew) |
| `ubuntu-latest` | Ubuntu 26.04.1 x86_64, image `ubuntu26` 20261111.196.1, 4 cores, 16 GB | 5.3.9 | 8.0.1 (apt, not preinstalled) | 0.11.0, preinstalled | 5.45.4 (apt, not preinstalled) | 1.13.0 (apt) |
| `bash:3.2` container | Alpine Linux, busybox utilities | 3.2.57 at `/usr/local/bin/bash` | none | none | none | none |

All **Tried** (printed by the workflow). One thing to know: on the same day, GitHub's docs and the runner-images README still listed `ubuntu-latest` as Ubuntu 24.04, while the runner I got was 26.04. The `-latest` labels move without notice.

## Findings

### 1. Cost and limits

*Question: are Actions minutes unmetered for a public repo, on Linux and macOS runners? Any limits on concurrency, job length or runner size?*

- **Docs.** Yes, free and unlimited on standard hosted runners, macOS included. ["Use of the standard GitHub-hosted runners is free and unlimited on public repositories."](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) The macOS labels are in that page's "standard runners for public repositories" table. This repo is public (checked with `gh api`).
- **Docs.** Larger runners are not free: ["Larger runners are billed for public repositories."](https://docs.github.com/en/billing/concepts/product-billing/github-actions) Nothing here needs one.
- **Docs.** [Limits](https://docs.github.com/en/actions/reference/limits) on the Free plan: 20 jobs at once, of which at most 5 macOS. 6 hours per job. 256 jobs per matrix.
- **Docs.** Runner size for public repos: Linux 4 cores and 16 GB, macOS arm64 3 cores and 7 GB, macOS Intel 4 cores and 14 GB. All have 14 GB of disk.
- For scale: if the repo were ever made private, macOS minutes cost about ten times Linux minutes ($0.062 against $0.006 per minute, same billing page).

Cost is not a constraint. The 5-job macOS limit is the only one a per-tool matrix could reach, at more than 5 tools.

### 2. Runners

*Question: which jobs should run on macOS (the real target) and which on Linux (faster)? Is a Linux job running bash 3.2 in a container worth having?*

**Tried.** Whole-job times, including checkout and installs:

| Job | Time |
| --- | --- |
| macOS arm64, everything (install ffmpeg, vid-tool tests, lint, fakes) | 4m16s / 4m12s |
| Linux, everything | 3m11s / 3m17s |

Linux is not much faster here, because the time goes on encoding video, not on starting up. Install times: `brew install ffmpeg` 32s / 35s on `macos-latest`. `apt-get update` plus `apt-get install ffmpeg expect` 13s / 17s on Linux.

**Tried.** The hosted macOS runners have only bash 3.2 on `PATH` (`which -a bash` printed `/bin/bash` alone). So `#!/usr/bin/env bash` gets 3.2 there, the same as on a stock Mac. A Mac with Homebrew's bash installed would get bash 5 from that line, which is why the existing tests call `/bin/bash "$tool"` explicitly.

**Tried.** The existing vid-tool tests also pass on Linux: 48 of 48, with the 7 `h264_videotoolbox` checks skipped. That says little about macOS, though. Linux has GNU `awk`, `sed`, `grep` and `stat`, and one macOS-only call (`stat -f` in the file picker) fails silently there because the script already ignores its error.

**Tried.** bash 3.2 in a container (`docker run bash:3.2`): the image pulls in about a second, and `bash -n` gives the same answers as `/bin/bash` on a Mac. But running the tools in it does not work. The fake-adb experiment went from 48 passes to 13: the image is Alpine with busybox utilities, has no `perl` or `expect`, and has no `/bin/bash`. Making it work means building a custom image, and it would still not have macOS's utilities.

**Options**

- (a) macOS only. One runner type, the real target, about 4 minutes.
- (b) macOS for tests, Linux for linting. Lint feedback in under a minute, at the cost of a second job to maintain.
- (c) Add a Linux run of the tests as well. Cheap, but a pass there proves little and a failure may be a Linux-only problem nobody cares about.
- (d) Add the bash 3.2 container. Not worth it, per the result above.

**Lean: (a), or (b) if fast lint feedback matters.** The tools are macOS tools. macOS runners are free here and take about as long. Pin the image (`macos-26`, not `macos-latest`) if surprise breakage matters more than staying current.

### 3. Linting

*Question: is `shellcheck` plus `bash -n` enough? Can either catch syntax that bash 3.2 doesn't support?*

**Tried.** I wrote 16 one-feature scripts, each using something added after bash 3.2, and ran `bash -n`, the script itself, and shellcheck 0.11.0 on each. Under bash 3.2.57 (same result on my Mac, on `macos-latest` and in the container):

```
bash -n  run   stderr  snippet (feature, bash version that added it)
0        0     yes     declare -A associative array (4.0)
0        1     yes     ${x,,} case conversion (4.0)
0        0     yes     mapfile / readarray builtin (4.0)
2        2     yes     |& pipe stdout and stderr (4.0)
2        2     yes     &>> append stdout and stderr (4.0)
2        2     yes     ;;& case fall-through (4.0)
0        0     yes     ${a[-1]} negative array index (4.3)
0        1     yes     printf %(fmt)T date formatting (4.2)
0        0     yes     read -t with a fractional timeout (4.0)
0        1     yes     local -n nameref (4.3)
2        2     yes     [[ -v name ]] is-set test (4.2)
0        1     yes     ${x@Q} parameter transformation (4.4)
0        1     yes     "${a[@]}" on an empty array under set -u (an error before 4.4)
0        1     yes     shopt -s globstar (4.0)
0        2     yes     wait -n (4.3)
0        1     no      $EPOCHSECONDS (5.0)
```

`bash -n` is the exit code of a parse-only check. `run` is the exit code of running the script. `stderr` is whether running it printed an error.

- `bash -n` under 3.2 caught 4 of 16. It only finds things the 3.2 parser rejects.
- The other 12 fail only when that line runs. Four of those printed an error but still exited 0 (the script carried on), and one (`$EPOCHSECONDS`) is silently empty.
- **shellcheck flagged none of the 16 as too new.** Every warning it gave was about something else.
- **Docs.** shellcheck has no option to target a bash version. [`--shell`](https://github.com/koalaman/shellcheck/blob/master/shellcheck.1.md) only picks a dialect: "Valid values are sh, bash, dash, ksh, and busybox." A request for this, [koalaman/shellcheck#1738](https://github.com/koalaman/shellcheck/issues/1738), dates from 2019. Whether it is still open is **assumed**.

So no, they are not enough to catch bash 4+ features. The only reliable check is to run the code under bash 3.2, which is what tests on a macOS runner do. Lines the tests never reach stay unchecked.

**Tried.** shellcheck is still useful for ordinary mistakes, and it is not clean on the repo today:

```
vid-tool/vid-tool line 193:  SC2010 (warning): Don't use ls | grep.
vid-tool/vid-tool line 538:  SC2329 (info): This function is never invoked.   [it is, through trap]
vid-tool/tests/run lines 79, 80, 86, 88, 134:  SC2016 (info): Expressions don't expand in single quotes.   [deliberate]
shellcheck on the tools exit=1
```

`adb-shot`, `adb-record` and `install.sh` are clean. `bash -n` passes on all four scripts.

**Options:** fail on everything (needs seven fixes or `# shellcheck disable=` lines first), or fail on warnings and above (`shellcheck -S warning`, needs one). **Lean: `-S warning`**, since the info-level results here are all false alarms.

shellcheck is preinstalled on the Linux runner and takes 5 to 8 seconds to `brew install` on macOS. It is not on a stock Mac, so a local lint step has to skip politely when it is missing, as the existing tests do for `expect`.

### 4. Tools that wrap an external program

*Question: assess replacing `adb` or `ffmpeg` with a fake on the PATH that returns canned output. What can this cover, and what can't it?*

**Tried.** I wrote a 55-line fake `adb`, plus two-line fakes for `osascript` and `open`, and ran `adb-shot` and `adb-record` against them (`research/testing/try-fakes`). 48 of 49 checks behaved as expected on macOS and on Linux, in about 16 seconds (most of it deliberate sleeps). No device, nothing left behind.

What the fake covered:

- Device choice: no device, an unauthorized device only, one device, two devices with the menu answered through piped input.
- File naming: given name, default name from the model, the `-2` no-overwrite suffix, too many arguments.
- `adb-shot`: warning text before the PNG is stripped, a non-PNG reply is rejected and the file removed, the powered-on display is picked on a foldable, `-D`, `-L`, clipboard copy goes to `osascript`, a failed copy doesn't lose the shot, `-p` calls `open`.
- `adb-record`: time limit, the fall-back to 180 seconds below API 34, `show_touches` is set and then restored, `-T` leaves it alone, Enter stops the recording, Ctrl+C stops it and the video is still pulled, a failed pull keeps the file on the device.
- `adb` missing from `PATH`.

Sample:

```
=== PASS [shot: foldable, picks the display that is on] exit=0 (want 0)
    Saved: out/fold.png
    PASS logged "screencap -p -d 222"
=== PASS [record: API 33 falls back to 180s] exit=0 (want 0)
    Note: unlimited recording needs Android 14+ (this device is API 33); using the 180s limit.
    PASS logged "--time-limit 180"
```

The one that did not pass is `adb-shot -n`, which reads `/dev/tty`. See question 6.

What a fake cannot cover:

- **Whether the canned output matches a real device.** I wrote the fake's replies from what the scripts parse, not from a device. If Android changes the format of `dumpsys SurfaceFlinger`, the fake keeps passing.
- Real timing, real `screenrecord` behaviour, a real PNG, the real clipboard.
- It is a second thing to keep in step with the tools.

A pitfall I hit: `adb-record` starts `screenrecord` as a background job, and bash starts background jobs with Ctrl+C's signal ignored. My fake could not react to it and ran for its full 30 seconds. The fake has to be stopped with a different signal.

For ffmpeg there are two kinds of fake. The existing vid-tool tests use a **wrapping** fake: it hides chosen encoders from `ffmpeg -encoders` and passes every other call to the real ffmpeg. That simulates a cut-down build while still doing real encoding. A fully canned ffmpeg would be faster but would test almost nothing, since the tool's value is in the ffmpeg arguments it builds.

**Options:** (a) fully canned fake, for programs the test machine can't have (`adb` with a device, `osascript`). (b) Wrapping fake over the real program, where it can be installed (`ffmpeg`). (c) The real thing only. **Lean: (a) for the `adb-` tools and (b) for vid-tool**, which is what the existing tests already do.

### 5. Real dependencies

*Question: can vid-tool's tests generate their own input videos? How long does installing ffmpeg take? Do hardware encoders work on hosted macOS runners? Is an Android emulator in CI worth it?*

**Tried.** Yes, tests can make their own clips. The existing tests build five with ffmpeg's built-in test pattern (`-f lavfi -i testsrc2=...`), including an odd-sized one, a variable-frame-rate one and a WebM with no stored length. No media is in the repo.

**Tried.** ffmpeg install time is under "Runners" above: about 33 seconds on macOS arm64, 10 to 22 on macOS Intel, about 15 on Linux. I did not try caching it.

**Tried.** vid-tool test time (`time vid-tool/tests/run`):

| Where | Time | Result |
| --- | --- | --- |
| My Mac | 0m60s | 55 pass |
| `macos-latest` (arm64) | 2m53s / 2m48s | 55 pass |
| `macos-15` (arm64) | 2m46s / 3m07s | 55 pass |
| `macos-26-intel` | 5m21s / 3m39s | 51 pass, 4 fail |
| `ubuntu-latest` | 2m27s / 2m26s | 48 pass, videotoolbox checks skipped |

**Tried.** `h264_videotoolbox` works on the arm64 macOS runners, including with software fallback turned off (`-allow_sw 0`). It prints a harmless warning:

```
IOServiceMatchingfailed for: AppleM2ScalerParavirtDriver
exit=0
-rw-r--r--  1 runner  staff  771987 Nov 15 20:04 vt-hw.mp4
```

It does **not** work on `macos-26-intel` unless software encoding is allowed, which vid-tool doesn't do. That is why 4 checks fail there:

```
[h264_videotoolbox @ 0x7f8ce4806fc0] Cannot create compression session: -12908
[h264_videotoolbox @ 0x7f8ce4806fc0] Try -allow_sw 1. The hardware encoder may be busy, or not supported.
exit=187
```

I did not check whether the arm64 runners use real hardware or something that only reports as hardware. For these tests it doesn't matter.

**Tried.** An Android emulator on `ubuntu-latest`, using the third-party action `reactivecircus/android-emulator-runner@v2` (API 34, x86_64). The whole job took 1m13s / 1m15s, and the emulator booted in 28s / 31s. That is faster than I expected.

- `adb-shot` worked against it: `Saved: out/emu-shot.png`.
- `adb-record` failed the same way both times:

```
Recording Android SDK built for x86_64... press Enter (or Ctrl+C) to stop.
Unable to open '/sdcard/screenrecord-20261115-200428.mp4': Operation not permitted
Pull failed; the recording is still on the device at /sdcard/screenrecord-20261115-200428.mp4
```

I did not find out why. It could be storage not being ready just after boot, or a real problem with this emulator image. Worth its own look.

**Docs.** The emulator can only run on Linux runners. ["Nested-virtualization is not supported"](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) on arm64 macOS runners. So an emulator job would run the tools on Linux with GNU utilities, bash 5 and no `osascript`: a real device, but not the real host.

**Options:** (a) no emulator, fakes only. (b) An emulator job that is run by hand or on a schedule and doesn't block merging. (c) An emulator job on every pull request. **Lean: (a) now, and (b) later** if a fake ever passes while a real device fails. Two runs are not enough to judge flakiness, and the one failure above is unexplained.

### 6. Interactive prompts

*Question: how should menus and Enter prompts be tested? Consider `expect`, piped input, and what happens when a script reads from `/dev/tty`.*

The tools read input in three different ways, and each needs a different approach. All **tried**.

| How the script reads | Where | Piped input | expect |
| --- | --- | --- | --- |
| Plain `read` or `select` on standard input | device menu in both `adb-` tools, Enter-to-stop in `adb-record` | Works | Works |
| Guarded by `[[ -t 0 ]]` (refuses unless a terminal) | every vid-tool menu | Refused by design. The script exits with a "say what to do" message, which is itself testable. | Works |
| `read ... </dev/tty` | `adb-shot -n` | Fails | Works |

Piped input working:

```
=== PASS [shot: two devices, '2' piped to the menu] exit=0 (want 0)
    PASS logged "adb -s SERIALBBB exec-out"
=== PASS [record: Enter piped on stdin stops a 30s recording] exit=0 (want 0)
    took 3s; fake screenrecord says: stopped-by-signal
```

`/dev/tty` with no terminal, which is the situation in CI:

```
adb-shot/adb-shot: line 155: /dev/tty: Device not configured        (macOS)
adb-shot/adb-shot: line 155: /dev/tty: No such device or address    (Linux)
exit=1; files:
```

The same through expect, on both systems:

```
Shot 1/2: press Enter to capture...
Saved: expected/series-1.png
Shot 2/2: press Enter to capture...
Saved: expected/series-2.png
### PASS shot series exit=0
```

expect also sent Ctrl+C to `adb-record`, and the fake's log showed the video pulled and `show_touches` restored.

**Tried, and failed:** `script`, which also supplies a terminal. Its arguments differ between macOS and Linux, and on macOS piped input never reached the tool. Worse, it exited 0 having taken no screenshots, so a test built on it would pass wrongly. Don't use it.

expect is preinstalled on macOS (5.45) and on the macOS runners. On Linux it needs `apt-get install expect`.

**Options:** (a) piped input only, which leaves terminal-only prompts untested. (b) expect only. (c) Piped input where the script reads standard input, expect for the rest. **Lean: (c).** Piped tests are simpler to read, and expect is already on every Mac. A separate question, outside this research, is whether `adb-shot -n` should read standard input like the other prompts do, which would make it testable with a pipe.

### 7. Layout

*Question: evaluate keeping each tool's tests in `<tool>/tests/run`, with one workflow that finds and runs each as a separate job. Does a `tests` folder confuse `install.sh`? Where do shared helpers and repo-wide checks go?*

**Tried.** `install.sh` is not confused. I ran it with `HOME` pointed at a temp folder, after adding `<tool>/tests/run` to every tool and a top-level `tests/` holding an executable `run` and a `lib.sh`:

```
exit=0; links: adb-record adb-shot vid-tool
```

It only links `<folder>/<folder>`. The one way to break it is a top-level folder holding an executable of its own name:

```
##### 3. a top-level folder holding an executable of the same name (tests/tests)
exit=0; links: adb-record adb-shot tests vid-tool
```

So a top-level `tests/` is safe as long as nothing in it is called `tests`.

The same run shows `install.sh` can itself be tested this way, in a temp `HOME`, with nothing real linked.

**On the proposal.** It fits what exists: `vid-tool/tests/run` already makes its own temp folder and removes it on exit. Points to settle:

- **Finding tests.** A workflow can list `*/tests/run` in a first job and fan out into one job per tool. This is **assumed** to work (it is a standard Actions pattern, a matrix built from a job's output). I did not build it. The simpler alternative is one job that loops over them.
- **Dependencies differ per tool.** vid-tool needs ffmpeg (33 seconds to install). The `adb-` tools with fakes need nothing. A generic workflow needs some way for a tool to say what to install, or it installs everything for everyone.
- **Shared helpers.** My fake-adb script reused the `run` and `check` helpers from `vid-tool/tests/run` almost unchanged, about 15 lines. The fake `adb` would be shared by both `adb-` tools. That is the case for a top-level `tests/` folder holding the helpers and shared fakes. The case against: each tool's tests stop being self-contained, which the README asks of each tool's docs.
- **Repo-wide checks.** These have no tool folder to live in: linting, `bash -n`, `install.sh` in a temp `HOME`, every tool answers `-h` with exit 0, every tool has a README and a row in the main table. A top-level `tests/run` is the natural home. Reading the code, all three tools print `-h` before they look for `adb` or `ffmpeg`, so the `-h` check needs nothing installed (**assumed** for the `adb-` tools, tried for vid-tool).

**Options**

- (a) Per-tool `tests/run` only, each fully self-contained, helpers copied.
- (b) Per-tool `tests/run`, plus a top-level `tests/` with `run` (repo-wide checks), shared helpers and shared fakes.
- (c) Everything in a top-level `tests/` folder.

**Lean: (b).** It keeps a tool's tests next to the tool, gives repo-wide checks a home, and avoids three copies of a fake `adb`. One job per tool or one job for all is a smaller decision. With three tools and four-minute runs, one job is simpler. Separate jobs give clearer failures.

### 8. Framework

*Question: plain bash test scripts, or a framework such as `bats`? Weigh the extra dependency against readability.*

- **Tried.** bats installs quickly: `brew install bats-core` took 3 to 6 seconds (1.14.0), `apt-get install bats` about 2.5 seconds (1.13.0). It is not preinstalled on any runner, and not on a stock Mac.
- **Tried.** Plain bash already works here. The existing suite is 160 lines with a 15-line helper, and my fake-adb experiment reused that helper for 49 more checks.
- **Assumed.** I did not write any bats tests, so I have not compared readability on this repo's own cases. I also did not check that bats itself runs on bash 3.2.

| | Plain bash | bats |
| --- | --- | --- |
| Local setup | None | `brew install bats-core` |
| Output | Home-made PASS/FAIL lines | Standard format, one line per test |
| Run one test | Not without adding it | Built in |
| A failing test stops the rest | No (existing helper carries on) | No |
| Maintenance | A small helper to own | A dependency to keep working |
| Existing tests | Already written this way | Would be rewritten |

**Lean: plain bash.** The constraint is that the same command works on a Mac and in CI, and "keep it small". Plain bash needs nothing installed and the existing tests already use it. bats becomes worth it if the suites grow enough that running single tests matters.

### 9. Triggers

*Question: every push, pull requests only, or both? Should a tool's tests run only when its folder changes?*

- **Docs.** Minutes are free, so cost doesn't decide this.
- **Tried.** A full macOS run is a little over 4 minutes.
- **Assumed.** If a check is ever made required for merging, a workflow skipped by a path filter can leave that check waiting forever. This is from memory, not checked.

**Options:** (a) pull requests, plus pushes to `main`. (b) Every push to every branch. (c) Either of those with per-tool path filters.

**Lean: (a), with no path filters.** Pull requests are where a result is acted on, and a run on `main` catches a bad merge. (b) runs everything twice for a branch that has a pull request. Path filters save little at three tools and four minutes, and they need care: a change to `install.sh`, shared helpers or the workflow itself must still run everything.

## Open questions for the discussion

1. **Where do the guidelines live?** A new step in the README's "Adding a tool" section, a separate doc, or both.
2. **How much testing is required for a new tool, and what is optional?** A possible floor, all shown to be cheap above: passes `bash -n` and shellcheck, `-h` exits 0, has a `tests/run` that works with no device and leaves nothing behind. Possible extras: prompts through expect, missing-feature cases through fakes.
3. **Do existing tools get tests before the guidelines apply to new ones?** The fake-adb experiment on the research branch is most of the way to tests for both `adb-` tools, if wanted.
4. **What happens to the provisional vid-tool tests?** Keep as the model for other tools, or rework to fit whatever is decided.
5. **Runner.** macOS only, or macOS plus a Linux lint job. Pin the image or follow `-latest`.
6. **shellcheck strictness.** Fail on warnings only, or on everything. Either way the current results need fixing or silencing first.
7. **Top-level `tests/` folder or not**, for shared helpers, the shared fake `adb` and repo-wide checks.
8. **Plain bash or bats.**
9. **Should `adb-shot -n` keep reading `/dev/tty`?** It is the only prompt that can't be tested with piped input.
10. **Emulator.** Leave out, or add a non-blocking job later. Related: someone should look at why `adb-record` failed on the emulator.
11. **Should a failing test block merging**, or only inform? This affects triggers and path filters.

## What I did not check

- Caching Homebrew or ffmpeg between runs.
- Writing real bats tests, or whether bats runs on bash 3.2.
- A workflow that discovers `*/tests/run` and builds one job per tool.
- `shfmt` or any formatter.
- Why `adb-record` failed on the emulator. Other emulator API levels or images.
- Whether a canned `dumpsys SurfaceFlinger` reply matches a real foldable. I have not compared the fake's output with any real device.
- The real clipboard on a runner (`osascript` was always faked).
- Flakiness. Everything ran twice at most.
- Timings at other times of day, or queue times for macOS runners under load. Both runs started within seconds.
- The path-filter and required-check interaction in question 9.

## What I tried that failed

- `script` as a way to give a prompt a terminal: different arguments on macOS and Linux, and a false pass on macOS.
- Running the tools in the `bash:3.2` container: no `/bin/bash`, no `perl`, busybox utilities.
- Stopping a fake `screenrecord` with the interrupt signal: background jobs ignore it.
- `h264_videotoolbox` on the Intel macOS runner: fails without software fallback.
- `adb-record` against a real emulator: "Operation not permitted" writing to `/sdcard`, both times.
