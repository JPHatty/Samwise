# Execution Boundary Matrix

## Purpose
**DEFINITIVE** mapping of where each service runs: LOCAL or CLOUD.

**PRINCIPLE:** Local Docker is CONTROL PLANE ONLY. State and compute live in cloud free tiers.

---

## Service Classification Matrix

| Service | Execution | Location | Provider | WHY | Failure Mode |
|---------|-----------|----------|----------|-----|--------------|
| **traefik** | LOCAL | Docker | - | Reverse proxy for local orchestration only | **CRITICAL** - System unusable without it |
| **n8n** | LOCAL | Docker | - | Orchestration UI and workflow execution control plane | **CRITICAL** - System unusable without it |
| **n8n-mcp** | LOCAL | Docker | - | Model Context Protocol server for n8n | **OPTIONAL** - Warning if missing |
| **n8n-workflows-mcp** | LOCAL | Docker | - | Workflow discovery MCP server | **OPTIONAL** - Warning if missing |
| **redis** | LOCAL | Docker | - | Ephemeral state cache (optional) | **DEGRADED** - Continue without cache |
| **desktop-commander** | LOCAL | Docker | - | Local execution interface stub | **OPTIONAL** - Warning if missing |
| **postgresql** | CLOUD | Supabase | PostgreSQL + pgvector | Persistent vector database, requires managed backups | **FAIL FAST** - Halt if unavailable |
| **qdrant** | CLOUD | Northflank / Fly.io | Vector DB | Vector similarity search, heavy compute | **FAIL FAST** - Halt if unavailable |
| **meilisearch** | CLOUD | Northflank | Full-text search | Search index, heavy compute | **DEGRADED** - Fallback to PostgreSQL text search |
| **minio** | CLOUD | Cloudflare R2 | Object storage | S3-compatible storage, CDN-backed | **FAIL FAST** - Halt if unavailable |
| **grafana** | CLOUD | Northflank | Metrics dashboard | Observability UI (read-only) | **OPTIONAL** - Log warning, continue |
| **prometheus** | CLOUD | Northflank | Metrics storage | Time-series metrics database | **OPTIONAL** - Log warning, continue |
| **loki** | CLOUD | Northflank | Log aggregation | Log storage and query | **OPTIONAL** - Log to stdout only |
| **tailscale** | LOCAL | Docker | Tailscale | VPN sidecar for secure tunnel | **OPTIONAL** - Continue without VPN |
| **livekit** | CLOUD | Fly.io / Koyeb | Media workers | Real-time media processing | **FAIL FAST** - Media features unavailable |

---

## Execution Rules

### LOCAL Services (Control Plane)

**Allowed to run in Docker:**
- `traefik` - Reverse proxy for local n8n UI
- `n8n` - Orchestration UI and workflow trigger
- `n8n-mcp` - Model Context Protocol server
- `n8n-workflows-mcp` - Workflow discovery
- `redis` - Ephemeral state cache (optional, can be disabled)
- `desktop-commander` - Local execution stub
- `tailscale` - VPN sidecar

**Constraints:**
- MUST use `profile: core` or `profile: workflows` or `profile: networking`
- MUST NOT store persistent state (except Redis, which is ephemeral)
- MUST NOT run compute-heavy workloads
- MUST NOT be exposed to public internet (behind Tailscale VPN only)

**Activation:**
```bash
docker compose --profile core up  # traefik, n8n, redis
docker compose --profile workflows up  # n8n, n8n-mcp, n8n-workflows-mcp
docker compose --profile vpn up  # tailscale
```

### CLOUD Services (State + Compute)

**FORBIDDEN to run in local Docker:**
- `postgresql` - Use Supabase cloud PostgreSQL
- `qdrant` - Use Northflank or Fly.io Qdrant cloud
- `meilisearch` - Use Northflank Meilisearch cloud
- `minio` - Use Cloudflare R2 object storage
- `grafana` - Use Northflank Grafana cloud
- `prometheus` - Use Northflank Prometheus cloud
- `loki` - Use Northflank Loki cloud
- `livekit` - Use Fly.io or Koyeb LiveKit cloud

**Constraints:**
- MUST be marked `profile: cloud-stub` in compose.yaml
- MUST have `disabled: true` (documentation only)
- MUST have comment: "DO NOT RUN LOCALLY - USE [PROVIDER]"
- Local runs MUST fail validation

**Activation:**
```bash
# NEVER run locally
# These are managed externally (Supabase, Northflank, Fly.io, Cloudflare)
```

---

## Service Details

