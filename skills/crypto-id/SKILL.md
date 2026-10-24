---
name: crypto-id
description: Recognize crypto and encoding primitives from their constants and structure (AES, DES, SHA/MD5, CRC, TEA/XTEA, RC4, base64/base32), then reproduce or invert them. Load when the check hashes, encrypts or encodes the input.
---

# crypto-id

## When to use

The check doesn't compare the input directly but hashes, encrypts, or encodes it and compares the result. You see magic constants, S-boxes, or structured loops. Identify the primitive, then either reproduce it (to make the expected value) or invert it.

## Steps

1. **Fingerprint by constant.** Primitives give themselves away:
   - `0x67452301 0xefcdab89 0x98badcfe 0x10325476` → **MD5** (also MD4/SHA-1 init);
   - `0x6a09e667 0xbb67ae85 ...` → **SHA-256**;
   - `0x9e3779b9` (delta) → **TEA/XTEA**;
   - a 256-byte byte permutation built in a loop → **RC4** (or an S-box);
   - the AES S-box (`0x63 0x7c 0x77 0x7b 0xf2 0x6b ...`) / `0x011b` reduction → **AES**;
   - a 256-entry 32-bit table with `0xedb88320` → **CRC32**.
2. **Confirm with a tool** rather than eyeballing: `capa` reports crypto capabilities; `yara` crypto rulesets flag constants; FLOSS may surface base64 alphabets.
3. **Spot encodings** (not crypto): `A-Za-z0-9+/` (+ `=` padding) → **base64**; `A-Z2-7` → **base32**; `0-9a-f` pairs → **hex**; a shifted-alphabet table → a substitution/XOR.
4. **Reproduce or invert**:
   - Hash/one-way: you can't invert — either the plaintext space is small (brute force) or the expected preimage/hash is stored to compare against (extract it).
   - Symmetric cipher: find the key and IV in the binary, then decrypt the stored ciphertext.
   - Encoding: just decode.

## Tools and commands

```sh
capa /work/src/app.exe                    # named crypto/encoding capabilities + addresses
yara /path/to/crypto.yar /work/src/app.exe
floss /work/src/app.exe | grep -iE 'base64|=$'   # alphabets / encoded blobs
```

`pycryptodome` (in `core`) reproduces the primitive once identified:

```python
from Crypto.Cipher import AES, ARC4
from hashlib import md5, sha256
ARC4.new(key).decrypt(ct)
AES.new(key, AES.MODE_CBC, iv).decrypt(ct)
```

For an unknown constant, search it online or check it against the lists above before assuming a custom scheme.

## Pitfalls

- "Looks like crypto" is often just XOR with a repeating key — check for that first; it's trivially invertible.
- Modified primitives (tweaked S-box, non-standard delta, swapped rounds) are common in crackmes — reproduce the binary's *exact* variant, not the textbook one.
- Endianness and block/word size errors produce right-length-but-wrong output; verify against one known input.
- A stored hash means brute force or a known preimage, not inversion — don't burn hours trying to reverse SHA.

## Verification

- Reproduce the primitive, confirm it matches the binary on a known input, compute the answer, then `easyre check '<answer>'`.
