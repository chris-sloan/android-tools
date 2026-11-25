# doc-tool

Find out-of-date pages in a folder of Markdown files, such as a wiki, and open them in glow. It uses git's record of when each page was last edited, not the file's date on disk, so the dates stay right after a fresh clone.

```bash
doc-tool ~/wiki
```

A menu asks what to show: pages oldest or newest first, who edits them, a status summary, or the full status report.

## Usage

```
doc-tool [-a | -n | -u | -r | -R] [-s text] [-b author] [-g] [-O age] [-x pattern] [-m count] [-f file] [-C] [-l] [folder]
```

| Option | What it does | Default |
| --- | --- | --- |
| `folder` | A git repo, or any folder inside one. Every `.md` and `.markdown` file under it that git tracks is a page. | This folder |
| `-a` | Pages, oldest first, then pick one to open in glow. | Menu in a terminal, `-a` otherwise |
| `-n` | Pages, newest first, then pick one to open in glow. | |
| `-u` | Who has edited the pages: how many each, how many they edited last, and when. People who have left are marked `(left)`. | |
| `-r` | Status summary: numbers for the whole folder, such as how many pages haven't been edited in 12 months. Printed, copied to the clipboard and saved on the Desktop. | |
| `-R` | Full status report: the summary, then every stale page by folder, and every page whose editors have all left. Printed, copied and saved like `-r`. | |
| `-s text` | Only pages whose path or contents contain this text. Any case. | All pages |
| `-b author` | Only pages this person has edited. Part of a name or email is enough. | Anyone |
| `-g` | Only pages whose editors have all left. Needs the [gone list](#people-who-have-left). | |
| `-O age` | Only pages not edited for this long: `30d`, `8w`, `6m` or `2y`. With `-r` and `-R`, the age that counts as stale. | `12m` for `-r` and `-R` |
| `-x pattern` | Skip commits whose message matches this pattern (extended regex, any case). Repeat to add more. | Skip none |
| `-m count` | With `-a` or `-n`, show this many pages at a time. `-m 0` shows them all. | `20` |
| `-f file` | With `-r` or `-R`, save the report to this file instead. | `~/Desktop/<folder>-status-<date>.txt` |
| `-C` | With `-r` or `-R`, don't copy the report to the clipboard. | Copy |
| `-l` | Just print the list; don't offer to open a page. | |
| `-h` | Show help. | |

Options go before the folder. Quote folder names with spaces. A month is 30 days and a year 365.

## Examples

```bash
doc-tool -a ~/wiki                       # oldest pages first; pick one to read
doc-tool -a -O 1y ~/wiki                 # only pages not edited for a year
doc-tool -n -s gradle ~/wiki             # recently edited pages that mention gradle
doc-tool -n -m 10 ~/wiki                 # the 10 most recently edited pages
doc-tool -a -b ann ~/wiki                # pages Ann has edited
doc-tool -a -g ~/wiki                    # pages nobody who edited them is still here to check
doc-tool -u ~/wiki/android               # who edits the android section
doc-tool -r ~/wiki                       # status summary, ready to paste into Slack or a ticket; also saved on the Desktop
doc-tool -R ~/wiki                       # the full report, with every stale page
doc-tool -r -O 6m -f ~/Documents/wiki.txt ~/wiki   # stricter summary, saved somewhere else
doc-tool -a -l ~/wiki | grep onboarding  # plain list for other commands
```

## Opening pages

With `-a` or `-n` in a terminal, the pages appear as a numbered list, 20 at a time:

```
120 pages.
     AGE    LAST EDIT   EDITED BY          PAGE
  1) 4.8y   2022-02-11  Ann Old            Profiles.md
  ...
 20) 3.9y   2022-12-01  Bob Dev            releases/v1.md
Pages 1-20 of 120. Number to open, Enter for more, q to quit:
```

- **A number** opens that page in glow. Any number from the whole list works, not just the ones on screen. Quit glow with `q` to come back to the same place in the list.
- **Enter** shows the next 20. On the last screen it goes back to the start.
- **b** goes back 20.
- **q** quits.

`-m 50` shows 50 at a time and `-m 0` shows them all at once. To change the usual number, set `page_limit` at the top of the script. `-s`, `-b` and `-O` narrow a big wiki down.

When the output goes to a file or another command, or with `-l`, the first 20 pages are printed, with a note of how many there are in all. `-m 0` prints every page; to scroll through them, use `doc-tool -a -l -m 0 | less`.

## Reading a page

glow shows the page in `less`, and the bottom line lists the main keys while you read:

| Key | What it does |
| --- | --- |
| `g` / `G` | Go to the top / bottom |
| `Space` or `f` / `b` | Page down / up |
| `d` / `u` | Half a page down / up |
| `j` / `k`, or the arrow keys | One line down / up |
| `/word` then Enter | Search for a word; `?word` searches backwards |
| `n` / `N` | Next / previous match |
| `h` | Every key `less` has; `q` closes it |
| `q` | Back to the list |

If you've set `PAGER` to something other than `less`, glow uses that instead, its keys apply, and the bottom line isn't changed.

## Status reports (`-r` and `-R`)

`-r` gives the numbers for the whole folder:

```
Docs status: wiki, 19 Nov 2026
120 pages in 9 folders, edited by 14 people.

Last edited:
  in the last 3 months      30   25%
  3 to 12 months ago        45   38%
  1 to 2 years ago          25   21%
  over 2 years ago          20   17%

Not edited in 12 months: 45 pages (38%)
Every editor has left: 12 pages (10%)
Oldest: onboarding/tools.md, last edited 2019-03-01 (7.7y)

Folders with the most stale pages:
    12 of 14    86%  releases/
     6 of 20    30%  android/
  ...

Folders with the most pages whose editors have all left:
  ...

Who edited the stale pages last:
    20  Ann Old
  ...
```

Each list shows the top 5. The "editors have all left" lines only appear once there's a [gone list](#people-who-have-left).

`-R` adds every stale page, grouped by folder, then every page whose editors have all left:

```
Not edited in 12 months, by folder:

android/ 6 of 20 stale
  3.1y   2023-10-02  Ann Old            android/gradle.md
  ...

Every editor has left, by folder:

releases/ 4 of 14 with no current editor
  ...
```

Both are printed, copied to the clipboard and saved as `~/Desktop/<folder>-status-<date>.txt` (`-R`: `<folder>-status-full-<date>.txt`), for example `wiki-status-2026-11-19.txt`. A second report on the same day is saved as `-2`, `-3` and so on, never over the first. `-f file` saves to that file instead.

To save reports somewhere else every time, change `report_dir` at the top of the script; the folder is made if it doesn't exist. Keep it outside the wiki, so reports don't add to it. Set `report_dir=""` to stop saving.

## People who have left

List them in `gone` at the top of the script, separated by `|`. Part of a name or email is enough, in any case:

```bash
gone="ann@example.com|bob old"
```

Then:

- `-g` shows only pages whose editors have all left. Nobody who worked on them is around to check them.
- `-u` marks those people `(left)`.
- `-r` counts their pages, and `-R` lists them by folder.

A page with even one current editor isn't counted, so the list stays short.

## Skipping bulk commits (`-x`)

A commit that reformats or moves every page makes them all look freshly edited. Skip those commits by their message:

```bash
doc-tool -r -x '^chore' -x 'reformat|bulk rename' ~/wiki
```

A skipped commit doesn't count as an edit, and its author doesn't count as an editor. If every commit to a page is skipped, the page's first commit is used. To skip the same commits every time, set `ignore_re` at the top of the script.

## How it works

- `git ls-files` lists the pages. Files git doesn't track yet aren't pages. A page that is staged but never committed shows as `uncommitted`, including in a repo with no commits yet.
- Page names with quotes, backslashes or spaces are fine. A name with a tab or line break in it is left out, with a note saying how many.
- One `git log` over the folder gives every page's last edit, its editors and their commit dates, so a big wiki is still quick.
- A merge commit counts as an edit to a page only when it changed the page itself, such as a conflict resolved by hand. Pages it just brought in from a branch keep the dates and editors of their own commits.
- The date is the author date: when the edit was written, not when it was merged or rebased.
- Names and emails go through the repo's `.mailmap`, so one person with two emails can be counted once.
- `-s` searches with `git grep`, so it reads the files as they are now.
- Nothing is ever changed, in the folder or in git.

## Troubleshooting

- **"isn't in a git repo"**: the folder must be a git repo or inside one. doc-tool reads every date from git.
- **"shallow clone"**: the repo was cloned with `--depth`, so older history is missing and dates can look too recent. Run the `git fetch --unshallow` command it prints.
- **A renamed page has lost its older editors**: git records a rename as a new file, so editors from before the rename aren't counted. The last-edit date is still right.
- **"glow isn't installed"**: `brew install glow`. Everything except opening a page works without it.
- **Every page looks recently edited**: a bulk commit probably touched them all. Find it with `git log --stat -- '*.md'` and skip it with `-x`.

## Tests

```bash
doc-tool/tests/run
```

Builds small wiki repos with back-dated commits in a temp folder. Needs git; the prompt tests use `expect`, which ships with macOS.
