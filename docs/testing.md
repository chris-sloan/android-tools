# Testing

How tools in this repo are tested. Decided on 2026-11-15 from the research on
[issue #4](https://github.com/chris-sloan/android-tools/issues/4), which holds
the evidence behind each rule.

Some of this is not built yet. [Status](#status) says what exists today.

## The short version

- Each tool keeps its own tests in `<tool>/tests/run`, a plain bash script.
- The same command works on a Mac and in CI: `<tool>/tests/run`.
- Tests need no Android device, no network and nothing from your real home folder.
- Programs the test machine can't have are replaced with fakes. Programs it can have are used for real.
- A tool lists what its tests need in `<tool>/tests/Brewfile`.
- CI runs every tool's tests on macOS. A failure is reported but does not block merging.

## What each tool's tests should cover

These five are the recommended floor.

1. **A `tests/run` script.** Executable, and exits non-zero if any check fails.
2. **Runs the tool under `/bin/bash`.** Call `/bin/bash "$tool"`, not the tool directly. See [bash 3.2](#bash-32).
3. **Self-contained.** No device, no network. Works in a temp folder and removes it on exit. Never touches the real `HOME`, Desktop or clipboard.
4. **Covers the tool's behaviour.** `-h` exits 0. Every option is used at least once. Every error message the tool can print is triggered. The case where a needed program is missing from `PATH` is tested.
5. **Lint clean.** Passes `bash -n` and `shellcheck -S warning`. See [Lint](#lint).

The floor is a recommendation, not a gate. If a tool can't meet one of these,
build the tool anyway. Say which point is not met, and why, in the comment at
the top of its `tests/run`, so the gap is written down and not forgotten.

## Layout

```
Tools/
├── tests/                 repo-wide checks, shared helpers, shared fakes
│   └── run
└── <tool>/
    ├── <tool>
    ├── README.md
    └── tests/
        ├── run            the tool's tests
        ├── Brewfile       what the tests need installed (optional)
        └── ...            expect scripts, fakes used by this tool only
```

- A tool's tests live next to the tool.
- The top-level `tests/` folder holds only what belongs to no single tool: the repo-wide checks, helpers used by more than one tool, and fakes used by more than one tool (the fake `adb`). Don't move something there until a second tool needs it.
- **Nothing in the top-level `tests/` folder may be named `tests`.** `install.sh` links any `<folder>/<folder>` executable, so `tests/tests` would be installed as a tool. A `tests` folder inside a tool is safe.

## Writing `tests/run`

Plain bash, no framework. `vid-tool/tests/run` is the reference example.

- Start with `#!/bin/bash` and a header comment: what the tests need, how to run them, and any floor point the tool doesn't meet.
- Make a temp folder with `mktemp -d`, remove it with a `trap ... EXIT`, and `cd` into it.
- Use a small `run` helper that takes a label, the expected exit code and a command. It prints one `PASS` or `FAIL` line per check and keeps going after a failure, so one run shows every failure.
- Check outputs as well as exit codes: the files made, the messages printed, and for a fake, how it was called.
- Print a pass and fail count at the end. Exit non-zero if anything failed.
- Keep it quick. If a suite gets slow enough that running one check matters, add a name filter to the helper before reaching for a framework.

### bash 3.2

macOS ships bash 3.2 at `/bin/bash`, and the tools must work with it. A Mac
with Homebrew's bash gets bash 5 from `#!/usr/bin/env bash`, so tests call
`/bin/bash "$tool"` explicitly.

Running the code under `/bin/bash` is the only reliable check for features
newer than 3.2. Of 16 such features tried, `bash -n` caught 4 and shellcheck
caught none. Most fail only when the line runs, and some fail without an error.
So a line the tests never reach is unchecked. This is the reason for covering
every option and every error path.

## External programs

| The program | What to do | Examples |
| --- | --- | --- |
| Can't be on the test machine, or acts on the real system | A **canned fake**: a script of the same name, first on `PATH`, that prints fixed replies and logs how it was called | `adb`, `osascript`, `open` |
| Can be installed | Use the **real program** | `ffmpeg` |
| Can be installed, but a test needs it to lack a feature | A **wrapping fake**: changes one answer and passes every other call to the real program | a fake `ffmpeg` that hides encoders from `ffmpeg -encoders` |

Don't replace an installable program with a canned fake. A canned `ffmpeg`
would test almost nothing, because the tool's value is in the arguments it
builds.

Rules for canned fakes:

- **Tests never depend on a person or a device.** A fake's replies can be written from what the tool parses. That is enough for the tests to be complete.
- **Use real output when you have it.** If a reply was copied from a real device, say so in a comment: device, Android version, date. A reply written by hand should say that too. This shows which replies are known to match reality and which are a guess.
- **A fake can't notice the real program changing.** If Android changes the format of a reply, the fake keeps passing. When a real device shows a bug the tests missed, add the real output as a test case first, then fix the tool.
- **A fake that runs as a background job can't be stopped with Ctrl+C's signal.** bash starts background jobs with that signal ignored. Stop it with a different signal. This applies to the fake `screenrecord` behind `adb-record`.
- The fake `adb` is shared by both `adb-` tools, so it lives in the top-level `tests/` folder.

## Prompts

| How the tool reads | How to test it |
| --- | --- |
| Plain `read` or `select` on standard input | Pipe the answers in |
| Refuses to prompt unless standard input is a terminal (`[[ -t 0 ]]`) | Test the refusal with no terminal. Test the menus with `expect` |

- **A new tool reads prompts from standard input.** Only require a terminal when there is a reason, and write the reason in a comment.
- **Don't read from `/dev/tty`.** It fails in CI and can't be tested with a pipe. `adb-shot -n` still does this, and [issue #6](https://github.com/chris-sloan/android-tools/issues/6) is to change it.
- **Don't use `script` to supply a terminal.** Its arguments differ between macOS and Linux, and on macOS it exited 0 without running the prompts, which would be a false pass.
- `expect` ships with macOS at `/usr/bin/expect`, so it needs no install. Keep expect scripts in the tool's `tests/` folder.

## Dependencies

A tool whose tests need something installed lists it in `<tool>/tests/Brewfile`:

```ruby
brew "ffmpeg"
```

Install with:

```bash
brew bundle --file=vid-tool/tests/Brewfile
```

- A tool with no `Brewfile` needs nothing installed. The `adb-` tools use fakes and have none.
- CI runs the same command before the tool's tests. No per-tool workflow is needed.
- The Brewfile is for the tests only. What a user needs is in the tool's README.
- This assumes macOS and Homebrew, which is where the tools run. If another OS is ever supported, this is the part to revisit.

When something is missing:

- **A needed program is missing:** `tests/run` exits non-zero at once, with a message that names the `brew bundle` command.
- **A check can't run** (for example the prompt tests without `expect`): print a visible `SKIP` line saying why. On a Mac a skip is not a failure. **When the `CI` variable is set, a skip counts as a failure.** Otherwise a broken install step in CI would show as a green run.

## Lint

Two checks, run on every tool script, every `tests/run` and `install.sh`:

```bash
bash -n <script>
shellcheck -S warning <script>
```

- `-S warning` fails on warnings and errors and ignores info and style notes. The info-level results on this repo were all false alarms.
- No baseline file. The count starts at zero and stays there. To silence a real false alarm, use a `# shellcheck disable=SCxxxx` line with a comment saying why.
- Lint catches ordinary mistakes. It does **not** catch bash features newer than 3.2. See [bash 3.2](#bash-32).
- shellcheck is not on a stock Mac (`brew install shellcheck`). When it is missing, the lint check is a `SKIP`, under the rule above.

## Repo-wide checks

`tests/run` at the top level holds checks that belong to no single tool:

- `bash -n` and shellcheck on every script.
- `install.sh` run with `HOME` pointed at a temp folder: it links every tool and nothing else.
- Every tool has a `README.md`, a `tests/run` and a row in the main README's table.

## CI

One GitHub Actions workflow covers every tool.

- **Runner:** `macos-26`, pinned. macOS is the only real target, and hosted macOS runners have only bash 3.2 on `PATH`. A `-latest` label moves without notice. The pin has to be bumped by hand when the image is retired.
- **Triggers:** pull requests, and pushes to `main`. No path filters, so every change runs everything.
- **Jobs:** a first job lists every `*/tests/run`. Each gets its own job, which installs that tool's `Brewfile` if it has one and then runs its tests. The top-level `tests/run` is one more job. A new tool is picked up with no workflow change.
- **Failures inform, they don't block.** No check is required by the `main` ruleset.
- **Failures are reported on the pull request.** A failing job posts a comment naming the tool, with its `FAIL` and `SKIP` lines. A pull request from a fork gets a read-only token and can't be commented on, so the same text also goes in the job summary.
- Free macOS runners allow 5 jobs at once. More tools than that will queue, not fail.

## Decided against, and when to revisit

| Not doing | Why | Revisit when |
| --- | --- | --- |
| A framework (bats) | Plain bash needs nothing installed and the existing tests use it | A tool needs something plain bash handles badly |
| An Android emulator in CI | It only runs on Linux runners, so not the real host. `adb-record` failed on it for an unknown reason | A fake passes while a real device fails |
| Linux runners | The tools are macOS tools. A pass on Linux proves little | Another OS is supported |
| bash 3.2 in a container | The image lacks `perl`, `expect` and macOS's utilities | Not expected |
| Required checks | Flakiness has not been measured | The workflow has run cleanly for a while |
| Path filters | They save little at this size and can skip a run that was needed | Runs become slow or numerous |

## Status

As of 2026-11-15. Update this section as the items land, and delete it once they all have.

In place:

- `vid-tool/tests/run` and `vid-tool/tests/prompts.exp`. They follow these guidelines, but still carry a "provisional" header and have no `Brewfile`.

Not built yet:

- The CI workflow, including the pull request comment.
- The top-level `tests/run` with lint and the `install.sh` check.
- Tests for `adb-record` and `adb-shot`, and the shared fake `adb`.
- `vid-tool/tests/Brewfile`, and the "provisional" header removed.
- The one shellcheck warning (`ls | grep` in `vid-tool`) fixed.
- `adb-shot -n` reading standard input ([issue #6](https://github.com/chris-sloan/android-tools/issues/6)).

### The research branch

The `research/testing-ci` branch holds the experiments behind issue #4. It is
not merged. Its `research/testing/` folder has a working fake `adb`, fake
`osascript` and `open`, and 49 checks for the `adb-` tools (`try-fakes`), an
expect script for prompts (`tty.exp`) and an `install.sh` check (`try-install`).
These are the starting point for the unbuilt tests above.

**Delete the branch when all three of these are on `main`:** the tests for
`adb-record`, the tests for `adb-shot`, and the `install.sh` check in the
top-level `tests/run`. Until then, keep it. Nothing else on it is needed: the
findings are in the comment on issue #4, and its workflow file is a throwaway.
