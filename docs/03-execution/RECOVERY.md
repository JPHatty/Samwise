# Recovery Procedures

## Purpose
Step-by-step recovery procedures for system failures and data loss.

## Recovery Scenarios

### Complete System Failure

#### Prerequisites
- Access to `exports/snapshots/`
- Docker and Docker Compose installed
- Network connectivity

#### Procedure
1. Navigate to project root: `cd /mnt/d/devops-workspace/samwise`
2. Verify exports exist: `ls -lh exports/snapshots/`
3. Restore configurations: `./scripts/recovery/restore-configs.sh`
4. Start core services: `docker compose -f docker/compose.yaml up -d redis traefik`
5. Restore n8n data: `./scripts/recovery/restore-n8n.sh`
6. Start remaining services: `docker compose -f docker/compose.yaml up -d`
7. Verify health: `./scripts/verify/health-check.sh`

### n8n Workflow Corruption

#### Procedure
1. Stop n8n: `docker compose -f docker/compose.yaml stop n8n`
2. Identify latest valid export: `ls -lt exports/n8n/`
3. Restore workflows: `./scripts/recovery/restore-workflows.sh <snapshot-date>`
4. Start n8n: `docker compose -f docker/compose.yaml start n8n`
5. Verify workflows: Access n8n UI and test critical workflows

### Credential Compromise

#### Procedure
1. Rotate compromised credentials immediately
2. Update .env files with new credentials
3. Restart affected services: `docker compose -f docker/compose.yaml restart <service>`
4. Audit logs: `./scripts/verify/audit-access.sh`
5. Document in DECISIONS.md

### Data Loss in Redis

#### Procedure
1. Redis is ephemeral cache - no persistent data
2. Services will rebuild state on reconnect
3. Monitor service logs for rebuild completion
4. No action required unless services fail to reconnect

## Recovery Testing
- Monthly recovery drills required
- Document test results in `exports/reports/`
- Update procedures based on lessons learned

## Escalation
If recovery fails after 3 attempts, document failure mode and halt operations.
