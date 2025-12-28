# Tool Registry Contract

## Purpose
Define the canonical structure, operations, and constraints for the tool registry used by ToolForge.

**Registry Location:** `/home/node/.n8n/data/tool-registry.json`

---

## Registry Schema

```json
{
  "tools": [
    {
      "tool_id": "export-workflows",
      "version": "1.0.0",
      "description": "Exports all n8n workflows to JSON file",
      "execution_mode": "local",
      "resource_class": "control",
      "rollback_strategy": "none",
      "timeout_seconds": 60,
      "credentials_required": ["N8N_API_KEY"],
      "side_effects": [
        {
          "effect_type": "file_write",
          "description": "Write workflows to exports/n8n/workflows.json",
          "reversible": false,
          "scope": "exports/n8n/"
        }
      ],
      "registered_at": "2024-12-26T10:30:00.000Z",
      "active": true,
      "workflow_file": "/home/node/.n8n/workflows/toolforge/export-workflows.json",
      "registered_by": "toolforge",
      "deactivated_at": null,
      "deactivated_reason": null
    }
  ],
  "last_updated": "2024-12-26T10:30:00.000Z",
  "total_tools": 1,
  "active_tools": 1
}
```

---

## Required Metadata

Every tool in the registry MUST have:

### Core Identity
- **`tool_id`** (string, required): Stable identifier, pattern `^[a-z0-9_-]+$`
- **`version`** (string, required): Semver version, pattern `^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)`
- **`description`** (string, required): 10-500 character description

### Execution Properties
- **`execution_mode`** (enum, required): `local` | `remote` | `browser`
- **`resource_class`** (enum, required): `control` | `compute` | `state`
- **`rollback_strategy`** (enum, required): `none` | `compensating` | `snapshot`
- **`timeout_seconds`** (integer, required): 1-3600

### Safety Declarations
- **`credentials_required`** (array of strings, required): Credential IDs only
- **`side_effects`** (array of objects, required): All side effects with `reversible` flag

### Registration Metadata
- **`registered_at`** (ISO 8601 timestamp, required): When tool was registered
- **`active`** (boolean, required): Whether this version is active
- **`workflow_file`** (path string, required): Location of n8n workflow JSON
- **`registered_by`** (string, required): "toolforge" or operator ID

### Deactivation Tracking (if applicable)
- **`deactivated_at`** (ISO 8601 timestamp, optional): When tool was deactivated
- **`deactivated_reason`** (string, optional): "version_update" | "security" | "deprecated" | "operator_request"

---

## Versioning Rules

### Semver Enforcement

**Major Version (X.0.0):**
- Breaking changes to `input_schema` or `output_schema`
- Changes to `execution_mode` or `resource_class`
- Removal of `side_effects`

**Minor Version (0.X.0):**
- Backwards-compatible additions to `input_schema` (new optional fields)
- Additional `side_effects` (must be non-breaking)
- Reduced `timeout_seconds`

**Patch Version (0.0.X):**
- Bug fixes in workflow logic
- Documentation updates to `description`
- Performance optimizations (no API changes)

### Version Update Procedure

When a new version of a tool is registered:

1. **Deactivate Old Version:**
   ```json
   {
     "tool_id": "export-workflows",
     "version": "1.0.0",
     "active": false,
     "deactivated_at": "2024-12-26T11:00:00.000Z",
     "deactivated_reason": "version_update"
   }
   ```

2. **Register New Version:**
   ```json
   {
     "tool_id": "export-workflows",
     "version": "1.1.0",
     "active": true,
     "registered_at": "2024-12-26T11:00:00.000Z"
   }
   ```

3. **Both Versions Coexist:**
   - Old versions remain in registry (never deleted)
   - Only `active: true` version is used for new executions
   - Existing executions using old version continue to completion

### Version Retrieval

**Get Active Version:**
```bash
jq '.tools[] | select(.tool_id == "export-workflows" and .active == true)' /home/node/.n8n/data/tool-registry.json
```

**Get All Versions:**
```bash
jq '.tools[] | select(.tool_id == "export-workflows") | sort_by(.version) | reverse' /home/node/.n8n/data/tool-registry.json
```

**Get Specific Version:**
```bash
jq '.tools[] | select(.tool_id == "export-workflows" and .version == "1.0.0")' /home/node/.n8n/data/tool-registry.json
```

---

## Deactivation and Rollback

### Deactivation Reasons

| Reason | Description | Reversible |
|--------|-------------|------------|
| `version_update` | New version registered | Yes (reactivate old version) |
| `security` | Security vulnerability detected | No (keep deactivated) |
| `deprecated` | Tool superseded by alternative | Yes (if still safe) |
| `operator_request` | Manual operator action | Yes (operator decision) |

