#!/bin/sh
# die - Detect It Easy (console `diec`). `easyre` triage calls `diec` to fill
# triage.md with compiler / packer / protector detection, so this module is
# part of the default set.
set -e

ARCH=$(dpkg --print-architecture)
. /etc/os-release 2>/dev/null || true
REL="${VERSION_ID:-24.04}"

if command -v diec >/dev/null 2>&1; then
  echo "diec already present"; diec --version 2>/dev/null | head -1 || true; exit 0
fi

apt-get update
apt-get install -y --no-install-recommends curl jq ca-certificates

TMP=$(mktemp -d)
# Find the newest Ubuntu .deb asset matching this release from the DIE releases.
URL=$(curl -fsSL https://api.github.com/repos/horsicq/DIE-engine/releases/latest \
  | jq -r --arg rel "$REL" --arg arch "$ARCH" \
      '.assets[].browser_download_url
       | select(test("[Uu]buntu"))
       | select(test($rel))
       | select(test($arch))
       | select(test("\\.deb$"))' | head -1)

# Fall back to any matching-arch Ubuntu .deb if the exact release is not offered
# (the .deb$ check skips the portable tar.gz that also says "Ubuntu").
[ -z "$URL" ] && URL=$(curl -fsSL https://api.github.com/repos/horsicq/DIE-engine/releases/latest \
  | jq -r --arg arch "$ARCH" \
      '.assets[].browser_download_url | select(test("[Uu]buntu")) | select(test($arch)) | select(test("\\.deb$"))' \
  | sort | tail -1)

if [ -n "$URL" ]; then
  echo "DIE: $URL"
  curl -fsSL "$URL" -o "$TMP/die.deb"
  apt-get install -y --no-install-recommends "$TMP/die.deb"
fi
rm -rf "$TMP"

command -v diec >/dev/null 2>&1 && { echo "[x] diec"; diec --version 2>/dev/null | head -1 || true; } \
  || echo "[ ] diec (install failed; triage will fall back to \`file\`)"