### LOCAL: traefik
- **Purpose:** Reverse proxy for local n8n UI
- **Resources:** 256M memory, 1.0 CPU
- **Exposure:** HTTP 80, HTTPS 443, Dashboard 8080
- **Network:** samwise-ingress (external), samwise-internal
- **Data:** ACME certificates (TLS)
- **Profile:** `ingress`, `core`
- **Why Local:** Only routes to local n8n, no public exposure
- **Failure Mode:** CRITICAL - System unusable without routing

### LOCAL: n8n
- **Purpose:** Orchestration UI and workflow control plane
- **Resources:** 2G memory, 2.0 CPU
- **Exposure:** HTTP 5678 (via Traefik)
- **Network:** samwise-internal
- **Data:** Workflow definitions (read-only from n8n/workflows)
- **Profile:** `core`, `workflows`
- **Why Local:** Control plane only, triggers cloud executions
- **Failure Mode:** CRITICAL - Cannot orchestrate without n8n

### LOCAL: n8n-mcp
- **Purpose:** Model Context Protocol server for n8n
- **Resources:** 256M memory, 0.5 CPU
- **Network:** samwise-internal
- **Data:** MCP server data (ephemeral)
- **Profile:** `mcp`, `workflows`
- **Why Local:** LLM interface for local n8n, low resource needs
- **Failure Mode:** OPTIONAL - Advanced LLM features unavailable

### LOCAL: n8n-workflows-mcp
- **Purpose:** Workflow discovery MCP server
- **Resources:** 256M memory, 0.5 CPU
- **Network:** samwise-internal
- **Data:** Workflow definitions (read-only mount)
- **Profile:** `mcp`, `workflows`
- **Why Local:** Exposes local workflows to LLMs
- **Failure Mode:** OPTIONAL - Manual workflow discovery required

### LOCAL: redis
- **Purpose:** Ephemeral state cache and message queue
- **Resources:** 512M memory, 1.0 CPU
- **Network:** samwise-internal
- **Data:** Redis dump (ephemeral, wiped on restart)
- **Profile:** `state`, `core`
- **Why Local:** Low-latency cache for orchestration, optional
- **Failure Mode:** DEGRADED - Continue without cache, performance impacted

### LOCAL: desktop-commander
- **Purpose:** Local execution interface stub
- **Resources:** 256M memory, 0.5 CPU
- **Network:** samwise-internal
- **Data:** Commander data (ephemeral)
- **Profile:** `utilities`, `local`
- **Why Local:** Interface to local Docker (read-only socket)
- **Failure Mode:** OPTIONAL - Manual command execution required

### LOCAL: tailscale
- **Purpose:** VPN sidecar for secure tunnel
- **Resources:** 256M memory, 0.5 CPU
- **Network:** samwise-internal + Tailscale mesh
- **Data:** Tailscale state (persistent)
- **Profile:** `networking`, `vpn`
- **Why Local:** Provides secure access to local n8n from anywhere
- **Failure Mode:** OPTIONAL - Local-only access without VPN

### CLOUD: postgresql
- **Purpose:** Primary database with pgvector extension
- **Provider:** Supabase (PostgreSQL 16 + pgvector)
- **Resources:** Cloud-managed (3GB memory, 2 CPU typically)
- **Data:** Persistent in cloud
- **Connection:** `SUPABASE_DB`, `SUPABASE_HOST`, `SUPABASE_PASSWORD`
- **Why Cloud:** Managed backups, automatic failover, pgvector extension
- **Failure Mode:** FAIL FAST - Database required for persistence
- **Stub Profile:** `cloud-stub` (documentation only in compose.yaml)

### CLOUD: qdrant
- **Purpose:** Vector similarity search database
- **Provider:** Northflank (Qdrant v1.7) or Fly.io
- **Resources:** Cloud-managed (4GB memory, 2 CPU typically)
- **Data:** Persistent in cloud
- **Connection:** `QDRANT_URL`, `QDRANT_API_KEY`
- **Why Cloud:** Heavy compute, requires persistent storage
- **Failure Mode:** FAIL FAST - Vector search required for RAG
- **Stub Profile:** `cloud-stub` (documentation only in compose.yaml)

### CLOUD: meilisearch
- **Purpose:** Full-text search engine
- **Provider:** Northflank (Meilisearch v1.5)
- **Resources:** Cloud-managed (2GB memory, 2 CPU typically)
- **Data:** Persistent in cloud
- **Connection:** `MEILISEARCH_HOST`, `MEILISEARCH_API_KEY`
- **Why Cloud:** Heavy compute, persistent indexes
- **Failure Mode:** DEGRADED - Fallback to PostgreSQL text search
- **Stub Profile:** `cloud-stub` (documentation only in compose.yaml)

