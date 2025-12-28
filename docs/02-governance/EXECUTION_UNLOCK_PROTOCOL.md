# Execution Unlock Protocol

## Purpose
**DEFINITIVE** specification of steps required to transition from EXECUTION_DISABLED to EXECUTION_ENABLED.

**PRINCIPLE:** Make it intentionally annoying to unlock execution incorrectly. Impossible to skip steps. Impossible to proceed without dual approval.

---

## Current State: EXECUTION_DISABLED

**Indicators of Disabled State:**
- No migration files have been applied to Supabase
- No tables exist in Supabase database
- No roles have been created in Supabase
- No RLS policies have been applied
- Supabase project is empty (except default Supabase tables)
- All adapters are in "disabled" state
- n8n workflows are not triggered
- Docker compose services are not running (except during development)
- `.authorization/execution-state` file contains: `status: EXECUTION_DISABLED`

**What is FORBIDDEN in EXECUTION_DISABLED state:**
- ❌ No tool execution
- ❌ No adapter invocation
- ❌ No migration execution
- ❌ No Supabase writes
- ❌ No n8n workflow triggers
- ❌ No Docker container starts (except manual development)

---

## Target State: EXECUTION_ENABLED

**Indicators of Enabled State:**
- All 4 migration files have been applied to Supabase
- All 10 tables exist in Supabase database
- All 5 roles exist in Supabase
- All RLS policies are applied
- All 29 indexes exist
- All 8 constraints exist
- All adapters are in "healthy" state
- n8n workflows can be triggered
- Precheck system is operational
- Drift detection is operational
- Emergency brake is operational
- `.authorization/execution-state` file contains: `status: EXECUTION_ENABLED`
- `.authorization/execution-unlock-[timestamp].json` exists with dual signatures

**What is ALLOWED in EXECUTION_ENABLED state:**
- ✅ Tool execution (with ToolSpec validation)
- ✅ Adapter invocation (with adapter contracts)
- ✅ Supabase reads/writes (with RLS enforcement)
- ✅ n8n workflow triggers
- ✅ RunRecord emission

---

## Execution Unlock Protocol (Step-by-Step)

### Phase 0: Pre-Unlock Verification

**Purpose:** Verify all prerequisites are met before attempting unlock.

**Step 0.1: Verify Authorization Roles Exist**
- [ ] Repository Maintainer role assigned
- [ ] Execution Approver role assigned
- [ ] Technical Authority role assigned
- [ ] Emergency Breaker role assigned
- [ ] Repository Owner role assigned
- [ ] All roles have valid PGP keys published in `.pgp-keys/`
- [ ] All PGP keys are signed by at least one other authorized role

**Verification Command:**
```bash
# Check PGP keys exist
ls -la .pgp-keys/*.asc
# Should list at least 5 public keys (one per role)

# Verify key signatures
gpg --list-keys --with-colons .pgp-keys/*.asc
# Should show signature chains

# Check key expiration
gpg --list-keys --with-colons | grep "pub"
# Should show no expired keys
```

**FAIL Condition:** Any role missing or any PGP key missing/expired/unsigned.
**Action on FAIL:** HALT. Assign missing roles, generate/rotate PGP keys, establish web of trust. Re-run Phase 0.

---

**Step 0.2: Verify Protected Files are Unmodified**
- [ ] DDL_DRAFT.sql is unmodified since STEP 10 commit
- [ ] ROLES_AND_RLS.md is unmodified since STEP 10 commit
- [ ] AUTHORITY_ASSERTIONS.md is unmodified since STEP 11 commit
- [ ] ADAPTER_CONTRACTS.md is unmodified since STEP 10 commit
- [ ] All 4 migration files are unmodified since STEP 11 commit
- [ ] Git shows no modifications to STEP 10/11 files
- [ ] Working tree is clean (except STEP 12/13 files)

**Verification Command:**
```bash
# Check for modifications to STEP 10/11 files
git diff --quiet supabase/schema/ supabase/security/ supabase/adapters/ migrations/planned/
# Exit code 0 = no changes (PASS)
# Exit code 1 = changes detected (FAIL)

# Check working tree
git status --porcelain
# Should show only STEP 12/13 files
```

