# Emergency Brake Specification

## Purpose
**DEFINITIVE** specification of immediate execution halt mechanism with override authority.

**PRINCIPLE:** When Emergency Brake is activated, ALL execution stops IMMEDIATELY. No debate, no confirmation, no rollback logic. Brake overrides everything.

---

## Emergency Brake Overview

**The Emergency Brake is an absolute STOP mechanism:**

> **When Emergency Brake is activated:**
> **1. ALL execution stops IMMEDIATELY**
> **2. No new operations can start**
> **3. Ongoing operations are terminated**
> **4. No debate, no confirmation, no rollback logic**
> **5. Brake overrides ALL other authorizations**
>
> **Only Emergency Breaker can activate brake.**
> **Only Emergency Breaker can clear brake after investigation.**

**Analogy:** Emergency stop button in industrial machinery. Red button, pressed in crisis, machine stops instantly, requires manual reset.

---

## Emergency Brake Activation

### Who Can Activate

**Only Emergency Breaker role can activate emergency brake:**

- ✅ Emergency Breaker: CAN activate brake at any time, for any reason
- ❌ Repository Owner: CANNOT activate brake (unless also Emergency Breaker)
- ❌ Technical Authority: CANNOT activate brake (unless also Emergency Breaker)
- ❌ Execution Approver: CANNOT activate brake (unless also Emergency Breaker)
- ❌ Repository Maintainer: CANNOT activate brake (unless also Emergency Breaker)

**Why only Emergency Breaker?**
- Prevents brake activation for petty reasons
- Prevents brake activation as a veto mechanism
- Ensures brake is used only for genuine emergencies
- Creates clear accountability: one role, one responsibility

---

### When to Activate

**Emergency Brake MUST be activated for these conditions:**

#### Condition 1: CRITICAL_FAILURE

**Detection:**
- Database corruption detected
- Schema validation failure during execution
- Authority model violation detected during execution
- Adapter contract violation detected during execution
- Data loss detected (unexpected deletion or modification)

**Example:**
```
ERROR: run_records table missing primary key constraint
CRITICAL: Schema drift detected during migration execution
ACTION: Activate Emergency Brake immediately
```

#### Condition 2: SECURITY_BREACH

**Detection:**
- Service_role usage detected in application code
- Unauthorized access detected (unknown IP, unknown user)
- SQL injection detected
- Authentication bypass detected
- Audit log tampering detected

**Example:**
```
ALERT: service_role key detected in .env file
CRITICAL: Service_role quarantine violation
ACTION: Activate Emergency Brake immediately
```

#### Condition 3: DATA_CORRUPTION

**Detection:**
- Unexpected data in append-only tables (deletions, modifications)
- Check constraint violations during execution
- Foreign key constraint violations
- Data integrity checks failing

**Example:**
```
ERROR: audit_log table contains deleted rows
CRITICAL: Append-only invariant violated
ACTION: Activate Emergency Brake immediately
```

#### Condition 4: UNEXPECTED_BEHAVIOR

**Detection:**
- Tools executing without ToolSpec
- Adapters invoking without approval
- Runtime behavior not matching specifications
- Unexpected side effects detected

**Example:**
```
WARNING: Adapter invoked without execution unlock approval
CRITICAL: Execution boundary violation
ACTION: Activate Emergency Brake immediately
```

#### Condition 5: OTHER

**Detection:**
- Any condition not covered above that Emergency Breaker believes requires immediate halt
- Human judgment call

**Example:**
```
OBSERVATION: System behavior does not match expectations
CONCERN: Potential undetected issue
ACTION: Emergency Breaker may activate brake (human judgment)
```

---

### How to Activate

**Step 1: Create Emergency Brake Artifact**

**File:** `.authorization/emergency-brake-[timestamp].json`

