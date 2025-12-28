# ToolForge Test Vectors

## Purpose
Provide dry-run test cases for validation gates. NO EXECUTION - these are input/output examples only.

**NOTE:** These are DOCUMENTATION artifacts, not executable tests. They demonstrate expected pass/fail behavior.

---

## Valid IntentSpec Examples

### Test Case V1: Simple Export Intent

**Input:**
```json
{
  "intent_id": "123e4567-e89b-12d3-a456-426614174000",
  "issued_at": "2024-12-26T12:00:00.000Z",
  "issuer": "human",
  "objective": "Export all n8n workflows to JSON file in exports directory",
  "constraints": [
    {
      "type": "scope_boundary",
      "description": "Only export workflows, do not modify",
      "value": "read-only"
    }
  ],
  "allowed_tools": ["export-workflows"],
  "forbidden_actions": ["delete_data", "modify_production"],
  "required_outputs": [
    {
      "artifact_type": "file",
      "format": "json",
      "destination": "exports/n8n/workflows.json"
    }
  ],
  "validation_level": "normal",
  "rollback_required": false,
  "audit_required": true
}
```

**Expected Outcome:** PASS at GATE 2
**Reasoning:** All required fields present, valid UUID, valid timestamp, no conflicts

---

### Test Case V2: Cloud Deployment Intent

**Input:**
```json
{
  "intent_id": "123e4567-e89b-12d3-a456-426614174001",
  "issued_at": "2024-12-26T12:05:00.000Z",
  "issuer": "agent",
  "objective": "Deploy container to Northflank free tier",
  "constraints": [
    {
      "type": "resource_limit",
      "description": "Max 512MB memory, 0.5 CPU",
      "value": {"memory_mb": 512, "cpu_cores": 0.5}
    },
    {
      "type": "service_restriction",
      "description": "Only free tier services",
      "value": "northflank-free"
    }
  ],
  "allowed_tools": ["deploy-northflank"],
  "forbidden_actions": ["modify_production", "expose_credentials"],
  "required_outputs": [
    {
      "artifact_type": "report",
      "format": "json",
      "schema_ref": "https://github.com/JPHatty/Samwise/schemas/deployment-report.json"
    }
  ],
  "validation_level": "strict",
  "rollback_required": true,
  "audit_required": true,
  "metadata": {
    "parent_intent_id": "123e4567-e89b-12d3-a456-426614174000",
    "priority": "high"
  }
}
```

**Expected Outcome:** PASS at GATE 2
**Reasoning:** Valid nested constraints, metadata allowed, parent_intent_id valid UUID

---

### Test Case V3: Vector Search Intent

**Input:**
```json
{
  "intent_id": "123e4567-e89b-12d3-a456-426614174002",
  "issued_at": "2024-12-26T12:10:00.000Z",
  "issuer": "human",
  "objective": "Perform semantic search over document embeddings using Qdrant",
  "constraints": [
    {
      "type": "data_protection",
      "description": "No sensitive data in embeddings"
    }
  ],
  "allowed_tools": [],
  "forbidden_actions": ["delete_data", "install_dependencies"],
  "required_outputs": [
    {
      "artifact_type": "metric",
      "format": "json",
      "schema_ref": "https://github.com/JPHatty/Samwise/schemas/search-metrics.json"
    }
  ],
  "validation_level": "normal",
  "rollback_required": false,
  "audit_required": true
}
```

**Expected Outcome:** PASS at GATE 2
**Reasoning:** Empty allowed_tools is valid (all tools allowed), objective non-empty

---

## Invalid IntentSpec Examples

### Test Case I1: Missing Required Field

**Input:**
```json
{
  "intent_id": "invalid-uuid-not-a-uuid",
  "issued_at": "2024-12-26T12:00:00.000Z",
  "issuer": "human",
  "objective": "",
  "constraints": [],
  "forbidden_actions": [],
  "required_outputs": [],
  "validation_level": "normal",
  "rollback_required": false,
  "audit_required": false
}
```

**Expected Outcome:** FAIL at GATE 2
**Failure Mode:** Schema validation
**Errors:**
- `intent_id`: Does not match UUID v4 format
- `objective`: Too short (0 < 1)
- Missing `constraints` items (must have at least one)

