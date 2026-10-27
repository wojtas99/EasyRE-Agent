---
name: wasm
description: WebAssembly modules (.wasm files, or wasm embedded in JS/HTML). Map imports and exports, decompile with wabt, find the check, and call exports directly from Node. Load when triage flags WebAssembly or JS code instantiates a wasm module. Requires the wasm toolchain module.
---

# wasm

## When to use

Triage shows `WebAssembly [wasm]`, the handout contains a `.wasm`, or JS calls `WebAssembly.instantiate`/`instantiateStreaming`. Wasm embedded in JS or HTML is usually a base64 string starting with `AGFzbQ` (the `\0asm` magic). Requires the `wasm` module; install with `sh /opt/easyre/toolchain/modules/wasm.sh` if `wasm2wat` is missing. Node is always in the base image.

## Steps

1. **Get the module out.** Use the `.wasm` file directly, or decode the base64 blob from the JS into `/work/agent/mod.wasm`.
2. **Map the interface.** `wasm-objdump -x` lists imports (what the host must provide), exports (the callable entry points: look for `check`, `verify`, `validate`, `main`, `_start`), data segments with their memory offsets, and the `name` section if it was not stripped.
3. **Identify the producer**, because it decides what is runtime noise:
   - Emscripten: a JS glue file with `Module`, `ccall`/`cwrap`, an exported `malloc`; imports often minified to names like `a.b`.
   - Rust `wasm-bindgen`: `__wbindgen_*` imports/exports, a `*_bg.wasm` next to generated JS.
   - Go: imports from `go`/`gojs` and a large runtime; the logic is in `main.main`. TinyGo output is much smaller.
   - Plain clang / AssemblyScript / hand-written: small and readable.
4. **Read the check** from the export the JS calls with the user input: `wasm-decompile` for C-like pseudo-code, `wasm2wat` for the exact instructions.
5. **Run it.** Instantiate the module in Node with stub imports and call the export with a candidate. Often faster than reading: dump memory after the transform, or brute-force one byte at a time.

## Tools and commands

```sh
python3 -c "import base64,sys; open('/work/agent/mod.wasm','wb').write(base64.b64decode(sys.argv[1]))" 'AGFzbQ...'
wasm-objdump -x /work/src/mod.wasm > /work/agent/mod.x.txt     # sections, imports, exports, data, names
wasm-objdump -d /work/src/mod.wasm > /work/agent/mod.dis       # disassembly with offsets
wasm-decompile /work/src/mod.wasm -o /work/agent/mod.dcmp      # C-like pseudo-code
wasm2wat /work/src/mod.wasm -o /work/agent/mod.wat             # exact text form
strings -n 5 /work/src/mod.wasm                                # data-segment strings
```

Call an export from Node. Replace `check` with the real export and match its signature; `WebAssembly.Module.imports` shows what must be stubbed:

```js
const fs = require('fs');
const mod = new WebAssembly.Module(fs.readFileSync('/work/src/mod.wasm'));
console.log(WebAssembly.Module.imports(mod), WebAssembly.Module.exports(mod));
const imports = {};
for (const i of WebAssembly.Module.imports(mod)) {
  if (i.kind === 'function') {
    (imports[i.module] ??= {})[i.name] = (...a) => { console.log('import', i.module, i.name, a); return 0; };
  }
}
const e = new WebAssembly.Instance(mod, imports).exports;
const s = Buffer.from(process.argv[2] || 'guess');
const p = e.malloc ? e.malloc(s.length + 1) : e.memory.buffer.byteLength - 4096;
const mem = new Uint8Array(e.memory.buffer);
mem.set(s, p);
mem[p + s.length] = 0;
console.log(e.check(p, s.length));
```

Save it as `/work/agent/run.js` and run `node /work/agent/run.js 'candidate'`. If the imports include a `memory`, `table` or `global`, create it (`new WebAssembly.Memory({ initial: N })` with the declared minimum) under the same module/name and use it instead of `e.memory`.

WASI modules (`wasi_snapshot_preview1` imports, `_start` export) run as programs:

```js
const fs = require('fs');
const { WASI } = require('node:wasi');
const wasi = new WASI({ version: 'preview1', args: ['app', process.argv[2] || 'guess'] });
const mod = new WebAssembly.Module(fs.readFileSync('/work/src/app.wasm'));
wasi.start(new WebAssembly.Instance(mod, wasi.getImportObject()));
```

`wasm-interp --wasi app.wasm` is an alternative, and `wasm-interp mod.wasm --run-all-exports --trace` traces a small module without imports. To patch: `wasm2wat`, edit the `.wat`, `wat2wasm mod.wat -o patched.wasm`.

## Pitfalls

- Strings are pointers: an `i32.const 1048` passed to a compare is an address in linear memory. Map it through the data segments in `wasm-objdump -x` (each lists its start offset): the bytes are at `address - segment_start` inside that segment.
- `wasm-decompile` output is pseudo-code, not C. Confirm odd loads, stores and casts in the `.wat` before trusting them in a solver.
- `i64` values cross into JS as `BigInt`: pass `5n`, not `5`.
- Memory can grow during a call (`malloc`), which detaches old `Uint8Array` views. Re-create the view after any call that may allocate.
- Emscripten, Rust and Go modules are mostly runtime. If the `name` section exists, grep function names first; otherwise follow the export the JS calls.
- Browser glue expects `window`, `document` or `fetch`. Under Node, stub those or skip the glue and instantiate the module directly as above.
- wabt errors on newer features (GC, exceptions, tail calls): add `--enable-all`.

## Verification

- Call the export (or run the WASI program) with the candidate and confirm the success result, then `easyre check '<answer>'`.
