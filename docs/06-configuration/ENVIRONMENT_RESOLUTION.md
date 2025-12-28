# Environment Resolution Rules

## Purpose
**DEFINITIVE** specification of how cloud endpoints are resolved at runtime.

**PRINCIPLE:** Fail safely and explicitly when dependencies are missing.

---

## Resolution Priority

At runtime, adapter configuration is resolved in this order:

```
1. Tool-specific override (highest priority)
   tool.config.<VARIABLE>

2. Adapter-level default
   adapter.config.<VARIABLE>

3. Global environment variable (lowest priority)
   process.env.<VARIABLE>
```

### Example: Qdrant Adapter Resolution

```javascript
// Tool specifies override
const tool = {
  adapter_id: "qdrant-vector",
  config: {
    QDRANT_URL: "https://custom-qdrant.example.com"  // ← Override
  }
};

// Adapter has defaults
const adapter = {
  config: {
    QDRANT_URL: process.env.QDRANT_URL  // ← Fallback
  }
};

// Resolution logic
function resolveConfig(tool, adapter) {
  return {
    QDRANT_URL: tool.config?.QDRANT_URL || adapter.config.QDRANT_URL,
    QDRANT_API_KEY: tool.config?.QDRANT_API_KEY || adapter.config.QDRANT_API_KEY
  };
}

// Result: Uses tool.config.QDRANT_URL if present, otherwise adapter default
```

---

## Startup Validation Sequence

When ToolForge or n8n starts, adapters are initialized in this order:

### Phase 1: Load Adapter Registry

```javascript
const registryPath = '/home/node/.n8n/data/adapter-registry.json';
const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));

// Registry structure:
{
  "version": "1.0.0",
  "adapters": [
    {
      "adapter_id": "supabase-postgres",
      "enabled": true,
      "config_required": ["SUPABASE_URL", "SUPABASE_ANON_KEY", "SUPABASE_DB", "SUPABASE_HOST", "SUPABASE_USER", "SUPABASE_PASSWORD"]
    },
    // ... other adapters
  ]
}
```

### Phase 2: Resolve Environment Variables

For each enabled adapter:

```javascript
for (const adapter of registry.adapters) {
  if (!adapter.enabled) continue;

  const config = {};
  const missing = [];
  const invalid = [];

  for (const varName of adapter.config_required) {
    const value = process.env[varName];

    // Check: Variable exists
    if (!value) {
      missing.push(varName);
      continue;
    }

    // Check: Variable format (validation)
    const validation = validateEnvVar(varName, value);
    if (!validation.valid) {
      invalid.push({ varName, reason: validation.reason });
      continue;
    }

    config[varName] = value;
  }

  adapter.resolved_config = config;
  adapter.validation_errors = [...missing, ...invalid];
}
```

### Phase 3: Classify Adapter Status

```javascript
const adapterStatus = {
  healthy: [],      // All config present and valid
  degraded: [],     // Optional adapter missing config
  failed: []        // Critical adapter missing config
};

for (const adapter of registry.adapters) {
  if (adapter.validation_errors.length === 0) {
    adapterStatus.healthy.push(adapter.adapter_id);
  } else if (adapter.critical) {
    adapterStatus.failed.push({
      adapter_id: adapter.adapter_id,
      errors: adapter.validation_errors
    });
  } else {
    adapterStatus.degraded.push({
      adapter_id: adapter.adapter_id,
      errors: adapter.validation_errors
    });
  }
}
```

### Phase 4: Emit Startup RunRecord

```javascript
const startupRecord = {
  run_id: crypto.randomUUID(),
  timestamp: new Date().toISOString(),
  event_type: "adapter_initialization",
  status: adapterStatus.failed.length > 0 ? "failure" : "success",
  adapters: {
    healthy: adapterStatus.healthy,
    degraded: adapterStatus.degraded,
    failed: adapterStatus.failed
  },
  system_ready: adapterStatus.failed.length === 0
};

// Write to append-only log
fs.appendFileSync(
  '/home/node/.n8n/data/adapter-initialization.jsonl',
  JSON.stringify(startupRecord) + '\n'
);
```

### Phase 5: Halt if Critical Adapters Failed