**FAIL Condition:** Any protected file modified.
**Action on FAIL:** HALT. Revert to STEP 10/11 state or document changes with approval tokens. Re-run Phase 0.

---

**Step 0.3: Verify Environment Configuration**
- [ ] SUPABASE_URL is set in .env
- [ ] SUPABASE_ANON_KEY is set in .env
- [ ] SUPABASE_SERVICE_KEY is unset or empty in .env
- [ ] SUPABASE_URL is valid HTTPS URL
- [ ] SUPABASE_ANON_KEY is valid JWT (starts with "eyJ")
- [ ] No other environment variables contain service_role references

**Verification Command:**
```bash
# Check SUPABASE_URL and SUPABASE_ANON_KEY are set
grep -E "^(SUPABASE_URL|SUPABASE_ANON_KEY)=" .env | wc -l
# Should return 2 (both set)

# Check SUPABASE_SERVICE_KEY is NOT set
grep -c "^SUPABASE_SERVICE_KEY=" .env || echo "0"
# Should return 0 (unset or empty)

# Validate URL format
grep "^SUPABASE_URL=https://" .env
# Should return match

# Validate JWT format
grep "^SUPABASE_ANON_KEY=eyJ" .env
# Should return match
```

**FAIL Condition:** SUPABASE_URL or SUPABASE_ANON_KEY missing/invalid, or SUPABASE_SERVICE_KEY set.
**Action on FAIL:** HALT. Fix environment configuration. Re-run Phase 0.

---

### Phase 1: Technical Readiness Verification

**Purpose:** Technical Authority verifies all technical conditions are met.

**Step 1.1: Run All 8 Prechecks**
- [ ] Precheck 1: File Integrity Verification - PASS
- [ ] Precheck 2: Environment Variable Verification - PASS
- [ ] Precheck 3: Schema Drift Detection - PASS
- [ ] Precheck 4: Authority Model Verification - PASS
- [ ] Precheck 5: Adapter Contract Verification - PASS
- [ ] Precheck 6: Validation Gates Verification - PASS
- [ ] Precheck 7: Migration Plan Verification - PASS
- [ ] Precheck 8: Audit Infrastructure Verification - PASS

**Reference:** EXECUTION_PRECHECK_SPEC.md for detailed precheck definitions.

**Verification Commands:**
```bash
# Run all prechecks (design only, not executed yet)
# Each precheck has PASS/FAIL condition defined in EXECUTION_PRECHECK_SPEC.md
# All 8 must PASS before proceeding
```

**FAIL Condition:** Any precheck FAILs.
**Action on FAIL:** HALT. Fix failed precheck. Re-run all 8 prechecks from beginning. No partial progression.

---

**Step 1.2: Run Drift Detection**
- [ ] Schema drift detection: Rule 1 (Table Existence) - PASS
- [ ] Schema drift detection: Rule 2 (Column Existence) - PASS
- [ ] Schema drift detection: Rule 3 (Foreign Key) - PASS
- [ ] Schema drift detection: Rule 4 (Index) - PASS
- [ ] Schema drift detection: Rule 5 (Constraint) - PASS
- [ ] Schema drift detection: Rule 6 (RLS Policy) - PASS
- [ ] Authority drift detection: Rule 1 (Role Existence) - PASS
- [ ] Authority drift detection: Rule 2 (Grant) - PASS
- [ ] Authority drift detection: Rule 3 (RLS Policy) - PASS
- [ ] Authority drift detection: Rule 4 (Service_Role) - PASS
- [ ] Authority drift detection: Rule 5 (Deny-First) - PASS
- [ ] Authority drift detection: Rule 6 (Privilege Escalation) - PASS

**Reference:** SCHEMA_DRIFT_GUARDS.md and AUTHORITY_DRIFT_GUARDS.md for detailed rules.

**Verification Commands:**
```bash
# Run all drift detection queries (design only, not executed yet)
# Each rule has PASS/FAIL condition defined in drift guard files
# All 12 rules must PASS before proceeding
```

