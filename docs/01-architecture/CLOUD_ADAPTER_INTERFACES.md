# Cloud Adapter Interface Specifications

## Purpose
**DEFINITIVE** interface contracts for all cloud service adapters.

**PRINCIPLE:** Tools reference adapters, not services. Adapters handle provider-specific wiring.

**CONSTRAINT:** INTERFACES ONLY. NO IMPLEMENTATION CODE.

---

## Adapter Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    TOOL LAYER                             │
│  (ToolSpec workflows, n8n nodes, business logic)          │
└────────────────────┬─────────────────────────────────────┘
                     │
                     │ Reference by adapter_id
                     │
┌────────────────────▼─────────────────────────────────────┐
│                  ADAPTER LAYER                            │
│  - Abstract provider specifics                            │
│  - Handle connection pooling                              │
│  - Normalize error responses                              │
│  - Enforce timeout/retry rules                            │
└────────────────────┬─────────────────────────────────────┘
                     │
                     │ HTTP/REST calls
                     │
┌────────────────────▼─────────────────────────────────────┐
│                 CLOUD SERVICES                            │
│  Supabase, Qdrant, Meilisearch, R2, Grafana, LiveKit     │
└───────────────────────────────────────────────────────────┘
```

**Rules:**
1. Tools MUST reference adapters by `adapter_id`
2. Tools MUST NOT reference cloud URLs directly
3. Adapters MUST declare `execution_target`
4. Adapters MUST handle all provider-specific quirks
5. Adapters MUST normalize error responses

---

## Adapter Registry

Each adapter is registered in `/home/node/.n8n/data/adapter-registry.json`:

```json
{
  "adapter_id": "supabase-postgres",
  "name": "Supabase PostgreSQL Adapter",
  "version": "1.0.0",
  "provider": "supabase",
  "service": "postgresql",
  "execution_target": {
    "mode": "cloud",
    "provider": "supabase",
    "region": "auto",
    "service": "postgresql"
  },
  "interface": "SupabasePostgresAdapter",
  "enabled": true,
  "capabilities": ["query", "vector_search", "pgvector"]
}
```

---

## Adapter 1: SupabasePostgresAdapter

**Purpose:** PostgreSQL queries + pgvector similarity search

### Interface Specification

```typescript
interface SupabasePostgresAdapter {
  // Metadata
  adapter_id: "supabase-postgres";
  version: "1.0.0";
  provider: "supabase";
  service: "postgresql";

  // Required Configuration (from ENV)
  config: {
    SUPABASE_URL: string;              // Base URL
    SUPABASE_ANON_KEY: string;         // Public API key
    SUPABASE_SERVICE_KEY?: string;     // Admin override
    SUPABASE_DB: string;               // Database name
    SUPABASE_HOST: string;             // Database host
    SUPABASE_PORT: number;             // Database port
    SUPABASE_USER: string;             // Database user
    SUPABASE_PASSWORD: string;         // Database password
  };

  // Operations
  operations: {
    // Execute SQL query
    query: {
      input: {
        sql: string;                   // SQL query (SELECT, INSERT, UPDATE, DELETE)
        params?: any[];                // Query parameters (prepared statements)
      };
      output: {
        rows: any[];                   // Query result rows
        rowCount: number;              // Number of rows affected/returned
        fields: FieldMetadata[];       // Column metadata
      };
      timeout: 30000;                  // 30 seconds
      retry: {
        policy: "none";                // No retries for writes
        max_attempts: 1;
      };
    };

    // Vector similarity search (pgvector)
    vector_search: {
      input: {
        table: string;                 // Table name with vector column
        vector_column: string;         // Name of vector column
        query_vector: number[];        // Query embedding
        limit?: number;                // Max results (default: 10)
        threshold?: number;            // Cosine similarity threshold (default: 0.0)
        filters?: Record<string, any>; // Additional WHERE clause filters
      };
      output: {
        results: Array<{
          id: string | number;
          similarity: number;          // Cosine similarity score
          data: any;                   // Row data
        }>;
        count: number;
      };
      timeout: 10000;                  // 10 seconds
      retry: {
        policy: "exponential_backoff";
        max_attempts: 3;
        base_delay_ms: 1000;
        max_delay_ms: 5000;
      };
    };

    // Health check
    health_check: {
      input: {};
      output: {
        healthy: boolean;
        latency_ms: number;
        error?: string;
      };
      timeout: 5000;                   // 5 seconds
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };
  };

