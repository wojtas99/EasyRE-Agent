---
name: solvers
description: Recover input with constraint solving (z3), symbolic execution (angr), or emulation (unicorn) instead of inverting a check by hand. Load when the check is invertible-but-messy, or path-dependent. z3/unicorn are in core; angr needs its module.
---

# solvers

## When to use

You understand *what* the check does but inverting it by hand is error-prone or the constraints interact. Pick the lightest tool that fits:

- **z3** — the input must satisfy a set of equations/constraints (checksums, per-char arithmetic, bit tricks). You transcribe the logic; z3 finds the input.
- **angr** — you don't want to transcribe anything: let symbolic execution find a path to the "success" address and tell you the input that reaches it. Best for self-contained checks with a clear good/bad branch.
- **unicorn** — you want to *run* one function (the transform/the VM handler) in isolation with your own inputs, without the rest of the program or an OS. Great for confirming a reimplementation or brute-forcing one stage.

## Steps

1. Identify the win condition precisely: the target address/branch that means "accepted", or the exact constraints on the input bytes.
2. Model only that. Keep the input symbolic, constants concrete.
3. Run the solver, get a candidate, then confirm on the real binary.

## Tools and commands

z3 (in `core`):

```python
from z3 import *
s = Solver(); b = [BitVec(f'b{i}', 8) for i in range(16)]
for x in b: s.add(x >= 0x20, x <= 0x7e)           # printable
# transcribe the check, e.g.:  s.add((b[0] ^ 0x42) + b[1] == 0x9c)
print(s.check(), bytes(s.model()[x].as_long() for x in b) if s.check()==sat else '')
```

angr (needs the `angr` module: `/opt/easyre/toolchain/modules/angr.sh`):

```python
import angr, claripy
p = angr.Project('/work/src/app', auto_load_libs=False)
sm = p.factory.simulation_manager(p.factory.full_init_state(stdin=angr.SimFile))
sm.explore(find=0x401337, avoid=0x401300)         # addresses of success / failure
print(sm.found[0].posix.dumps(0))                 # the stdin that reaches 'find'
```

unicorn (in `core`): map the code, set registers/stack, write the input into memory, run the function's range, read the result out. Use it to brute-force one byte/stage at a time against the real handler.

## Pitfalls

- angr state explosion: constrain `stdin` length, use `auto_load_libs=False`, and prefer `find`/`avoid` addresses over running to completion. If it hangs, fall back to z3 with the logic you can read.
- z3 is only as right as your transcription — re-read the decompiled check and mirror it exactly, including integer widths and overflow (use `BitVec`, not `Int`).
- A solver answer is a hypothesis until the real target accepts it.
- Don't reach for angr when a 5-line z3 model or a direct inversion would do.

## Verification

- Run the candidate against the real target (`dynamic-wine` for `.exe`), then `easyre check '<answer>'`.