**FAIL Condition:** Any drift detection FAILs.
**Action on FAIL:** HALT. Fix drift or revert to known good state. Re-run all 12 drift detection rules from beginning.

---

**Step 1.3: Verify Database Backup**
- [ ] Database backup exists
- [ ] Backup is recent (within 24 hours)
- [ ] Backup is valid (can be restored)
- [ ] Backup size is reasonable (not empty, not truncated)
- [ ] Backup stored in secure location (not in repository)

**Verification Commands:**
```bash
# Check backup file exists
ls -lh .backups/supabase-backup-*.sql
# Should show recent backup file

# Check backup is valid SQL
head -n 100 .backups/supabase-backup-*.sql | grep "PostgreSQL database dump"
# Should show PostgreSQL dump header

# Check backup size
du -h .backups/supabase-backup-*.sql
# Should show reasonable size (not 0 bytes)
```

**FAIL Condition:** Backup missing, expired, invalid, or too small.
**Action on FAIL:** HALT. Create new database backup. Verify backup validity. Re-run Phase 1.

---

**Step 1.4: Verify Rollback Plan**
- [ ] Rollback plan documented in each migration file
- [ ] Rollback commands tested on test database
- [ ] Rollback time measured (should be < 5 minutes)
- [ ] Rollback steps are clear and unambiguous
- [ ] Rollback preserves audit trail (no data loss)

**Verification Commands:**
```bash
# Check rollback plan exists in each migration
grep -l "Rollback Strategy:" migrations/planned/*.sql
# Should list all 4 migration files

# Verify rollback syntax is valid
# (Parse rollback SQL blocks for syntax errors)
```

**FAIL Condition:** Rollback plan missing, untested, or unclear.
**Action on FAIL:** HALT. Document rollback plan, test on test database, measure rollback time. Re-run Phase 1.

---

**Step 1.5: Emit Technical Readiness Artifact**

**Technical Authority creates and signs artifact:**

**File:** `.authorization/technical-readiness-[timestamp].json`

**Content:**
```json
{
  "artifact_type": "TECHNICAL_READINESS",
  "version": "1.0.0",
  "technical_authority": {
    "role": "Technical Authority",
    "pgp_key_id": "0123456789ABCDEF",
    "identity": "technical-authority@example.com"
  },
  "timestamp": "2025-12-27T10:00:00Z",
  "precheck_results": {
    "precheck_1_file_integrity": "PASS",
    "precheck_2_environment": "PASS",
    "precheck_3_schema_drift": "PASS",
    "precheck_4_authority_drift": "PASS",
    "precheck_5_adapter_contract": "PASS",
    "precheck_6_validation_gates": "PASS",
    "precheck_7_migration_plan": "PASS",
    "precheck_8_audit_infrastructure": "PASS",
    "overall_result": "ALL_PASS"
  },
  "drift_detection_results": {
    "schema_drift_rule_1": "PASS",
    "schema_drift_rule_2": "PASS",
    "schema_drift_rule_3": "PASS",
    "schema_drift_rule_4": "PASS",
    "schema_drift_rule_5": "PASS",
    "schema_drift_rule_6": "PASS",
    "authority_drift_rule_1": "PASS",
    "authority_drift_rule_2": "PASS",
    "authority_drift_rule_3": "PASS",
    "authority_drift_rule_4": "PASS",
    "authority_drift_rule_5": "PASS",
    "authority_drift_rule_6": "PASS",
    "overall_result": "ALL_PASS"
  },
  "backup_verification": {
    "backup_exists": true,
    "backup_recent": true,
    "backup_valid": true,
    "backup_size_bytes": 1234567,
    "overall_result": "PASS"
  },
  "rollback_plan_verification": {
    "rollback_plan_documented": true,
    "rollback_tested": true,
    "rollback_time_seconds": 180,
    "overall_result": "PASS"
  },
  "technical_readiness_verdict": "READY_FOR_EXECUTION_UNLOCK",
  "signature": "PGP-SIGNATURE-BASE64-ENCODED"
}
```

