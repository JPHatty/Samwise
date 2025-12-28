# Ports and Limits

## Purpose
Document all network ports, resource limits, and service quotas for samwise infrastructure.

## CONSTRAINTS-FIRST PRINCIPLE

**NO SERVICE MAY EXCEED DECLARED LIMITS**

All resource limits in this document are absolute ceilings. Docker Compose enforces these limits via `deploy.resources.limits`. If a service requires more resources, update this document AND compose.yaml BEFORE deployment.

## Service Activation

**All services are DISABLED by default.** Activation requires explicit profile selection:

```bash
# Example: Enable core infrastructure
docker compose --profile core up

# Example: Enable monitoring stack
docker compose --profile monitoring up

# Example: Enable multiple profiles
docker compose --profile core --profile database --profile monitoring up
```

See `.env.example` for complete profile listing.

---

## Port Allocation

### External (Host → Container)
| Port | Protocol | Service | Profile | Purpose |
|------|----------|---------|---------|---------|
| 80   | HTTP     | traefik | ingress | HTTP → HTTPS redirect |
| 443  | HTTPS    | traefik | ingress | Main ingress |
| 8080 | HTTP     | traefik | ingress | Traefik Dashboard |
| 5678 | HTTP     | n8n     | core/workflows | Workflow UI |
| 6333 | HTTP     | qdrant  | database/vector | REST API |
| 6334 | gRPC     | qdrant  | database/vector | gRPC API |
| 7700 | HTTP     | meilisearch | database/search | Search API |
| 9000 | HTTP     | minio   | storage | S3-compatible API |
| 9001 | HTTP     | minio   | storage | Web Console |
| 3001 | HTTP     | grafana | monitoring | Metrics Dashboard |
| 3100 | HTTP     | loki    | monitoring | Log Query API |
| 9090 | HTTP     | prometheus | monitoring | Metrics API |

### Internal (Docker Network)
| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 5432 | TCP      | postgresql | PostgreSQL database |
| 6379 | TCP      | redis | Cache/Queue |
| 3000 | HTTP     | n8n-mcp | MCP server stub |
| 3001 | HTTP     | n8n-workflows-mcp | Workflow MCP stub |
| 3002 | HTTP     | desktop-commander | Commander stub |
| 7880 | HTTP/WS  | livekit* | Media server (legacy) |
| 7881 | TCP      | livekit* | TURN/STUN (legacy) |

_* Legacy service from docker/compose.yaml, not in root compose.yaml_

---

## Resource Limits

### Memory (per container)
| Service | Profile | Limit | Reservation | Volume |
|---------|---------|-------|-------------|--------|
| traefik | ingress | 256M | 128M | data/traefik |
| n8n | core/workflows | 2G | 1G | data/n8n |
| n8n-mcp | mcp | 256M | 128M | data/n8n-mcp |
| n8n-workflows-mcp | mcp | 256M | 128M | data/n8n-workflows-mcp |
| redis | state | 512M | 256M | data/redis |
| postgresql | database | 2G | 1G | data/postgresql |
| qdrant | vector | 2G | 512M | data/qdrant |
| meilisearch | search | 1G | 256M | data/meilisearch |
| minio | storage | 1G | 256M | data/minio |
| grafana | monitoring | 512M | 256M | data/grafana |
| prometheus | monitoring | 1G | 512M | data/prometheus |
| loki | monitoring | 1G | 512M | data/loki |
| tailscale | vpn | 256M | 64M | data/tailscale |
| desktop-commander | utilities | 256M | 64M | data/desktop-commander |

**Total Maximum Memory**: ~12.5 GB (if all profiles enabled)

### CPU (per container)
| Service | Profile | Limit | Reservation |
|---------|---------|-------|-------------|
| traefik | ingress | 1.0 | 0.5 |
| n8n | core/workflows | 2.0 | 1.0 |
| n8n-mcp | mcp | 0.5 | 0.25 |
| n8n-workflows-mcp | mcp | 0.5 | 0.25 |
| redis | state | 1.0 | 0.5 |
| postgresql | database | 2.0 | 1.0 |
| qdrant | vector | 2.0 | 0.5 |
| meilisearch | search | 2.0 | 0.5 |
| minio | storage | 2.0 | 0.5 |
| grafana | monitoring | 0.5 | 0.25 |
| prometheus | monitoring | 1.0 | 0.5 |
| loki | monitoring | 1.0 | 0.5 |
| tailscale | vpn | 0.5 | 0.1 |
| desktop-commander | utilities | 0.5 | 0.1 |

**Total Maximum CPU Cores**: ~16.5 (if all profiles enabled)