### Rollback Procedure

To rollback to a previous version:

1. **Identify Target Version:**
   ```bash
   jq '.tools[] | select(.tool_id == "export-workflows" and .version == "1.0.0")' /home/node/.n8n/data/tool-registry.json
   ```

2. **Deactivate Current Version:**
   ```javascript
   const registry = JSON.parse(fs.readFileSync('/home/node/.n8n/data/tool-registry.json', 'utf8'));
   const current = registry.tools.find(t => t.tool_id === 'export-workflows' && t.active);
   if (current) {
     current.active = false;
     current.deactivated_at = new Date().toISOString();
     current.deactivated_reason = 'operator_request';
   }
   ```

3. **Reactivate Target Version:**
   ```javascript
   const target = registry.tools.find(t => t.tool_id === 'export-workflows' && t.version === '1.0.0');
   if (target) {
     target.active = true;
     target.deactivated_at = null;
     target.deactivated_reason = null;
   }
   ```

4. **Write Registry:**
   ```javascript
   fs.writeFileSync('/home/node/.n8n/data/tool-registry.json', JSON.stringify(registry, null, 2), 'utf8');
   ```

### Rollback Safety Checks

Before rolling back, verify:
- [ ] Target version has no security vulnerabilities
- [ ] Target version workflow file still exists
- [ ] Target version credentials are still available
- [ ] Rollback is logged in DECISIONS.md

---

## Indexing and Queries

### Primary Index: `tool_id`

**Unique Constraint:** Each `tool_id` can have multiple versions, but only ONE active version per tool_id.

### Secondary Indexes

**By Execution Mode:**
```bash
jq '.tools[] | select(.active == true) | select(.execution_mode == "remote")' /home/node/.n8n/data/tool-registry.json
```

**By Resource Class:**
```bash
jq '.tools[] | select(.active == true) | select(.resource_class == "compute")' /home/node/.n8n/data/tool-registry.json
```

**By Credential:**
```bash
jq '.tools[] | select(.active == true) | select(.credentials_required[] | contains("GITHUB_TOKEN"))' /home/node/.n8n/data/tool-registry.json
```

**By Side Effect:**
```bash
jq '.tools[] | select(.active == true) | select(.side_effects[].effect_type == "network_request")' /home/node/.n8n/data/tool-registry.json
```

### Full-Text Search

```bash
jq -r '.tools[] | select(.active == true) | .description' /home/node/.n8n/data/tool-registry.json | grep -i "backup"
```

---

## Atomic Update Operations

### Register New Tool

```javascript
const crypto = require('crypto');
const fs = require('fs');

// ACQUIRE LOCK (pseudo-code, use file lock in production)
const lock = acquireLock('/home/node/.n8n/data/tool-registry.lock');

try {
  // READ CURRENT REGISTRY
  const registry = JSON.parse(fs.readFileSync('/home/node/.n8n/data/tool-registry.json', 'utf8'));

  // CHECK FOR CONFLICTING ACTIVE VERSION
  const conflict = registry.tools.find(t => t.tool_id === newTool.tool_id && t.active);
  if (conflict) {
    conflict.active = false;
    conflict.deactivated_at = new Date().toISOString();
    conflict.deactivated_reason = 'version_update';
  }

  // ADD NEW TOOL
  registry.tools.push({
    ...newTool,
    registered_at: new Date().toISOString(),
    active: true,
    workflow_file: `/home/node/.n8n/workflows/toolforge/${newTool.tool_id}.json`,
    registered_by: 'toolforge'
  });

  // UPDATE METADATA
  registry.last_updated = new Date().toISOString();
  registry.total_tools = registry.tools.length;
  registry.active_tools = registry.tools.filter(t => t.active).length;

  // WRITE REGISTRY
  fs.writeFileSync('/home/node/.n8n/data/tool-registry.json', JSON.stringify(registry, null, 2), 'utf8');

} finally {
  // RELEASE LOCK
  releaseLock(lock);
}
```

### Deactivate Tool

```javascript
const lock = acquireLock('/home/node/.n8n/data/tool-registry.lock');

try {
  const registry = JSON.parse(fs.readFileSync('/home/node/.n8n/data/tool-registry.json', 'utf8'));

  const tool = registry.tools.find(t => t.tool_id === toolId && t.version === version);
  if (!tool) {
    throw new Error(`Tool ${toolId}@${version} not found`);
  }

  tool.active = false;
  tool.deactivated_at = new Date().toISOString();
  tool.deactivated_reason = reason;

  registry.active_tools = registry.tools.filter(t => t.active).length;
  registry.last_updated = new Date().toISOString();

  fs.writeFileSync('/home/node/.n8n/data/tool-registry.json', JSON.stringify(registry, null, 2), 'utf8');

} finally {
  releaseLock(lock);
}
```

