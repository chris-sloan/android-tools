#!/usr/bin/env bash
# Links every tool in this folder into ~/.local/bin so it's on your PATH.
# A tool is any folder containing an executable with the same name,
# e.g. adb-shot/adb-shot. Safe to re-run after adding a new tool.
set -eo pipefail

here=$(cd "$(dirname "$0")" && pwd)
bin="$HOME/.local/bin"
mkdir -p "$bin"

for dir in "$here"/*/; do
  name=$(basename "$dir")
  tool="$dir$name"
  [[ -x $tool ]] || continue
  target="$bin/$name"
  if [[ -e $target && ! -L $target ]]; then
    echo "skip  $name: $target exists and isn't a link (move it aside first)" >&2
    continue
  fi
  ln -sfn "$tool" "$target"
  echo "link  $name -> $tool"
done

case ":$PATH:" in
  *":$bin:"*) ;;
  *) echo "Note: $bin isn't on your PATH; add it in ~/.zshrc." ;;
esac
