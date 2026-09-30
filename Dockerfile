FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 \
    IS_SANDBOX=1 DISABLE_AUTOUPDATER=1 CODEX_HOME=/state/codex WINEDEBUG=-all \
    EASYRE_SKILLS=/opt/easyre/skills PIP_BREAK_SYSTEM_PACKAGES=1 \
    PATH=/opt/easyre/tools:/root/.local/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq file p7zip-full unzip python3 python3-pip python3-venv && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y --no-install-recommends nodejs && \
    npm i -g @anthropic-ai/claude-code @openai/codex

COPY toolchain/ /opt/easyre/toolchain/
RUN if [ -x /opt/easyre/toolchain/install.sh ]; then /opt/easyre/toolchain/install.sh; fi

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