---

## Consistency Constraints

### Invariant 1: One Active Version Per Tool ID
```
FOR EACH tool_id:
  COUNT(tools WHERE active = true) = 1
```

### Invariant 2: All Active Tools Have Valid Workflow Files
```
FOR EACH tool WHERE active = true:
  EXISTS file at tool.workflow_file
```

### Invariant 3: Credential IDs Refer to Defined n8n Credentials
```
FOR EACH tool WHERE active = true:
  FOR EACH credential_id IN tool.credentials_required:
    EXISTS n8n credential with name = credential_id
```

### Invariant 4: No Active Tools With Security Deactivation
```
FOR EACH tool WHERE active = true:
  tool.deactivated_reason != "security"
```

---

## Audit Trail

### Registry Change Log

All mutations to the registry should be logged to `/home/node/.n8n/data/tool-registry-changes.jsonl`:

```jsonl
{"timestamp":"2024-12-26T10:30:00.000Z","action":"register","tool_id":"export-workflows","version":"1.0.0","operator":"toolforge","previous_state":null}
{"timestamp":"2024-12-26T11:00:00.000Z","action":"update","tool_id":"export-workflows","version":"1.1.0","operator":"toolforge","previous_state":{"version":"1.0.0","active":true}}
{"timestamp":"2024-12-26T11:05:00.000Z","action":"deactivate","tool_id":"export-workflows","version":"1.0.0","operator":"operator","reason":"version_update"}
```

### Reconstruct Registry State at Timestamp

```bash
# Get registry state as of 2024-12-26T10:45:00Z
jq -r 'select(.timestamp <= "2024-12-26T10:45:00Z")' /home/node/.n8n/data/tool-registry-changes.jsonl | \
  jq 'group_by(.tool_id) | map({tool_id: .[0].tool_id, versions: [.[].version]})'
```

---

## Backup and Restore

### Backup Registry
```bash
cp /home/node/.n8n/data/tool-registry.json /home/node/.n8n/backups/tool-registry-$(date +%Y%m%d-%H%M%S).json
```

### Restore Registry
```bash
cp /home/node/.n8n/backups/tool-registry-20241226-103000.json /home/node/.n8n/data/tool-registry.json
```

### Validation After Restore
```bash
# Verify JSON is valid
jq empty /home/node/.n8n/data/tool-registry.json

# Verify invariants
# (Use n8n workflow to check all 4 invariants)
```

---

## Integration Points

### With ToolForge Registration Workflow

The `toolforge_register_tool.json` workflow is the **ONLY** authorized mutator of the registry.

**Manual edits** to `tool-registry.json are FORBIDDEN** during normal operations.

Emergency manual edits must be:
1. Documented in DECISIONS.md
2. Logged to tool-registry-changes.jsonl
3. Validated against all 4 invariants
4. Backed up before modification

### With n8n Workflow System

**Tool Discovery:**
When an Intent specifies `allowed_tools`, ToolForge queries the registry:

```javascript
const allowedTools = intent.allowed_tools || [];
const registeredTools = registry.tools.filter(t =>
  t.active && allowedTools.includes(t.tool_id)
);
```

**Tool Execution:**
When executing a tool, n8n loads workflow from `workflow_file` path.

### With RunRecord System

Every tool registration creates a RunRecord with `artifacts` including:
- `type: "file"` → `location: workflow_file`
- `type: "configuration"` → `location: tool-registry.json`

---

## Monitoring and Alerts

### Health Checks

**Registry Health Metrics:**
- Total tools registered
- Active tools vs inactive
- Tools by execution mode
- Tools by resource class
- Recent registrations (last 24h)
- Failed registrations (from RunRecords)

**Alert Conditions:**
- Registry file size > 10MB (indicates bloat)
- More than 100 versions of same tool_id (indicates version churn)
- Active tools with missing workflow files (critical)
- Tools deactivated for "security" reason (investigate)

### Example Metrics Query

```bash
echo "Active Tools: $(jq '.active_tools' /home/node/.n8n/data/tool-registry.json)"
echo "Total Tools: $(jq '.total_tools' /home/node/.n8n/data/tool-registry.json)"
echo "Remote Tools: $(jq '[.tools[] | select(.active == true and .execution_mode == "remote")] | length' /home/node/.n8n/data/tool-registry.json)"
echo "Compute Tools: $(jq '[.tools[] | select(.active == true and .resource_class == "compute")] | length' /home/node/.n8n/data/tool-registry.json)"
```
