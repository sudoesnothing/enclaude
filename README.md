# Enclaude

An ephemeral Docker sandbox for running [Claude Code](https://claude.ai/code) in isolation.

Each session runs in a fresh container that is torn down on exit. Workspace data
persists across sessions in named Docker volumes, so your work is never lost.
Your host filesystem stays clean: *no bind mounts, no Docker socket access*.

> Previously released as [claude-code-sandbox](https://github.com/sudoesnothing/claude-code-sandbox). That repo is archived for historical reference.

---

## What's Included

- **Ubuntu 24.04** with sudo access
- **Node.js 22 LTS**
- **Claude Code CLI** (latest)
- **git**, curl
- **VS Code Dev Containers** support

---

## Prerequisites

| Requirement | Notes |
|---|---|
| [Docker](https://docs.docker.com/get-docker/) Engine 24+ or Docker Desktop 4.20+ | Required |
| Docker Compose v2 (`docker compose`, not `docker-compose`) | Included with Docker Desktop |
| [VS Code](https://code.visualstudio.com/) + [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) | Optional |

---

## Quick Start

### Linux / macOS

```bash
git clone https://github.com/sudoesnothing/enclaude.git
cd enclaude
bash scripts/setup/start.sh
```

### Windows

```
git clone https://github.com/sudoesnothing/enclaude.git
cd enclaude
start.bat
```

On first run, the image is built automatically. Inside the container:

```bash
claude          # complete the OAuth flow in your browser
```

Credentials are saved in a Docker volume and persist across sessions. You only
need to authenticate once (until the token expires).

Type `exit` to end the session. The container is removed; your workspace and
credentials are preserved in Docker volumes.

---

## VS Code Dev Containers

```
F1 -> Dev Containers: Reopen in Container
```

Or attach to a running container:

```
F1 -> Dev Containers: Attach to Running Container -> enclaude
```

---

## How It Works

| Component | Detail |
|---|---|
| Base image | Ubuntu 24.04 |
| Runtime | Node.js 22 LTS |
| Container user | `claude` (UID 1001) with passwordless sudo |
| Workspace volume | `enclaude-workspace` mounted at `/workspace` |
| Config volume | `enclaude-config` mounted at `/home/claude/.claude` |
| Lifecycle | Container created on start, removed on exit |
| Data persistence | Volumes survive container teardown |

---

## Installing Packages

The container user has sudo access for installing tools during a session:

```bash
sudo apt-get update && sudo apt-get install -y python3
```

Packages installed this way are ephemeral. *They exist only for the current
session.* To make packages **permanent**, add them to the `Dockerfile` and rebuild.

---

## Configuration

Copy `.env.example` to `.env` to adjust resource limits:

```bash
cp .env.example .env
```

| Variable | Default | Description |
|---|---|---|
| `SANDBOX_MEMORY_LIMIT` | `8g` | Container memory cap |
| `SANDBOX_CPU_LIMIT` | `4` | vCPU count |

---

## Security

This is a personal development tool, not an enterprise security product. The
goal is reasonable isolation from the host, not defense against a hostile
workload.

| Control | Status |
|---|---|
| Non-root user (`claude`, UID 1001) | Yes |
| Sudo available | Yes — single-user, ephemeral container |
| `no-new-privileges` | No — requires setuid for sudo; planned for multi-user mode where sudo is removed |
| Docker default seccomp profile | Yes |
| No host filesystem bind mounts | Yes |
| No Docker socket access | Yes |
| Named volumes only | Yes |
| Resource limits (memory + CPU) | Yes |

---

## Volumes

| Volume | Purpose |
|---|---|
| `enclaude-workspace` | Workspace data at `/workspace` |
| `enclaude-config` | Claude Code credentials and config |

To reset your workspace completely:

```bash
docker volume rm enclaude-workspace
```

To reset credentials (will require re-authentication):

```bash
docker volume rm enclaude-config
```

---

## FAQ

**Why not just use VS Code Dev Containers?**

Dev Containers are great - *Enclaude even supports them*. But Enclaude is
CLI-first and IDE-agnostic: it works from any terminal without VS Code.
Containers are also ephemeral by default (removed on exit), which Dev
Containers are not. And everything is purpose-built for Claude Code — volumes,
entrypoint, auth persistence — so there's nothing to configure.

**Is this secure enough?**

For personal use, yes. Enclaude isolates Claude Code from your host filesystem,
blocks Docker socket access, and enforces resource limits. It is not designed
to contain a hostile workload or meet enterprise compliance requirements - *yet*. It's
a development tool for individual developers who want reasonable guardrails.
See the [Roadmap](#roadmap) for planned hardening (seccomp, egress filtering).

---

## Roadmap

Planned features for future releases:

- **Multi-user sessions** | per-user containers, volumes, networks, and credential injection. See [docs/multi-user-deployment.md](docs/multi-user-deployment.md) for the planned design.
- **Custom seccomp profile** | restrict syscalls to only what Claude Code needs
- **Egress filtering** | proxy sidecar to allowlist only `api.anthropic.com`
- **External secrets managers** | Vault, Bitwarden integration. See [docs/secrets-management.md](docs/secrets-management.md).