---

### Test Case I2: Forbidden Action Conflict

**Input:**
```json
{
  "intent_id": "123e4567-e89b-12d3-a456-426614174003",
  "issued_at": "2024-12-26T12:15:00.000Z",
  "issuer": "human",
  "objective": "Backup database then delete old backups",
  "constraints": [],
  "allowed_tools": [],
  "forbidden_actions": ["delete_data"],
  "required_outputs": [
    {
      "artifact_type": "file",
      "format": "binary"
    }
  ],
  "validation_level": "normal",
  "rollback_required": true,
  "audit_required": true
}
```

**Expected Outcome:** PASS at GATE 2 (Intent is valid), BUT will fail ToolSpec generation if LLM generates delete_data side_effect

**Note:** This is a VALID IntentSpec (schema-compliant) but represents an operator error - requesting deletion while forbidding deletion. The LLM may struggle to generate a compliant ToolSpec.

---

### Test Case I3: Future Timestamp

**Input:**
```json
{
  "intent_id": "123e4567-e89b-12d3-a456-426614174004",
  "issued_at": "2099-12-26T12:00:00.000Z",
  "issuer": "human",
  "objective": "Test intent from future",
  "constraints": [],
  "forbidden_actions": [],
  "required_outputs": [],
  "validation_level": "normal",
  "rollback_required": false,
  "audit_required": false
}
```

**Expected Outcome:** FAIL at GATE 2 (Additional Constraints)
**Failure Mode:** Constraint violation
**Error:** `issued_at` cannot be in the future

---

### Test Case I4: Missing Forbidden Actions

**Input:**
```json
{
  "intent_id": "123e4567-e89b-12d3-a456-426614174005",
  "issued_at": "2024-12-26T12:20:00.000Z",
  "issuer": "human",
  "objective": "Do something without safety constraints",
  "constraints": [],
  "forbidden_actions": [],
  "required_outputs": [],
  "validation_level": "experimental",
  "rollback_required": false,
  "audit_required": false
}
```

**Expected Outcome:** PASS at GATE 2 (schema-compliant)

**Warning:** Empty `forbidden_actions` is valid but dangerous. In production, this would trigger a manual review warning.

---

## Expected Pass/Fail Outcomes

| Test Case | Gate 2 Result | Reason |
|-----------|---------------|--------|
| V1: Simple Export | PASS | All fields valid, constraints explicit |
| V2: Cloud Deploy | PASS | Nested constraints valid, metadata allowed |
| V3: Vector Search | PASS | Empty allowed_tools is valid |
| I1: Missing Fields | FAIL | Invalid UUID, empty objective |
| I2: Self-Contradicting | PASS* | Schema valid, but may fail ToolSpec generation |
| I3: Future Timestamp | FAIL | Additional constraint: no future dates |
| I4: No Safety | PASS | Schema valid, but flagged for review |

\* I2 passes schema validation but represents a logical contradiction.

---

## ToolSpec Validation Examples

### Test Case T1: Valid ToolSpec

**Input (Generated ToolSpec):**
```json
{
  "tool_id": "export-workflows",
  "version": "1.0.0",
  "description": "Exports all n8n workflows to JSON file",
  "input_schema": {
    "type": "object",
    "properties": {
      "format": {
        "type": "string",
        "enum": ["json", "yaml"]
      }
    },
    "required": ["format"]
  },
  "output_schema": {
    "type": "object",
    "properties": {
      "file_path": {
        "type": "string"
      },
      "count": {
        "type": "integer"
      }
    },
    "required": ["file_path", "count"]
  },
  "execution_mode": "local",
  "credentials_required": ["N8N_API_KEY"],
  "side_effects": [
    {
      "effect_type": "file_write",
      "description": "Write export file",
      "reversible": false,
      "scope": "exports/n8n/"
    }
  ],
  "rollback_strategy": "none",
  "timeout_seconds": 60,
  "resource_class": "control"
}
```

**Expected Outcome:** PASS at GATE 4
**Reasoning:** All required fields, valid format, credential IDs only, side_effects declared

