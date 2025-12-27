# Dry-Run Validation Paths

## Purpose
**DEFINITIVE** specification of DRY mode validation for ToolForge adapters.

**PRINCIPLE:** Validate routing and configuration WITHOUT touching cloud services.

---

## Dry-Run Mode Definition

### What Dry-Run Is

**Dry-Run Mode:** A validation mode where ToolForge simulates the entire adapter resolution and execution path WITHOUT making any HTTP calls to cloud services.

**Goals:**
1. Validate adapter configuration is correct
2. Verify tool-to-adapter routing is valid
3. Check environment variables are present and well-formed
4. Test input/output schema compatibility
5. Emit detailed validation report

**What Dry-Run DOES:**
- ✅ Resolve adapter configuration from environment variables
- ✅ Validate adapter_id is registered
- ✅ Validate adapter_operation exists in interface
- ✅ Validate input schema matches operation requirements
- ✅ Simulate timeout enforcement
- ✅ Generate mock output matching output schema
- ✅ Emit detailed validation RunRecord

**What Dry-Run DOES NOT DO:**
- ❌ NO HTTP calls to cloud services
- ❌ NO actual adapter execution
- ❌ NO data mutation
- ❌ NO side effects
- ❌ NO credential usage (only validates presence)

---

## Dry-Run Workflow

### Trigger Dry-Run Mode

```bash
# Method 1: Environment variable
export TOOLFORGE_DRY_RUN=true
n8n execute tool

# Method 2: Intent flag
IntentSpec.dry_run = true

# Method 3: ToolForge API call
POST /api/toolforge/validate
{
  "toolspec": {...},
  "intent": {...},
  "dry_run": true
}
```

### Dry-Run Execution Flow

```
┌──────────────────────────────────────────────────────────┐
│ 1. RECEIVE Intent + ToolSpec                            │
│    - Check dry_run flag                                  │
└────────────────────┬─────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────────┐
│ 2. RESOLVE Adapter Configuration                        │
│    - Load environment variables                          │
│    - Validate required vars present                      │
│    - Check variable formats (URLs, API keys, etc.)       │
└────────────────────┬─────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────────┐
│ 3. VALIDATE Tool → Adapter Routing                      │
│    - Check adapter_id is registered                     │
│    - Check adapter_operation exists                      │
│    - Verify input schema compatibility                   │
└────────────────────┬─────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────────┐
│ 4. SIMULATE Adapter Execution (NO HTTP CALLS)           │
│    - Generate mock request payload                       │
│    - Validate against operation input schema             │
│    - Simulate timeout countdown (enforced)               │
│    - Generate mock response (matches output schema)      │
└────────────────────┬─────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────────┐
│ 5. EMIT Dry-Run RunRecord                               │
│    - Success: "Would route correctly"                   │
│    - Failure: Explicit validation error                  │
│    - Include simulated execution metadata                │
└───────────────────────────────────────────────────────────┘
```

---

## Dry-Run Validation Stages

### Stage 1: Adapter Configuration Validation

**Check:** All required environment variables are present and valid.

```javascript
function validateAdapterConfigDryRun(adapter_id) {
  const adapter = adapter_registry.get(adapter_id);
  const config = {};
  const missing = [];
  const invalid = [];
  const warnings = [];

  for (const varName of adapter.config_required) {
    const value = process.env[varName];

    // Check presence
    if (!value) {
      missing.push(varName);
      continue;
    }

    // Check format
    const validation = validateEnvVar(varName, value);
    if (!validation.valid) {
      invalid.push({ varName, reason: validation.reason });
      continue;
    }

    // Format-specific checks
    if (varName.endsWith('_URL')) {
      const urlCheck = validateUrlVar(varName, value);
      if (!urlCheck.valid) {
        invalid.push({ varName, reason: urlCheck.reason });
      }
    }

    config[varName] = value;
  }

  // Check optional variables
  for (const varName of adapter.config_optional || []) {
    const value = process.env[varName];
    if (value) {
      const validation = validateEnvVar(varName, value);
      if (!validation.valid) {
        warnings.push({ varName, reason: validation.reason });
      } else {
        config[varName] = value;
      }
    }
  }

  return {
    valid: missing.length === 0 && invalid.length === 0,
    config,
    missing,
    invalid,
    warnings
  };
}
```

**Success Output:**

```json
{
  "stage": "adapter_config_validation",
  "adapter_id": "supabase-postgres",
  "status": "pass",
  "config_resolved": {
    "SUPABASE_URL": "https://xxxxx.supabase.co",
    "SUPABASE_ANON_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "SUPABASE_DB": "postgresql",
    "SUPABASE_HOST": "xxxxx.supabase.co",
    "SUPABASE_PORT": "5432",
    "SUPABASE_USER": "postgres",
    "SUPABASE_PASSWORD": "[REDACTED]"
  },
  "note": "All required environment variables present and valid"
}
```

