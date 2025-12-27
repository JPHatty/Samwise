# ToolForge Validation Gates & Failure Paths

## Purpose
Document all validation checkpoints in the ToolForge pipeline, including exact failure conditions and stop behaviors.

---

## Pipeline Overview

```
INTAKE → VALIDATE INTENT → GENERATE TOOLSPEC → VALIDATE TOOLSPEC → COMPILE → REGISTER
   ↓            ↓                    ↓                    ↓              ↓         ↓
 GATE 1       GATE 2              GATE 3               GATE 4          GATE 5    GATE 6
```

**At any gate failure: HALT execution, emit RunRecord, return error to caller.**

---

## GATE 1: Intake Payload Validation

**Workflow:** `toolforge_intake.json`
**Node:** "Validate Payload Exists"
**Location:** ToolForge: Intake & Route → If Node

### What is Validated
- JSON payload is not empty
- JSON is parseable
- Content-Type is application/json

### Failure Condition
```javascript
{
  "payload": null || undefined || "",
  "payload": "{}" // empty object
}
```

### Stop Behavior
- **RETURN:** HTTP 400 Bad Request
- **ERROR:** `validation_failed`
- **MESSAGE:** "Payload is empty or invalid JSON"
- **RUN_RECORD:** NOT emitted (validation happens before RunRecord creation)
- **NEXT:** Pipeline halts, caller must retry with valid payload

### Success Path
→ Proceed to GATE 2: IntentSpec Validation

---

## GATE 2: IntentSpec Schema Validation

**Workflow:** `toolforge_validate_intent.json`
**Node:** "Validate Against Schema" + "Verify Additional Constraints"
**Location:** ToolForge: Validate IntentSpec → Code Node (Ajv)

### What is Validated

#### 2a. JSON Schema Validation (Ajv)
- **Schema:** `claude-flow/contracts/intent-spec.schema.json`
- **Mode:** STRICT (no coercion, no defaults, removeAdditional: false)
- **Required Fields:**
  - `intent_id` (UUID v4 format)
  - `issued_at` (RFC3339 timestamp)
  - `issuer` (enum: "human" | "agent")
  - `objective` (non-empty, 1-1000 chars)
  - `constraints` (array, non-empty)
  - `forbidden_actions` (array, required)
  - `required_outputs` (array, required)
  - `validation_level` (enum: "strict" | "normal" | "experimental")
  - `rollback_required` (boolean)
  - `audit_required` (boolean)

#### 2b. Additional Constraint Checks
- **UUID Format:** `intent_id` must match pattern `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`
- **Timestamp Logic:** `issued_at` cannot be in the future
- **Objective Non-Empty:** `objective.trim().length > 0`
- **Constraint Conflict Warning:** Both `allowed_tools` and `forbidden_actions` specified

### Failure Conditions

#### Schema Validation Failure
```json
{
  "valid": false,
  "error": "validation_failed",
  "message": "IntentSpec does not conform to schema",
  "errors": [
    {
      "path": "/intent_id",
      "keyword": "format",
      "message": "Must match UUID v4 format"
    }
  ]
}
```

#### Constraint Violation
```json
{
  "valid": false,
  "error": "constraint_violation",
  "message": "IntentSpec failed additional constraint checks",
  "errors": [
    {
      "field": "intent_id",
      "constraint": "valid_uuid_v4",
      "message": "intent_id must be a valid UUID v4"
    }
  ]
}
```

### Stop Behavior
- **RETURN:** HTTP 400 Bad Request
- **ERROR:** `schema_validation_failed` or `constraint_violation`
- **RUN_RECORD:** Created with status=`failure`, critic_verdict=`fail`
- **HALT:** Pipeline stops immediately
- **RECOVERY:** Operator must fix IntentSpec and retry

### Success Path
→ Proceed to GATE 3: ToolSpec Generation

---

## GATE 3: ToolSpec Generation (LLM)

**Workflow:** `toolforge_generate_toolspec.json`
**Node:** "Call LLM (LOCAL)" + "Extract ToolSpec JSON"
**Location:** ToolForge: Generate ToolSpec → LangChain LLM Node

