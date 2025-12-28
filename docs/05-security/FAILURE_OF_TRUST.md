# Failure of Trust

## Purpose
**DEFINITIVE** specification of system protections that work even when the operator is untrustworthy.

**PRINCIPLE:** Assume the operator will make bad decisions. Design safeguards that work anyway.

---

## The Failure of Trust Assumption

**Traditional Model (Trust-Based):**

> "The operator is knowledgeable, careful, and well-intentioned. We can trust them to follow procedures, read warnings, and make good decisions."

**Samwise Model (Trust-Minimized):**

> "The operator is tired, rushed, emotional, or reckless. They will ignore warnings, bypass safeguards, and make bad decisions. The system must protect itself anyway."

**This document assumes:**

1. ❌ The operator does NOT read documentation
2. ❌ The operator does NOT understand the system
3. ❌ The operator ignores warnings
4. ❌ The operator bypasses safeguards
5. ❌ The operator is tired or stressed
6. ❌ The operator is emotional (fear, greed, anger)
7. ❌ The operator has conflicts of interest
8. ❌ The operator makes bad decisions

**And the system must STILL be safe.**

---

## Protection 1: Prechecks Cannot Be Bypassed

### Failure Scenario: Operator Skips Prechecks

**What the operator does:**
- Operator is in a hurry
- Operator wants to unlock execution NOW
- Operator skips running prechecks
- Operator claims "all prechecks PASS" without verification

**How the system protects itself:**

**Technical Authority Artifact Requires Precheck Results:**
```json
{
  "artifact_type": "TECHNICAL_READINESS",
  "precheck_results": {
    "precheck_1_file_integrity": "PASS",  // Must be explicit
    "precheck_2_environment": "PASS",     // Must be explicit
    "precheck_3_schema_drift": "PASS",    // Must be explicit
    // ... all 8 prechecks must be listed
  }
}
```

**Verification Script Checks Precheck Artifacts:**
```bash
# Verify precheck artifacts exist
if [ ! -f .authorization/precheck-results-*.json ]; then
  echo "❌ FAIL: Precheck results not found"
  echo "   You cannot claim prechecks PASS without running them."
  exit 1
fi

# Verify all 8 prechecks show PASS
jq '.precheck_results.overall_result' .authorization/precheck-results-*.json
# Must return "ALL_PASS"
# Cannot be manually edited (PGP signature verification)
```

**Two-Person Rule Prevents Self-Verification:**
- Technical Authority must run prechecks
- Execution Approver must independently verify
- Same person cannot do both
- Prevents "I claim prechecks PASS" without verification

**Protection Works Even If:**
- ✅ Operator is tired (prechecks must be run and signed)
- ✅ Operator is in a hurry (verification takes time, cannot be skipped)
- ✅ Operator doesn't read documentation (precheck scripts are automated)
- ✅ Operator lies about precheck results (second person verifies independently)

---

## Protection 2: Drift Detection Cannot Be Ignored

### Failure Scenario: Operator Ignores Drift Detection

**What the operator does:**
- Drift detection shows FAIL
- Operator says "it's probably fine, just a small drift"
- Operator proceeds with execution anyway
- Operator claims "drift is acceptable"

**How the system protects itself:**

**Drift Detection FAIL = Automatic Rejection:**
```bash
# Run drift detection
bash scripts/detect-schema-drift.sh
# Exit code 0 = PASS (no drift)
# Exit code 1 = FAIL (drift detected)

# If FAIL, execution unlock CANNOT proceed
if [ $? -ne 0 ]; then
  echo "❌ CRITICAL: Schema drift detected"
  echo "   Execution unlock FORBIDDEN when drift detected."
  echo "   Fix drift or revert to known good state."
  exit 1
fi
```

**No "Acceptable Drift" Exception:**
- Drift is binary: PASS or FAIL
- No "minor drift" exception
- No "drift is acceptable" override
- Drift detected = automatic halt

**Technical Authority Verdict Must Be READY:**
```json
{
  "technical_readiness_verdict": "READY_FOR_EXECUTION_UNLOCK"  // or "NOT_READY"
}
```

