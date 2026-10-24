---
name: javascript-electron
description: JavaScript, Node and Electron apps - unpack asar, undo bundling and obfuscation, pretty-print, find the check. Load when triage flags an Electron app or the handout is JS/Node. Requires the js toolchain module.
---

# javascript-electron

## When to use

Triage shows an Electron app (`app.asar`), or the handout is JavaScript / a Node bundle. Requires the `js` module; install with `/opt/easyre/toolchain/modules/js.sh` if the tools are missing. Node is always in the base image.

## Steps

1. **Electron**: the app code is inside `resources/app.asar`. Extract it, then read `main.js`/`index.js` and whatever the renderer loads.
2. **Bundled** (webpack/rollup, one giant minified file): un-bundle and deobfuscate with `webcrack`, which also splits modules back out. Then pretty-print.
3. **Just minified**: `js-beautify` to get readable layout.
4. **Find the check**: an input compared with a string, a value passed to `===`/`==`, a hash (`crypto.createHash`), or an `atob`/`Buffer.from(...,'base64')` decode. Node lets you also just *run* the relevant function.

## Tools and commands

```sh
asar extract /work/src/resources/app.asar /work/agent/app   # unpack Electron
asar list /work/src/app.asar
webcrack /work/agent/app/main.js -o /work/agent/unpacked    # un-bundle + deobfuscate
js-beautify -r /work/agent/app/renderer.js                  # pretty-print in place
grep -rniE 'password|flag|secret|===|atob|createHash' /work/agent/app
```

Run the check directly instead of reading all of it:

```sh
node -e 'const f=require("/work/agent/app/check.js"); console.log(f.validate("guess"))'
node -e 'console.log(Buffer.from("ZmxhZw==","base64").toString())'   # decode constants
```

## Pitfalls

- `.asar` is an archive, not source — extract it first; `grep` on the raw `.asar` misses most of it.
- Obfuscated JS often builds the comparison string at runtime from an array + index math; `webcrack` resolves much of this, but sometimes evaluating the decoder in `node` is fastest.
- Source maps (`.map`), if shipped, hand you the original source — check for them before deobfuscating.
- Electron logic may be split between the main process (`main.js`) and the renderer; the check can be in either.

## Verification

- Run the recovered/validator function in `node` with the candidate, or reimplement the decode, then `easyre check '<answer>'`.
