# Change Authorization Log

## Purpose
**DEFINITIVE** specification of append-only authorization records for all human decisions.

**PRINCIPLE:** Every authorization action is logged permanently. No deletions, no modifications, complete audit trail.

**IMPORTANT:** This is DESIGN ONLY. No implementation. This document defines what the log SHOULD contain if implemented.

---

## Authorization Log Overview

**The Authorization Log is an append-only record of:**

- WHO authorized what
- WHEN they authorized it
- UNDER WHICH CONDITIONS they authorized it
- WHAT ARTIFACTS prove the authorization
- WHAT SIGNATURES verify the authorization

**Key Properties:**

1. **Append-Only:**
   - New entries are added to the end
   - No existing entries can be modified
   - No existing entries can be deleted
   - Log grows monotonically

2. **Immutable:**
   - Once written, entries are permanent
   - No editing, no updating, no revising
   - Corrections create new entries (referencing old entry)

3. **Signed:**
   - Each entry includes PGP signature of authorizing actor
   - Signature verification required for validity
   - Invalid signatures cause entry rejection

4. **Ordered:**
   - Entries are timestamped
   - Entries are in chronological order
   - No out-of-order entries

**Log Location:** `.authorization/CHANGE_AUTHORIZATION_LOG.md`

---

## Log Entry Format

### Standard Entry Structure

**Every log entry follows this format:**

```markdown
## [TIMESTAMP] - [EVENT_TYPE]

**Actor:** [Role] - [PGP Key ID] - [Identity]
**Action:** [Description of action]
**Target:** [What was acted upon]
**Approval Artifacts:** [Links to artifacts]
**Signatures:** [PGP signature verification results]
**Rationale:** [Why action was taken]
**Conditions:** [Conditions that were met]
**References:** [Links to related entries or documents]
```

**Example Entry:**

```markdown
## 2025-12-27T12:00:00Z - EXECUTION_UNLOCK_GRANTED

**Actor:** Execution Approver - FEDCBA9876543210 - execution-approver@example.com
**Action:** Granted execution unlock for INITIAL_MIGRATION phase
**Target:** System execution state (EXECUTION_DISABLED → EXECUTION_ENABLED)
**Approval Artifacts:**
  - Technical Readiness: .authorization/technical-readiness-20251227100000.json
  - Execution Approval: .authorization/execution-approver-20251227110000.json
  - Execution Unlock: .authorization/execution-unlock-20251227120000.json
**Signatures:**
  - Technical Authority (0123456789ABCDEF): VALID
  - Execution Approver (FEDCBA9876543210): VALID
  - Two-Person Rule: SATISFIED (different PGP keys)
**Rationale:** All technical readiness checks passed. Two different humans reviewed and approved. System is ready for controlled migration execution.
**Conditions:**
  - All 8 prechecks: PASS
  - All 12 drift detection rules: PASS
  - Backup verification: PASS
  - Rollback plan verification: PASS
  - Service_role quarantine: PASS (no usage detected)
**References:**
  - EXECUTION_UNLOCK_PROTOCOL.md Step 4.2
  - TWO_KEY_RULE_SPEC.md Section: Two-Key Combination
  - Definition of Done: STEP 13 Deliverable 2
```

---

## Event Types

### EVENT_TYPE: ROLE_GRANTED

**When:** A role is granted to a person.

**Entry Format:**

```markdown
## [TIMESTAMP] - ROLE_GRANTED

**Actor:** Repository Owner - [PGP Key ID] - [Identity]
**Action:** Granted [Role] to [Person]
**Target:** [Role] authorization
**Approval Artifacts:**
  - Role Grant Artifact: .authorization/role-grant-[timestamp].json
**Signatures:**
  - Repository Owner: VALID
**Rationale:** [Why role was granted to this person]
**Conditions:**
  - PGP key generated: YES
  - PGP key published: YES (.pgp-keys/[role].asc)
  - Role acceptance confirmed: YES
**References:**
  - OPERATOR_AUTHORIZATION_MODEL.md [Role Definition]
```

**Example:**

