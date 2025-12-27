# Simulated ToolForge Runs

## Purpose
**DEFINITIVE** specification of simulated ToolForge executions to prove failure handling.

**PRINCIPLE:** We simulate execution to prove the system fails correctly WITHOUT actually running.

---

## Simulation Protocol

### How Simulations Work

**Simulation** = Pretend to execute without actually executing.

**What simulations DO:**
- ✅ Parse IntentSpec and ToolSpec
- ✅ Run validation gates (GATES 2-6)
- ✅ Simulate adapter resolution
- ✅ Emit complete RunRecord
- ✅ Simulate rollback (if needed)
- ✅ Leave audit trail

**What simulations DO NOT do:**
- ❌ NO Docker container starts
- ❌ NO HTTP calls to adapters
- ❌ NO actual tool execution
- ❌ NO file system writes
- ❌ NO database mutations
- ❌ NO side effects

### Simulation Commands

```bash
# Run a simulation
n8n execute-tool-simulation \
  --intent-spec /path/to/intent.json \
  --tool-spec /path/to/toolspec.json \
  --dry-run \
  --simulate

# The --simulate flag ensures:
# - Validation runs normally
# - Adapter resolution is simulated
# - NO HTTP calls are made
# - RunRecord is emitted
```

---

## Simulation 1: Missing adapter_id (MUST FAIL)

**Purpose:** Prove validation catches missing adapter_id

### Input: IntentSpec

```json
{
  "intent_id": "sim-1-missing-adapter-intent",
  "issued_at": "2024-12-26T14:00:00.000Z",
  "issuer": "human",
  "objective": "Search vector database for similar documents",
  "constraints": [
    { "type": "execution_mode", "value": "remote" }
  ],
  "forbidden_actions": [],
  "required_outputs": [
    { "artifact_type": "search_results", "description": "Similar documents" }
  ],
  "validation_level": "strict",
  "rollback_required": false,
  "audit_required": true
}
```

### Input: ToolSpec

```json
{
  "tool_id": "vector-search-no-adapter",
  "version": "1.0.0",
  "description": "Search vector database without specifying adapter",
  "execution_mode": "remote",
  "resource_class": "compute",
  "adapter_id": null,
  "adapter_operation": "search",
  "input_schema": {
    "type": "object",
    "properties": {
      "query": { "type": "array", "items": { "type": "number" } }
    }
  },
  "output_schema": {
    "type": "object",
    "properties": {
      "results": { "type": "array" }
    }
  },
  "credentials_required": [],
  "side_effects": [],
  "rollback_strategy": "none",
  "timeout_seconds": 10,
  "dependencies": {}
}
```

### Simulation Execution

```bash
# Run simulation
n8n execute-tool-simulation \
  --intent-spec sim-1-intent.json \
  --tool-spec sim-1-toolspec.json \
  --simulate
```

### Expected Result: FAIL

**Gate:** GATE 4 - ToolSpec Cross-Validation (Rule 7)

**Validation Output:**
```json
{
  "simulation_id": "sim-1-missing-adapter",
  "timestamp": "2024-12-26T14:00:01.234Z",
  "intent_id": "sim-1-missing-adapter-intent",
  "tool_id": "vector-search-no-adapter",
  "status": "failure",
  "failure_gate": "GATE_4_TOOLSPEC_CROSS_VALIDATION",
  "failure_rule": "RULE_7_REMOTE_REQUIRES_ADAPTER",
  "errors": [
    {
      "field": "adapter_id",
      "constraint": "remote_requires_adapter",
      "message": "REMOTE tools MUST specify adapter_id (e.g., 'supabase-postgres', 'qdrant-vector')",
      "severity": "error"
    }
  ],
  "validation_checks": {
    "intent_validation": "pass",
    "toolspec_schema": "pass",
    "execution_boundary": "fail",
    "adapter_validation": "fail"
  },
  "halted": true,
  "execution_attempted": false
}
```