**If drift detected:**
- Technical Authority MUST set verdict to "NOT_READY"
- Execution Approver CANNOT approve if verdict is "NOT_READY"
- Two-key rule blocks unlock (Key 1 rejected)

**Protection Works Even If:**
- ✅ Operator says "it's probably fine" (system rejects anyway)
- ✅ Operator says "just a small drift" (no exception mechanism)
- ✅ Operator proceeds anyway (verification blocks unlock)
- ✅ Operator doesn't understand drift (automated detection)

---

## Protection 3: Two-Person Rule Cannot Be Circumvented

### Failure Scenario: Operator Tries Single-Person Approval

**What the operator does:**
- Operator holds both Technical Authority and Execution Approver roles
- Operator approves execution unlock with both keys
- Operator says "I'm qualified for both roles"

**How the system protects itself:**

**PGP Key IDs Must Be Different:**
```bash
KEY1_ID=$(jq '.key_1_technical_readiness.pgp_key_id' .authorization/execution-unlock-*.json -r)
KEY2_ID=$(jq '.key_2_human_intent.pgp_key_id' .authorization/execution-unlock-*.json -r)

if [ "$KEY1_ID" = "$KEY2_ID" ]; then
  echo "❌ CRITICAL: TWO-KEY RULE VIOLATION"
  echo "   Same person cannot hold both keys."
  echo "   You cannot approve your own execution unlock."
  exit 1
fi
```

**Role Definitions Prohibit Conflicts:**
- OPERATOR_AUTHORIZATION_MODEL.md explicitly states:
  - "Execution Approver + Technical Authority (for same execution phase) = FORBIDDEN"
  - "Same person CANNOT hold both keys for the same approval"

**Repository Owner Must Verify Roles:**
- Before granting roles, Repository Owner checks for conflicts
- Repository Owner does NOT grant both roles to same person
- If both roles already held, Repository Owner revokes one

**Protection Works Even If:**
- ✅ Operator says "I'm qualified for both" (roles prohibit conflicts)
- ✅ Operator holds both roles (Repository Owner revokes)
- ✅ Operator tries to self-approve (PGP key IDs must differ)
- ✅ Operator doesn't understand two-person rule (automated verification)

---

## Protection 4: Service_Role Quarantine Cannot Be Bypassed

### Failure Scenario: Operator Uses Service_Role for Convenience

**What the operator does:**
- Operator is tired of RLS policies blocking access
- Operator sets SUPABASE_SERVICE_KEY in .env
- Operator says "I just need to query this data, it's fine"

**How the system protects itself:**

**Precheck 2 Detects SUPABASE_SERVICE_KEY:**
```bash
# Check SUPABASE_SERVICE_KEY is NOT set
if grep -q "^SUPABASE_SERVICE_KEY=" .env; then
  if [ -n "$(grep "^SUPABASE_SERVICE_KEY=" .env | cut -d'=' -f2)" ]; then
    echo "❌ CRITICAL: SUPABASE_SERVICE_KEY is set"
    echo "   Service_role key is FORBIDDEN in application code."
    echo "   Service_role bypasses RLS and creates security vulnerabilities."
    exit 1
  fi
fi
```

**AUTHORITY_ASSERTIONS.md Explicitly Forbids Service_Role:**
- "🚫 MUST NEVER be used in application code"
- "🚫 MUST NEVER be used in adapter operations"
- "🚫 MUST NEVER be used in ToolForge workflows"

**CI Guardrail Blocks Service_Role Usage:**
- CI_GUARDRAILS_DESIGN.md Guardrail 5: Service_Role Quarantine Enforcement
- If SUPABASE_SERVICE_KEY detected → CRITICAL → BLOCK MERGE

**Drift Detection Detects Service_Role References:**
```sql
-- Authority Drift Rule 4: Service_Role Violation Detection
SELECT
    schemaname,
    tablename,
    grantee,
    privilege_type
FROM pg_grants
WHERE grantee = 'service_role'
  AND schemaname = 'public';
-- If ANY rows returned → FAIL → HALT
```

