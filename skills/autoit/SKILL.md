---
name: autoit
description: Compiled AutoIt scripts (an .exe with an embedded AU3!EA05/EA06 script, or a bare .a3x). Extract and decompile the script to .au3 source, then read it or run an edited copy. Load when triage flags an AutoIt script. Requires the autoit toolchain module.
---

# autoit

## When to use

Triage shows `AutoIt script [script-bundle]` (the `AU3!EA06` or `AU3!EA05` marker), or DIE reports AutoIt. The `.exe` is the stock AutoIt interpreter with the target script embedded as a resource: the logic lives in the script, not in the native code. Requires the `autoit` module; install with `sh /opt/easyre/toolchain/modules/autoit.sh` if `autoit-ripper` is missing.

## Steps

1. **Unpack first if needed.** Aut2Exe can UPX-compress its output; the marker is then hidden and triage shows only `UPX`. Unpack a copy (`upx -d`) and work on that.
2. **Extract the script** with `autoit-ripper`. EA06 scripts (AutoIt v3.2.6+) are tokenized and the tool rebuilds `.au3` source; EA05 scripts (older v3) are stored as source. Files embedded with `FileInstall` come out next to the script: check them too.
3. **Find the user code.** `#include`d standard UDFs are inlined, so the script can be thousands of lines. Grep for the success/failure text and the input path: `InputBox`, `GUICtrlRead`, `GUIGetMsg` loops, `MsgBox`, `$CmdLine`.
4. **Read the check.** Typical shapes: a direct compare (`If $in == "..." Then`), a hash (`_Crypt_HashData`), or a custom transform built from `StringMid`/`Asc`/`Chr`/`BitXOR` loops. Obfuscated scripts route strings through a decoder function: evaluate it instead of reading it.
5. **Solve**: reimplement the transform in Python, or run an edited copy of the script that prints the intermediate values.

## Tools and commands

```sh
upx -d -o /work/agent/unpacked.exe /work/src/app.exe        # only if UPX-packed
autoit-ripper /work/src/app.exe /work/agent/au3              # --ea EA05|EA06 forces the version
ls -la /work/agent/au3                                        # script + FileInstall payloads
grep -niE 'MsgBox|InputBox|GUICtrlRead|\$CmdLine|==|BitXOR|_Crypt_|StringReverse' /work/agent/au3/*.au3
```

Run an edited copy to dump values. `autoit3` is the AutoIt interpreter under Wine; GUI scripts need a virtual display. Writing to a file is the most reliable output channel:

```sh
cp /work/agent/au3/<script>.au3 /work/agent/dbg.au3
# add lines such as:  FileWrite(@ScriptDir & "\dbg.txt", $decoded & @CRLF)
cd /work/agent && xvfb-run -a autoit3 /ErrorStdOut dbg.au3; cat dbg.txt
```

## Pitfalls

- AutoIt `=` compares strings **case-insensitively**; only `==` is case-sensitive. A check written with `=` accepts any casing, so submit the exact form the task asks for.
- `StringMid`, `StringInStr` and `StringLeft`/`StringRight` positions are 1-based, and `StringSplit` puts the element count in `[0]`. Off-by-one errors are the usual reimplementation bug.
- EA06 scripts are UTF-16: `AscW`/`ChrW` and `Asc`/`Chr` differ above 0x7F.
- Do not reverse the interpreter in Ghidra; it is the stock AutoIt runtime and the prefetch hook skips it on purpose.
- If `autoit-ripper` finds nothing: the file is still packed, it is another script compiler (AutoHotkey, AutoIt v2), or the script resource was tampered with. Check `diec` and `strings -el` before treating it as plain native code.
- A bare `.a3x` is a compiled script without the interpreter; `autoit3 file.a3x` runs it.
- Paths given to `autoit3` are Windows paths under Wine. Relative paths from the script's own directory are safest.

## Verification

- Run the original target with the candidate (`dynamic-wine`), or the recovered check in `autoit3`, and confirm the success path, then `easyre check '<answer>'`.
