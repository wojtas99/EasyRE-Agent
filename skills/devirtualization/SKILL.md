---
name: devirtualization
description: Crackmes whose check is protected by a commercial code virtualizer (VMProtect, Themida/WinLicense, or a heavy custom VM). Recover the semantics of the virtualized check - by tracing the handlers on a concrete run and lifting the input transform - then solve it. Load when triage/DIE tags a virtualizing protector, or custom-vm meets an industrial-strength VM.
---

# devirtualization

## When to use

Triage/DIE tags `VMProtect`, `Themida` or `WinLicense`, or you have unpacked the target (see `unpacking`) and the check is not native code but a dispatch loop over bytecode that is far bigger and more obfuscated than a hand-rolled VM. This is `custom-vm` turned up to industrial strength: many handlers, duplicated/polymorphic handlers, obfuscated handler bodies, sometimes nested VMs. The goal is unchanged - recover what the check does to the input and invert it - you do not need to rebuild the original compiler output.

Virtualizers are common in modern crackmes, so this is a first-class path, not a last resort. Read `custom-vm` and `solvers` first; this skill is the heavy-VM version of both.

## Steps

1. **Unpack the outer layer** (`unpacking`): the protector packs/encrypts, then virtualizes. Dump at the OEP so the native parts, the VM dispatcher and the handler table are readable.
2. **Scope the virtualization.** Authors almost never virtualize the whole program - usually just the serial/flag check or one transform. Everything else is normal native code you read directly (`native-binaries`). Find the boundary: where input enters the VM and where the verdict comes back out.
3. **Locate the VM pieces** (same inventory as `custom-vm`): the VM entry stub (pushes the native context, jumps into the interpreter), the dispatcher loop, the handler table, the virtual registers / VM stack, the bytecode pointer, and where your input bytes are read in.
4. **Prefer trace-based lifting over static reading.** Reading every obfuscated handler statically is slow and anti-debug fights you. Instead run the check once on a known input and record the *executed* handler stream and its effects - that linear trace is the actual program for that input:
   - Emulate the check in `unicorn`: map the unpacked image, set up the stack/context, write your input in, run from the VM entry, and log every dispatch (the handler address and the VM registers/memory it reads and writes). Emulation side-steps the protector's debugger detection.
   - Or trace under the debugger / `WINEDEBUG=+relay` (`dynamic-wine`) when emulation is hard to set up.
5. **Cluster and name the handlers by semantics, not address.** Polymorphism and duplication mean the same operation appears at many addresses; group handlers by what they do to the VM state (`push imm`, `add`, `xor`, `load input[i]`, `cmp`). Read a representative of each cluster in Ghidra, or infer it from the trace's before/after state. This semantic map is the whole job, exactly as in `custom-vm`.
6. **Lift the trace to a model.** Replay the handler trace to emit readable pseudo-ops, or build the symbolic transform the VM applies to the input directly in Python. Keep the input symbolic, constants concrete.
7. **Solve.** Hand the lifted transform to `z3` (per-byte or interacting constraints), or let `angr` find the path to the accept branch when you can isolate the virtualized function. Invert directly when the transform is simple once lifted.
8. **Verify** the candidate on the real target before `easyre check`.

## Tools and commands

All installed: `ghidra-headless` (handler bodies, dispatcher), `unicorn` (concrete + instrumented emulation of the VM), `z3`/`angr` (`solvers`), `capstone`, gdb and `WINEDEBUG=+relay` (`dynamic-wine`).

Trace-based handler logging with unicorn (sketch - adapt the context setup to the target):

```python
from unicorn import *
from unicorn.x86_const import *
mu = Uc(UC_ARCH_X86, UC_MODE_64)
# map the unpacked image + a stack, write input bytes into the buffer the VM reads,
# then hook each instruction to log dispatches into the handler table:
seen = {}
def hook(uc, addr, size, _):
    if addr in HANDLERS:                     # addresses from the handler table
        seen.setdefault(addr, 0); seen[addr] += 1
        # record VM regs/stack here to recover this handler's effect
mu.hook_add(UC_HOOK_CODE, hook)
mu.emu_start(VM_ENTRY, VM_END)
```

Specialised devirtualizers for VMProtect/Themida exist as community/research projects. You are root with network, so you may fetch and try one (`git clone` / `pip install`), but check it matches the protector *version* - they are brittle and version-bound, and a wrong-version tool wastes time. The trace-and-lift method above uses only installed tools and always works, so treat an external devirtualizer as an accelerator, not a dependency, and fall back to tracing when it does not fit.

Split the work with lanes (`AGENT.md`) when stuck: e.g. one lane emulates+lifts in unicorn, one drives `angr` on the isolated function, one reads the handlers statically in Ghidra.

## Pitfalls

- **Do not devirtualize more than you must.** Only the handlers that touch the input matter; ignore the rest of the VM program.
- **Handler duplication/polymorphism**: cluster by semantics or you will "discover" hundreds of handlers that are a dozen operations.
- **Anti-debug and anti-tamper**: prefer emulation (`unicorn`) or Wine tracing to attaching a debugger; the protector may detect gdb and change behaviour or exit.
- **Nested / multiple VMs**: a handler may itself enter another VM. Lift the inner one first.
- **angr state explosion** is worse here than anywhere - constrain input length, isolate the virtualized function, prefer trace-based `z3` over whole-program symbolic execution.
- **Budget**: a virtualized check is expensive. Use lanes and trace-based lifting to make progress; if after a genuine effort it still will not yield, write `/work/HELP.md` (protector name and version, what is virtualized, the handler map and trace you recovered, where you are stuck) so a human continues from your work rather than from zero.

## Verification

- Confirm the lifted model reproduces the real VM on a known input (same verdict/intermediate values) before trusting it, then run your solved candidate against the real target (`dynamic-wine`) and `easyre check '<answer>'`.
