---
name: dotnet
description: .NET / Mono managed assemblies and Unity games (Mono or IL2CPP). Decompile to C#, handle obfuscation, recover IL2CPP metadata, and extract single-file bundles. Load when triage flags a .NET assembly or Unity. Requires the dotnet toolchain module.
---

# dotnet

## When to use

Triage shows `.NET assembly` (`mscoree.dll`), a Unity game (`UnityPlayer`), or IL2CPP (`global-metadata.dat`). Requires the `dotnet` module; install with `sh /opt/easyre/toolchain/modules/dotnet.sh` if the tools are missing.

## Steps

1. **Managed .NET / Mono** (there is a `.dll`/`.exe` with CIL, or Unity with `Managed/Assembly-CSharp.dll`):
   - Decompile straight to C# with `ilspycmd`. Read the check in `Assembly-CSharp.dll` for Unity, or the main assembly otherwise.
   - If decompilation is garbage (renamed to `a.b.c`, control-flow mangled), it is obfuscated — deobfuscate first (`de4dot`), then decompile again.
2. **Unity IL2CPP** (no managed DLLs, there is `GameAssembly.dll`/`libil2cpp.so` + `global-metadata.dat`): the C# was compiled to native. Recover symbol names with `il2cppdumper`, then read the native code (`ghidra-headless`) using the recovered names.
3. **Single-file host** (one big `.exe`, triage shows `.NET single-file bundle` and/or a large `overlay`): the managed DLLs are bundled in the overlay and `ilspycmd` cannot open the host directly. Extract first: `dotnet-bundle /work/src/App.exe -o /work/agent/bundle` (add `--all` for the framework too), then decompile the DLLs from there. If triage shows an unusual host `PDB:` path (a custom-built runtime, not a stock framework), the host itself may be modified - analyse it natively too (`native-binaries`, `ghidra-headless`), because the managed code may only be a decoy.
4. **Find the check** in the recovered C#: usually a `bool`-returning method comparing the input to a field, a constant, or a hash. Managed strings are in cleartext in the metadata — grep them.

## Tools and commands

```sh
ilspycmd /work/src/App.dll -o /work/agent/cs            # decompile assembly to C#
ilspycmd -l c /work/src/App.dll                          # list types
de4dot /work/src/App.dll -o /work/agent/clean.dll        # deobfuscate, then re-decompile
il2cppdumper GameAssembly.dll global-metadata.dat /work/agent/il2cpp   # dump.cs + headers
dotnet /work/src/App.dll                                 # run it (self-contained managed apps)
```

Strings from managed metadata:

```sh
strings -el App.dll | grep -iE 'flag|serial|correct|key'   # UTF-16 user strings
```

## Pitfalls

- Don't reach for a native disassembler on a managed DLL — decompile the CIL instead; it reads like source.
- IL2CPP native code is meaningless without `il2cppdumper` first; the dump maps addresses to the original method names.
- Obfuscators (ConfuserEx, etc.) may also encrypt strings and resources at runtime — sometimes running under a debugger and dumping is faster than static deobfuscation.
- Unity logic can live in `Assembly-CSharp.dll`, not the launcher `.exe`.
- A single-file host bundles everything; a clean-looking managed assembly inside it is not proof the logic is managed - a custom-built host (odd `PDB:` path) can carry native modifications.

## Verification

- Reimplement the check in C# or Python from the decompiled logic, or run the app with the candidate, then `easyre check '<answer>'`.