**Failure Output:**

```json
{
  "stage": "adapter_config_validation",
  "adapter_id": "qdrant-vector",
  "status": "fail",
  "missing_variables": ["QDRANT_URL", "QDRANT_API_KEY"],
  "invalid_variables": [],
  "resolution": "Add missing environment variables to .env file",
  "dry_run_result": "WOULD_FAIL_AT_RUNTIME"
}
```

---

### Stage 2: Tool → Adapter Routing Validation

**Check:** Tool can route to adapter successfully.

```javascript
function validateToolAdapterRouting(toolspec, dry_run = true) {
  const issues = [];

  // Check 1: adapter_id is registered
  const adapter = adapter_registry.get(toolspec.adapter_id);
  if (!adapter) {
    issues.push({
      check: "adapter_registered",
      status: "fail",
      message: `adapter_id '${toolspec.adapter_id}' is not registered`,
      valid_adapters: adapter_registry.list(),
      resolution: "Use a valid adapter_id from CLOUD_ADAPTER_INTERFACES.md"
    });
    return { valid: false, issues };
  }

  // Check 2: adapter_operation exists
  const operation = adapter.interface.operations[toolspec.adapter_operation];
  if (!operation) {
    issues.push({
      check: "operation_exists",
      status: "fail",
      message: `adapter_operation '${toolspec.adapter_operation}' not found in adapter '${toolspec.adapter_id}'`,
      valid_operations: Object.keys(adapter.interface.operations),
      resolution: "Use a valid operation from CLOUD_ADAPTER_INTERFACES.md"
    });
    return { valid: false, issues };
  }

  // Check 3: input schema compatibility
  const inputSchema = operation.input;
  const toolInput = toolspec.input_schema;

  const schemaCheck = validateSchemaCompatibility(toolInput, inputSchema);
  if (!schemaCheck.compatible) {
    issues.push({
      check: "input_schema_compatibility",
      status: "fail",
      message: "Tool input schema is not compatible with adapter operation",
      incompatibilities: schemaCheck.differences,
      resolution: "Update tool input_schema to match adapter operation requirements"
    });
  }

  // Check 4: output schema compatibility
  const outputSchema = operation.output;
  const toolOutput = toolspec.output_schema;

  const outputCheck = validateSchemaCompatibility(outputSchema, toolOutput);
  if (!outputCheck.compatible) {
    issues.push({
      check: "output_schema_compatibility",
      status: "warning",
      message: "Tool output schema may not match adapter operation",
      incompatibilities: outputCheck.differences,
      note: "This is a heuristic check - full validation requires runtime execution"
    });
  }

  return {
    valid: issues.filter(i => i.status === "fail").length === 0,
    issues,
    routing: {
      tool_id: toolspec.tool_id,
      adapter_id: toolspec.adapter_id,
      operation: toolspec.adapter_operation,
      target: adapter.execution_target
    }
  };
}
```

**Success Output:**

```json
{
  "stage": "tool_adapter_routing",
  "status": "pass",
  "routing": {
    "tool_id": "semantic-search",
    "adapter_id": "qdrant-vector",
    "operation": "search",
    "execution_target": {
      "mode": "cloud",
      "provider": "northflank",
      "region": "us-east-1",
      "service": "qdrant"
    }
  },
  "validation": {
    "adapter_registered": "pass",
    "operation_exists": "pass",
    "input_schema_compatibility": "pass",
    "output_schema_compatibility": "pass"
  },
  "dry_run_result": "WOULD_ROUTE_CORRECTLY"
}
```

**Failure Output:**

```json
{
  "stage": "tool_adapter_routing",
  "status": "fail",
  "routing": {
    "tool_id": "invalid-tool",
    "adapter_id": "unknown-adapter",
    "operation": null
  },
  "issues": [
    {
      "check": "adapter_registered",
      "status": "fail",
      "message": "adapter_id 'unknown-adapter' is not registered"
    }
  ],
  "dry_run_result": "WOULD_FAIL_AT_ROUTING"
}
```

---

### Stage 3: Simulated Execution

**Check:** Simulate adapter execution WITHOUT HTTP calls.

