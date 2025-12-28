# RunRecord Emission Examples

## Purpose
Provide canonical examples of RunRecord objects emitted at various stages of the ToolForge pipeline.

**NOTE:** Hashes in these examples are placeholders (repeating 'a' characters). Real implementations will compute actual SHA-256 hashes.

---

## Example 1: Successful Tool Registration

**Context:** All validation gates passed, tool registered successfully.

```json
{
  "run_id": "550e8400-e29b-41d4-a716-446655440002",
  "intent_id": "660e8400-e29b-41d4-a716-446655440001",
  "tool_id": "export-workflows",
  "tool_version": "1.0.0",
  "started_at": "2024-12-26T10:30:00.000Z",
  "finished_at": "2024-12-26T10:30:15.432Z",
  "status": "success",
  "inputs_hash": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "outputs_hash": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  "artifacts": [
    {
      "type": "file",
      "location": "/home/node/.n8n/workflows/toolforge/export-workflows.json",
      "created_at": "2024-12-26T10:30:14.000Z",
      "hash": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
    },
    {
      "type": "configuration",
      "location": "/home/node/.n8n/workflows/toolforge/export-workflows.json",
      "created_at": "2024-12-26T10:30:14.000Z"
    }
  ],
  "logs_ref": "toolforge-550e8400-e29b-41d4-a716-446655440002",
  "rollback_executed": false,
  "rollback_details": null,
  "critic_verdict": "pass",
  "critic_details": {
    "checks_performed": [
      {
        "check_name": "intent_validation",
        "result": "pass",
        "details": "IntentSpec conforms to schema"
      },
      {
        "check_name": "toolspec_validation",
        "result": "pass",
        "details": "ToolSpec conforms to schema and Intent constraints"
      },
      {
        "check_name": "workflow_compilation",
        "result": "pass",
        "details": "Workflow compiled successfully, no inline credentials"
      },
      {
        "check_name": "file_write",
        "result": "pass",
        "details": "Workflow file written successfully"
      },
      {
        "check_name": "registry_update",
        "result": "pass",
        "details": "Tool registry updated successfully"
      }
    ],
    "overall_score": 1.0
  },
  "errors": [],
  "performance": {
    "duration_ms": 15432,
    "cpu_time_ms": 12000,
    "memory_peak_mb": 256.5,
    "network_bytes_sent": 1024,
    "network_bytes_received": 2048
  },
  "metadata": {
    "executor": "toolforge",
    "environment": "development",
    "registration_type": "success",
    "workflow_name": "ToolForge: Register Tool"
  }
}
```

**File Location:** `/home/node/.n8n/data/run-records/550e8400-e29b-41d4-a716-446655440002.json`

---

## Example 2: Failed IntentSpec Validation

**Context:** IntentSpec failed schema validation at GATE 2.

```json
{
  "run_id": "550e8400-e29b-41d4-a716-446655440003",
  "intent_id": "invalid-intent-id",
  "tool_id": null,
  "tool_version": null,
  "started_at": "2024-12-26T10:35:00.000Z",
  "finished_at": "2024-12-26T10:35:00.234Z",
  "status": "failure",
  "inputs_hash": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "outputs_hash": null,
  "artifacts": [],
  "logs_ref": "toolforge-error-550e8400-e29b-41d4-a716-446655440003",
  "rollback_executed": false,
  "rollback_details": null,
  "critic_verdict": "fail",
  "critic_details": {
    "checks_performed": [
      {
        "check_name": "intent_validation",
        "result": "fail",
        "details": "Intent does not conform to intent-spec.schema.json"
      }
    ],
    "overall_score": 0.0
  },
  "errors": [
    {
      "timestamp": "2024-12-26T10:35:00.123Z",
      "severity": "error",
      "message": "IntentSpec does not conform to schema",
      "code": "schema_validation_failed",
      "stack_trace": "AjvValidationError: data/intent_id must match format \"uuid\""
    }
  ],
  "performance": {
    "duration_ms": 234,
    "cpu_time_ms": 100,
    "memory_peak_mb": 64.0
  },
  "metadata": {
    "executor": "toolforge",
    "environment": "development",
    "error_workflow": true,
    "failed_node": "Validate Against Schema",
    "failed_node_type": "n8n-nodes-base.code"
  }
}
```