**Signing Process:**
```bash
# Create artifact file
cat > .authorization/technical-readiness-$(date +%Y%m%d%H%M%S).json <<'EOF'
{ ... artifact content ... }
EOF

# Sign artifact with PGP key
gpg --default-key <TECHNICAL_AUTHORITY_KEY_ID> \
    --armor \
    --detach-sign \
    .authorization/technical-readiness-$(date +%Y%m%d%H%M%S).json

# Verify signature
gpg --verify .authorization/technical-readiness-$(date +%Y%m%d%H%M%S).json.asc \
              .authorization/technical-readiness-$(date +%Y%m%d%H%M%S).json
```

**FAIL Condition:** Artifact not created, not signed, or signature invalid.
**Action on FAIL:** HALT. Create and sign artifact correctly. Re-run Phase 1.

---

### Phase 2: Human Intent Verification

**Purpose:** Execution Approver reviews technical readiness and provides human intent approval.

**Step 2.1: Review Technical Readiness Artifact**
- [ ] Technical Readiness Artifact exists
- [ ] Artifact signature is valid (from Technical Authority PGP key)
- [ ] All 8 prechecks show PASS
- [ ] All 12 drift detection rules show PASS
- [ ] Backup verification shows PASS
- [ ] Rollback plan verification shows PASS
- [ ] Technical readiness verdict is READY_FOR_EXECUTION_UNLOCK

**Verification Commands:**
```bash
# Verify artifact exists
ls -la .authorization/technical-readiness-*.json

# Verify signature
gpg --verify .authorization/technical-readiness-*.json.asc \
              .authorization/technical-readiness-*.json
# Should show "Good signature" from Technical Authority

# Verify all checks show PASS
jq '.precheck_results.overall_result' .authorization/technical-readiness-*.json
# Should return "ALL_PASS"

jq '.drift_detection_results.overall_result' .authorization/technical-readiness-*.json
# Should return "ALL_PASS"

jq '.technical_readiness_verdict' .authorization/technical-readiness-*.json
# Should return "READY_FOR_EXECUTION_UNLOCK"
```

**FAIL Condition:** Artifact missing, signature invalid, or any check shows FAIL.
**Action on FAIL:** HALT. Do NOT proceed. Technical Authority must fix issues and re-emit artifact. Re-run Phase 2.

---

**Step 2.2: Independent Review of Precheck Results**
- [ ] Execution Approver independently verifies precheck results
- [ ] Execution Approver independently verifies drift detection results
- [ ] Execution Approver independently reviews backup and rollback plan
- [ ] Execution Approver confirms agreement with Technical Authority

**Review Process:**
- Execution Approver reads EXECUTION_PRECHECK_SPEC.md
- Execution Approver reads SCHEMA_DRIFT_GUARDS.md
- Execution Approver reads AUTHORITY_DRIFT_GUARDS.md
- Execution Approver runs verification queries manually (spot check)
- Execution Approver confirms all checks PASS independently

**FAIL Condition:** Execution Approver disagrees with Technical Authority.
**Action on FAIL:** HALT. Resolve disagreement before proceeding. Re-run Phase 2.

---

**Step 2.3: Emit Execution Approver Artifact**

**Execution Approver creates and signs artifact:**

**File:** `.authorization/execution-approver-[timestamp].json`

**Content:**
```json
{
  "artifact_type": "EXECUTION_APPROVAL",
  "version": "1.0.0",
  "execution_approver": {
    "role": "Execution Approver",
    "pgp_key_id": "FEDCBA9876543210",
    "identity": "execution-approver@example.com"
  },
  "timestamp": "2025-12-27T11:00:00Z",
  "technical_readiness_artifact": ".authorization/technical-readiness-20251227100000.json",
  "technical_readiness_signature": "PGP-SIGNATURE-FROM-TECHNICAL-AUTHORITY",
  "independent_review_complete": true,
  "independent_review_result": "AGREE_WITH_TECHNICAL_READINESS",
  "execution_phase_being_approved": "INITIAL_MIGRATION",
  "conditions_for_approval": [
    "All 8 prechecks PASS",
    "All 12 drift detection rules PASS",
    "Backup verified and valid",
    "Rollback plan tested and documented",
    "No service_role usage detected",
    "No drift detected in schema or authority model"
  ],
  "approval_statement": "I approve execution unlock for INITIAL_MIGRATION phase under the conditions that all prechecks pass, all drift detection passes, backup is verified, rollback plan is tested, and no service_role usage occurs.",
  "approval_verdict": "APPROVED_FOR_EXECUTION_UNLOCK",
  "signature": "PGP-SIGNATURE-BASE64-ENCODED"
}
```

