#!/bin/sh
cd "$(dirname "$0")" || exit 1
if [ "$1" = "open" ]; then
  job=$(ls -1dtr jobs/"$2"*/ 2>/dev/null | grep -v '/_' | tail -n 1)
  [ -n "$job" ] || { echo "No job found matching \"$2\". See: ./easyre.sh jobs"; exit 1; }
  job=${job%/}
  target="$job/report.md"
  [ -f "$job/tutor.md" ] && target="$job/tutor.md"
  [ "$3" = "folder" ] || [ ! -f "$target" ] && target="$job"
  if command -v xdg-open >/dev/null 2>&1; then xdg-open "$target"; else open "$target"; fi
  exit 0
fi
exec docker compose run --rm easyre easyre "$@"
