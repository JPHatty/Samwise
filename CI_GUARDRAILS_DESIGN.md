# CI Guardrails Design

## Purpose
**DEFINITIVE** specification of CI checks that would prevent silent drift through unapproved changes.

**PRINCIPLE:** Block merges that would weaken execution boundaries, schema, or authority model.

**IMPORTANT:** This is DESIGN ONLY. No CI configuration files will be created. This document describes what CI checks SHOULD do if implemented.

---

## Guardrail 1: Schema File Protection

**Protected Files:**
- supabase/schema/DDL_DRAFT.sql
- migrations/planned/001_tables.sql
- migrations/planned/002_indexes.sql
- migrations/planned/003_constraints.sql

**Trigger:** ANY diff detected in protected files

**Check Behavior:**

1. **Detect Changes:**
   ```bash
   git diff --name-only origin/main...HEAD | grep -E '^supabase/schema/|^migrations/planned/'
   ```

2. **Validate Approval:**
   - Check commit message for required approval token
   - Required tokens: `[SCHEMA-APPROVED]` or `[APPROVED-STEP12]`
   - Token MUST be present in commit message body

3. **Validate Integrity:**
   - SQL syntax validation (no parse errors)
   - Table count unchanged (10/10 tables)
   - No DROP TABLE statements
   - No DELETE FROM statements on append-only tables

**PASS Condition:**
- ✅ No changes detected (automatic pass)
- ✅ Changes detected AND commit message includes approval token AND integrity checks pass

**FAIL Condition:**
- ❌ Changes detected AND commit message missing approval token
- ❌ Changes detected AND SQL syntax errors
- ❌ Changes detected AND table count changed
- ❌ Changes detected AND forbidden statements present (DROP TABLE, DELETE FROM append-only tables)

**Action on FAIL:**
- 🚫 **BLOCK MERGE** - Exit code 1
- 🚫 Output detailed failure reason
- 🚫 List all modified files
- 🚫 Require explicit approval token in commit message

**CI Output Format:**
```
❌ CI GUARDRAIL FAIL: Schema File Protection
MODIFIED FILES:
  - supabase/schema/DDL_DRAFT.sql
  - migrations/planned/001_tables.sql

REQUIRED: Commit message must contain [SCHEMA-APPROVED] or [APPROVED-STEP12]
ACTUAL: No approval token found

ACTION: Add approval token to commit message and re-push

BLOCKING: This merge is FORBIDDEN until approval is obtained.
```

---

## Guardrail 2: Authority File Protection

**Protected Files:**
- supabase/security/ROLES_AND_RLS.md
- supabase/security/AUTHORITY_ASSERTIONS.md
- migrations/planned/004_roles_rls.sql

**Trigger:** ANY diff detected in protected authority files

**Check Behavior:**

1. **Detect Changes:**
   ```bash
   git diff --name-only origin/main...HEAD | grep -E '^supabase/security/|^migrations/planned/004_roles_rls.sql'
   ```

2. **Validate Approval:**
   - Check commit message for required approval token
   - Required tokens: `[AUTHORITY-APPROVED]` or `[APPROVED-STEP12]`
   - Token MUST be present in commit message body

3. **Validate Integrity:**
   - Role count unchanged (5/5 roles)
   - No GRANT statements for service_role
   - No DROP POLICY for service_role quarantine
   - Deny-first posture preserved (anon/authenticated have 0 grants)
   - RLS enabled on all 10 tables

**PASS Condition:**
- ✅ No changes detected (automatic pass)
- ✅ Changes detected AND commit message includes approval token AND integrity checks pass

**FAIL Condition:**
- ❌ Changes detected AND commit message missing approval token
- ❌ Changes detected AND role count changed
- ❌ Changes detected AND service_role grants detected
- ❌ Changes detected AND RLS disabled on any table
- ❌ Changes detected AND deny-first posture violated

**Action on FAIL:**
- 🚫 **BLOCK MERGE** - Exit code 1
- 🚫 Output detailed failure reason
- 🚫 List all modified files
- 🚫 Require explicit approval token in commit message
- 🚫 CRITICAL: Authority model changes require explicit review

**CI Output Format:**
```
❌ CI GUARDRAIL FAIL: Authority File Protection
MODIFIED FILES:
  - supabase/security/AUTHORITY_ASSERTIONS.md
  - migrations/planned/004_roles_rls.sql

REQUIRED: Commit message must contain [AUTHORITY-APPROVED] or [APPROVED-STEP12]
ACTUAL: No approval token found

INTEGRITY CHECK FAIL:
  - Line 45: GRANT detected on service_role role
  - Line 78: RLS disabled on tools table

ACTION: Fix violations, add approval token, and re-push

BLOCKING: This merge is FORBIDDEN until approval is obtained and violations fixed.
```

