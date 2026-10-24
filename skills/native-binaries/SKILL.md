---
name: native-binaries
description: PE and ELF compiled code (C, C++, Go, Rust, Delphi, VB6). Identify the toolchain, find the check function and read it. Load after triage says the target is a native executable.
---

# native-binaries

## When to use

The target is a compiled native executable (PE `.exe`/`.dll` or ELF) and not .NET, Python, Java or JavaScript. Triage's `file`/DIE line and the markers tell you which.

## Steps

1. **Confirm the toolchain** from triage markers. The toolchain decides how you read it:
   - **MSVC / MinGW / GCC / Clang C or C++**: normal functions, read the decompiler output directly.
   - **Go**: static, stripped of normal symbols but function names survive in the `gopclntab`. Recover them first.
   - **Rust**: heavy monomorphized generics and panic strings with `src/main.rs` paths; follow the panic/format strings to the logic.
   - **Delphi / C++Builder** (markers `Embarcadero`, `Borland`, `FastMM`, `TObject`): register calling convention (`fastcall`: EAX, EDX, ECX), string compares via `System::__linkproc__ LStrCmp`/`UStrCmp`, event handlers wired through the VMT/RTTI. Look at RTTI to name forms and methods.
   - **VB6** (`MSVBVM60`): p-code or native; string work goes through `MSVBVM60.dll` ordinals (`__vbaStrCmp`, `__vbaStrComp`).
2. **Locate input entry**: `main`/`WinMain`, `argv`, `scanf`/`fgets`/`ReadFile`/`GetWindowTextA`. For GUI, find the button/key handler (see `dynamic-wine`).
3. **Find the check**: what the input is compared with (`strcmp`/`memcmp`), transformed by (loops, xor, arithmetic), or passed to. Pull the constants out of the binary; do not guess.
4. **Decide read vs run**: a short local check — read and invert it. A long or data-driven one — run or emulate it (`dynamic-wine`, `solvers`).

## Tools and commands

- `diec <file>` — compiler/packer/protector (triage usually has this already).
- `strings -n 6 <f>` and `strings -el <f>` — ASCII and UTF-16 strings; grep for `correct|wrong|valid|flag|serial`.
- `nm -C <f>`, `readelf -a <f>`, `objdump -d -M intel <f>` — symbols, headers, disassembly (ELF).
- `rabin2 -I/-z/-i <f>`, `r2 -A -q -c 'afl; pdf @ sym.main' <f>` — radare2 info, strings, imports, auto-analysis.
- Ghidra decompiler via the `ghidra-headless` skill is the fastest way to readable C; if the `ghidra` module is installed, `agent/prefetch/decompiled.c` is already waiting.
- Go: `r2`'s `aa` recovers `gopclntab` names; or `strings | grep 'go build'` for the version.
- `floss <f>` — recovers stack/obfuscated strings MSVC often hides.

## Pitfalls

- Stripped ≠ no symbols: Go keeps `gopclntab`, Delphi keeps RTTI, C++ keeps mangled names and vtables.
- Delphi's `fastcall` means the first args are in registers, not on the stack — the decompiler's stack-arg guess is often wrong; check the disassembly.
- `strcmp` with a literal is the easy case; a byte-by-byte loop with a transform is the common real case — read the loop.
- Reading the whole program. Find the one comparison that gates success and work backwards from it.

## Verification

- Extract the expected value or invert the transform, then confirm on the real target (run it with the candidate) before `easyre check '<answer>'`.
