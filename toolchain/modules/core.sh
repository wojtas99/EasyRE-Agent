#!/bin/sh
# core - the everyday static-analysis and scripting toolbox referenced by
# re-methodology and most file-type skills: binutils, debuggers, radare2,
# packers, carving, exiftool, the Python RE libraries (capstone/keystone/
# unicorn/z3/lief/pefile), yara + a crypto-constant rule set, FLOSS and capa.
set -e

apt-get update
apt-get install -y --no-install-recommends \
  binutils gdb gdbserver strace ltrace \
  radare2 upx-ucl binwalk yara xxd bsdmainutils libimage-exiftool-perl \
  cmake build-essential libmagic1 patchelf curl jq unzip

# Python RE libraries. PIP_BREAK_SYSTEM_PACKAGES=1 is set in the image env.
pip install --no-cache-dir \
  capstone keystone-engine unicorn z3-solver \
  pefile lief pyelftools macholib \
  yara-python ropgadget pwntools \
  pycryptodome \
  flare-floss

mkdir -p /opt/easyre/tools/yara

# capa: the standalone release has its rules embedded (the pip package does not
# and fails with "default embedded rules not found").
TMP=$(mktemp -d)
URL=$(curl -fsSL https://api.github.com/repos/mandiant/capa/releases/latest \
  | jq -r '.assets[].browser_download_url | select(test("/capa-v[^/]*-linux\\.zip$"))' | head -1) || true
if [ -n "${URL:-}" ] && curl -fsSL "$URL" -o "$TMP/capa.zip"; then
  unzip -oq "$TMP/capa.zip" -d /opt/easyre/tools && chmod +x /opt/easyre/tools/capa
else
  echo "!! capa download failed (skipped)"
fi
rm -rf "$TMP"

# Crypto-constant YARA rules (see the crypto-id skill).
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC="$HERE/.."
[ -f "$SRC/yara/crypto.yar" ] || SRC=/opt/easyre/toolchain
cp "$SRC/yara/crypto.yar" /opt/easyre/tools/yara/crypto.yar

echo "core tools:"
for t in objdump readelf nm strings gdb strace radare2 upx binwalk exiftool yara floss capa; do
  command -v "$t" >/dev/null 2>&1 && printf '  [x] %s\n' "$t" || printf '  [ ] %s\n' "$t"
done
python3 - <<'PY' || true
for m in ("capstone","keystone","unicorn","z3","pefile","lief","Crypto","yara","ropgadget"):
    try:
        __import__(m); print(f"  [x] py:{m}")
    except Exception:
        print(f"  [ ] py:{m}")
PY