**Signing Process:**
```bash
# Create artifact file
cat > .authorization/execution-approver-$(date +%Y%m%d%H%M%S).json <<'EOF'
{ ... artifact content ... }
EOF

# Sign artifact with PGP key
gpg --default-key <EXECUTION_APPROVER_KEY_ID> \
    --armor \
    --detach-sign \
    .authorization/execution-approver-$(date +%Y%m%d%H%M%S).json

# Verify signature
gpg --verify .authorization/execution-approver-$(date +%Y%m%d%H%M%S).json.asc \
              .authorization/execution-approver-$(date +%Y%m%d%H%M%S).json
```

**FAIL Condition:** Artifact not created, not signed, or signature invalid.
**Action on FAIL:** HALT. Create and sign artifact correctly. Re-run Phase 2.

---

### Phase 3: Dual Signature Verification

**Purpose:** Verify that two different humans have approved execution unlock.

**Step 3.1: Verify Two-Person Rule**
- [ ] Technical Authority PGP key ID ≠ Execution Approver PGP key ID
- [ ] Technical Authority identity ≠ Execution Approver identity
- [ ] Both artifacts signed by different PGP keys
- [ ] Both signatures are valid
- [ ] Both artifacts reference each other

**Verification Commands:**
```bash
# Extract PGP key IDs from both artifacts
TECH_KEY_ID=$(jq '.technical_authority.pgp_key_id' .authorization/technical-readiness-*.json -r)
EXEC_KEY_ID=$(jq '.execution_approver.pgp_key_id' .authorization/execution-approver-*.json -r)

# Verify keys are different
if [ "$TECH_KEY_ID" = "$EXEC_KEY_ID" ]; then
  echo "FAIL: Same person approved both technical readiness and execution approval"
  exit 1
fi

# Verify both signatures are valid
gpg --verify .authorization/technical-readiness-*.json.asc
gpg --verify .authorization/execution-approver-*.json.asc
# Both should show "Good signature" from different keys

# Verify execution approver artifact references technical readiness artifact
jq -r '.technical_readiness_artifact' .authorization/execution-approver-*.json
# Should return path to technical readiness artifact
```

**FAIL Condition:** Same person approved both artifacts, or any signature invalid.
**Action on FAIL:** HALT. Two different humans must approve. Re-run Phase 3.

---

**Step 3.2: Emit Execution Unlock Artifact**

**Combine both approvals into single unlock artifact:**

**File:** `.authorization/execution-unlock-[timestamp].json`

**Content:**
```json
{
  "artifact_type": "EXECUTION_UNLOCK",
  "version": "1.0.0",
  "timestamp": "2025-12-27T12:00:00Z",
  "technical_readiness_artifact": ".authorization/technical-readiness-20251227100000.json",
  "execution_approval_artifact": ".authorization/execution-approver-20251227110000.json",
  "technical_authority": {
    "role": "Technical Authority",
    "pgp_key_id": "0123456789ABCDEF",
    "identity": "technical-authority@example.com",
    "signature": "PGP-SIGNATURE-FROM-TECHNICAL-READINESS-ARTIFACT"
  },
  "execution_approver": {
    "role": "Execution Approver",
    "pgp_key_id": "FEDCBA9876543210",
    "identity": "execution-approver@example.com",
    "signature": "PGP-SIGNATURE-FROM-EXECUTION-APPROVER-ARTIFACT"
  },
  "execution_phase": "INITIAL_MIGRATION",
  "unlock_conditions": [
    "All 8 prechecks PASS",
    "All 12 drift detection rules PASS",
    "Backup verified and valid",
    "Rollback plan tested and documented",
    "Two different humans approved (two-person rule)",
    "No service_role usage detected",
    "No drift detected in schema or authority model"
  ],
  "unlock_verdict": "EXECUTION_UNLOCK_APPROVED",
  "dual_signature": "PGP-SIGNATURE-BASE64-ENCODED (optional combined signature)"
}
```