**RunRecord Emitted:**
```json
{
  "run_id": "sim-1-missing-adapter-550e8400-e29b-41d4-a716-446655440010",
  "intent_id": "sim-1-missing-adapter-intent",
  "tool_id": "vector-search-no-adapter",
  "started_at": "2024-12-26T14:00:01.000Z",
  "finished_at": "2024-12-26T14:00:01.234Z",
  "status": "failure",
  "inputs_hash": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "outputs_hash": null,
  "artifacts": [],
  "logs_ref": "simulation-sim-1-missing-adapter",
  "rollback_executed": false,
  "critic_verdict": "fail",
  "critic_details": {
    "checks_performed": [{
      "check_name": "adapter_validation",
      "result": "fail",
      "details": "REMOTE tool missing adapter_id"
    }],
    "overall_score": 0.0
  },
  "errors": [{
    "timestamp": "2024-12-26T14:00:01.100Z",
    "severity": "error",
    "code": "REMOTE_REQUIRES_ADAPTER",
    "message": "REMOTE tools MUST specify adapter_id"
  }],
  "performance": {
    "duration_ms": 234,
    "cpu_time_ms": 100,
    "memory_peak_mb": 64.0
  },
  "metadata": {
    "executor": "toolforge-simulation",
    "simulation": true,
    "dry_run": true,
    "fault_injected": "missing_adapter_id"
  }
}
```

### Side Effects Verification

```bash
# Verify NO containers started
docker ps | grep samwise
# Output: (empty)

# Verify NO files created
find /home/node/.n8n -newer /tmp/sim-1-pre -type f ! -name "run-records/*"
# Output: Only RunRecord file

# Verify NO HTTP calls
# (Network monitoring shows no outbound traffic)
```

---

## Simulation 2: Forbidden LOCAL→CLOUD Access (MUST FAIL)

**Purpose:** Prove execution boundaries block unsafe access

### Input: IntentSpec

```json
{
  "intent_id": "sim-2-boundary-violation-intent",
  "issued_at": "2024-12-26T14:05:00.000Z",
  "issuer": "agent",
  "objective": "Write data directly to cloud PostgreSQL database",
  "constraints": [],
  "forbidden_actions": ["delete_data"],
  "required_outputs": [
    { "artifact_type": "write_confirmation", "description": "Data written" }
  ],
  "validation_level": "strict",
  "rollback_required": true,
  "audit_required": true
}
```

### Input: ToolSpec

```json
{
  "tool_id": "local-db-writer",
  "version": "1.0.0",
  "description": "Write directly to cloud database from LOCAL context",
  "execution_mode": "local",
  "resource_class": "state",
  "side_effects": [{
    "effect_type": "database_write",
    "description": "Write directly to PostgreSQL",
    "reversible": true
  }],
  "rollback_strategy": "compensating",
  "timeout_seconds": 30
}
```

### Simulation Execution

```bash
n8n execute-tool-simulation \
  --intent-spec sim-2-intent.json \
  --tool-spec sim-2-toolspec.json \
  --simulate
```

### Expected Result: FAIL

**Gate:** GATE 4 - Execution Boundary Validation (Rule 1 + Rule 4)

**Validation Output:**
```json
{
  "simulation_id": "sim-2-boundary-violation",
  "status": "failure",
  "failure_gate": "GATE_4_EXECUTION_BOUNDARY",
  "failure_rules": ["RULE_1_LOCAL_CONTROL_ONLY", "RULE_4_LOCAL_NO_DIRECT_CLOUD_DB"],
  "errors": [
    {
      "field": "execution_mode",
      "constraint": "local_control_only",
      "message": "LOCAL tools MUST have resource_class=control (not state)",
      "severity": "error"
    },
    {
      "field": "side_effects",
      "constraint": "local_no_direct_cloud_db",
      "message": "LOCAL tools CANNOT directly access cloud databases: database_write",
      "severity": "error",
      "required": "Use HTTP APIs (Supabase REST, Qdrant HTTP API, Meilisearch HTTP API)"
    }
  ],
  "halted": true,
  "execution_attempted": false
}
```

---

## Simulation 3: Invalid adapter_operation (MUST FAIL)

**Purpose:** Prove adapter operations are validated against interface

### Input: IntentSpec

```json
{
  "intent_id": "sim-3-invalid-operation-intent",
  "issued_at": "2024-12-26T14:10:00.000Z",
  "issuer": "human",
  "objective": "Drop all Qdrant collections",
  "constraints": [],
  "forbidden_actions": [],
  "required_outputs": [
    { "artifact_type": "drop_confirmation", "description": "Collections dropped" }
  ],
  "validation_level": "strict",
  "rollback_required": true,
  "audit_required": true
}
```

### Input: ToolSpec

```json
{
  "tool_id": "qdrant-drop-all",
  "version": "1.0.0",
  "description": "Drop all Qdrant collections (DANGEROUS)",
  "execution_mode": "remote",
  "resource_class": "compute",
  "adapter_id": "qdrant-vector",
  "adapter_operation": "drop_all_collections",
  "side_effects": [{
    "effect_type": "state_mutation",
    "description": "Deletes all vector data",
    "reversible": false
  }],
  "rollback_strategy": "none",
  "timeout_seconds": 60
}
```

