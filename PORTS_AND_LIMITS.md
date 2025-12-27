# Ports and Limits

## Purpose
Document all network ports, resource limits, and service quotas.

## Port Allocation

### External (Host → Traefik)
| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 80   | HTTP     | Traefik | HTTP → HTTPS redirect |
| 443  | HTTPS    | Traefik | Main ingress |

### Internal (Docker Network)
| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 5678 | HTTP     | n8n     | Workflow UI |
| 6379 | TCP      | Redis   | Cache/Queue |
| 7880 | HTTP/WS  | LiveKit | Media server |
| 7881 | TCP      | LiveKit | TURN/STUN |
| 8080 | HTTP     | Traefik | Dashboard |

## Resource Limits

### Memory (per container)
| Service | Limit | Reservation |
|---------|-------|-------------|
| Traefik | 256MB | 128MB |
| n8n     | 2GB   | 1GB |
| Redis   | 512MB | 256MB |
| LiveKit | 4GB   | 2GB |

### CPU (per container)
| Service | Limit | Reservation |
|---------|-------|-------------|
| Traefik | 1.0   | 0.5 |
| n8n     | 2.0   | 1.0 |
| Redis   | 1.0   | 0.5 |
| LiveKit | 4.0   | 2.0 |

### Storage
| Service | Volume | Size Limit |
|---------|--------|------------|
| n8n     | /data  | 10GB |
| Redis   | /data  | 5GB |
| LiveKit | /data  | 20GB |

## Rate Limits

### Traefik
- 100 requests/second per IP
- 1000 requests/minute per IP
- 10 connections/IP to LiveKit

### n8n
- 50 workflow executions/minute
- 1000 webhook calls/hour

### Redis
- 10,000 operations/second (default)

## Quotas

### Cloud Provider Limits
See `infra/<provider>/limits.md` for provider-specific quotas.

### Local Development
- Max 10 concurrent workflows
- Max 5 LiveKit rooms
- Max 100MB Redis memory
