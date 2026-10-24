#!/bin/sh
# js - JavaScript / Node / Electron targets: unpack asar, undo bundling and
# obfuscation, pretty-print. Node is already in the base image. See the
# javascript-electron skill.
set -e

npm i -g @electron/asar webcrack js-beautify

echo "js tools:"
for t in asar webcrack js-beautify; do
  command -v "$t" >/dev/null 2>&1 && printf '  [x] %s\n' "$t" || printf '  [ ] %s\n' "$t"
done