### Expected Result: FAIL

**Gate:** GATE 4 - Adapter Validation (Rule 8)

**Validation Output:**
```json
{
  "simulation_id": "sim-3-invalid-operation",
  "status": "failure",
  "failure_gate": "GATE_4_ADAPTER_VALIDATION",
  "failure_rule": "RULE_8_ADAPTER_REQUIRES_OPERATION",
  "errors": [{
    "field": "adapter_operation",
    "constraint": "invalid_adapter_operation",
    "message": "Invalid operation 'drop_all_collections' for adapter 'qdrant-vector'",
    "severity": "error",
    "valid_operations": ["search", "upsert", "create_collection", "health_check"]
  }],
  "halted": true,
  "reason": "Operation not defined in adapter interface (safety constraint)"
}
```

---

## Simulation 4: Direct Cloud URL Forbidden (MUST FAIL)

**Purpose:** Prove tools cannot bypass adapters with direct URLs

### Input: IntentSpec

```json
{
  "intent_id": "sim-4-direct-url-intent",
  "issued_at": "2024-12-26T14:15:00.000Z",
  "issuer": "human",
  "objective": "Connect to Qdrant using direct URL",
  "constraints": [],
  "forbidden_actions": [],
  "required_outputs": [
    { "artifact_type": "connection_status", "description": "Connected" }
  ],
  "validation_level": "normal",
  "rollback_required": false,
  "audit_required": false
}
```

### Input: ToolSpec

```json
{
  "tool_id": "direct-qdrant-connector",
  "version": "1.0.0",
  "description": "Connect to Qdrant directly without adapter",
  "execution_mode": "remote",
  "resource_class": "compute",
  "adapter_id": "qdrant-vector",
  "credentials_required": ["QDRANT_URL"],
  "side_effects": [{
    "effect_type": "network_request",
    "description": "HTTP request to Qdrant",
    "reversible": false
  }],
  "rollback_strategy": "none",
  "timeout_seconds": 10
}
```

### Expected Result: FAIL

**Gate:** GATE 4 - Adapter Validation (Rule 9)

**Validation Output:**
```json
{
  "simulation_id": "sim-4-direct-url",
  "status": "failure",
  "failure_gate": "GATE_4_ADAPTER_VALIDATION",
  "failure_rule": "RULE_9_NO_DIRECT_CLOUD_URLS",
  "errors": [{
    "field": "credentials_required",
    "constraint": "no_direct_cloud_urls",
    "message": "ToolSpec MUST use adapter_id instead of direct cloud URL: QDRANT_URL",
    "severity": "error",
    "forbidden_credential": "QDRANT_URL",
    "required_action": "Remove QDRANT_URL and use adapter_id instead"
  }],
  "halted": true,
  "reason": "Direct cloud URLs bypass adapter safety checks"
}
```

---

## Simulation 5: Meilisearch Degrades (MUST DEGRADE)

**Purpose:** Prove optional adapter failure triggers fallback

### Input: IntentSpec

```json
{
  "intent_id": "sim-5-degraded-intent",
  "issued_at": "2024-12-26T14:20:00.000Z",
  "issuer": "agent",
  "objective": "Search documents with full-text search",
  "constraints": [],
  "forbidden_actions": [],
  "required_outputs": [
    { "artifact_type": "search_results", "description": "Matching documents" }
  ],
  "validation_level": "normal",
  "rollback_required": false,
  "audit_required": false
}
```

### Input: ToolSpec

```json
{
  "tool_id": "fulltext-search",
  "version": "1.0.0",
  "description": "Full-text search with Meilisearch (fallback to PostgreSQL)",
  "execution_mode": "remote",
  "resource_class": "compute",
  "adapter_id": "meilisearch",
  "adapter_operation": "search",
  "input_schema": {
    "type": "object",
    "properties": {
      "query": { "type": "string" }
    }
  },
  "output_schema": {
    "type": "object",
    "properties": {
      "hits": { "type": "array" }
    }
  },
  "credentials_required": [],
  "side_effects": [],
  "rollback_strategy": "none",
  "timeout_seconds": 5
}
```

### Simulated Environment State

```bash
# Meilisearch env vars MISSING
# (Simulating adapter failure)
unset MEILISEARCH_HOST
unset MEILISEARCH_API_KEY
```

### Expected Result: DEGRADE

