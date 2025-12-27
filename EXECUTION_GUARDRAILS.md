# Execution Guardrails

## Purpose
**DEFINITIVE** specification of preconditions and STOP conditions before ANY live execution.

**PRINCIPLE:** Define what must be true before execution, and what must cause an immediate halt.

**Reference:** STEP 10 invariants (data schema, authority model, adapter contracts)

---

## Preconditions for Live Execution

### Category 1: Schema Readiness

**ALL of the following MUST be true before ANY execution:**

1. ✅ **Migration Applied:**
   - DDL_DRAFT.sql has been executed on Supabase
   - All 10 tables exist in database
   - All 29 indexes exist in database
   - All 8 constraints exist in database
   - All 4 RLS policies exist in database

2. ✅ **Schema Verification:**
   - Table structure matches STEP 10 DDL exactly
   - No missing columns
   - No extra columns (unless documented)
   - No missing foreign keys
   - No missing constraints

3. ✅ **No Schema Drift:**
   - DDL_DRAFT.sql is still current (not modified since migration)
   - No manual schema changes in Supabase dashboard
   - No unexpected tables added
   - No unexpected columns added

**If ANY condition is FALSE:**
- 🚫 **CRITICAL: DO NOT EXECUTE**
- 🚫 Schema mismatch detected
- 🚫 Re-run migration or update DDL
- 🚫 Re-verify schema before execution

### Category 2: Authority Model Readiness

**ALL of the following MUST be true:**

1. ✅ **Roles Created:**
   - internal_system role exists
   - future_operator role exists
   - anon role exists (managed by Supabase)
   - authenticated role exists (managed by Supabase)
   - service_role exists (managed by Supabase)

2. ✅ **Privileges Granted:**
   - internal_system has SELECT on all tables
   - internal_system has INSERT on execution tables
   - internal_system has UPDATE on allowed flags
   - future_operator has SELECT on all tables
   - anon has NO grants (deny-first)
   - authenticated has NO grants (deny-first)
   - service_role has NO application-level grants

3. ✅ **RLS Enabled:**
   - RLS is enabled on all 10 tables
   - RLS policies exist for internal_system
   - RLS policies exist for future_operator
   - No policies exist for anon (deny-all)
   - No policies exist for authenticated (deny-all)

4. ✅ **Service_Role Quarantine:**
   - SUPABASE_SERVICE_KEY is unset or empty in .env
   - No code references service_role key
   - No adapter uses service_role key
   - No workflow uses service_role key

**If ANY condition is FALSE:**
- 🚫 **CRITICAL: DO NOT EXECUTE**
- 🚫 Authority model not ready
- 🚫 Re-run roles_rls migration or fix grants
- 🚫 Re-verify authority before execution

### Category 3: Adapter Readiness

**ALL of the following MUST be true:**

1. ✅ **Adapter Contracts Defined:**
   - ADAPTER_CONTRACTS.md exists
   - All 3 adapters have contracts defined
   - All failure modes documented
   - All explicit denials documented

2. ✅ **Adapter Readiness Verified:**
   - ADAPTER_READINESS.md exists
   - SAFE invocation conditions documented
   - UNSAFE invocation conditions documented
   - Preconditions documented for each adapter

3. ✅ **Environment Configuration:**
   - SUPABASE_URL is set and valid
   - SUPABASE_ANON_KEY is set and valid
   - SUPABASE_SERVICE_KEY is unset or empty
   - Credentials can be loaded and validated

4. ✅ **Adapter Connectivity:**
   - supabase-health adapter has been tested
   - Health check returned HTTP 200 OK
   - Authentication successful (ANON_KEY accepted)
   - No boundary violations detected

**If ANY condition is FALSE:**
- 🚫 **CRITICAL: DO NOT EXECUTE**
- 🚫 Adapter not ready
- 🚫 Fix environment configuration
- 🚫 Test adapter connectivity again
- 🚫 Re-verify readiness before execution

### Category 4: Validation Gates

**ALL of the following MUST be true:**

