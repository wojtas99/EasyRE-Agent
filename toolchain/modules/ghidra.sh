#!/bin/sh
# ghidra - headless Ghidra + a JDK 21, plus the `prefetch` hook that `easyre`
# triage runs in the background on the main native binary (decompiled C,
# function list and strings dropped into agent/prefetch/). See the
# ghidra-headless skill.
set -e

apt-get update
apt-get install -y --no-install-recommends openjdk-21-jdk-headless curl jq unzip ca-certificates

GHIDRA_DIR=/opt/ghidra
if [ ! -x "$GHIDRA_DIR/support/analyzeHeadless" ]; then
  TMP=$(mktemp -d)
  URL=$(curl -fsSL https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest \
    | jq -r '.assets[].browser_download_url | select(test("ghidra_.*PUBLIC.*\\.zip$"))' | head -1)
  [ -n "$URL" ] || { echo "could not resolve a Ghidra release URL"; exit 1; }
  echo "Ghidra: $URL"
  curl -fsSL "$URL" -o "$TMP/ghidra.zip"
  rm -rf "$GHIDRA_DIR"
  mkdir -p "$GHIDRA_DIR"
  unzip -q "$TMP/ghidra.zip" -d "$TMP"
  # The zip contains a single ghidra_<ver>_PUBLIC/ top dir.
  inner=$(find "$TMP" -maxdepth 1 -type d -name 'ghidra_*_PUBLIC')
  cp -a "$inner/." "$GHIDRA_DIR/"
  rm -rf "$TMP"
fi

mkdir -p /opt/easyre/tools /opt/easyre/tools/ghidra_scripts
ln -sfn "$GHIDRA_DIR/support/analyzeHeadless" /opt/easyre/tools/analyzeHeadless

# Ship the prefetch hook and its Ghidra post-script. The install.sh copies the
# toolchain tree to /opt/easyre/toolchain, so prefer that; fall back to this
# module's own directory when run standalone from the source tree.
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC="$HERE/.."
[ -f "$SRC/ghidra_scripts/PrefetchDump.py" ] || SRC=/opt/easyre/toolchain
cp "$SRC/prefetch" /opt/easyre/tools/prefetch
cp "$SRC/ghidra_scripts/PrefetchDump.py" /opt/easyre/tools/ghidra_scripts/PrefetchDump.py
chmod +x /opt/easyre/tools/prefetch

"$GHIDRA_DIR/support/analyzeHeadless" 2>&1 | head -1 || true
echo "[x] ghidra headless + prefetch hook"
