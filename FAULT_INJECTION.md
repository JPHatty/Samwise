# Fault Injection Matrix

## Purpose
**DEFINITIVE** specification of how Samwise fails when things go wrong.

**PRINCIPLE:** We prove correctness through refusal, not success. Every failure is intentional, logged, and auditable.

---

## Fault Injection Philosophy

### What Fault Injection Proves

**Fault injection** is the practice of deliberately introducing failures to verify that the system responds correctly.

**In Samwise, we inject faults to prove:**
1. Validation gates reject invalid input
2. Execution boundaries are enforced
3. Failure modes trigger correctly
4. Rollback executes when required
5. RunRecords capture all failures
6. No unsafe operations slip through

### What We Are NOT Testing

- ❌ NOT testing cloud service availability
- ❌ NOT testing adapter functionality
- ❌ NOT testing happy-path success
- ❌ NOT testing performance
- ❌ NOT testing scalability

**We ARE testing:**
- ✅ Refusal of unsafe operations
- ✅ Validation gate enforcement
- ✅ Failure detection and logging
- ✅ Rollback execution
- ✅ Audit trail completeness

---

## Fault Categories

### Category 1: Validation Failures
Faults that trigger at validation gates (GATES 2-5).

### Category 2: Configuration Failures
Faults related to missing or invalid environment/configuration.

### Category 3: Boundary Violations
Faults related to crossing execution boundaries (LOCAL ↔ CLOUD).

### Category 4: Credential Failures
Faults related to missing, invalid, or forbidden credentials.

### Category 5: Execution Failures
Faults that occur during execution (timeouts, retries exhausted).

### Category 6: Critic Rejections
Faults that trigger rollback after execution.

---

## Fault Injection Matrix

### Fault 1: Missing adapter_id (REMOTE Tool)

**Injection Point:** ToolSpec generation or validation

**Fault Spec:**
```json
{
  "toolspec": {
    "tool_id": "vector-search",
    "execution_mode": "remote",
    "resource_class": "compute",
    "adapter_id": null,  // ← FAULT: Missing adapter_id
    "adapter_operation": "search",
    "input_schema": {...},
    "output_schema": {...}
  }
}
```

**Expected Failure Gate:** GATE 4 - ToolSpec Cross-Validation (Rule 7)

**Expected Behavior:**
```javascript
// Validation fails at toolforge_validate_toolspec.json
{
  "valid": false,
  "error": "cross_validation_failed",
  "message": "ToolSpec violated Intent constraints",
  "errors": [
    {
      "field": "adapter_id",
      "constraint": "remote_requires_adapter",
      "message": "REMOTE tools MUST specify adapter_id (e.g., 'supabase-postgres', 'qdrant-vector')",
      "severity": "error"
    }
  ]
}
```

**RunRecord Entry:**
```json
{
  "run_id": "fault-1-missing-adapter-id",
  "status": "failure",
  "critic_verdict": "fail",
  "errors": [{
    "timestamp": "2024-12-26T13:00:00.000Z",
    "severity": "error",
    "code": "REMOTE_REQUIRES_ADAPTER",
    "message": "REMOTE tools MUST specify adapter_id",
    "fault_injected": "missing_adapter_id"
  }],
  "rollback_executed": false
}
```

**Halt:** YES - Pipeline stops at GATE 4

**Recovery:** Add valid `adapter_id` to ToolSpec

---

### Fault 2: Invalid adapter_operation

**Injection Point:** ToolSpec validation

**Fault Spec:**
```json
{
  "toolspec": {
    "tool_id": "semantic-search",
    "execution_mode": "remote",
    "adapter_id": "qdrant-vector",
    "adapter_operation": "destroy_all_data",  // ← FAULT: Invalid operation
    "input_schema": {...},
    "output_schema": {...}
  }
}
```

**Expected Failure Gate:** GATE 4 - ToolSpec Cross-Validation (Rule 8)

**Expected Behavior:**
```javascript
{
  "valid": false,
  "error": "cross_validation_failed",
  "errors": [{
    "field": "adapter_operation",
    "constraint": "invalid_adapter_operation",
    "message": "Invalid operation 'destroy_all_data' for adapter 'qdrant-vector'",
    "severity": "error",
    "valid_operations": ["search", "upsert", "create_collection", "health_check"]
  }]
}
```