```javascript
if (adapterStatus.failed.length > 0) {
  const errors = adapterStatus.failed.map(f => `- ${f.adapter_id}: ${f.errors.join(', ')}`).join('\n');

  throw new Error(`CRITICAL: Required adapters failed initialization:\n${errors}\n\nSystem cannot start. Fix configuration and retry.`);
}
```

---

## Environment Variable Validation

### Validation Rules by Type

#### URL Variables

Must be valid HTTPS URLs:

```javascript
function validateUrlVar(name, value) {
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:') {
      return { valid: false, reason: `Must be HTTPS URL, got ${url.protocol}` };
    }
    return { valid: true };
  } catch {
    return { valid: false, reason: 'Invalid URL format' };
  }
}

// Applies to:
// - SUPABASE_URL
// - QDRANT_URL
// - MEILISEARCH_HOST
// - R2_ENDPOINT
// - GRAFANA_URL
// - PROMETHEUS_URL
// - LOKI_URL
// - LIVEKIT_URL
```

#### API Key Variables

Must be non-empty strings, valid format:

```javascript
function validateApiKeyVar(name, value) {
  if (value.length < 16) {
    return { valid: false, reason: 'API key too short (min 16 characters)' };
  }

  // Specific format checks
  if (name === 'SUPABASE_ANON_KEY' || name === 'SUPABASE_SERVICE_KEY') {
    if (!value.startsWith('eyJ')) {
      return { valid: false, reason: 'Supabase keys must be JWT format (eyJ...)' };
    }
  }

  return { valid: true };
}

// Applies to:
// - SUPABASE_ANON_KEY, SUPABASE_SERVICE_KEY
// - QDRANT_API_KEY
// - MEILISEARCH_API_KEY
// - R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY
// - GRAFANA_API_KEY
// - PROMETHEUS_API_KEY
// - LOKI_API_KEY
// - LIVEKIT_API_KEY, LIVEKIT_API_SECRET
```

#### Boolean Variables

Must be 'true' or 'false' (case-insensitive):

```javascript
function validateBooleanVar(name, value) {
  const normalized = value.toLowerCase();
  if (normalized !== 'true' && normalized !== 'false') {
    return { valid: false, reason: `Must be 'true' or 'false', got '${value}'` };
  }
  return { valid: true };
}
```

#### Integer Variables

Must be valid integers in range:

```javascript
function validateIntVar(name, value, min, max) {
  const num = parseInt(value, 10);
  if (isNaN(num)) {
    return { valid: false, reason: `Not a valid integer: ${value}` };
  }
  if (num < min || num > max) {
    return { valid: false, reason: `Must be between ${min} and ${max}, got ${num}` };
  }
  return { valid: true };
}

// Applies to:
// - SUPABASE_PORT (default: 5432, range: 1024-65535)
// - QDRANT_COLLECTION_SIZE (default: 768, range: 1-4096)
```

---

## Runtime Resolution Failures

### Category 1: CRITICAL Failures

**Definition:** Adapter is required for core system functionality.

**Behavior:** Halt immediately, emit CRITICAL RunRecord, require operator intervention.

**Affected Adapters:**
- `supabase-postgres` (database required)
- `qdrant-vector` (vector search required)
- `cloudflare-r2` (object storage required)
- `livekit` (media features required)

**RunRecord Format:**

```json
{
  "run_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-12-26T12:00:00.000Z",
  "event_type": "adapter_resolution_failure",
  "status": "failure",
  "severity": "critical",
  "adapter_id": "supabase-postgres",
  "error": {
    "code": "ENV_VAR_MISSING",
    "message": "Required environment variable not set",
    "missing_variables": ["SUPABASE_URL", "SUPABASE_ANON_KEY"],
    "resolution": "Set missing variables in .env file and restart",
    "documentation": "See ENV_VAR_MAPPING.md"
  },
  "system_ready": false,
  "halt_execution": true
}
```

**Example Error Message:**

```
CRITICAL: Required adapter 'supabase-postgres' failed initialization

Missing environment variables:
- SUPABASE_URL (required: HTTPS URL to Supabase project)
- SUPABASE_ANON_KEY (required: Supabase anonymous API key)

Resolution:
1. Open .env file
2. Add SUPABASE_URL=https://xxxxx.supabase.co
3. Add SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
4. Restart n8n: docker compose restart n8n

System cannot start. Fix configuration and retry.
```

