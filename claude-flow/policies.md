# Claude-Flow Policies

## Operational Policies

### Before ANY Action
1. Check current state in Redis
2. Verify prerequisites in OPERATING_RULES.md
3. Export current workflows
4. Log decision in DECISIONS.md

### Workflow Modifications
- Never modify running workflows
- Always test in isolated environment
- Require manual approval for production

### Infrastructure Changes
- Never auto-deploy to production
- Always verify health checks
- Maintain rollback capability

### Credential Management
- Never log credentials
- Never expose in error messages
- Rotate on schedule per OPERATING_RULES.md

## Error Handling
- Log all errors to exports/logs/
- Notify via n8n webhook
- Halt on critical failures
- Provide recovery instructions