**RunRecord Entry:**
```json
{
  "run_id": "fault-2-invalid-adapter-operation",
  "status": "failure",
  "critic_verdict": "fail",
  "errors": [{
    "code": "INVALID_ADAPTER_OPERATION",
    "message": "Invalid operation 'destroy_all_data' for adapter 'qdrant-vector'",
    "fault_injected": "invalid_adapter_operation"
  }]
}
```

**Halt:** YES - Pipeline stops at GATE 4

**Recovery:** Use valid operation from adapter interface

---

### Fault 3: Missing Required Environment Variable

**Injection Point:** Adapter initialization

**Fault Spec:**
```bash
# Environment state:
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
# SUPABASE_PASSWORD is MISSING  # ← FAULT
```

**Expected Failure Gate:** Phase 2 - Environment Resolution

**Expected Behavior:**
```javascript
// Adapter initialization fails
{
  "adapter_id": "supabase-postgres",
  "status": "failure",
  "severity": "critical",
  "error": {
    "code": "ENV_VAR_MISSING",
    "message": "Required environment variable not set",
    "missing_variables": ["SUPABASE_PASSWORD"]
  },
  "system_ready": false,
  "halt_execution": true
}
```

**RunRecord Entry:**
```json
{
  "run_id": "fault-3-missing-env-var",
  "event_type": "adapter_resolution_failure",
  "status": "failure",
  "severity": "critical",
  "adapter_id": "supabase-postgres",
  "error": {
    "code": "ENV_VAR_MISSING",
    "missing_variables": ["SUPABASE_PASSWORD"],
    "fault_injected": "missing_env_var"
  },
  "system_ready": false
}
```

**Halt:** YES - System cannot start

**Recovery:** Add missing variable to .env and restart

---

### Fault 4: Forbidden LOCAL → CLOUD Database Access

**Injection Point:** ToolSpec validation

**Fault Spec:**
```json
{
  "toolspec": {
    "tool_id": "direct-db-access",
    "execution_mode": "local",
    "resource_class": "compute",  // ← FAULT: LOCAL tool with compute
    "side_effects": [{
      "effect_type": "database_write",  // ← FAULT: Direct DB access
      "description": "Write directly to cloud database",
      "reversible": false
    }]
  }
}
```

**Expected Failure Gate:** GATE 4 - Execution Boundary Validation (Rule 1 + Rule 4)

**Expected Behavior:**
```javascript
{
  "valid": false,
  "errors": [
    {
      "field": "execution_mode",
      "constraint": "local_control_only",
      "message": "LOCAL tools MUST have resource_class=control (not compute)",
      "severity": "error"
    },
    {
      "field": "side_effects",
      "constraint": "local_no_direct_cloud_db",
      "message": "LOCAL tools CANNOT directly access cloud databases: database_write",
      "severity": "error",
      "required": "Use HTTP APIs (Supabase REST, Qdrant HTTP API)"
    }
  ]
}
```

**RunRecord Entry:**
```json
{
  "run_id": "fault-4-forbidden-local-cloud-access",
  "status": "failure",
  "critic_verdict": "fail",
  "errors": [{
    "code": "BOUNDARY_VIOLATION",
    "message": "LOCAL tool attempted CLOUD database access",
    "fault_injected": "forbidden_local_cloud_access",
    "violations": ["local_control_only", "local_no_direct_cloud_db"]
  }]
}
```

**Halt:** YES - Pipeline stops at GATE 4

**Recovery:** Change to `execution_mode: "remote"` with `adapter_id: "supabase-postgres"`

---

### Fault 5: Direct Cloud URL in credentials_required

**Injection Point:** ToolSpec validation

**Fault Spec:**
```json
{
  "toolspec": {
    "tool_id": "direct-url-tool",
    "execution_mode": "remote",
    "adapter_id": "qdrant-vector",
    "credentials_required": [
      "QDRANT_URL"  // ← FAULT: Direct cloud URL forbidden
    ]
  }
}
```

**Expected Failure Gate:** GATE 4 - Adapter Validation (Rule 9)

**Expected Behavior:**
```javascript
{
  "valid": false,
  "errors": [{
    "field": "credentials_required",
    "constraint": "no_direct_cloud_urls",
    "message": "ToolSpec MUST use adapter_id instead of direct cloud URL: QDRANT_URL",
    "severity": "error",
    "forbidden_credential": "QDRANT_URL",
    "required_action": "Remove QDRANT_URL and use adapter_id instead"
  }]
}
```

