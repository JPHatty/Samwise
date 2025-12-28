# Environment Variable Mapping (LOCAL vs CLOUD)

## Purpose
**DEFINITIVE** mapping of all environment variables to LOCAL or CLOUD execution targets.

**PRINCIPLE:** LOCAL variables control Docker services. CLOUD variables connect to external providers via HTTP APIs.

---

## LOCAL Services (Docker Compose)

### Traefik (Ingress Control Plane)

| Variable | Required | Default | Purpose | Validation |
|----------|----------|---------|---------|------------|
| `TRAEFIK_DASHBOARD_INSECURE` | No | `false` | Enable dashboard without TLS | Boolean: `true`\|`false` |
| `TRAEFIK_LOG_LEVEL` | No | `INFO` | Logging verbosity | Enum: `DEBUG`, `INFO`, `WARN`, `ERROR` |

**Service:** traefik (profile: `core`, `ingress`)
**Networks:** samwise-ingress, samwise-internal

---

### N8N (Orchestration Control Plane)

| Variable | Required | Default | Purpose | Validation |
|----------|----------|---------|---------|------------|
| `N8N_BASIC_AUTH_ACTIVE` | No | `true` | Enable basic auth | Boolean: `true`\|`false` |
| `N8N_BASIC_AUTH_USER` | Yes* | - | Admin username | *Required if basic auth enabled |
| `N8N_BASIC_AUTH_PASSWORD` | Yes* | - | Admin password | *Required if basic auth enabled |
| `N8N_HOST` | No | `localhost` | Public hostname | FQDN or IP |
| `N8N_PORT` | No | `5678` | HTTP port | 1024-65535 |
| `N8N_PROTOCOL` | No | `http` | Connection protocol | Enum: `http`, `https` |
| `N8N_ENCRYPTION_KEY` | **YES** | - | Credential encryption | 32+ character random string |
| `N8N_WEBHOOK_URL` | **YES** | - | Webhook base URL | Full URL: `https://n8n.example.com` |
| `N8N_EDITOR_BASE_URL` | No | - | Editor UI base URL | Full URL: `https://n8n.example.com` |
| `N8N_LOG_LEVEL` | No | `info` | Logging verbosity | Enum: `trace`, `debug`, `info`, `warn`, `error` |
| `N8N_LOG_OUTPUT` | No | `console` | Log destination | Enum: `console`, `file` |
| `N8N_METRICS` | No | `false` | Enable metrics endpoint | Boolean: `true`\|`false` |

**Service:** n8n (profile: `core`, `workflows`)
**Network:** samwise-internal

---

### Redis (Ephemeral Cache)

| Variable | Required | Default | Purpose | Validation |
|----------|----------|---------|---------|------------|
| `REDIS_PASSWORD` | **YES** | - | Redis authentication | 16+ character random string |

**Service:** redis (profile: `core`, `state`)
**Network:** samwise-internal
**Note:** Ephemeral cache, data wiped on restart

---

### N8N-MCP (Model Context Protocol Server)

| Variable | Required | Default | Purpose | Validation |
|----------|----------|---------|---------|------------|
| `N8N_MCP_PORT` | No | `3000` | MCP server port | 1024-65535 |
| `N8N_WEBHOOK_URL` | **YES** | - | n8n webhook URL | Inherited from N8N |
| `MCP_LOG_LEVEL` | No | `info` | Logging verbosity | Enum: `debug`, `info`, `warn`, `error` |

**Service:** n8n-mcp (profile: `mcp`, `workflows`)
**Network:** samwise-internal

---

### N8N-Workflows-MCP (Workflow Discovery MCP)

| Variable | Required | Default | Purpose | Validation |
|----------|----------|---------|---------|------------|
| `N8N_WORKFLOWS_MCP_PORT` | No | `3001` | MCP server port | 1024-65535 |
| `WORKFLOWS_PATH` | No | `/workflows` | Workflow mount path | Absolute path |
| `N8N_API_URL` | No | `http://n8n:5678` | n8n API endpoint | Internal URL |
| `N8N_API_KEY` | **YES** | - | n8n API key | n8n-generated API key |
| `MCP_LOG_LEVEL` | No | `info` | Logging verbosity | Enum: `debug`, `info`, `warn`, `error` |

**Service:** n8n-workflows-mcp (profile: `mcp`, `workflows`)
**Network:** samwise-internal

---

### Desktop-Commander (Local Execution Interface)

| Variable | Required | Default | Purpose | Validation |
|----------|----------|---------|---------|------------|
| `COMMANDER_PORT` | No | `3002` | Commander API port | 1024-65535 |
| `COMMANDER_LOG_LEVEL` | No | `info` | Logging verbosity | Enum: `debug`, `info`, `warn`, `error` |

