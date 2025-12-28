# STOP Conditions - STEP 8

## Purpose
**DEFINITIVE** specification of when STEP 8 must halt and STEP 9 is forbidden.

**PRINCIPLE:** Explicit STOP conditions prevent unsafe progression beyond simulation phase.

---

## What Are STOP Conditions?

### Definition

**STOP Condition:** An explicit, testable condition that MUST halt current progress and trigger operator intervention.

**In Samwise STEP 8, STOP conditions:**
- Are pre-defined (not discovered during execution)
- Are binary (either condition is met or not met)
- Trigger immediate halt
- Require explicit operator acknowledgement to proceed
- May forbid progression to STEP 9 entirely

### STOP Condition Categories

#### Category 1: Validation STOP Conditions
Conditions detected during validation that MUST halt execution.

#### Category 2: Simulation STOP Conditions
Conditions during simulation that MUST halt and require investigation.

#### Category 3: Invariant Violation STOP Conditions
Conditions that violate system invariants and MUST be resolved.

#### Category 4: Proof Failure STOP Conditions
Conditions where failure proofs cannot be generated or verified.

#### Category 5: Forbidden Progression Conditions
Conditions that make STEP 9 permanently forbidden.

---

## STOP Condition 1: Simulation Produces Side Effects

### Statement
**If ANY simulation produces observable side effects beyond RunRecord emission, HALT IMMEDIATELY.**

### Detection Methods

#### Detection 1.1 - Docker State Change

**Test:** Compare pre and post Docker state

```bash
# Pre-state
docker ps -a --format "{{.Names}}" > /tmp/docker-pre.txt
docker images --format "{{.Repository}}:{{.Tag}}" > /tmp/docker-images-pre.txt

# Run simulation
n8n execute-tool-simulation --intent-spec sim-1-intent.json --tool-spec sim-1-toolspec.json --simulate

# Post-state
docker ps -a --format "{{.Names}}" > /tmp/docker-post.txt
docker images --format "{{.Repository}}:{{.Tag}}" > /tmp/docker-images-post.txt

# Check for changes
if ! diff /tmp/docker-pre.txt /tmp/docker-post.txt > /dev/null; then
  echo "STOP CONDITION: Docker state changed"
  exit 1
fi

if ! diff /tmp/docker-images-pre.txt /tmp/docker-images-post.txt > /dev/null; then
  echo "STOP CONDITION: Docker images changed"
  exit 1
fi
```

**STOP Condition Triggered:**
- New containers created
- Containers started
- New images pulled
- Networks created
- Volumes created

#### Detection 1.2 - Filesystem Mutation

**Test:** Check for file mutations beyond RunRecords

```bash
touch /tmp/fs-pre-marker

# Run simulation
n8n execute-tool-simulation --simulate

# Check for new files (excluding RunRecords)
find /home/node/.n8n/data -type f -newer /tmp/fs-pre-marker \
  ! -path "*/run-records/*" ! -path "*/simulations/*" ! -path "*/failure-proofs/*" > /tmp/files-changed.txt

if [ -s /tmp/files-changed.txt ]; then
  echo "STOP CONDITION: Files mutated:"
  cat /tmp/files-changed.txt
  exit 1
fi
```

**STOP Condition Triggered:**
- Tool registry index modified
- Adapter registry modified
- Workflow files modified
- Configuration files modified
- ANY file mutation outside allowed directories

#### Detection 1.3 - HTTP Traffic

**Test:** Monitor for outbound HTTP traffic

```bash
# Start network monitoring
tcpdump -i any -w /tmp/sim-network.pcap 'not host 127.0.0.1 and not net 172.16.0.0/12' &
TCPDUMP_PID=$!

# Run simulation
n8n execute-tool-simulation --simulate

# Stop monitoring
kill $TCPDUMP_PID

# Analyze traffic
tcpdump -r /tmp/sim-network.pcap -n | grep -E "(POST|GET|PUT|DELETE)" > /tmp/http-traffic.txt

if [ -s /tmp/http-traffic.txt ]; then
  echo "STOP CONDITION: HTTP traffic detected:"
  cat /tmp/http-traffic.txt
  exit 1
fi
```

