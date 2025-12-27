# Execution Precheck Specification

## Purpose
**DEFINITIVE** ordered checklist that MUST pass before migrations, n8n enablement, or adapter activation.

**PRINCIPLE:** Fail-fast verification prevents execution in unvalidated or unsafe environments.

---

## Precheck Overview

**This precheck specification defines:**
- Ordered checks (must execute in sequence)
- Input requirements for each check
- Conditions that determine PASS vs FAIL
- Failure classifications (CRITICAL / STOP)
- Required actions for each failure

**When to Run:**
- Before ANY migration execution
- Before n8n workflow enablement
- Before adapter activation
- Before ANY tool execution

**Execution Order:**
Checks MUST be executed in the order specified below. Any FAIL halts subsequent checks.

---

## Precheck 1: File Integrity Verification

**Purpose:** Verify all STEP 10 design files are present and unmodified.

**Inputs:**
- File system (local repository)
- Git history (frozen commits)

**Check:**

1. **Required Files Exist:**
   - supabase/schema/DDL_DRAFT.sql
   - supabase/security/ROLES_AND_RLS.md
   - supabase/adapters/ADAPTER_CONTRACTS.md
   - migrations/planned/001_tables.sql
   - migrations/planned/002_indexes.sql
   - migrations/planned/003_constraints.sql
   - migrations/planned/004_roles_rls.sql

2. **File Contents Unmodified:**
   - Git diff shows NO changes to STEP 10 files
   - No files modified since STEP 10 commit
   - No uncommitted changes

**PASS Condition:**
- ✅ All 10 files exist
- ✅ Git shows no modifications to STEP 10 files
- ✅ Working tree is clean (except STEP 11/12 files)

**FAIL Condition:**
- ❌ Any required file missing
- ❌ Any STEP 10 file modified
- ❌ Uncommitted changes to STEP 10 files

**Classification:** CRITICAL

**Action on FAIL:**
- 🚫 HALT all execution
- 🚫 Identify modified file
- 🚫 Revert to STEP 10 state or document changes
- 🚫 Re-verify all prechecks

**Command:**
```bash
# Check file existence
ls -la supabase/schema/DDL_DRAFT.sql supabase/security/ROLES_AND_RLS.md supabase/adapters/ADAPTER_CONTRACTS.md

# Check for modifications
git diff --quiet supabase/schema/ supabase/security/ supabase/adapters/
# Exit code 0 = no changes (PASS)
# Exit code 1 = changes detected (FAIL)
```

---

## Precheck 2: Environment Variable Verification

**Purpose:** Verify required environment variables are present and valid.

**Inputs:**
- .env file
- Environment variables in current shell

**Check:**

1. **Required Variables Present:**
   - SUPABASE_URL is set
   - SUPABASE_ANON_KEY is set
   - Variables are not empty
   - Variables match expected format

2. **Forbidden Variables Absent:**
   - SUPABASE_SERVICE_KEY is unset or empty
   - No service_role key references in code

3. **Variable Format Validation:**
   - SUPABASE_URL is valid HTTPS URL
   - SUPABASE_ANON_KEY is valid JWT format (starts with "eyJ")

**PASS Condition:**
- ✅ SUPABASE_URL set and valid
- ✅ SUPABASE_ANON_KEY set and valid
- ✅ SUPABASE_SERVICE_KEY unset or empty
- ✅ No format validation errors

**FAIL Condition:**
- ❌ SUPABASE_URL missing or invalid
- ❌ SUPABASE_ANON_KEY missing or invalid
- ❌ SUPABASE_SERVICE_KEY set (quarantine violation)

**Classification:** CRITICAL

**Action on FAIL:**
- 🚫 HALT all execution
- 🚫 Fix environment configuration
- 🚫 Re-verify all prechecks