1. ✅ **Validation Gates Implemented:**
   - GATE 1: IntentSpec Intake exists
   - GATE 2: IntentSpec Validation exists
   - GATE 3: ToolSpec Generation exists
   - GATE 4: ToolSpec Validation exists
   - GATE 5: Workflow Compilation exists
   - GATE 6: Tool Registration exists
   - toolforge_fail_and_log exists

2. ✅ **Validation Logic Tested:**
   - All validation gates have been tested
   - Invalid IntentSpec is rejected
   - Invalid ToolSpec is rejected
   - Boundary violations are detected
   - Unsafe tools are rejected

3. ✅ **Invariant Tests Pass:**
   - All 16 invariant tests pass (INVARIANT_VERIFICATION.md)
   - Schema rejects invalid input (3/3 tests)
   - ToolForge refuses unsafe tools (5/5 tests)
   - Adapters were never invoked (4/4 tests)
   - Boundaries held under pressure (4/4 tests)

**If ANY condition is FALSE:**
- 🚫 **CRITICAL: DO NOT EXECUTE**
- 🚫 Validation gates not working
- 🚫 Fix validation logic
- 🚫 Re-test all invariant tests
- 🚫 All tests must pass before execution

### Category 5: Simulation Artifacts

**ALL of the following MUST be true:**

1. ✅ **STEP 8 Simulations Complete:**
   - All 6 fault injection simulations executed
   - All 4 failure simulations verified
   - All 1 degradation simulation verified
   - All 1 dry-run simulation verified

2. ✅ **Failure Proofs Generated:**
   - All failure proof artifacts exist
   - All verification scripts exist
   - All RunRecords emitted
   - All side effects verified as zero

3. ✅ **STOP Conditions Not Triggered:**
   - STOP condition 1 not triggered (no side effects)
   - STOP condition 2 not triggered (validation works)
   - STOP condition 3 not triggered (no adapter invocation)
   - STOP condition 4 not triggered (proofs generated)
   - STOP condition 5 not triggered (invariants hold)
   - STOP condition 6 not triggered (no forbidden conditions)

**If ANY condition is FALSE:**
- 🚫 **CRITICAL: DO NOT EXECUTE**
- 🚫 Simulations incomplete or failed
- 🚫 Re-run failed simulations
- 🚫 Verify all STOP conditions clear
- 🚫 All simulations must pass before execution

### Category 6: RunRecord Infrastructure

**ALL of the following MUST be true:**

1. ✅ **RunRecord Schema Validated:**
   - run-record.schema.json matches database schema
   - All required fields exist
   - All field types match
   - All constraints match

2. ✅ **RunRecord Emission Ready:**
   - RunRecords can be created
   - RunRecords can be stored
   - RunRecord indexing works
   - RunRecord queries work

3. ✅ **Audit Trail Ready:**
   - audit_log table can accept inserts
   - audit_log is append-only (no deletes)
   - audit_log queries work
   - audit_log indexing works

**If ANY condition is FALSE:**
- 🚫 **CRITICAL: DO NOT EXECUTE**
- 🚫 Audit infrastructure not ready
- 🚫 Fix RunRecord or audit_log issues
- 🚷 Verify audit infrastructure before execution

---

## STOP Conditions

### STOP Condition 1: Schema Drift Detected

**TRIGGER: ANY of the following:**

1. ❌ DDL_DRAFT.sql has been modified since migration
2. ❌ Manual schema changes detected in Supabase dashboard
3. ❌ Unexpected tables found in database
4. ❌ Unexpected columns found in tables
5. ❌ Missing tables (DDL_DRAFT.sql says exists, database says no)
6. ❌ Missing columns (DDL_DRAFT.sql says exists, database says no)
7. ❌ Missing indexes
8. ❌ Missing constraints
9. ❌ Missing RLS policies

**ACTION:**
- 🚫 **HALT ALL EXECUTION IMMEDIATELY**
- 🚫 DO NOT execute any tools
- 🚫 DO NOT invoke any adapters
- 🚫 DO NOT perform any writes

**RESOLUTION:**
- Identify source of schema drift
- Re-run migration if needed
- Update DDL_DRAFT.sql if changes are intentional
- Re-verify schema matches DDL
- All preconditions must be re-verified

