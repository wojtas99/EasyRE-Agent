# Ghidra post-script for the EasyRE prefetch hook. Jython (Ghidra 2.x API).
# Usage (driven by toolchain/prefetch): -postScript PrefetchDump.py <output_dir>
# Dumps decompilation, a function list, defined strings and imports so the
# agent has a first-pass analysis waiting in agent/prefetch/.
import os

from ghidra.app.decompiler import DecompInterface
from ghidra.util.task import ConsoleTaskMonitor

args = getScriptArgs()
outdir = args[0] if args else "/work/agent/prefetch"
if not os.path.isdir(outdir):
    os.makedirs(outdir)

monitor = ConsoleTaskMonitor()
fm = currentProgram.getFunctionManager()
funcs = sorted(fm.getFunctions(True), key=lambda f: f.getEntryPoint().getOffset())

# functions.txt
with open(os.path.join(outdir, "functions.txt"), "w") as fh:
    for f in funcs:
        body = f.getBody()
        size = body.getNumAddresses() if body is not None else 0
        fh.write("%s  %6d  %s\n" % (f.getEntryPoint(), size, f.getName()))

# decompiled.c
dec = DecompInterface()
dec.openProgram(currentProgram)
with open(os.path.join(outdir, "decompiled.c"), "w") as fh:
    for f in funcs:
        try:
            res = dec.decompileFunction(f, 60, monitor)
            if res is not None and res.decompileCompleted():
                code = res.getDecompiledFunction().getC()
            else:
                code = "/* decompile failed: %s */" % f.getName()
        except Exception as e:
            code = "/* decompile error in %s: %s */" % (f.getName(), e)
        fh.write("/* === %s @ %s === */\n%s\n\n" % (f.getName(), f.getEntryPoint(), code))

# strings.txt
listing = currentProgram.getListing()
with open(os.path.join(outdir, "strings.txt"), "w") as fh:
    for d in listing.getDefinedData(True):
        try:
            dt = d.getDataType().getName().lower()
            if "unicode" in dt or "string" in dt or "char" in dt:
                val = d.getValue()
                if val is not None:
                    s = unicode(val).replace("\n", "\\n")
                    if len(s.strip()) >= 3:
                        fh.write("%s  %s\n" % (d.getAddress(), s))
        except Exception:
            pass

# imports.txt
with open(os.path.join(outdir, "imports.txt"), "w") as fh:
    st = currentProgram.getSymbolTable()
    for sym in st.getExternalSymbols():
        parent = sym.getParentNamespace()
        lib = parent.getName() if parent is not None else "?"
        fh.write("%s!%s\n" % (lib, sym.getName()))

print("PrefetchDump: wrote decompiled.c, functions.txt, strings.txt, imports.txt to %s" % outdir)
