#!/bin/sh
# jvm - Java / Android targets: jadx (dex/apk -> Java), apktool (resources +
# smali), cfr (JAR/class decompiler). Shares a JRE with the ghidra module if
# that is installed. See the jvm-android skill.
set -e

apt-get update
apt-get install -y --no-install-recommends curl jq unzip ca-certificates
command -v java >/dev/null 2>&1 || apt-get install -y --no-install-recommends openjdk-21-jre-headless

mkdir -p /opt/easyre/tools

# jadx (dex/apk/jar -> Java source), prebuilt release.
if [ ! -x /opt/jadx/bin/jadx ]; then
  TMP=$(mktemp -d)
  URL=$(curl -fsSL https://api.github.com/repos/skylot/jadx/releases/latest \
    | jq -r '.assets[].browser_download_url | select(test("jadx-[0-9].*\\.zip$"))' | head -1)
  curl -fsSL "$URL" -o "$TMP/jadx.zip"
  mkdir -p /opt/jadx && unzip -oq "$TMP/jadx.zip" -d /opt/jadx
  rm -rf "$TMP"
fi
ln -sfn /opt/jadx/bin/jadx /opt/easyre/tools/jadx
ln -sfn /opt/jadx/bin/jadx-gui /opt/easyre/tools/jadx-gui 2>/dev/null || true

# apktool (APK resources + smali) from the Ubuntu archive.
apt-get install -y --no-install-recommends apktool || true

# cfr (JAR/class decompiler), single jar.
if [ ! -f /opt/cfr/cfr.jar ]; then
  TMP=$(mktemp -d)
  URL=$(curl -fsSL https://api.github.com/repos/leibnitz27/cfr/releases/latest \
    | jq -r '.assets[].browser_download_url | select(test("cfr-.*\\.jar$"))' | head -1)
  mkdir -p /opt/cfr && curl -fsSL "$URL" -o /opt/cfr/cfr.jar
  rm -rf "$TMP"
fi
printf '#!/bin/sh\nexec java -jar /opt/cfr/cfr.jar "$@"\n' > /opt/easyre/tools/cfr
chmod +x /opt/easyre/tools/cfr

echo "jvm tools:"
for t in java jadx apktool cfr; do
  command -v "$t" >/dev/null 2>&1 && printf '  [x] %s\n' "$t" || printf '  [ ] %s\n' "$t"
done
