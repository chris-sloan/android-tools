# Testing research (issue #4)

Throwaway experiments behind the findings comment on issue #4. This branch is
evidence, not a proposal. Nothing here is meant to be merged.

| File | What it tries |
| --- | --- |
| `fake-bin/adb`, `fake-bin/osascript`, `fake-bin/open` | Fakes put first on `PATH`. They return canned output and log each call. |
| `try-fakes` | Runs `adb-shot` and `adb-record` against the fakes, with no device. |
| `try-bash32`, `bash4-snippets/` | One newer-bash feature per file. Shows which ones `bash -n` catches and which only fail when run. |
| `try-tty`, `tty.exp` | Prompts that read the terminal: no terminal, piped input, `script`, `expect`. |
| `try-install` | Runs `install.sh` in a temp `HOME` with test folders added. |
| `../../.github/workflows/research-testing.yml` | Runs all of the above, plus timings, on GitHub's macOS and Linux runners. |

Each script takes an optional bash binary as its first argument (default `/bin/bash`).
