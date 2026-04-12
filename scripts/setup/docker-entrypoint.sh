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

exec "$@"