**Content:**
```json
{
  "artifact_type": "EMERGENCY_BRAKE",
  "version": "1.0.0",
  "emergency_breaker": {
    "role": "Emergency Brake",
    "pgp_key_id": "ABCDEF1234567890",
    "identity": "emergency-breaker@example.com"
  },
  "timestamp": "2025-12-27T15:30:00Z",
  "brake_reason": {
    "category": "CRITICAL_FAILURE",
    "description": "Schema drift detected during migration execution",
    "details": "run_records table missing primary key constraint after migration execution. Expected 10 tables, found 9 tables. Migration failed mid-execution."
  },
  "immediate_actions_taken": [
    "All ongoing tool executions terminated",
    "All adapter invocations halted",
    "All n8n workflows paused",
    "Database connection closed",
    "Execution state locked to EXECUTION_HALTED"
  ],
  "investigation_plan": [
    "Review migration execution logs",
    "Verify database schema state",
    "Identify missing table or constraint",
    "Determine root cause of migration failure",
    "Plan recovery or rollback strategy"
  ],
  "execution_state_before_brake": "EXECUTION_ENABLED",
  "execution_state_after_brake": "EXECUTION_HALTED",
  "signature": "PGP-SIGNATURE-BASE64-ENCODED"
}
```

**Step 2: Sign Artifact with PGP Key**

```bash
# Create artifact file
cat > .authorization/emergency-brake-$(date +%Y%m%d%H%M%S).json <<'EOF'
{
  ... artifact content ...
}
EOF

# Sign artifact with PGP key
gpg --default-key <EMERGENCY_BREAKER_KEY_ID> \
    --armor \
    --detach-sign \
    .authorization/emergency-brake-$(date +%Y%m%d%H%M%S).json

# Verify signature
gpg --verify .authorization/emergency-brake-$(date +%Y%m%d%H%M%S).json.asc \
              .authorization/emergency-brake-$(date +%Y%m%d%H%M%S).json
```

**Step 3: Update Execution State File**

```bash
# Lock execution state to EXECUTION_HALTED
cat > .authorization/execution-state <<'EOF'
status: EXECUTION_HALTED
timestamp: 2025-12-27T15:30:00Z
emergency_brake_artifact: .authorization/emergency-brake-20251227153000.json
emergency_brake_reason: CRITICAL_FAILURE - Schema drift detected during migration execution
emergency_breaker_pgp_key_id: ABCDEF1234567890
previous_state: EXECUTION_ENABLED
brake_active: true
EOF
```

**Step 4: Update Authorization Log**

```bash
# Append to authorization log
cat >> .authorization/CHANGE_AUTHORIZATION_LOG.md <<'EOF'

## 2025-12-27T15:30:00Z - EMERGENCY_BRAKE_ACTIVATED

**Emergency Breaker:** emergency-breaker@example.com (ABCDEF1234567890)
**Action:** Emergency Brake activated
**Brake Reason:** CRITICAL_FAILURE - Schema drift detected during migration execution
**Details:** run_records table missing primary key constraint after migration execution. Expected 10 tables, found 9 tables. Migration failed mid-execution.
**Immediate Actions Taken:**
  - All ongoing tool executions terminated
  - All adapter invocations halted
  - All n8n workflows paused
  - Database connection closed
  - Execution state locked to EXECUTION_HALTED
**Investigation Plan:**
  - Review migration execution logs
  - Verify database schema state
  - Identify missing table or constraint
  - Determine root cause of migration failure
  - Plan recovery or rollback strategy
**Signature:** PGP-SIGNATURE-FROM-EMERGENCY-BRAKER
**Previous State:** EXECUTION_ENABLED
**Current State:** EXECUTION_HALTED
**Brake Active:** YES
EOF
```

**Step 5: Commit Artifacts**

