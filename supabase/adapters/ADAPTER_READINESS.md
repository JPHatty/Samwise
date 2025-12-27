# Adapter Readiness Checks

## Purpose
**DEFINITIVE** specification of adapter readiness requirements for safe invocation.

**PRINCIPLE:** Define what constitutes SAFE vs UNSAFE invocation before attempting execution.

**Reference:** STEP 10 - supabase/adapters/ADAPTER_CONTRACTS.md

---

## Adapter 1: toolforge-runrecords

### Purpose
Insert execution records, artifacts, and audit logs into Supabase from ToolForge.

### Required Inputs

**Environment Variables:**
- `SUPABASE_URL`: HTTPS URL to Supabase project
- `SUPABASE_ANON_KEY`: JWT for authentication (anon role)

**Data Structures (for INSERT run_records):**
```json
{
  "run_id": "TEXT (UUID format)",
  "intent_id": "TEXT",
  "tool_id": "TEXT",
  "tool_version": "TEXT",
  "started_at": "TIMESTAMPTZ (ISO 8601)",
  "finished_at": "TIMESTAMPTZ (ISO 8601)",
  "status": "TEXT (enum: success|failure|timeout|degraded)",
  "inputs_hash": "TEXT (SHA-256 hex)",
  "critic_verdict": "TEXT (enum: pass|fail)",
  "metadata": "JSONB",
  "errors": "JSONB (array, optional)",
  "warnings": "JSONB (array, optional)"
}
```

**Data Structures (for INSERT audit_log):**
```json
{
  "audit_id": "TEXT (UUID format)",
  "event_type": "TEXT",
  "actor": "TEXT",
  "operation": "TEXT",
  "target_type": "TEXT",
  "target_id": "TEXT",
  "details": "JSONB",
  "run_id": "TEXT (optional)"
}
```

**Data Structures (for INSERT validation_log):**
```json
{
  "validation_id": "TEXT (UUID format)",
  "gate": "TEXT",
  "intent_id": "TEXT (optional)",
  "tool_id": "TEXT (optional)",
  "validation_result": "TEXT (enum: pass|fail)",
  "halted": "BOOLEAN",
  "errors": "JSONB (optional)"
}
```

### Expected Outputs

**Success Response:**
```json
{
  "status": "success",
  "operation": "insert",
  "table": "run_records",
  "record_id": "run_id (from input)",
  "rows_affected": 1,
  "timestamp": "TIMESTAMPTZ"
}
```

**Failure Response:**
```json
{
  "status": "error",
  "error_code": "TEXT (enum below)",
  "error_message": "TEXT (human-readable)",
  "details": "JSONB (error-specific)",
  "timestamp": "TIMESTAMPTZ"
}
```

### Failure Modes

**1. AUTH_FAILED (Code: 401)**
- **Cause:** Invalid JWT token, expired token, wrong key type
- **Detection:** HTTP 401 response from Supabase REST API
- **Symptoms:** Authentication header rejected
- **Recovery:** Halt execution, emit CRITICAL RunRecord, require operator intervention
- **Retry:** DO NOT RETRY (auth failure is persistent)
- **SAFE vs UNSAFE:**
  - ❌ UNSAFE to retry (invalid credentials will keep failing)
  - ❌ UNSAFE to use service_role key (forbidden)
  - ✅ SAFE to halt and alert operator

**2. CONSTRAINT_VIOLATION (Code: 23505)**
- **Cause:** NOT NULL, UNIQUE, CHECK, or FK constraint violated
- **Detection:** HTTP 400 with PostgreSQL error details
- **Symptoms:** Data rejected by database constraints
- **Recovery:** Halt execution, emit ERROR RunRecord, fix input data
- **Retry:** DO NOT RETRY (constraint violation is data error)
- **SAFE vs UNSAFE:**
  - ❌ UNSAFE to retry (same invalid data will fail again)
  - ❌ UNSAFE to bypass constraints (security violation)
  - ✅ SAFE to halt and fix input data