```markdown
## 2025-12-27T09:00:00Z - ROLE_GRANTED

**Actor:** Repository Owner - 9999888877776666 - repository-owner@example.com
**Action:** Granted Technical Authority role to tech-lead@example.com
**Target:** Technical Authority authorization
**Approval Artifacts:**
  - Role Grant Artifact: .authorization/role-grant-20251227090000.json
**Signatures:**
  - Repository Owner (9999888877776666): VALID
**Rationale:** Tech lead has deep technical knowledge of system, understands all prechecks and drift detection rules. Qualified to verify technical readiness.
**Conditions:**
  - PGP key generated: YES (0123456789ABCDEF)
  - PGP key published: YES (.pgp-keys/technical-authority.asc)
  - Role acceptance confirmed: YES (tech-lead@example.com signed role acceptance artifact)
**References:**
  - OPERATOR_AUTHORIZATION_MODEL.md Role 3: Technical Authority
```

---

### EVENT_TYPE: ROLE_REVOKED

**When:** A role is revoked from a person.

**Entry Format:**

```markdown
## [TIMESTAMP] - ROLE_REVOKED

**Actor:** Repository Owner - [PGP Key ID] - [Identity]
**Action:** Revoked [Role] from [Person]
**Target:** [Role] authorization
**Approval Artifacts:**
  - Role Revoke Artifact: .authorization/role-revoke-[timestamp].json
**Signatures:**
  - Repository Owner: VALID
  - [Revoked Role] (if voluntary revocation): VALID
**Rationale:** [Why role was revoked]
**Conditions:**
  - Revocation reason: [SECURITY_COMPROMISE | POLICY_VIOLATION | INACTIVITY | ROLE_NO_LONGER_NEEDED | VOLUNTARY]
  - PGP key revoked: YES
  - PGP key added to revoked list: YES
**References:**
  - OPERATOR_AUTHORIZATION_MODEL.md Section: Authorization Revocation
```

**Example:**

```markdown
## 2025-12-27T14:00:00Z - ROLE_REVOKED

**Actor:** Repository Owner - 9999888877776666 - repository-owner@example.com
**Action:** Revoked Execution Approver role from manager@example.com
**Target:** Execution Approver authorization
**Approval Artifacts:**
  - Role Revoke Artifact: .authorization/role-revoke-20251227140000.json
**Signatures:**
  - Repository Owner (9999888877776666): VALID
  - Execution Approver (FEDCBA9876543210): VALID (voluntary revocation)
**Rationale:** Manager is leaving project, voluntarily resigned from Execution Approver role. New Execution Approver will be appointed.
**Conditions:**
  - Revocation reason: VOLUNTARY
  - PGP key revoked: YES
  - PGP key added to revoked list: YES (.pgp-keys/revoked/execution-approver.asc)
**References:**
  - OPERATOR_AUTHORIZATION_MODEL.md Section: Authorization Revocation
```

---

### EVENT_TYPE: EXECUTION_UNLOCK_GRANTED

**When:** Execution unlock is granted (two-key rule satisfied).

**Entry Format:** (see example above in "Standard Entry Structure")

**Required Fields:**
- Actor (Execution Approver)
- Action (granted execution unlock)
- Target (execution state transition)
- Approval Artifacts (technical readiness + execution approval + execution unlock)
- Signatures (both Key 1 and Key 2)
- Rationale (why unlock was granted)
- Conditions (all prechecks PASS, all drift detection PASS, etc.)
- References (EXECUTION_UNLOCK_PROTOCOL.md, TWO_KEY_RULE_SPEC.md)

---

### EVENT_TYPE: EXECUTION_UNLOCK_REVOKED

**When:** Execution unlock is revoked (emergency brake or other reason).

**Entry Format:**

```markdown
## [TIMESTAMP] - EXECUTION_UNLOCK_REVOKED

**Actor:** [Role] - [PGP Key ID] - [Identity]
**Action:** Revoked execution unlock
**Target:** System execution state (EXECUTION_ENABLED → EXECUTION_HALTED or EXECUTION_DISABLED)
**Approval Artifacts:**
  - Revocation Artifact: .authorization/execution-unlock-revoke-[timestamp].json
  - Emergency Brake Artifact (if applicable): .authorization/emergency-brake-[timestamp].json
**Signatures:**
  - [Role]: VALID
**Rationale:** [Why unlock was revoked]
**Conditions:**
  - Revocation reason: [EMERGENCY_BRAKE | SECURITY_BREACH | POLICY_VIOLATION | OTHER]
  - Emergency conditions resolved: [YES | NO | PENDING]
**References:**
  - EMERGENCY_BRAKE_SPEC.md (if applicable)
```

