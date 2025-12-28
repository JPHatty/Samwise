# Adapter Interface Contracts

## Purpose
**DEFINITIVE** specification of adapter interfaces for all Supabase-bound operations.

**PRINCIPLE:** Define contracts upfront to prevent painting into corners later.

**STATUS:** DESIGN ONLY - NO CODE, NO EXAMPLES, NO SDK USAGE

---

## Contract Template

Each adapter contract specifies:
- **Adapter ID:** Unique identifier
- **Allowed Operations:** Read-only vs. future write capabilities
- **Required Inputs:** Data structures needed
- **Returned Outputs:** Response structures
- **Failure Modes:** All possible error conditions
- **Explicit Denials:** What the adapter is NEVER allowed to do

---

## Adapter 1: ToolForge → Supabase (Run Records)

### Adapter Identity
- **Adapter ID:** `toolforge-runrecords`
- **Provider:** internal (n8n ToolForge)
- **Service:** Supabase PostgreSQL
- **Version:** 1.0.0

### Allowed Operations

**READ Operations:**
- ✅ Query run_records by run_id
- ✅ Query run_records by intent_id
- ✅ Query run_records by tool_id
- ✅ Query run_records by date range
- ✅ Query run_records by status
- ✅ Query run_artifacts by run_id
- ✅ Query audit_log by timestamp range
- ✅ Query validation_log by gate

**WRITE Operations:**
- ✅ INSERT into run_records (new execution record)
- ✅ INSERT into run_artifacts (execution artifacts)
- ✅ INSERT into audit_log (audit events)
- ✅ INSERT into validation_log (validation results)
- ✅ INSERT into adapter_events (adapter lifecycle)
- ✅ UPDATE run_artifacts (rolled_back flag only)
- ✅ UPDATE tools (is_active flag only for deprecation)
- ✅ UPDATE adapters (health_status only)

**FORBIDDEN Operations:**
- ❌ DELETE from any table
- ❌ UPDATE on audit_log (immutable)
- ❌ UPDATE on run_records (immutable)
- ❌ UPDATE on validation_log (immutable)
- ❌ UPDATE on adapter_events (immutable)
- ❌ UPDATE on tool definitions (immutable)
- ❌ TRUNCATE any table
- ❌ DROP any table
- ❌ ALTER schema (DDL operations)
- ❌ CREATE/ALTER/DROP policies
- ❌ CREATE/ALTER/DROP functions
- ❌ CREATE/ALTER/DROP triggers

### Required Inputs

**For INSERT run_records:**
- run_id: TEXT (UUID)
- intent_id: TEXT
- tool_id: TEXT
- tool_version: TEXT
- started_at: TIMESTAMPTZ
- finished_at: TIMESTAMPTZ
- status: TEXT (enum)
- inputs_hash: TEXT (SHA-256)
- critic_verdict: TEXT (enum)
- metadata: JSONB
- errors: JSONB (array, optional)
- warnings: JSONB (array, optional)

**For INSERT audit_log:**
- audit_id: TEXT (UUID)
- event_type: TEXT
- actor: TEXT
- operation: TEXT
- target_type: TEXT
- target_id: TEXT
- details: JSONB
- run_id: TEXT (optional)

**For INSERT validation_log:**
- validation_id: TEXT (UUID)
- gate: TEXT
- intent_id: TEXT (optional)
- tool_id: TEXT (optional)
- validation_result: TEXT (enum)
- halted: BOOLEAN
- errors: JSONB (optional)

### Returned Outputs

**Query Response Structure:**
- Success: Array of matching records (JSON)
- Failure: Error object with code, message, details

**INSERT Response Structure:**
- Success: Confirmation with inserted record ID
- Failure: Error object with constraint violation details

**Error Response Structure:**
- code: TEXT (enum: AUTH_FAILED, CONSTRAINT_VIOLATION, TIMEOUT, SCHEMA_MISMATCH)
- message: TEXT (human-readable)
- details: JSONB (error-specific data)

### Failure Modes

**1. Authentication Failure**
- **Code:** AUTH_FAILED
- **Cause:** Invalid JWT token or missing API key
- **Detection:** HTTP 401 response from Supabase
- **Recovery:** Halt execution, emit CRITICAL RunRecord, require operator intervention
- **Retry:** DO NOT retry (auth failure is persistent)

**2. Constraint Violation**
- **Code:** CONSTRAINT_VIOLATION
- **Cause:** NOT NULL, UNIQUE, CHECK, or FK constraint violated
- **Detection:** HTTP 400 with constraint error details
- **Recovery:** Halt execution, emit ERROR RunRecord, fix input data
- **Retry:** DO NOT retry (constraint violation is data error)

**3. Timeout**
- **Code:** TIMEOUT
- **Cause:** Query exceeds 30-second timeout
- **Detection:** HTTP 408 or client-side timeout
- **Recovery:** Log warning, retry once, then fail
- **Retry:** Retry once with exponential backoff (max 2 attempts total)

