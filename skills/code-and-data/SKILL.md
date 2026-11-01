---
name: code-and-data
description: Tasks where the handout is a program plus a separate data file (a packet capture, an encrypted blob, a memory dump, a log) and the answer lives in the data, reachable only by applying an algorithm or key recovered from the program. Load when triage lists both an executable and a data artifact, or the flag is not inside the binary.
---

# code-and-data

## When to use

The handout has more than one artifact: an executable *and* data - a `.pcap`/`.pcapng`, an encrypted file, a dump, a database, a log. The binary alone has no flag; it is the keygen/encoder/decoder, and the answer is in the data once you apply what the binary does. Triage lists every file - decide each one's role before you start.

This skill is the bridge between `native-binaries`/`dotnet`/... (reverse the code), `crypto-id` (name the primitive), `formats-forensics`/`net` (open the data), and `solvers` (invert). It does not replace them; it sequences them.

## Steps

1. **Assign roles.** Which file is code, which is data? The data file's format (triage's `file` line) tells you how to open it. The code tells you how it was produced or consumed.
2. **Read the data's shape first.** Skim the capture/blob: protocol, message sizes, what is plaintext vs. random-looking (high entropy = encrypted/compressed). This tells you which part of the program to focus on.
3. **Find the transform in the code.** Locate where the program reads or writes that data: the socket/file I/O, then the function that encrypts, hashes, encodes or checks it. Pull the real constants, keys, IVs and tables out of the binary (`crypto-id` to recognise standard vs. custom primitives).
4. **Recover any runtime-derived material from the data itself.** Keys are often not static: a handshake, nonce, seed or session id in the capture is combined (XOR, KDF) with something to form the key. Reconstruct that from the captured bytes.
5. **Reimplement the transform in Python** in `/work/agent/` and **apply it offline** to the data. Keep it a faithful mirror of the decompiled logic - exact integer widths, byte order, iteration order.
6. **Recognise the answer.** Decrypted output should become readable: ASCII, a flag format, a known file magic. If it is still garbage, the transform, key or ordering is wrong - go back to step 3/4.

## Tools and commands

- Captures: the `net` module (`tshark` to follow streams and export fields, `capinfos` to summarise) and `scapy` (in `core`) for scripted parsing. See `formats-forensics` for carving other data files.
- Reversing the transform: the file-type skill for the binary, plus `crypto-id`.
- Reimplementation/solving: Python in `/work/agent/`, `pycryptodome` and `z3` (in `core`), see `solvers`.

```sh
tshark -r /work/src/challenge.pcapng -q -z follow,tcp,raw,0      # one stream's bytes
tshark -r cap.pcapng -Y 'http' -T fields -e http.request.uri -e data.data   # pick fields
capinfos /work/src/challenge.pcapng
```

## Pitfalls

- Assuming the flag is in the binary. If `strings`/decompilation never yields it, it is in the data - pivot.
- A plausible decrypt that is not quite text usually means wrong key derivation (step 4) or wrong chunk order, not wrong cipher.
- Standard-looking crypto with non-standard constants: a tweaked S-box or a custom PRNG means you must reimplement it exactly, not call a library.
- Processing order matters for stream ciphers / PRNG-keyed data: decrypt messages in the same chronological order the program produced them, or the keystream desyncs.

## Verification

- The recovered answer must come out of the *data* using constants/logic taken from the *code*, and read as a sane flag/string. Then confirm on the real target if it accepts input, and `easyre check '<answer>'`.