### Category 2: DEGRADED Failures

**Definition:** Adapter is optional or has fallback behavior.

**Behavior:** Log warning, emit degraded RunRecord, continue with fallback.

**Affected Adapters:**
- `meilisearch` (fallback to PostgreSQL text search)
- `prometheus` (metrics unavailable, logs only)
- `loki` (logs to stdout only)
- `grafana` (use Prometheus API directly)

**RunRecord Format:**

```json
{
  "run_id": "550e8400-e29b-41d4-a716-446655440001",
  "timestamp": "2024-12-26T12:00:01.000Z",
  "event_type": "adapter_resolution_degraded",
  "status": "success",
  "severity": "degraded",
  "adapter_id": "meilisearch",
  "error": {
    "code": "ENV_VAR_MISSING",
    "message": "Optional environment variable not set",
    "missing_variables": ["MEILISEARCH_HOST", "MEILISEARCH_API_KEY"],
    "fallback": "PostgreSQL text search",
    "impact": "Slower full-text search, no fuzzy matching"
  },
  "system_ready": true,
  "continue": true
}
```

**Example Warning Message:**

```
WARNING: Optional adapter 'meilisearch' not configured

Missing environment variables:
- MEILISEARCH_HOST
- MEILISEARCH_API_KEY

Impact: Full-text search will use PostgreSQL fallback
- Slower query performance
- No typo tolerance
- No fuzzy matching

Resolution (optional):
1. Provision Meilisearch on Northflank
2. Add MEILISEARCH_HOST and MEILISEARCH_API_KEY to .env
3. Restart n8n

System continuing in degraded mode.
```

### Category 3: OPTIONAL Failures

**Definition:** Adapter provides enhanced features but is not required.

**Behavior:** Log info message, emit info RunRecord, continue normally.

**Affected Adapters:**
- `n8n-mcp` (manual tool registration)
- `n8n-workflows-mcp` (manual workflow discovery)
- `tailscale` (local-only access)

**RunRecord Format:**

```json
{
  "run_id": "550e8400-e29b-41d4-a716-446655440002",
  "timestamp": "2024-12-26T12:00:02.000Z",
  "event_type": "adapter_resolution_optional",
  "status": "success",
  "severity": "info",
  "adapter_id": "n8n-mcp",
  "error": {
    "code": "ADAPTER_DISABLED",
    "message": "Optional adapter not enabled",
    "features_unavailable": ["auto_tool_discovery", "llm_tool_registration"]
  },
  "system_ready": true,
  "continue": true
}
```

---

## Runtime Adapter Execution

### Execution Flow

When a tool executes with an adapter:

```javascript
async function executeToolWithAdapter(tool, adapter, input) {
  // 1. Resolve adapter config
  const config = resolveAdapterConfig(adapter);

  // 2. Validate config is present
  const validation = validateAdapterConfig(adapter.adapter_id, config);
  if (!validation.valid) {
    // Emit RunRecord based on severity
    if (adapter.critical) {
      throw new AdapterConfigError(validation.message);
    } else {
      logger.warn(`Adapter ${adapter.adapter_id} unavailable: ${validation.message}`);
      // Use fallback or continue
    }
  }

  // 3. Execute operation
  const result = await adapter.execute(tool.adapter_operation, input, config);

  // 4. Emit success RunRecord
  emitRunRecord({
    run_id: crypto.randomUUID(),
    tool_id: tool.tool_id,
    adapter_id: adapter.adapter_id,
    operation: tool.adapter_operation,
    status: "success",
    timestamp: new Date().toISOString()
  });

  return result;
}
```

### Adapter Execution Timeout

Each adapter operation enforces timeout:

```javascript
async function executeWithTimeout(operation, timeoutMs) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const result = await operation({ signal: controller.signal });
    clearTimeout(timeoutId);
    return result;
  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new AdapterTimeoutError(`Operation exceeded ${timeoutMs}ms timeout`);
    }
    throw error;
  }
}
```

**Timeout by Adapter:**

| Adapter | Operation | Timeout |
|---------|-----------|---------|
| supabase-postgres | query | 30s |
| supabase-postgres | vector_search | 10s |
| qdrant-vector | search | 10s |
| qdrant-vector | upsert | 30s |
| meilisearch | search | 5s |
| cloudflare-r2 | put_object | 60s |
| cloudflare-r2 | get_object | 30s |
| prometheus | query_metrics | 30s |
| loki | query_logs | 30s |
| livekit | create_room | 10s |

