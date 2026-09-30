# Toolchain

| Tool | Use |
|---|---|
| Wine (32 + 64 bit) | Run Windows `.exe` files: `wine /work/src/app.exe` (input via stdin: `printf 'guess\n' \| wine app.exe`) |
| Xvfb | Virtual display for GUI programs: `xvfb-run -a wine app.exe` |
| MinGW runtime DLLs | `libstdc++-6.dll`, `libgcc_s_*.dll`, `libwinpthread-1.dll` are preinstalled in the Wine prefix, so programs built with MinGW/g++ run without copying DLLs |