---

## Guardrail 3: Execution Boundary Protection

**Protected Files:**
- compose.yaml
- EXECUTION_BOUNDARIES.md
- ENV_VAR_MAPPING.md
- claude-flow/contracts/tool-spec.schema.json

**Trigger:** ANY diff detected in protected boundary files

**Check Behavior:**

1. **Detect Changes:**
   ```bash
   git diff --name-only origin/main...HEAD | grep -E '^compose.yaml|^EXECUTION_BOUNDARIES|^ENV_VAR_MAPPING|^claude-flow/contracts/tool-spec.schema.json'
   ```

2. **Validate Approval:**
   - Check commit message for required approval token
   - Required tokens: `[BOUNDARY-APPROVED]` or `[APPROVED-STEP12]`
   - Token MUST be present in commit message body

3. **Validate Boundary Posture:**
   - compose.yaml: Cloud services still marked as stubs (cloud-stub profile)
   - compose.yaml: Cloud services have failing healthchecks
   - tool-spec.schema.json: adapter_id required for remote tools
   - tool-spec.schema.json: Direct cloud URLs forbidden in credentials_required
   - EXECUTION_BOUNDARIES.md: LOCAL vs CLOUD mapping preserved

**PASS Condition:**
- ✅ No changes detected (automatic pass)
- ✅ Changes detected AND commit message includes approval token AND boundary posture preserved

**FAIL Condition:**
- ❌ Changes detected AND commit message missing approval token
- ❌ Changes detected AND cloud stubs removed from compose.yaml
- ❌ Changes detected AND adapter_id requirement removed
- ❌ Changes detected AND direct cloud URLs allowed in credentials_required
- ❌ Changes detected AND LOCAL vs CLOUD boundary weakened

**Action on FAIL:**
- 🚫 **BLOCK MERGE** - Exit code 1
- 🚫 Output detailed failure reason
- 🚫 List all boundary violations
- 🚫 Require explicit approval token in commit message
- 🚫 CRITICAL: Boundary weakening is IRREVERSIBLE without rollback

**CI Output Format:**
```
❌ CI GUARDRAIL FAIL: Execution Boundary Protection
MODIFIED FILES:
  - compose.yaml
  - claude-flow/contracts/tool-spec.schema.json

REQUIRED: Commit message must contain [BOUNDARY-APPROVED] or [APPROVED-STEP12]
ACTUAL: No approval token found

BOUNDARY VIOLATIONS DETECTED:
  - compose.yaml: Removed cloud-stub profile from qdrant service
  - tool-spec.schema.json: Removed adapter_id requirement for remote tools
  - tool-spec.schema.json: Removed URL pattern validation from credentials_required

ACTION: Restore boundary posture, add approval token, and re-push

BLOCKING: This merge is FORBIDDEN until boundaries are restored.
```

---

## Guardrail 4: Adapter Contract Protection

**Protected Files:**
- supabase/adapters/ADAPTER_CONTRACTS.md
- supabase/adapters/ADAPTER_READINESS.md
- ADAPTER_CONTRACT_ASSERTIONS.md

**Trigger:** ANY diff detected in protected adapter contract files

**Check Behavior:**

1. **Detect Changes:**
   ```bash
   git diff --name-only origin/main...HEAD | grep -E '^supabase/adapters/|^ADAPTER_CONTRACT_ASSERTIONS'
   ```

2. **Validate Approval:**
   - Check commit message for required approval token
   - Required tokens: `[ADAPTER-APPROVED]` or `[APPROVED-STEP12]`
   - Token MUST be present in commit message body

3. **Validate Contract Versioning:**
   - Contract version present in all adapters
   - Breaking changes (adapter_id, operations, failure modes) trigger MAJOR version bump
   - Non-breaking changes trigger MINOR or PATCH version bump
   - Version bump must be documented in commit message

**PASS Condition:**
- ✅ No changes detected (automatic pass)
- ✅ Changes detected AND commit message includes approval token AND versioning rules followed

**FAIL Condition:**
- ❌ Changes detected AND commit message missing approval token
- ❌ Breaking changes detected without MAJOR version bump
- ❌ Contract version removed or downgraded
- ❌ New adapter added without version 1.0.0

**Action on FAIL:**
- 🚫 **BLOCK MERGE** - Exit code 1
- 🚫 Output detailed failure reason
- 🚫 List all contract violations
- 🚫 Require version bump for breaking changes

