#!/bin/sh
# EasyRE-Agent toolchain installer.
#
# Modules live in toolchain/modules/<name>.sh. EASYRE_TOOLS picks which ones are
# installed: "all" (the default) or a comma-separated subset in .env, e.g.:
#
#   EASYRE_TOOLS=core,die,ghidra
#
# The "wine" module is always installed (the agent needs it to run .exe
# targets and to auto-verify).
#
#   install.sh            install every selected module
#   install.sh <module>   install that module if it is selected, else skip it
#                         (the Dockerfile runs one module per image layer)
#
# Every module is standalone and idempotent, so the agent can also run one
# mid-job, e.g.:  sh /opt/easyre/toolchain/modules/ghidra.sh  (the install is
# lost when the job ends: every job runs in a fresh container).
set -e

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MODULES="$HERE/modules"

REQ="${EASYRE_TOOLS:-all}"
case ",$REQ," in
  *",all,"*)
    REQ="core,die,$(for f in "$MODULES"/*.sh; do basename "$f" .sh; done | tr '\n' ',')" ;;
esac

WANT=""
for m in $(echo "wine,$REQ" | tr ',' ' '); do
  case " $WANT " in *" $m "*) ;; *) WANT="$WANT $m" ;; esac
done

if [ $# -gt 0 ]; then
  RUNLIST=""
  for m in "$@"; do
    case " $WANT " in
      *" $m "*) RUNLIST="$RUNLIST $m" ;;
      *) echo "== EasyRE toolchain: $m is not in EASYRE_TOOLS, skipped ==" ;;
    esac
  done
else
  RUNLIST="$WANT"
fi
[ -n "$RUNLIST" ] || exit 0

echo "== EasyRE toolchain: installing [${RUNLIST# }] =="
for m in $RUNLIST; do
  s="$MODULES/$m.sh"
  if [ -f "$s" ]; then
    echo "---- module: $m ----"
    sh "$s"
  else
    echo "!! unknown toolchain module: $m (skipped). Available:"
    ls "$MODULES" | sed 's/\.sh$//' | sed 's/^/     /'
  fi
done

# Shrink the image: drop the apt cache the modules populated.
rm -rf /var/lib/apt/lists/* /tmp/* 2>/dev/null || true
echo "== EasyRE toolchain: done =="
