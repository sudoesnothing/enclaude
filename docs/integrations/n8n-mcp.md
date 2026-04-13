# n8n MCP Server Integration

Connect Claude Code to your self-hosted [n8n](https://n8n.io/) instance via the
[Model Context Protocol](https://modelcontextprotocol.io/). This gives Claude
access to your n8n workflows as callable tools.

Requires the [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) community node
installed in your n8n instance.

---

## Prerequisites

- A running n8n instance with the MCP server endpoint enabled
- An API token or access token from your n8n instance
- Network connectivity between the Enclaude container and n8n (shared Docker
  network or public URL)

---

## Setup

1. Copy `.env.example` to `.env` if you haven't already:
   ```bash
   cp .env.example .env
   ```

2. Set your n8n MCP token and endpoint URL in `.env`:
   ```bash
   N8N_MCP_TOKEN=your-n8n-token-here
   N8N_MCP_URL=https://your-n8n-instance.example.com/mcp-server/http
   ```

3. Start or restart the container:
   ```bash
   bash scripts/setup/start.sh
   ```

4. On login you'll see a status message confirming the connection:
   ```
   n8n MCP: connected (https://your-n8n-instance.example.com/mcp-server/http)
   ```

---

## Configuration

| Variable | Default | Description |
|---|---|---|
| `N8N_MCP_TOKEN` | *(empty, disabled)* | Bearer token for n8n MCP authentication |
| `N8N_MCP_URL` | *(empty, disabled)* | Full URL to your n8n MCP HTTP endpoint |

Both variables must be set to enable the integration. When either is empty,
MCP is not configured and no status message is shown.

---

## Network Options

**Docker-local** (both containers on the same host):

If your n8n and Enclaude containers share a Docker network, use the internal
hostname and port directly. This keeps traffic on the local bridge network.

```bash
N8N_MCP_URL=http://n8n:5678/mcp-server/http
```

The container name (`n8n`) must match the service name in your n8n
`docker-compose.yml`, and both services must join the same external network
(e.g., `shared`).

**Remote** (via public URL, tunnel, or VPN):

If your n8n instance is exposed via a reverse proxy, Cloudflare tunnel, or
similar, use the public URL.

```bash
N8N_MCP_URL=https://your-n8n-instance.example.com/mcp-server/http
```

---

## How It Works

On every container boot, the entrypoint script:

1. Reads `N8N_MCP_TOKEN` and `N8N_MCP_URL` from the environment
2. Writes the MCP server config to `/home/claude/.claude/settings.json`
   (persisted in the `enclaude-config` volume)
3. Runs a quick health check against the endpoint
4. Writes the result to `~/.mcp-status`, displayed on shell login

The config is regenerated on every boot, so changes to `.env` take effect
on the next restart. If the token is removed, the stale MCP entry is
automatically cleaned from `settings.json`.

---

## Disabling

Remove or empty `N8N_MCP_TOKEN` in `.env` and restart the container. The
entrypoint will remove the MCP entry from `settings.json` automatically.

---

## Troubleshooting

**"connection failed (HTTP 401)"** - Your token is invalid or expired.
Generate a new one in your n8n instance and update `.env`.

**"connection failed (HTTP 000)"** - The endpoint is unreachable. Check that
your n8n instance is running and that the URL is correct. If using Docker-local
routing, verify both containers are on the same network.

**MCP tools not appearing in Claude** - After confirming the status message
shows "connected", restart Claude Code (`claude` command) to pick up the new
MCP configuration.
