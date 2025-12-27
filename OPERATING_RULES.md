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

## Docker Configuration Constraints

### Physical Reality Principle

**Rule: Docker config defines physical reality; workflows adapt to it.**

- Resource limits in `compose.yaml` are absolute ceilings
- Services MUST NOT exceed allocated memory/CPU
- If workflow requires more resources, update compose.yaml FIRST
- Monitor with `docker stats` before/after changes
- No implicit defaults; all constraints explicit

### Profile-Only Activation

**Rule: Profiles are the only allowed activation mechanism.**

- All services are DISABLED by default
- Activation requires explicit `--profile <name>` flag
- Valid profiles listed in `.env.example`
- Multiple profiles allowed: `docker compose --profile core --profile monitoring up`
- NEVER remove `profiles:` section to auto-enable service

### Constraint Enforcement

**Before starting ANY service:**

1. Verify `.env` file exists and is populated
2. Check required variables are non-empty
3. Confirm resource limits are acceptable
4. Ensure volume paths exist (or can be created)
5. Verify no port conflicts on host

**Starting services:**

```bash
# Enable core infrastructure
docker compose --profile core up -d

# Enable monitoring
docker compose --profile monitoring up -d

# Enable multiple profiles
docker compose --profile core --profile database --profile monitoring up -d
```

**Stopping services:**

```bash
# Stop specific profile
docker compose --profile monitoring down

# Stop all running services
docker compose down
```

### Resource Monitoring

**Check resource usage:**

```bash
# Live stats for all containers
docker stats

# Inspect specific service limits
docker inspect samwise-n8n | grep -A 10 Memory

# Check volume usage
docker system df -v
```

**If service is OOM killed:**

1. Check `docker logs <container>` for OOM evidence
2. Review `PORTS_AND_LIMITS.md` for current limits
3. Increase memory limit in compose.yaml
4. Update `PORTS_AND_LIMITS.md` to match
5. Restart with `docker compose --profile <profile> up -d`

### Volume Management

**All persistent data stored under `data/` directory:**

- `data/traefik` - Traefik config and certificates
- `data/n8n` - Workflow data and credentials
- `data/redis` - Redis persistence dump
- `data/postgresql` - Database cluster
- `data/qdrant` - Vector storage
- `data/meilisearch` - Search indexes
- `data/minio` - Object storage
- `data/grafana` - Dashboards and panels
- `data/prometheus` - Metrics time-series
- `data/loki` - Log chunks
- `data/tailscale` - VPN state and keys

**Backup before volume deletion:**

1. Stop service: `docker compose --profile <profile> down`
2. Backup volume: `docker run --rm -v samwise_<volume>:/data -v $(pwd):/backup alpine tar czf /backup/<volume>-backup.tar.gz /data`
3. Verify backup exists
4. Only then delete volume

### Network Constraints

**Two networks defined:**

1. `samwise-ingress` (172.20.0.0/16)
   - External access via Traefik
   - Exposes ports 80, 443, 8080

2. `samwise-internal` (172.21.0.0/16)
   - Service-to-service communication only
   - No external access
   - Internal network isolation

**Firewall rules MUST precede service start:**

- Block unauthorized ports
- Rate-limit external access
- VPN-only for sensitive services

### Configuration Validation

**Validate compose.yaml syntax:**

```bash
docker compose config
```

**Validate environment variables:**

```bash
docker compose config | grep "warning"
```

**Dry-run service start:**

```bash
docker compose --profile <profile> config --no-interpolate
```

### Health Check Verification

**After service start, verify health:**

```bash
# Check all services
docker compose ps

# Check specific service health
docker inspect samwise-redis --format='{{.State.Health.Status}}'
```

**Wait for healthy status before proceeding:**

```bash
# Loop until healthy (or timeout)
timeout 60 bash -c 'until docker inspect samwise-n8n --format="{{.State.Health.Status}}" | grep healthy; do sleep 2; done'
```

### Security Rules

1. **NEVER commit `.env` files** - use `.env.example` as template
2. **Rotate credentials quarterly** - update `.env` and restart services
3. **Use secrets management** - avoid plaintext passwords in compose.yaml
4. **Scan images regularly** - `docker scan <image>`
5. **Update base images** - monthly security patches
6. **Limit container capabilities** - no `--privileged` mode
7. **Run as non-root** - where supported by image