  // Failure Modes
  failure_modes: {
    CONNECTION_FAILED: {
      severity: "error";
      halt: true;
      message: "Supabase connection failed - check SUPABASE_URL and credentials";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    QUERY_FAILED: {
      severity: "error";
      halt: true;
      message: "SQL query execution failed";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    TIMEOUT: {
      severity: "error";
      halt: true;
      message: "Query exceeded timeout threshold";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    VECTOR_COLUMN_MISSING: {
      severity: "error";
      halt: true;
      message: "pgvector column not found in table";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };
  };
}
```

### Environment Resolution

| Variable | Required | Validation | Fallback |
|----------|----------|------------|----------|
| `SUPABASE_URL` | YES | Must be valid HTTPS URL | None - FAIL |
| `SUPABASE_ANON_KEY` | YES | Non-empty string | None - FAIL |
| `SUPABASE_SERVICE_KEY` | NO | Valid JWT format | Use ANON_KEY |
| `SUPABASE_DB` | YES | Non-empty string | Default: "postgresql" |
| `SUPABASE_HOST` | YES | Valid hostname | Extract from URL |
| `SUPABASE_PORT` | NO | 1024-65535 | Default: 5432 |
| `SUPABASE_USER` | YES | Non-empty string | Default: "postgres" |
| `SUPABASE_PASSWORD` | YES | Non-empty string | None - FAIL |

### Adapter Contract

**GUARANTEES:**
- All SQL queries use prepared statements (NO injection)
- Vector search returns cosine similarity scores (0-1)
- Timeouts are enforced per-operation
- No automatic retries on write operations
- Connection pooling handled internally
- All errors map to standardized failure modes

**VIOLATIONS:**
- Direct TCP connections to PostgreSQL (FORBIDDEN)
- Raw credential passthrough (FORBIDDEN)
- Bypassing adapter timeout (FORBIDDEN)

---

## Adapter 2: QdrantVectorAdapter

**Purpose:** Vector similarity search and indexing

### Interface Specification

```typescript
interface QdrantVectorAdapter {
  // Metadata
  adapter_id: "qdrant-vector";
  version: "1.0.0";
  provider: "northflank" | "fly.io";
  service: "qdrant";

  // Required Configuration (from ENV)
  config: {
    QDRANT_URL: string;               // Base API URL
    QDRANT_API_KEY: string;           // API key
    QDRANT_COLLECTION?: string;       // Default collection name
  };

  // Operations
  operations: {
    // Search vectors by similarity
    search: {
      input: {
        collection: string;           // Collection name
        vector: number[];             // Query vector
        limit?: number;               // Max results (default: 10)
        score_threshold?: number;     // Min similarity score (default: 0.0)
        payload_filter?: object;      // Payload filter (Qdrant filter syntax)
        with_payload?: boolean;       // Include payload in results (default: true)
        with_vector?: boolean;        // Include vectors in results (default: false)
      };
      output: {
        results: Array<{
          id: string | number;
          score: number;              // Similarity score (0-1)
          payload?: object;           // Associated payload
          vector?: number[];          // Result vector (if requested)
        }>;
        status: "ok" | "error";
        time: number;                 // Search time in seconds
      };
      timeout: 10000;                 // 10 seconds
      retry: {
        policy: "exponential_backoff";
        max_attempts: 3;
        base_delay_ms: 500;
        max_delay_ms: 3000;
      };
    };

    // Upsert vectors
    upsert: {
      input: {
        collection: string;
        points: Array<{
          id: string | number;
          vector: number[];
          payload?: object;
        }>;
      };
      output: {
        status: "completed" | "error";
        upserted_count: number;
        operation_id: number;
      };
      timeout: 30000;                 // 30 seconds
      retry: {
        policy: "none";               // No retries on write
        max_attempts: 1;
      };
    };

    // Create collection
    create_collection: {
      input: {
        collection: string;
        vector_size: number;          // Vector dimensionality
        distance: "Cosine" | "Euclid" | "Dot";
        payload_schema?: Record<string, "keyword" | "integer" | "float" | "bool">;
      };
      output: {
        status: "ok" | "error";
        result: boolean;
      };
      timeout: 5000;                  // 5 seconds
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };

    // Health check
    health_check: {
      input: {};
      output: {
        healthy: boolean;
        latency_ms: number;
        collections_count: number;
        error?: string;
      };
      timeout: 5000;
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };
  };

  // Failure Modes
  failure_modes: {
    CONNECTION_FAILED: {
      severity: "error";
      halt: true;
      message: "Qdrant connection failed - check QDRANT_URL and API key";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    COLLECTION_NOT_FOUND: {
      severity: "error";
      halt: true;
      message: "Qdrant collection does not exist - create collection first";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    TIMEOUT: {
      severity: "error";
      halt: true;
      message: "Qdrant operation exceeded timeout";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    VECTOR_MISMATCH: {
      severity: "error";
      halt: true;
      message: "Vector dimensionality does not match collection";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };
  };
}
```

### Environment Resolution

| Variable | Required | Validation | Fallback |
|----------|----------|------------|----------|
| `QDRANT_URL` | YES | Must be valid HTTPS URL | None - FAIL |
| `QDRANT_API_KEY` | YES | Non-empty string | None - FAIL |
| `QDRANT_COLLECTION` | NO | Non-empty string | Use operation parameter |

### Adapter Contract

**GUARANTEES:**
- All vectors are normalized before storage
- Similarity scores are 0-1 range
- Timeouts enforced per-operation
- No automatic retries on write operations
- Collection existence validated before operations

---

## Adapter 3: MeilisearchAdapter

**Purpose:** Full-text search with fuzzy matching

### Interface Specification

```typescript
interface MeilisearchAdapter {
  // Metadata
  adapter_id: "meilisearch";
  version: "1.0.0";
  provider: "northflank";
  service: "meilisearch";

  // Required Configuration (from ENV)
  config: {
    MEILISEARCH_HOST: string;         // Base API URL
    MEILISEARCH_API_KEY: string;      // Master API key
  };

  // Operations
  operations: {
    // Search documents
    search: {
      input: {
        index: string;                // Index name
        q: string;                    // Search query
        limit?: number;               // Max results (default: 20)
        offset?: number;              // Pagination offset (default: 0)
        filter?: string | object;     // Filter expression
        sort?: Array<string>;         // Sort criteria
        facets?: Array<string>;       // Facets to compute
        highlight?: boolean;          // Highlight matches (default: true)
        cropping?: boolean;           // Crop results (default: false)
      };
      output: {
        hits: Array<{
          id: string;
          title?: string;
          content?: string;
          _formatted?: object;        // Highlighted/cropped text
          _ranking_score: number;     // Relevance score
        }>;
        estimated_total_hits: number;
        processing_time_ms: number;
        query: string;
        limit: number;
        offset: number;
      };
      timeout: 5000;                  // 5 seconds
      retry: {
        policy: "exponential_backoff";
        max_attempts: 3;
        base_delay_ms: 300;
        max_delay_ms: 2000;
      };
    };

    // Add/update documents
    index_documents: {
      input: {
        index: string;
        documents: Array<object>;     // Documents to index
        primary_key?: string;         // Primary key field
      };
      output: {
        update_id: number;
        status: "enqueued" | "processed";
        type: "documentsAddition";
      };
      timeout: 30000;                 // 30 seconds
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };

    // Create index
    create_index: {
      input: {
        uid: string;                  // Index unique identifier
        primary_key?: string;
      };
      output: {
        uid: string;
        primary_key?: string;
        created_at: string;           // ISO8601 timestamp
        updated_at: string;           // ISO8601 timestamp
      };
      timeout: 10000;                 // 10 seconds
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };

    // Health check
    health_check: {
      input: {};
      output: {
        healthy: boolean;
        latency_ms: number;
        indexes_count: number;
        error?: string;
      };
      timeout: 5000;
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };
  };

  // Failure Modes
  failure_modes: {
    CONNECTION_FAILED: {
      severity: "warning";
      halt: false;
      message: "Meilisearch unavailable - falling back to PostgreSQL text search";
      run_record: {
        status: "success";
        critic_verdict: "pass";
        warnings: [{
          code: "SEARCH_DEGRADED",
          severity: "warning"
        }];
      };
    };

    INDEX_NOT_FOUND: {
      severity: "error";
      halt: true;
      message: "Meilisearch index does not exist";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    TIMEOUT: {
      severity: "warning";
      halt: false;
      message: "Meilisearch timeout - using fallback search";
      run_record: {
        status: "success";
        critic_verdict: "pass";
        warnings: [{
          code: "SEARCH_TIMEOUT",
          severity: "warning"
        }];
      };
    };
  };
}
```

### Environment Resolution

| Variable | Required | Validation | Fallback |
|----------|----------|------------|----------|
| `MEILISEARCH_HOST` | YES | Must be valid HTTPS URL | None - DEGRADED |
| `MEILISEARCH_API_KEY` | YES | Non-empty string | None - DEGRADED |

### Adapter Contract

**GUARANTEES:**
- Full-text search with typo tolerance
- Fuzzy matching enabled by default
- Highlighting and cropping support
- Degraded mode falls back to PostgreSQL

---

## Adapter 4: CloudflareR2Adapter

**Purpose:** S3-compatible object storage

### Interface Specification

```typescript
interface CloudflareR2Adapter {
  // Metadata
  adapter_id: "cloudflare-r2";
  version: "1.0.0";
  provider: "cloudflare";
  service: "r2";

  // Required Configuration (from ENV)
  config: {
    R2_ENDPOINT: string;             // S3-compatible API endpoint
    R2_ACCESS_KEY_ID: string;        // Access key ID
    R2_SECRET_ACCESS_KEY: string;    // Secret access key
    R2_BUCKET: string;               // Bucket name
    R2_REGION?: string;              // Region (default: "auto")
  };

  // Operations
  operations: {
    // Upload object
    put_object: {
      input: {
        key: string;                  // Object key (path)
        body: Buffer | string;        // Object data
        content_type?: string;        // MIME type
        metadata?: Record<string, string>; // Custom metadata
      };
      output: {
        key: string;
        version_id?: string;
        etag: string;
        location: string;
      };
      timeout: 60000;                 // 60 seconds
      retry: {
        policy: "exponential_backoff";
        max_attempts: 3;
        base_delay_ms: 1000;
        max_delay_ms: 10000;
      };
    };

    // Download object
    get_object: {
      input: {
        key: string;
        version_id?: string;
      };
      output: {
        key: string;
        body: Buffer;
        content_type: string;
        metadata: Record<string, string>;
        size: number;
      };
      timeout: 30000;                 // 30 seconds
      retry: {
        policy: "exponential_backoff";
        max_attempts: 3;
        base_delay_ms: 500;
        max_delay_ms: 5000;
      };
    };

    // Delete object
    delete_object: {
      input: {
        key: string;
        version_id?: string;
      };
      output: {
        deleted: boolean;
        key: string;
      };
      timeout: 10000;                 // 10 seconds
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };

    // List objects
    list_objects: {
      input: {
        prefix?: string;              // Key prefix
        max_keys?: number;            // Max results (default: 1000)
        continuation_token?: string;  // Pagination token
      };
      output: {
        objects: Array<{
          key: string;
          size: number;
          last_modified: string;      // ISO8601 timestamp
          etag: string;
        }>;
        is_truncated: boolean;
        next_continuation_token?: string;
      };
      timeout: 10000;
      retry: {
        policy: "exponential_backoff";
        max_attempts: 2;
        base_delay_ms: 500;
        max_delay_ms: 2000;
      };
    };

    // Presigned URL (for direct upload/download)
    presigned_url: {
      input: {
        key: string;
        expires_in?: number;         // URL expiration in seconds (default: 3600)
        operation: "get" | "put";
      };
      output: {
        url: string;
        expires_at: string;          // ISO8601 timestamp
      };
      timeout: 1000;                  // 1 second (local operation)
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };

    // Health check
    health_check: {
      input: {};
      output: {
        healthy: boolean;
        latency_ms: number;
        bucket_accessible: boolean;
        error?: string;
      };
      timeout: 5000;
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };
  };

  // Failure Modes
  failure_modes: {
    CONNECTION_FAILED: {
      severity: "error";
      halt: true;
      message: "Cloudflare R2 connection failed - check R2_ENDPOINT and credentials";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    BUCKET_NOT_FOUND: {
      severity: "error";
      halt: true;
      message: "R2 bucket does not exist - create bucket in Cloudflare dashboard";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    ACCESS_DENIED: {
      severity: "error";
      halt: true;
      message: "R2 access denied - check R2_ACCESS_KEY_ID and permissions";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    TIMEOUT: {
      severity: "error";
      halt: true;
      message: "R2 operation exceeded timeout - file may be too large";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };
  };
}
```

### Environment Resolution

| Variable | Required | Validation | Fallback |
|----------|----------|------------|----------|
| `R2_ENDPOINT` | YES | Must be valid HTTPS URL | None - FAIL |
| `R2_ACCESS_KEY_ID` | YES | Non-empty string | None - FAIL |
| `R2_SECRET_ACCESS_KEY` | YES | Non-empty string | None - FAIL |
| `R2_BUCKET` | YES | Valid bucket name | None - FAIL |
| `R2_REGION` | NO | Valid region name | Default: "auto" |

### Adapter Contract

**GUARANTEES:**
- S3-compatible API (works with any S3 client)
- Zero egress fees (Cloudflare R2 feature)
- Automatic multipart upload for large files
- Presigned URLs for direct client access

---

## Adapter 5: ObservabilityAdapters

**Purpose:** Metrics and logging (Prometheus, Loki, Grafana)

### Interface Specification

```typescript
interface ObservabilityAdapters {
  // Prometheus Adapter
  prometheus: {
    adapter_id: "prometheus";
    version: "1.0.0";
    provider: "northflank";
    service: "prometheus";

    config: {
      PROMETHEUS_URL: string;
      PROMETHEUS_API_KEY?: string;
    };

    operations: {
      query_metrics: {
        input: {
          query: string;              // PromQL query
          start?: string;             // ISO8601 start timestamp
          end?: string;               // ISO8601 end timestamp
          step?: string;              // Query resolution (default: "15s")
        };
        output: {
          result_type: "matrix" | "vector";
          result: Array<{
            metric: Record<string, string>;
            values?: Array<[number, string]>; // [timestamp, value]
            value?: [number, string];
          }>;
        };
        timeout: 30000;
        retry: {
          policy: "exponential_backoff";
          max_attempts: 2;
          base_delay_ms: 500;
          max_delay_ms: 2000;
        };
      };
    };

    failure_modes: {
      CONNECTION_FAILED: {
        severity: "info";
        halt: false;
        message: "Prometheus unavailable - metrics not collected";
      };
    };
  };

  // Loki Adapter
  loki: {
    adapter_id: "loki";
    version: "1.0.0";
    provider: "northflank";
    service: "loki";

    config: {
      LOKI_URL: string;
      LOKI_API_KEY?: string;
      LOKI_USERNAME?: string;
      LOKI_PASSWORD?: string;
    };

    operations: {
      query_logs: {
        input: {
          query: string;              // LogQL query
          start?: string;             // ISO8601 start timestamp
          end?: string;               // ISO8601 end timestamp
          limit?: number;             // Max results (default: 100)
        };
        output: {
          result: Array<{
            stream: Record<string, string>;
            values: Array<[string, string]>; // [nanosecond_timestamp, line]
          }>;
        };
        timeout: 30000;
        retry: {
          policy: "exponential_backoff";
          max_attempts: 2;
          base_delay_ms: 500;
          max_delay_ms: 2000;
        };
      };
    };

    failure_modes: {
      CONNECTION_FAILED: {
        severity: "info";
        halt: false;
        message: "Loki unavailable - logs to stdout only";
      };
    };
  };

  // Grafana Adapter (read-only dashboards)
  grafana: {
    adapter_id: "grafana";
    version: "1.0.0";
    provider: "northflank";
    service: "grafana";

    config: {
      GRAFANA_URL: string;
      GRAFANA_API_KEY?: string;
    };

    operations: {
      get_dashboard: {
        input: {
          dashboard_uid: string;      // Dashboard unique identifier
        };
        output: {
          dashboard: object;
          meta: object;
        };
        timeout: 10000;
        retry: {
          policy: "none";
          max_attempts: 1;
        };
      };
    };

    failure_modes: {
      CONNECTION_FAILED: {
        severity: "info";
        halt: false;
        message: "Grafana unavailable - use Prometheus API directly";
      };
    };
  };
}
```

---

## Adapter 6: LiveKitAdapter

**Purpose:** Real-time media processing

### Interface Specification

```typescript
interface LiveKitAdapter {
  // Metadata
  adapter_id: "livekit";
  version: "1.0.0";
  provider: "fly.io" | "koyeb";
  service: "livekit";

  // Required Configuration (from ENV)
  config: {
    LIVEKIT_URL: string;              // WebSocket/HTTP URL
    LIVEKIT_API_KEY: string;          // API key
    LIVEKIT_API_SECRET: string;       // API secret
  };

  // Operations
  operations: {
    // Create room
    create_room: {
      input: {
        name: string;                 // Room name
        empty_timeout?: number;       // Seconds to empty room (default: 300)
        max_participants?: number;    // Max participants (default: 0 = unlimited)
      };
      output: {
        sid: string;                  // Room SID
        name: string;
        empty_timeout: number;
        max_participants: number;
        creation_time: number;        // Unix timestamp
        num_participants: number;
      };
      timeout: 10000;
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };

    // List rooms
    list_rooms: {
      input: {};
      output: {
        rooms: Array<{
          sid: string;
          name: string;
          num_participants: number;
          max_participants: number;
        }>;
      };
      timeout: 5000;
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };

    // Delete room
    delete_room: {
      input: {
        room: string;                 // Room SID or name
      };
      output: {
        deleted: boolean;
      };
      timeout: 5000;
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };

    // Health check
    health_check: {
      input: {};
      output: {
        healthy: boolean;
        latency_ms: number;
        rooms_count: number;
        error?: string;
      };
      timeout: 5000;
      retry: {
        policy: "none";
        max_attempts: 1;
      };
    };
  };

  // Failure Modes
  failure_modes: {
    CONNECTION_FAILED: {
      severity: "error";
      halt: true;
      message: "LiveKit connection failed - check LIVEKIT_URL and credentials";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    ROOM_NOT_FOUND: {
      severity: "error";
      halt: true;
      message: "LiveKit room does not exist";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };

    AUTH_FAILED: {
      severity: "error";
      halt: true;
      message: "LiveKit authentication failed - check API key and secret";
      run_record: {
        status: "failure";
        critic_verdict: "fail";
      };
    };
  };
}
```

---

## Adapter Discovery and Resolution

### Adapter Lookup

Tools resolve adapters by `adapter_id`:

```javascript
// Tool references adapter
const tool = {
  tool_id: "semantic-search",
  adapter_id: "qdrant-vector",  // ← Adapter reference
  operation: "search",
  input: { ... }
};

// Runtime resolution
const adapter = adapter_registry.resolve(tool.adapter_id);
// → Returns QdrantVectorAdapter interface
```

### Environment Resolution Priority

1. **Tool-specific override** (highest priority)
   ```javascript
   tool.config.QDRANT_URL  // Override for this tool only
   ```

2. **Adapter-level default**
   ```javascript
   adapter.config.QDRANT_URL  // Adapter default
   ```

3. **Global environment variable** (lowest priority)
   ```javascript
   process.env.QDRANT_URL  // System default
   ```

### Validation Rules

**ToolSpec MUST:**
- Reference `adapter_id` (not cloud URLs)
- Specify `operation` from adapter interface
- Provide inputs matching operation schema
- Declare `adapter_capabilities` as constraints

**ToolSpec MUST NOT:**
- Reference `SUPABASE_URL`, `QDRANT_URL`, etc. directly
- Hardcode cloud service endpoints
- Assume provider-specific quirks
- Bypass adapter timeout/retry rules

**Validation Enforcement:**
```javascript
// In toolforge_validate_toolspec.json
if (toolspec.credentials_required) {
  const forbidden_patterns = [
    /SUPABASE_URL/, /QDRANT_URL/, /MEILISEARCH_HOST/,
    /R2_ENDPOINT/, /GRAFANA_URL/, /LIVEKIT_URL/
  ];

  for (const cred of toolspec.credentials_required) {
    if (forbidden_patterns.some(pattern => pattern.test(cred))) {
      issues.push({
        field: "credentials_required",
        constraint: "use_adapter_not_direct_url",
        message: `Tool must use adapter_id, not direct cloud URL: ${cred}`,
        severity: "error"
      });
    }
  }
}
```

---

## Adapter Lifecycle

### Initialization (Startup)

```javascript
// 1. Load adapter registry
const registry = loadAdapterRegistry('/home/node/.n8n/data/adapter-registry.json');

// 2. Resolve environment variables
for (const adapter of registry.adapters) {
  adapter.resolve_env(process.env);
}

// 3. Validate adapter configurations
const validation = registry.validate_all();
if (!validation.valid) {
  // Emit RunRecord with validation errors
  // Halt if any CRITICAL adapter fails
}

// 4. Health check all adapters
const health = await registry.health_check_all();
// Log warnings for OPTIONAL adapters that fail
// Halt if any CRITICAL adapter fails
```

### Operation Execution (Runtime)

```javascript
// 1. Tool specifies adapter_id and operation
const result = await adapter.execute(tool.operation, tool.input);

// 2. Adapter handles:
//    - Input validation
//    - Environment resolution
//    - HTTP request construction
//    - Timeout enforcement
//    - Retry logic
//    - Error normalization
//    - Response parsing

// 3. Result includes:
//    - Operation output (matching interface spec)
//    - Execution metadata (latency, retries)
//    - RunRecord entry
```

### Failure Handling

```javascript
try {
  const result = await adapter.execute(operation, input);
} catch (error) {
  // Adapter normalizes errors to failure_modes
  const failure_mode = adapter.classify_error(error);

  // Emit RunRecord based on failure_mode.severity
  switch (failure_mode.severity) {
    case "error":
      // Halt execution, emit failure RunRecord
      break;
    case "warning":
      // Continue with fallback, emit degraded RunRecord
      break;
    case "info":
      // Continue normally, emit info RunRecord
      break;
  }
}
```

---

## Summary Table

| Adapter | Provider | Service | Critical? | Fallback |
|---------|----------|---------|-----------|----------|
| **supabase-postgres** | Supabase | PostgreSQL + pgvector | YES | None |
| **qdrant-vector** | Northflank/Fly.io | Vector DB | YES | None |
| **meilisearch** | Northflank | Full-text search | NO | PostgreSQL text search |
| **cloudflare-r2** | Cloudflare | Object storage | YES | None |
| **prometheus** | Northflank | Metrics storage | NO | Logs only |
| **loki** | Northflank | Log aggregation | NO | Stdout |
| **grafana** | Northflank | Metrics UI | NO | Prometheus API |
| **livekit** | Fly.io/Koyeb | Real-time media | YES | None |

**Next:** ToolSpec → Adapter mapping rules (STEP 7.2)