**RunRecord Entry:**
```json
{
  "run_id": "fault-5-direct-cloud-url",
  "status": "failure",
  "critic_verdict": "fail",
  "errors": [{
    "code": "DIRECT_CLOUD_URL_FORBIDDEN",
    "message": "ToolSpec MUST use adapter_id instead of direct cloud URL",
    "fault_injected": "direct_cloud_url",
    "forbidden_credential": "QDRANT_URL"
  }]
}
```

**Halt:** YES - Pipeline stops at GATE 4

**Recovery:** Remove direct cloud URL, rely on adapter_id for configuration

---

### Fault 6: Timeout Simulation

**Injection Point:** Adapter execution simulation

**Fault Spec:**
```javascript
// Simulate operation exceeding timeout
{
  "adapter_id": "cloudflare-r2",
  "operation": "put_object",
  "timeout_ms": 1000,  // ← 1 second timeout
  "injected_delay": 2000  // ← FAULT: 2 second execution time
}
```

**Expected Failure Gate:** Runtime execution

**Expected Behavior:**
```javascript
// Adapter enforces timeout
{
  "dry_run": false,
  "adapter_id": "cloudflare-r2",
  "operation": "put_object",
  "status": "failure",
  "error": {
    "code": "ADAPTER_TIMEOUT",
    "message": "Operation exceeded 1000ms timeout",
    "timeout_ms": 1000,
    "actual_duration_ms": 2000
  },
  "retry_attempt": 0,
  "halt_execution": true
}
```

**RunRecord Entry:**
```json
{
  "run_id": "fault-6-timeout",
  "status": "failure",
  "critic_verdict": "fail",
  "errors": [{
    "timestamp": "2024-12-26T13:05:00.000Z",
    "severity": "error",
    "code": "ADAPTER_TIMEOUT",
    "message": "Operation exceeded 1000ms timeout",
    "fault_injected": "timeout_exceeded",
    "timeout_ms": 1000,
    "actual_duration_ms": 2000
  }],
  "performance": {
    "duration_ms": 1000,
    "timed_out": true
  }
}
```

**Halt:** YES - Operation halted at timeout

**Recovery:** Increase timeout in adapter interface or optimize operation

---

### Fault 7: Retry Exhaustion

**Injection Point:** Adapter execution with retry policy

**Fault Spec:**
```javascript
{
  "adapter_id": "qdrant-vector",
  "operation": "search",
  "retry": {
    "policy": "exponential_backoff",
    "max_attempts": 3,
    "inject_failure": true  // ← FAULT: All attempts fail
  }
}
```

**Expected Behavior:**
```javascript
// Attempt 1 fails
{ "attempt": 1, "error": "ECONNREFUSED", "retry_after": 500 }
// Attempt 2 fails
{ "attempt": 2, "error": "ECONNREFUSED", "retry_after": 1000 }
// Attempt 3 fails
{ "attempt": 3, "error": "ECONNREFUSED", "retry_exhausted": true }

// Final result
{
  "status": "failure",
  "error": {
    "code": "RETRY_EXHAUSTED",
    "message": "All retry attempts failed",
    "total_attempts": 3,
    "last_error": "ECONNREFUSED"
  }
}
```

**RunRecord Entry:**
```json
{
  "run_id": "fault-7-retry-exhaustion",
  "status": "failure",
  "critic_verdict": "fail",
  "errors": [{
    "code": "RETRY_EXHAUSTED",
    "message": "All retry attempts failed",
    "fault_injected": "retry_exhaustion",
    "total_attempts": 3,
    "retry_policy": "exponential_backoff"
  }],
  "retry_history": [
    { "attempt": 1, "error": "ECONNREFUSED", "timestamp": "..." },
    { "attempt": 2, "error": "ECONNREFUSED", "timestamp": "..." },
    { "attempt": 3, "error": "ECONNREFUSED", "timestamp": "..." }
  ]
}
```

**Halt:** YES - Operation fails after retries exhausted

**Recovery:** Fix cloud service connectivity

---

### Fault 8: Critic Rejection (Rollback Executed)

**Injection Point:** Post-execution critic evaluation