**Protection Works Even If:**
- ✅ Operator sets SUPABASE_SERVICE_KEY (precheck detects and blocks)
- ✅ Operator says "it's just for querying" (no exception mechanism)
- ✅ Operator doesn't understand RLS (automated detection)
- ✅ Operator bypasses .env check (drift detection detects grants)

---

## Protection 5: Emergency Brake Cannot Be Overridden

### Failure Scenario: Operator Tries to Override Emergency Brake

**What the operator does:**
- Emergency Breaker activates brake
- Operator says "it's just a false alarm, let's proceed"
- Operator tries to continue execution despite active brake

**How the system protects itself:**

**Execution State Locked to EXECUTION_HALTED:**
```bash
# Check execution state
STATE=$(jq '.status' .authorization/execution-state -r)

if [ "$STATE" = "EXECUTION_HALTED" ]; then
  echo "❌ CRITICAL: EXECUTION_HALTED"
  echo "   Emergency Brake is active."
  echo "   All execution is blocked until brake is cleared."
  exit 1
fi
```

**All Runtime Operations Check Brake Status:**
- Before any operation, check if brake is active
- If active, reject operation immediately
- No override mechanism, no confirmation dialog

**Only Emergency Breaker Can Clear Brake:**
- EMERGENCY_BRAKE_SPEC.md explicitly states:
  - "Only Emergency Breaker can clear brake after investigation"
  - "No other role can override Emergency Brake"

**Brake Clearing Requires Investigation:**
- Root cause must be identified
- Fix or rollback plan must be documented
- Preventive measures must be defined
- Stakeholders must be informed

**Protection Works Even If:**
- ✅ Operator says "it's just a false alarm" (brake still blocks)
- ✅ Operator tries to proceed (runtime checks reject)
- ✅ Operator doesn't understand brake (only Emergency Breaker can clear)
- ✅ Operator is Repository Owner (cannot override brake)

---

## Protection 6: Append-Only Tables Cannot Be Modified

### Failure Scenario: Operator Tries to Delete Incriminating Records

**What the operator does:**
- Operator makes a mistake
- Operator wants to hide the mistake
- Operator tries to delete run_records or audit_log entries
- Operator says "I'll just clean up this error"

**How the system protects itself:**

**No DELETE Grants on Append-Only Tables:**
```sql
-- From 004_roles_rls.sql
-- internal_system role has NO DELETE grants on append-only tables
-- GRANT DELETE is NOT granted for:
--   - run_records
--   - audit_log
--   - validation_log
--   - adapter_events
--   - execution_stats
```

**RLS Policies Prevent Deletes:**
```sql
-- Even if internal_system had DELETE grants
-- RLS policies would prevent deletions
CREATE POLICY "no_delete_run_records" ON run_records
  FOR DELETE
  TO internal_system
  USING (false);  -- Always deny
```

**AUTHORITY_ASSERTIONS.md Explicitly Prohibits Deletes:**
- "❌ MUST NOT DELETE from run_records (append-only audit trail)"
- "❌ MUST NOT DELETE from audit_log (strictly append-only)"

**Drift Detection Detects DELETE Grants:**
```sql
-- Authority Drift Rule: Check for unexpected DELETE grants
SELECT
    table_name,
    grantee,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_name IN ('run_records', 'audit_log', 'validation_log')
  AND privilege_type = 'DELETE';
-- If ANY rows returned → FAIL → HALT
```

**Protection Works Even If:**
- ✅ Operator tries DELETE FROM run_records (permission denied)
- ✅ Operator grants DELETE permission (drift detection detects)
- ✅ Operator bypasses RLS (no DELETE grants at database level)
- ✅ Operator doesn't understand append-only (automated prevention)

---

## Protection 7: Protected Files Cannot Be Silently Modified

### Failure Scenario: Operator Silently Changes Schema

**What the operator does:**
- Operator wants to add a new column
- Operator modifies DDL_DRAFT.sql
- Operator commits change without approval token
- Operator hopes nobody notices

**How the system protects itself:**

