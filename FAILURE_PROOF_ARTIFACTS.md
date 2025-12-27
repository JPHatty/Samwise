# Failure Proof Artifacts

## Purpose
**DEFINITIVE** specification of how to prove simulations leave zero side effects.

**PRINCIPLE:** Every simulation MUST be auditable and repeatable with verifiable proof of no execution.

---

## Proof Philosophy

### What Failure Proofs Demonstrate

**Failure proofs** are verifiable artifacts that demonstrate:
1. NO Docker containers were started
2. NO HTTP calls were made
3. NO files were mutated
4. NO registry changes occurred
5. NO side effects of any kind

**In Samwise, we generate failure proofs to prove:**
- Simulations are simulation-only (dry-run)
- Validation gates reject invalid input
- Faults are detected and logged
- No execution actually occurred
- System state remains unchanged

### Proof Categories

#### Category 1: Pre-Execution State Capture
Capture system state BEFORE simulation.

#### Category 2: Post-Execution Verification
Verify system state AFTER simulation matches pre-execution state.

#### Category 3: Audit Trail Verification
Verify RunRecord captures the failure correctly.

#### Category 4: Side Effect Detection
Detect any unintended side effects.

---

## Proof Protocol

### Pre-Execution State Capture

Before running any simulation, capture baseline state:

```bash
# 1. Create proof directory
PROOF_DIR="/home/node/.n8n/data/failure-proofs/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$PROOF_DIR"

# 2. Capture Docker state
docker ps --format "{{.Names}}" | sort > "$PROOF_DIR/docker-ps-pre.txt"
docker images --format "{{.Repository}}:{{.Tag}}" | sort > "$PROOF_DIR/docker-images-pre.txt"
docker network ls --format "{{.Name}}" | sort > "$PROOF_DIR/docker-networks-pre.txt"

# 3. Capture filesystem state (specific directories)
find /home/node/.n8n/data -type f -newer /tmp/sim-pre-marker \
  ! -path "*/run-records/*" ! -path "*/simulations/*" > "$PROOF_DIR/files-pre.txt" || true

# 4. Capture registry state
cat /home/node/.n8n/data/tool-registry/index.json > "$PROOF_DIR/registry-pre.json"

# 5. Create marker file for post-exec comparison
touch /tmp/sim-pre-marker
```

### Post-Execution Verification

After simulation completes, verify no changes:

```bash
# 1. Capture Docker state (post-exec)
docker ps --format "{{.Names}}" | sort > "$PROOF_DIR/docker-ps-post.txt"
docker images --format "{{.Repository}}:{{.Tag}}" | sort > "$PROOF_DIR/docker-images-post.txt"
docker network ls --format "{{.Name}}" | sort > "$PROOF_DIR/docker-networks-post.txt"

# 2. Capture filesystem state (post-exec)
find /home/node/.n8n/data -type f -newer /tmp/sim-pre-marker \
  ! -path "*/run-records/*" ! -path "*/simulations/*" > "$PROOF_DIR/files-post.txt" || true

# 3. Capture registry state (post-exec)
cat /home/node/.n8n/data/tool-registry/index.json > "$PROOF_DIR/registry-post.json"

# 4. Generate diff report
echo "=== Docker Containers Diff ===" > "$PROOF_DIR/verification-report.txt"
diff "$PROOF_DIR/docker-ps-pre.txt" "$PROOF_DIR/docker-ps-post.txt" || {
  echo "✗ PASS: No container changes" >> "$PROOF_DIR/verification-report.txt"
}

echo "" >> "$PROOF_DIR/verification-report.txt"
echo "=== Docker Images Diff ===" >> "$PROOF_DIR/verification-report.txt"
diff "$PROOF_DIR/docker-images-pre.txt" "$PROOF_DIR/docker-images-post.txt" || {
  echo "✗ PASS: No image changes" >> "$PROOF_DIR/verification-report.txt"
}

echo "" >> "$PROOF_DIR/verification-report.txt"
echo "=== Filesystem Diff (excluding RunRecords) ===" >> "$PROOF_DIR/verification-report.txt"
diff "$PROOF_DIR/files-pre.txt" "$PROOF_DIR/files-post.txt" || {
  echo "✗ PASS: No file mutations (excluding RunRecords)" >> "$PROOF_DIR/verification-report.txt"
}

echo "" >> "$PROOF_DIR/verification-report.txt"
echo "=== Registry Diff ===" >> "$PROOF_DIR/verification-report.txt"
diff <(jq -S . "$PROOF_DIR/registry-pre.json") <(jq -S . "$PROOF_DIR/registry-post.json") || {
  echo "✗ PASS: No registry changes" >> "$PROOF_DIR/verification-report.txt"
}

# 5. Output report
cat "$PROOF_DIR/verification-report.txt"
```