**4. Schema Mismatch**
- **Code:** SCHEMA_MISMATCH
- **Cause:** Table or column does not exist
- **Detection:** HTTP 400 with "column does not exist" or "relation does not exist"
- **Recovery:** CRITICAL - schema out of sync, halt all operations
- **Retry:** DO NOT retry (schema mismatch requires manual intervention)

**5. Network Error**
- **Code:** NETWORK_ERROR
- **Cause:** Connection refused, DNS failure, network unreachable
- **Detection:** curl/network layer error
- **Recovery:** Log warning, retry with exponential backoff (max 3 attempts)
- **Retry:** Yes, up to 3 attempts with 500ms, 1000ms, 2000ms backoff

**6. Boundary Violation**
- **Code:** BOUNDARY_VIOLATION
- **Cause:** Attempted forbidden operation (DELETE, UPDATE on immutable table)
- **Detection:** Client-side validation gate rejection
- **Recovery:** CRITICAL - validation gate failed, should not reach adapter
- **Retry:** DO NOT retry (this is a code logic error)

### Explicit Denials

**This adapter is NEVER allowed to:**
- ❌ Use service_role key for any operation
- ❌ Delete from audit_log, run_records, or any append-only table
- ❌ Modify tool definitions (only is_active flag for deprecation)
- ❌ Execute DDL statements (CREATE, ALTER, DROP)
- ❌ Modify RLS policies
- ❌ Access tables outside the defined schema
- ❌ Bypass validation gates
- ❌ Perform bulk operations without explicit limits
- ❌ Execute unparameterized SQL (SQL injection risk)

---

## Adapter 2: Health Check → Supabase (Connectivity)

### Adapter Identity
- **Adapter ID:** `supabase-health`
- **Provider:** supabase
- **Service:** postgresql (via REST API)
- **Version:** 1.0.0

### Allowed Operations

**READ Operations:**
- ✅ HTTP HEAD request to /rest/v1/ (connectivity check)
- ✅ HTTP GET to /rest/v1/ with API key header (authentication check)

**WRITE Operations:**
- ❌ NONE (read-only adapter)

**FORBIDDEN Operations:**
- ❌ All write operations
- ❌ All data retrieval queries
- ❌ All schema operations

### Required Inputs

**For Health Check:**
- SUPABASE_URL: TEXT (HTTPS URL)
- SUPABASE_ANON_KEY: TEXT (JWT)
- timeout_ms: INTEGER (default: 10000)

### Returned Outputs

**Success Response:**
- status: TEXT ("healthy")
- http_status: INTEGER (200)
- response_time_ms: INTEGER
- server: TEXT (e.g., "cloudflare")
- content_type: TEXT (e.g., "application/openapi+json")

**Failure Response:**
- status: TEXT ("unhealthy")
- error_code: TEXT
- error_message: TEXT
- http_status: INTEGER (if HTTP response received)

### Failure Modes

**1. Authentication Failure**
- **Code:** AUTH_FAILED
- **Cause:** Invalid ANON_KEY
- **Detection:** HTTP 401 response
- **Recovery:** Halt, emit CRITICAL RunRecord
- **Retry:** DO NOT retry

**2. Connection Failure**
- **Code:** CONNECTION_FAILED
- **Cause:** Network unreachable, DNS failure, timeout
- **Detection:** curl/network error
- **Recovery:** Log warning, retry once
- **Retry:** Yes, once with 1000ms backoff

**3. Unexpected Response**
- **Code:** UNEXPECTED_RESPONSE
- **Cause:** HTTP 5xx, 4xx (not 401)
- **Detection:** HTTP status not in {200, 401}
- **Recovery:** Log warning, mark as degraded
- **Retry:** DO NOT retry (service issue, persistent)

### Explicit Denials

**This adapter is NEVER allowed to:**
- ❌ Use service_role key
- ❌ Execute any SQL query
- ❌ Access any table data
- ❌ Perform write operations
- ❌ Access admin endpoints
- ❌ Modify any configuration

---

## Adapter 3: Metrics → Supabase (Read-Only Queries)

### Adapter Identity
- **Adapter ID:** `supabase-metrics`
- **Provider:** internal
- **Service:** Supabase PostgreSQL
- **Version:** 1.0.0 (FUTURE - not implemented in STEP 10)

### Allowed Operations

**READ Operations (FUTURE):**
- ✅ Aggregate queries on run_records (COUNT, AVG, MAX, MIN)
- ✅ Time-series queries on run_records (group by started_at)
- ✅ Filter queries on status, critic_verdict, execution_mode
- ✅ JOIN queries between run_records and execution_stats

**WRITE Operations:**
- ❌ NONE (read-only metrics adapter)

**FORBIDDEN Operations:**
- ❌ All write operations
- ❌ DELETE operations
- ❌ DDL operations

### Required Inputs (FUTURE)

