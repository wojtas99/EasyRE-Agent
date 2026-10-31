---
name: unpacking
description: Packed or protected executables - recognise the packer, unpack a copy, and when there is no static unpacker, run to the original entry point (OEP) under Wine and dump the unpacked image out of memory with dump-mem. Load when triage/DIE says packed/protected or the on-disk file has tiny code and huge high-entropy data.
---

# unpacking

## When to use

Triage or `diec` reports a packer/protector (UPX, or a named/unknown one), or the file itself gives it away: very few real functions, one or two sections with high entropy, imports reduced to `LoadLibrary`/`GetProcAddress`, a tiny `.text` next to a big `.data`/overlay. Reading the on-disk bytes shows only the packer stub; the real program appears only once it has unpacked itself in memory.

Do this *before* the file-type skill: unpack a copy into `agent/`, then analyse the copy with `native-binaries` / `dotnet` / etc.

## Steps

1. **Identify the packer** from `triage.md`/`diec`. Three cases:
   - **UPX** (by far the most common): unpack statically, no running needed (see below).
   - **A known packer with a tool** (e.g. some .NET protectors - use `de4dot` via the `dotnet` skill).
   - **A simple or custom packer** with no static unpacker: unpack dynamically by dumping from memory at the OEP.
2. **Try the cheap static path first.** `upx -d` handles UPX and some clones outright. If it works, you are done - analyse the unpacked copy.
3. **If there is no static unpacker, dump from memory.** The idea: the stub decrypts the real code into memory and jumps to the original entry point (OEP). Run the target under Wine (`dynamic-wine`), stop it at the OEP, and read the unpacked image back out of the process with `dump-mem`.
4. **Find the OEP.** It is the point where the stub hands control to the real program. Practical ways to catch it:
   - A packer stub often ends with a far `jmp`/`ret` into a *different* section than the one it runs in - break there.
   - For many UPX-style stubs the classic tell is a `pushad` near the entry and the OEP right after the matching `popad`; break after the `popad`.
   - Or let the stub run and break on the first execution inside the section it just wrote to.
   Use gdb on the Wine process (`dynamic-wine`): set a breakpoint, let the stub run, and read `$pc` when it stops - that address, minus the image base, is the OEP RVA.
5. **Dump and fix up.** With the process stopped at the OEP, run `dump-mem` with `--oep`; it rebuilds a PE whose section layout matches memory (raw offset = virtual address) so static tools can read it.
6. **Analyse the dump** with the matching file-type skill. The logic, strings and constants are now all readable.

## Tools and commands

UPX (static, in `core`):

```sh
upx -d -o /work/agent/unpacked.exe /work/src/packed.exe   # also try without -d then -t to test
```

Dynamic dump at OEP (Wine + gdb + `dump-mem`, all present in the image):

```sh
# 1. start it under Wine, paused, and attach gdb (see the dynamic-wine skill)
wine /work/src/packed.exe & sleep 2
pid=$(pgrep -f packed.exe | tail -1)
gdb -p "$pid"
#    (in gdb) set a breakpoint at the suspected OEP, continue, confirm $pc, leave it stopped

# 2. in another shell, dump the unpacked image out of the stopped process
dump-mem "$pid" --oep 0x00401abc -o /work/agent/unpacked.exe
#    --base 0x400000 if auto-detection picks the wrong module
#    --stop     to SIGSTOP the process yourself if it is NOT held by gdb

# 3. read the dump
diec /work/agent/unpacked.exe
strings -n 6 /work/agent/unpacked.exe | grep -iE 'correct|wrong|flag|serial'
```

`dump-mem --help` documents every flag. It reads `/proc/<pid>/mem` (the container has `SYS_PTRACE`), reconstructs the section table, and optionally sets the entry point to the OEP you pass.

## Pitfalls

- **Dump while the process is stopped**, not running free, or sections tear mid-read. A gdb breakpoint holds it; otherwise `--stop`.
- **Dump at the OEP, not before.** Dump too early and the code is still encrypted; the point of stopping at the OEP is that unpacking has finished.
- **The IAT is not rebuilt.** The raw dump reads perfectly in Ghidra/objdump/strings (which is all you need to find the check), but it will usually not *run* until the import table is reconstructed - do not waste time trying to execute it; read it instead.
- **Auto-detected base can be wrong** if several PE modules are mapped. Pass `--module packed.exe` or `--base` from `info proc mappings` in gdb.
- **Self-checking/anti-debug packers** may detect gdb or refuse to run headless. If so, confirm the OEP with a `WINEDEBUG=+relay` trace or static reading of the stub instead, and dump on a plain `kill -STOP`.
- Do not over-reach: if `upx -d` already gave you a clean file, there is nothing to dump.

## Verification

- `diec` on the dump should now report the real compiler (MinGW/MSVC/...) instead of the packer, and `strings`/the decompiler should show the program's real text. Analyse the dump, recover the answer, confirm it on the *original* target (`dynamic-wine`), then `easyre check '<answer>'`.