### STOP Condition 2: Authority Model Violation

**TRIGGER: ANY of the following:**

1. ❌ Roles missing (internal_system, future_operator)
2. ❌ Unexpected grants to anon or authenticated
3. ❌ Unexpected grants to service_role
4. ❌ Missing grants for internal_system
5. ❌ Missing grants for future_operator
6. ❌ RLS disabled on any table
7. ❌ RLS policies missing or incorrect
8. ❌ SUPABASE_SERVICE_KEY set in .env
9. ❌ Code using service_role key

**ACTION:**
- 🚫 **HALT ALL EXECUTION IMMEDIATELY**
- 🚫 DO NOT execute any tools
- 🚫 DO NOT invoke any adapters
- 🚫 DO NOT perform any writes

**RESOLUTION:**
- Fix role grants
- Fix RLS policies
- Remove SUPABASE_SERVICE_KEY from .env
- Remove service_role usage from code
- Re-verify authority model
- All preconditions must be re-verified

### STOP Condition 3: Adapter Not Ready

**TRIGGER: ANY of the following:**

1. ❌ SUPABASE_URL not set or invalid
2. ❌ SUPABASE_ANON_KEY not set or invalid
3. ❌ Adapter contract not defined
4. ❌ Adapter readiness not verified
5. ❌ Health check not performed
6. ❌ Health check failed
7. ❌ Boundary violations detected in adapter

**ACTION:**
- 🚫 **HALT ALL EXECUTION IMMEDIATELY**
- 🚫 DO NOT execute any tools
- 🚫 DO NOT invoke adapters
- 🚫 DO NOT perform any writes

**RESOLUTION:**
- Fix environment configuration
- Define adapter contracts
- Verify adapter readiness
- Test adapter health check
- Fix boundary violations
- Re-verify adapter readiness
- All preconditions must be re-verified

### STOP Condition 4: Validation Gates Failed

**TRIGGER: ANY of the following:**

1. ❌ Validation gate not implemented
2. ❌ Validation gate not tested
3. ❌ Invalid IntentSpec accepted (should be rejected)
4. ❌ Invalid ToolSpec accepted (should be rejected)
5. ❌ Boundary violation accepted (should be rejected)
6. ❌ Invariant test failed

**ACTION:**
- 🚫 **HALT ALL EXECUTION IMMEDIATELY**
- 🚫 DO NOT execute any tools
- 🚫 DO NOT invoke any adapters
- 🚫 DO NOT perform any writes

**RESOLUTION:**
- Fix validation gate logic
- Re-test validation gates
- Re-run all invariant tests
- All 16 invariant tests must pass
- All preconditions must be re-verified

### STOP Condition 5: Simulation Artifacts Missing

**TRIGGER: ANY of the following:**

1. ❌ STEP 8 simulations not executed
2. ❌ Simulation not verified
3. ❌ Failure proof not generated
4. ❌ RunRecord not emitted
5. ❌ Side effects detected in simulation
6. ❌ STOP condition triggered in STEP 8

**ACTION:**
- 🚫 **HALT ALL EXECUTION IMMEDIATELY**
- 🚫 DO NOT proceed to execution
- 🚫 DO NOT invoke any adapters

**RESOLUTION:**
- Complete STEP 8 simulations
- Verify all simulations
- Generate all failure proofs
- Verify zero side effects
- Clear all STOP conditions
- All preconditions must be re-verified

### STOP Condition 6: Audit Infrastructure Not Ready

**TRIGGER: ANY of the following:**

1. ❌ RunRecord schema mismatch
2. ❌ RunRecord cannot be created
3. ❌ RunRecord cannot be stored
4. ❌ audit_log cannot accept inserts
5. ❌ audit_log has deletes (append-only violated)
6. ❌ audit_log queries failing

**ACTION:**
- 🚫 **HALT ALL EXECUTION IMMEDIATELY**
- 🚫 DO NOT execute any tools
- 🚫 NO audit trail = NO execution

**RESOLUTION:**
- Fix RunRecord schema
- Fix RunRecord emission
- Fix audit_log append-only
- Verify audit infrastructure
- All preconditions must be re-verified