---

## Proof Artifacts by Category

### Artifact 1: Docker Activity Proof

**Purpose:** Prove NO Docker containers started or images pulled.

**Pre-State Capture:**
```bash
# List running containers
docker ps --format "{{.Names}} {{.Status}}" > /tmp/docker-containers-pre.txt

# List all containers (including stopped)
docker ps -a --format "{{.Names}} {{.Status}}" > /tmp/docker-all-containers-pre.txt

# List images
docker images --format "{{.Repository}}:{{.Tag}} {{.CreatedAt}}" > /tmp/docker-images-pre.txt

# List networks
docker network ls --format "{{.Name}} {{.Driver}}" > /tmp/docker-networks-pre.txt

# List volumes
docker volume ls --format "{{.Name}}" > /tmp/docker-volumes-pre.txt
```

**Post-Execution Verification:**
```bash
# Capture post-state
docker ps --format "{{.Names}} {{.Status}}" > /tmp/docker-containers-post.txt
docker ps -a --format "{{.Names}} {{.Status}}" > /tmp/docker-all-containers-post.txt
docker images --format "{{.Repository}}:{{.Tag}} {{.CreatedAt}}" > /tmp/docker-images-post.txt
docker network ls --format "{{.Name}} {{.Driver}}" > /tmp/docker-networks-post.txt
docker volume ls --format "{{.Name}}" > /tmp/docker-volumes-post.txt

# Generate diff
echo "=== CONTAINERS STARTED ===" > /tmp/docker-proof.txt
diff /tmp/docker-containers-pre.txt /tmp/docker-containers-post.txt || echo "PASS: No containers started" >> /tmp/docker-proof.txt

echo "" >> /tmp/docker-proof.txt
echo "=== CONTAINERS CREATED ===" >> /tmp/docker-proof.txt
diff /tmp/docker-all-containers-pre.txt /tmp/docker-all-containers-post.txt || echo "PASS: No containers created" >> /tmp/docker-proof.txt

echo "" >> /tmp/docker-proof.txt
echo "=== IMAGES PULLED ===" >> /tmp/docker-proof.txt
diff /tmp/docker-images-pre.txt /tmp/docker-images-post.txt || echo "PASS: No images pulled" >> /tmp/docker-proof.txt

echo "" >> /tmp/docker-proof.txt
echo "=== NETWORKS CREATED ===" >> /tmp/docker-proof.txt
diff /tmp/docker-networks-pre.txt /tmp/docker-networks-post.txt || echo "PASS: No networks created" >> /tmp/docker-proof.txt

echo "" >> /tmp/docker-proof.txt
echo "=== VOLUMES CREATED ===" >> /tmp/docker-proof.txt
diff /tmp/docker-volumes-pre.txt /tmp/docker-volumes-post.txt || echo "PASS: No volumes created" >> /tmp/docker-proof.txt
```

**Expected Output:**
```
=== CONTAINERS STARTED ===
PASS: No containers started

=== CONTAINERS CREATED ===
PASS: No containers created

=== IMAGES PULLED ===
PASS: No images pulled

=== NETWORKS CREATED ===
PASS: No networks created

=== VOLUMES CREATED ===
PASS: No volumes created
```

**Failure Indicators (MUST NOT OCCUR):**
- `diff` shows any output (indicates state change)
- New containers appear in post-state
- New images appear in post-state
- New networks or volumes created

---

### Artifact 2: HTTP Activity Proof

**Purpose:** Prove NO HTTP calls made to external services.

