---
name: re-methodology
description: The default approach for any reverse engineering task. Read this first on every job before choosing tools. Covers how to orient, find the check, extract what you need, solve, and verify.
---

# re-methodology

## When to use

At the start of every task, before choosing tools. This is the overall plan. The file-type skills (native-binaries, dotnet, python-targets, ...) cover the details once you know what you are dealing with.

## Steps

1. **Orient.** Read `TASK.md`: its wording and title often point at the intended path. Read `triage.md`: it already lists the file type and, if DIE is installed, the compiler, packer and protections. Do not re-run tools to learn what is already there.
2. **Pick the category**: native PE/ELF, .NET, Python, Java/Android, JavaScript, custom VM, or a non-code file. Load the matching skill.
3. **Packed or obfuscated?** Unpack a copy first. If the answer is built at runtime, plan to run or emulate that part instead of reading all of it.
4. **Find the check.** Where does the input enter (argv, stdin, a text field, a key handler)? What is it compared with, transformed by, or passed to?
5. **Extract, do not guess.** Pull the real constants, tables and keys out of the file.
6. **Solve with the cheapest method**: invert the check in Python, use a solver (z3, angr), or run/emulate the target (wine, unicorn).

## Tools and commands

- `diec <file>`: identify compiler, packer and protections, if `triage.md` did not already show it.
- `strings -n 4 <file>` and `strings -el <file>`: ASCII and wide (UTF-16) strings. Look for messages like "correct", "wrong", "valid".
- `toolchain/README.md` lists everything installed in the image.

## Pitfalls

- Opening five tools at once. Answer one question at a time.
- Trusting the decompiler blindly. When it looks wrong, check the disassembly.
- Modifying `src/`. Patch and unpack only copies in `agent/`.
- Brute force that would take more than a couple of hours means you are on the wrong path.
- Repeating dead ends. Record them in `agent/notes.md`.

## Verification

- Confirm the candidate on the real target when that is cheap, then run `easyre check '<answer>'`.
- Keep `agent/notes.md` current: one line per finding, `hypothesis | evidence | result`.
