---
name: formats-forensics
description: Non-executable inputs - documents, archives, images (stego), packet captures, and custom/unknown file formats. Carve, identify, extract the hidden data. Load when the handout is data rather than a program.
---

# formats-forensics

## When to use

The handout isn't a program to reverse but a file to pull something out of: an archive, an office/PDF document, an image hiding data, a `.pcap`, or an unknown binary blob with its own layout.

## Steps

1. **Identify and look inside.** `file` for the type; `binwalk` to find embedded/appended files; `strings` for obvious text. Many "formats" challenges are just an appended ZIP or a renamed file — check the real magic.
2. **Archives**: extract (handle passwords and nested archives). The flag may be in a comment, a password-protected inner file, or a file with a misleading extension.
3. **Documents** (PDF/OOXML): OOXML (`.docx/.xlsx/.pptx`) are ZIPs — unzip and read the XML and embedded media. PDFs hide data in streams, objects and metadata.
4. **Images / stego**: check metadata, appended data (`binwalk`), LSBs, and distinct color planes. Look for a second file concatenated after the image's end marker.
5. **Packet captures**: follow streams, export transferred objects, reassemble.
6. **Unknown/custom format**: hex-dump it, find the header magic, record field widths by spotting lengths/offsets/counts, and write a small Python parser in `/work/agent/` to walk and extract.

## Tools and commands

```sh
file -b blob; xxd blob | head                      # type + header magic
binwalk blob;  binwalk -e --dd='.*' blob           # find + carve embedded files
strings -n 6 blob | grep -iE 'flag|pass|key'
7z l archive;  7z x -p'PASS' archive -o/work/agent/out
unzip doc.docx -d /work/agent/doc                  # OOXML is a zip
exiftool image.png 2>/dev/null; xxd image.png | tail   # metadata + trailing data
```

For a custom format, parse with Python `struct`:

```python
import struct
d = open('/work/agent/blob','rb').read()
magic, count = struct.unpack_from('<4sI', d, 0)
# walk records using the widths you inferred from the hex dump
```

## Pitfalls

- Trusting the extension — always check the real magic; a `.png` that is actually a ZIP is a classic.
- Stopping at the first layer: carved files are often themselves archives or encoded — recurse.
- Over-reaching for stego tools when the data is just appended after the image EOF (`binwalk`/`xxd` tail finds it).
- Assuming encryption when it's encoding (base64/hex) or a simple XOR — test that first.

## Verification

- Extract the actual answer string/file and, if the task has a checker, pass it to `easyre check '<answer>'`.