**Adapter Resolution:**
```json
{
  "adapter_id": "meilisearch",
  "status": "degraded",
  "error": {
    "code": "ENV_VAR_MISSING",
    "missing_variables": ["MEILISEARCH_HOST", "MEILISEARCH_API_KEY"]
  },
  "fallback": "PostgreSQL text search",
  "impact": "Slower query performance, no fuzzy matching"
}
```

**Simulation Output:**
```json
{
  "simulation_id": "sim-5-degraded",
  "status": "success",
  "degraded": true,
  "adapter_resolution": {
    "adapter_id": "meilisearch",
    "available": false,
    "fallback_active": true,
    "fallback_type": "postgresql_text_search"
  },
  "execution": {
    "mode": "fallback",
    "operation": "postgres_like_query",
    "simulated_results": {
      "hits": [
        { "id": "doc-1", "title": "Document 1" }
      ],
      "total_hits": 1,
      "fallback_notice": "Results from PostgreSQL text search (Meilisearch unavailable)"
    }
  },
  "warnings": [{
    "code": "ADAPTER_DEGRADED",
    "message": "Meilisearch unavailable - using PostgreSQL text search fallback"
  }]
}
```

**RunRecord Emitted:**
```json
{
  "run_id": "sim-5-degraded-550e8400-e29b-41d4-a716-446655440011",
  "status": "success",
  "critic_verdict": "pass",
  "warnings": [{
    "timestamp": "2024-12-26T14:20:05.000Z",
    "severity": "warning",
    "code": "ADAPTER_DEGRADED",
    "message": "Meilisearch unavailable - using PostgreSQL text search fallback"
  }],
  "degraded": true,
  "fallback_active": true
}
```

---

## Simulation 6: Dry-Run Pass (PASSES DRY-RUN ONLY)

**Purpose:** Prove dry-run mode validates without executing

### Input: IntentSpec

```json
{
  "intent_id": "sim-6-dry-run-pass-intent",
  "issued_at": "2024-12-26T14:25:00.000Z",
  "issuer": "human",
  "objective": "Validate vector search configuration without executing",
  "constraints": [],
  "forbidden_actions": [],
  "required_outputs": [
    { "artifact_type": "validation_result", "description": "Configuration is valid" }
  ],
  "validation_level": "strict",
  "rollback_required": false,
  "audit_required": true
}
```

### Input: ToolSpec

```json
{
  "tool_id": "validated-vector-search",
  "version": "1.0.0",
  "description": "Validated vector search tool with all required fields",
  "execution_mode": "remote",
  "resource_class": "compute",
  "adapter_id": "qdrant-vector",
  "adapter_operation": "search",
  "input_schema": {
    "type": "object",
    "properties": {
      "vector": { "type": "array", "items": { "type": "number" } },
      "limit": { "type": "number", "default": 10 }
    }
  },
  "output_schema": {
    "type": "object",
    "properties": {
      "results": { "type": "array" },
      "count": { "type": "number" }
    }
  },
  "credentials_required": [],
  "side_effects": [],
  "rollback_strategy": "none",
  "timeout_seconds": 10
}
```

### Dry-Run Simulation

```bash
n8n execute-tool-simulation \
  --intent-spec sim-6-intent.json \
  --tool-spec sim-6-toolspec.json \
  --dry-run \
  --simulate
```

### Expected Result: PASS (DRY-RUN ONLY)

**Validation Output:**
```json
{
  "simulation_id": "sim-6-dry-run-pass",
  "dry_run": true,
  "status": "success",
  "dry_run_result": "WOULD_ROUTE_CORRECTLY",
  "validation_stages": [
    {
      "stage": "adapter_config_validation",
      "status": "pass",
      "adapter_id": "qdrant-vector",
      "config_resolved": {
        "QDRANT_URL": "https://qdrant.example.com",
        "QDRANT_API_KEY": "[REDACTED]"
      }
    },
    {
      "stage": "tool_adapter_routing",
      "status": "pass",
      "routing": {
        "tool_id": "validated-vector-search",
        "adapter_id": "qdrant-vector",
        "operation": "search",
        "execution_target": {
          "mode": "cloud",
          "provider": "northflank",
          "service": "qdrant"
        }
      }
    },
    {
      "stage": "simulated_execution",
      "status": "success",
      "dry_run_result": "WOULD_EXECUTE_SUCCESSFULLY",
      "mock_output": {
        "results": [
          { "id": "mock-1", "score": 0.95 }
        ],
        "count": 1
      }
    }
  ],
  "validation_summary": {
    "total_stages": 3,
    "passed_stages": 3,
    "failed_stages": 0
  },
  "note": "NO HTTP calls were made. This is a validation-only execution."
}
```

