#!/bin/sh
# angr - binary symbolic-execution engine (pulls in a large dependency tree:
# claripy, pyvex, z3, unicorn). Opt-in because of its size. See the solvers
# skill.
set -e

apt-get update
apt-get install -y --no-install-recommends build-essential python3-dev

# PIP_BREAK_SYSTEM_PACKAGES=1 is set in the image env.
pip install --no-cache-dir angr

python3 - <<'PY' || echo "[ ] angr import failed"
import angr, claripy
print("[x] angr", angr.__version__)
PY
