#!/bin/sh
# ghidra - headless Ghidra + the JDK version that release requires, PyGhidra
# for Python 3 scripts, and the `prefetch` hook that `easyre` triage runs in
# the background on the main native binary (agent/prefetch/). See the
# ghidra-headless skill.
set -e

apt-get update
apt-get install -y --no-install-recommends curl jq unzip ca-certificates

GHIDRA_DIR=/opt/ghidra
if [ ! -x "$GHIDRA_DIR/support/analyzeHeadless" ]; then
  TMP=$(mktemp -d)
  URL=$(curl -fsSL https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest \
    | jq -r '.assets[].browser_download_url | select(test("ghidra_.*PUBLIC.*\\.zip$"))' | head -1)
  [ -n "$URL" ] || { echo "could not resolve a Ghidra release URL (GitHub API rate limit?)"; exit 1; }
  echo "Ghidra: $URL"
  curl -fsSL "$URL" -o "$TMP/ghidra.zip"
  unzip -q "$TMP/ghidra.zip" -d "$TMP"
  inner=$(find "$TMP" -maxdepth 1 -type d -name 'ghidra_*_PUBLIC' | head -1)
  rm -rf "$GHIDRA_DIR" && mkdir -p "$GHIDRA_DIR"
  cp -a "$inner/." "$GHIDRA_DIR/"
  rm -rf "$TMP"
fi

# Install the JDK this release asks for (Ghidra 12.2 requires 25) and pin it,
# so a different java on PATH (e.g. one pulled in by apktool) never wins.
JMIN=$(sed -n 's/^application.java.min=//p' "$GHIDRA_DIR/Ghidra/application.properties")
JMIN=${JMIN:-25}
apt-get install -y --no-install-recommends "openjdk-${JMIN}-jdk-headless" \
  || { echo "Ghidra needs JDK $JMIN but openjdk-${JMIN}-jdk-headless is not in apt"; exit 1; }
JDK=$(ls -d /usr/lib/jvm/java-"${JMIN}"-openjdk-* | head -1)
sed -i "s|^JAVA_HOME_OVERRIDE=.*|JAVA_HOME_OVERRIDE=$JDK|" "$GHIDRA_DIR/support/launch.properties"

# PyGhidra (Python 3 scripts via pyghidraRun). Installed offline from the
# wheels shipped with Ghidra; without it pyghidraRun stops at an interactive prompt.
pip install --no-cache-dir --no-index -f "$GHIDRA_DIR/Ghidra/Features/PyGhidra/pypkg/dist" pyghidra \
  || echo "!! PyGhidra install failed: Java scripts still work, Python 3 scripts will not"

mkdir -p /opt/easyre/tools/ghidra_scripts
ln -sfn "$GHIDRA_DIR/support/analyzeHeadless" /opt/easyre/tools/analyzeHeadless
ln -sfn "$GHIDRA_DIR/support/pyghidraRun" /opt/easyre/tools/pyghidraRun

# Ship the prefetch hook and its Java post-script. Prefer this module's own
# tree (source checkout, or /opt/easyre/toolchain after the Dockerfile COPY).
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC="$HERE/.."
[ -f "$SRC/ghidra_scripts/PrefetchDump.java" ] || SRC=/opt/easyre/toolchain
cp "$SRC/prefetch" /opt/easyre/tools/prefetch
cp "$SRC/ghidra_scripts/PrefetchDump.java" /opt/easyre/tools/ghidra_scripts/PrefetchDump.java
chmod +x /opt/easyre/tools/prefetch

# Self-test: a full prefetch run on a tiny binary proves the JDK, the launcher
# and the post-script all work (and pre-compiles the script for later runs).
T=$(mktemp -d)
if /opt/easyre/tools/prefetch /bin/true "$T/out" > "$T/log" 2>&1; then
  echo "[x] ghidra headless + prefetch hook ($(cat "$T/out/DONE"))"
else
  tail -40 "$T/log"
  echo "!! prefetch self-test failed"
  exit 1
fi
rm -rf "$T"