**File Location:** `/home/node/.n8n/data/run-records/550e8400-e29b-41d4-a716-446655440003.json`

---

## Example 3: Failed ToolSpec Validation

**Context:** ToolSpec failed cross-validation with Intent at GATE 4.

```json
{
  "run_id": "550e8400-e29b-41d4-a716-446655440004",
  "intent_id": "770e8400-e29b-41d4-a716-446655440007",
  "tool_id": "delete-all-data",
  "tool_version": "1.0.0",
  "started_at": "2024-12-26T10:40:00.000Z",
  "finished_at": "2024-12-26T10:40:05.678Z",
  "status": "failure",
  "inputs_hash": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "outputs_hash": null,
  "artifacts": [],
  "logs_ref": "toolforge-error-550e8400-e29b-41d4-a716-446655440004",
  "rollback_executed": false,
  "rollback_details": null,
  "critic_verdict": "fail",
  "critic_details": {
    "checks_performed": [
      {
        "check_name": "intent_validation",
        "result": "pass",
        "details": "IntentSpec validated successfully"
      },
      {
        "check_name": "llm_generation",
        "result": "pass",
        "details": "ToolSpec generated successfully"
      },
      {
        "check_name": "toolspec_cross_validation",
        "result": "fail",
        "details": "ToolSpec violates Intent constraints (forbidden actions)"
      }
    ],
    "overall_score": 0.3
  },
  "errors": [
    {
      "timestamp": "2024-12-26T10:40:05.123Z",
      "severity": "error",
      "message": "ToolSpec includes forbidden action: delete_data",
      "code": "cross_validation_failed",
      "stack_trace": null
    }
  ],
  "performance": {
    "duration_ms": 5678,
    "cpu_time_ms": 4500,
    "memory_peak_mb": 512.0
  },
  "metadata": {
    "executor": "toolforge",
    "environment": "development",
    "error_workflow": true,
    "failed_node": "Cross-Validate Against Intent",
    "failed_node_type": "n8n-nodes-base.code",
    "forbidden_action": "delete_data"
  }
}
```

**File Location:** `/home/node/.n8n/data/run-records/550e8400-e29b-41d4-a716-446655440004.json`

---

## Example 4: Failed Compilation

**Context:** Workflow compilation failed due to unknown node type at GATE 5.

```json
{
  "run_id": "550e8400-e29b-41d4-a716-446655440005",
  "intent_id": "880e8400-e29b-41d4-a716-446655440008",
  "tool_id": "broken-tool",
  "tool_version": "1.0.0",
  "started_at": "2024-12-26T10:45:00.000Z",
  "finished_at": "2024-12-26T10:45:02.345Z",
  "status": "failure",
  "inputs_hash": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "outputs_hash": null,
  "artifacts": [],
  "logs_ref": "toolforge-error-550e8400-e29b-41d4-a716-446655440005",
  "rollback_executed": false,
  "rollback_details": null,
  "critic_verdict": "fail",
  "critic_details": {
    "checks_performed": [
      {
        "check_name": "intent_validation",
        "result": "pass",
        "details": "IntentSpec validated successfully"
      },
      {
        "check_name": "toolspec_validation",
        "result": "pass",
        "details": "ToolSpec validated successfully"
      },
      {
        "check_name": "workflow_compilation",
        "result": "fail",
        "details": "Generated workflow contains invalid node types"
      }
    ],
    "overall_score": 0.5
  },
  "errors": [
    {
      "timestamp": "2024-12-26T10:45:02.100Z",
      "severity": "error",
      "message": "Unknown node type: n8n-nodes-base.nonexistent",
      "code": "compilation_failed"
    }
  ],
  "performance": {
    "duration_ms": 2345,
    "cpu_time_ms": 2000,
    "memory_peak_mb": 128.0
  },
  "metadata": {
    "executor": "toolforge",
    "environment": "development",
    "error_workflow": true,
    "failed_node": "Verify Compilation",
    "failed_node_type": "n8n-nodes-base.code",
    "invalid_node_type": "n8n-nodes-base.nonexistent"
  }
}
```