---

### Test Case T2: Invalid ToolSpec (Inline Credentials)

**Input:**
```json
{
  "tool_id": "bad-tool",
  "version": "1.0.0",
  "description": "Tool with inline credentials",
  "input_schema": {"type": "object"},
  "output_schema": {"type": "object"},
  "execution_mode": "remote",
  "credentials_required": ["github_pat_11B373QLY0Z3bcYeS7nFgf"],
  "side_effects": [],
  "rollback_strategy": "none",
  "timeout_seconds": 60,
  "resource_class": "compute"
}
```

**Expected Outcome:** FAIL at GATE 4 (Credential Format)
**Failure Mode:** Cross-validation
**Error:** Invalid credential ID format (contains secret, not ID)

---

### Test Case T3: Invalid ToolSpec (Forbidden Side Effect)

**Context:** Intent with `forbidden_actions: ["delete_data"]`

**Input ToolSpec:**
```json
{
  "tool_id": "delete-all-files",
  "version": "1.0.0",
  "description": "Deletes all files in directory",
  "input_schema": {"type": "object"},
  "output_schema": {"type": "object"},
  "execution_mode": "local",
  "credentials_required": [],
  "side_effects": [
    {
      "effect_type": "file_delete",
      "description": "Delete files",
      "reversible": false,
      "scope": "/tmp/*"
    }
  ],
  "rollback_strategy": "snapshot",
  "timeout_seconds": 30,
  "resource_class": "state"
}
```

**Expected Outcome:** FAIL at GATE 4 (Forbidden Action)
**Failure Mode:** Cross-validation
**Error:** ToolSpec includes forbidden action: delete_data (file_delete maps to delete_data)

---

## Full Pipeline Test Examples

### Test Case P1: Complete Success Pipeline

**Input Intent:** V1 (Simple Export Intent)

**Expected Flow:**
1. GATE 1: PASS (payload non-empty)
2. GATE 2: PASS (IntentSpec valid)
3. GATE 3: PASS (LLM generates valid ToolSpec)
4. GATE 4: PASS (ToolSpec valid, aligns with Intent)
5. GATE 5: PASS (Workflow compiles, no inline creds)
6. GATE 6: PASS (Tool registered, RunRecord emitted)

**Final Output:**
```json
{
  "registered": true,
  "tool_id": "export-workflows",
  "version": "1.0.0",
  "run_record": {
    "run_id": "...",
    "status": "success",
    "critic_verdict": "pass"
  }
}
```

---

### Test Case P2: Failure at Gate 2

**Input Intent:** I1 (Missing Required Field)

**Expected Flow:**
1. GATE 1: PASS (payload non-empty)
2. GATE 2: FAIL (Intent invalid)

**Final Output:**
```json
{
  "valid": false,
  "error": "validation_failed",
  "errors": [
    {
      "path": "/intent_id",
      "message": "Does not match format 'uuid'"
    }
  ]
}
```

**RunRecord:** Created with status=`failure`, critic_verdict=`fail`

---

### Test Case P3: Failure at Gate 4

**Input Intent:** V2 (Cloud Deployment)

**LLM Generated ToolSpec:** T2 (Inline Credentials)

**Expected Flow:**
1. GATE 1: PASS
2. GATE 2: PASS (Intent valid)
3. GATE 3: PASS (LLM generated ToolSpec)
4. GATE 4: FAIL (Invalid credential format)

**Final Output:**
```json
{
  "valid": false,
  "error": "cross_validation_failed",
  "errors": [
    {
      "field": "credentials_required",
      "constraint": "credential_id_only",
      "message": "Invalid credential ID format: github_pat_...",
      "severity": "error"
    }
  ]
}
```

**Recovery:** Operator must adjust Intent or LLM prompt to exclude credentials

---

## NO EXECUTION GUARANTEE

**All test vectors are DRY-RUN ONLY.**

None of these test cases will:
- Start Docker containers
- Pull images
- Execute n8n workflows
- Call external APIs
- Modify system state
- Access credentials

These are INPUT/OUTPUT examples for validation testing only.