### Storage Volumes
| Service | Volume Path | Purpose | Size Limit |
|---------|-------------|---------|------------|
| traefik | data/traefik | Config, ACME certs | 100MB |
| n8n | data/n8n | Workflow data, credentials | 10GB |
| n8n | n8n/workflows | Workflow definitions | 100MB |
| n8n-mcp | data/n8n-mcp | MCP server data | 1GB |
| n8n-workflows-mcp | data/n8n-workflows-mcp | Workflow MCP data | 1GB |
| redis | data/redis | Persistence dump | 5GB |
| postgresql | data/postgresql | Database cluster | 20GB |
| qdrant | data/qdrant | Vector storage | 30GB |
| meilisearch | data/meilisearch | Search indexes | 20GB |
| minio | data/minio | Object storage | 50GB |
| grafana | data/grafana | Dashboards, panels | 5GB |
| prometheus | data/prometheus | Metrics time-series | 30GB |
| loki | data/loki | Log chunks | 20GB |
| tailscale | data/tailscale | State, keys | 100MB |
| desktop-commander | data/desktop-commander | Commander data | 1GB |

**Total Maximum Storage**: ~193.2 GB

---

## Service Profiles

### core
Core infrastructure services:
- traefik (ingress)
- n8n (workflows)
- redis (state)
- minio (storage)

**Resources**: 4.75 GB memory, 6.0 CPU cores

### workflows
Workflow automation:
- n8n
- n8n-mcp
- n8n-workflows-mcp

**Resources**: 2.5 GB memory, 3.0 CPU cores

### mcp
Model Context Protocol servers:
- n8n-mcp
- n8n-workflows-mcp

**Resources**: 512 MB memory, 1.0 CPU core

### state
State management:
- redis

**Resources**: 512 MB memory, 1.0 CPU core

### database
Persistent data stores:
- postgresql (with pgvector + jsonb)
- qdrant (vector DB)
- meilisearch (search)

**Resources**: 5 GB memory, 6.0 CPU cores

### vector
Vector database only:
- qdrant

**Resources**: 2 GB memory, 2.0 CPU cores

### search
Full-text search only:
- meilisearch

**Resources**: 1 GB memory, 2.0 CPU cores

### storage
Object storage:
- minio

**Resources**: 1 GB memory, 2.0 CPU cores

### observability / monitoring
Metrics and logging:
- grafana
- prometheus
- loki

**Resources**: 2.5 GB memory, 2.5 CPU cores

### ingress / networking
Reverse proxy:
- traefik

**Resources**: 256 MB memory, 1.0 CPU core

### vpn / networking
VPN sidecar:
- tailscale

**Resources**: 256 MB memory, 0.5 CPU core

### utilities / local
Local execution interface:
- desktop-commander

**Resources**: 256 MB memory, 0.5 CPU core

---

## Healthcheck Contracts

All services define healthcheck stubs in compose.yaml. These are NOT executed until the service starts. Healthcheck parameters:

| Service | Test Interval | Timeout | Retries | Start Period |
|---------|---------------|---------|---------|--------------|
| traefik | 10s | 3s | 3 | 5s |
| n8n | 15s | 5s | 5 | 30s |
| n8n-mcp | 30s | 5s | 3 | 10s |
| n8n-workflows-mcp | 30s | 5s | 3 | 10s |
| redis | 10s | 3s | 5 | 10s |
| postgresql | 10s | 5s | 5 | 30s |
| qdrant | 30s | 10s | 5 | 20s |
| meilisearch | 30s | 10s | 5 | 20s |
| minio | 30s | 20s | 5 | 30s |
| grafana | 30s | 10s | 5 | 30s |
| prometheus | 30s | 10s | 5 | 30s |
| loki | 30s | 10s | 5 | 20s |
| tailscale | 60s | 10s | 3 | 30s |
| desktop-commander | 30s | 5s | 3 | 10s |

---

## Network Configuration

### samwise-ingress
- **Purpose**: External ingress via Traefik
- **Subnet**: 172.20.0.0/16
- **Services**: traefik, grafana
- **Firewall**: Expose ports 80, 443, 8080

### samwise-internal
- **Purpose**: Internal service-to-service communication
- **Subnet**: 172.21.0.0/16
- **Services**: All services
- **Firewall**: No external access (internal only)

---

## Rate Limits

### Traefik
- 100 requests/second per IP
- 1000 requests/minute per IP
- 10 connections/IP to backend services

### n8n
- 50 workflow executions/minute
- 1000 webhook calls/hour

### Redis
- 10,000 operations/second (default)

### PostgreSQL
- Max connections: 100
- Connection pool min: 5

---

## Quotas

### Local Development Limits
- Max 10 concurrent workflows
- Max 5 LiveKit rooms (legacy)
- Max 100MB Redis memory for development

### Cloud Provider Limits
See `infra/<provider>/limits.md` for provider-specific quotas.

---

## Enforcement

**Resource limits are enforced by Docker Compose via:**

```yaml
deploy:
  resources:
    limits:
      cpus: 'X.Y'
      memory: ZZZM
    reservations:
      cpus: 'A.B'
      memory: YYYM
```

**If a service exceeds its limits:**
- Container will be throttled (CPU)
- Container will be OOM killed (memory)
- Restart policy applies (`restart: unless-stopped`)

**To change limits:**
1. Update PORTS_AND_LIMITS.md
2. Update compose.yaml service definition
3. Run: `docker compose --profile <profile> up -d`
4. Monitor: `docker stats`

---

## Audit

**Last Updated**: 2024-12-26
**Compose Version**: v2
**Total Services Defined**: 14
**Total Profiles**: 13
**Activation**: All services disabled by default