**Fault Spec:**
```javascript
// Tool executes successfully but critic rejects output
{
  "tool_id": "risky-operation",
  "execution": {
    "status": "success",
    "output": { "result": "unauthorized_change" }
  },
  "critic": {
    "evaluates": "output_validation",
    "injected_verdict": "fail",  // ← FAULT: Critic rejects
    "reason": "Output violates constraint"
  }
}
```

**Expected Behavior:**
```javascript
// Execution succeeds
{ "status": "success", "output": {...} }

// Critic evaluation fails
{
  "critic_verdict": "fail",
  "critic_details": {
    "checks_performed": [{
      "check_name": "output_validation",
      "result": "fail",
      "details": "Output violates safety constraint"
    }],
    "overall_score": 0.0
  }
}

// Rollback executes
{
  "rollback_executed": true,
  "rollback_details": {
    "triggered_at": "2024-12-26T13:10:00.000Z",
    "completed_at": "2024-12-26T13:10:02.000Z",
    "success": true,
    "strategy_used": "compensating",
    "notes": "Executed compensating transaction to undo changes"
  }
}
```

**RunRecord Entry:**
```json
{
  "run_id": "fault-8-critic-rejection",
  "status": "failure",
  "critic_verdict": "fail",
  "errors": [{
    "timestamp": "2024-12-26T13:10:01.000Z",
    "severity": "error",
    "code": "CRITIC_REJECTION",
    "message": "Critic rejected execution output",
    "fault_injected": "critic_rejection"
  }],
  "rollback_executed": true,
  "rollback_details": {
    "triggered_at": "2024-12-26T13:10:00.000Z",
    "completed_at": "2024-12-26T13:10:02.000Z",
    "success": true,
    "strategy_used": "compensating"
  },
  "artifacts": [
    {
      "type": "file",
      "location": "/tmp/unauthorized-change.txt",
      "rolled_back": true
    }
  ]
}
```

**Halt:** YES - Operation halted, rollback executed

**Recovery:** Fix constraint violation and retry

---

## Fault Severity Levels

### CRITICAL Faults

**Definition:** System cannot function without this component.

**Faults:**
- Missing required environment variable for CRITICAL adapter
- Adapter initialization failure (Supabase, Qdrant, R2, LiveKit)
- Validation gate failure with rollback_required=true

**Behavior:**
- Halt immediately
- Emit CRITICAL RunRecord
- Require operator intervention
- NO automatic recovery

**Examples:** Fault 3 (missing env var)

### ERROR Faults

**Definition:** Operation cannot proceed, but system remains functional.

**Faults:**
- Invalid ToolSpec (schema violation, constraint violation)
- Missing adapter_id for remote tool
- Invalid adapter_operation
- Boundary violation (LOCAL→CLOUD access)
- Direct cloud URL in credentials

**Behavior:**
- Halt operation
- Emit ERROR RunRecord
- Require fix before retry
- Clear error message provided

**Examples:** Fault 1, 2, 4, 5

### WARNING Faults

**Definition:** Operation can proceed with degraded functionality.

**Faults:**
- Optional adapter missing (Meilisearch, Prometheus, Loki)
- Timeout on optional operation
- LOCAL tool using adapter_id (allowed but unusual)

**Behavior:**
- Continue with fallback
- Emit WARNING RunRecord
- Log degradation
- No halt

**Examples:** (None in matrix, but Meilisearch fallback would qualify)

### INFO Faults

**Definition:** Informational only, no impact on operation.

**Faults:**
- Optional adapter disabled
- Dry-run mode activated
- Non-critical validation warnings

**Behavior:**
- Continue normally
- Emit INFO RunRecord
- Log for awareness

---

## Rollback Triggers

### When Rollback Executes

Rollback is executed when ALL of the following are TRUE:

1. **Intent requires rollback:**
   ```json
   { "intent": { "rollback_required": true } }
   ```

2. **ToolSpec has rollback_strategy != "none":**
   ```json
   { "toolspec": { "rollback_strategy": "compensating" } }
   ```

3. **Critic verdict is FAIL:**
   ```json
   { "critic_verdict": "fail" }
   ```

### Rollback Strategies

#### Strategy: Compensating

Execute reverse operation to undo changes.