**Example:**

```markdown
## 2025-12-27T15:30:00Z - EXECUTION_UNLOCK_REVOKED

**Actor:** Emergency Breaker - ABCDEF1234567890 - emergency-breaker@example.com
**Action:** Revoked execution unlock (Emergency Brake activated)
**Target:** System execution state (EXECUTION_ENABLED → EXECUTION_HALTED)
**Approval Artifacts:**
  - Emergency Brake Artifact: .authorization/emergency-brake-20251227153000.json
**Signatures:**
  - Emergency Breaker (ABCDEF1234567890): VALID
**Rationale:** Schema drift detected during migration execution. run_records table missing primary key constraint. Migration failed mid-execution. Critical failure requires immediate halt.
**Conditions:**
  - Revocation reason: EMERGENCY_BRAKE
  - Emergency conditions resolved: PENDING (investigation in progress)
**References:**
  - EMERGENCY_BRAKE_SPEC.md Condition 1: CRITICAL_FAILURE
```

---

### EVENT_TYPE: EMERGENCY_BRAKE_ACTIVATED

**When:** Emergency Brake is activated.

**Entry Format:** (see EMERGENCY_BRAKE_SPEC.md for example)

**Required Fields:**
- Actor (Emergency Breaker)
- Action (activated emergency brake)
- Target (execution state transition)
- Approval Artifacts (emergency brake artifact)
- Signatures (Emergency Breaker)
- Rationale (why brake was activated)
- Conditions (brake reason category, immediate actions taken)
- References (EMERGENCY_BRAKE_SPEC.md)

---

### EVENT_TYPE: EMERGENCY_BRAKE_CLEARED

**When:** Emergency Brake is cleared.

**Entry Format:** (see EMERGENCY_BRAKE_SPEC.md for example)

**Required Fields:**
- Actor (Emergency Breaker)
- Action (cleared emergency brake)
- Target (execution state transition)
- Approval Artifacts (emergency brake clear artifact)
- Signatures (Emergency Breaker)
- Rationale (why brake was cleared)
- Conditions (investigation summary, resolution plan, preventive measures, stakeholders informed)
- References (EMERGENCY_BRAKE_SPEC.md)

---

### EVENT_TYPE: PROTECTED_FILE_MODIFIED

**When:** A protected file is modified with approval.

**Entry Format:**

```markdown
## [TIMESTAMP] - PROTECTED_FILE_MODIFIED

**Actor:** Repository Maintainer - [PGP Key ID] - [Identity]
**Action:** Modified [Protected File]
**Target:** [Protected File Path]
**Approval Artifacts:**
  - Commit: [Commit Hash]
  - Commit Message: [Includes approval token]
**Signatures:**
  - Repository Maintainer: VALID
  - Approver (if separate): VALID
**Rationale:** [Why file was modified]
**Conditions:**
  - Approval token present: YES ([APPROVAL-TOKEN])
  - Commit signed: [YES | NO]
  - CI guardrails passed: [YES | NO | N/A]
**References:**
  - CI_GUARDRAILS_DESIGN.md [Guardrail #]
  - [Protected File] - Original version
```

**Example:**

```markdown
## 2025-12-27T10:00:00Z - PROTECTED_FILE_MODIFIED

**Actor:** Repository Maintainer - 1111222233334444 - maintainer@example.com
**Action:** Modified DDL_DRAFT.sql (added new column to tools table)
**Target:** supabase/schema/DDL_DRAFT.sql
**Approval Artifacts:**
  - Commit: a1b2c3d4e5f6
  - Commit Message: "feat: Add category column to tools table [SCHEMA-APPROVED]"
**Signatures:**
  - Repository Maintainer (1111222233334444): VALID
  - Schema Approver (separate maintainer): VALID
**Rationale:** New feature requires categorization of tools. Category column added to tools table to support tool filtering and grouping.
**Conditions:**
  - Approval token present: YES ([SCHEMA-APPROVED])
  - Commit signed: NO (optional but recommended)
  - CI guardrails passed: N/A (CI not implemented yet)
**References:**
  - CI_GUARDRAILS_DESIGN.md Guardrail 1: Schema File Protection
  - supabase/schema/DDL_DRAFT.sql - Original version (commit e5f6g7h8)
```

---