**3. TIMEOUT (Code: 408 or client timeout)**
- **Cause:** Query exceeds 30-second timeout
- **Detection:** HTTP 408 or client-side timeout exception
- **Symptoms:** No response within timeout period
- **Recovery:** Log warning, retry once with exponential backoff
- **Retry:** YES (max 2 attempts total: initial + 1 retry)
- **SAFE vs UNSAFE:**
  - ✅ SAFE to retry once (transient network issue possible)
  - ❌ UNSAFE to retry indefinitely (may mask persistent issue)
  - ✅ SAFE to emit degraded RunRecord after retry fails

**4. SCHEMA_MISMATCH (Code: 42P01 or 42703)**
- **Cause:** Table or column does not exist (schema out of sync)
- **Detection:** HTTP 400 with "relation does not exist" or "column does not exist"
- **Symptoms:** Query references non-existent schema object
- **Recovery:** CRITICAL - schema mismatch, halt all operations
- **Retry:** DO NOT RETRY (schema mismatch requires manual intervention)
- **SAFE vs UNSAFE:**
  - ❌ UNSAFE to retry (schema will still be missing)
  - ❌ UNSAFE to continue execution (data corruption risk)
  - ❌ UNSAFE to use service_role to fix (forbidden)
  - ✅ SAFE to halt and emit CRITICAL RunRecord

**5. NETWORK_ERROR (Code: curl/network error)**
- **Cause:** Connection refused, DNS failure, network unreachable
- **Detection:** Client-side network exception
- **Symptoms:** Unable to reach Supabase endpoint
- **Recovery:** Log warning, retry with exponential backoff (max 3 attempts)
- **Retry:** YES (max 3 attempts with 500ms, 1000ms, 2000ms backoff)
- **SAFE vs UNSAFE:**
  - ✅ SAFE to retry (transient network issues)
  - ❌ UNSAFE to retry indefinitely (may mask persistent outage)
  - ✅ SAFE to emit degraded RunRecord after 3 failures

**6. BOUNDARY_VIOLATION (Code: client validation)**
- **Cause:** Attempted forbidden operation (DELETE, UPDATE on immutable table)
- **Detection:** Client-side validation gate rejection
- **Symptoms:** Operation rejected before reaching Supabase
- **Recovery:** CRITICAL - validation gate failed (code logic error)
- **Retry:** DO NOT RETRY (logic error must be fixed)
- **SAFE vs UNSAFE:**
  - ❌ UNSAFE to bypass validation gates
  - ❌ UNSAFE to retry (same error will occur)
  - ❌ UNSAFE to use service_role to work around (forbidden)
  - ✅ SAFE to halt and emit CRITICAL RunRecord

### SAFE Invocation Conditions

**ALL of the following MUST be true:**

1. ✅ Environment variables present and valid (SUPABASE_URL, SUPABASE_ANON_KEY)
2. ✅ Using ANON_KEY (not service_role)
3. ✅ Operation type is INSERT only (no DELETE, no UPDATE on immutable columns)
4. ✅ Target table is in allowed list (run_records, audit_log, validation_log, adapter_events, execution_stats, run_artifacts)
5. ✅ Data structure matches schema (all required fields present, types correct)
6. ✅ Validation gates passed (all 6 gates from STEP 5)
7. ✅ Client-side checks passed (no boundary violations)

**If ANY condition is FALSE:**
- ❌ INVOCATION IS UNSAFE
- ❌ DO NOT EXECUTE
- ❌ EMIT ERROR RUNRECORD
- ❌ HALT OPERATION

### UNSAFE Invocation Conditions

**ANY of the following makes invocation UNSAFE:**

1. ❌ Using service_role key (FORBIDDEN)
2. ❌ Attempting DELETE operation on any table
3. ❌ Attempting UPDATE on immutable table (run_records, validation_log, audit_log, adapter_events)
4. ❌ Missing required environment variables
5. ❌ Invalid data structure (missing required fields, wrong types)
6. ❌ Validation gates failed
7. ❌ Boundary violations detected
8. ❌ Target table not in allowed list
9. ❌ Bypassing client-side validation

**If ANY condition is TRUE:**
- 🚫 **CRITICAL: DO NOT INVOKE ADAPTER**
- 🚫 EMIT CRITICAL RUNRECORD
- 🚫 HALT ALL OPERATIONS
- 🚫 REQUIRE OPERATOR INTERVENTION

---

## Adapter 2: supabase-health