**For Metrics Query:**
- query_type: TEXT (enum: count_by_status, avg_duration, error_rate, etc.)
- time_range: JSONB (start_date, end_date)
- filters: JSONB (optional filter conditions)
- aggregation: TEXT (SUM, COUNT, AVG, etc.)

### Returned Outputs (FUTURE)

**Success Response:**
- results: JSONB (aggregated metrics)
- query_time_ms: INTEGER
- row_count: INTEGER

**Failure Response:**
- error_code: TEXT
- error_message: TEXT
- query: TEXT (for debugging)

### Failure Modes (FUTURE)

**1. Query Timeout**
- **Code:** QUERY_TIMEOUT
- **Cause:** Complex query exceeds 30-second timeout
- **Detection:** HTTP 408 or client timeout
- **Recovery:** Log warning, simplify query, retry
- **Retry:** Yes, once with simplified query

**2. Schema Mismatch**
- **Code:** SCHEMA_MISMATCH
- **Cause:** Column or table does not exist
- **Detection:** HTTP 400 with SQL error
- **Recovery:** CRITICAL - metrics adapter broken
- **Retry:** DO NOT retry

### Explicit Denials

**This adapter is NEVER allowed to:**
- ❌ Perform write operations
- ❌ Delete any data
- ❌ Access individual rows without aggregation (privacy protection)
- ❌ Use service_role key
- ❌ Modify schema
- ❌ Access audit_log directly (use summary views only)

---

## Cross-Adapter Constraints

### Universal Prohibitions

**ALL adapters are NEVER allowed to:**

1. **Use service_role key** (forbidden until migrations)
2. **Delete from append-only tables** (audit_log, run_records, validation_log, adapter_events)
3. **Modify immutable data** (run_records after creation, tool versions)
4. **Execute DDL statements** (CREATE, ALTER, DROP on schema objects)
5. **Modify RLS policies** (policy management is manual operation only)
6. **Bypass validation gates** (all writes must go through validation)
7. **Perform unparameterized queries** (SQL injection prevention)
8. **Access tables outside defined schema** (no user tables, no auth schema)
9. **Execute transactions without explicit rollback** (all writes must be revertible)
10. **Access other users' data** (no cross-tenant data access)

### Credential Boundaries

**ANON_KEY:**
- ✅ Allowed for: Health checks, future public read-only endpoints
- ❌ Forbidden for: Any write operations
- ❌ Forbidden for: System-level operations

**SERVICE_ROLE_KEY:**
- 🚫 **FORBIDDEN** until migrations step
- 🚫 **FORBIDDEN** in application code
- 🚫 **FORBIDDEN** in adapter operations
- ✅ Allowed for: Manual migrations only (future step)

**INTERNAL_SYSTEM_KEY:**
- ✅ Allowed for: All internal system operations
- ✅ Allowed for: ToolForge writes (run_records, audit_log)
- ✅ Allowed for: Adapter lifecycle events
- ❌ Forbidden for: Schema modifications
- ❌ Forbidden for: Policy modifications

### Operation Boundaries

**READ-ONLY Adapters (supabase-health, supabase-metrics):**
- ✅ Can SELECT data
- ❌ Cannot INSERT, UPDATE, DELETE
- ❌ Cannot execute DDL
- ❌ Cannot modify RLS policies

**WRITE Adapters (toolforge-runrecords):**
- ✅ Can INSERT into allowed tables
- ✅ Can UPDATE specific flags (is_active, rolled_back, health_status)
- ❌ Cannot DELETE from any table
- ❌ Cannot UPDATE immutable columns
- ❌ Cannot execute DDL

**BOUNDARY ENFORCEMENT:**
- All adapter operations MUST go through validation gates first
- Validation gates reject forbidden operations BEFORE adapter execution
- Adapter MUST validate operation type against allowed operations
- Adapter MUST validate table access against table-specific access controls

---

## Contract Versioning

### Version 1.0.0 (Current)
**Date:** 2025-12-27
**Status:** FROZEN
**Adapters Defined:** 3 (toolforge-runrecords, supabase-health, supabase-metrics)

### Future Changes
**Any change to these contracts requires:**
1. Explicit documentation update
2. Version number increment
3. Review of all affected adapters
4. Re-validation of boundary enforcement
5. Re-testing of all failure modes

**Breaking changes require:**
- Major version increment (1.x → 2.0)
- Migration plan for existing data
- Rollback strategy if deployment fails
- Explicit operator approval

---

## Summary

**Adapters Defined:** 3
**Operations Specified:** Read + Write (controlled)
**Failure Modes Documented:** 6 per adapter
**Explicit Denials:** Universal + per-adapter
**Contract Status:** FROZEN - v1.0.0

**Key Guarantees:**
- No service_role usage in application code
- No DELETE operations on append-only tables
- No UPDATE on immutable data
- All writes validated before adapter execution
- All failures logged and audited

**This contract freezes the adapter interface model. Future changes require explicit review and version increment.**