**Service:** desktop-commander (profile: `utilities`, `local`)
**Network:** samwise-internal
**Note:** Stub only, no actual execution capabilities

---

### Tailscale (VPN Sidecar)

| Variable | Required | Default | Purpose | Validation |
|----------|----------|---------|---------|------------|
| `TS_AUTHKEY` | **YES** | - | Tailscale auth key | `tskey-auth-<key>` |
| `TS_EXTRA_ARGS` | No | `--advertise-exit-node` | Additional args | Tailscale CLI flags |
| `TS_LOG_LEVEL` | No | `info` | Logging verbosity | Enum: `debug`, `info`, `warn`, `error` |

**Service:** tailscale (profile: `networking`, `vpn`)
**Network:** samwise-internal + Tailscale mesh
**Note:** Optional, provides secure tunnel access

---

## CLOUD Services (HTTP API Connections)

### PostgreSQL (Supabase)

**Provider:** Supabase (PostgreSQL 16 + pgvector)
**Pricing:** Free tier available
**Documentation:** https://supabase.com/docs

| Variable | Required | Default | Purpose | Format |
|----------|----------|---------|---------|--------|
| `SUPABASE_URL` | **YES** | - | Supabase project URL | `https://xxxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | **YES** | - | Anonymous API key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| `SUPABASE_SERVICE_KEY` | **YES** | - | Service role key (admin) | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| `SUPABASE_DB` | **YES** | `postgresql` | Database driver | `postgresql` |
| `SUPABASE_HOST` | **YES** | - | Database host | `xxxxx.supabase.co` |
| `SUPABASE_PORT` | No | `5432` | Database port | `5432` |
| `SUPABASE_USER` | **YES** | `postgres` | Database user | `postgres` |
| `SUPABASE_PASSWORD` | **YES** | - | Database password | Database password |

**Connection String:**
```
postgresql://${SUPABASE_USER}:${SUPABASE_PASSWORD}@${SUPABASE_HOST}:${SUPABASE_PORT}/${SUPABASE_DB}
```

**Failure Mode:** FAIL FAST - Database required for persistence

---

### Qdrant (Northflank or Fly.io)

**Provider:** Northflank (Qdrant v1.7) or Fly.io
**Pricing:** Free tier available
**Documentation:** https://qdrant.tech/documentation

| Variable | Required | Default | Purpose | Format |
|----------|----------|---------|---------|--------|
| `QDRANT_URL` | **YES** | - | Qdrant API endpoint | `https://qdrant.example.com` |
| `QDRANT_API_KEY` | **YES** | - | Qdrant API key | API key string |
| `QDRANT_COLLECTION` | No | `samwise` | Default collection | Collection name |

**HTTP API Usage:**
```bash
curl -X GET ${QDRANT_URL}/collections/${QDRANT_COLLECTION} \
  -H "api-key: ${QDRANT_API_KEY}"
```

**Failure Mode:** FAIL FAST - Vector search required for RAG

---

### Meilisearch (Northflank)

**Provider:** Northflank (Meilisearch v1.5)
**Pricing:** Free tier available
**Documentation:** https://docs.meilisearch.com

| Variable | Required | Default | Purpose | Format |
|----------|----------|---------|---------|--------|
| `MEILISEARCH_HOST` | **YES** | - | Meilisearch API endpoint | `https://meilisearch.example.com` |
| `MEILISEARCH_API_KEY` | **YES** | - | Master API key | Master key string |

**HTTP API Usage:**
```bash
curl -X GET ${MEILISEARCH_HOST}/indexes \
  -H "Authorization: Bearer ${MEILISEARCH_API_KEY}"
```

**Failure Mode:** DEGRADED - Fallback to PostgreSQL text search

---

### MinIO (Cloudflare R2)

**Provider:** Cloudflare R2 (S3-compatible)
**Pricing:** Free tier available (10GB storage, 10M Class A operations/month)
**Documentation:** https://developers.cloudflare.com/r2

| Variable | Required | Default | Purpose | Format |
|----------|----------|---------|---------|--------|
| `R2_ENDPOINT` | **YES** | - | R2 API endpoint | `https://<accountid>.r2.cloudflarestorage.com` |
| `R2_ACCESS_KEY_ID` | **YES** | - | R2 access key | Access key ID |
| `R2_SECRET_ACCESS_KEY` | **YES** | - | R2 secret key | Secret access key |
| `R2_BUCKET` | **YES** | - | R2 bucket name | Bucket name |
| `R2_REGION` | No | `auto` | R2 region | `auto` |