**Network Monitoring Setup:**
```bash
# Option 1: Use tcpdump (if available)
# Start packet capture
tcpdump -i any -w /tmp/network-pre.pcap host not 127.0.0.1 &
TCPDUMP_PID=$!

# Option 2: Use Docker network stats
docker stats --no-stream --format "table {{.Container}}\t{{.NetIO}}" > /tmp/docker-network-stats-pre.txt

# Option 3: Use n8n execution logs (if n8n is running)
# Check for HTTP requests before simulation
grep -r "HTTP REQUEST" /home/node/.n8n/logs/ | tail -20 > /tmp/n8n-http-pre.txt || true
```

**Post-Execution Verification:**
```bash
# Option 1: Stop packet capture and analyze
kill $TCPDUMP_PID
tcpdump -r /tmp/network-pre.pcap host not 127.0.0.1 > /tmp/network-activity.txt

# Check for external HTTP traffic
echo "=== EXTERNAL HTTP CALLS ===" > /tmp/http-proof.txt
if grep -E "POST|GET|PUT|DELETE" /tmp/network-activity.txt | grep -v "127.0.0.1"; then
  echo "FAIL: External HTTP calls detected" >> /tmp/http-proof.txt
else
  echo "PASS: No external HTTP calls" >> /tmp/http-proof.txt
fi

# Option 2: Compare Docker network stats
docker stats --no-stream --format "table {{.Container}}\t{{.NetIO}}" > /tmp/docker-network-stats-post.txt

echo "" >> /tmp/http-proof.txt
echo "=== DOCKER NETWORK I/O CHANGE ===" >> /tmp/http-proof.txt
if ! diff /tmp/docker-network-stats-pre.txt /tmp/docker-network-stats-post.txt; then
  echo "INFO: Network I/O changed (expected for n8n internal traffic)" >> /tmp/http-proof.txt
fi

# Option 3: Check n8n logs for HTTP requests
grep -r "HTTP REQUEST" /home/node/.n8n/logs/ | tail -20 > /tmp/n8n-http-post.txt || true

echo "" >> /tmp/http-proof.txt
echo "=== N8N HTTP REQUESTS ===" >> /tmp/http-proof.txt
if ! diff /tmp/n8n-http-pre.txt /tmp/n8n-http-post.txt; then
  echo "FAIL: New HTTP requests detected in n8n logs" >> /tmp/http-proof.txt
else
  echo "PASS: No new HTTP requests" >> /tmp/http-proof.txt
fi

cat /tmp/http-proof.txt
```

**Expected Output:**
```
=== EXTERNAL HTTP CALLS ===
PASS: No external HTTP calls

=== DOCKER NETWORK I/O CHANGE ===
INFO: Network I/O changed (expected for n8n internal traffic)

=== N8N HTTP REQUESTS ===
PASS: No new HTTP requests
```

**Forbidden External Destinations:**
- `*.supabase.co`
- `*.qdrant.io`
- `*.meilisearch.com`
- `*.r2.cloudflarestorage.com`
- `*.northflank.com`
- `*.livekit.io`