### Purpose
Verify Supabase connectivity and authentication without accessing data.

### Required Inputs

**Environment Variables:**
- `SUPABASE_URL`: HTTPS URL to Supabase project
- `SUPABASE_ANON_KEY`: JWT for authentication

**Health Check Parameters:**
```json
{
  "operation": "health_check",
  "method": "HEAD",
  "endpoint": "/rest/v1/",
  "timeout_ms": 10000
}
```

### Expected Outputs

**Success Response:**
```json
{
  "status": "healthy",
  "http_status": 200,
  "response_time_ms": 150,
  "server": "cloudflare",
  "content_type": "application/openapi+json; charset=utf-8"
}
```

**Failure Response:**
```json
{
  "status": "unhealthy",
  "error_code": "TEXT (enum below)",
  "error_message": "TEXT",
  "http_status": "INTEGER (if HTTP response received)"
}
```

### Failure Modes

**1. AUTH_FAILED (Code: 401)**
- **Cause:** Invalid ANON_KEY, expired token
- **Detection:** HTTP 401 response
- **Recovery:** Halt, emit CRITICAL RunRecord
- **Retry:** DO NOT RETRY
- **SAFE vs UNSAFE:**
  - ❌ UNSAFE to retry (invalid credentials)
  - ✅ SAFE to halt and alert operator

**2. CONNECTION_FAILED (Code: network error)**
- **Cause:** Network unreachable, DNS failure, timeout
- **Detection:** curl/network error
- **Recovery:** Log warning, retry once
- **Retry:** YES (once with 1000ms backoff)
- **SAFE vs UNSAFE:**
  - ✅ SAFE to retry once (transient network issue)
  - ❌ UNSAFE to retry indefinitely

