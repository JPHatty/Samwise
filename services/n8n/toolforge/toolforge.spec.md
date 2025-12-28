# ToolForge Specification

## Purpose
Define the ToolForge agent framework for n8n workflow integration.

## ToolSpec to n8n Workflow Mapping

### Core Principle
Each `tool-spec.schema.json` instance maps to **exactly one** n8n workflow.

### Mapping Rules

**tool_id → Workflow Name**
- Tool ID becomes n8n workflow name
- Example: `tool_id: "deploy-service"` → n8n workflow: "deploy-service"
- Pattern: `^[a-z0-9_-]+$` (lowercase, alphanumeric, hyphens, underscores)

**version → Workflow Tags**
- Tool version stored as n8n workflow tag
- Example: `version: "1.0.0"` → tag: `v1.0.0`
- Enables version-specific workflow execution

**input_schema → Webhook Schema Validation**
- n8n webhook node validates incoming requests against input_schema
- Invalid inputs rejected before workflow execution
- Returns 400 Bad Request with validation errors

**output_schema → Response Formatting**
- Workflow output formatted per output_schema before return
- Final node validates output against schema
- Validation failure triggers rollback (if strategy != "none")

**execution_mode → n8n Execution Context**
- `local`: Execute in n8n container
- `remote`: HTTP Request node to external service
- `browser`: Not supported in n8n (requires separate service)

**credentials_required → n8n Credentials**
- Each credential ID maps to n8n credential by name
- Example: `GITHUB_TOKEN` → n8n credential: "GitHub API Token"
- Credentials injected via n8n credential system

**side_effects → Workflow Nodes**
- Each side_effect maps to specific n8n node types:
  - `file_write` → Write Binary File node
  - `file_delete` → Delete File node (custom or Execute Command)
  - `network_request` → HTTP Request node
  - `state_mutation` → Redis node (SET command)
  - `service_restart` → Execute Command node (docker restart)
  - `database_write` → Postgres/MySQL node
  - `credential_access` → Credentials node
  - `log_generation` → Function/Code node (console.log)

**rollback_strategy → Error Workflow**
- `none`: No error workflow
- `compensating`: Error trigger activates "rollback" sub-workflow
- `snapshot`: Pre-execution snapshot node, restore on error

**timeout_seconds → Workflow Settings**
- Maps to n8n workflow execution timeout setting
- Bounded: 1-3600 seconds (per tool-spec)

**resource_class → Workflow Execution Queue**
- `control`: Priority queue (low latency)
- `compute`: Standard queue (higher throughput)
- `state`: Dedicated queue (serialized execution)

### Example Mapping

**tool-spec.json**:
```json
{
  "tool_id": "export-workflows",
  "version": "1.0.0",
  "execution_mode": "local",
  "credentials_required": ["N8N_API_KEY"],
  "side_effects": [
    {"effect_type": "file_write", "scope": "exports/n8n/"}
  ],
  "rollback_strategy": "none",
  "timeout_seconds": 60,
  "resource_class": "control"
}
```

**n8n Workflow Structure**:
- Workflow Name: `export-workflows`
- Tags: `v1.0.0`, `control`
- Trigger: Webhook (validates input_schema)
- Credentials: n8n credential "N8N API Key"
- Nodes:
  1. HTTP Request (n8n API /workflows)
  2. Function (format data)
  3. Write Binary File (exports/n8n/workflows.json)
- Settings:
  - Timeout: 60 seconds
  - Execution queue: control

### Validation Workflow

**Pre-execution** (n8n webhook node):
1. Validate request against input_schema
2. Return 400 if invalid
3. Extract intent_id from headers/payload

**During execution**:
1. Generate run_id (UUID v4)
2. Hash inputs (SHA-256)
3. Execute workflow nodes
4. Capture all node outputs
5. Handle errors per rollback_strategy

**Post-execution**:
1. Hash outputs (SHA-256)
2. Format response per output_schema
3. Validate output format
4. Write run-record to Redis/file storage
5. Return response with run_id

## Architecture
- Workflow-based tool execution
- Dynamic capability registration (via tool-spec)
- Event-driven coordination (Redis pub/sub)
- Persistent state management (Redis + file exports)

## Integration Points
- n8n webhook triggers (input validation)
- Redis pub/sub messaging (event coordination)
- Claude-Flow MCP servers (intent → tool mapping)
- Run-record storage (append-only audit trail)

## Tool Schema
See `claude-flow/contracts/tool-spec.schema.json` for complete specification.
