# Claude-Flow Policies

## Purpose
Operational procedures, safety protocols, and runtime constraints.

## Contract Enforcement (NON-NEGOTIABLE)

### Input Validation
**IF INPUT DOES NOT VALIDATE, EXECUTION HALTS.**

All inputs must conform to `intent-spec.schema.json`:
- Intent ID must be valid UUID v4
- Timestamp must be RFC3339 compliant
- Objective must be non-empty (1-1000 characters)
- All required fields must be present
- No additional properties allowed
- Constraints must be machine-validatable

**Validation Failure = Immediate Halt**
- No partial execution
- No fallback to "best effort"
- No interpretation of malformed input
- Error logged to run-record
- Operator notified

### Schema Adherence
Schemas are **LAW, not guidance**:
- `intent-spec.schema.json` - Defines valid intents
- `tool-spec.schema.json` - Defines executable tools
- `run-record.schema.json` - Defines audit trail

**All execution MUST**:
1. Validate input against intent-spec
2. Validate tool capabilities against tool-spec
3. Record outcome in run-record format
4. Reject unknown fields
5. Enforce type constraints
6. Verify required fields

### Execution Contract
Every execution creates an immutable run-record:
- Append-only storage
- No mutation after write
- SHA-256 hashes for inputs/outputs
- Critic verdict required
- Rollback status documented

## Operational Policies

### Before ANY Action
1. Validate intent against schema
2. Check current state in Redis
3. Verify prerequisites in OPERATING_RULES.md
4. Export current workflows
5. Log decision in DECISIONS.md

### Workflow Modifications
- Never modify running workflows
- Always test in isolated environment
- Require manual approval for production
- Validate against tool-spec before deployment

### Infrastructure Changes
- Never auto-deploy to production
- Always verify health checks
- Maintain rollback capability
- Document in run-record

### Credential Management
- Never log credentials
- Never expose in error messages
- Rotate on schedule per OPERATING_RULES.md
- Credential IDs only in tool-spec (never secrets)

## Error Handling
- Log all errors to exports/logs/
- Record in run-record.errors array
- Notify via n8n webhook
- Halt on critical failures
- Provide recovery instructions
- Update critic_verdict appropriately
