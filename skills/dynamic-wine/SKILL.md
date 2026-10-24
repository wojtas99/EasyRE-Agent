---
name: dynamic-wine
description: Run and observe Windows .exe targets on Linux under Wine - console and GUI, tracing, debugging, and driving the UI on a virtual display. Load when running the target is cheaper than reading it.
---

# dynamic-wine

## When to use

The target is a Windows `.exe` and running it answers the question faster than static reading: the check is data-driven, the input transform is long, or you want to confirm a candidate. Wine is always installed.

## Steps

1. **Run it once** and see what it does with input. Console programs usually read from stdin or argv.
2. **Pick observation depth**: watch strings/output → trace API calls → single-step in the debugger.
3. **For GUI targets**, bring up a virtual display, then either automate the widgets or just drive the critical path.
4. **Confirm the candidate** on the real binary before `easyre check`.

## Tools and commands

Console:

```sh
printf 'guess\n'  | wine /work/src/app.exe          # feed stdin
wine /work/src/app.exe MY_SERIAL                     # argv
WINEDEBUG=+relay wine app.exe 2>/work/agent/relay.txt # trace every API call (huge; grep it)
WINEDEBUG=+relay wine app.exe 2>&1 | grep -iE 'strcmp|lstrcmp|wcscmp|MessageBox'
```

GUI on a virtual display:

```sh
xvfb-run -a wine /work/src/app.exe                   # run headless
# with input automation (install xdotool if missing):
xvfb-run -a sh -c 'wine app.exe & sleep 5; DISPLAY=:99 xdotool type "serial"; xdotool key Return; sleep 3'
```

Debugging and memory:

```sh
winedbg --gdb wine app.exe           # winedbg; attach gdb to inspect/break
wine app.exe & gdb -p $(pgrep -f app.exe)   # native gdb onto the wine process
```

`+relay` filtered to compare/API calls is usually the fastest way to catch "input vs expected" at the moment of comparison. For a key built at runtime, break in the debugger right after the transform and read it out of memory.

## Pitfalls

- First run per prefix is slow and noisy (Wine init, `fixme:` spam) — ignore `fixme:`/`err:` unless they are the point.
- `WINEDEBUG=+relay` output is enormous; always redirect to a file and grep, never watch it raw.
- `WINEDEBUG=-all` (set in the image) silences the noise; unset it when you *want* tracing.
- GUI programs may exit instantly under Xvfb if they need a resource Wine lacks; check with a quick `+relay` grep for the failing call.
- Running the target is running untrusted code. These are crackmes — fine in this container; never do this with real malware outside an isolated VM.

## Verification

- A candidate that makes the real program print the success string (or pass `--verify`) is proven. Record the exact command in the report.