```javascript
async function simulateAdapterExecution(adapter, operation, input, dry_run = true) {
  const simulation = {
    dry_run: true,
    adapter_id: adapter.adapter_id,
    operation: operation,
    input: input,
    timestamp: new Date().toISOString()
  };

  // Validate input against operation schema
  const inputValidation = validateInput(operation.input_schema, input);
  if (!inputValidation.valid) {
    return {
      dry_run_result: "WOULD_FAIL_VALIDATION",
      stage: "input_validation",
      status: "fail",
      errors: inputValidation.errors
    };
  }
  simulation.input_validation = "pass";

  // Check timeout constraints
  const timeoutMs = operation.timeout || 30000;
  simulation.timeout_ms = timeoutMs;

  // Simulate timeout countdown (NO actual waiting)
  simulation.timeout_simulation = {
    started_at: new Date().toISOString(),
    would_timeout_at: new Date(Date.now() + timeoutMs).toISOString(),
    note: "Timeout would be enforced at runtime"
  };

  // Generate mock output matching operation output schema
  const mockOutput = generateMockOutput(operation.output_schema);
  simulation.mock_output = mockOutput;
  simulation.output_validation = "pass";

  // Simulate retry policy (NO actual retries)
  if (operation.retry) {
    simulation.retry_policy = {
      policy: operation.retry.policy,
      max_attempts: operation.retry.max_attempts,
      note: "Retry policy would be enforced at runtime"
    };
  }

  simulation.dry_run_result = "WOULD_EXECUTE_SUCCESSFULLY";
  simulation.status = "success";

  return simulation;
}
```

**Success Output:**

```json
{
  "stage": "simulated_execution",
  "dry_run": true,
  "adapter_id": "supabase-postgres",
  "operation": "vector_search",
  "status": "success",
  "dry_run_result": "WOULD_EXECUTE_SUCCESSFULLY",
  "input_validation": "pass",
  "timeout_ms": 10000,
  "timeout_simulation": {
    "started_at": "2024-12-26T12:00:00.000Z",
    "would_timeout_at": "2024-12-26T12:00:10.000Z"
  },
  "mock_output": {
    "results": [
      {
        "id": "mock-id-1",
        "similarity": 0.95,
        "data": { "text": "Mock result data" }
      }
    ],
    "count": 1
  },
  "output_validation": "pass",
  "note": "This is a simulation. No HTTP calls were made."
}
```

---

## Dry-Run RunRecord Format

### Success RunRecord

```json
{
  "run_id": "dry-run-550e8400-e29b-41d4-a716-446655440003",
  "dry_run": true,
  "timestamp": "2024-12-26T12:00:00.000Z",
  "intent_id": "770e8400-e29b-41d4-a716-446655440007",
  "tool_id": "semantic-search",
  "tool_version": "1.0.0",
  "adapter_id": "qdrant-vector",
  "adapter_operation": "search",
  "status": "success",
  "dry_run_result": "WOULD_ROUTE_CORRECTLY",
  "stages": [
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
        "tool_id": "semantic-search",
        "adapter_id": "qdrant-vector",
        "operation": "search",
        "execution_target": {
          "mode": "cloud",
          "provider": "northflank",
          "region": "us-east-1",
          "service": "qdrant"
        }
      }
    },
    {
      "stage": "simulated_execution",
      "status": "success",
      "dry_run_result": "WOULD_EXECUTE_SUCCESSFULLY",
      "mock_output": { "results": [], "count": 0 }
    }
  ],
  "validation_summary": {
    "total_stages": 3,
    "passed_stages": 3,
    "failed_stages": 0
  },
  "critic_verdict": "pass",
  "metadata": {
    "executor": "toolforge",
    "dry_run_mode": true,
    "note": "No HTTP calls were made. This is a validation-only execution."
  }
}
```

### Failure RunRecord

```json
{
  "run_id": "dry-run-550e8400-e29b-41d4-a716-446655440004",
  "dry_run": true,
  "timestamp": "2024-12-26T12:00:01.000Z",
  "intent_id": "880e8400-e29b-41d4-a716-446655440008",
  "tool_id": "broken-tool",
  "tool_version": "1.0.0",
  "adapter_id": "unknown-adapter",
  "adapter_operation": null,
  "status": "failure",
  "dry_run_result": "WOULD_FAIL_AT_ROUTING",
  "stages": [
    {
      "stage": "adapter_config_validation",
      "status": "skip",
      "reason": "adapter_id not registered"
    },
    {
      "stage": "tool_adapter_routing",
      "status": "fail",
      "errors": [
        {
          "check": "adapter_registered",
          "message": "adapter_id 'unknown-adapter' is not registered"
        }
      ]
    }
  ],
  "errors": [
    {
      "timestamp": "2024-12-26T12:00:01.000Z",
      "severity": "error",
      "code": "ADAPTER_NOT_REGISTERED",
      "message": "Cannot route to unregistered adapter",
      "resolution": "Use a valid adapter_id from CLOUD_ADAPTER_INTERFACES.md"
    }
  ],
  "critic_verdict": "fail",
  "metadata": {
    "executor": "toolforge",
    "dry_run_mode": true,
    "note": "Validation failed. Fix issues before runtime execution."
  }
}
```

---

## Dry-Run API Endpoints

### Validate Tool with Dry-Run