**Creation Process:**
```bash
# Create combined artifact
cat > .authorization/execution-unlock-$(date +%Y%m%d%H%M%S).json <<'EOF'
{ ... artifact content ... }
EOF

# Optionally sign with both keys (for extra assurance)
gpg --default-key <TECHNICAL_AUTHORITY_KEY_ID> \
    --armor \
    --detach-sign \
    .authorization/execution-unlock-$(date +%Y%m%d%H%M%S).json

gpg --default-key <EXECUTION_APPROVER_KEY_ID> \
    --armor \
    --detach-sign \
    .authorization/execution-unlock-$(date +%Y%m%d%H%M%S).json
```

**FAIL Condition:** Artifact not created, or references invalid.
**Action on FAIL:** HALT. Create artifact correctly. Re-run Phase 3.

---

### Phase 4: Execution State Transition

**Purpose:** Transition from EXECUTION_DISABLED to EXECUTION_ENABLED.

**Step 4.1: Update Execution State File**
- [ ] `.authorization/execution-state` file updated
- [ ] Previous state: EXECUTION_DISABLED
- [ ] New state: EXECUTION_ENABLED
- [ ] Timestamp recorded
- [ ] Execution unlock artifact referenced

**Update Process:**
```bash
# Update execution state file
cat > .authorization/execution-state <<'EOF'
status: EXECUTION_ENABLED
timestamp: 2025-12-27T12:00:00Z
execution_unlock_artifact: .authorization/execution-unlock-20251227120000.json
technical_readiness_artifact: .authorization/technical-readiness-20251227100000.json
execution_approval_artifact: .authorization/execution-approver-20251227110000.json
technical_authority_pgp_key_id: 0123456789ABCDEF
execution_approver_pgp_key_id: FEDCBA9876543210
execution_phase: INITIAL_MIGRATION
EOF
```

**FAIL Condition:** State file not updated or contains invalid data.
**Action on FAIL:** HALT. Update state file correctly. Re-run Phase 4.

---

**Step 4.2: Update Authorization Log**
- [ ] Append to `.authorization/CHANGE_AUTHORIZATION_LOG.md`
- [ ] Log entry includes: who, what, when, artifacts, signatures
- [ ] Log is append-only (no modifications to previous entries)

**Log Entry:**
```markdown
## 2025-12-27T12:00:00Z - EXECUTION_UNLOCK_GRANTED

**Technical Authority:** technical-authority@example.com (0123456789ABCDEF)
**Execution Approver:** execution-approver@example.com (FEDCBA9876543210)
**Action:** Execution unlock granted for INITIAL_MIGRATION phase
**Execution Unlock Artifact:** .authorization/execution-unlock-20251227120000.json
**Technical Readiness Artifact:** .authorization/technical-readiness-20251227100000.json
**Execution Approval Artifact:** .authorization/execution-approver-20251227110000.json
**Signatures:**
  - Technical Authority signature: VALID
  - Execution Approver signature: VALID
  - Two-person rule verified: PASS (different PGP keys)
**Unlock Conditions:**
  - All 8 prechecks: PASS
  - All 12 drift detection rules: PASS
  - Backup verification: PASS
  - Rollback plan verification: PASS
  - Service_role quarantine: PASS (no usage detected)
**Rationale:** All technical readiness checks passed. Two different humans reviewed and approved. System is ready for controlled migration execution.
```

**FAIL Condition:** Log entry not created or incomplete.
**Action on FAIL:** HALT. Create log entry correctly. Re-run Phase 4.

---