**File Location:** `/home/node/.n8n/data/run-records/550e8400-e29b-41d4-a716-446655440005.json`

---

## Example 5: Critic Rejection (Rollback Executed)

**Context:** Tool execution passed but critic verdict is fail, rollback was executed.

```json
{
  "run_id": "550e8400-e29b-41d4-a716-446655440006",
  "intent_id": "990e8400-e29b-41d4-a716-446655440009",
  "tool_id": "risky-operation",
  "tool_version": "1.0.0",
  "started_at": "2024-12-26T10:50:00.000Z",
  "finished_at": "2024-12-26T10:50:30.000Z",
  "status": "failure",
  "inputs_hash": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "outputs_hash": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  "artifacts": [
    {
      "type": "file",
      "location": "/tmp/risky-output.txt",
      "created_at": "2024-12-26T10:50:25.000Z",
      "hash": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
    }
  ],
  "logs_ref": "toolforge-550e8400-e29b-41d4-a716-446655440006",
  "rollback_executed": true,
  "rollback_details": {
    "triggered_at": "2024-12-26T10:50:28.000Z",
    "completed_at": "2024-12-26T10:50:30.000Z",
    "success": true,
    "strategy_used": "compensating",
    "notes": "Critic verdict was fail, executed compensating transaction to undo changes"
  },
  "critic_verdict": "fail",
  "critic_details": {
    "checks_performed": [
      {
        "check_name": "output_validation",
        "result": "fail",
        "details": "Output does not match required schema"
      },
      {
        "check_name": "constraint_violation",
        "result": "fail",
        "details": "Tool exceeded resource limits defined in Intent"
      },
      {
        "check_name": "side_effect_verification",
        "result": "fail",
        "details": "Unauthorized file write detected"
      }
    ],
    "overall_score": 0.0
  },
  "errors": [
    {
      "timestamp": "2024-12-26T10:50:26.000Z",
      "severity": "warning",
      "message": "Resource usage exceeded 2GB memory limit",
      "code": "RESOURCE_LIMIT_EXCEEDED"
    },
    {
      "timestamp": "2024-12-26T10:50:27.000Z",
      "severity": "error",
      "message": "Output validation failed: field 'result' missing",
      "code": "OUTPUT_VALIDATION_FAILED"
    }
  ],
  "performance": {
    "duration_ms": 30000,
    "cpu_time_ms": 25000,
    "memory_peak_mb": 4096.0,
    "network_bytes_sent": 0,
    "network_bytes_received": 0
  },
  "metadata": {
    "executor": "toolforge",
    "environment": "development",
    "rollback_reason": "critic_rejection",
    "original_intent_id": "990e8400-e29b-41d4-a716-446655440009"
  }
}
```

**File Location:** `/home/node/.n8n/data/run-records/550e8400-e29b-41d4-a716-446655440006.json`

---

## Index File Examples

### errors.jsonl (Append-Only Error Index)
```jsonl
{"run_id":"550e8400-e29b-41d4-a716-446655440003","intent_id":"invalid-intent-id","tool_id":null,"status":"failure","error_severity":"error","error_message":"IntentSpec does not conform to schema","failed_node":"Validate Against Schema","timestamp":"2024-12-26T10:35:00.234Z"}
{"run_id":"550e8400-e29b-41d4-a716-446655440004","intent_id":"770e8400-e29b-41d4-a716-446655440007","tool_id":"delete-all-data","status":"failure","error_severity":"error","error_message":"ToolSpec includes forbidden action: delete_data","failed_node":"Cross-Validate Against Intent","timestamp":"2024-12-26T10:40:05.678Z"}
{"run_id":"550e8400-e29b-41d4-a716-446655440005","intent_id":"880e8400-e29b-41d4-a716-446655440008","tool_id":"broken-tool","status":"failure","error_severity":"error","error_message":"Unknown node type: n8n-nodes-base.nonexistent","failed_node":"Verify Compilation","timestamp":"2024-12-26T10:45:02.345Z"}
```