### EVENT_TYPE: AUTHORIZATION_MODEL_CHANGED

**When:** Authorization model is modified.

**Entry Format:**

```markdown
## [TIMESTAMP] - AUTHORIZATION_MODEL_CHANGED

**Actor:** Repository Owner - [PGP Key ID] - [Identity]
**Action:** Modified Authorization Model
**Target:** OPERATOR_AUTHORIZATION_MODEL.md (or other authorization document)
**Approval Artifacts:**
  - Commit: [Commit Hash]
  - Commit Message: [Includes [AUTHORIZATION-APPROVED] token]
  - Role Change Artifacts: [If roles added/removed]
**Signatures:**
  - Repository Owner: VALID
  - [Other Repository Owner, if multi-owner]: VALID
**Rationale:** [Why authorization model was changed]
**Conditions:**
  - Approval token present: YES ([AUTHORIZATION-APPROVED])
  - Multi-owner approval: [YES | NO | N/A]
  - Existing roles reviewed: YES
**References:**
  - OPERATOR_AUTHORIZATION_MODEL.md [Modified Section]
  - CI_GUARDRAILS_DESIGN.md Guardrail 6: Precheck Protection
```

**Example:**

```markdown
## 2025-12-27T11:00:00Z - AUTHORIZATION_MODEL_CHANGED

**Actor:** Repository Owner - 9999888877776666 - repository-owner@example.com
**Action:** Modified Authorization Model (added Data Steward role)
**Target:** OPERATOR_AUTHORIZATION_MODEL.md
**Approval Artifacts:**
  - Commit: f6e5d4c3b2a1
  - Commit Message: "feat: Add Data Steward role [AUTHORIZATION-APPROVED]"
  - Role Grant Artifact: .authorization/role-grant-data-steward-20251227110000.json
**Signatures:**
  - Repository Owner (9999888877776666): VALID
  - Co-Owner (8888777766665555): VALID
**Rationale:** New compliance requirements require data governance role. Data Steward role added to oversee data access and retention policies.
**Conditions:**
  - Approval token present: YES ([AUTHORIZATION-APPROVED])
  - Multi-owner approval: YES (2 owners approved)
  - Existing roles reviewed: YES (no conflicts with existing roles)
**References:**
  - OPERATOR_AUTHORIZATION_MODEL.md Role 6: Data Steward (NEW)
  - CI_GUARDRAILS_DESIGN.md Guardrail 6: Precheck Protection
```

---

## Log Integrity

### Append-Only Enforcement

**How append-only property is enforced:**

1. **File Permissions:**
   - `.authorization/CHANGE_AUTHORIZATION_LOG.md` is write-only (append)
   - No edit permissions on existing entries
   - Only Repository Owner can change permissions (with audit trail)

2. **Git History:**
   - Every commit adds new entries, never modifies old entries
   - Git history preserves all previous versions
   - Any attempt to modify history is detected (git reflog)

3. **Cryptographic Hashing:**
   - Each entry includes hash of previous entry
   - Chain of hashes prevents tampering
   - Broken hash chain indicates log tampering

4. **PGP Signatures:**
   - Each entry includes PGP signature of authorizing actor
   - Signature verification required for validity
   - Invalid signatures cause entry rejection

**Log Integrity Verification:**

```bash
#!/bin/bash
# verify-log-integrity.sh

echo "Verifying authorization log integrity..."

# Check file permissions (append-only)
if [ ! -a .authorization/CHANGE_AUTHORIZATION_LOG.md ]; then
  echo "❌ FAIL: Authorization log does not exist"
  exit 1
fi

# Check for PGP signatures
if ! grep -q "signature:" .authorization/CHANGE_AUTHORIZATION_LOG.md; then
  echo "❌ FAIL: Authorization log missing signatures"
  exit 1
fi

# Verify PGP signatures
# (Extract and verify each signature)
# This is design only, not implemented

# Check git history for modifications
if git log --all --full-history -- .authorization/CHANGE_AUTHORIZATION_LOG.md | grep -q "revert"; then
  echo "❌ FAIL: Authorization log history contains reversions (possible tampering)"
  exit 1
fi

echo "✅ PASS: Authorization log integrity verified"
exit 0
```

---

## Log Auditing

### Regular Audits

**Authorization log should be audited regularly:**

**Frequency:** Monthly (every 30 days)

**Audit Procedure:**

