#!/bin/sh
# emu - full-binary emulation with Qiling (built on unicorn), for when Wine is
# the wrong tool: a protector detects the Wine/debugger environment and refuses
# to run, or you want to execute one function in isolation. Qiling reimplements
# many OS APIs in Python, so there is no real process or debugger for
# anti-analysis to notice. See the emulation skill. (unicorn is in core.)
set -e

apt-get update
apt-get install -y --no-install-recommends git

pip install --no-cache-dir qiling

# Qiling needs a rootfs. The Linux/UEFI/macOS rootfs is freely redistributable
# and fetched here. Windows PE emulation additionally needs Windows system DLLs,
# which are NOT redistributable: supply them yourself (Qiling ships
# examples/scripts/dllscollector.bat, run on a Windows box) into
# $QILING_ROOTFS/x8664_windows and x86_windows. ELF targets work out of the box.
ROOT=/opt/easyre/qiling-rootfs
if [ ! -d "$ROOT/.git" ]; then
  git clone --depth 1 https://github.com/qilingframework/rootfs.git "$ROOT" \
    || echo "!! rootfs clone failed; set QILING_ROOTFS yourself (see the emulation skill)"
fi

python3 - <<'PY' || true
try:
    import qiling
    print("  [x] qiling", getattr(qiling, "__version__", "?"))
except Exception as e:
    print("  [ ] qiling:", e)
PY
command -v qltool >/dev/null 2>&1 && echo "  [x] qltool" || echo "  [ ] qltool"
echo "QILING_ROOTFS=$ROOT (ELF ready; Windows PE needs user-supplied DLLs)"
