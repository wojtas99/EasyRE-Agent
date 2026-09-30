#!/bin/sh
cat >/dev/null
M=/work/.easyre
[ -f "$M/job.json" ] || M=/work
[ -f /work/HELP.md ] && exit 0
if grep -q '"mode": "tutor"' "$M/job.json" 2>/dev/null; then
  [ -f "$M/answer" ] && exit 0
  msg="Not finished: solve the task and verify the answer with easyre check (it stays private), then stop."
elif grep -q '"mode": "hint"' "$M/job.json" 2>/dev/null; then
  [ -f "$M/DONE" ] && exit 0
  msg="Not finished: verify the answer with easyre check, write /work/hints.md, then run easyre done."
else
  [ -f "$M/ANSWER" ] && exit 0
  msg="No accepted answer yet (easyre check has not accepted one). Re-read /work/agent/notes.md, pick the next most promising lead, and continue."
fi
n=$(cat "$M/stops" 2>/dev/null || echo 0); [ "$n" -ge 30 ] && exit 0
echo $((n + 1)) > "$M/stops"
echo "$msg" >&2
exit 2
