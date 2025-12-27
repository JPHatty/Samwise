# Operating Rules

## Purpose
Operational procedures, safety protocols, and runtime constraints.

## Non-Negotiable Rules

### Before ANY Deployment
1. Export current n8n workflows to `exports/n8n/`
2. Verify backup exists
3. Document change in DECISIONS.md
4. Test in local environment first

### Service Management
1. Never force-remove containers with active data
2. Always check logs before restart
3. Verify health endpoints after deployment
4. Monitor resource usage for 5 minutes post-deploy

### Credential Management
1. Never commit .env files
2. Rotate credentials quarterly
3. Use .env.example as template only
4. Validate credentials before service start

### Network Management
1. All ports documented in PORTS_AND_LIMITS.md
2. No dynamic port assignment
3. Firewall rules must precede service start
4. TLS required for external endpoints

### Data Management
1. Daily exports to `exports/snapshots/`
2. Verify export integrity before deletion
3. Retain minimum 7 days of snapshots
4. Test recovery procedures monthly

## Emergency Procedures
See [RECOVERY.md](./RECOVERY.md) for incident response.

## Change Management
See [DECISIONS.md](./DECISIONS.md) for decision logging.
