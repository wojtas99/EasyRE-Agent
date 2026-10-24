// EasyRE prefetch post-script: dumps functions, strings, imports, then the
// decompilation of every non-thunk function, and finally a DONE marker.
// Java on purpose: runs on stock Ghidra (Jython is only an optional extension
// since Ghidra 12, and PyGhidra needs a different launcher).
// Usage: -postScript PrefetchDump.java <output_dir> [decompile_timeout_s]
// @category EasyRE
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.List;

import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.data.StringDataInstance;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Namespace;
import ghidra.program.model.symbol.Symbol;
import ghidra.program.util.DefinedStringIterator;

public class PrefetchDump extends GhidraScript {

	private PrintWriter open(File dir, String name) throws IOException {
		return new PrintWriter(new BufferedWriter(new OutputStreamWriter(
			new FileOutputStream(new File(dir, name)), StandardCharsets.UTF_8)));
	}

	@Override
	protected void run() throws Exception {
		String[] args = getScriptArgs();
		File out = new File(args.length > 0 ? args[0] : "/work/agent/prefetch").getAbsoluteFile();
		int timeout = args.length > 1 ? Integer.parseInt(args[1]) : 30;
		out.mkdirs();
		new File(out, "DONE").delete();

		List<Function> funcs = new ArrayList<>();
		for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
			funcs.add(f);
		}

		try (PrintWriter w = open(out, "functions.txt")) {
			for (Function f : funcs) {
				w.printf("%s  %6d  %s%s%n", f.getEntryPoint(), f.getBody().getNumAddresses(),
					f.getName(true), f.isThunk() ? "  [thunk]" : "");
			}
		}

		try (PrintWriter w = open(out, "strings.txt")) {
			for (Data d : DefinedStringIterator.forProgram(currentProgram)) {
				String s = StringDataInstance.getStringDataInstance(d).getStringValue();
				if (s != null && s.trim().length() >= 3) {
					w.printf("%s  %s%n", d.getAddress(), s.replace("\n", "\\n"));
				}
			}
		}

		try (PrintWriter w = open(out, "imports.txt")) {
			for (Symbol s : currentProgram.getSymbolTable().getExternalSymbols()) {
				Namespace p = s.getParentNamespace();
				w.printf("%s!%s%n", p == null ? "?" : p.getName(), s.getName());
			}
		}

		DecompInterface dec = new DecompInterface();
		dec.openProgram(currentProgram);
		int done = 0;
		try (PrintWriter w = open(out, "decompiled.c")) {
			for (Function f : funcs) {
				if (monitor.isCancelled()) {
					break;
				}
				if (f.isThunk() || f.isExternal()) {
					continue;
				}
				DecompileResults r = dec.decompileFunction(f, timeout, monitor);
				String code = (r != null && r.decompileCompleted())
						? r.getDecompiledFunction().getC()
						: "/* decompile failed: " + (r == null ? "?" : r.getErrorMessage()) + " */\n";
				w.printf("/* === %s @ %s === */%n%s%n", f.getName(true), f.getEntryPoint(), code);
				w.flush();
				done++;
			}
		}
		finally {
			dec.dispose();
		}
		Files.writeString(new File(out, "DONE").toPath(), done + " functions decompiled\n");
		println("PrefetchDump: " + funcs.size() + " functions, " + done + " decompiled -> " + out);
	}
}