### What is Validated
- **LLM Response:** Must be valid JSON
- **JSON Structure:** Must be parseable
- **Code Block Removal:** Strip markdown ````json` blocks if present

### Failure Conditions

#### LLM Output Not JSON
```json
{
  "success": false,
  "error": "llm_output_invalid_json",
  "message": "LLM did not output valid JSON",
  "raw_response": "I'll help you with that...", // conversational filler
  "parse_error": "Unexpected token I at position 0"
}
```

#### LLM Generation Timeout
```json
{
  "success": false,
  "error": "llm_timeout",
  "message": "LLM did not respond within 120 seconds",
  "timeout_seconds": 120
}
```

### Stop Behavior
- **RETURN:** HTTP 500 Internal Server Error
- **ERROR:** `llm_generation_failed`
- **RUN_RECORD:** Created with status=`failure`, critic_verdict=`inconclusive` (LLM fault)
- **HALT:** Pipeline stops
- **RETRY:** Operator may retry (LLM is non-deterministic)

### Success Path
→ Proceed to GATE 4: ToolSpec Schema Validation

---

## GATE 4: ToolSpec Schema Validation

**Workflow:** `toolforge_validate_toolspec.json`
**Node:** "Validate ToolSpec Schema" + "Cross-Validate Against Intent"
**Location:** ToolForge: Validate ToolSpec → Code Node (Ajv)

### What is Validated

#### 4a. ToolSpec Schema (Ajv)
- **Schema:** `claude-flow/contracts/tool-spec.schema.json`
- **Mode:** STRICT
- **Required Fields:**
  - `tool_id` (pattern: `^[a-z0-9_-]+$`)
  - `version` (semver pattern)
  - `description` (10-500 chars)
  - `input_schema` (complete JSON Schema)
  - `output_schema` (complete JSON Schema)
  - `execution_mode` (enum: "local" | "remote" | "browser")
  - `credentials_required` (array of credential IDs only)
  - `side_effects` (array with effect_type, description, reversible)
  - `rollback_strategy` (enum: "none" | "compensating" | "snapshot")
  - `timeout_seconds` (1-3600)
  - `resource_class` (enum: "control" | "compute" | "state")

#### 4b. Intent Cross-Validation
- **Rollback Alignment:** If `intent.rollback_required=true`, ToolSpec `rollback_strategy` cannot be "none"
- **Forbidden Actions:** No `side_effects` can map to `intent.forbidden_actions`
- **Credential Format:** All `credentials_required` must match `^[A-Z0-9_]+$`
- **Timeout Bounds:** `timeout_seconds` must be 1-3600
- **Output Alignment:** `output_schema` should produce `intent.required_outputs` (warning only)

### Failure Conditions

#### Schema Validation Failure
```json
{
  "valid": false,
  "error": "schema_validation_failed",
  "message": "ToolSpec does not conform to schema",
  "errors": [
    {
      "path": "/tool_id",
      "keyword": "pattern",
      "message": "Must match pattern ^[a-z0-9_-]+$"
    }
  ]
}
```

#### Cross-Validation Failure
```json
{
  "valid": false,
  "error": "cross_validation_failed",
  "message": "ToolSpec violated Intent constraints",
  "errors": [
    {
      "field": "side_effects",
      "constraint": "forbidden_action",
      "message": "ToolSpec includes forbidden action: delete_data",
      "severity": "error"
    }
  ]
}
```

### Stop Behavior
- **RETURN:** HTTP 400 Bad Request
- **ERROR:** `schema_validation_failed` or `cross_validation_failed`
- **RUN_RECORD:** Created with status=`failure`, critic_verdict=`fail`
- **HALT:** Pipeline stops
- **RECOVERY:** Operator must adjust Intent or regenerate ToolSpec

### Success Path
→ Proceed to GATE 5: Workflow Compilation

---

## GATE 5: Workflow Compilation

**Workflow:** `toolforge_compile_workflow.json`
**Node:** "Verify Compilation"
**Location:** ToolForge: Compile Workflow → Code Node

### What is Validated
- **Node Completeness:** All nodes have `id`, `name`, `type`
- **Node Type Validity:** Only known n8n node types used
- **No Inline Credentials:** No passwords, tokens, secrets in workflow JSON
- **Execution Boundary:** Workflow declares execution mode (local/remote)

### Failure Conditions

#### Missing Required Fields
```json
{
  "valid": false,
  "error": "compilation_failed",
  "message": "Workflow compilation failed validation",
  "errors": [
    {
      "node": "trigger-webhook",
      "error": "missing_required_fields",
      "message": "Node must have id, name, and type"
    }
  ]
}
```

#### Credentials Inlined (CRITICAL)
```json
{
  "valid": false,
  "error": "credentials_inlined",
  "message": "Workflow contains inlined credentials (FORBIDDEN)",
  "severity": "critical"
}
```

#### Unknown Node Type
```json
{
  "valid": false,
  "error": "compilation_failed",
  "errors": [
    {
      "node": "some-node",
      "error": "invalid_node_type",
      "message": "Unknown node type: n8n-nodes-base.fakeNode"
    }
  ]
}
```

### Stop Behavior
- **RETURN:** HTTP 500 Internal Server Error
- **ERROR:** `compilation_failed`
- **RUN_RECORD:** Created with status=`failure`, critic_verdict=`fail`
- **HALT:** Pipeline stops
- **RECOVERY:** Fix workflow generation logic or ToolSpec

### Success Path
→ Proceed to GATE 6: Tool Registration

---

## GATE 6: Tool Registration

**Workflow:** `toolforge_register_tool.json`
**Node:** "Write Workflow File" + "Update Tool Registry"
**Location:** ToolForge: Register Tool → Code Node

### What is Validated
- **File Write Success:** Workflow file written to `/home/node/.n8n/workflows/toolforge/{tool_id}.json`
- **Registry Update:** Tool entry added/updated in `/home/node/.n8n/data/tool-registry.json`
- **RunRecord Emitted:** Success RunRecord written to append-only storage

### Failure Conditions

#### File Write Failure
```json
{
  "success": false,
  "error": "file_write_failed",
  "message": "Failed to write workflow file",
  "details": "EACCES: permission denied"
}
```

#### Registry Write Failure
```json
{
  "success": false,
  "error": "registry_write_failed",
  "message": "Failed to write tool registry"
}
```

#### RunRecord Write Failure (Non-Fatal)
- Continues anyway (RunRecord is audit, not blocking)
- Logs error to console

### Stop Behavior
- **RETURN:** HTTP 500 Internal Server Error
- **ERROR:** `file_write_failed` or `registry_write_failed`
- **RUN_RECORD:** Created with status=`failure`, critic_verdict=`fail`
- **HALT:** Pipeline stops
- **RECOVERY:** Check filesystem permissions, disk space

### Success Path
→ Tool registered successfully, return HTTP 200 with confirmation

---

## ERROR HANDLER: Centralized Error Catching

**Workflow:** `toolforge_fail_and_log.json`
**Trigger:** Activated by ANY parent workflow error
**Node:** "Error Trigger" → "Extract Error Context" → "Create Failure RunRecord"

### What is Captured
- **Error Details:** `$workflow.error.message`, `$workflow.error.name`, `$workflow.error.stack`
- **Workflow Context:** `id`, `name`, `mode`, `startTime`, `executionTime`
- **Node Context:** Which node failed, node type
- **Input Data:** Original input that caused failure

### Rollback Handling
- Checks `intent.rollback_required`
- Checks `toolspec.rollback_strategy`
- Executes rollback if strategy != "none"
- Documents rollback decision in `rollback_details`

### RunRecord Emission
- **Status:** `failure`
- **Critic Verdict:** `fail`
- **Errors:** Populated from error context
- **Rollback Executed:** Boolean
- **Append-Only:** Written to `/home/node/.n8n/data/run-records/{run_id}.json`

### Log Outputs
- **Individual RunRecord:** `/home/node/.n8n/data/run-records/{run_id}.json`
- **Error Index:** `/home/node/.n8n/data/run-records/errors.jsonl` (append-only)

---

## Summary Table

| Gate | Validated | Failure HTTP | RunRecord Status | Recovery |
|------|-----------|--------------|------------------|----------|
| 1. Intake | Payload non-empty | 400 | N/A | Retry with valid payload |
| 2. IntentSpec | Schema + constraints | 400 | failure (fail) | Fix IntentSpec |
| 3. LLM | JSON parseable | 500 | failure (inconclusive) | Retry (LLM non-deterministic) |
| 4. ToolSpec | Schema + Intent alignment | 400 | failure (fail) | Fix Intent or regenerate |
| 5. Compile | Node validity, no creds | 500 | failure (fail) | Fix generation logic |
| 6. Register | File/registry write | 500 | failure (fail) | Check permissions |
| Error Handler | Catch-all errors | 200 (handled) | failure (fail) | Investigate logs |

---

## Failure Path Diagram

```
                        ┌─────────────┐
                        │   INTAKE    │
                        └──────┬──────┘
                               │
                    ┌──────────▼──────────┐
                    │  VALIDATE INTENT    │ ◄── GATE 2
                    │   (Ajv + Checks)    │
                    └──────────┬──────────┘
                               │
                ┌──────────────▼──────────────┐
                │    GENERATE TOOLSPEC        │ ◄── GATE 3
                │   (LLM → JSON parse)        │
                └──────────────┬──────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  VALIDATE TOOLSPEC  │ ◄── GATE 4
                    │ (Schema + Intent)   │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   COMPILE WORKFLOW  │ ◄── GATE 5
                    │  (Nodes + No creds)  │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   REGISTER TOOL     │ ◄── GATE 6
                    │ (Write + Registry)   │
                    └──────────┬──────────┘
                               │
                        ┌──────▼──────┐
                        │   SUCCESS   │
                        └─────────────┘

                         ┌──────────┐
                         │  ERROR   │
                         │  HANDLER │
                         └────┬─────┘
                              │
                        ┌─────▼─────┐
                        │ RUNRECORD │
                        │   LOGGED  │
                        └───────────┘
```

---

## Stop Conditions (NON-NEGOTIABLE)

1. **IF INPUT DOES NOT VALIDATE** at any gate → HALT immediately
2. **IF SCHEMA VALIDATION FAILS** → HALT, return 400, emit failure RunRecord
3. **IF FORBIDDEN ACTION DETECTED** → HALT, return 400, emit failure RunRecord
4. **IF CREDENTIALS INLINED** → HALT, return 500, emit CRITICAL failure RunRecord
5. **IF ROLLBACK REQUIRED BUT NOT POSSIBLE** → HALT, emit failure RunRecord
6. **IF ANY GATE FAILS** → No partial execution, no fallback, no interpretation

**RECOVERY:** Only after operator fixes the root cause and retries.