### STOP Condition 7: Unsafe Operation Detected

**TRIGGER: ANY of the following:**

1. ❌ Attempting DELETE operation
2. ❌ Attempting UPDATE on immutable table
3. ❌ Attempting operation with service_role
4. ❌ Attempting operation outside adapter contracts
5. ❌ Attempting to bypass validation gates
6. ❌ Attempting to modify RLS policies
7. ❌ Attempting DDL operation

**ACTION:**
- 🚫 **CRITICAL: HALT IMMEDIATELY**
- 🚫 This is a safety violation
- 🚫 Operation is FORBIDDEN
- 🚫 Emit CRITICAL RunRecord

**RESOLUTION:**
- Identify why unsafe operation was attempted
- Fix validation logic (should have blocked it)
- Fix client-side checks
- Review adapter contracts
- Re-verify all preconditions
- Explicit approval required to proceed

---

## Pre-Execution Checklist

**Before ANY live execution, verify:**

### Schema
- [ ] Migration applied (DDL_DRAFT.sql)
- [ ] All tables exist (10/10)
- [ ] All indexes exist (29/29)
- [ ] All constraints exist (8/8)
- [ ] All RLS policies exist (on all tables)
- [ ] No schema drift detected

### Authority
- [ ] All roles exist (5/5)
- [ ] All privileges granted correctly
- [ ] RLS enabled on all tables
- [ ] service_role has NO grants
- [ ] SUPABASE_SERVICE_KEY is unset

### Adapters
- [ ] Adapter contracts defined
- [ ] Adapter readiness documented
- [ ] Environment variables set
- [ ] Health check passed
- [ ] No boundary violations

### Validation
- [ ] All 6 validation gates implemented
- [ ] All validation gates tested
- [ ] All 16 invariant tests pass

### Simulations
- [ ] All 6 STEP 8 simulations complete
- [ ] All failure proofs generated
- [ ] All STOP conditions clear

### Audit
- [ ] RunRecord schema validated
- [ ] RunRecord emission works
- [ ] audit_log append-only verified

### Safety
- [ ] No unsafe operations detected
- [ ] No boundary violations
- [ ] No service_role usage
- [ ] No DDL operations attempted

**If ALL checkboxes are checked:**
- ✅ **SAFE TO PROCEED WITH EXECUTION**

**If ANY checkbox is unchecked:**
- 🚫 **DO NOT EXECUTE**
- 🚫 Fix failed precondition
- 🚫 Re-verify all preconditions

---

## Runtime Halt Conditions

**HALT IMMEDIATELY if ANY of these occur during execution:**

1. 🚫 Schema mismatch error (table or column does not exist)
2. 🚫 Permission denied error (unexpected auth failure)
3. 🚫 Constraint violation error (data validation failed)
4. 🚫 Service role usage detected (CRITICAL)
5. 🚫 DELETE operation detected (CRITICAL)
6. 🚫 UPDATE on immutable table detected (CRITICAL)
7. 🚫 DDL operation detected (CRITICAL)
8. 🚫 RLS policy bypass detected (CRITICAL)
9. 🚫 Validation gate bypass detected (CRITICAL)
10. 🚫 Adapter contract violation detected (CRITICAL)

**When halt condition triggered:**

1. **STOP operation immediately**
2. **Emit CRITICAL RunRecord**
3. **Log all context**
4. **Preserve all state**
5. **Alert operator**
6. **DO NOT retry automatically**

---

## Summary

**Preconditions:** 6 categories, 40+ individual checks
**STOP Conditions:** 7 critical halt triggers
**Runtime Halts:** 10 immediate stop conditions
**Verification:** All must pass before execution

**Key Principles:**
- Schema must match DDL exactly
- Authority model must be deny-first
- Adapters must be verified ready
- Validation gates must pass
- Simulations must complete
- Audit infrastructure must work

**Enforcement:**
- Pre-execution checklist required
- All violations emit CRITICAL RunRecords
- All halts require operator intervention
- No automatic recovery from violations

**Execution is FORBIDDEN until ALL preconditions are met and NO STOP conditions are active.**
