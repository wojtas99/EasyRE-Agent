#!/bin/sh
# wasm - WebAssembly targets: wabt (wasm-objdump, wasm2wat, wasm-decompile,
# wasm-interp, wasm2c, wat2wasm). Node from the base image instantiates modules
# and calls their exports directly. See the wasm skill.
set -e

apt-get update
apt-get install -y --no-install-recommends wabt

echo "wasm tools:"
for t in wasm-objdump wasm2wat wasm-decompile wasm-interp wasm2c wat2wasm node; do
  command -v "$t" >/dev/null 2>&1 && printf '  [x] %s\n' "$t" || printf '  [ ] %s\n' "$t"
done