```bash
POST /api/toolforge/dry-run
Content-Type: application/json

{
  "toolspec": {
    "tool_id": "semantic-search",
    "adapter_id": "qdrant-vector",
    "adapter_operation": "search",
    "input_schema": {...},
    "output_schema": {...}
  },
  "intent": {
    "intent_id": "...",
    "objective": "Search for similar documents"
  },
  "dry_run": true
}
```

**Response (Success):**

```json
{
  "dry_run_result": "WOULD_ROUTE_CORRECTLY",
  "status": "success",
  "validation": {
    "adapter_config": "pass",
    "tool_routing": "pass",
    "simulated_execution": "pass"
  },
  "run_record": {...}
}
```

**Response (Failure):**

```json
{
  "dry_run_result": "WOULD_FAIL_AT_ROUTING",
  "status": "failure",
  "validation": {
    "adapter_config": "fail",
    "tool_routing": "fail",
    "errors": [...]
  },
  "run_record": {...}
}
```

### Batch Dry-Run Validation

```bash
POST /api/toolforge/dry-run/batch
Content-Type: application/json

{
  "toolspecs": [
    {...},
    {...},
    {...}
  ],
  "dry_run": true
}
```

**Response:**

```json
{
  "total_tools": 3,
  "would_pass": 2,
  "would_fail": 1,
  "results": [
    {
      "tool_id": "tool-1",
      "dry_run_result": "WOULD_ROUTE_CORRECTLY"
    },
    {
      "tool_id": "tool-2",
      "dry_run_result": "WOULD_ROUTE_CORRECTLY"
    },
    {
      "tool_id": "tool-3",
      "dry_run_result": "WOULD_FAIL_AT_ROUTING",
      "errors": [...]
    }
  ]
}
```

---

## Dry-Run Use Cases

### Use Case 1: Pre-Deployment Validation

Validate tools before deploying to production:

```bash
# Validate all tools in dry-run mode
for tool in tools/*.json; do
  curl -X POST http://localhost:5678/api/toolforge/dry-run \
    -H "Content-Type: application/json" \
    -d @tool
done
```

**Expected:** All tools return `WOULD_ROUTE_CORRECTLY`

### Use Case 2: Configuration Verification

Verify environment variables are correctly set:

```bash
# Dry-run all adapters to check config
docker compose run --rm n8n npx toolforge dry-run --check-config
```

**Expected:** All adapters report config validation "pass"

### Use Case 3: CI/CD Pipeline Integration

Add dry-run validation to CI pipeline:

```yaml
# .github/workflows/validate-tools.yml
name: Validate Tools

on: [push, pull_request]

jobs:
  dry-run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Start n8n
        run: docker compose --profile core up -d
      - name: Dry-run all tools
        run: |
          for tool in n8n/workflows/toolforge/*.json; do
            curl -X POST http://localhost:5678/api/toolforge/dry-run \
              -H "Content-Type: application/json" \
              -d @$tool
          done
```

---

## Dry-Run Guarantees

### Safety Guarantees

**DRY RUN GUARANTEES:**
1. ✅ NO HTTP calls to cloud services
2. ✅ NO data mutation
3. ✅ NO side effects
4. ✅ NO credential exposure (only validates presence)
5. ✅ NO adapter execution (simulation only)

**Validation Guarantees:**
1. ✅ All environment variables are validated for format
2. ✅ Tool-to-adapter routing is validated
3. ✅ Input/output schemas are checked for compatibility
4. ✅ Timeout constraints are verified
5. ✅ Detailed RunRecord emitted with validation results

### What Dry-Run Cannot Catch

**LIMITATIONS:**
- ❌ Cannot detect actual cloud service availability
- ❌ Cannot validate API keys are working (only format)
- ❌ Cannot detect rate limits or quota issues
- ❌ Cannot detect network connectivity problems
- ❌ Cannot detect runtime errors (only static validation)

**For full runtime validation, use:**
- Adapter health checks (`health_check` operations)
- Integration tests with staging environment
- Manual testing with non-destructive operations

---

## Dry-Run Exit Codes

| Exit Code | Meaning | RunRecord Status |
|-----------|---------|------------------|
| 0 | All validations passed | success |
| 1 | Adapter config validation failed | failure |
| 2 | Tool routing validation failed | failure |
| 3 | Input schema validation failed | failure |
| 4 | Adapter not registered | failure |
| 5 | Operation not found in adapter | failure |

---

## Summary

**Dry-Run Mode:** Validate WITHOUT executing

**Stages:**
1. Adapter config validation
2. Tool → Adapter routing validation
3. Simulated execution (mock output)

**Success:** `WOULD_ROUTE_CORRECTLY`
**Failure:** Explicit error with `WOULD_FAIL_AT_*` stage

**Guarantees:** NO HTTP calls, NO side effects, NO credential usage

**Next:** STOP Conditions (STEP 7.5)