**3. UNEXPECTED_RESPONSE (Code: 5xx or 4xx not 401)**
- **Cause:** Supabase service error or misconfiguration
- **Detection:** HTTP status not in {200, 401}
- **Recovery:** Log warning, mark as degraded
- **Retry:** DO NOT RETRY (service issue, persistent)
- **SAFE vs UNSAFE:**
  - ❌ UNSAFE to retry (service won't fix itself)
  - ✅ SAFE to mark adapter as degraded

### SAFE Invocation Conditions

**ALL of the following MUST be true:**

1. ✅ Environment variables present and valid
2. ✅ Using ANON_KEY (not service_role)
3. ✅ Operation is HEAD request only (read-only)
4. ✅ Endpoint is /rest/v1/ (metadata only, no data access)
5. ✅ Timeout is reasonable (≤ 10 seconds)
6. ✅ No authentication bypass attempted

### UNSAFE Invocation Conditions

**ANY of the following makes invocation UNSAFE:**

1. ❌ Using service_role key
2. ❌ Operation is GET/POST/PUT/DELETE (data access or modification)
3. ❌ Endpoint is not /rest/v1/ (accessing table data)
4. ❌ Attempting to query data
5. ❌ Attempting to modify data
6. ❌ Bypassing authentication

---

## Adapter 3: supabase-metrics (FUTURE)

### Purpose
Aggregate and query metrics from Supabase for monitoring and analytics.

### Status
**NOT IMPLEMENTED IN STEP 11**
This adapter is planned for future implementation when metrics are required.

### Planned Required Inputs (FUTURE)

**Environment Variables:**
- `SUPABASE_URL`: HTTPS URL to Supabase project
- `SUPABASE_ANON_KEY`: JWT for authentication (read-only operations)

**Query Parameters (FUTURE):**
```json
{
  "query_type": "TEXT (enum: count_by_status, avg_duration, error_rate)",
  "time_range": {
    "start_date": "DATE",
    "end_date": "DATE"
  },
  "filters": "JSONB (optional filter conditions)",
  "aggregation": "TEXT (SUM, COUNT, AVG, etc.)"
}
```

### Planned Failure Modes (FUTURE)

**1. QUERY_TIMEOUT**
- **Recovery:** Simplify query, retry once
- **Retry:** YES (once with simplified query)

**2. SCHEMA_MISMATCH**
- **Recovery:** CRITICAL - adapter broken
- **Retry:** DO NOT RETRY

### Planned SAFE Invocation Conditions (FUTURE)

1. ✅ Using ANON_KEY (read-only)
2. ✅ Operation is SELECT only (no writes)
3. ✅ Queries use aggregation (SUM, COUNT, AVG)
4. ✅ No individual row access (privacy protection)
5. ✅ Queries have time limits (≤ 30 seconds)
6. ✅ Queries are parameterized (SQL injection prevention)

### Planned UNSAFE Invocation Conditions (FUTURE)

1. ❌ Using service_role
2. ❌ Attempting INSERT/UPDATE/DELETE
3. ❌ Accessing individual rows without aggregation
4. ❌ Accessing audit_log directly (use summary views)
5. ❌ Unparameterized queries (SQL injection risk)

---

## Cross-Adapter Safety Checks

### Universal Preconditions

**Before invoking ANY adapter, verify:**

1. **Environment State:**
   - ✅ SUPABASE_URL is set and valid
   - ✅ SUPABASE_ANON_KEY is set and valid
   - ✅ SUPABASE_SERVICE_KEY is NOT set (empty or unset)

2. **Client Validation:**
   - ✅ All 6 validation gates passed (STEP 5)
   - ✅ No boundary violations detected
   - ✅ ToolSpec is valid
   - ✅ IntentSpec is valid

3. **Adapter-Specific Checks:**
   - ✅ Operation type is allowed for adapter
   - ✅ Target table is in allowed list
   - ✅ Data structure matches schema
   - ✅ No forbidden fields present

4. **Safety Guards:**
   - ✅ Read-only operation if adapter is read-only
   - ✅ No service_role key usage
   - ✅ Timeout is reasonable
   - ✅ Retry policy is defined

### Universal Prohibitions

**NO adapter is EVER allowed to:**

1. 🚫 Use service_role key in application code
2. 🚫 DELETE from append-only tables
3. 🚫 UPDATE immutable columns
4. 🚫 Execute DDL statements (CREATE, ALTER, DROP)
5. 🚫 Modify RLS policies
6. 🚫 Access tables outside defined schema
7. 🚫 Bypass validation gates
8. 🚫 Execute unparameterized SQL
9. 🚫 Retry indefinitely (max retry limits enforced)
10. 🚫 Hide errors or suppress audit logging

### Invocation Checklist

**Before invoking toolforge-runrecords adapter:**

- [ ] Environment variables verified (SUPABASE_URL, SUPABASE_ANON_KEY)
- [ ] Validation gates passed (all 6 gates)
- [ ] Operation type is INSERT (not DELETE, not UPDATE)
- [ ] Target table is allowed (run_records, audit_log, etc.)
- [ ] Data structure validated (all required fields, correct types)
- [ ] No boundary violations detected
- [ ] Retry policy defined (max 2-3 attempts based on error type)
- [ ] Audit log will be emitted after operation
- [ ] Rollback plan exists (if required)

**Before invoking supabase-health adapter:**

- [ ] Environment variables verified
- [ ] Operation is HEAD (read-only)
- [ ] Endpoint is /rest/v1/ (metadata only)
- [ ] Timeout is ≤ 10 seconds
- [ ] No data access attempted
- [ ] No modification attempted

**Before invoking supabase-metrics adapter (FUTURE):**

- [ ] Environment variables verified
- [ ] Operation is SELECT with aggregation
- [ ] No individual row access
- [ ] No access to audit_log directly
- [ ] Queries are parameterized
- [ ] Time limit is ≤ 30 seconds
- [ ] Retry policy defined

---

## Summary

**Adapters Defined:** 3 (toolforge-runrecords, supabase-health, supabase-metrics)
**Readiness Criteria:** Explicit preconditions for each adapter
**Safe Invocation:** All conditions must be met
**Unsafe Invocation:** Any violation = CRITICAL, halt immediately
**Failure Modes:** 6 per adapter, with recovery strategies
**Universal Prohibitions:** 10 absolute denials for all adapters

**Key Guarantees:**
- No adapter invocation without meeting all SAFE conditions
- No service_role usage in application code
- No DELETE or UPDATE on append-only/immutable data
- All failures emit appropriate RunRecords
- All errors are logged and audited
- No indefinite retries (max limits enforced)

**Adapter readiness is verified BEFORE any execution attempt.**
