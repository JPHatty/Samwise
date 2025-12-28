# Failure Guarantees for Missing Dependencies

## Purpose
**DEFINITIVE** specification of how Samwise behaves when cloud dependencies are unavailable.

**PRINCIPLE:** Each service has a documented failure mode with guaranteed behavior.

---

## Failure Mode Classifications

### CRITICAL
System cannot function without this service.
**Guarantee:** Halt immediately, emit CRITICAL RunRecord, require operator intervention.

### FAIL FAST
System can detect missing dependency early and halt cleanly.
**Guarantee:** Halt at validation time, emit error RunRecord, provide clear error message.

### DEGRADED
System can continue with reduced functionality.
**Guarantee:** Log warning, emit degraded RunRecord, continue with documented fallback behavior.

### OPTIONAL
Service provides enhanced features but is not required.
**Guarantee:** Log info message, emit info RunRecord, continue normally without features.

---

## LOCAL Services Failure Guarantees

### Traefik (Ingress Control Plane)

**Failure Mode:** CRITICAL
**Why Required:** No routing to n8n UI, system unusable

**Detection:**
- Container exits with non-zero code
- Healthcheck fails
- Ports 80/443 not listening

**Behavior:**
```javascript
{
  "status": "critical",
  "service": "traefik",
  "error": "INGRESS_UNAVAILABLE",
  "message": "Traefik is not running - system cannot route requests",
  "resolution": "Check Docker logs: docker compose logs traefik",
  "run_record": {
    "status": "failure",
    "critic_verdict": "fail",
    "errors": [{
      "code": "INGRESS_UNAVAILABLE",
      "severity": "critical",
      "message": "Traefik container failed to start or crashed"
    }]
  }
}
```

**Recovery:**
1. Check Docker logs: `docker compose logs traefik`
2. Verify ports 80/443 are available: `netstat -an | grep -E ':(80|443)'`
3. Restart traefik: `docker compose restart traefik`

---

### N8N (Orchestration Control Plane)

**Failure Mode:** CRITICAL
**Why Required:** No orchestration, cannot trigger workflows

**Detection:**
- Container exits with non-zero code
- Healthcheck fails (GET /healthz returns non-200)
- Port 5678 not listening

**Behavior:**
```javascript
{
  "status": "critical",
  "service": "n8n",
  "error": "ORCHESTRATION_UNAVAILABLE",
  "message": "N8N is not running - cannot execute workflows",
  "resolution": "Check Docker logs: docker compose logs n8n",
  "run_record": {
    "status": "failure",
    "critic_verdict": "fail",
    "errors": [{
      "code": "ORCHESTRATION_UNAVAILABLE",
      "severity": "critical",
      "message": "N8N container failed to start or crashed"
    }]
  }
}
```

**Recovery:**
1. Check Docker logs: `docker compose logs n8n`
2. Verify N8N_ENCRYPTION_KEY is set in .env
3. Check Redis connectivity (if enabled)
4. Restart n8n: `docker compose restart n8n`

---

### Redis (Ephemeral Cache)

**Failure Mode:** DEGRADED
**Why Optional:** Cache improves performance but not required

**Detection:**
- Connection refused on port 6379
- Auth failed: `NOAUTH Authentication required`
- Redis not responding to PING

**Behavior:**
```javascript
{
  "status": "degraded",
  "service": "redis",
  "error": "CACHE_UNAVAILABLE",
  "message": "Redis cache unavailable - continuing without cache",
  "fallback": "Direct execution without caching",
  "performance_impact": "Higher latency, no state sharing",
  "run_record": {
    "status": "success",
    "critic_verdict": "pass",
    "warnings": [{
      "code": "CACHE_UNAVAILABLE",
      "severity": "warning",
      "message": "Redis unavailable - running without cache"
    }]
  }
}
```

**Recovery:**
1. Check if Redis container is running: `docker ps | grep redis`
2. Verify REDIS_PASSWORD in .env
3. Restart Redis: `docker compose restart redis`
4. **No action required** - system continues without cache

---

### N8N-MCP (Model Context Protocol Server)

**Failure Mode:** OPTIONAL
**Why Optional:** Advanced LLM features unavailable

**Detection:**
- Connection refused on MCP port
- MCP healthcheck fails

