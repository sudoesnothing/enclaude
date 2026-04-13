#!/bin/bash
set -e

WORKSPACE=/workspace
INIT_MARKER="${WORKSPACE}/.initialized"

initialize_workspace() {
    # Default: minimal workspace with a single projects/ directory.
    # To use the WAT (Workflows/Agents/Tools) layout instead,
    # comment out the line below and uncomment the WAT block.
    mkdir -p "${WORKSPACE}/projects"

    # WAT Framework layout — uncomment to enable:
    # mkdir -p \
    #     "${WORKSPACE}/projects" \
    #     "${WORKSPACE}/tools" \
    #     "${WORKSPACE}/workflows" \
    #     "${WORKSPACE}/.tmp"

    # Base .gitignore
    if [ ! -f "${WORKSPACE}/.gitignore" ]; then
        cat > "${WORKSPACE}/.gitignore" << 'EOF'
.env
*.credentials.json
token.json
.tmp/
__pycache__/
node_modules/
.DS_Store
Thumbs.db
EOF
    fi

    touch "${INIT_MARKER}"
}

if [ ! -f "${INIT_MARKER}" ]; then
    initialize_workspace
fi

# Persist credentials across ephemeral containers.
# Claude Code writes config to ~/.claude.json but only ~/.claude/ is volume-mounted.
# Symlink into the volume so the file survives container teardown.
ln -sf /home/claude/.claude/.claude.json /home/claude/.claude.json

# ── n8n MCP configuration (optional) ──────────────────────
# When N8N_MCP_TOKEN and N8N_MCP_URL are set, writes MCP
# config to /workspace/.mcp.json (picked up by Claude Code
# from any subdirectory).  Runs every boot so token and URL
# stay current with .env values.
configure_mcp() {
    local mcp_file="${WORKSPACE}/.mcp.json"
    local status_file="/home/claude/.mcp-status"
    local mcp_url="${N8N_MCP_URL:-}"

    # No token or URL → clean up any stale config, remove status file
    if [ -z "${N8N_MCP_TOKEN:-}" ] || [ -z "${mcp_url}" ]; then
        if [ -f "$mcp_file" ]; then
            node -e "
                const fs = require('fs');
                try {
                    const s = JSON.parse(fs.readFileSync('$mcp_file', 'utf8'));
                    if (s.mcpServers && s.mcpServers['n8n-mcp']) {
                        delete s.mcpServers['n8n-mcp'];
                        if (Object.keys(s.mcpServers).length === 0) delete s.mcpServers;
                        fs.writeFileSync('$mcp_file', JSON.stringify(s, null, 2) + '\n');
                    }
                } catch {}
            "
        fi
        rm -f "$status_file"
        return 0
    fi

    # Token and URL are set → write/merge MCP config into .mcp.json
    node -e "
        const fs = require('fs');
        const path = '$mcp_file';
        const url = process.env.N8N_MCP_URL;
        const token = process.env.N8N_MCP_TOKEN;
        let config = {};
        try { config = JSON.parse(fs.readFileSync(path, 'utf8')); } catch {}
        if (!config.mcpServers) config.mcpServers = {};
        config.mcpServers['n8n-mcp'] = {
            type: 'http',
            url: url,
            headers: { Authorization: 'Bearer ' + token }
        };
        fs.writeFileSync(path, JSON.stringify(config, null, 2) + '\n');
    "
    chmod 600 "$mcp_file"

    # Health check — quick connectivity test
    local http_code
    http_code=$(curl -s -o /dev/null -w '%{http_code}' \
        --max-time 3 \
        -H "Authorization: Bearer ${N8N_MCP_TOKEN}" \
        "${mcp_url}" 2>/dev/null) || http_code="000"

    if [ "$http_code" -ge 200 ] 2>/dev/null && [ "$http_code" -lt 400 ] 2>/dev/null; then
        echo "  n8n MCP: connected (${mcp_url})" | tee "$status_file"
    else
        echo "  n8n MCP: connection failed (HTTP ${http_code}) - check N8N_MCP_TOKEN in .env and restart" | tee "$status_file"
    fi
}

configure_mcp

exec "$@"