1. **Verify Log Integrity:**
   - [ ] File permissions correct (append-only)
   - [ ] No missing entries (check timestamps are sequential)
   - [ ] No duplicate entries (check timestamps and event types)
   - [ ] No invalid signatures (verify all PGP signatures)

2. **Verify Log Completeness:**
   - [ ] All role grants logged
   - [ ] All role revokes logged
   - [ ] All execution unlocks logged
   - [ ] All emergency brakes logged
   - [ ] All protected file modifications logged

3. **Verify Authorization Consistency:**
   - [ ] All unlocks have two-key rule satisfied
   - [ ] All emergency brakes have clear artifacts
   - [ ] All role changes have Repository Owner approval
   - [ ] All protected file changes have approval tokens

4. **Generate Audit Report:**

**Audit Report Artifact:**

```json
{
  "artifact_type": "AUTHORIZATION_LOG_AUDIT",
  "version": "1.0.0",
  "timestamp": "2025-12-27T09:00:00Z",
  "audit_period": {
    "start_date": "2025-11-27T00:00:00Z",
    "end_date": "2025-12-27T00:00:00Z"
  },
  "auditor": {
    "role": "Repository Owner",
    "pgp_key_id": "9999888877776666",
    "identity": "repository-owner@example.com"
  },
  "integrity_checks": {
    "file_permissions_correct": true,
    "no_missing_entries": true,
    "no_duplicate_entries": true,
    "all_signatures_valid": true
  },
  "completeness_checks": {
    "all_role_grants_logged": true,
    "all_role_revokes_logged": true,
    "all_unlocks_logged": true,
    "all_brakes_logged": true,
    "all_protected_file_changes_logged": true
  },
  "consistency_checks": {
    "all_unlocks_two_key_rule": true,
    "all_brakes_cleared": true,
    "all_role_changes_approved": true,
    "all_file_changes_approved": true
  },
  "audit_result": "PASS",
  "issues_found": [],
  "recommendations": [],
  "signature": "PGP-SIGNATURE-BASE64-ENCODED"
}
```

---

## Log Queries

### Query Examples

**Query 1: All actions by specific person**

```bash
grep "Actor:.*john@example.com" .authorization/CHANGE_AUTHORIZATION_LOG.md
```

**Query 2: All emergency brake activations**

```bash
grep "EVENT_TYPE: EMERGENCY_BRAKE_ACTIVATED" .authorization/CHANGE_AUTHORIZATION_LOG.md
```

**Query 3: All execution unlock grants**

```bash
grep "EVENT_TYPE: EXECUTION_UNLOCK_GRANTED" .authorization/CHANGE_AUTHORIZATION_LOG.md
```

**Query 4: All protected file modifications in date range**

```bash
sed -n '/2025-12-01T00:00:00Z/,/2025-12-31T23:59:59Z/p' .authorization/CHANGE_AUTHORIZATION_LOG.md | \
  grep "EVENT_TYPE: PROTECTED_FILE_MODIFIED"
```

**Query 5: All actions by specific role**

```bash
grep "Actor:.*Execution Approver" .authorization/CHANGE_AUTHORIZATION_LOG.md
```

---

## Summary

**Authorization Log Defined:** Append-only record of all human authorization actions
**Event Types Defined:** 7 (ROLE_GRANTED, ROLE_REVOKED, EXECUTION_UNLOCK_GRANTED, EXECUTION_UNLOCK_REVOKED, EMERGENCY_BRAKE_ACTIVATED, EMERGENCY_BRAKE_CLEARED, PROTECTED_FILE_MODIFIED, AUTHORIZATION_MODEL_CHANGED)
**Entry Format:** Standardized with required fields (Actor, Action, Target, Artifacts, Signatures, Rationale, Conditions, References)
**Integrity Enforcement:** File permissions, Git history, cryptographic hashing, PGP signatures
**Auditing:** Monthly audits with integrity, completeness, and consistency checks

**Key Properties:**
- Append-only (no modifications, no deletions)
- Immutable (once written, permanent)
- Signed (PGP signatures for validity)
- Ordered (chronological, timestamps)
- Complete (all authorization actions logged)
- Auditable (regular integrity checks)

**This is DESIGN ONLY. No implementation. The log defines what SHOULD be recorded if implemented.**

**The Authorization Log makes all human decisions transparent, accountable, and auditable.**