**RunRecord Emitted:**
```json
{
  "run_id": "dry-run-sim-6-550e8400-e29b-41d4-a716-446655440012",
  "dry_run": true,
  "timestamp": "2024-12-26T14:25:05.000Z",
  "intent_id": "sim-6-dry-run-pass-intent",
  "tool_id": "validated-vector-search",
  "status": "success",
  "dry_run_result": "WOULD_ROUTE_CORRECTLY",
  "critic_verdict": "pass",
  "metadata": {
    "executor": "toolforge-simulation",
    "dry_run_mode": true,
    "note": "No HTTP calls were made. This is a validation-only execution."
  }
}
```

### Verification: NO Execution

```bash
# Verify NO HTTP calls to Qdrant
# (Network monitoring: no outbound traffic to qdrant.example.com)

# Verify NO data written
# (Database shows no new records)

# Verify ONLY RunRecord emitted
ls -la /home/node/.n8n/data/run-records/dry-run-sim-6-*.json
# Output: RunRecord file exists, nothing else
```

---

## Simulation Summary

| Sim ID | Tool | Intent | Result | Gate | Fault Type |
|--------|------|--------|--------|------|------------|
| 1 | vector-search-no-adapter | Search docs | FAIL | GATE 4 | Missing adapter_id |
| 2 | local-db-writer | Write to DB | FAIL | GATE 4 | Boundary violation |
| 3 | qdrant-drop-all | Drop collections | FAIL | GATE 4 | Invalid operation |
| 4 | direct-qdrant-connector | Direct URL | FAIL | GATE 4 | Direct URL forbidden |
| 5 | fulltext-search | Search docs | DEGRADE | STARTUP | Optional adapter missing |
| 6 | validated-vector-search | Validate config | PASS | N/A | Dry-run only |

**Outcomes:**
- 4 simulations MUST FAIL ✅
- 1 simulation DEGRADES ✅
- 1 simulation PASSES (dry-run only) ✅

---

## Running All Simulations

### Batch Simulation Command

```bash
# Run all 6 simulations
for i in {1..6}; do
  echo "=== Running Simulation $i ==="
  n8n execute-tool-simulation \
    --intent-spec sim-$i-intent.json \
    --tool-spec sim-$i-toolspec.json \
    --simulate \
    --output /home/node/.n8n/data/simulations/sim-$i-result.json
done

# Summary
echo "=== Simulation Summary ==="
jq -r '[.simulation_id, .status, .dry_run_result] | @tsv' \
  /home/node/.n8n/data/simulations/sim-*-result.json
```

### Expected Output

```
=== Simulation Summary ===
sim-1-missing-adapter	fail	NULL
sim-2-boundary-violation	fail	NULL
sim-3-invalid-operation	fail	NULL
sim-4-direct-url	fail	NULL
sim-5-degraded	success	degraded
sim-6-dry-run-pass	success	WOULD_ROUTE_CORRECTLY
```

---

## Verification: No Side Effects

After running all simulations, verify:

```bash
# 1. NO containers started
docker ps | grep samwise
# Expected: (empty)

# 2. NO HTTP calls made
# (Check firewall logs, network monitoring)
# Expected: No outbound traffic to cloud services

# 3. NO files written (except RunRecords)
find /home/node/.n8n -type f -newer /tmp/sim-pre \
  ! -path "*/run-records/*" ! -path "*/simulations/*"
# Expected: (empty)

# 4. NO database mutations
# (Check Supabase dashboard)
# Expected: No new records, no changes

# 5. RunRecords emitted
ls /home/node/.n8n/data/run-records/sim-*-*.json
# Expected: 6 RunRecord files
```

**All verifications MUST pass for STEP 8.2 to be complete.**

---

## Summary

**Simulations prove:**
1. ✅ Validation rejects invalid ToolSpecs (4 failures)
2. ✅ Boundaries block unsafe access (2 boundary violations)
3. ✅ Optional adapters trigger fallback (1 degradation)
4. ✅ Dry-run validates without executing (1 dry-run pass)
5. ✅ All failures are logged (6 RunRecords)
6. ✅ NO side effects occur (no containers, no HTTP, no writes)

**We prove correctness through controlled failure, not risky success.**

**Next:** Failure Proof Artifacts (STEP 8.3)
