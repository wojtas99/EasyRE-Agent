#!/bin/sh
# jvm - Java / Android targets: jadx (dex/apk -> Java), apktool (resources +
# smali), cfr (JAR/class decompiler). Reuses the JDK from the ghidra module if
# present. See the jvm-android skill.
set -e

apt-get update
apt-get install -y --no-install-recommends curl jq unzip ca-certificates
command -v java >/dev/null 2>&1 || apt-get install -y --no-install-recommends openjdk-25-jre-headless

mkdir -p /opt/easyre/tools

# jadx (dex/apk/jar -> Java source), prebuilt release (not the -gui Windows zips).
if [ ! -x /opt/jadx/bin/jadx ]; then
  TMP=$(mktemp -d)
  URL=$(curl -fsSL https://api.github.com/repos/skylot/jadx/releases/latest \
    | jq -r '.assets[].browser_download_url | select(test("/jadx-[0-9][^/]*\\.zip$"))' | head -1)
  [ -n "$URL" ] || { echo "could not resolve a jadx release URL (GitHub API rate limit?)"; exit 1; }
  curl -fsSL "$URL" -o "$TMP/jadx.zip"
  rm -rf /opt/jadx && mkdir -p /opt/jadx && unzip -oq "$TMP/jadx.zip" -d /opt/jadx
  chmod +x /opt/jadx/bin/*
  rm -rf "$TMP"
fi
ln -sfn /opt/jadx/bin/jadx /opt/easyre/tools/jadx

# apktool (APK resources + smali) from the Ubuntu archive.
apt-get install -y --no-install-recommends apktool

# cfr: the plain cfr-<ver>.jar (the release also ships -javadoc/-sources jars).
if [ ! -f /opt/cfr/cfr.jar ]; then
  URL=$(curl -fsSL https://api.github.com/repos/leibnitz27/cfr/releases/latest \
    | jq -r '.assets[].browser_download_url | select(test("/cfr-[0-9.]+\\.jar$"))' | head -1)
  [ -n "$URL" ] || { echo "could not resolve a cfr release URL (GitHub API rate limit?)"; exit 1; }
  mkdir -p /opt/cfr && curl -fsSL "$URL" -o /opt/cfr/cfr.jar
fi
printf '#!/bin/sh\nexec java -jar /opt/cfr/cfr.jar "$@"\n' > /opt/easyre/tools/cfr
chmod +x /opt/easyre/tools/cfr

echo "jvm tools:"
for t in java jadx apktool cfr; do
  command -v "$t" >/dev/null 2>&1 && printf '  [x] %s\n' "$t" || printf '  [ ] %s\n' "$t"
done
cfr --version 2>&1 | head -1
