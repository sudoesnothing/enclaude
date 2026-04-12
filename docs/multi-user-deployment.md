> **Status: Planned — Not Yet Implemented**
>
> This document describes the planned multi-user deployment model for a future
> release. It is not currently functional. Enclaude currently supports
> single-user mode only. See the main [README](../README.md) for usage.

---

# Multi-User Deployment

This guide covers running Enclaude as a shared team environment. Each user
gets an isolated, ephemeral container with their own workspace volume, credentials,
and network. Containers are created on session start and removed on exit — volumes
persist so work is not lost between sessions.

---

## Prerequisites

- Docker Engine 24+ or Docker Desktop 4.20+
- Docker Compose v2 (`docker compose`, not `docker-compose`)
- Host running Linux, macOS, or Windows (WSL2)
- One set of Claude Code credentials per user (OAuth flow, see below)

---

## Architecture Overview

```
Host machine
├── secrets/
│   ├── alice/credentials.json   ← gitignored, injected at runtime
│   └── bob/credentials.json
│
├── docker-compose.yml           ← base: hardened container config
└── docker-compose.session.yml   ← per-user: volumes, networks, secrets

Per-user Docker resources (created on first session, persist after)
├── Volume: enclaude-workspace-<username>   ← /workspace inside container
├── Volume: enclaude-config-<username>      ← /home/claude/.claude
└── Network: enclaude-net-<username>        ← isolated per user
```

---

## Onboarding a New User

### Step 1 — Create the secrets directory

```bash
mkdir -p secrets/<username>
```

### Step 2 — First-time authentication

On first run there are no credentials yet, so start the container manually and
complete the OAuth flow inside:

```bash
export SESSION_USER=<username>
docker compose -f docker-compose.yml -f docker-compose.session.yml up -d
docker exec -it enclaude-<username> bash
```

Inside the container:

```bash
claude
# Follow the browser OAuth flow
# Credentials are written to /home/claude/.claude/.credentials.json
exit
```

### Step 3 — Export credentials to the host

```bash
docker cp enclaude-<username>:/home/claude/.claude/.credentials.json \
    secrets/<username>/credentials.json
```

### Step 4 — Stop the bootstrap container

```bash
export SESSION_USER=<username>
docker compose -f docker-compose.yml -f docker-compose.session.yml down
```

### Step 5 — All future sessions

```bash
bash scripts/setup/start-session.sh <username>
```

Credentials are injected automatically. No interactive auth needed until the token expires.

---

## Running Sessions

```bash
# Start a session
bash scripts/setup/start-session.sh alice

# In a separate terminal, start another session concurrently
bash scripts/setup/start-session.sh bob
```

Each session gets:
- Its own container (`enclaude-alice`, `enclaude-bob`)
- Its own workspace volume (data persists across sessions)
- Its own network (no cross-user traffic)
- Its own credentials (injected from `secrets/<username>/credentials.json`)

On shell exit, the container is removed. Volumes remain.

---

## Revoking a User

```bash
# Remove credentials (prevents future sessions)
rm -rf secrets/<username>

# Optionally destroy their workspace data (irreversible)
docker volume rm enclaude-workspace-<username>
docker volume rm enclaude-config-<username>
```

---

## Resource Limits

Default limits are set in `.env` and apply per container:

```bash
SANDBOX_MEMORY_LIMIT=8g
SANDBOX_CPU_LIMIT=4
```

To give a specific user different limits, add an override in
`docker-compose.override.yml` scoped to their container name, or pass environment
variables inline:

```bash
SANDBOX_MEMORY_LIMIT=16g SANDBOX_CPU_LIMIT=8 \
    bash scripts/setup/start-session.sh alice
```

---

## Network Egress Restriction (Optional)

By default, containers can reach the internet freely. Claude Code only needs to
reach Anthropic's API (`api.anthropic.com`). To restrict outbound to an allowlist:

### Step 1 — Set the per-user network to internal

In `docker-compose.session.yml`:
```yaml
networks:
  enclaude-net-${SESSION_USER}:
    driver: bridge
    internal: true    # blocks all external routing
```

### Step 2 — Add an egress proxy sidecar

Add a Caddy or Squid proxy container to `docker-compose.session.yml` that:
- Is connected to both the internal per-user network and an external network
- Allowlists only `api.anthropic.com:443`
- All other outbound is blocked by the internal network flag

Example Caddy forward-proxy config:
```
{
  order forward_proxy before reverse_proxy
}

:3128 {
  forward_proxy {
    acl {
      allow host api.anthropic.com
      deny all
    }
  }
}
```

Set `HTTPS_PROXY=http://proxy:3128` in the container environment and point
Claude Code at it.

---

## Security Posture Summary

| Control | v1 (single-user) | v2 (multi-user) |
|---|---|---|
| Non-root user | Yes | Yes |
| No sudo | No (passwordless sudo) | Yes (sudo removed) |
| no-new-privileges | No | Yes |
| cap_drop ALL | No | Yes |
| Seccomp profile | No | Yes (custom) |
| Read-only root fs | No | Yes + tmpfs overlays |
| Per-user isolation | N/A | Yes (volumes + networks) |
| Credential injection | Volume mount | Docker Secrets |
| Egress filtering | No | Optional (see above) |

---

## Comparison: Why Not Firecracker or Kubernetes?

**Firecracker** (used by AWS Lambda, Modal, Fly.io) provides hardware-level VM
isolation between untrusted tenants. It's the right choice when you cannot trust
the workload — e.g., running arbitrary user-submitted code from the internet.

**This setup** is for a known, trusted team running Claude Code. The threat model
is accidental data leakage between users and runaway resource consumption — both
addressed by per-user containers, volumes, and limits. Docker + seccomp + no
capabilities is appropriate for this use case and is operationally simpler.

If your requirements change (external users, arbitrary code execution, compliance
requirements), Firecracker or a managed sandbox service (E2B, Modal) is the
natural upgrade path.