```bash
# Stage and commit emergency brake artifacts
git add .authorization/
git commit -m "[EMERGENCY_BRAKE] Execution halted due to CRITICAL_FAILURE

- Schema drift detected during migration execution
- Emergency Brake activated by emergency-breaker@example.com
- All execution halted immediately
- Execution state locked to EXECUTION_HALTED
- Investigation pending"

# Push to remote (if network available)
git push origin main
```

---

## Emergency Brake Behavior

### Immediate Halt

**When Emergency Brake is activated, these actions occur IMMEDIATELY:**

1. **All Tool Executions Terminated:**
   - Ongoing tool executions receive SIGTERM
   - No new tool executions can start
   - ToolForge rejects all execution requests

2. **All Adapter Invocations Halted:**
   - Ongoing adapter calls are cancelled
   - No new adapter calls can start
   - Adapters return "EMERGENCY_BRAKE_ACTIVE" error

3. **All n8n Workflows Paused:**
   - Active workflow executions are stopped
   - New workflow executions are blocked
   - n8n triggers are disabled

4. **Database Connection Closed:**
   - All Supabase connections are terminated
   - No new connections can be opened
   - Database queries return "EMERGENCY_BRAKE_ACTIVE" error

5. **Execution State Locked:**
   - `.authorization/execution-state` set to `EXECUTION_HALTED`
   - Brake active flag set to `true`
   - No state transitions allowed until brake cleared

6. **All Runtime Operations Blocked:**
   - Docker containers cannot start (except emergency access)
   - No migration execution can proceed
   - No validation gates can run
   - No drift detection can run (unless for investigation)

**No Confirmations, No Debate, No Rollback Logic:**