**Behavior:**
```javascript
{
  "status": "optional",
  "service": "n8n-mcp",
  "error": "MCP_SERVER_UNAVAILABLE",
  "message": "MCP server unavailable - LLM features disabled",
  "disabled_features": ["tool_discovery", "auto_registration"],
  "run_record": {
    "status": "success",
    "critic_verdict": "pass",
    "info": [{
      "code": "MCP_SERVER_UNAVAILABLE",
      "severity": "info",
      "message": "MCP server not running - manual tool registration required"
    }]
  }
}
```

**Recovery:**
1. Start MCP server: `docker compose --profile workflows up`
2. **No action required** - manual tool registration still works

---

### N8N-Workflows-MCP (Workflow Discovery MCP)

**Failure Mode:** OPTIONAL
**Why Optional:** Manual workflow discovery still possible

**Detection:**
- Connection refused on MCP port
- Workflow directory not accessible

**Behavior:**
```javascript
{
  "status": "optional",
  "service": "n8n-workflows-mcp",
  "error": "WORKFLOW_MCP_UNAVAILABLE",
  "message": "Workflow MCP unavailable - manual discovery required",
  "fallback": "Direct filesystem access to /home/node/.n8n/workflows",
  "run_record": {
    "status": "success",
    "critic_verdict": "pass",
    "info": [{
      "code": "WORKFLOW_MCP_UNAVAILABLE",
      "severity": "info",
      "message": "Workflow MCP not running - use manual workflow listing"
    }]
  }
}
```

**Recovery:**
1. Start MCP server: `docker compose --profile workflows up`
2. **No action required** - use n8n UI to browse workflows

---

### Tailscale (VPN Sidecar)

**Failure Mode:** OPTIONAL
**Why Optional:** Local-only access without VPN

**Detection:**
- Tailscale not connected
- TS_AUTHKEY invalid or expired
- Tailscale API unreachable

**Behavior:**
```javascript
{
  "status": "optional",
  "service": "tailscale",
  "error": "VPN_UNAVAILABLE",
  "message": "Tailscale VPN unavailable - local-only access",
  "access_scope": "localhost only",
  "remote_access": "disabled",
  "run_record": {
    "status": "success",
    "critic_verdict": "pass",
    "info": [{
      "code": "VPN_UNAVAILABLE",
      "severity": "info",
      "message": "Tailscale not connected - use localhost:5678 for n8n UI"
    }]
  }
}
```

**Recovery:**
1. Check Tailscale status: `docker compose exec tailscale tailscale status`
2. Reauthenticate with new TS_AUTHKEY
3. **No action required** - access n8n at localhost:5678 instead

---

## CLOUD Services Failure Guarantees

### Supabase (PostgreSQL + pgvector)

**Failure Mode:** FAIL FAST
**Why Required:** Primary database, vector storage, persistence

**Detection:**
- Connection timeout
- Auth failed: `FATAL: password authentication failed`
- Host unreachable
- Supabase API returns 401/403

**Behavior:**
```javascript
{
  "status": "failure",
  "service": "supabase",
  "error": "DATABASE_UNAVAILABLE",
  "message": "Supabase PostgreSQL unreachable - cannot persist data",
  "validation_gate": "pre-execution",
  "halt_execution": true,
  "run_record": {
    "status": "failure",
    "critic_verdict": "fail",
    "errors": [{
      "code": "DATABASE_UNAVAILABLE",
      "severity": "error",
      "message": "Failed to connect to Supabase: connection timeout",
      "troubleshooting": [
        "Check SUPABASE_URL in .env",
        "Verify Supabase project is active",
        "Check SUPABASE_PASSWORD is correct",
        "Test connectivity: curl -I ${SUPABASE_URL}"
      ]
    }]
  }
}
```

**Guarantee:**
- Workflow execution HALT before any state mutation
- RunRecord emitted with `status: failure`
- Clear error message with troubleshooting steps
- NO partial execution, NO data corruption

**Recovery:**
1. Verify .env variables: `SUPABASE_URL`, `SUPABASE_PASSWORD`, `SUPABASE_ANON_KEY`
2. Check Supabase dashboard: https://supabase.com/dashboard
3. Test connectivity: `curl -I ${SUPABASE_URL}`
4. Pause/Resume Supabase project if paused
5. Regenerate API keys if expired

**Retry Strategy:**
- NO automatic retries (database failures indicate configuration issues)
- Operator must fix configuration before retry

---

### Qdrant (Vector Database)

**Failure Mode:** FAIL FAST
**Why Required:** Vector similarity search for RAG

**Detection:**
- Connection timeout
- API key invalid (401 Unauthorized)
- Collection not found (404 Not Found)
- Qdrant service unavailable (503 Service Unavailable)

