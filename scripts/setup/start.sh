#!/usr/bin/env bash
# start.sh — launch an ephemeral enclaude session.
# Container is removed on exit. Workspace data persists in Docker volumes.
#
# Usage (from repo root):
#   bash scripts/setup/start.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "$REPO_ROOT"

# Verify Docker is running
if ! docker info &>/dev/null; then
    echo ""
    echo "  Error: Docker is not running."
    echo "  Please start Docker Desktop (or the Docker daemon) and try again."
    echo ""
    exit 1
fi

echo ""
echo "  [enclaude] Building and starting container..."
echo ""

docker compose up -d --build

echo ""
echo "  ============================================"
echo "  Enclaude is ready."
echo ""
echo "  Run 'claude' to start Claude Code."
echo "  Run 'exit' to end the session."
echo "  ============================================"
echo ""

docker exec -it enclaude bash

echo ""
echo "  [enclaude] Session ended. Tearing down container..."
echo "  [enclaude] (Workspace data is preserved in Docker volumes.)"
echo ""

docker compose down --remove-orphans