**CI Output Format:**
```
❌ CI GUARDRAIL FAIL: Adapter Contract Protection
MODIFIED FILES:
  - supabase/adapters/ADAPTER_CONTRACTS.md

REQUIRED: Commit message must contain [ADAPTER-APPROVED] or [APPROVED-STEP12]
ACTUAL: No approval token found

CONTRACT VIOLATIONS DETECTED:
  - toolforge-runrecords: Added DELETE operation (BREAKING CHANGE)
  - supabase-health: Removed timeout_ms field (BREAKING CHANGE)
  - No MAJOR version bump detected (1.0.0 → should be 2.0.0)

ACTION: Fix contract versioning, add approval token, and re-push

BLOCKING: This merge is FORBIDDEN until versioning is corrected.
```

---

## Guardrail 5: Service_Role Quarantine Enforcement

**Protected Scope:**
- .env file (SUPABASE_SERVICE_KEY variable)
- Any code referencing service_role key
- Any adapter using service_role authentication

**Trigger:** ANY of the following detected

**Check Behavior:**

1. **Detect Service_Role Usage:**
   ```bash
   # Check .env for SUPABASE_SERVICE_KEY
   git show origin/main...HEAD:.env | grep -c "^SUPABASE_SERVICE_KEY="
   # Should return 0 (unset or empty)

   # Check code for service_role references
   git diff origin/main...HEAD | grep -i "service_role"
   # Should return 0 (no references)
   ```

2. **Validate Quarantine:**
   - SUPABASE_SERVICE_KEY is unset or empty in .env
   - No code files contain "service_role" string
   - No adapter operations use service_role authentication
   - No workflow JSONs contain service_role references

**PASS Condition:**
- ✅ SUPABASE_SERVICE_KEY is unset or empty
- ✅ No service_role references in code
- ✅ No service_role usage in adapters
- ✅ No service_role usage in workflows

**FAIL Condition:**
- ❌ SUPABASE_SERVICE_KEY is set and non-empty
- ❌ service_role references detected in code
- ❌ service_role usage detected in adapters
- ❌ service_role usage detected in workflows

**Action on FAIL:**
- 🚫 **CRITICAL: BLOCK MERGE** - Exit code 1
- 🚫 **CRITICAL: EMIT SECURITY ALERT**
- 🚫 Output detailed quarantine violation
- 🚫 Require immediate removal of service_role usage
- 🚫 This is a CRITICAL security violation

**CI Output Format:**
```
🚫 CRITICAL CI GUARDRAIL FAIL: Service_Role Quarantine Violation
VIOLATION DETECTED:
  - .env: SUPABASE_SERVICE_KEY is set (should be unset or empty)
  - supabase-health adapter: Line 45 uses service_role for authentication

SERVICE_ROLE QUARANTINE:
  - service_role key is FORBIDDEN in application code
  - service_role bypasses RLS and has unlimited privileges
  - Using service_role creates IRREVERSIBLE security vulnerabilities

ACTION: Remove all service_role usage immediately

BLOCKING: This merge is FORBIDDEN. Security violation must be fixed.
```

---

## Guardrail 6: Precheck Specification Protection

**Protected Files:**
- EXECUTION_PRECHECK_SPEC.md
- SCHEMA_DRIFT_GUARDS.md
- AUTHORITY_DRIFT_GUARDS.md

**Trigger:** ANY diff detected in protected precheck files

**Check Behavior:**

1. **Detect Changes:**
   ```bash
   git diff --name-only origin/main...HEAD | grep -E '^EXECUTION_PRECHECK_SPEC|^SCHEMA_DRIFT_GUARDS|^AUTHORITY_DRIFT_GUARDS'
   ```

2. **Validate Approval:**
   - Check commit message for required approval token
   - Required tokens: `[PRECHECK-APPROVED]` or `[APPROVED-STEP12]`
   - Token MUST be present in commit message body

3. **Validate Precheck Count:**
   - EXECUTION_PRECHECK_SPEC.md: 8 prechecks (no fewer)
   - SCHEMA_DRIFT_GUARDS.md: 6 drift rules (no fewer)
   - AUTHORITY_DRIFT_GUARDS.md: 6 drift rules (no fewer)
   - No precheck removal (additions allowed with approval)

**PASS Condition:**
- ✅ No changes detected (automatic pass)
- ✅ Changes detected AND commit message includes approval token AND precheck count preserved or increased

