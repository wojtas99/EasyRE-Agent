#!/bin/sh
# python - packaged-Python targets: unpack PyInstaller, then decompile the
# bytecode with the right tool for the version. See the python-targets skill.
set -e

apt-get update
apt-get install -y --no-install-recommends git cmake build-essential

# PIP_BREAK_SYSTEM_PACKAGES=1 is set in the image env.
# pyinstxtractor-ng: unpack PyInstaller onefile/onedir into .pyc files.
# decompyle3 / uncompyle6: Python <= 3.8 bytecode. xdis: version detection.
pip install --no-cache-dir pyinstxtractor-ng decompyle3 uncompyle6 xdis

# pycdc / pycdas: C++ decompiler + disassembler, the best bet for 3.9+ .pyc.
if [ ! -x /opt/easyre/tools/pycdc ]; then
  TMP=$(mktemp -d)
  git clone --depth 1 https://github.com/zrax/pycdc "$TMP/pycdc"
  cmake -S "$TMP/pycdc" -B "$TMP/pycdc/build" -DCMAKE_BUILD_TYPE=Release
  cmake --build "$TMP/pycdc/build" -j "$(nproc)"
  mkdir -p /opt/easyre/tools
  cp "$TMP/pycdc/build/pycdc" /opt/easyre/tools/pycdc
  cp "$TMP/pycdc/build/pycdas" /opt/easyre/tools/pycdas
  rm -rf "$TMP"
fi

echo "python-target tools:"
for t in pyinstxtractor-ng pycdc pycdas decompyle3 uncompyle6; do
  command -v "$t" >/dev/null 2>&1 && printf '  [x] %s\n' "$t" || printf '  [ ] %s\n' "$t"
done