**Example:**
```javascript
// Original operation: Create file
{ "operation": "write_file", "path": "/tmp/data.txt" }

// Rollback: Delete file
{ "rollback": "delete_file", "path": "/tmp/data.txt" }
```

**Fault:** Fault 8 (Critic Rejection)

#### Strategy: Snapshot

Restore system to pre-execution snapshot.

**Example:**
```javascript
// Before execution
{ "snapshot": { "database_state": "snapshot-123" } }

// After execution (failed)
{ "rollback": { "restore_snapshot": "snapshot-123" } }
```

**Trigger:** Multiple state mutations that must be atomic

#### Strategy: None

No rollback possible.

**Behavior:**
- Log that rollback cannot be executed
- Mark RunRecord with `rollback_executed: false`
- Require manual cleanup

---

## Fault Injection Summary Table

| Fault ID | Name | Category | Gate | Severity | Halt? | Rollback? |
|----------|------|----------|------|----------|--------|-----------|
| 1 | Missing adapter_id | Validation | GATE 4 | ERROR | YES | NO |
| 2 | Invalid adapter_operation | Validation | GATE 4 | ERROR | YES | NO |
| 3 | Missing env var | Configuration | STARTUP | CRITICAL | YES | NO |
| 4 | LOCAL→CLOUD access | Boundary | GATE 4 | ERROR | YES | NO |
| 5 | Direct cloud URL | Boundary | GATE 4 | ERROR | YES | NO |
| 6 | Timeout | Execution | RUNTIME | ERROR | YES | NO |
| 7 | Retry exhaustion | Execution | RUNTIME | ERROR | YES | NO |
| 8 | Critic rejection | Critic | POST-EXEC | ERROR | YES | YES |

---

## Fault Injection Commands

### Inject Fault 1: Missing adapter_id

```bash
# Create ToolSpec without adapter_id
cat > /tmp/fault1-toolspec.json << 'EOF'
{
  "tool_id": "vector-search",
  "execution_mode": "remote",
  "resource_class": "compute",
  "adapter_operation": "search"
  // adapter_id is MISSING
}
EOF

# Validate (should fail)
curl -X POST http://localhost:5678/api/toolforge/validate \
  -H "Content-Type: application/json" \
  -d @/tmp/fault1-toolspec.json

# Expected: 400 Bad Request with error "REMOTE tools MUST specify adapter_id"
```

### Inject Fault 3: Missing Environment Variable

```bash
# Unset environment variable
unset SUPABASE_PASSWORD

# Attempt to initialize adapter
docker compose run --rm n8n npx toolforge init-adapter supabase-postgres

# Expected: Failure with "ENV_VAR_MISSING: SUPABASE_PASSWORD"
```

### Inject Fault 6: Timeout

```bash
# Create operation that will timeout
cat > /tmp/fault6-operation.json << 'EOF'
{
  "adapter_id": "cloudflare-r2",
  "operation": "put_object",
  "input": {
    "key": "large-file.bin",
    "body": "<simulated large file>"
  },
  "timeout_ms": 1000  // Very short timeout
}
EOF

# Execute (should timeout)
curl -X POST http://localhost:5678/api/adapter/execute \
  -H "Content-Type: application/json" \
  -d @/tmp/fault6-operation.json

# Expected: 408 Request Timeout with error "Operation exceeded 1000ms timeout"
```

---

## Fault Detection Verification

### After Injecting Each Fault

Verify the fault was detected correctly:

```bash
# 1. Check RunRecord was emitted
ls -la /home/node/.n8n/data/run-records/fault-*.json

# 2. Verify RunRecord content
cat /home/node/.n8n/data/run-records/fault-1-missing-adapter-id.json | jq '.errors'

# 3. Verify no side effects
# (No containers started, no files changed, etc.)

# 4. Verify rollback (if applicable)
cat /home/node/.n8n/data/run-records/fault-8-critic-rejection.json | jq '.rollback_executed'
```

---

## Summary

**Fault injection proves:**
1. ✅ Validation gates reject invalid input
2. ✅ Execution boundaries are enforced
3. ✅ Missing configuration fails explicitly
4. ✅ Boundary violations are blocked
5. ✅ Timeouts are enforced
6. ✅ Retries are bounded
7. ✅ Critic can trigger rollback
8. ✅ All failures are logged

**We prove correctness through refusal, not success.**

**Next:** Simulated ToolForge Runs (STEP 8.2)