- Emergency Brake does NOT ask for confirmation
- Emergency Brake does NOT present options
- Emergency Brake does NOT execute rollback logic (rollback is manual, post-brake)
- Emergency Brake does NOT preserve state (state may be inconsistent, that's the point)

---

### Override Authority

**Emergency Brake overrides ALL other authorizations:**

1. **Overrides Execution Unlock:**
   - Even if execution unlock artifact exists and is valid
   - Even if both Key 1 and Key 2 approved
   - Even if all prechecks PASS
   - Emergency Brake takes precedence

2. **Overrides Prechecks:**
   - Even if all 8 prechecks PASS
   - Even if drift detection PASS
   - Emergency Brake takes precedence

3. **Overrides CI Guardrails:**
   - Even if CI guardrails all PASS
   - Even if all approval tokens present
   - Emergency Brake takes precedence

4. **Overrides Repository Owner:**
   - Even Repository Owner cannot override Emergency Brake
   - Only Emergency Breaker can clear brake
   - Even Emergency Breaker cannot override their own brake (must clear properly)

**Emergency Brake is absolute. Nothing overrides it.**

---

## Emergency Brake Clearing

### Who Can Clear

**Only Emergency Breaker can clear emergency brake:**

- ✅ Emergency Breaker: CAN clear brake after investigation
- ❌ Repository Owner: CANNOT clear brake (unless also Emergency Breaker)
- ❌ Technical Authority: CANNOT clear brake (unless also Emergency Breaker)
- ❌ Execution Approver: CANNOT clear brake (unless also Emergency Breaker)
- ❌ Repository Maintainer: CANNOT clear brake (unless also Emergency Breaker)

**Why only Emergency Breaker?**
- Ensures brake is cleared only after investigation
- Prevents premature brake clearing
- Creates clear accountability: same role that activated must clear

---

### When to Clear

**Emergency Brake MUST be cleared ONLY after:**

1. **Root Cause Identified:**
   - [ ] Investigation completed
   - [ ] Root cause of emergency condition identified
   - [ ] Scope of impact understood

2. **Fix or Rollback Planned:**
   - [ ] Fix strategy documented (if fixable)
   - [ ] Rollback strategy documented (if not fixable)
   - [ ] Strategy tested (if possible)

3. **Preventive Measures Defined:**
   - [ ] Measures to prevent recurrence defined
   - [ ] Changes to processes or safeguards documented
   - [ ] Authorization model updated if needed

4. **Stakeholders Informed:**
   - [ ] All stakeholders notified of brake activation
   - [ ] All stakeholders notified of resolution plan
   - [ ] All stakeholders agree to resume execution

**Emergency Brake CANNOT be cleared if:**

- ❌ Root cause not identified
- ❌ Fix or rollback not planned
- ❌ Preventive measures not defined
- ❌ Stakeholders not informed
- ❌ Emergency condition still ongoing

---

### How to Clear

**Step 1: Create Emergency Brake Clear Artifact**

**File:** `.authorization/emergency-brake-clear-[timestamp].json`

**Content:**
```json
{
  "artifact_type": "EMERGENCY_BRAKE_CLEAR",
  "version": "1.0.0",
  "emergency_breaker": {
    "role": "Emergency Brake",
    "pgp_key_id": "ABCDEF1234567890",
    "identity": "emergency-breaker@example.com"
  },
  "timestamp": "2025-12-27T18:00:00Z",
  "original_emergency_brake_artifact": ".authorization/emergency-brake-20251227153000.json",
  "investigation_summary": {
    "root_cause": "Migration execution failed due to timeout. One table creation command timed out after 30 seconds, leaving schema in incomplete state.",
    "impact_scope": "1 table missing (run_records). No data corruption. No security breach.",
    "investigation_duration_hours": 2.5,
    "investigation_artifacts": [
      ".authorization/investigation-logs-20251227.txt",
      ".authorization/database-state-20251227.json"
    ]
  },
  "resolution_plan": {
    "strategy": "ROLLBACK_AND_RETRY",
    "steps": [
      "Rollback incomplete migration using documented rollback commands",
      "Verify schema is clean (all 4 migrations NOT applied)",
      "Increase migration timeout to 60 seconds",
      "Re-run migration execution with new timeout",
      "Verify all 10 tables created successfully"
    ],
    "rollback_commands_documented": true,
    "rollback_tested": true
  },
  "preventive_measures": {
    "measures_defined": [
      "Increase migration timeout to 60 seconds in migration files",
      "Add pre-execution timeout check to prechecks",
      "Add migration timeout to execution unlock conditions"
    ],
    "authorization_model_updated": false,
    "process_changes_documented": true
  },
  "stakeholders_informed": [
    "Repository Owner notified",
    "Technical Authority notified",
    "Execution Approver notified"
  ],
  "execution_state_before_clear": "EXECUTION_HALTED",
  "execution_state_after_clear": "EXECUTION_ENABLED",
  "signature": "PGP-SIGNATURE-BASE64-ENCODED"
}
```

**Step 2: Sign Artifact with PGP Key**

```bash
# Create artifact file
cat > .authorization/emergency-brake-clear-$(date +%Y%m%d%H%M%S).json <<'EOF'
{
  ... artifact content ...
}
EOF

# Sign artifact with PGP key
gpg --default-key <EMERGENCY_BREAKER_KEY_ID> \
    --armor \
    --detach-sign \
    .authorization/emergency-brake-clear-$(date +%Y%m%d%H%M%S).json

# Verify signature
gpg --verify .authorization/emergency-brake-clear-$(date +%Y%m%d%H%M%S).json.asc \
              .authorization/emergency-brake-clear-$(date +%Y%m%d%H%M%S).json
```

**Step 3: Update Execution State File**

```bash
# Unlock execution state (back to previous state or EXECUTION_ENABLED)
cat > .authorization/execution-state <<'EOF'
status: EXECUTION_ENABLED
timestamp: 2025-12-27T18:00:00Z
emergency_brake_artifact: .authorization/emergency-brake-20251227153000.json
emergency_brake_clear_artifact: .authorization/emergency-brake-clear-20251227180000.json
emergency_brake_reason: CRITICAL_FAILURE - Schema drift detected (CLEARED)
emergency_breaker_pgp_key_id: ABCDEF1234567890
brake_active: false
brake_duration_hours: 2.5
resolution_strategy: ROLLBACK_AND_RETRY
EOF
```

**Step 4: Update Authorization Log**

```bash
# Append to authorization log
cat >> .authorization/CHANGE_AUTHORIZATION_LOG.md <<'EOF'

## 2025-12-27T18:00:00Z - EMERGENCY_BRAKE_CLEARED

**Emergency Breaker:** emergency-breaker@example.com (ABCDEF1234567890)
**Action:** Emergency Brake cleared
**Original Brake Artifact:** .authorization/emergency-brake-20251227153000.json
**Investigation Summary:**
  - Root Cause: Migration execution failed due to timeout
  - Impact Scope: 1 table missing (run_records). No data corruption. No security breach
  - Investigation Duration: 2.5 hours
  - Investigation Artifacts: .authorization/investigation-logs-20251227.txt
**Resolution Plan:**
  - Strategy: ROLLBACK_AND_RETRY
  - Steps: Rollback incomplete migration, verify schema clean, increase timeout, re-run migration
  - Rollback Commands Documented: YES
  - Rollback Tested: YES
**Preventive Measures:**
  - Increase migration timeout to 60 seconds
  - Add pre-execution timeout check to prechecks
  - Add migration timeout to execution unlock conditions
**Stakeholders Informed:**
  - Repository Owner: YES
  - Technical Authority: YES
  - Execution Approver: YES
**Signature:** PGP-SIGNATURE-FROM-EMERGENCY-BREAKER
**Previous State:** EXECUTION_HALTED
**Current State:** EXECUTION_ENABLED
**Brake Active:** NO
**Brake Duration:** 2.5 hours
EOF
```

**Step 5: Commit Artifacts**

```bash
# Stage and commit emergency brake clear artifacts
git add .authorization/
git commit -m "[EMERGENCY_BRAKE_CLEAR] Execution resumed after investigation

- Root cause identified: Migration timeout
- Resolution plan: Rollback and retry with increased timeout
- Preventive measures defined: Timeout increased, checks added
- Stakeholders informed: All notified
- Execution state returned to EXECUTION_ENABLED"

# Push to remote (if network available)
git push origin main
```

---

## False-Positive Handling

### What is a False Positive?

**False Positive:** Emergency Brake activated for a condition that is not actually critical.

**Examples:**
- Misinterpreted log message (not actually an error)
- Temporary network issue (self-corrected)
- Human misunderstanding (system working correctly)
- Test data anomaly (not real issue)

---

### False Positive Indicators

**Investigation may reveal false positive if:**

1. **No Root Cause Found:**
   - Investigation finds no actual problem
   - System state is consistent and correct
   - No anomalies detected

2. **Misinterpretation:**
   - Log message was warning, not error
   - Condition was expected, not anomalous
   - Human misunderstood system behavior

3. **Self-Corrected:**
   - Issue resolved itself before brake
   - Transient condition no longer present
   - No action needed

---

### False Positive Response

**If investigation reveals false positive:**

1. **Document False Positive:**
   - Create false-positive determination artifact
   - Explain why brake activation was false positive
   - Document what was learned

2. **Clear Brake:**
   - Follow normal brake clearing process
   - Mark as false positive in authorization log
   - Return execution to previous state

3. **Prevent Future False Positives:**
   - Update monitoring to avoid misinterpretation
   - Add documentation to clarify ambiguous conditions
   - Train Emergency Breaker on system behavior

**False Positive Determination Artifact:**

```json
{
  "artifact_type": "FALSE_POSITIVE_DETERMINATION",
  "version": "1.0.0",
  "emergency_breaker": {
    "role": "Emergency Brake",
    "pgp_key_id": "ABCDEF1234567890",
    "identity": "emergency-breaker@example.com"
  },
  "timestamp": "2025-12-27T17:00:00Z",
  "original_emergency_brake_artifact": ".authorization/emergency-brake-20251227153000.json",
  "false_positive_determination": {
    "was_brake_justified": false,
    "why_brake_was_activated": "Misinterpreted log message as error",
    "why_it_was_false_positive": "Log message was expected warning, not critical error",
    "what_was_learned": "System logs have both warnings and errors. Need better distinction.",
    "preventive_measures": [
      "Update Emergency Breaker training on log message interpretation",
      "Add log message severity indicators",
      "Document expected warning messages"
    ]
  },
  "signature": "PGP-SIGNATURE-BASE64-ENCODED"
}
```

**False Positives Are OK:**

- Emergency Brake is designed to be over-cautious
- Better to activate brake for false positive than to not activate for real emergency
- False positives are learning opportunities, not failures
- No blame or shame for false positive activations

---

## Emergency Brake Testing

### Regular Testing

**Emergency Brake mechanism should be tested regularly:**

**Frequency:** Quarterly (every 3 months)

**Test Procedure:**

1. **Simulate Emergency Condition:**
   - Create test condition that triggers brake
   - Do NOT use real emergency (use test mode)

2. **Activate Brake:**
   - Emergency Breaker creates brake artifact
   - Verify execution state changes to EXECUTION_HALTED
   - Verify all operations blocked

3. **Investigate:**
   - Simulate investigation process
   - Document root cause (test condition)
   - Plan resolution (clear brake)

4. **Clear Brake:**
   - Emergency Breaker creates clear artifact
   - Verify execution state returns to EXECUTION_ENABLED
   - Verify operations resume

5. **Document Test:**
   - Create test report artifact
   - Log test in authorization log
   - Update procedures if needed

**Test Report Artifact:**

```json
{
  "artifact_type": "EMERGENCY_BRAKE_TEST",
  "version": "1.0.0",
  "timestamp": "2025-12-27T12:00:00Z",
  "test_type": "QUARTERLY_TEST",
  "emergency_breaker": {
    "role": "Emergency Brake",
    "pgp_key_id": "ABCDEF1234567890",
    "identity": "emergency-breaker@example.com"
  },
  "test_conditions": {
    "simulated_emergency": "Test condition - not real emergency",
    "brake_activation_successful": true,
    "execution_state_changed_to_halting": true,
    "all_operations_blocked": true,
    "brake_clearing_successful": true,
    "execution_state_returned_to_enabled": true,
    "operations_resumed": true
  },
  "test_result": "PASS",
  "issues_found": [],
  "recommendations": [],
  "signature": "PGP-SIGNATURE-BASE64-ENCODED"
}
```

---

## Summary

**Emergency Brake Defined:** Absolute halt mechanism with override authority
**Activation:** Only Emergency Breaker, for 5 conditions (CRITICAL_FAILURE, SECURITY_BREACH, DATA_CORRUPTION, UNEXPECTED_BEHAVIOR, OTHER)
**Behavior:** Immediate halt of all execution, no confirmations, no debate, no rollback logic
**Override Authority:** Overrides all other authorizations (execution unlock, prechecks, CI, Repository Owner)
**Clearing:** Only Emergency Breaker, after investigation, fix/rollback plan, preventive measures, stakeholder notification
**False Positives:** OK, document as learning opportunity, no blame
**Testing:** Quarterly testing of brake activation and clearing

**Key Guarantees:**
- Emergency Brake is absolute (overrides everything)
- Emergency Brake is immediate (no confirmations, no debate)
- Emergency Brake is single-role (only Emergency Breaker can activate/clear)
- Emergency Brake is investigable (all activations logged)
- Emergency Brake is testable (quarterly tests required)
- Emergency Brake is reversible (can be cleared after investigation)

**Emergency Brake makes catastrophic failures survivable and provides absolute control in crisis.**
