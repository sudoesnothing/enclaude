FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    sudo \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN groupadd --gid 1001 claude \
    && useradd --uid 1001 --gid 1001 --shell /bin/bash --create-home claude \
    && echo "claude ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/claude \
    && chmod 0440 /etc/sudoers.d/claude

# Install Claude Code CLI (native binary)
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && cp /root/.local/bin/claude /usr/local/bin/claude \
    && rm -rf /root/.local /root/.claude

# Workspace
RUN mkdir -p /workspace && chown claude:claude /workspace \
    && mkdir -p /home/claude/.claude && chown claude:claude /home/claude/.claude

COPY --chmod=755 scripts/setup/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# MCP status message on shell login
RUN echo '# Show MCP connection status on login' >> /home/claude/.bashrc \
    && echo '[ -f /home/claude/.mcp-status ] && cat /home/claude/.mcp-status' >> /home/claude/.bashrc

USER claude
WORKDIR /workspace

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD command -v claude > /dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["sleep", "infinity"]
