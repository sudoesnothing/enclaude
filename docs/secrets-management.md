# Secrets Management

## Current: Volume-Based (Single User)

Claude Code credentials are stored in the `enclaude-config` named Docker volume,
mounted at `/home/claude/.claude` inside the container. On first run, `claude`
prompts for OAuth authentication. Credentials persist in the volume across
sessions — you only need to authenticate once (until the token expires).

This is appropriate for local, single-user use. Credentials never touch the
image or the repo.

## First-Time Setup

1. Run `bash scripts/setup/start.sh` (or `start.bat` on Windows)
2. Inside the container, run `claude`
3. Complete the OAuth flow in your browser
4. Credentials are saved automatically to the volume

To force re-authentication, remove the config volume:

```bash
docker volume rm enclaude-config
```

---

## What the credential file contains

The `~/.claude/.credentials.json` file is written by Claude Code during OAuth
authentication. It contains your session token. Treat it like a password —
gitignore it, don't log it, don't bind-mount it from a world-readable location.

---

## Future: External Secrets Managers

The following integrations are planned for multi-user deployments but are not
yet implemented. They are included here as reference material.

---

### Option A: Docker Secrets

Native to Docker Compose, no extra tooling required. Credentials live in
`secrets/<username>/credentials.json` on the host, gitignored.

See [multi-user-deployment.md](multi-user-deployment.md) for the planned session
flow that uses Docker Secrets for per-user credential injection.

---

### Option B: HashiCorp Vault

Good fit if you're already running Vault locally or in your infrastructure.

**`Dockerfile`** — add `vault` to the image:
```dockerfile
RUN curl -fsSL https://releases.hashicorp.com/vault/1.17.0/vault_1.17.0_linux_amd64.zip \
    -o /tmp/vault.zip && unzip /tmp/vault.zip -d /usr/local/bin && rm /tmp/vault.zip
```

**`.env`** (gitignored):
```bash
VAULT_ADDR=http://your-vault-host:8200
VAULT_TOKEN=your-token
```

**`docker-entrypoint.sh`** — add before `exec "$@"`:
```bash
if [ -n "${VAULT_ADDR:-}" ] && [ -n "${VAULT_TOKEN:-}" ]; then
    mkdir -p /home/claude/.claude
    vault kv get -field=value secret/claude-credentials \
        > /home/claude/.claude/.credentials.json
    chmod 600 /home/claude/.claude/.credentials.json
fi
```

---

### Option C: Bitwarden Secrets Manager

Good fit if you already use Bitwarden. Uses the `bws` CLI.

**`Dockerfile`** — add `bws` to the image:
```dockerfile
RUN curl -fsSL https://github.com/bitwarden/sdk/releases/latest/download/bws-x86_64-unknown-linux-gnu.zip \
    -o /tmp/bws.zip && unzip /tmp/bws.zip -d /usr/local/bin && rm /tmp/bws.zip
```

**`.env`** (gitignored):
```bash
BWS_ACCESS_TOKEN=your-access-token
CLAUDE_SECRET_ID=your-secret-uuid
```

**`docker-entrypoint.sh`** — add before `exec "$@"`:
```bash
if [ -n "${BWS_ACCESS_TOKEN:-}" ] && [ -n "${CLAUDE_SECRET_ID:-}" ]; then
    mkdir -p /home/claude/.claude
    bws secret get "$CLAUDE_SECRET_ID" \
        | jq -r '.value' \
        > /home/claude/.claude/.credentials.json
    chmod 600 /home/claude/.claude/.credentials.json
fi
```