### index.jsonl (Append-Only Master Index)
```jsonl
{"run_id":"550e8400-e29b-41d4-a716-446655440002","intent_id":"660e8400-e29b-41d4-a716-446655440001","tool_id":"export-workflows","status":"success","critic_verdict":"pass","timestamp":"2024-12-26T10:30:15.432Z"}
{"run_id":"550e8400-e29b-41d4-a716-446655440003","intent_id":"invalid-intent-id","tool_id":null,"status":"failure","critic_verdict":"fail","timestamp":"2024-12-26T10:35:00.234Z"}
{"run_id":"550e8400-e29b-41d4-a716-446655440004","intent_id":"770e8400-e29b-41d4-a716-446655440007","tool_id":"delete-all-data","status":"failure","critic_verdict":"fail","timestamp":"2024-12-26T10:40:05.678Z"}
{"run_id":"550e8400-e29b-41d4-a716-446655440005","intent_id":"880e8400-e29b-41d4-a716-446655440008","tool_id":"broken-tool","status":"failure","critic_verdict":"fail","timestamp":"2024-12-26T10:45:02.345Z"}
{"run_id":"550e8400-e29b-41d4-a716-446655440006","intent_id":"990e8400-e29b-41d4-a716-446655440009","tool_id":"risky-operation","status":"failure","critic_verdict":"fail","timestamp":"2024-12-26T10:50:30.000Z"}
```

---

## Storage Structure

```
/home/node/.n8n/data/
├── run-records/
│   ├── 550e8400-e29b-41d4-a716-446655440002.json
│   ├── 550e8400-e29b-41d4-a716-446655440003.json
│   ├── 550e8400-e29b-41d4-a716-446655440004.json
│   ├── 550e8400-e29b-41d4-a716-446655440005.json
│   ├── 550e8400-e29b-41d4-a716-446655440006.json
│   ├── index.jsonl          # All runs (append-only)
│   └── errors.jsonl         # Error runs only (append-only)
```

---

## Query Patterns

### Get All Runs for a Tool
```bash
grep "\"tool_id\": \"export-workflows\"" /home/node/.n8n/data/run-records/index.jsonl
```

### Get All Failed Runs
```bash
grep "\"status\": \"failure\"" /home/node/.n8n/data/run-records/index.jsonl
```

### Get Runs with Critic Verdict
```bash
grep "\"critic_verdict\": \"fail\"" /home/node/.n8n/data/run-records/index.jsonl
```

### Get Error Summary
```bash
jq -r '.error_message' /home/node/.n8n/data/run-records/errors.jsonl | sort | uniq -c
```

---

## Canonical RunRecord Creation Function

```javascript
const crypto = require('crypto');

function createRunRecord(context) {
  const {
    intent_id,
    tool_id,
    tool_version,
    status,
    inputs,
    outputs,
    artifacts,
    errors,
    rollback_executed,
    rollback_details,
    critic_verdict,
    critic_checks
  } = context;

  // Generate run_id (UUID v4)
  const run_id = crypto.randomUUID();

  // Hash inputs
  const inputs_hash = crypto.createHash('sha256')
    .update(JSON.stringify(inputs))
    .digest('hex');

  // Hash outputs (null if failure)
  const outputs_hash = outputs
    ? crypto.createHash('sha256').update(JSON.stringify(outputs)).digest('hex')
    : null;

  // Timestamp
  const now = new Date().toISOString();

  return {
    run_id,
    intent_id,
    tool_id,
    tool_version,
    started_at: now,
    finished_at: now,
    status,
    inputs_hash,
    outputs_hash,
    artifacts: artifacts || [],
    logs_ref: `toolforge-${run_id}`,
    rollback_executed: rollback_executed || false,
    rollback_details: rollback_details || null,
    critic_verdict: critic_verdict || (status === 'success' ? 'pass' : 'fail'),
    critic_details: {
      checks_performed: critic_checks || [],
      overall_score: critic_verdict === 'pass' ? 1.0 : 0.0
    },
    errors: errors || [],
    performance: {
      duration_ms: 0,
      cpu_time_ms: 0,
      memory_peak_mb: 0
    },
    metadata: {
      executor: 'toolforge',
      environment: process.env.NODE_ENV || 'development'
    }
  };
}
```