**FAIL Condition:**
- ❌ Changes detected AND commit message missing approval token
- ❌ Precheck count reduced (weakened detection)
- ❌ Precheck execution order changed
- ❌ STOP conditions removed

**Action on FAIL:**
- 🚫 **BLOCK MERGE** - Exit code 1
- 🚫 Output detailed failure reason
- 🚫 List all removed prechecks or stop conditions
- 🚫 Require explicit approval for any precheck changes

**CI Output Format:**
```
❌ CI GUARDRAIL FAIL: Precheck Specification Protection
MODIFIED FILES:
  - EXECUTION_PRECHECK_SPEC.md

REQUIRED: Commit message must contain [PRECHECK-APPROVED] or [APPROVED-STEP12]
ACTUAL: No approval token found

PRECHECK VIOLATIONS DETECTED:
  - Precheck 4 (Authority Model Verification) removed
  - Precheck count reduced from 8 to 7
  - STOP condition 2 removed

ACTION: Restore precheck count, add approval token, and re-push

BLOCKING: This merge is FORBIDDEN until prechecks are restored.
```

---

## CI Guardrails Summary

**Guardrails Defined:** 6
**Protected Files:** 20+ files across schema, authority, boundaries, adapters, prechecks
**Approval Tokens:** [SCHEMA-APPROVED], [AUTHORITY-APPROVED], [BOUNDARY-APPROVED], [ADAPTER-APPROVED], [PRECHECK-APPROVED], or [APPROVED-STEP12]
**Block Conditions:** All violations block merge with exit code 1

**Key Guarantees:**
- No schema changes without explicit approval
- No authority model changes without explicit approval
- No boundary weakening without explicit approval
- No adapter contract changes without version bump
- No service_role usage (CRITICAL quarantine)
- No precheck removal without approval

**CI Pipeline Flow:**
1. **File Diff Detection** → Identify modified protected files
2. **Approval Token Validation** → Check commit message for approval
3. **Integrity Checks** → Validate invariants (count, posture, versioning)
4. **Pass/Fail Decision** → Pass = merge allowed, Fail = merge blocked
5. **Detailed Output** → Show exactly what failed and why

**Implementation Notes:**

This is DESIGN ONLY. If CI were to be implemented, the pipeline would:

1. Run on every pull request
2. Check all 6 guardrails in parallel
3. Fail fast if any guardrail fails
4. Output detailed failure messages
5. Require fixes before merge can proceed
6. Log all guardrail results for audit

**Example CI Workflow (Pseudo-Code):**
```yaml
# .github/workflows/guardrails.yml (NOT CREATED, DESIGN ONLY)
name: CI Guardrails
on: pull_request
jobs:
  guardrails:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Schema Protection
        run: ./ci/guardrails/check-schema-protection.sh
      - name: Authority Protection
        run: ./ci/guardrails/check-authority-protection.sh
      - name: Boundary Protection
        run: ./ci/guardrails/check-boundary-protection.sh
      - name: Adapter Protection
        run: ./ci/guardrails/check-adapter-protection.sh
      - name: Service_Role Quarantine
        run: ./ci/guardrails/check-service-role-quarantine.sh
      - name: Precheck Protection
        run: ./ci/guardrails/check-precheck-protection.sh
```

**This CI guardrails design is NOT implemented. This document describes what CI SHOULD do if implemented.**

---

## Why CI Guardrails Matter

**Without CI Guardrails:**
- Silent drift through unapproved changes
- Schema modifications without review
- Authority model weakening without detection
- Boundary violations slipping through
- Service_role quarantine violations
- Precheck removal going unnoticed

**With CI Guardrails:**
- All changes to protected files require explicit approval
- Schema integrity enforced automatically
- Authority model preserved through approval checks
- Boundary posture validated on every merge
- Service_role quarantine enforced (CRITICAL)
- Precheck count and order preserved

**CI Guardrails Make Execution Boring:**
- No surprises in merged code
- No silent weakening of invariants
- No hidden security violations
- All changes explicit and approved
- Drift detection automated

**CI Guardrails Make Execution Safe:**
- Changes require explicit approval tokens
- Integrity checks validate all modifications
- Security violations (service_role) blocked immediately
- Boundary weakening detected before merge
- Precheck removal prevented

**CI Guardrails Make Execution Irreversible in the Right Ways:**
- Frozen schema cannot be changed without approval
- Frozen authority model cannot be weakened without approval
- Adapter contracts cannot be broken without version bump
- Service_Role quarantine cannot be bypassed
- Precheck count cannot be reduced without approval

**CI guardrails are the automated enforcement mechanism for all STEP 12 drift detection.**