**Behavior:**
```javascript
{
  "status": "failure",
  "service": "qdrant",
  "error": "VECTOR_DB_UNAVAILABLE",
  "message": "Qdrant unreachable - RAG features unavailable",
  "validation_gate": "pre-execution",
  "halt_execution": true,
  "affected_features": ["semantic_search", "vector_similarity", "embeddings_indexing"],
  "run_record": {
    "status": "failure",
    "critic_verdict": "fail",
    "errors": [{
      "code": "VECTOR_DB_UNAVAILABLE",
      "severity": "error",
      "message": "Failed to connect to Qdrant: connection refused",
      "troubleshooting": [
        "Check QDRANT_URL in .env",
        "Verify QDRANT_API_KEY is valid",
        "Test connectivity: curl -I ${QDRANT_URL}",
        "Check collection exists: curl ${QDRANT_URL}/collections/${QDRANT_COLLECTION}"
      ]
    }]
  }
}
```

**Guarantee:**
- Workflow execution HALT before vector operations
- RunRecord emitted with `status: failure`
- Clear error message with troubleshooting steps
- NO partial vector indexing

**Recovery:**
1. Verify .env variables: `QDRANT_URL`, `QDRANT_API_KEY`
2. Check Northflank/Fly.io dashboard for Qdrant service status
3. Test connectivity: `curl -I ${QDRANT_URL}`
4. Verify collection exists: `curl ${QDRANT_URL}/collections/${QDRANT_COLLECTION}`
5. Create collection if missing

**Retry Strategy:**
- NO automatic retries (vector DB failures indicate service issues)
- Operator must provision Qdrant or fix configuration

---

### Meilisearch (Full-Text Search)

**Failure Mode:** DEGRADED
**Why Optional:** Fallback to PostgreSQL text search available

**Detection:**
- Connection timeout
- API key invalid (403 Forbidden)
- Index not found (404 Not Found)

**Behavior:**
```javascript
{
  "status": "degraded",
  "service": "meilisearch",
  "error": "SEARCH_UNAVAILABLE",
  "message": "Meilisearch unavailable - falling back to PostgreSQL text search",
  "fallback": "PostgreSQL LIKE/ILIKE queries",
  "performance_impact": "Slower full-text search, no fuzzy matching",
  "run_record": {
    "status": "success",
    "critic_verdict": "pass",
    "warnings": [{
      "code": "SEARCH_DEGRADED",
      "severity": "warning",
      "message": "Meilisearch unavailable - using PostgreSQL text search fallback"
    }]
  }
}
```

**Guarantee:**
- Workflow execution CONTINUES with fallback
- RunRecord emitted with `status: success` (degraded)
- Warning logged for operator awareness
- Search functionality preserved (slower)

**Recovery:**
1. Verify .env variables: `MEILISEARCH_HOST`, `MEILISEARCH_API_KEY`
2. Check Northflank dashboard for Meilisearch service status
3. Test connectivity: `curl -I ${MEILISEARCH_HOST}`
4. **No action required** - PostgreSQL fallback works

**Retry Strategy:**
- Automatic retry on next search operation
- Exponential backoff: 1s, 2s, 4s, 8s (max 3 retries)

---

### Cloudflare R2 (Object Storage)

**Failure Mode:** FAIL FAST
**Why Required:** S3-compatible storage for artifacts

**Detection:**
- Connection timeout
- Auth failed (403 Forbidden)
- Bucket not found (404 Not Found)

**Behavior:**
```javascript
{
  "status": "failure",
  "service": "cloudflare-r2",
  "error": "OBJECT_STORAGE_UNAVAILABLE",
  "message": "Cloudflare R2 unreachable - cannot store artifacts",
  "validation_gate": "pre-execution",
  "halt_execution": true,
  "affected_operations": ["file_upload", "artifact_storage", "backup_export"],
  "run_record": {
    "status": "failure",
    "critic_verdict": "fail",
    "errors": [{
      "code": "OBJECT_STORAGE_UNAVAILABLE",
      "severity": "error",
      "message": "Failed to connect to Cloudflare R2: authentication failed",
      "troubleshooting": [
        "Check R2_ENDPOINT in .env",
        "Verify R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY",
        "Verify R2_BUCKET exists",
        "Test with AWS CLI: aws s3 ls --endpoint-url ${R2_ENDPOINT}"
      ]
    }]
  }
}
```

**Guarantee:**
- Workflow execution HALT before file operations
- RunRecord emitted with `status: failure`
- Clear error message with troubleshooting steps
- NO partial uploads, NO orphaned objects