**CI Guardrail Blocks Protected File Changes:**
```bash
# CI Guardrail 1: Schema File Protection
git diff --name-only origin/main...HEAD | grep -E '^supabase/schema/'
# If any files changed → check commit message for approval token

if ! git log -1 --pretty=%B | grep -q "\[SCHEMA-APPROVED\]"; then
  echo "❌ CI GUARDRAIL FAIL: Schema file changed without approval"
  echo "   Commit message must contain [SCHEMA-APPROVED] or [APPROVED-STEP12]"
  echo "   Blocked merge. Fix commit message and re-push."
  exit 1
fi
```

**Git History Reveals All Changes:**
- Every commit is logged
- Every change is attributed
- No silent modifications possible

**Drift Detection Detects Schema Changes:**
```sql
-- Schema Drift Rule 1: Table Existence Verification
-- Compare DDL_DRAFT.sql tables to actual database tables
-- If mismatch → FAIL → HALT
```

**Two-Person Rule Requires Separate Approval:**
- Repository Maintainer modifies file
- Separate reviewer must approve
- Same person cannot self-approve

**Protection Works Even If:**
- ✅ Operator modifies file silently (CI guardrail blocks merge)
- ✅ Operator commits without token (CI guardrail blocks)
- ✅ Operator doesn't understand approval process (CI enforces)
- ✅ Operator tries to bypass CI (drift detection catches schema change)

---

## Protection 8: Execution Unlock Cannot Be Granted Without Dual Approval

### Failure Scenario: Operator Tries to Self-Approve Execution

**What the operator does:**
- Operator is the only person available
- Operator says "I'll approve both keys myself"
- Operator forges second signature

**How the system protects itself:**

**PGP Signatures Cannot Be Forged:**
- PGP private key is required to sign
- Private key is protected by passphrase
- Forging signature requires private key (impossible without key)

**Key Signing Web of Trust:**
- Authorized roles sign each other's keys
- Creates trust chain: "I verify this key belongs to this person"
- Forged key is not in web of trust
- Signature verification fails

**Repository Owner Verifies Key Ownership:**
- Before granting role, Repository Owner verifies PGP key
- Key signing ceremony: prove key ownership in person
- Prevents "I'll generate a fake key for myself"

**Authorization Log References Artifacts:**
```markdown
**Signatures:**
  - Technical Authority (0123456789ABCDEF): VALID
  - Execution Approver (FEDCBA9876543210): VALID
  - Two-Person Rule: SATISFIED (different PGP keys)
```

**Verification Script Checks Artifacts Exist:**
```bash
# Verify technical readiness artifact exists and is signed
if [ ! -f .authorization/technical-readiness-*.json ]; then
  echo "❌ FAIL: Technical readiness artifact not found"
  exit 1
fi

if ! gpg --verify .authorization/technical-readiness-*.json.asc 2>/dev/null; then
  echo "❌ FAIL: Technical readiness signature invalid"
  exit 1
fi
```

**Protection Works Even If:**
- ✅ Operator tries to self-approve (PGP keys must differ)
- ✅ Operator forges signature (impossible without private key)
- ✅ Operator generates fake key (not in web of trust)
- ✅ Operator doesn't understand PGP (verification blocks)

---

## Protection 9: Precheck Execution Order Cannot Be Changed

### Failure Scenario: Operator Reorders Prechecks

**What the operator does:**
- Operator wants to skip Precheck 1 (file integrity)
- Operator says "I'll just run Precheck 2 first"
- Operator changes precheck execution order

**How the system protects itself:**

**EXECUTION_PRECHECK_SPEC.md Defines Fixed Order:**
- Prechecks MUST be executed in order 1-8
- No reordering allowed
- No skipping allowed

**Automated Precheck Script Enforces Order:**
```bash
#!/bin/bash
# run-all-prechecks.sh

# Precheck 1 MUST run first
bash scripts/precheck-1-file-integrity.sh
if [ $? -ne 0 ]; then
  echo "❌ Precheck 1 FAIL"
  echo "   Halting subsequent prechecks."
  exit 1
fi

# Precheck 2 runs ONLY after Precheck 1 PASS
bash scripts/precheck-2-environment.sh
if [ $? -ne 0 ]; then
  echo "❌ Precheck 2 FAIL"
  echo "   Halting subsequent prechecks."
  exit 1
fi

# ... and so on for all 8 prechecks
```

