#!/bin/sh
# dotnet - managed-code targets: .NET SDK + ilspycmd decompiler, plus
# best-effort de4dot (deobfuscator) and Il2CppDumper (Unity IL2CPP). See the
# dotnet skill.
set -e

apt-get update
apt-get install -y --no-install-recommends curl jq unzip ca-certificates

# .NET SDK from the Ubuntu 24.04 archive (no Microsoft repo needed).
apt-get install -y --no-install-recommends dotnet-sdk-8.0 || \
  apt-get install -y --no-install-recommends dotnet-sdk-9.0

export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export PATH="$PATH:/root/.dotnet/tools"

# ilspycmd: the reliable headless C# decompiler.
dotnet tool install -g ilspycmd || dotnet tool update -g ilspycmd || true
# Expose it on PATH via /opt/easyre/tools (dotnet's tools dir is not on PATH).
[ -x /root/.dotnet/tools/ilspycmd ] && ln -sf /root/.dotnet/tools/ilspycmd /opt/easyre/tools/ilspycmd || true

# Il2CppDumper (Unity IL2CPP) - prebuilt .NET build, run via `dotnet`.
TMP=$(mktemp -d)
URL=$(curl -fsSL https://api.github.com/repos/Perfare/Il2CppDumper/releases/latest \
  | jq -r '.assets[].browser_download_url | select(test("net.*\\.zip$"))' | head -1) || true
if [ -n "${URL:-}" ]; then
  curl -fsSL "$URL" -o "$TMP/i.zip" && mkdir -p /opt/Il2CppDumper && unzip -oq "$TMP/i.zip" -d /opt/Il2CppDumper || true
  DLL=$(find /opt/Il2CppDumper -name 'Il2CppDumper.dll' | head -1)
  if [ -n "$DLL" ]; then
    printf '#!/bin/sh\nexec dotnet "%s" "$@"\n' "$DLL" > /opt/easyre/tools/il2cppdumper
    chmod +x /opt/easyre/tools/il2cppdumper
  fi
fi

# de4dot-cex (deobfuscator) - prebuilt .NET build, best effort.
URL=$(curl -fsSL https://api.github.com/repos/ViRb3/de4dot-cex/releases/latest \
  | jq -r '.assets[].browser_download_url | select(test("\\.zip$"))' | head -1) || true
if [ -n "${URL:-}" ]; then
  curl -fsSL "$URL" -o "$TMP/d.zip" && mkdir -p /opt/de4dot && unzip -oq "$TMP/d.zip" -d /opt/de4dot || true
  DLL=$(find /opt/de4dot -name 'de4dot*.dll' | head -1)
  if [ -n "$DLL" ]; then
    printf '#!/bin/sh\nexec dotnet "%s" "$@"\n' "$DLL" > /opt/easyre/tools/de4dot
    chmod +x /opt/easyre/tools/de4dot
  fi
fi
rm -rf "$TMP"

echo "dotnet tools:"
for t in dotnet ilspycmd il2cppdumper de4dot; do
  command -v "$t" >/dev/null 2>&1 && printf '  [x] %s\n' "$t" || printf '  [ ] %s\n' "$t"
done
