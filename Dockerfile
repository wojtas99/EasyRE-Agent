FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 \
    IS_SANDBOX=1 DISABLE_AUTOUPDATER=1 CODEX_HOME=/state/codex WINEDEBUG=-all \
    EASYRE_SKILLS=/opt/easyre/skills PIP_BREAK_SYSTEM_PACKAGES=1 \
    PATH=/opt/easyre/tools:/root/.local/bin:/root/.dotnet/tools:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq file p7zip-full unzip python3 python3-pip python3-venv && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y --no-install-recommends nodejs && \
    npm i -g @anthropic-ai/claude-code @openai/codex && \
    npm cache clean --force && rm -rf /var/lib/apt/lists/*

# Toolchain: one image layer per module, the heavy and stable ones first. A
# module that fails or is edited rebuilds from its own layer on; the layers
# above it stay cached. EASYRE_TOOLS (set in .env) picks the modules: "all" or
# a subset; a module not picked prints "skipped". A new module in
# toolchain/modules/ needs its own COPY + RUN pair below.
COPY toolchain/install.sh /opt/easyre/toolchain/
COPY toolchain/modules/wine.sh /opt/easyre/toolchain/modules/
RUN mkdir -p /opt/easyre/tools && sh /opt/easyre/toolchain/install.sh wine
# Declared after wine, so changing it does not reinstall Wine or the layers above.
ARG EASYRE_TOOLS=all
COPY toolchain/yara/ /opt/easyre/toolchain/yara/
COPY toolchain/modules/core.sh /opt/easyre/toolchain/modules/
RUN sh /opt/easyre/toolchain/install.sh core
COPY toolchain/modules/die.sh /opt/easyre/toolchain/modules/
RUN sh /opt/easyre/toolchain/install.sh die
COPY toolchain/prefetch /opt/easyre/toolchain/
COPY toolchain/ghidra_scripts/ /opt/easyre/toolchain/ghidra_scripts/
COPY toolchain/modules/ghidra.sh /opt/easyre/toolchain/modules/
RUN sh /opt/easyre/toolchain/install.sh ghidra
COPY toolchain/modules/jvm.sh /opt/easyre/toolchain/modules/
RUN sh /opt/easyre/toolchain/install.sh jvm
COPY toolchain/modules/dotnet.sh /opt/easyre/toolchain/modules/
RUN sh /opt/easyre/toolchain/install.sh dotnet
COPY toolchain/modules/python.sh /opt/easyre/toolchain/modules/
RUN sh /opt/easyre/toolchain/install.sh python
COPY toolchain/modules/js.sh /opt/easyre/toolchain/modules/
RUN sh /opt/easyre/toolchain/install.sh js
COPY toolchain/modules/autoit.sh /opt/easyre/toolchain/modules/
RUN sh /opt/easyre/toolchain/install.sh autoit
COPY toolchain/modules/wasm.sh /opt/easyre/toolchain/modules/
RUN sh /opt/easyre/toolchain/install.sh wasm
COPY toolchain/modules/angr.sh /opt/easyre/toolchain/modules/
RUN sh /opt/easyre/toolchain/install.sh angr

# Everything below changes often but is cheap; keep it after the toolchain.
COPY toolchain/README.md /opt/easyre/toolchain/README.md
COPY config/ /opt/easyre/config/
COPY skills/ /opt/easyre/skills/
COPY easyre /usr/local/bin/easyre
COPY toolchain/dump-mem /opt/easyre/tools/dump-mem
RUN mkdir -p /opt/easyre/tools /root/.claude /root/.agents /state/codex /tasks /jobs && \
    cp /opt/easyre/config/claude-settings.json /root/.claude/settings.json && \
    echo '{"hasCompletedOnboarding": true}' > /root/.claude.json && \
    ln -sfn /opt/easyre/skills /root/.claude/skills && ln -sfn /opt/easyre/skills /root/.agents/skills && \
    chmod +x /usr/local/bin/easyre /opt/easyre/config/*.sh /opt/easyre/tools/dump-mem && \
    claude --version && codex --version

WORKDIR /jobs
CMD ["easyre", "--help"]