### CLOUD: minio
- **Purpose:** S3-compatible object storage
- **Provider:** Cloudflare R2 (S3-compatible API)
- **Resources:** Cloud-managed (unlimited storage)
- **Data:** Persistent in cloud
- **Connection:** `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`
- **Why Cloud:** CDN-backed, unlimited storage, free tier
- **Failure Mode:** FAIL FAST - Object storage required
- **Stub Profile:** `cloud-stub` (documentation only in compose.yaml)

### CLOUD: grafana
- **Purpose:** Metrics visualization dashboard
- **Provider:** Northflank (Grafana)
- **Resources:** Cloud-managed
- **Data:** Cloud Prometheus data source
- **Connection:** `GRAFANA_URL`, `GRAFANA_API_KEY`
- **Why Cloud:** Read-only metrics, no local impact
- **Failure Mode:** OPTIONAL - Metrics unavailable, log warning
- **Stub Profile:** `cloud-stub` (documentation only in compose.yaml)

### CLOUD: prometheus
- **Purpose:** Metrics time-series database
- **Provider:** Northflank (Prometheus)
- **Resources:** Cloud-managed
- **Data:** Persistent in cloud
- **Connection:** `PROMETHEUS_URL`, `PROMETHEUS_API_KEY`
- **Why Cloud:** Heavy storage, long retention
- **Failure Mode:** OPTIONAL - Metrics unavailable, log warning
- **Stub Profile:** `cloud-stub` (documentation only in compose.yaml)

### CLOUD: loki
- **Purpose:** Log aggregation and query
- **Provider:** Northflank (Loki)
- **Resources:** Cloud-managed
- **Data:** Persistent in cloud
- **Connection:** `LOKI_URL`, `LOKI_API_KEY`
- **Why Cloud:** Heavy storage, log retention
- **Failure Mode:** OPTIONAL - Logs to stdout only
- **Stub Profile:** `cloud-stub` (documentation only in compose.yaml)

### CLOUD: livekit
- **Purpose:** Real-time media processing workers
- **Provider:** Fly.io or Koyeb
- **Resources:** Cloud-managed (auto-scaling)
- **Data:** Ephemeral in cloud
- **Connection:** `LIVEKIT_API_KEY`, `LIVEKIT_URL`
- **Why Cloud:** Heavy compute, requires global edge deployment
- **Failure Mode:** FAIL FAST - Media features unavailable
- **Stub Profile:** `cloud-stub` (documentation only in compose.yaml)

---

## Failure Modes Explained

### CRITICAL
System cannot function without this service.
**Action:** Halt immediately, emit CRITICAL RunRecord, require operator intervention.

### FAIL FAST
System can detect missing dependency early and halt cleanly.
**Action:** Halt at validation time, emit error RunRecord, provide clear error message.

### DEGRADED
System can continue with reduced functionality.
**Action:** Log warning, emit degraded RunRecord, continue with fallback behavior.

### OPTIONAL
Service provides enhanced features but is not required.
**Action:** Log info message, emit info RunRecord, continue normally.

---

## Boundary Enforcement Rules

### Rule 1: No Local State Persistence
Local services MUST NOT persist data between restarts (except Redis, which is ephemeral).

**Allowed:**
- Redis (ephemeral cache, wiped on restart)
- Tailscale (VPN state, non-critical)
- Traefik (ACME certificates, can be regenerated)

**Forbidden:**
- PostgreSQL running locally
- Qdrant running locally
- MinIO running locally
- Any database running locally

### Rule 2: No Local Compute for Stateful Operations
Heavy compute and stateful operations MUST run in cloud.

**Cloud-Only:**
- Vector similarity search (Qdrant)
- Full-text search indexing (Meilisearch)
- Object storage operations (MinIO/R2)
- Media processing (LiveKit)
- Metrics storage (Prometheus, Loki)

**Allowed Locally:**
- Orchestration logic (n8n workflows)
- MCP servers (n8n-mcp, n8n-workflows-mcp)
- Light caching (Redis)
- Routing (Traefik)

### Rule 3: Cloud Services Have Stubs in Compose
Cloud services MUST exist in compose.yaml as stubs for documentation, but MUST be disabled.

**Stub Format:**
```yaml
cloud-service:
  image: provider/image:tag
  profiles:
    - cloud-stub  # Special profile, never enabled
  disabled: true  # MUST be disabled
  environment:
    - CLOUD_PROVIDER_URL=${CLOUD_PROVIDER_URL}  # Document expected env var
    - CLOUD_PROVIDER_API_KEY=${CLOUD_PROVIDER_API_KEY}  # ID only
```