**Command:**
```bash
# Check variables
grep -E "^(SUPABASE_URL|SUPABASE_ANON_KEY)=" .env | wc -l
# Should return 2 (both set)

# Check service_role is NOT set
grep -c "^SUPABASE_SERVICE_KEY=" .env || echo "0"
# Should return 0 (unset or empty)

# Validate URL format
grep "^SUPABASE_URL=https://" .env
# Should return match

# Validate JWT format
grep "^SUPABASE_ANON_KEY=eyJ" .env
# Should return match
```

---

## Precheck 3: Schema Drift Detection

**Purpose:** Verify database schema matches frozen DDL (STEP 10).

**Inputs:**
- Supabase database (read-only connection)
- DDL_DRAFT.sql reference

**Check:**

1. **Table Existence:** All 10 tables exist in database
2. **Column Existence:** All columns exist with correct types
3. **Index Existence:** All 29 indexes exist
4. **Constraint Existence:** All 8 constraints exist
5. **RLS Status:** RLS enabled on all 10 tables
6. **RLS Policies:** All 24 policies exist

**Reference:** SCHEMA_DRIFT_GUARDS.md for detailed rules.

**PASS Condition:**
- ✅ All 10 tables exist
- ✅ All columns match DDL exactly
- ✅ All indexes exist
- ✅ All constraints exist
- ✅ RLS enabled on all tables
- ✅ All RLS policies exist
- ✅ No extra tables, columns, indexes, constraints, or policies

**FAIL Condition:**
- ❌ Any table missing
- ❌ Any column missing, extra, or wrong type
- ❌ Any index missing
- ❌ Any constraint missing
- ❌ RLS disabled on any table
- ❌ Any RLS policy missing or extra

**Classification:** CRITICAL

**Action on FAIL:**
- 🚫 HALT all execution
- 🚫 Run migrations if schema not applied
- 🚫 Fix schema drift if detected
- 🚫 Re-verify all prechecks

**Command:**
```bash
# Run schema drift detection queries (from SCHEMA_DRIFT_GUARDS.md)
# Queries should return 0 rows (no drift)
# Any rows returned = FAIL
```

---

## Precheck 4: Authority Model Verification

**Purpose:** Verify roles, grants, and RLS match frozen authority model (STEP 10).

**Inputs:**
- Supabase database (read-only connection)
- AUTHORITY_ASSERTIONS.md reference

**Check:**

1. **Role Existence:** All 5 roles exist
2. **Grant Verification:** All grants match expected state
3. **RLS Policy Verification:** All 24 policies exist
4. **Service_Role Quarantine:** service_role has 0 grants
5. **Deny-First Posture:** anon and authenticated have 0 policies

**Reference:** AUTHORITY_DRIFT_GUARDS.md for detailed rules.

**PASS Condition:**
- ✅ All 5 roles exist
- ✅ All grants match AUTHORITY_ASSERTIONS.md
- ✅ All RLS policies exist
- ✅ service_role has 0 grants
- ✅ anon has 0 grants and 0 policies
- ✅ authenticated has 0 grants and 0 policies
- ✅ No extra roles, grants, or policies

**FAIL Condition:**
- ❌ Any role missing
- ❌ Any grant missing or extra
- ❌ Any RLS policy missing or extra
- ❌ service_role has any grants
- ❌ anon or authenticated have access

**Classification:** CRITICAL

**Action on FAIL:**
- 🚫 HALT all execution
- 🚫 Run roles_rls migration if needed
- 🚫 Fix authority drift if detected
- 🚫 Re-verify all prechecks

**Command:**
```bash
# Run authority drift detection queries (from AUTHORITY_DRIFT_GUARDS.md)
# Queries should return 0 rows (no drift)
# Any rows returned = FAIL
```

---

## Precheck 5: Adapter Contract Verification

**Purpose:** Verify ToolSpec → Adapter mappings are valid.

**Inputs:**
- Tool registry (registered tools)
- ADAPTER_CONTRACTS.md reference
- ADAPTER_READINESS.md reference

**Check:**