**STOP Condition Triggered:**
- ANY HTTP request to cloud service
- Outbound traffic on port 443
- Outbound traffic on port 80
- DNS lookups to cloud domains

### Required Actions When STOP Condition 1 Triggered

1. **IMMEDIATE HALT:**
   - Stop all simulations
   - Do NOT run any more tests
   - Preserve all state for investigation

2. **Investigation:**
   - Identify which side effect occurred
   - Trace the root cause
   - Determine if it's a test flaw or system flaw

3. **Resolution:**
   - Fix the root cause
   - Re-run all affected simulations
   - Re-verify STOP condition 1

4. **Documentation:**
   - Document the side effect
   - Document the resolution
   - Update test vectors if needed

**STEP 9 is FORBIDDEN until STOP condition 1 is resolved.**

---

## STOP Condition 2: Validation Gates Fail to Reject Unsafe Input

### Statement
**If ANY validation gate accepts input that should be rejected, HALT IMMEDIATELY.**

### Detection Methods

#### Detection 2.1 - Schema Validation Failure

**Test:** Submit invalid IntentSpec with schema violation

```bash
# Test vector: IntentSpec missing required field
cat > /tmp/test-invalid-intent.json << 'EOF'
{
  "intent_id": "test-invalid-1",
  // "issued_at" is MISSING
  "issuer": "human",
  "objective": "Test",
  "constraints": [],
  "forbidden_actions": [],
  "required_outputs": [],
  "validation_level": "normal",
  "rollback_required": false,
  "audit_required": false
}
EOF

# Validate
RESULT=$(curl -s -X POST http://localhost:5678/webhook/toolforge-validate-intent \
  -H "Content-Type: application/json" \
  -d @/tmp/test-invalid-intent.json | jq '.valid')

if [ "$RESULT" != "false" ]; then
  echo "STOP CONDITION: Schema validation accepted invalid input"
  exit 1
fi
```

**STOP Condition Triggered:**
- Schema validation returns `valid: true` for invalid input
- Missing required fields not detected
- Type violations not detected
- Enum violations not detected
- Additional properties not detected

#### Detection 2.2 - Validation Gate Bypass

**Test:** Submit unsafe ToolSpec that should be rejected

```bash
# Test vector: ToolSpec with REMOTE execution but no adapter_id
cat > /tmp/test-unsafe-toolspec.json << 'EOF'
{
  "tool_id": "unsafe-remote-no-adapter",
  "version": "1.0.0",
  "description": "Unsafe tool",
  "execution_mode": "remote",  // ← Requires adapter_id
  "resource_class": "compute",
  // adapter_id is MISSING
  "input_schema": { "type": "object" },
  "output_schema": { "type": "object" },
  "credentials_required": [],
  "side_effects": [],
  "rollback_strategy": "none",
  "timeout_seconds": 10
}
EOF

# Validate
RESULT=$(curl -s -X POST http://localhost:5678/webhook/toolforge-validate-toolspec \
  -H "Content-Type: application/json" \
  -d @/tmp/test-unsafe-toolspec.json | jq '.valid')

if [ "$RESULT" != "false" ]; then
  echo "STOP CONDITION: Validation gate accepted unsafe tool"
  exit 1
fi
```

**STOP Condition Triggered:**
- REMOTE tool without adapter_id accepted
- LOCAL tool with compute resource_class accepted
- LOCAL tool with cloud database access accepted
- Direct cloud URL in credentials accepted
- Invalid adapter operation accepted

#### Detection 2.3 - Boundary Violation Accepted

**Test:** Submit ToolSpec with execution boundary violation

