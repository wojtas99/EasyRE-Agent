#!/bin/sh
# EasyRE-Agent toolchain installer.
#
# Modules live in toolchain/modules/<name>.sh. Pick which ones to install with
# the EASYRE_TOOLS build-arg: "all" (the default) installs every module, or
# give a comma-separated subset in .env for a smaller image, e.g.:
#
#   EASYRE_TOOLS=core,die,ghidra
#
# The "wine" module is always installed (the agent needs it to run .exe
# targets and to auto-verify).
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
WANT="wine,$REQ"

echo "== EasyRE toolchain: installing [$WANT] =="

seen=""
echo "$WANT" | tr ',' '\n' | while IFS= read -r m; do
  m=$(echo "$m" | tr -d ' ')
  [ -z "$m" ] && continue
  case ",$seen," in *",$m,"*) continue ;; esac
  seen="$seen,$m"
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