**Stop Condition: Any FAIL Halts Subsequent Checks:**
- EXECUTION_PRECHECK_SPEC.md explicitly states:
  - "Any precheck FAIL → HALT immediately"
  - "Do not execute subsequent prechecks"

**Technical Readiness Artifact Requires All 8 Prechecks:**
```json
{
  "precheck_results": {
    "precheck_1_file_integrity": "PASS",
    "precheck_2_environment": "PASS",
    "precheck_3_schema_drift": "PASS",
    "precheck_4_authority_drift": "PASS",
    "precheck_5_adapter_contract": "PASS",
    "precheck_6_validation_gates": "PASS",
    "precheck_7_migration_plan": "PASS",
    "precheck_8_audit_infrastructure": "PASS"
  }
}
```

**Protection Works Even If:**
- ✅ Operator reorders prechecks (script enforces order)
- ✅ Operator skips precheck (script requires all 8)
- ✅ Operator modifies script (artifact verification fails)
- ✅ Operator doesn't understand order (automated enforcement)

---

## Protection 10: Rollback Plan Cannot Be Skipped

### Failure Scenario: Operator Says "Rollback is Not Needed"

**What the operator does:**
- Operator is confident execution will succeed
- Operator says "we don't need a rollback plan"
- Operator skips rollback testing

**How the system protects itself:**

**Precheck 7: Migration Plan Verification:**
- "Rollback Strategy: Rollback commands documented" → MUST be true
- "Rollback commands tested" → MUST be true
- If either is false → Precheck 7 FAIL → HALT

**Migration Files Require Rollback Strategy:**
```sql
-- From 001_tables.sql
-- Rollback Strategy:
-- DROP TABLE IF EXISTS tools CASCADE;
-- DROP TABLE IF EXISTS tool_versions CASCADE;
-- ... (rollback commands documented)
```

**Technical Readiness Verification Includes Rollback:**
```json
{
  "rollback_plan_verification": {
    "rollback_plan_documented": true,  // Must be true
    "rollback_tested": true,            // Must be true
    "rollback_time_seconds": 180,       // Must be measured
    "overall_result": "PASS"            // Only PASS if above are true
  }
}
```

**Execution Approver Must Verify Rollback:**
- Execution Approver spot-checks rollback plan
- Execution Approver verifies rollback was tested
- Execution Approver CANNOT approve if rollback not tested

**Protection Works Even If:**
- ✅ Operator says "rollback not needed" (precheck requires documented rollback)
- ✅ Operator skips testing (precheck requires tested rollback)
- ✅ Operator confident of success (no exception mechanism)
- ✅ Operator doesn't understand rollback (precheck enforces)

---

## Summary: Trust-Minimized Design

**Protections Defined:** 10 layers of safeguards that work even when operator is untrustworthy

**Key Principle:**
> **The system protects itself from the operator.**
> **Assume the operator is tired, rushed, emotional, or reckless.**
> **Design safeguards that work anyway.**

**How It Works:**

1. **Automated Verification:**
   - Prechecks run automatically
   - Drift detection runs automatically
   - Scripts enforce rules
   - No manual bypass

2. **Two-Person Rule:**
   - No single actor can approve execution
   - Independent verification required
   - Conflicts of interest detected and blocked

3. **Cryptographic Proofs:**
   - PGP signatures prevent forgery
   - Web of trust prevents impersonation
   - Artifacts cannot be tampered with

4. **Append-Only Logs:**
   - All actions logged permanently
   - No deletions, no modifications
   - Complete audit trail

5. **Absolute Stops:**
   - Emergency Brake cannot be overridden
   - Drift detection cannot be ignored
   - Service_role quarantine cannot be bypassed

6. **Explicit Prohibitions:**
   - No implicit permissions
   - No "it's probably fine" exceptions
   - No "just this once" bypasses

**The Result:**
- System is safe even when operator is not
- System is correct even when operator makes mistakes
- System is secure even when operator is reckless

**This is GOVERNANCE WITHOUT TRUST.**