```bash
# Test vector: LOCAL tool with all boundary violations
cat > /tmp/test-boundary-violation.json << 'EOF'
{
  "tool_id": "boundary-violation-all",
  "execution_mode": "local",
  "resource_class": "compute",  // ← Violation 1
  "adapter_id": "supabase-postgres",  // ← Violation 2
  "credentials_required": ["SUPABASE_URL"],  // ← Violation 3
  "side_effects": [{
    "effect_type": "database_write",  // ← Violation 4
    "description": "Write to cloud DB",
    "reversible": false
  }],
  "input_schema": { "type": "object" },
  "output_schema": { "type": "object" },
  "version": "1.0.0",
  "description": "All boundary violations",
  "rollback_strategy": "none",
  "timeout_seconds": 10
}
EOF

# Validate
VALID=$(curl -s -X POST http://localhost:5678/webhook/toolforge-validate-toolspec \
  -H "Content-Type: application/json" \
  -d @/tmp/test-boundary-violation.json)

RESULT=$(echo "$VALID" | jq '.valid')
ERROR_COUNT=$(echo "$VALID" | jq '.errors | length')

if [ "$RESULT" != "false" ] || [ "$ERROR_COUNT" -lt 4 ]; then
  echo "STOP CONDITION: Boundary violations not detected ($ERROR_COUNT/4 detected)"
  exit 1
fi
```

**STOP Condition Triggered:**
- Boundary violation not detected
- Only partial violations detected
- Validation passes with boundary violations

### Required Actions When STOP Condition 2 Triggered

1. **IMMEDIATE HALT:**
   - Stop all validation tests
   - Identify which validation gate failed
   - Determine the severity (schema vs. logic)

2. **Investigation:**
   - Check if Ajv is configured correctly (STRICT mode)
   - Check if validation rules are implemented
   - Check if validation logic has bugs
   - Check if validation is being bypassed

3. **Resolution:**
   - Fix validation logic
   - Add missing validation rules
   - Update schema if needed
   - Re-run all validation tests

4. **Regression Testing:**
   - Re-run all fault injection tests
   - Re-run all simulation tests
   - Verify all unsafe inputs are rejected

**STEP 9 is FORBIDDEN until STOP condition 2 is resolved.**

---

## STOP Condition 3: Adapters Invoked During Simulation

### Statement
**If ANY adapter is invoked during simulation or dry-run mode, HALT IMMEDIATELY.**

### Detection Methods

#### Detection 3.1 - Adapter Execution Logs

**Test:** Check for adapter execution logs after simulation

```bash
touch /tmp/sim-pre-marker

# Run simulation
n8n execute-tool-simulation --simulate

# Check for adapter logs
find /home/node/.n8n/logs -name "*adapter*.log" -newer /tmp/sim-pre-marker > /tmp/adapter-logs.txt

if [ -s /tmp/adapter-logs.txt ]; then
  echo "STOP CONDITION: Adapter logs found:"
  cat /tmp/adapter-logs.txt
  exit 1
fi
```

**STOP Condition Triggered:**
- Adapter initialization logs found
- Adapter execution logs found
- Adapter HTTP request logs found
- Adapter error logs found

#### Detection 3.2 - Cloud Service Access

**Test:** Monitor cloud service access logs

```bash
# Before simulation, capture access log state
# (This requires access to cloud service dashboards)

# Run simulation
n8n execute-tool-simulation --simulate

# After simulation, check for new access logs
# Supabase dashboard: Check recent requests
# Qdrant logs: Check recent access
# Meilisearch logs: Check recent queries

# If ANY new requests found, STOP
if [ new_requests_detected ]; then
  echo "STOP CONDITION: Cloud services accessed during simulation"
  exit 1
fi
```

**STOP Condition Triggered:**
- Supabase requests detected
- Qdrant requests detected
- Meilisearch requests detected
- R2 requests detected
- ANY cloud service request detected

#### Detection 3.3 - Dry-Run Mode Violation

**Test:** Verify dry-run flag is respected

```bash
# Run with --dry-run flag
n8n execute-tool-simulation \
  --intent-spec test-intent.json \
  --tool-spec test-toolspec.json \
  --dry-run \
  --simulate

# Check RunRecord for dry_run flag
DRY_RUN=$(jq -r '.dry_run' /home/node/.n8n/data/run-records/latest.json)

if [ "$DRY_RUN" != "true" ]; then
  echo "STOP CONDITION: Dry-run flag not set in RunRecord"
  exit 1
fi

# Check for HTTP traffic (should be none)
if [ -s /tmp/http-traffic.txt ]; then
  echo "STOP CONDITION: HTTP traffic during dry-run"
  exit 1
fi
```

