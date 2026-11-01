---
name: emulation
description: Run a target (or one function of it) by emulating the CPU and OS instead of executing it, with Qiling (whole program) or unicorn (one function). Load when Wine is the wrong tool - a protector detects the Wine/debugger environment and refuses to run, or you want to run just the check in isolation. Qiling needs the emu module; unicorn is in core.
---

# emulation

## When to use

Running the real program is the right idea but Wine is the wrong vehicle:

- the target is packed/virtualized and **detects Wine or a debugger** and bails (`dynamic-wine` gets you nothing);
- you want to run **one function** - the transform, a VM handler, a hash - with your own inputs, without the rest of the program or an OS;
- you need tight control: snapshot state, brute-force one stage, log every executed instruction.

Emulation has no real process and no debugger, so most anti-debug/anti-VM checks have nothing to trip on.

## Steps

1. **Pick the grain.** One self-contained function -> `unicorn` (in `core`): map the code, set registers/stack, write the input, run the address range, read the result. The whole program with OS behaviour -> `qiling` (the `emu` module).
2. **For Qiling, get the rootfs right.** `QILING_ROOTFS=/opt/easyre/qiling-rootfs`. ELF targets run as-is. **Windows PE needs Windows system DLLs** in `x8664_windows`/`x86_windows` (not redistributable; supply them via Qiling's `dllscollector.bat` on a Windows box). Without them, API-heavy PE targets will stop on a missing DLL - then fall back to emulating just the check with unicorn.
3. **Run to the interesting point**, hook the comparison or read the transformed buffer out of emulated memory.
4. **Confirm** the recovered input on the real target when it will run, else argue correctness from the emulated run.

## Tools and commands

Qiling (the `emu` module), quickest via `qltool`:

```sh
qltool run -f /work/src/app --rootfs "$QILING_ROOTFS/x8664_linux"            # ELF
qltool run -f /work/src/app.exe --rootfs "$QILING_ROOTFS/x8664_windows"      # PE (needs DLLs)
```

Scripted, to hook the check or seed an input:

```python
from qiling import Qiling
ql = Qiling(["/work/src/app"], "/opt/easyre/qiling-rootfs/x8664_linux", verbose=0)
def on_cmp(ql):      # hook the success branch / read a buffer
    print(hex(ql.arch.regs.arch_pc))
ql.hook_address(on_cmp, 0x401337)
ql.run()
```

unicorn (in `core`) for a single function: see `solvers` and `custom-vm` - map code, set up the stack, write the input, `emu_start(begin, end)`, read the result.

## Pitfalls

- **Windows rootfs/DLLs** is the usual wall for PE targets; if a DLL is missing, emulate the isolated check with unicorn instead of fighting the rootfs.
- Unimplemented syscalls/APIs: Qiling covers many but not all - hook the missing one with a Python stub that returns what the program expects.
- Emulation is slower than native; emulate the slice you need, not a long GUI/network path.
- An emulator is only as right as its environment; verify a recovered answer on the real target when it can run.

## Verification

- Feed the emulator's answer to the real target (`dynamic-wine`) if it runs, then `easyre check '<answer>'`. If it will not run at all, show the emulated success path in the report.