**Recovery:**
1. Verify .env variables: `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`
2. Check Cloudflare R2 dashboard: https://dash.cloudflare.com
3. Create bucket if missing
4. Regenerate R2 API tokens if expired

**Retry Strategy:**
- NO automatic retries (R2 failures indicate configuration issues)
- Operator must fix configuration or provision bucket

---

### Grafana (Metrics Dashboard)

**Failure Mode:** OPTIONAL
**Why Optional:** Read-only metrics, no operational impact

**Detection:**
- Connection timeout
- API key invalid (401 Unauthorized)
- Dashboard not found (404 Not Found)

**Behavior:**
```javascript
{
  "status": "optional",
  "service": "grafana",
  "error": "DASHBOARD_UNAVAILABLE",
  "message": "Grafana unavailable - metrics visualization disabled",
  "fallback": "Prometheus direct query or logs only",
  "run_record": {
    "status": "success",
    "critic_verdict": "pass",
    "info": [{
      "code": "DASHBOARD_UNAVAILABLE",
      "severity": "info",
      "message": "Grafana unreachable - use Prometheus API directly or check logs"
    }]
  }
}
```

**Recovery:**
1. Verify .env variables: `GRAFANA_URL`, `GRAFANA_API_KEY`
2. **No action required** - metrics still collected in Prometheus

---

### Prometheus (Metrics Storage)

**Failure Mode:** OPTIONAL
**Why Optional:** Metrics are nice-to-have, not required

**Detection:**
- Connection timeout
- API endpoint unreachable

**Behavior:**
```javascript
{
  "status": "optional",
  "service": "prometheus",
  "error": "METRICS_UNAVAILABLE",
  "message": "Prometheus unavailable - metrics not collected",
  "fallback": "Logs only",
  "run_record": {
    "status": "success",
    "critic_verdict": "pass",
    "info": [{
      "code": "METRICS_UNAVAILABLE",
      "severity": "info",
      "message": "Prometheus unreachable - relying on logs for observability"
    }]
  }
}
```

**Recovery:**
1. Verify .env variables: `PROMETHEUS_URL`, `PROMETHEUS_API_KEY`
2. **No action required** - system functions without metrics

---

### Loki (Log Aggregation)

**Failure Mode:** OPTIONAL
**Why Optional:** Logs to stdout if Loki unavailable

**Detection:**
- Connection timeout
- Auth failed (401 Unauthorized)

**Behavior:**
```javascript
{
  "status": "optional",
  "service": "loki",
  "error": "LOG_AGGREGATION_UNAVAILABLE",
  "message": "Loki unavailable - logs to stdout only",
  "fallback": "stdout/stderr logging",
  "run_record": {
    "status": "success",
    "critic_verdict": "pass",
    "info": [{
      "code": "LOG_AGGREGATION_UNAVAILABLE",
      "severity": "info",
      "message": "Loki unreachable - logs available in Docker container output"
    }]
  }
}
```

**Recovery:**
1. Verify .env variables: `LOKI_URL`, `LOKI_API_KEY`
2. **No action required** - use Docker logs: `docker compose logs -f`

---

### LiveKit (Real-Time Media)

**Failure Mode:** FAIL FAST
**Why Required:** Media processing requires real-time workers

**Detection:**
- Connection timeout
- API key invalid (403 Forbidden)
- Room not found (404 Not Found)

**Behavior:**
```javascript
{
  "status": "failure",
  "service": "livekit",
  "error": "MEDIA_WORKERS_UNAVAILABLE",
  "message": "LiveKit unreachable - media features unavailable",
  "validation_gate": "pre-execution",
  "halt_execution": true,
  "affected_features": ["audio_processing", "video_streaming", "realtime_media"],
  "run_record": {
    "status": "failure",
    "critic_verdict": "fail",
    "errors": [{
      "code": "MEDIA_WORKERS_UNAVAILABLE",
      "severity": "error",
      "message": "Failed to connect to LiveKit: connection timeout",
      "troubleshooting": [
        "Check LIVEKIT_URL in .env",
        "Verify LIVEKIT_API_KEY and LIVEKIT_API_SECRET",
        "Test connectivity: curl -I ${LIVEKIT_URL}",
        "Check Fly.io/Koyeb dashboard for LiveKit service status"
      ]
    }]
  }
}
```

**Guarantee:**
- Workflow execution HALT before media operations
- RunRecord emitted with `status: failure`
- Clear error message with troubleshooting steps
- NO partial media processing