**STOP Condition Triggered:**
- Dry-run flag missing from RunRecord
- Dry-run flag is false
- HTTP traffic during dry-run
- Adapter execution during dry-run

### Required Actions When STOP Condition 3 Triggered

1. **IMMEDIATE HALT:**
   - Stop all simulations
   - Identify which adapter was invoked
   - Determine how dry-run/simulation flags were bypassed

2. **Investigation:**
   - Check if dry-run flag is being checked
   - Check if adapter execution is conditional
   - Check if there's a code path that bypasses dry-run
   - Check if validation gates are enforcing dry-run

3. **Resolution:**
   - Fix dry-run enforcement
   - Add dry-run checks before adapter calls
   - Ensure all adapter calls are conditional
   - Re-run all simulation tests

4. **Verification:**
   - Re-run all simulations
   - Verify zero adapter invocations
   - Verify zero HTTP traffic
   - Verify all RunRecords have dry_run=true

**STEP 9 is FORBIDDEN until STOP condition 3 is resolved.**

---

## STOP Condition 4: Failure Proofs Cannot Be Generated

### Statement
**If failure proof artifacts cannot be generated or verified, HALT IMMEDIATELY.**

### Detection Methods

#### Detection 4.1 - Proof Generation Failure

**Test:** Attempt to generate failure proofs

```bash
# Run verification script
./verify-simulation.sh sim-1-missing-adapter

# Check if proof directory was created
if [ ! -d "/home/node/.n8n/data/failure-proofs/*-sim-1-missing-adapter" ]; then
  echo "STOP CONDITION: Proof directory not created"
  exit 1
fi

# Check if verification report exists
if [ ! -f "/home/node/.n8n/data/failure-proofs/*-sim-1-missing-adapter/verification-report.txt" ]; then
  echo "STOP CONDITION: Verification report not generated"
  exit 1
fi
```

**STOP Condition Triggered:**
- Proof directory not created
- Pre-state capture failed
- Post-state capture failed
- Diff report not generated
- Verification report missing

#### Detection 4.2 - Proof Verification Failure

**Test:** Verify proof shows no side effects

```bash
# Check verification report
REPORT="/home/node/.n8n/data/failure-proofs/*-sim-1-missing-adapter/verification-report.txt"

# Look for FAIL markers
if grep -q "✗ FAIL" "$REPORT"; then
  echo "STOP CONDITION: Verification report shows failures:"
  grep "✗ FAIL" "$REPORT"
  exit 1
fi

# Verify all checks passed
PASS_COUNT=$(grep -c "✓ PASS" "$REPORT" || echo "0")
if [ "$PASS_COUNT" -lt 4 ]; then
  echo "STOP CONDITION: Not all verification checks passed ($PASS_COUNT/4)"
  exit 1
fi
```

**STOP Condition Triggered:**
- Verification report shows FAIL
- Docker state changed
- Filesystem mutated
- Registry changed
- HTTP traffic detected

#### Detection 4.3 - RunRecord Not Emitted

**Test:** Verify RunRecord exists for simulation

```bash
SIMULATION_ID="sim-1-missing-adapter"
RUN_RECORD="/home/node/.n8n/data/run-records/${SIMULATION_ID}-*.json"

if ! ls $RUN_RECORD 1> /dev/null 2>&1; then
  echo "STOP CONDITION: RunRecord not found for simulation"
  exit 1
fi

# Verify RunRecord structure
jq -e '.run_id' "$RUN_RECORD" > /dev/null || {
  echo "STOP CONDITION: RunRecord missing run_id"
  exit 1
}

jq -e '.status' "$RUN_RECORD" > /dev/null || {
  echo "STOP CONDITION: RunRecord missing status"
  exit 1
}

jq -e '.errors' "$RUN_RECORD" > /dev/null || {
  echo "STOP CONDITION: RunRecord missing errors"
  exit 1
}
```

**STOP Condition Triggered:**
- RunRecord not created
- RunRecord missing required fields
- RunRecord has wrong status
- RunRecord missing error details

### Required Actions When STOP Condition 4 Triggered