**Step 4.3: Commit Authorization Artifacts**
- [ ] All authorization artifacts committed to Git
- [ ] Commit message includes [EXECUTION-UNLOCK] token
- [ ] Commit signed with PGP key (optional but recommended)

**Commit Process:**
```bash
# Stage authorization artifacts
git add .authorization/

# Commit with approval token
git commit -m "[EXECUTION-UNLOCK] Transition from EXECUTION_DISABLED to EXECUTION_ENABLED

- Technical readiness verified by Technical Authority
- Execution approval granted by Execution Approver
- Two-person rule satisfied (different PGP keys)
- All 8 prechecks PASS
- All 12 drift detection rules PASS
- Backup and rollback plan verified
- Execution state updated to EXECUTION_ENABLED

Ready to proceed with INITIAL_MIGRATION phase."
```

**FAIL Condition:** Artifacts not committed or commit message missing token.
**Action on FAIL:** HALT. Commit artifacts correctly. Re-run Phase 4.

---

## Post-Unlock Verification

### Verification Step 1: Confirm Execution State

**Verify execution state file shows EXECUTION_ENABLED:**
```bash
cat .authorization/execution-state
# Should show: status: EXECUTION_ENABLED
```

### Verification Step 2: Confirm Artifacts Exist

**Verify all authorization artifacts exist:**
```bash
ls -la .authorization/execution-unlock-*.json
ls -la .authorization/technical-readiness-*.json
ls -la .authorization/execution-approver-*.json
ls -la .authorization/execution-state
```

### Verification Step 3: Confirm Signatures Valid

**Verify all PGP signatures are valid:**
```bash
for sig in .authorization/*.asc; do
  gpg --verify "$sig"
done
# All should show "Good signature"
```

### Verification Step 4: Confirm Log Updated

**Verify authorization log updated:**
```bash
tail -n 20 .authorization/CHANGE_AUTHORIZATION_LOG.md
# Should show EXECUTION_UNLOCK_GRANTED entry
```

---

## Intentional Annoyances

**This protocol is intentionally annoying to execute incorrectly:**

1. **Two-Person Rule:**
   - Same person CANNOT approve both technical readiness and execution intent
   - Forces collaboration and review
   - Prevents single-point-of-failure

2. **PGP Signatures:**
   - Every approval must be signed with PGP key
   - Prevents forgery and impersonation
   - Requires key management overhead

3. **Artifacts for Everything:**
   - Technical readiness must be documented in artifact
   - Execution approval must be documented in artifact
   - Dual approval must be documented in combined artifact
   - Creates paper trail, prevents ambiguity

4. **Independent Verification:**
   - Execution Approver must independently verify precheck results
   - Cannot blindly trust Technical Authority
   - Forces actual review, not rubber-stamping

5. **Append-Only Authorization Log:**
   - Every authorization event logged
   - Cannot modify or delete log entries
   - Creates permanent audit trail

6. **State File with References:**
   - Execution state file must reference unlock artifact
   - Unlock artifact must reference technical readiness and approval artifacts
   - Creates chain of custody, prevents missing artifacts

7. **Git Commit with Token:**
   - All authorization artifacts must be committed to Git
   - Commit message must include [EXECUTION-UNLOCK] token
   - Prevents hidden state changes

**These annoyances make reckless execution nearly impossible.**

---

## Summary

**Phases Defined:** 4 (Pre-Unlock Verification, Technical Readiness, Human Intent, State Transition)
**Steps Defined:** 15+ steps across all phases
**Two-Person Rule:** Required for execution unlock (Technical Authority + Execution Approver)
**Artifacts Required:** 3+ artifacts with PGP signatures
**Verification Steps:** 4+ verification steps at each phase
**Intentional Annoyances:** 7 layers of friction to prevent reckless execution

**Key Guarantees:**
- Execution unlock requires two different humans
- All technical conditions verified before human approval
- All approvals documented in signed artifacts
- All actions logged in append-only authorization log
- State transition is explicit and reversible (via emergency brake)
- No shortcuts, no bypasses, no silent transitions

**Execution unlock is boring, safe, and requires explicit dual approval.**
