#!/bin/sh
# angr - binary symbolic-execution engine (pulls in a large dependency tree:
# claripy, pyvex, z3, unicorn). See the solvers skill.
#
# Pinned below 10: angr 10 moved claripy inside angr (angr.rustylib.claripy),
# which breaks the long-documented `import claripy` and the scripts built on it.
# angr 9.x keeps the API that the solvers skill and most write-ups use.
# bitstring is capped too: bitstring 5 dropped ConstBitStream, which pyvex 9.x
# still imports (angr 10's pyvex caps it itself).
set -e

apt-get update
apt-get install -y --no-install-recommends build-essential python3-dev

# PIP_BREAK_SYSTEM_PACKAGES=1 is set in the image env.
pip install --no-cache-dir "angr<10" "bitstring<5"

python3 - <<'PY' || echo "[ ] angr import failed"
import angr
try:
    import claripy
except ImportError:
    from angr.rustylib import claripy
claripy.BVS("x", 8)
print("[x] angr", angr.__version__)
PY