### Rule 4: ToolSpec MUST Declare execution_target
ToolSpecs generated by ToolForge MUST explicitly declare where they run.

**New Field in tool-spec.schema.json:**
```json
{
  "execution_target": {
    "mode": "cloud",
    "provider": "supabase",
    "region": "us-east-1",
    "service": "postgresql"
  }
}
```

**Validation:**
- If `execution_mode: "local"` → `execution_target` must be `null` or local
- If `execution_mode: "remote"` → `execution_target` MUST specify cloud provider
- LOCAL tools CANNOT reference cloud databases directly (must use HTTP APIs)
- CLOUD tools CANNOT assume Docker locality

---

## Dependency Graph

```
                    ┌──────────────────────────────────────────────────────────┐
                    │                    LOCAL                          │
                    │           (Control Plane - Docker)                │
                    └──────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────┴──────────────────────────────────────┐
                    │                                                       │
            ┌───────▼────────┐                                   ┌──────▼──────┐
            │     n8n        │                                   │  traefik   │
            │  (orchestrator) │◄───── routes ─────────────────────►│ (proxy)    │
            └───────┬────────┘                                   └──────┬──────┘
                    │                                                     │
        ┌───────────┼───────────┬───────────────┬────────────────────────────┐
        │           │           │               │                            │
   ┌────▼────┐ ┌───▼────┐ ┌────▼────┐   ┌─────▼─────┐  ┌──────────▼─────┐
   │ n8n-mcp │ │ redis  │ │desktop │   │tailscale │  │ ToolForge      │
   │  (MCP)  │ │(cache) │ │commander│   │  (VPN)   │  │ (orchestrator)│
   └────┬────┘ └───┬────┘ └────┬────┘   └───────────┘  └────────┬────────┘
        │          │         │
        └──────────┴─────────┴───────────────────────┬───────────────┘
                                                      │
                    ┌───────────────────────────────────┴───────────────┐
                    │               CLOUD (HTTP APIs only)             │
                    └──────────────────────────────────────────────────┘
                                        │
        ┌───────────────────┬───────────────┬───────────────┬───────────────┐
        │                   │               │               │               │
   ┌────▼────────┐  ┌─────▼──────┐  ┌───▼────────┐  ┌─────▼──────┐  ┌────▼─────┐
   │ Supabase   │  │ Northflank │  │ Cloudflare │  │ Northflank │  │ Fly.io  │
   │PostgreSQL  │  │ Qdrant     │  │ R2 (MinIO) │  │ Meilisearch│  │ LiveKit  │
   │ + pgvector │  │ + Meili... │  │            │  │ + Grafana..│  │          │
   └─────────────┘  └────────────┘  └────────────┘  └────────────┘  └──────────┘
```

**Key:**
- LOCAL = Solid lines (Docker)
- CLOUD = Dashed lines (HTTP APIs)
- Data flows: n8n → HTTP API → Cloud services
- NO direct Docker-to-Docker connections to cloud databases

---

## Activation Examples

### Start Local Control Plane
```bash
# Start core local services
docker compose --profile core up

# Services started: traefik, n8n, redis
# Services NOT started: postgresql, qdrant, meilisearch, minio, grafana, prometheus, loki, livekit
```

### Start VPN Access
```bash
# Start Tailscale VPN
docker compose --profile vpn up

# Service started: tailscale
# Access n8n UI at: https://n8n.tailnet-name.ts.net
```

### Start MCP Servers
```bash
# Start MCP servers
docker compose --profile workflows up

# Services started: n8n, n8n-mcp, n8n-workflows-mcp
```

### Attempt to Start Cloud Service (FORBIDDEN)
```bash
# This will fail validation
docker compose --profile cloud-stub up

# Error: Cloud services MUST NOT run locally
# Use managed providers: Supabase, Northflank, Fly.io, Cloudflare
```

---

## Validation Checklist

Before starting ANY local service:

- [ ] Service is in LOCAL list above
- [ ] Service uses `profile: core` or `profile: workflows` or `profile: networking`
- [ ] Service does NOT persist state (except Redis/Tailscale)
- [ ] Service is NOT compute-heavy (resource_class: `control` only)
- [ ] Service is NOT exposed to public internet (VPN only)

Before connecting to ANY cloud service:

- [ ] Service is in CLOUD list above
- [ ] Environment variables are set (Provider URL, API key)
- [ ] Service is NOT in compose.yaml `profiles` (except `cloud-stub`)
- [ ] Connection is via HTTP API (not Docker network)
- [ ] Fallback behavior is defined if unavailable
