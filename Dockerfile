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

# Toolchain. Copy the installer + modules and run them first, so that editing
# docs or anything below does not invalidate (and reinstall) this heavy layer.
COPY toolchain/install.sh toolchain/prefetch /opt/easyre/toolchain/
COPY toolchain/modules/ /opt/easyre/toolchain/modules/
COPY toolchain/ghidra_scripts/ /opt/easyre/toolchain/ghidra_scripts/
COPY toolchain/yara/ /opt/easyre/toolchain/yara/
# Which toolchain modules to install (see toolchain/README.md); `wine` is always
# added. Set EASYRE_TOOLS in .env and run `docker compose build`. Declared here,
# not at the top, so changing it does not rebuild the Node/agent-CLI layer above.
ARG EASYRE_TOOLS=all
RUN mkdir -p /opt/easyre/tools && EASYRE_TOOLS="${EASYRE_TOOLS}" sh /opt/easyre/toolchain/install.sh

# Everything below changes often but is cheap; keep it after the toolchain.
COPY toolchain/README.md /opt/easyre/toolchain/README.md
COPY config/ /opt/easyre/config/
COPY skills/ /opt/easyre/skills/
COPY easyre /usr/local/bin/easyre
RUN mkdir -p /opt/easyre/tools /root/.claude /root/.agents /state /tasks /jobs && \
    cp /opt/easyre/config/claude-settings.json /root/.claude/settings.json && \
    echo '{"hasCompletedOnboarding": true}' > /root/.claude.json && \
    ln -sfn /opt/easyre/skills /root/.claude/skills && ln -sfn /opt/easyre/skills /root/.agents/skills && \
    chmod +x /usr/local/bin/easyre /opt/easyre/config/*.sh && \
    claude --version && codex --version

WORKDIR /jobs
CMD ["easyre", "--help"]