**S3-Compatible Client Usage:**
```javascript
const s3 = new S3Client({
  endpoint: R2_ENDPOINT,
  region: R2_REGION,
  credentials: {
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
  },
});
```

**Failure Mode:** FAIL FAST - Object storage required

---

### Grafana (Northflank)

**Provider:** Northflank (Grafana)
**Pricing:** Free tier available
**Documentation:** https://grafana.com/docs

| Variable | Required | Default | Purpose | Format |
|----------|----------|---------|---------|--------|
| `GRAFANA_URL` | **YES** | - | Grafana UI URL | `https://grafana.example.com` |
| `GRAFANA_API_KEY` | **YES** | - | Grafana API key | API key string |

**Failure Mode:** OPTIONAL - Metrics unavailable, log warning

---

### Prometheus (Northflank)

**Provider:** Northflank (Prometheus)
**Pricing:** Free tier available
**Documentation:** https://prometheus.io/docs

| Variable | Required | Default | Purpose | Format |
|----------|----------|---------|---------|--------|
| `PROMETHEUS_URL` | **YES** | - | Prometheus API endpoint | `https://prometheus.example.com` |
| `PROMETHEUS_API_KEY` | **YES** | - | Prometheus API key | API key string |

**Failure Mode:** OPTIONAL - Metrics unavailable, log warning

---

### Loki (Northflank)

**Provider:** Northflank (Loki)
**Pricing:** Free tier available
**Documentation:** https://grafana.com/docs/loki/latest

| Variable | Required | Default | Purpose | Format |
|----------|----------|---------|---------|--------|
| `LOKI_URL` | **YES** | - | Loki API endpoint | `https://loki.example.com` |
| `LOKI_API_KEY` | **YES** | - | Loki API key | API key string |
| `LOKI_USERNAME` | No | - | Loki username (if auth) | Username |
| `LOKI_PASSWORD` | No | - | Loki password (if auth) | Password |

**Failure Mode:** OPTIONAL - Logs to stdout only

---

### LiveKit (Fly.io or Koyeb)

**Provider:** Fly.io or Koyeb (LiveKit)
**Pricing:** Free tier available
**Documentation:** https://docs.livekit.io

| Variable | Required | Default | Purpose | Format |
|----------|----------|---------|---------|--------|
| `LIVEKIT_URL` | **YES** | - | LiveKit API endpoint | `https://livekit.example.com` |
| `LIVEKIT_API_KEY` | **YES** | - | LiveKit API key | API key string |
| `LIVEKIT_API_SECRET` | **YES** | - | LiveKit API secret | API secret string |

**Failure Mode:** FAIL FAST - Media features unavailable

---

## .env.example Structure

```bash
# ============================================================
# LOCAL SERVICES (Docker Compose - Traefik, N8N, Redis)
# ============================================================

# Traefik
TRAEFIK_DASHBOARD_INSECURE=false
TRAEFIK_LOG_LEVEL=INFO

# N8N
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=changeme
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_ENCRYPTION_KEY=changemechangemechangemechangeme
N8N_WEBHOOK_URL=http://localhost:5678
N8N_EDITOR_BASE_URL=http://localhost:5678
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=console
N8N_METRICS=false

# Redis
REDIS_PASSWORD=changemechangeme

# N8N-MCP
N8N_MCP_PORT=3000
MCP_LOG_LEVEL=info

# N8N-Workflows-MCP
N8N_WORKFLOWS_MCP_PORT=3001
WORKFLOWS_PATH=/workflows
N8N_API_URL=http://n8n:5678
N8N_API_KEY=your_n8n_api_key_here
MCP_LOG_LEVEL=info

# Desktop-Commander
COMMANDER_PORT=3002
COMMANDER_LOG_LEVEL=info

# Tailscale
TS_AUTHKEY=tskey-auth-<your-tailscale-key>
TS_EXTRA_ARGS=--advertise-exit-node
TS_LOG_LEVEL=info

# ============================================================
# CLOUD SERVICES (HTTP API Connections)
# ============================================================

# Supabase (PostgreSQL + pgvector)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_DB=postgresql
SUPABASE_HOST=xxxxx.supabase.co
SUPABASE_PORT=5432
SUPABASE_USER=postgres
SUPABASE_PASSWORD=your_supabase_password

# Qdrant (Northflank or Fly.io)
QDRANT_URL=https://qdrant.example.com
QDRANT_API_KEY=your_qdrant_api_key
QDRANT_COLLECTION=samwise

# Meilisearch (Northflank)
MEILISEARCH_HOST=https://meilisearch.example.com
MEILISEARCH_API_KEY=your_meilisearch_master_key

# Cloudflare R2 (S3-compatible object storage)
R2_ENDPOINT=https://<accountid>.r2.cloudflarestorage.com
R2_ACCESS_KEY_ID=your_r2_access_key_id
R2_SECRET_ACCESS_KEY=your_r2_secret_access_key
R2_BUCKET=samwise
R2_REGION=auto

# Grafana (Northflank)
GRAFANA_URL=https://grafana.example.com
GRAFANA_API_KEY=your_grafana_api_key

# Prometheus (Northflank)
PROMETHEUS_URL=https://prometheus.example.com
PROMETHEUS_API_KEY=your_prometheus_api_key

# Loki (Northflank)
LOKI_URL=https://loki.example.com
LOKI_API_KEY=your_loki_api_key
LOKI_USERNAME=your_loki_username
LOKI_PASSWORD=your_loki_password

# LiveKit (Fly.io or Koyeb)
LIVEKIT_URL=https://livekit.example.com
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_api_secret
```

