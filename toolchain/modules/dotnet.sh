#!/bin/sh
# dotnet - managed-code targets: .NET SDK 10 + ilspycmd (C# decompiler),
# Il2CppDumper (Unity IL2CPP metadata) and de4dot (deobfuscator, runs on Mono).
# See the dotnet skill.
set -e

apt-get update
# dotnet-sdk-10.0: current ilspycmd targets .NET 10. de4dot: Ubuntu's Mono build.
apt-get install -y --no-install-recommends curl jq unzip ca-certificates dotnet-sdk-10.0 de4dot

export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
DOTNET_ROOT=$(dirname "$(readlink -f "$(command -v dotnet)")")
mkdir -p /opt/easyre/tools

# ilspycmd in a fixed tool path + a wrapper, so it works without ~/.dotnet/tools
# on PATH and finds the apt-installed runtime.
dotnet tool install --tool-path /opt/ilspycmd ilspycmd \
  || dotnet tool update --tool-path /opt/ilspycmd ilspycmd
printf '#!/bin/sh\nexport DOTNET_ROOT=%s\nexec /opt/ilspycmd/ilspycmd "$@"\n' "$DOTNET_ROOT" \
  > /opt/easyre/tools/ilspycmd
chmod +x /opt/easyre/tools/ilspycmd

# Il2CppDumper: newest cross-platform build (net6/net7 releases; the -win ones
# are skipped). Rolled forward onto the installed runtime, and "press any key"
# disabled so it does not crash without a terminal.
TMP=$(mktemp -d)
URL=$(curl -fsSL https://api.github.com/repos/Perfare/Il2CppDumper/releases/latest \
  | jq -r '[.assets[].browser_download_url | select(test("Il2CppDumper-net[0-9]+-v[^/]*\\.zip$"))]
           | sort_by(capture("-net(?<n>[0-9]+)-v").n | tonumber) | last // empty') || true
if [ -n "${URL:-}" ] && curl -fsSL "$URL" -o "$TMP/i.zip"; then
  rm -rf /opt/Il2CppDumper && mkdir -p /opt/Il2CppDumper && unzip -oq "$TMP/i.zip" -d /opt/Il2CppDumper
  DLL=$(find /opt/Il2CppDumper -name 'Il2CppDumper.dll' | head -1)
  if [ -n "$DLL" ]; then
    sed -i 's/"RequireAnyKey": *true/"RequireAnyKey": false/' "$(dirname "$DLL")/config.json" 2>/dev/null || true
    printf '#!/bin/sh\nexport DOTNET_ROOT=%s DOTNET_ROLL_FORWARD=Major\nexec dotnet "%s" "$@"\n' \
      "$DOTNET_ROOT" "$DLL" > /opt/easyre/tools/il2cppdumper
    chmod +x /opt/easyre/tools/il2cppdumper
  fi
else
  echo "!! Il2CppDumper download failed (skipped)"
fi
rm -rf "$TMP"

echo "dotnet tools:"
for t in dotnet ilspycmd il2cppdumper de4dot; do
  command -v "$t" >/dev/null 2>&1 && printf '  [x] %s\n' "$t" || printf '  [ ] %s\n' "$t"
done
ilspycmd --version 2>/dev/null | head -1 || echo "!! ilspycmd does not start"