1. **Contract File Integrity:** ADAPTER_CONTRACTS.md unmodified since STEP 10
2. **Contract Version:** All adapters at version 1.0.0 (or compatible)
3. **Adapter Registry:** All registered ToolSpecs have valid adapter_id
4. **Operation Validity:** All adapter_operation values are valid
5. **Mapping Invariants:** All ToolSpecs satisfy mapping rules

**Reference:** ADAPTER_CONTRACT_ASSERTIONS.md for detailed assertions.

**PASS Condition:**
- ✅ ADAPTER_CONTRACTS.md matches frozen state (or version bumped)
- ✅ All ToolSpecs reference valid adapters
- ✅ All ToolSpecs reference valid operations
- ✅ All ToolSpecs have compatible contract versions
- ✅ No breaking changes detected

**FAIL Condition:**
- ❌ ADAPTER_CONTRACTS.md modified without version bump
- ❌ Any ToolSpec references invalid adapter
- ❌ Any ToolSpec references invalid operation
- ❌ Any ToolSpec has incompatible contract version
- ❌ Breaking changes detected

**Classification:** ERROR

**Action on FAIL:**
- 🚫 HALT all execution
- 🚫 Update affected ToolSpecs
- 🚫 Re-validate all prechecks

**Command:**
```bash
# Check adapter contract file integrity
git diff --quiet supabase/adapters/ADAPTER_CONTRACTS.md
# Exit code 0 = no changes (PASS)
# Exit code 1 = changes detected (verify version bump)

# Validate ToolSpecs in registry
# (Query tool registry for adapter mappings)
# Verify all adapter_ids exist in ADAPTER_CONTRACTS.md
# Verify all adapter_operations are valid for their adapters
```

---

## Precheck 6: Validation Gates Verification

**Purpose:** Verify all validation gates are implemented and tested.

**Inputs:**
- n8n workflow files (read-only)
- INVARIANT_VERIFICATION.md reference

**Check:**

1. **Gate Implementation:** All 6 validation gates exist
2. **Gate Testing:** All gates have been tested
3. **Invariant Tests:** All 16 invariant tests pass
4. **Simulation Results:** STEP 8 simulations all pass

**Reference:** INVARIANT_VERIFICATION.md, STEP 8 artifacts.

**PASS Condition:**
- ✅ GATE 1: IntentSpec Intake exists
- ✅ GATE 2: IntentSpec Validation exists
- ✅ GATE 3: ToolSpec Generation exists
- ✅ GATE 4: ToolSpec Validation exists
- ✅ GATE 5: Workflow Compilation exists
- ✅ GATE 6: Tool Registration exists
- ✅ All 16 invariant tests pass
- ✅ All STEP 8 simulations verified

**FAIL Condition:**
- ❌ Any validation gate missing
- ❌ Any gate not tested
- ❌ Any invariant test fails
- ❌ Any STEP 8 simulation fails

**Classification:** ERROR

**Action on FAIL:**
- 🚫 HALT all execution
- 🚫 Implement missing gates
- 🚫 Fix failing tests
- 🚫 Re-run simulations

**Command:**
```bash
# Check validation gate files exist
ls -la n8n/toolforge/workflows/toolforge_*.json

# Run invariant tests
bash verify-invariants.sh
# Should return exit code 0 (all pass)

# Verify STEP 8 simulations
# (Check simulation reports for all pass status)
```

---

## Precheck 7: Migration Plan Verification

**Purpose:** Verify migration plan is ready and rollback strategy is tested.

**Inputs:**
- Migration files (migrations/planned/)
- Rollback documentation

**Check:**

1. **Migration Files Ready:** All 4 migration files exist
2. **Rollback Strategy:** Rollback commands documented
3. **Backup Verification:** Database backup exists (if migration already applied)