---

## Dynamic Reconfiguration

### Runtime Adapter Re-resolution

Adapters can be re-resolved at runtime without restart:

```javascript
// Reload environment variables
function reloadAdapterConfig(adapterId) {
  const adapter = registry.getAdapter(adapterId);
  const config = {};

  for (const varName of adapter.config_required) {
    config[varName] = process.env[varName];
  }

  adapter.resolved_config = config;
  logger.info(`Adapter ${adapterId} re-resolved`);

  return adapter;
}
```

**Triggered by:**
- SIGHUP signal to n8n process
- Manual API call to `POST /api/adapters/reload`
- Config file change detected

**Validation after reload:**

```javascript
const reloadResult = {
  adapter_id: adapterId,
  previous_status: "failed",
  new_status: "healthy",
  timestamp: new Date().toISOString(),
  changes: {
    fixed: ["SUPABASE_URL", "SUPABASE_ANON_KEY"],
    still_missing: []
  }
};
```

---

## Runtime Adapter Resolution Table

| Adapter ID | Required Env Vars | Optional Env Vars | Critical? | Fallback |
|-----------|------------------|-------------------|-----------|----------|
| **supabase-postgres** | SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_DB, SUPABASE_HOST, SUPABASE_USER, SUPABASE_PASSWORD | SUPABASE_PORT, SUPABASE_SERVICE_KEY | YES | None |
| **qdrant-vector** | QDRANT_URL, QDRANT_API_KEY | QDRANT_COLLECTION | YES | None |
| **meilisearch** | MEILISEARCH_HOST, MEILISEARCH_API_KEY | - | NO | PostgreSQL text search |
| **cloudflare-r2** | R2_ENDPOINT, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET | R2_REGION | YES | None |
| **prometheus** | PROMETHEUS_URL | PROMETHEUS_API_KEY | NO | Logs only |
| **loki** | LOKI_URL | LOKI_API_KEY, LOKI_USERNAME, LOKI_PASSWORD | NO | Stdout |
| **grafana** | GRAFANA_URL | GRAFANA_API_KEY | NO | Prometheus API |
| **livekit** | LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET | - | YES | None |

---

## Troubleshooting Environment Resolution

### Symptom: Adapter fails to initialize

**Diagnosis:**
```bash
# Check adapter initialization log
cat /home/node/.n8n/data/adapter-initialization.jsonl | jq '.'
```

**Common Causes:**
1. Environment variable not set in .env
2. Environment variable set but invalid format
3. .env file not loaded (wrong location, syntax error)

**Resolution:**
```bash
# 1. Verify .env exists and is readable
ls -la /path/to/samwise/.env

# 2. Check variable syntax (no spaces around =)
grep SUPABASE_URL .env

# 3. Test variable loading
docker compose config

# 4. Restart services
docker compose restart n8n
```

### Symptom: Adapter works at startup but fails at runtime

**Diagnosis:**
```bash
# Check runtime adapter status
curl http://localhost:5678/api/adapters/status
```

**Common Causes:**
1. Environment variable changed after startup
2. Cloud service went down
3. API key expired
4. Network connectivity issue

**Resolution:**
```bash
# 1. Reload adapter config
curl -X POST http://localhost:5678/api/adapters/reload

# 2. Check cloud service status
# (provider-specific dashboards)

# 3. Regenerate API keys if expired

# 4. Test connectivity
curl -I $SUPABASE_URL
```

---

## Summary

**Resolution Priority:** Tool override → Adapter default → Global env var

**Startup Validation:** Load registry → Resolve env vars → Validate config → Classify status → Emit RunRecord → Halt if critical failed

**Failure Categories:**
- **CRITICAL:** Halt immediately (Supabase, Qdrant, R2, LiveKit)
- **DEGRADED:** Continue with fallback (Meilisearch, Prometheus, Loki, Grafana)
- **OPTIONAL:** Log info only (MCP servers, Tailscale)

**Runtime Behavior:** Timeout enforcement, retry policies, error normalization, RunRecord emission

**Next:** Dry-Run Validation Paths (STEP 7.4)
