#!/bin/sh
# wine - run Windows .exe targets on Linux (32 + 64 bit) + Xvfb for GUI +
# the MinGW runtime DLLs so g++/MinGW-built binaries run without copying DLLs.
# xdotool drives GUI targets on the virtual display (see the dynamic-wine skill).
# Always installed; required by `easyre` auto-verify and `doctor`.
set -e

dpkg --add-architecture i386
apt-get update
apt-get install -y --no-install-recommends wine wine64 wine32:i386 xvfb xauth xdotool \
  gcc-mingw-w64-x86-64-posix-runtime gcc-mingw-w64-i686-posix-runtime \
  mingw-w64-x86-64-dev mingw-w64-i686-dev

WINEDLLOVERRIDES="mscoree,mshtml=" xvfb-run -a wineboot -i || true
wineserver -w || true

W="${WINEPREFIX:-/root/.wine}/drive_c/windows"
for f in libstdc++-6.dll libgcc_s_seh-1.dll libssp-0.dll; do
  cp /usr/lib/gcc/x86_64-w64-mingw32/*-posix/$f "$W/system32/" 2>/dev/null || true
done
cp /usr/x86_64-w64-mingw32/lib/libwinpthread-1.dll "$W/system32/" 2>/dev/null || true
for f in libstdc++-6.dll libgcc_s_dw2-1.dll libgcc_s_sjlj-1.dll libssp-0.dll; do
  cp /usr/lib/gcc/i686-w64-mingw32/*-posix/$f "$W/syswow64/" 2>/dev/null || true
done
cp /usr/i686-w64-mingw32/lib/libwinpthread-1.dll "$W/syswow64/" 2>/dev/null || true

ls "$W/system32" | grep -E 'libstdc|winpthread|libgcc' || true
wine --version
