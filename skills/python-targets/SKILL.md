---
name: python-targets
description: Packaged Python apps (PyInstaller, Nuitka) and raw .pyc bytecode. Unpack, detect the Python version, decompile with the right tool. Load when triage flags a PyInstaller/Nuitka bundle or a .pyc. Requires the python toolchain module.
---

# python-targets

## When to use

Triage shows a PyInstaller archive (`MEI` magic, `PYZ-00.pyz`), a Nuitka build, or the handout is `.pyc`/`.pyz`. Requires the `python` module; install with `/opt/easyre/toolchain/modules/python.sh` if the tools are missing.

## Steps

1. **PyInstaller**: extract the bundle, then decompile the entry-point module.
   - `pyinstxtractor-ng app.exe` → a `*_extracted/` dir with `.pyc` files and the `PYZ-00.pyz` contents.
   - The entry point is the `.pyc` named like the program (no standard-library package path). Decompile that first.
2. **Detect the bytecode version** before decompiling — it decides the tool.
3. **Decompile**:
   - Python **3.9+**: `pycdc` (and `pycdas` for a disassembly when decompile fails).
   - Python **≤ 3.8**: `decompyle3` or `uncompyle6` usually give cleaner source.
4. **Nuitka** is compiled to C → a native binary, not bytecode. Treat it as native (`native-binaries`, `ghidra-headless`); the Python logic is inlined into C.

## Tools and commands

```sh
pyinstxtractor-ng /work/src/app.exe                 # -> app.exe_extracted/
python3 -c "import xdis.magics as m; print(open('x.pyc','rb').read(4).hex())"  # magic -> version
pycdc  app_extracted/app.pyc  > /work/agent/app.py  # 3.9+
pycdas app_extracted/app.pyc  > /work/agent/app.dis # disassembly fallback
decompyle3 old.pyc > out.py                          # <= 3.8
uncompyle6 old.pyc > out.py                          # <= 3.8 alternative
```

If a `.pyc` header is stripped (raw code object), prepend the right 16-byte header for its version before decompiling, or just read `pycdas` output.

## Pitfalls

- Wrong-version decompiler → wrong or empty output. Check the magic first.
- `pyinstxtractor-ng` leaves `.pyc` without a proper header for some versions — `pycdc` handles raw code objects; the legacy tools may need the header fixed.
- The interesting code is almost never the stdlib `.pyc` files it also dumps — pick the app module.
- A failed decompile still gives you `pycdas` disassembly, which is enough to read a simple check.

## Verification

- Reimplement or run the recovered check with the candidate (`python3 out.py`), then `easyre check '<answer>'`.