---

## Validation Rules

### LOCAL Variables
- **Validation:** Checked by Docker Compose on startup
- **Failure Mode:** Service fails to start if required variable missing
- **Recovery:** Operator must add missing variable to .env and restart

### CLOUD Variables
- **Validation:** Checked by n8n workflows at runtime (HTTP connection test)
- **Failure Mode:** Workflow fails with clear error message
- **Recovery:** Operator must provision cloud service and add credentials to .env

---

## Security Rules

### Prohibited in .env
- **NEVER commit .env to git** (already in .gitignore)
- **NEVER share API keys or secrets** in plaintext
- **NEVER use production keys in development**

### Required Key Strength
- `N8N_ENCRYPTION_KEY`: 32+ characters, random
- `REDIS_PASSWORD`: 16+ characters, random
- `SUPABASE_PASSWORD`: 16+ characters, random
- All cloud API keys: Use provider-generated keys

### Key Rotation
- Cloud API keys: Rotate per provider recommendations
- Local service keys: Rotate every 90 days
- N8N encryption key: **DO NOT ROTATE** (breaks credential decryption)

---

## Quick Reference

### LOCAL Services Start Command
```bash
docker compose --profile core up
# Starts: traefik, n8n, redis
# Requires: LOCAL variables only
```

### CLOUD Services Provisioning
```bash
# Manual provisioning required:
# 1. Create Supabase project → Get SUPABASE_* variables
# 2. Create Northflank Qdrant → Get QDRANT_* variables
# 3. Create Northflank Meilisearch → Get MEILISEARCH_* variables
# 4. Create Cloudflare R2 bucket → Get R2_* variables
# 5. (Optional) Create Northflank observability stack → Get GRAFANA_*, PROMETHEUS_*, LOKI_* variables
# 6. (Optional) Create Fly.io LiveKit → Get LIVEKIT_* variables
```

### Full Stack Activation
```bash
# LOCAL (Docker)
docker compose --profile core up
docker compose --profile workflows up
docker compose --profile vpn up

# CLOUD (HTTP API connections)
# Ensure all CLOUD variables are set in .env
# n8n workflows will validate connections at runtime
```

---

## Troubleshooting

### Symptom: Service fails to start
**Cause:** Missing required LOCAL variable
**Fix:** Check .env, add missing variable, restart service

### Symptom: n8n workflow fails with "connection refused"
**Cause:** Missing or invalid CLOUD variable
**Fix:**
1. Check cloud service is running
2. Verify API credentials in .env
3. Test connection: `curl ${CLOUD_SERVICE_URL}`

### Symptom: "invalid credentials" error
**Cause:** Incorrect API key or secret
**Fix:** Regenerate API key in cloud provider console, update .env

### Symptom: "timeout connecting to service"
**Cause:** Network firewall or incorrect endpoint URL
**Fix:**
1. Verify endpoint URL is correct
2. Check firewall allows outbound HTTPS
3. Test with curl from n8n container

---

## Appendix: Provider Setup Links

- **Supabase:** https://supabase.com/dashboard (create project → Settings → API)
- **Northflank:** https://northflank.com (create services → Qdrant, Meilisearch, Grafana, Prometheus, Loki)
- **Cloudflare R2:** https://dash.cloudflare.com/ (R2 → Create bucket → API tokens)
- **Fly.io:** https://fly.io/dashboard (create Qdrant or LiveKit service)
- **Tailscale:** https://login.tailscale.com/admin/settings/keys (generate auth key)
