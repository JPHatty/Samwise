# Operator Authorization Model

## Purpose
**DEFINITIVE** specification of human roles OUTSIDE the system with explicit prohibitions.

**PRINCIPLE:** Governance without trust. No implicit permissions. All authorization is explicit, scoped, and revocable.

---

## Human Role Definitions

### Role 1: Repository Maintainer

**Description:**
Individual with write access to the Git repository. Can merge pull requests and modify codebase.

**ALLOWED ACTIONS:**
- ✅ Merge pull requests that pass CI guardrails (if CI implemented)
- ✅ Modify non-protected files (code, docs, tests)
- ✅ Review and approve changes from others
- ✅ Update documentation
- ✅ Commit non-critical changes

**EXPLICIT PROHIBITIONS:**
- ❌ CANNOT modify protected files without approval tokens:
  - supabase/schema/DDL_DRAFT.sql
  - supabase/security/ROLES_AND_RLS.md
  - supabase/security/AUTHORITY_ASSERTIONS.md
  - supabase/adapters/ADAPTER_CONTRACTS.md
  - migrations/planned/*.sql
  - EXECUTION_BOUNDARIES.md
  - tool-spec.schema.json
  - compose.yaml (cloud service stubs)
- ❌ CANNOT approve execution unlock alone (requires dual approval)
- ❌ CANNOT bypass CI guardrails (if CI implemented)
- ❌ CANNOT merge changes that weaken invariants
- ❌ CANNOT disable any drift detection or precheck
- ❌ CANNOT access service_role key or use it in code

**AUTHORIZATION PROOF:**
- Git commit must include approval token for protected files
- Approval tokens: [SCHEMA-APPROVED], [AUTHORITY-APPROVED], [BOUNDARY-APPROVED], [ADAPTER-APPROVED], [PRECHECK-APPROVED]
- Maintainer identity proven by Git signature (GPG) or verified email

**REVOCATION:**
- Write access can be revoked by repository owner
- Approval tokens are rejected if maintainer is removed from authorized list

---

### Role 2: Execution Approver

**Description:**
Individual authorized to approve execution unlock. Provides human intent confirmation.

**ALLOWED ACTIONS:**
- ✅ Approve execution unlock (with technical readiness key)
- ✅ Review precheck results before approving
- ✅ Review drift detection results before approving
- ✅ Verify backup and rollback plan before approving
- ✅ Grant explicit approval for execution phase transition

**EXPLICIT PROHIBITIONS:**
- ❌ CANNOT approve execution unlock alone (requires dual approval)
- ❌ CANNOT bypass any precheck (all 8 must PASS)
- ❌ CANNOT approve if drift detected (all drift checks must PASS)
- ❌ CANNOT approve if backup missing or unverified
- ❌ CANNOT approve if rollback plan untested
- ❌ CANNOT modify system code or configuration
- ❌ CANNOT access service_role key or use it in code
- ❌ CANNOT delegate approval authority

**AUTHORIZATION PROOF:**
- Must sign approval artifact with PGP key
- Approval artifact must include:
  - Execution approver identity (PGP key ID)
  - Timestamp of approval
  - Specific execution phase being approved
  - Reference to technical readiness approval (from Technical Authority)
  - Explicit statement: "I approve execution unlock for [phase] under conditions [X, Y, Z]"

**REVOCATION:**
- Approval can be revoked by emitting EMERGENCY_BRAKE artifact
- PGP key can be revoked (prevents future approvals)
- Approval artifact can be marked as revoked in CHANGE_AUTHORIZATION_LOG.md

---

### Role 3: Technical Authority

**Description:**
Individual responsible for verifying technical readiness. Provides technical confirmation.

**ALLOWED ACTIONS:**
- ✅ Verify technical readiness for execution unlock
- ✅ Run prechecks (all 8 must PASS)
- ✅ Run drift detection (all checks must PASS)
- ✅ Verify database backup exists and is valid
- ✅ Verify rollback plan is documented and tested
- ✅ Verify audit infrastructure is ready
- ✅ Grant technical readiness approval (with execution approver key)

**EXPLICIT PROHIBITIONS:**
- ❌ CANNOT approve execution unlock alone (requires dual approval)
- ❌ CANNOT approve if any precheck FAILs
- ❌ CANNOT approve if any drift detected
- ❌ CANNOT approve if backup missing or invalid
- ❌ CANNOT approve if rollback plan untested
- ❌ CANNOT approve if audit infrastructure not ready
- ❌ CANNOT bypass technical readiness verification
- ❌ CANNOT grant execution approver key to themselves

**AUTHORIZATION PROOF:**
- Must sign technical readiness artifact with PGP key
- Technical readiness artifact must include:
  - Technical Authority identity (PGP key ID)
  - Timestamp of verification
  - All 8 precheck results (all PASS)
  - All drift detection results (all PASS)
  - Backup verification result
  - Rollback plan verification result
  - Audit infrastructure verification result
  - Explicit statement: "Technical readiness confirmed for [phase]"

**REVOCATION:**
- Technical readiness can be revoked by emitting EMERGENCY_BRAKE artifact
- PGP key can be revoked (prevents future verifications)
- Technical readiness artifact can be marked as revoked in CHANGE_AUTHORIZATION_LOG.md

---

### Role 4: Emergency Breaker

**Description:**
Individual authorized to immediately halt execution. No debate, no confirmation required.

**ALLOWED ACTIONS:**
- ✅ Emit EMERGENCY_BRAKE artifact to halt execution immediately
- ✅ Override any ongoing operation
- ✅ Lock execution state (prevent further execution until investigation)
- ✅ Access diagnostic logs for incident investigation
- ✅ Approve execution resume after emergency resolved

**EXPLICIT PROHIBITIONS:**
- ❌ CANNOT emit EMERGENCY_BRAKE without documented reason
- ❌ CANNOT emit EMERGENCY_BRAKE to bypass normal approval process
- ❌ CANNOT emit EMERGENCY_BRAKE to skip prechecks or drift detection
- ❌ CANNOT modify system code or configuration
- ❌ CANNOT access service_role key or use it in code
- ❌ CANNOT delegate emergency breaker authority (except in documented succession)

**AUTHORIZATION PROOF:**
- Must sign EMERGENCY_BRAKE artifact with PGP key
- EMERGENCY_BRAKE artifact must include:
  - Emergency Breaker identity (PGP key ID)
  - Timestamp of brake emission
  - Reason for emergency brake (one of: CRITICAL_FAILURE, SECURITY_BREACH, DATA_CORRUPTION, UNEXPECTED_BEHAVIOR, OTHER)
  - Detailed description of emergency condition
  - Immediate actions taken
  - Investigation plan (if applicable)
  - Explicit statement: "EMERGENCY_BRAKE activated. All execution halted."

**REVOCATION:**
- N/A (Emergency Breaker authority is absolute when activated)
- Emergency Breaker can be removed from authorized role list (prevents future brakes)

---

### Role 5: Repository Owner

**Description:**
Individual with ultimate authority over repository governance. Can grant/revoke all other roles.

**ALLOWED ACTIONS:**
- ✅ Grant Repository Maintainer role
- ✅ Revoke Repository Maintainer role
- ✅ Grant Execution Approver role
- ✅ Revoke Execution Approver role
- ✅ Grant Technical Authority role
- ✅ Revoke Technical Authority role
- ✅ Grant Emergency Breaker role
- ✅ Revoke Emergency Breaker role
- ✅ Modify this OPERATOR_AUTHORIZATION_MODEL.md (with explicit approval)
- ✅ Define approval token requirements
- ✅ Define PGP key requirements

**EXPLICIT PROHIBITIONS:**
- ❌ CANNOT grant themselves additional roles (except Repository Owner)
- ❌ CANNOT bypass CI guardrails (if CI implemented)
- ❌ CANNOT modify protected files without approval tokens
- ❌ CANNOT access service_role key or use it in code
- ❌ CANNOT override EMERGENCY_BRAKE once emitted
- ❌ CANNOT delegate Repository Owner role
- ❌ CANNOT modify this document without [AUTHORIZATION-APPROVED] token

**AUTHORIZATION PROOF:**
- Repository Owner identity proven by:
  - Git repository ownership (GitHub/GitLab/Bitbucket admin access)
  - Verified email address
  - Optional: PGP key for signing authorization changes

**REVOCATION:**
- N/A (Repository Owner is ultimate authority)
- In multi-owner scenarios, removal requires consensus of other owners

---

## Cross-Role Prohibitions

### Universal Denials (ALL Roles)

**These actions are FORBIDDEN for ALL human roles:**

1. **No Service_Role Usage:**
   - 🚫 **FORBIDDEN** for all roles to use service_role key in application code
   - 🚫 **FORBIDDEN** for all roles to access service_role key from .env
   - 🚫 **FORBIDDEN** for all roles to grant service_role permissions
   - Only permitted for manual migrations (explicit operator action, not automated)

2. **No Bypass of Drift Detection:**
   - 🚫 **FORBIDDEN** to disable drift detection rules
   - 🚫 **FORBIDDEN** to ignore drift detection results
   - 🚫 **FORBIDDEN** to proceed with execution if drift detected

3. **No Bypass of Prechecks:**
   - 🚫 **FORBIDDEN** to disable precheck rules
   - 🚫 **FORBIDDEN** to skip prechecks
   - 🚫 **FORBIDDEN** to proceed with execution if precheck FAILs

4. **No Bypass of CI Guardrails:**
   - 🚫 **FORBIDDEN** to disable CI guardrails (if CI implemented)
   - 🚫 **FORBIDDEN** to merge changes that fail CI guardrails
   - 🚫 **FORBIDDEN** to modify CI guardrails without approval

5. **No Silent Changes:**
   - 🚫 **FORBIDDEN** to modify protected files without approval token
   - 🚫 **FORBIDDEN** to modify protected files without documentation
   - 🚫 **FORBIDDEN** to modify protected files without commit message referencing approval

6. **No Self-Approval:**
   - 🚫 **FORBIDDEN** for Execution Approver to approve their own execution request
   - 🚫 **FORBIDDEN** for Technical Authority to verify their own technical readiness
   - 🚫 **FORBIDDEN** for Repository Maintainer to approve their own protected file changes

---

## Authorization Proof Mechanisms

### PGP Key Signatures

**All human roles MUST use PGP keys for authorization:**

1. **Key Generation:**
   - Minimum 4096-bit RSA key
   - Key expiration: 1 year (must be rotated annually)
   - Key stored in secure location (hardware token recommended)
   - Key revocation certificate stored offline

2. **Key Distribution:**
   - Public keys published in repository: `.pgp-keys/`
   - Public keys signed by other authorized roles (web of trust)
   - Key fingerprints documented in this file

3. **Signature Verification:**
   - All approval artifacts must be signed
   - Signature verification required before accepting approval
   - Expired or revoked signatures rejected
   - Signature forgery attempts logged as CRITICAL security events

### Approval Tokens

**Commit message approval tokens for protected file changes:**

1. **Schema Changes:** [SCHEMA-APPROVED] or [APPROVED-STEP12]
2. **Authority Changes:** [AUTHORITY-APPROVED] or [APPROVED-STEP12]
3. **Boundary Changes:** [BOUNDARY-APPROVED] or [APPROVED-STEP12]
4. **Adapter Changes:** [ADAPTER-APPROVED] or [APPROVED-STEP12]
5. **Precheck Changes:** [PRECHECK-APPROVED] or [APPROVED-STEP12]
6. **Authorization Changes:** [AUTHORIZATION-APPROVED]

**Token Validation:**
- Token must be present in commit message body
- Token must match protected file type being modified
- Token without valid signature from authorized role is rejected
- Token used for wrong file type is rejected

### Artifact-Based Authorization

**For execution unlock and emergency brake:**

1. **Execution Unlock Artifact:**
   - File: `.authorization/execution-unlock-[timestamp].json`
   - Signed by both Execution Approver AND Technical Authority (dual signature)
   - Contains: execution phase, precheck results, drift detection results, timestamp, both signatures
   - Verified before execution unlock

2. **Emergency Brake Artifact:**
   - File: `.authorization/emergency-brake-[timestamp].json`
   - Signed by Emergency Breaker
   - Contains: reason, detailed description, immediate actions, timestamp, signature
   - Verified immediately (no debate, no confirmation)

3. **Authorization Log Artifact:**
   - File: `.authorization/CHANGE_AUTHORIZATION_LOG.md`
   - Append-only record of all authorization events
   - Contains: who, what, when, approval artifacts, PGP signatures
   - Verified on every authorization action

---

## Role Separation Requirements

### Two-Person Rule

**Critical operations require two different humans:**

1. **Execution Unlock:**
   - Requires: Execution Approver (human intent) + Technical Authority (technical readiness)
   - Same person CANNOT hold both roles for same approval
   - Both must sign execution unlock artifact
   - Both PGP signatures must be valid

2. **Protected File Changes:**
   - Requires: Repository Maintainer (code change) + separate reviewer (approval)
   - Maintainer CANNOT approve their own changes
   - Both must sign off on changes (via PR review + approval token)

3. **Authorization Model Changes:**
   - Requires: Repository Owner (proposal) + separate Repository Owner (approval)
   - Single owner CANNOT modify authorization model alone
   - Multi-owner scenarios require consensus

### Role Conflicts

**These role combinations are FORBIDDEN:**

1. ❌ Execution Approver + Technical Authority (for same execution phase)
   - Violates two-person rule
   - Allows single actor to unlock execution alone

2. ❌ Execution Approver + Repository Maintainer (for self-approval)
   - Allows maintainer to approve their own execution requests

3. ❌ Technical Authority + Repository Maintainer (for self-verification)
   - Allows maintainer to verify their own technical readiness

**Allowed Combinations:**
- ✅ Repository Owner + any other role (except dual approval conflicts)
- ✅ Emergency Breaker + any other role (emergency brake is absolute)
- ✅ Execution Approver + Repository Maintainer (for different execution phases, with two-person rule)

---

## Authorization Revocation

### Voluntary Revocation

**Any authorized role can voluntarily revoke their authorization:**

1. **Revocation Process:**
   - Emit revocation artifact signed with PGP key
   - Artifact includes: role being revoked, timestamp, reason
   - Repository Owner updates authorized role list
   - Revoked role cannot perform further actions

2. **Revocation Effects:**
   - PGP key added to revoked list
   - Future signatures from revoked key rejected
   - Existing approvals remain valid (unless explicitly revoked)
   - Role can be re-granted by Repository Owner

### Involuntary Revocation

**Repository Owner can revoke any role (except other Repository Owners in multi-owner scenarios):**

1. **Revocation Process:**
   - Repository Owner emits revocation artifact
   - Artifact includes: role being revoked, person being revoked, timestamp, reason
   - Revoked person notified (if possible)
   - Revoked role cannot perform further actions

2. **Revocation Reasons:**
   - Security compromise (PGP key lost/stolen)
   - Policy violation (bypassed safeguards, unauthorized actions)
   - Inactivity (no authorization actions for 6+ months)
   - Role no longer needed (project phase change)

### Emergency Revocation

**Emergency Breaker can immediately halt execution but cannot revoke roles:**

- EMERGENCY_BRAKE artifact halts all execution
- Role revocation requires separate action by Repository Owner
- Emergency brake takes precedence over all pending authorizations

---

## Authorization Audit Trail

### Append-Only Authorization Log

**All authorization events recorded in `.authorization/CHANGE_AUTHORIZATION_LOG.md`:**

1. **Log Entry Format:**
   ```markdown
   ## [TIMESTAMP] - [EVENT_TYPE]

   **Actor:** [Role] - [PGP Key ID]
   **Action:** [Description of action]
   **Target:** [What was acted upon]
   **Approval Artifacts:** [Links to artifacts]
   **Signatures:** [PGP signature verification results]
   **Rationale:** [Why action was taken]
   ```

2. **Event Types Logged:**
   - ROLE_GRANTED
   - ROLE_REVOKED
   - EXECUTION_UNLOCK_GRANTED
   - EXECUTION_UNLOCK_REVOKED
   - EMERGENCY_BRAKE_ACTIVATED
   - EMERGENCY_BRAKE_CLEARED
   - PROTECTED_FILE_MODIFIED
   - AUTHORIZATION_MODEL_CHANGED

3. **Log Properties:**
   - Append-only (no deletions, no modifications)
   - Each entry signed by actor
   - Log integrity verified regularly
   - Tampering detected as CRITICAL security event

---

## Summary

**Human Roles Defined:** 5 (Repository Maintainer, Execution Approver, Technical Authority, Emergency Breaker, Repository Owner)
**Authorization Mechanisms:** PGP signatures, approval tokens, artifact-based authorization
**Two-Person Rule:** Required for execution unlock and protected file changes
**Universal Prohibitions:** 6 explicit denials for all roles
**Authorization Audit:** Append-only log with PGP signatures

**Key Principles:**
- No implicit trust
- All authorization explicit and scoped
- All actions reversible (except emergency brake)
- All authorizations logged and audited
- Two-person rule for critical operations
- PGP signatures prevent forgery
- Role separation prevents single-point-of-failure

**This authorization model makes power boring (requires explicit approval), mistakes survivable (revocable + auditable), and prevents reckless actions (two-person rule + universal prohibitions).**