**PASS Condition:**
- ✅ 001_tables.sql exists and is valid SQL
- ✅ 002_indexes.sql exists and is valid SQL
- ✅ 003_constraints.sql exists and is valid SQL
- ✅ 004_roles_rls.sql exists and is valid SQL
- ✅ Rollback commands documented in each file
- ✅ SQL syntax validated (no parse errors)

**FAIL Condition:**
- ❌ Any migration file missing
- ❌ Any migration file has syntax error
- ❌ Rollback strategy not documented

**Classification:** ERROR

**Action on FAIL:**
- 🚫 HALT all execution
- 🚫 Fix migration files
- 🚫 Document rollback strategy
- 🚫 Re-verify all prechecks

**Command:**
```bash
# Verify migration files exist
ls -la migrations/planned/*.sql

# Validate SQL syntax (using a SQL parser)
# (No actual execution)
```

---

## Precheck 8: Audit Infrastructure Verification

**Purpose:** Verify audit infrastructure is ready to record execution.

**Inputs:**
- Database schema (read-only connection)
- RunRecord schema reference

**Check:**

1. **RunRecord Tables:** run_records table exists and is accessible
2. **Audit Log Tables:** audit_log table exists and is accessible
3. **Insert Permissions:** internal_system role has INSERT grants
4. **Append-Only:** No DELETE grants on append-only tables

**PASS Condition:**
- ✅ run_records table exists
- ✅ audit_log table exists
- ✅ internal_system has INSERT on both tables
- ✅ No DELETE grants on append-only tables

**FAIL Condition:**
- ❌ run_records table missing
- ❌ audit_log table missing
- ❌ internal_system lacks INSERT grants
- ❌ DELETE grants detected on append-only tables

**Classification:** CRITICAL

**Action on FAIL:**
- 🚫 HALT all execution
- 🚫 Run migrations if tables missing
- 🚫 Fix grants if permissions wrong
- 🚫 Re-verify all prechecks

**Command:**
```bash
# Check tables exist
# (Query database for run_records, audit_log tables)

# Check permissions
# (Query information_schema.role_table_grants for INSERT grants)
```

---

## Precheck Execution Order

**Prechecks MUST execute in this order:**

1. **File Integrity Verification** - Verify design files present
2. **Environment Variable Verification** - Verify configuration
3. **Schema Drift Detection** - Verify database schema
4. **Authority Model Verification** - Verify roles/RLS
5. **Adapter Contract Verification** - Verify ToolSpec mappings
6. **Validation Gates Verification** - Verify validation logic
7. **Migration Plan Verification** - Verify migration files
8. **Audit Infrastructure Verification** - Verify audit tables

**Stop Condition:**
- ANY precheck FAIL → HALT immediately
- Do not execute subsequent prechecks
- Fix failed precheck
- Re-run all prechecks from beginning

---

## Precheck Response Summary

**On PASS (All 8 prechecks pass):**
- ✅ Environment is validated
- ✅ Schema matches frozen state
- ✅ Authority model matches frozen state
- ✅ Adapters are ready
- ✅ Validation gates are working
- ✅ Audit infrastructure is ready
- **SAFE TO PROCEED WITH NEXT STEP**

**On FAIL (Any precheck fails):**
- ❌ Environment is not ready
- ❌ Schema drift detected
- ❌ Authority drift detected
- ❌ Adapters not ready
- ❌ Validation not working
- ❌ Audit infrastructure not ready
- **DO NOT PROCEED**
- **FIX FAILURES**
- **RE-RUN ALL PRECHECKS**

---

## Summary

**Prechecks Defined:** 8
**Execution Order:** Fixed sequence (1-8)
**Classifications:** CRITICAL, ERROR
**Stop Condition:** Any FAIL halts subsequent checks

**Key Guarantees:**
- Prechecks execute in fixed order
- Any FAIL triggers immediate halt
- All prechecks must pass before execution
- Failed prechecks must be fixed before retry
- All fixes require re-running all prechecks

**Execution is FORBIDDEN until ALL prechecks PASS.**