1. **IMMEDIATE HALT:**
   - Stop all simulations
   - Identify which proof generation failed
   - Determine root cause

2. **Investigation:**
   - Check if verification script is executable
   - Check if required tools are available (jq, docker, tcpdump)
   - Check if file permissions are correct
   - Check if disk space is available

3. **Resolution:**
   - Fix verification script
   - Install missing tools
   - Fix permissions
   - Re-run proof generation

4. **Verification:**
   - Re-run all simulations
   - Verify all proofs generated
   - Verify all proofs pass
   - Verify all RunRecords emitted

**STEP 9 is FORBIDDEN until STOP condition 4 is resolved.**

---

## STOP Condition 5: Invariants Violated

### Statement
**If ANY system invariant is violated, HALT IMMEDIATELY.**

### Detection Methods

#### Detection 5.1 - Invariant 1 Violation

**Test:** Schemas accept invalid input

```bash
# Run invariant verification script
./verify-invariants.sh

# Check if Invariant 1 tests all pass
INV1_PASS=$(grep "Test 1:" -A 1 verify-invariants.log | grep -c "✓ PASS" || echo "0")

if [ "$INV1_PASS" -lt 3 ]; then
  echo "STOP CONDITION: Invariant 1 violated (schemas accept invalid input)"
  exit 1
fi
```

**STOP Condition Triggered:**
- Schema validation passes for invalid input
- Missing required fields not detected
- Type violations not detected
- Additional properties not detected

#### Detection 5.2 - Invariant 2 Violation

**Test:** ToolForge accepts unsafe tools

```bash
# Check Invariant 2 tests
INV2_PASS=$(grep "Test 2:" -A 1 verify-invariants.log | grep -c "✓ PASS" || echo "0")

if [ "$INV2_PASS" -lt 5 ]; then
  echo "STOP CONDITION: Invariant 2 violated (ToolForge accepts unsafe tools)"
  exit 1
fi
```

**STOP Condition Triggered:**
- REMOTE tool without adapter accepted
- LOCAL tool with compute accepted
- LOCAL tool with cloud DB access accepted
- Direct cloud URL accepted
- Invalid adapter operation accepted

#### Detection 5.3 - Invariant 3 Violation

**Test:** Adapters invoked during simulation

```bash
# Check Invariant 3 tests
INV3_PASS=$(grep "Test 3:" -A 1 verify-invariants.log | grep -c "✓ PASS" || echo "0")

if [ "$INV3_PASS" -lt 4 ]; then
  echo "STOP CONDITION: Invariant 3 violated (adapters were invoked)"
  exit 1
fi
```

**STOP Condition Triggered:**
- HTTP traffic detected
- Docker containers started
- Adapter logs found
- Cloud services accessed

#### Detection 5.4 - Invariant 4 Violation

**Test:** Boundaries violated

```bash
# Check Invariant 4 tests
INV4_PASS=$(grep "Test 4:" -A 1 verify-invariants.log | grep -c "✓ PASS" || echo "0")

if [ "$INV4_PASS" -lt 4 ]; then
  echo "STOP CONDITION: Invariant 4 violated (boundaries did not hold)"
  exit 1
fi
```

**STOP Condition Triggered:**
- Boundary violations not detected
- Boundary violations accepted
- Retry bypasses validation
- Multiple violations not all detected

### Required Actions When STOP Condition 5 Triggered

1. **IMMEDIATE HALT:**
   - Stop all tests
   - Identify which invariant violated
   - Determine severity

2. **Investigation:**
   - Review validation logic
   - Review boundary enforcement
   - Review adapter abstraction
   - Review test vectors

3. **Resolution:**
   - Fix violated invariant
   - Update validation rules
   - Update boundary checks
   - Re-run all invariant tests

4. **Regression Testing:**
   - Re-run all 16 invariant tests
   - Verify all pass
   - Document the violation and resolution

**STEP 9 is FORBIDDEN until STOP condition 5 is resolved.**

---

## STOP Condition 6: Forbidden Progression Conditions

### Statement
**Under these conditions, STEP 9 is PERMANENTLY FORBIDDEN.**

### Forbidden Progression Triggers

#### Trigger 6.1: Critical Validation Failure

