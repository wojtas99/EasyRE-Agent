---
name: jvm-android
description: Java/Kotlin JARs and class files, and Android APKs (dex, resources, smali, native .so). Decompile to Java, patch smali, find the native layer. Load when triage flags a Java archive or Android APK. Requires the jvm toolchain module.
---

# jvm-android

## When to use

Triage shows a Java archive (`META-INF/MANIFEST.MF`) or an Android APK (`classes.dex`). Requires the `jvm` module; install with `sh /opt/easyre/toolchain/modules/jvm.sh` if the tools are missing.

## Steps

1. **JAR / .class**: decompile to Java with `cfr`. Read the `main`/entry class and follow the check.
2. **APK**: decompile the dex to Java with `jadx` for reading; use `apktool` when you need resources (`strings.xml`, `AndroidManifest.xml`) or want to patch and rebuild via smali.
   - Entry points: the launcher `Activity` from the manifest, `onCreate`, button `onClick` handlers.
   - Secrets hide in `res/values/strings.xml`, `assets/`, and `BuildConfig`.
3. **Native layer**: a check in `lib/<abi>/*.so` reached through JNI. Pull the `.so` and treat it as native (`native-binaries`, `ghidra-headless`); JNI method names are `Java_<pkg>_<class>_<method>`.
4. **Find the check**: a `boolean` method comparing input to a constant, a decoded resource, or a value returned from JNI.

## Tools and commands

```sh
jadx -d /work/agent/jadx  /work/src/app.apk     # dex -> readable Java (best first look)
apktool d /work/src/app.apk -o /work/agent/apk  # resources + smali (for patch/rebuild)
cfr /work/src/app.jar --outputdir /work/agent/jar   # JAR/class -> Java
unzip -l app.apk                                 # list; dex, libs, assets
strings -a lib/arm64-v8a/libnative.so | grep -i flag
```

Patch-and-rebuild (smali) when you want to neutralize a check:

```sh
# edit agent/apk/smali/.../Check.smali  (e.g. force the boolean return)
apktool b /work/agent/apk -o /work/agent/patched.apk
```

## Pitfalls

- `jadx` is best for reading; `apktool` is what you need for resources and for rebuilding. Use the right one.
- The logic may be entirely in a JNI `.so` — if the Java check just calls `nativeCheck()`, pivot to the native skill.
- Obfuscated (ProGuard/R8) names are meaningless; follow data flow and strings, not names.
- Rebuilt APKs must be re-signed to install on a device — but for a crackme you usually only need to *read* the check, not run it.

## Verification

- Reimplement the check from the decompiled Java, or read the constant it compares against, then `easyre check '<answer>'`.
