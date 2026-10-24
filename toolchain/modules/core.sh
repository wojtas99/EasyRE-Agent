#!/bin/sh
# core - the everyday static-analysis and scripting toolbox referenced by
# re-methodology and most file-type skills: binutils, debuggers, radare2,
# packers, carving, and the Python RE libraries (capstone/keystone/unicorn/
# z3/lief/pefile), plus yara + FLOSS + capa.
set -e

apt-get update
apt-get install -y --no-install-recommends \
  binutils gdb gdbserver strace ltrace \
  radare2 upx-ucl binwalk yara xxd bsdmainutils \
  cmake build-essential libmagic1 patchelf

# Python RE libraries. PIP_BREAK_SYSTEM_PACKAGES=1 is set in the image env.
pip install --no-cache-dir \
  capstone keystone-engine unicorn z3-solver \
  pefile lief pyelftools macholib \
  yara-python ropgadget pwntools \
  pycryptodome \
  flare-floss flare-capa

echo "core tools:"
for t in objdump readelf nm strings gdb strace radare2 upx binwalk yara floss capa; do
  command -v "$t" >/dev/null 2>&1 && printf '  [x] %s\n' "$t" || printf '  [ ] %s\n' "$t"
done
python3 - <<'PY' || true
for m in ("capstone","keystone","unicorn","z3","pefile","lief","Crypto","yara","ropgadget"):
    try:
        __import__(m); print(f"  [x] py:{m}")
    except Exception:
        print(f"  [ ] py:{m}")
PY
