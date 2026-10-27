#!/bin/sh
# autoit - compiled AutoIt scripts (AU3!EA05 / AU3!EA06 inside the .exe):
# autoit-ripper extracts the embedded script and rebuilds .au3 source, and the
# AutoIt interpreter (`autoit3`, runs under Wine) executes an edited copy of the
# recovered script to dump values. See the autoit skill.
set -e

apt-get update
apt-get install -y --no-install-recommends curl unzip ca-certificates

# PIP_BREAK_SYSTEM_PACKAGES=1 is set in the image env.
pip install --no-cache-dir autoit-ripper

# AutoIt interpreter from the official portable zip. Optional: if the download
# fails, extraction still works and only `autoit3` is missing.
mkdir -p /opt/easyre/tools
EXE=$(find /opt/autoit -name AutoIt3.exe 2>/dev/null | head -1)
if [ -z "$EXE" ]; then
  TMP=$(mktemp -d)
  if curl -fsSL "https://www.autoitscript.com/cgi-bin/getfile.pl?autoit3/autoit-v3.zip" -o "$TMP/autoit.zip" \
     && rm -rf /opt/autoit && mkdir -p /opt/autoit && unzip -oq "$TMP/autoit.zip" -d /opt/autoit; then
    EXE=$(find /opt/autoit -name AutoIt3.exe | head -1)
  fi
  rm -rf "$TMP"
fi
if [ -n "$EXE" ]; then
  printf '#!/bin/sh\nexec wine "%s" "$@"\n' "$EXE" > /opt/easyre/tools/autoit3
  chmod +x /opt/easyre/tools/autoit3
else
  echo "!! AutoIt interpreter download failed (skipped): autoit3 will be missing"
fi

echo "autoit tools:"
for t in autoit-ripper autoit3; do
  command -v "$t" >/dev/null 2>&1 && printf '  [x] %s\n' "$t" || printf '  [ ] %s\n' "$t"
done