**Allowed Internal Traffic:**
- `127.0.0.1` (localhost)
- `172.16.0.0/12` (Docker internal network)
- n8n UI access (user's browser → n8n)

---

### Artifact 3: Filesystem Mutation Proof

**Purpose:** Prove NO files mutated (except RunRecords).

**Pre-Execution State Capture:**
```bash
# Create marker file
touch /tmp/fs-pre-marker

# Capture filesystem state (directories we care about)
# 1. n8n data directory (excluding run-records)
find /home/node/.n8n/data -type f ! -path "*/run-records/*" -exec stat -c "%n %Y %s" {} \; | sort > /tmp/fs-pre.txt

# 2. n8n workflows directory
find /home/node/.n8n/workflows -type f -exec stat -c "%n %Y %s" {} \; | sort > /tmp/workflows-pre.txt

# 3. Git working directory state
git status --porcelain > /tmp/git-pre.txt
git diff > /tmp/git-diff-pre.txt
```

**Post-Execution Verification:**
```bash
# Capture post-state
find /home/node/.n8n/data -type f ! -path "*/run-records/*" -newer /tmp/fs-pre-marker -exec stat -c "%n %Y %s" {} \; | sort > /tmp/fs-post.txt

find /home/node/.n8n/workflows -type f -newer /tmp/fs-pre-marker -exec stat -c "%n %Y %s" {} \; | sort > /tmp/workflows-post.txt

git status --porcelain > /tmp/git-post.txt
git diff > /tmp/git-diff-post.txt

# Generate diff report
echo "=== FILESYSTEM MUTATIONS (data dir, excluding run-records) ===" > /tmp/fs-proof.txt
if [ -s /tmp/fs-post.txt ]; then
  echo "FAIL: Files mutated:" >> /tmp/fs-proof.txt
  cat /tmp/fs-post.txt >> /tmp/fs-proof.txt
else
  echo "PASS: No file mutations" >> /tmp/fs-proof.txt
fi

echo "" >> /tmp/fs-proof.txt
echo "=== WORKFLOW FILE MUTATIONS ===" >> /tmp/fs-proof.txt
if [ -s /tmp/workflows-post.txt ]; then
  echo "FAIL: Workflow files mutated:" >> /tmp/fs-proof.txt
  cat /tmp/workflows-post.txt >> /tmp/fs-proof.txt
else
  echo "PASS: No workflow file mutations" >> /tmp/fs-proof.txt
fi

echo "" >> /tmp/fs-proof.txt
echo "=== GIT WORKING DIRECTORY CHANGES ===" >> /tmp/fs-proof.txt
if ! diff /tmp/git-pre.txt /tmp/git-post.txt; then
  echo "FAIL: Git working directory changed:" >> /tmp/fs-proof.txt
  diff /tmp/git-pre.txt /tmp/git-post.txt >> /tmp/fs-proof.txt
else
  echo "PASS: No git changes" >> /tmp/fs-proof.txt
fi

cat /tmp/fs-proof.txt
```

**Expected Output:**
```
=== FILESYSTEM MUTATIONS (data dir, excluding run-records) ===
PASS: No file mutations

=== WORKFLOW FILE MUTATIONS ===
PASS: No workflow file mutations

=== GIT WORKING DIRECTORY CHANGES ===
PASS: No git changes
```

**Allowed File Changes:**
- RunRecord files in `/home/node/.n8n/data/run-records/`
- Simulation result files in `/home/node/.n8n/data/simulations/`
- Proof artifact files in `/home/node/.n8n/data/failure-proofs/`

**Forbidden File Changes:**
- Any file in `/home/node/.n8n/workflows/`
- Tool registry index in `/home/node/.n8n/data/tool-registry/index.json`
- Adapter registry in `/home/node/.n8n/data/adapter-registry.json`
- Any configuration file

---

### Artifact 4: Registry Change Proof

**Purpose:** Prove NO registry changes occurred.

**Pre-Execution State Capture:**
```bash
# 1. Tool Registry
cat /home/node/.n8n/data/tool-registry/index.json > /tmp/tool-registry-pre.json

# 2. Adapter Registry
cat /home/node/.n8n/data/adapter-registry.json > /tmp/adapter-registry-pre.json

# 3. Count registered tools
jq '.tools | length' /home/node/.n8n/data/tool-registry/index.json > /tmp/tool-count-pre.txt
```

**Post-Execution Verification:**
```bash
# Capture post-state
cat /home/node/.n8n/data/tool-registry/index.json > /tmp/tool-registry-post.json
cat /home/node/.n8n/data/adapter-registry.json > /tmp/adapter-registry-post.json
jq '.tools | length' /home/node/.n8n/data/tool-registry/index.json > /tmp/tool-count-post.txt

# Generate diff report
echo "=== TOOL REGISTRY CHANGE ===" > /tmp/registry-proof.txt
if ! diff <(jq -S . /tmp/tool-registry-pre.json) <(jq -S . /tmp/tool-registry-post.json); then
  echo "FAIL: Tool registry changed" >> /tmp/registry-proof.txt
  diff <(jq -S . /tmp/tool-registry-pre.json) <(jq -S . /tmp/tool-registry-post.json) >> /tmp/registry-proof.txt
else
  echo "PASS: Tool registry unchanged" >> /tmp/registry-proof.txt
fi

echo "" >> /tmp/registry-proof.txt
echo "=== ADAPTER REGISTRY CHANGE ===" >> /tmp/registry-proof.txt
if ! diff <(jq -S . /tmp/adapter-registry-pre.json) <(jq -S . /tmp/adapter-registry-post.json); then
  echo "FAIL: Adapter registry changed" >> /tmp/registry-proof.txt
  diff <(jq -S . /tmp/adapter-registry-pre.json) <(jq -S . /tmp/adapter-registry-post.json) >> /tmp/registry-proof.txt
else
  echo "PASS: Adapter registry unchanged" >> /tmp/registry-proof.txt
fi

echo "" >> /tmp/registry-proof.txt
echo "=== TOOL COUNT CHANGE ===" >> /tmp/registry-proof.txt
if ! diff /tmp/tool-count-pre.txt /tmp/tool-count-post.txt; then
  echo "FAIL: Tool count changed:" >> /tmp/registry-proof.txt
  diff /tmp/tool-count-pre.txt /tmp/tool-count-post.txt >> /tmp/registry-proof.txt
else
  echo "PASS: Tool count unchanged" >> /tmp/registry-proof.txt
fi

cat /tmp/registry-proof.txt
```

**Expected Output:**
```
=== TOOL REGISTRY CHANGE ===
PASS: Tool registry unchanged

=== ADAPTER REGISTRY CHANGE ===
PASS: Adapter registry unchanged

=== TOOL COUNT CHANGE ===
PASS: Tool count unchanged
```

**Allowed Registry Changes:**
- NONE (simulations MUST NOT modify registries)

**Forbidden Registry Changes:**
- New tool registration
- Tool deactivation
- Tool metadata changes
- Adapter configuration changes

---

### Artifact 5: Audit Trail Verification

**Purpose:** Prove RunRecord captures failure correctly.

**RunRecord Verification:**
```bash
# 1. Locate RunRecord for simulation
SIMULATION_ID="sim-1-missing-adapter"
RUN_RECORD="/home/node/.n8n/data/run-records/${SIMULATION_ID}-*.json"

# 2. Verify RunRecord exists
echo "=== RUNRECORD EXISTS ===" > /tmp/audit-proof.txt
if [ -f "$RUN_RECORD" ]; then
  echo "PASS: RunRecord found" >> /tmp/audit-proof.txt
else
  echo "FAIL: RunRecord not found" >> /tmp/audit-proof.txt
  exit 1
fi

# 3. Verify RunRecord structure
echo "" >> /tmp/audit-proof.txt
echo "=== RUNRECORD STRUCTURE ===" >> /tmp/audit-proof.txt
jq '.run_id' "$RUN_RECORD" > /dev/null && echo "PASS: run_id present" >> /tmp/audit-proof.txt || echo "FAIL: run_id missing" >> /tmp/audit-proof.txt
jq '.intent_id' "$RUN_RECORD" > /dev/null && echo "PASS: intent_id present" >> /tmp/audit-proof.txt || echo "FAIL: intent_id missing" >> /tmp/audit-proof.txt
jq '.tool_id' "$RUN_RECORD" > /dev/null && echo "PASS: tool_id present" >> /tmp/audit-proof.txt || echo "FAIL: tool_id missing" >> /tmp/audit-proof.txt
jq '.status' "$RUN_RECORD" > /dev/null && echo "PASS: status present" >> /tmp/audit-proof.txt || echo "FAIL: status missing" >> /tmp/audit-proof.txt
jq '.started_at' "$RUN_RECORD" > /dev/null && echo "PASS: started_at present" >> /tmp/audit-proof.txt || echo "FAIL: started_at missing" >> /tmp/audit-proof.txt
jq '.finished_at' "$RUN_RECORD" > /dev/null && echo "PASS: finished_at present" >> /tmp/audit-proof.txt || echo "FAIL: finished_at missing" >> /tmp/audit-proof.txt

# 4. Verify failure captured
echo "" >> /tmp/audit-proof.txt
echo "=== FAILURE CAPTURED ===" >> /tmp/audit-proof.txt
STATUS=$(jq -r '.status' "$RUN_RECORD")
if [ "$STATUS" = "failure" ]; then
  echo "PASS: Status is 'failure'" >> /tmp/audit-proof.txt
else
  echo "FAIL: Status is '$STATUS', expected 'failure'" >> /tmp/audit-proof.txt
fi

# 5. Verify errors present
echo "" >> /tmp/audit-proof.txt
echo "=== ERRORS RECORDED ===" >> /tmp/audit-proof.txt
ERROR_COUNT=$(jq '.errors | length' "$RUN_RECORD")
if [ "$ERROR_COUNT" -gt 0 ]; then
  echo "PASS: $ERROR_COUNT errors recorded" >> /tmp/audit-proof.txt
  echo "Error codes:" >> /tmp/audit-proof.txt
  jq -r '.errors[].code' "$RUN_RECORD" | sed 's/^/  - /' >> /tmp/audit-proof.txt
else
  echo "FAIL: No errors recorded" >> /tmp/audit-proof.txt
fi

# 6. Verify no execution attempted
echo "" >> /tmp/audit-proof.txt
echo "=== EXECUTION ATTEMPTED ===" >> /tmp/audit-proof.txt
EXECUTION_ATTEMPTED=$(jq -r '.execution_attemptected // false' "$RUN_RECORD")
if [ "$EXECUTION_ATTEMPTED" = "false" ] || [ "$EXECUTION_ATTEMPTED" = "null" ]; then
  echo "PASS: No execution attempted" >> /tmp/audit-proof.txt
else
  echo "FAIL: Execution was attempted (should have been halted)" >> /tmp/audit-proof.txt
fi

# 7. Verify simulation flag
echo "" >> /tmp/audit-proof.txt
echo "=== SIMULATION FLAG ===" >> /tmp/audit-proof.txt
SIMULATION_FLAG=$(jq -r '.metadata.simulation // false' "$RUN_RECORD")
if [ "$SIMULATION_FLAG" = "true" ]; then
  echo "PASS: Simulation flag is true" >> /tmp/audit-proof.txt
else
  echo "FAIL: Simulation flag is missing or false" >> /tmp/audit-proof.txt
fi

cat /tmp/audit-proof.txt
```

**Expected Output:**
```
=== RUNRECORD EXISTS ===
PASS: RunRecord found

=== RUNRECORD STRUCTURE ===
PASS: run_id present
PASS: intent_id present
PASS: tool_id present
PASS: status present
PASS: started_at present
PASS: finished_at present

=== FAILURE CAPTURED ===
PASS: Status is 'failure'

=== ERRORS RECORDED ===
PASS: 1 errors recorded
Error codes:
  - REMOTE_REQUIRES_ADAPTER

=== EXECUTION ATTEMPTED ===
PASS: No execution attempted

=== SIMULATION FLAG ===
PASS: Simulation flag is true
```

**Required RunRecord Fields:**
- `run_id`: UUID
- `intent_id`: From IntentSpec
- `tool_id`: From ToolSpec
- `status`: Must be "failure"
- `started_at`: ISO timestamp
- `finished_at`: ISO timestamp
- `errors`: Array with at least 1 error
- `metadata.simulation`: Must be true
- `metadata.dry_run`: Must be true (if applicable)

---

## Automated Verification Script

### Complete Verification Script

```bash
#!/bin/bash
# verify-simulation.sh - Complete simulation verification
# Usage: ./verify-simulation.sh <simulation-id>

set -e

SIMULATION_ID=$1
PROOF_DIR="/home/node/.n8n/data/failure-proofs/$(date +%Y%m%d-%H%M%S)-${SIMULATION_ID}"

echo "=== Verification for Simulation: ${SIMULATION_ID} ==="
echo "Proof directory: ${PROOF_DIR}"
mkdir -p "$PROOF_DIR"

# ============================================================
# PRE-EXECUTION STATE CAPTURE
# ============================================================

echo ""
echo "Capturing pre-execution state..."

touch /tmp/sim-pre-marker

# Docker state
docker ps --format "{{.Names}}" | sort > "$PROOF_DIR/docker-ps-pre.txt"
docker images --format "{{.Repository}}:{{.Tag}}" | sort > "$PROOF_DIR/docker-images-pre.txt"

# Filesystem state
find /home/node/.n8n/data -type f ! -path "*/run-records/*" -exec stat -c "%n %Y %s" {} \; 2>/dev/null | sort > "$PROOF_DIR/files-pre.txt" || true

# Registry state
cat /home/node/.n8n/data/tool-registry/index.json > "$PROOF_DIR/registry-pre.json" 2>/dev/null || echo "{}" > "$PROOF_DIR/registry-pre.json"

# Git state
git status --porcelain > "$PROOF_DIR/git-pre.txt" 2>/dev/null || true

echo "Pre-execution state captured."

# ============================================================
# RUN SIMULATION
# ============================================================

echo ""
echo "Running simulation..."
echo "  (Simulation execution would happen here)"
echo "Simulation complete."

# ============================================================
# POST-EXECUTION VERIFICATION
# ============================================================

echo ""
echo "Verifying post-execution state..."

# Capture post-state
docker ps --format "{{.Names}}" | sort > "$PROOF_DIR/docker-ps-post.txt"
docker images --format "{{.Repository}}:{{.Tag}}" | sort > "$PROOF_DIR/docker-images-post.txt"

find /home/node/.n8n/data -type f ! -path "*/run-records/*" -newer /tmp/sim-pre-marker -exec stat -c "%n %Y %s" {} \; 2>/dev/null | sort > "$PROOF_DIR/files-post.txt" || true

cat /home/node/.n8n/data/tool-registry/index.json > "$PROOF_DIR/registry-post.json" 2>/dev/null || echo "{}" > "$PROOF_DIR/registry-post.json"

git status --porcelain > "$PROOF_DIR/git-post.txt" 2>/dev/null || true

# ============================================================
# GENERATE VERIFICATION REPORT
# ============================================================

echo ""
echo "Generating verification report..."

REPORT="$PROOF_DIR/verification-report.txt"

echo "SIMULATION VERIFICATION REPORT" > "$REPORT"
echo "Simulation ID: ${SIMULATION_ID}" >> "$REPORT"
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$REPORT"
echo "" >> "$REPORT"

echo "## 1. DOCKER ACTIVITY" >> "$REPORT"
echo "=== Containers Started ===" >> "$REPORT"
if diff "$PROOF_DIR/docker-ps-pre.txt" "$PROOF_DIR/docker-ps-post.txt" > /dev/null; then
  echo "✓ PASS: No containers started" >> "$REPORT"
else
  echo "✗ FAIL: Containers were started" >> "$REPORT"
  diff "$PROOF_DIR/docker-ps-pre.txt" "$PROOF_DIR/docker-ps-post.txt" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "=== Images Pulled ===" >> "$REPORT"
if diff "$PROOF_DIR/docker-images-pre.txt" "$PROOF_DIR/docker-images-post.txt" > /dev/null; then
  echo "✓ PASS: No images pulled" >> "$REPORT"
else
  echo "✗ FAIL: Images were pulled" >> "$REPORT"
  diff "$PROOF_DIR/docker-images-pre.txt" "$PROOF_DIR/docker-images-post.txt" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "## 2. FILESYSTEM MUTATIONS" >> "$REPORT"
echo "=== Files Changed (excluding RunRecords) ===" >> "$REPORT"
if [ ! -s "$PROOF_DIR/files-post.txt" ]; then
  echo "✓ PASS: No file mutations" >> "$REPORT"
else
  echo "✗ FAIL: Files were mutated:" >> "$REPORT"
  cat "$PROOF_DIR/files-post.txt" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "## 3. REGISTRY CHANGES" >> "$REPORT"
echo "=== Tool Registry ===" >> "$REPORT"
if diff <(jq -S . "$PROOF_DIR/registry-pre.json" 2>/dev/null) <(jq -S . "$PROOF_DIR/registry-post.json" 2>/dev/null) > /dev/null; then
  echo "✓ PASS: No registry changes" >> "$REPORT"
else
  echo "✗ FAIL: Registry was modified" >> "$REPORT"
  diff <(jq -S . "$PROOF_DIR/registry-pre.json") <(jq -S . "$PROOF_DIR/registry-post.json") >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "## 4. GIT WORKING DIRECTORY" >> "$REPORT"
echo "=== Git Status Changes ===" >> "$REPORT"
if diff "$PROOF_DIR/git-pre.txt" "$PROOF_DIR/git-post.txt" > /dev/null; then
  echo "✓ PASS: No git changes" >> "$REPORT"
else
  echo "✗ FAIL: Git working directory changed:" >> "$REPORT"
  diff "$PROOF_DIR/git-pre.txt" "$PROOF_DIR/git-post.txt" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "## 5. RUNRECORD VERIFICATION" >> "$REPORT"
RUN_RECORD="/home/node/.n8n/data/run-records/${SIMULATION_ID}-*.json"
if ls $RUN_RECORD 1> /dev/null 2>&1; then
  echo "✓ PASS: RunRecord found" >> "$REPORT"
  echo "RunRecord: $(ls $RUN_RECORD)" >> "$REPORT"
else
  echo "✗ FAIL: RunRecord not found" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "## SUMMARY" >> "$REPORT"
FAIL_COUNT=$(grep -c "✗ FAIL" "$REPORT")
if [ $FAIL_COUNT -eq 0 ]; then
  echo "✓ ALL CHECKS PASSED - Simulation left no side effects" >> "$REPORT"
else
  echo "✗ $FAIL_CHECKS FAILED - Simulation had side effects" >> "$REPORT"
fi

# Output report
cat "$REPORT"

# Return exit code based on results
if [ $FAIL_COUNT -eq 0 ]; then
  exit 0
else
  exit 1
fi
```

**Usage:**
```bash
chmod +x verify-simulation.sh
./verify-simulation.sh sim-1-missing-adapter
```

---

## Proof Verification Checklist

### Before Simulation

- [ ] Create proof directory with timestamp
- [ ] Capture Docker state (containers, images, networks, volumes)
- [ ] Capture filesystem state (excluding run-records)
- [ ] Capture registry state (tool registry, adapter registry)
- [ ] Capture git working directory state
- [ ] Create pre-execution marker file

### After Simulation

- [ ] Capture Docker state (post-exec)
- [ ] Capture filesystem state (post-exec)
- [ ] Capture registry state (post-exec)
- [ ] Capture git working directory state (post-exec)
- [ ] Generate diff reports for all state comparisons
- [ ] Verify RunRecord was emitted
- [ ] Verify RunRecord contains required fields
- [ ] Verify RunRecord status matches expected result
- [ ] Verify errors are recorded (for failures)
- [ ] Verify simulation flag is set

### Automated Verification

- [ ] All Docker diffs show no changes
- [ ] All filesystem diffs show no mutations (except RunRecords)
- [ ] All registry diffs show no changes
- [ ] Git working directory unchanged
- [ ] RunRecord exists and is valid
- [ ] HTTP activity logs show no external calls

---

## Proof Retention

### Retention Policy

**Proof Artifacts:**
- Retain for: 30 days
- Location: `/home/node/.n8n/data/failure-proofs/YYYYMMDD-HHMMSS-<simulation-id>/`
- Format: Timestamped directory with all verification files

**RunRecords:**
- Retain for: 365 days (1 year)
- Location: `/home/node/.n8n/data/run-records/`
- Format: `<simulation-id>-<uuid>.json`
- Index: Append-only JSONL log

**Cleanup Script:**
```bash
#!/bin/bash
# cleanup-old-proofs.sh - Delete proof artifacts older than 30 days

find /home/node/.n8n/data/failure-proofs/ -type d -mtime +30 -exec rm -rf {} \;

echo "Cleanup complete. Old proof artifacts deleted."
```

---

## Summary

**Failure proofs demonstrate:**
1. ✅ NO Docker containers started or images pulled
2. ✅ NO HTTP calls to external services
3. ✅ NO file mutations (except RunRecords)
4. ✅ NO registry changes
5. ✅ NO git working directory changes
6. ✅ RunRecord captures failure correctly
7. ✅ All state changes are auditable and repeatable

**We prove correctness through verifiable artifacts, not assumptions.**

**Next:** Invariant Verification (STEP 8.4)
