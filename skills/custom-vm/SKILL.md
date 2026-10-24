---
name: custom-vm
description: Targets that validate input with a custom virtual machine or bytecode interpreter - recover the handler table, disassemble the bytecode, lift it, then solve. Load when the check runs a dispatch loop over embedded bytecode.
---

# custom-vm

## When to use

The check isn't native logic but an interpreter: a central dispatch loop (big `switch`, or `jmp [table + opcode*n]`) walking an array of bytes/opcodes. Signs: a fetch-decode-execute loop, a "program counter" variable, an opcode handler table, and a blob of bytecode in `.data`/`.rodata`.

## Steps

1. **Confirm the VM and find its pieces**:
   - the dispatch loop and how it fetches the next opcode;
   - the handler table (map opcode → handler address);
   - the VM state: registers/stack array, the PC, and where the input is loaded in;
   - the bytecode blob and where it starts.
2. **Map the handlers.** Read each handler and write down its semantics: `0x01: push imm`, `0x02: xor top two`, `0x07: cmp with input[i]`, etc. This map is the whole job.
3. **Disassemble the bytecode** with a small script that walks the blob using your opcode map, printing one instruction per line. Now you can read the "program".
4. **Understand the check** from the disassembly: it almost always transforms the input and compares against constants.
5. **Solve**: for a simple per-byte check, invert it directly; for anything with interacting constraints, model the handlers' effects in `z3` (see `solvers`) or emulate the VM in Python with the input symbolic/bruteforced per byte.

## Tools and commands

- Static: `ghidra-headless` for the dispatch loop and handlers (the decompiled `switch` makes the opcode map readable); `objdump -d`/`r2` for the jump-table form.
- Dump the bytecode blob: `xxd -s <off> -l <len> file`, or in Ghidra `getBytes(toAddr(...), n)`.
- Write the disassembler and the solver/emulator as Python in `/work/agent/`. `z3-solver`, `capstone` (if a handler itself is native), and `unicorn` (to emulate the real handler code instead of reimplementing it) are installed.

## Pitfalls

- Reimplementing a handler wrong silently breaks everything downstream — verify your emulator against the real binary on a known input (`dynamic-wine`) before trusting it.
- Some VMs are obfuscation over a trivial check; once the disassembly is readable the logic is often a plain compare — don't over-engineer a solver.
- Opcode operands vary in width; get the decode loop's stride exactly right or the whole disassembly shifts.
- Watch for a self-modifying or key-seeded bytecode stream (decoded at runtime) — dump it *after* the decode, from memory.

## Verification

- Feed your solver's answer to the real target and confirm it is accepted, then `easyre check '<answer>'`.