**Recovery:**
1. Verify .env variables: `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`
2. Check Fly.io/Koyeb dashboard for LiveKit service status
3. Test connectivity: `curl -I ${LIVEKIT_URL}`
4. Create room if missing

**Retry Strategy:**
- NO automatic retries (LiveKit failures indicate provisioning issues)
- Operator must provision LiveKit service

---

## Startup Validation Sequence

When ToolForge or n8n starts, the following validation sequence occurs:

```
1. LOCAL: Check Traefik health
   └─ FAIL: CRITICAL → HALT

2. LOCAL: Check N8N health
   └─ FAIL: CRITICAL → HALT

3. LOCAL: Check Redis connectivity
   └─ FAIL: DEGRADED → CONTINUE with warning

4. CLOUD: Validate Supabase connection
   └─ FAIL: FAIL FAST → HALT

5. CLOUD: Validate Qdrant connection
   └─ FAIL: FAIL FAST → HALT

6. CLOUD: Validate Meilisearch connection
   └─ FAIL: DEGRADED → CONTINUE with fallback

7. CLOUD: Validate Cloudflare R2 connection
   └─ FAIL: FAIL FAST → HALT

8. CLOUD: Validate observability stack (Prometheus, Loki, Grafana)
   └─ FAIL: OPTIONAL → CONTINUE with info

9. CLOUD: Validate LiveKit (if media features required)
   └─ FAIL: FAIL FAST → HALT
```

**Startup Result:**
- **PASS:** All CRITICAL and FAIL FAST checks passed → System operational
- **DEGRADED:** Optional services unavailable → System operational with warnings
- **FAIL:** Any CRITICAL or FAIL FAST check failed → System halted, operator intervention required

---

## RunRecord Emission Rules

### CRITICAL / FAIL FAST Failures
```json
{
  "run_id": "<uuid>",
  "status": "failure",
  "critic_verdict": "fail",
  "errors": [{
    "timestamp": "<iso8601>",
    "severity": "error",
    "code": "<SERVICE>_UNAVAILABLE",
    "message": "Service unavailable with troubleshooting steps"
  }],
  "halt_execution": true
}
```

### DEGRADED Failures
```json
{
  "run_id": "<uuid>",
  "status": "success",
  "critic_verdict": "pass",
  "warnings": [{
    "timestamp": "<iso8601>",
    "severity": "warning",
    "code": "<SERVICE>_DEGRADED",
    "message": "Service unavailable, using fallback"
  }],
  "fallback_active": true
}
```

### OPTIONAL Failures
```json
{
  "run_id": "<uuid>",
  "status": "success",
  "critic_verdict": "pass",
  "info": [{
    "timestamp": "<iso8601>",
    "severity": "info",
    "code": "<SERVICE>_OPTIONAL_UNAVAILABLE",
    "message": "Optional service unavailable, features disabled"
  }],
  "optional_features_disabled": ["<feature_list>"]
}
```

---

## Troubleshooting Checklist

When a workflow fails with dependency error:

- [ ] Check .env file has required variables
- [ ] Test cloud service connectivity: `curl -I ${SERVICE_URL}`
- [ ] Verify API keys are not expired
- [ ] Check cloud provider dashboard for service status
- [ ] Review Docker logs: `docker compose logs -f <service>`
- [ ] Check RunRecord error details for specific troubleshooting steps
- [ ] Retry after fixing configuration (DO NOT retry without fixing root cause)

---

## Appendix: Quick Reference

| Service | Failure Mode | Startup Check | Retry? | Fallback |
|---------|--------------|---------------|--------|----------|
| **Traefik** | CRITICAL | Yes | No | None |
| **N8N** | CRITICAL | Yes | No | None |
| **Redis** | DEGRADED | Yes | Yes | No cache |
| **N8N-MCP** | OPTIONAL | No | No | Manual registration |
| **N8N-Workflows-MCP** | OPTIONAL | No | No | Manual discovery |
| **Tailscale** | OPTIONAL | No | No | Local access |
| **Supabase** | FAIL FAST | Yes | No | None |
| **Qdrant** | FAIL FAST | Yes | No | None |
| **Meilisearch** | DEGRADED | Yes | Yes | PostgreSQL text search |
| **Cloudflare R2** | FAIL FAST | Yes | No | None |
| **Grafana** | OPTIONAL | No | No | Prometheus direct |
| **Prometheus** | OPTIONAL | No | No | Logs only |
| **Loki** | OPTIONAL | No | No | Stdout logs |
| **LiveKit** | FAIL FAST | Yes | No | None |
