---
name: ghidra-headless
description: Drive Ghidra without the GUI to decompile native binaries in batch. Load when you need decompiled C, a function list, or a custom analysis script on a PE/ELF target. Requires the ghidra toolchain module.
---

# ghidra-headless

## When to use

You want readable decompiled C for a native binary and the lightweight tools (`objdump`, `r2`) are not enough. Requires the `ghidra` module (`which analyzeHeadless`); if it is missing, install it with `/opt/easyre/toolchain/modules/ghidra.sh`.

## Steps

1. **Check for prefetch output first.** If triage started the prefetch hook, the analysis is already running or done in `/work/agent/prefetch/`:
   - `decompiled.c` — every function decompiled;
   - `functions.txt` — address, size, name;
   - `strings.txt`, `imports.txt`.
   `tail -f /work/agent/prefetch/prefetch.log` to see if it is still going. Do not start a second analysis of the same file.
2. **Grep the decompilation** for the lead you got from triage/strings (the success message, the compare function) and read outward from there.
3. **Only if you need more** (a custom pass, a different binary, scripted extraction) run headless yourself with a post-script.

## Tools and commands

Run a one-off analysis and dump with the shipped script:

```sh
prefetch /work/src/target.exe /work/agent/gh
# or directly:
analyzeHeadless /tmp/proj gh -import /work/src/target.exe \
  -scriptPath /opt/easyre/tools/ghidra_scripts \
  -postScript PrefetchDump.java /work/agent/gh -deleteProject
```

Write your own post-script in Java (`.java`, like the shipped `PrefetchDump.java`) and pass it with `-postScript Name.java`. For Python 3, use PyGhidra (`pyghidraRun`), which the `ghidra` module installs — there is no bundled Jython. The GhidraScript API below is the same from either path (Python 3 shown):

```python
# currentProgram is provided. Decompile one function:
from ghidra.app.decompiler import DecompInterface
d = DecompInterface(); d.openProgram(currentProgram)
fn = getFunction("check")                      # or getFunctionContaining(toAddr(0x401000))
print(d.decompileFunction(fn, 60, monitor).getDecompiledFunction().getC())
# Read bytes / defined data:
getBytes(toAddr(0x402000), 16)
getDataAt(toAddr(0x403000)).getValue()
```

Pass arguments to your script with `getScriptArgs()` and reach them after `-postScript Name.py arg1 arg2`.

## Pitfalls

- Two scripting paths: Java post-scripts (`.java`) run on stock headless Ghidra — that is what the shipped `PrefetchDump.java` uses; Python scripts need **PyGhidra** (CPython 3, via `pyghidraRun`), installed by this module. Match the file extension to the path you pick; do not assume a bundled Jython — there is none.
- Headless import of a large binary is slow (minutes). Analyze once, write results to `agent/`, then read files — do not re-run per question.
- The decompiler guesses calling conventions and types; when the C looks nonsensical, drop to the Listing/disassembly for that function.
- Use `-deleteProject` (or a temp project dir) so repeated runs do not collide on a locked project.

## Verification

- Cross-check a surprising decompiled constant against the raw bytes (`getBytes`, or `xxd` on the file at that offset) before trusting it in a solver.
