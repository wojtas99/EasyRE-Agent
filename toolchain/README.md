# Toolchain

This file lists what is installed in the image. The agent reads it to know
which tools it can use. Always confirm with `which <tool>` before use; if a
tool is missing, you are root with network access, so install it (`apt-get`,
`pip`, `npm`) or run the matching module: `/opt/easyre/toolchain/modules/<name>.sh`.

## How it is built

The toolchain is split into modules under `toolchain/modules/*.sh`, selected at
build time with the `EASYRE_TOOLS` build-arg (comma-separated). The `wine`
module is always installed. Default optional set: `core,die`.

Enable more in `docker-compose.yml`:

```yaml
services:
  easyre:
    build:
      context: .
      args:
        EASYRE_TOOLS: "core,die,ghidra"
```

Each module is standalone and idempotent, so the agent can also pull one in
during a job, e.g. `/opt/easyre/toolchain/modules/ghidra.sh`.

## Always installed: `wine`

| Tool | Use |
|---|---|
| Wine (32 + 64 bit) | Run Windows `.exe`: `wine /work/src/app.exe` (stdin: `printf 'guess\n' \| wine app.exe`) |
| Xvfb | Virtual display for GUI programs: `xvfb-run -a wine app.exe` |
| MinGW runtime DLLs | `libstdc++-6.dll`, `libgcc_s_*.dll`, `libwinpthread-1.dll` are in the Wine prefix, so MinGW/g++ binaries run without copying DLLs |

## Modules

### `core` (default) — ~0.5 GB

Everyday static analysis and solver scripting.

| Tool | Use |
|---|---|
| `objdump` `readelf` `nm` `strings` (binutils) | Disassembly, headers, symbols, ASCII/wide strings |
| `gdb` + `gdbserver`, `strace`, `ltrace` | Native debugging and syscall/library tracing |
| `radare2` (`r2`) | Interactive/scriptable disassembly: `r2 -A -q -c 'afl;pdf @ main' file` |
| `upx` | Unpack UPX: `upx -d -o out.exe packed.exe` |
| `binwalk` | Carve embedded data: `binwalk -e file` |
| `exiftool`, `xxd` | File metadata; hex dumps (see `formats-forensics`) |
| `yara` + `yara-python` | Signature matching |
| `floss`, `capa` | Deobfuscated strings; capability detection |
| py: `capstone` `keystone` `unicorn` | Disassemble / assemble / emulate |
| py: `z3-solver` | Constraint solving |
| py: `pefile` `lief` `pyelftools` `macholib` | Parse PE / ELF / Mach-O |
| py: `pwntools` `ropgadget` `pycryptodome` | Exploit/solver helpers, ROP, crypto |

### `die` (default) — ~0.3 GB

`diec` — Detect It Easy console. `easyre` triage calls it to fill `triage.md`
with compiler, packer and protector detection: `diec <file>`.

### `ghidra` — ~1.5 GB

Headless Ghidra, the JDK the release requires (installed and pinned automatically), and PyGhidra for Python 3 scripts.

- `analyzeHeadless` (also at `/opt/easyre/tools/analyzeHeadless`): batch decompilation.
- `prefetch <binary> <outdir>`: the triage hook. If the `ghidra` module is
  installed, triage runs it in the background on the main native binary and
  drops `decompiled.c`, `functions.txt`, `strings.txt`, `imports.txt` into
  `/work/agent/prefetch/`. Read those first instead of re-analyzing.

See the `ghidra-headless` skill.

### `dotnet` — ~1 GB

.NET / Unity managed code.

| Tool | Use |
|---|---|
| `dotnet` (SDK 10) | Run managed tools; build helpers |
| `ilspycmd` | Decompile assemblies to C#: `ilspycmd app.dll -o out/` |
| `il2cppdumper` | Unity IL2CPP: recover metadata from `GameAssembly` + `global-metadata.dat` |
| `de4dot` | Deobfuscate protected .NET (best effort) |

### `jvm` — ~0.2 GB

Java / Android (shares a JRE with `ghidra` if present).

| Tool | Use |
|---|---|
| `jadx` | dex/apk/jar → Java: `jadx -d out app.apk` |
| `apktool` | APK resources + smali: `apktool d app.apk` |
| `cfr` | JAR/class decompiler: `cfr app.jar --outputdir out` |

### `python` — ~0.1 GB

Packaged Python.

| Tool | Use |
|---|---|
| `pyinstxtractor-ng` | Unpack PyInstaller onefile/onedir to `.pyc` |
| `pycdc` / `pycdas` | Decompile / disassemble `.pyc` (best for 3.9+) |
| `decompyle3`, `uncompyle6` | Decompile `.pyc` for Python ≤ 3.8 |
| py: `xdis` | Detect the bytecode version to pick the tool |

### `js` — ~0.1 GB

JavaScript / Node / Electron.

| Tool | Use |
|---|---|
| `asar` (`@electron/asar`) | Unpack `app.asar`: `asar extract app.asar out/` |
| `webcrack` | Undo webpack/bundling + common obfuscation |
| `js-beautify` | Pretty-print minified JS |

### `angr` — ~1+ GB

`angr` — binary symbolic execution (Python). Opt-in; heavy. See the `solvers`
skill.

## Also in the base image (not a module)

Python 3 + pip, Node.js, `7z`/`unzip`, `file`, `curl`, `git`, `jq`.