**Condition:** ANY validation gate consistently fails to reject unsafe input

**Examples:**
- Schema validation accepts invalid input (3+ times)
- Validation gate accepts unsafe tools (3+ times)
- Boundary checks fail to detect violations (3+ times)

**Action:**
- STEP 9 is PERMANENTLY FORBIDDEN
- System cannot be deployed
- Complete redesign required

#### Trigger 6.2: Adapter Invocation During Simulation

**Condition:** Adapters are invoked during simulation or dry-run mode

**Examples:**
- HTTP traffic to cloud services during simulation
- Docker containers started during simulation
- Adapter execution logs found during simulation

**Action:**
- STEP 9 is PERMANENTLY FORBIDDEN
- Dry-run enforcement is broken
- Cannot guarantee safe execution

#### Trigger 6.3: Failure Proofs Cannot Be Generated

**Condition:** Failure proof artifacts cannot be generated or verified

**Examples:**
- Verification script consistently fails
- Proof generation fails 3+ times
- RunRecords not emitted for simulations

**Action:**
- STEP 9 is PERMANENTLY FORBIDDEN
- Audit trail is broken
- Cannot verify safety

#### Trigger 6.4: Multiple Invariants Violated

**Condition:** 2+ invariants violated and cannot be fixed

**Examples:**
- Invariants 1 and 2 both violated
- Invariants 3 and 4 both violated
- Any 2 invariants violated

**Action:**
- STEP 9 is PERMANENTLY FORBIDDEN
- System is fundamentally unsafe
- Complete redesign required

### Operator Intervention Required

When ANY forbidden progression trigger is met:

1. **Stop all work:**
   - Do NOT proceed to STEP 9
   - Do NOT attempt deployment
   - Do NOT bypass STOP conditions

2. **Escalate:**
   - Notify system architect
   - Document all violations
   - Request review

3. **Redesign:**
   - Reconsider validation architecture
   - Reconsider boundary enforcement
   - Reconsider adapter abstraction
   - Reconsider simulation approach

4. **Re-verify:**
   - Start from STEP 5
   - Re-implement with fixes
   - Re-run all verification tests

---

## STOP Condition Checklist

### Before Running ANY Simulation

- [ ] Pre-state capture script executed
- [ ] Docker state captured
- [ ] Filesystem state captured
- [ ] Network monitoring started
- [ ] Marker file created

### After Running ANY Simulation

- [ ] Post-state captured
- [ ] Docker state unchanged (STOP if changed)
- [ ] Filesystem unchanged (STOP if changed)
- [ ] No HTTP traffic (STOP if traffic found)
- [ ] No adapter logs (STOP if logs found)
- [ ] RunRecord emitted (STOP if missing)
- [ ] RunRecord valid (STOP if invalid)
- [ ] Failure proofs generated (STOP if failed)

### Before Proceeding to STEP 9

- [ ] All 6 simulations executed
- [ ] All 4 failures verified
- [ ] All 1 degradation verified
- [ ] All 1 dry-run pass verified
- [ ] All failure proofs generated
- [ ] All proofs verified
- [ ] All 16 invariants verified
- [ ] NO STOP conditions triggered
- [ ] NO forbidden progression conditions met

### Forbidden Progression Check

- [ ] STOP condition 1 not triggered (no side effects)
- [ ] STOP condition 2 not triggered (validation works)
- [ ] STOP condition 3 not triggered (no adapter invocation)
- [ ] STOP condition 4 not triggered (proofs generated)
- [ ] STOP condition 5 not triggered (invariants hold)
- [ ] STOP condition 6 not triggered (no forbidden conditions)

**If ANY check fails, STEP 9 is FORBIDDEN.**

---

## STOP Condition Summary

**5 STOP Conditions:**
1. Simulation produces side effects
2. Validation gates fail to reject unsafe input
3. Adapters invoked during simulation
4. Failure proofs cannot be generated
5. Invariants violated

**1 Forbidden Progression Category:**
6. Multiple STOP conditions or critical failures

**We define explicit STOP conditions to prevent unsafe progression.**

**Next:** Final Validation and Commit (STEP 8 Complete)
