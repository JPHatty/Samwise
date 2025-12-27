# Authority Drift Guards

## Purpose
**DEFINITIVE** specification of how to detect authority model drift BEFORE any execution.

**PRINCIPLE:** Silent authority model changes (roles, grants, RLS) are prevented through explicit verification.

**Reference:** STEP 10 - supabase/security/ROLES_AND_RLS.md, AUTHORITY_ASSERTIONS.md

---

## What Is Authority Drift?

**Authority Drift:** Any difference between the frozen authority model (STEP 10) and the actual database state.

**Types of Drift:**
1. **Role Drift:** Roles missing, extra roles added, role properties changed
2. **Grant Drift:** Privileges granted outside approved list, privileges revoked
3. **RLS Policy Drift:** Policies missing, extra policies added, policy commands changed
4. **Service_Role Violation:** service_role granted privileges it shouldn't have
5. **Deny-First Violation:** anon or authenticated granted access
6. **Privilege Escalation:** future_operator granted write privileges

**Why Authority Drift is Dangerous:**
- Security bypasses (unauthorized access to sensitive data)
- Audit trail compromise (append-only violated)
- Privilege escalation (roles exceed their defined boundaries)
- Silent failures (application expects certain grants)
- Irreversible changes (grants are hard to track)

---

## Authority Drift Detection Rules

### Rule 1: Role Existence Verification

**Check:** Verify exactly 5 roles exist with correct properties.

**Expected Roles (5):**
1. **anon** - Managed by Supabase (no CREATE ROLE statement)
2. **authenticated** - Managed by Supabase (no CREATE ROLE statement)
3. **service_role** - Managed by Supabase (no CREATE ROLE statement)
4. **internal_system** - Created by 004_roles_rls.sql
5. **future_operator** - Created by 004_roles_rls.sql

**Expected Role Properties:**
- anon: NOLOGIN (managed by Supabase), NO grants
- authenticated: NOLOGIN (managed by Supabase), NO grants
- service_role: NOLOGIN (managed by Supabase), NO application-level grants
- internal_system: NOLOGIN, specific SELECT/INSERT/UPDATE grants
- future_operator: NOLOGIN, SELECT-only grants

**PASS Condition:**
- ✅ All 5 roles exist
- ✅ No extra roles exist (outside Supabase managed roles)
- ✅ internal_system has NOLOGIN attribute
- ✅ future_operator has NOLOGIN attribute

**FAIL Condition:**
- ❌ Missing role (DDL defines it, database doesn't have it)
- ❌ Extra role (database has role not in DDL)
- ❌ Role has LOGIN attribute (security risk)
- ❌ Role properties mismatch (different attributes than expected)

**Example FAIL:**
```sql
-- Expected:
internal_system: NOLOGIN, specific grants

-- Database has:
-- internal_system: LOGIN (can connect to database)
-- Result: FAIL - Role can login directly (security risk)
```

**Detection Method:**
```sql
SELECT
  rolname,
  rolcanlogin,
  rolsuper
FROM pg_roles
WHERE rolname IN ('anon', 'authenticated', 'service_role', 'internal_system', 'future_operator')
ORDER BY rolname;

-- Verify:
-- - All 5 roles exist
-- - All have rolcanlogin = false (NOLOGIN)
-- - None have rolsuper = true
```

---

### Rule 2: Grant Verification

**Check:** Verify all grants match AUTHORITY_ASSERTIONS.md exactly.

**Expected Grants for internal_system:**

**Schema Grants:**
- ✅ USAGE on schema public
- ✅ SELECT on all tables (10 tables)
- ✅ INSERT on execution tables (run_records, run_artifacts, audit_log, validation_log, adapter_events, execution_stats)
- ✅ UPDATE on allowed flags only (tools.is_active, run_artifacts.rolled_back, adapters.health_status)

**Expected Grants for future_operator:**

**Schema Grants:**
- ✅ USAGE on schema public
- ✅ SELECT on all tables (10 tables)

**Expected Grants for anon:**
- ❌ NONE (deny-first posture)

**Expected Grants for authenticated:**
- ❌ NONE (deny-first posture)

**Expected Grants for service_role:**
- ❌ NONE (forbidden in application code)

**PASS Condition:**
- ✅ internal_system has exactly 11 grants (1 USAGE + 10 SELECT + 6 INSERT + 3 UPDATE)
- ✅ future_operator has exactly 11 grants (1 USAGE + 10 SELECT)
- ✅ anon has 0 grants (deny-all)
- ✅ authenticated has 0 grants (deny-all)
- ✅ service_role has 0 application-level grants (forbidden)

**FAIL Condition:**
- ❌ Missing grant (DDL defines it, database doesn't have it)
- ❌ Extra grant (database has grant not in DDL)
- ❌ Grant on wrong object (wrong table, wrong schema)
- ❌ Grant for forbidden operation (DELETE, UPDATE on immutable columns)

**Example FAIL:**
```sql
-- Expected:
-- internal_system: SELECT on all tables, INSERT on execution tables

-- Database has:
-- internal_system: DELETE on audit_log (FORBIDDEN)
-- Result: FAIL - Internal system can delete audit logs (security bypass)
```

**Detection Method:**
```sql
-- Check grants for internal_system
SELECT
  grantee,
  table_schema,
  table_name,
  privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'internal_system'
  AND table_schema = 'public'
ORDER BY table_name, privilege_type;

-- Should return:
-- grantee        | table_schema | table_name         | privilege_type
-- ---------------+--------------+--------------------+----------------
-- internal_system| public       | tools              | SELECT
-- internal_system| public       | tool_versions       | SELECT
-- internal_system| public       | run_records        | SELECT
-- internal_system| public       | run_records        | INSERT
-- internal_system| public       | run_artifacts      | SELECT
-- internal_system| public       | run_artifacts      | INSERT
-- ... (total 11 grants)

-- Any DELETE privilege = FAIL
-- Any INSERT on immutable table = FAIL
-- Any UPDATE on non-flag column = FAIL
```

---

### Rule 3: RLS Policy Verification

**Check:** Verify RLS policies match 004_roles_rls.sql exactly.

**Expected Policies:**
- 20 policies on core tables (2 per table: internal_system + future_operator)
- 4 policies on tool_versions (2 policies)
- Total: 24 policies

**Expected Policy Structure:**
- All tables have policies for internal_system (FOR ALL USING (true) WITH CHECK (true))
- All tables have policies for future_operator (FOR SELECT USING (true))
- No policies for anon (implicit deny-all)
- No policies for authenticated (implicit deny-all)

**PASS Condition:**
- ✅ All 10 tables have RLS enabled
- ✅ All 10 tables have internal_system policy
- ✅ All 10 tables have future_operator SELECT policy
- ✅ tool_versions has 2 policies
- ✅ No policies for anon
- ✅ No policies for authenticated

**FAIL Condition:**
- ❌ RLS not enabled on a table
- ❌ Missing policy (DDL defines it, database doesn't have it)
- ❌ Extra policy (database has policy not in DDL)
- ❌ Policy for anon or authenticated (deny-first violated)
- ❌ Policy command mismatch (different USING clause)

**Example FAIL:**
```sql
-- Expected:
-- All tables have RLS enabled, internal_system policies exist

-- Database has:
-- run_records: RLS disabled (rowsecurity = false)
-- Result: FAIL - RLS bypass possible on run_records (security breach)
```

**Detection Method:**
```sql
-- Check RLS enabled
SELECT
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'tools', 'tool_versions', 'run_records', 'run_artifacts',
    'intents', 'audit_log', 'validation_log', 'adapters',
    'adapter_events', 'execution_stats'
  )
ORDER BY tablename;

-- Should return 10 rows, all with rowsecurity = true

-- Check RLS policies
SELECT
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Should return:
-- - 2 policies per table (internal_system, future_operator)
-- - 20 policies total
-- - No policies for anon or authenticated
```

---

### Rule 4: Service_Role Violation Detection

**Check:** Verify service_role has NO application-level grants.

**Expected State:**
- service_role exists (managed by Supabase)
- service_role has NO GRANT statements for application tables
- service_role has NO USAGE grant on schema public
- service_role has NO SELECT, INSERT, UPDATE, DELETE privileges

**FORBIDDEN State:**
- service_role has SELECT on any table
- service_role has INSERT on any table
- service_role has UPDATE on any table
- service_role has DELETE on any table
- service_role has USAGE on schema public

**PASS Condition:**
- ✅ service_role exists (required by Supabase)
- ✅ service_role has 0 grants on application tables
- ✅ service_role has 0 grants on schema public

**FAIL Condition:**
- ❌ service_role has ANY grant on application tables
- ❌ service_role has USAGE on schema public
- ❌ Code uses service_role key (check .env file)

**Example FAIL:**
```sql
-- Expected:
-- service_role: NO grants (forbidden in application code)

-- Database has:
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO service_role;
-- Result: CRITICAL FAIL - Service role can read all data (quarantine violated)
```

**Detection Method:**
```sql
-- Check for service_role grants
SELECT
  grantee,
  table_schema,
  table_name,
  privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'service_role'
  AND table_schema = 'public';

-- Should return 0 rows
-- Any rows = CRITICAL FAIL

-- Check .env file
grep -c "^SUPABASE_SERVICE_KEY=" .env
-- Should return 0 (unset or empty)
-- Any non-zero = CRITICAL FAIL
```

**CRITICAL RESPONSE:**
If service_role violation is detected:
- 🚫 **CRITICAL: HALT ALL OPERATIONS IMMEDIATELY**
- 🚫 Emit CRITICAL RunRecord
- 🚫 Revoke all service_role grants
- 🚫 Remove SUPABASE_SERVICE_KEY from .env
- 🚫 Review all audit logs for service_role usage

---

### Rule 5: Deny-First Violation Detection

**Check:** Verify anon and authenticated have NO access (deny-first posture).

**Expected State:**
- anon: 0 policies (implicit deny-all)
- authenticated: 0 policies (implicit deny-all)
- anon: 0 grants (implicit deny-all)
- authenticated: 0 grants (implicit deny-all)

**FORBIDDEN State:**
- anon has SELECT grant on any table
- anon has policy on any table
- authenticated has SELECT grant on any table
- authenticated has policy on any table

**PASS Condition:**
- ✅ anon has 0 grants on application tables
- ✅ anon has 0 policies on application tables
- ✅ authenticated has 0 grants on application tables
- ✅ authenticated has 0 policies on application tables

**FAIL Condition:**
- ❌ anon has ANY grant on application tables
- ❌ anon has ANY policy on application tables
- ❌ authenticated has ANY grant on application tables
- ❌ authenticated has ANY policy on application tables

**Example FAIL:**
```sql
-- Expected:
-- anon: 0 grants, 0 policies (deny-all)

-- Database has:
-- CREATE POLICY "anon_select_tools" ON tools
--   FOR SELECT TO anon USING (true);
-- Result: FAIL - Deny-first posture violated (public access granted)
```

**Detection Method:**
```sql
-- Check for anon grants
SELECT COUNT(*) AS anon_grants
FROM information_schema.role_table_grants
WHERE grantee = 'anon'
  AND table_schema = 'public';

-- Should return 0

-- Check for anon policies
SELECT COUNT(*) AS anon_policies
FROM pg_policies
WHERE 'anon' = ANY(roles)
  AND schemaname = 'public';

-- Should return 0

-- Repeat for authenticated role
```

---

### Rule 6: Privilege Escalation Detection

**Check:** Verify future_operator has read-only access only.

**Expected State:**
- future_operator: SELECT on all tables (read-only)
- future_operator: NO INSERT grants
- future_operator: NO UPDATE grants
- future_operator: NO DELETE grants

**FORBIDDEN State:**
- future_operator has INSERT on any table
- future_operator has UPDATE on any table
- future_operator has DELETE on any table
- future_operator has USAGE on schema sequences

**PASS Condition:**
- ✅ future_operator has SELECT on all tables (10 grants)
- ✅ future_operator has 0 INSERT grants
- ✅ future_operator has 0 UPDATE grants
- ✅ future_operator has 0 DELETE grants

**FAIL Condition:**
- ❌ future_operator has INSERT grant on any table
- ❌ future_operator has UPDATE grant on any table
- ❌ future_operator has DELETE grant on any table
- ❌ future_operator has write capability

**Example FAIL:**
```sql
-- Expected:
-- future_operator: SELECT only (read-only monitoring)

-- Database has:
-- GRANT INSERT ON run_records TO future_operator;
-- Result: FAIL - Future operator can write to run_records (privilege escalation)
```

**Detection Method:**
```sql
SELECT
  grantee,
  table_name,
  privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'future_operator'
  AND table_schema = 'public'
  AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE')
ORDER BY table_name, privilege_type;

-- Should return 0 rows
-- Any rows = FAIL (privilege escalation)
```

---

## Authority Drift Detection Examples

### Example 1: PASS - No Drift

**Expected State:**
- internal_system: SELECT on all tables, INSERT on execution tables
- future_operator: SELECT on all tables
- anon: 0 grants
- authenticated: 0 grants
- service_role: 0 grants

**Database State:** Matches expected state exactly

**Result:** ✅ PASS - Authority model matches STEP 10

---

### Example 2: FAIL - Extra Grant

**Expected State:**
- internal_system: SELECT on tools, INSERT on run_records

**Database State:**
- internal_system: SELECT on tools, INSERT on run_records
- internal_system: **DELETE on audit_log** (EXTRA GRANT)

**Result:** ❌ FAIL - Extra grant detected (internal_system can delete audit logs)

**Classification:** CRITICAL
**Impact:** Audit trail compromise, data loss
**Action:** Revoke extra grant immediately

---

### Example 3: FAIL - Missing Grant

**Expected State:**
- internal_system: INSERT on execution_stats

**Database State:**
- internal_system: **Missing INSERT grant** on execution_stats

**Result:** ❌ FAIL - Missing grant (adapter cannot write execution stats)

**Classification:** ERROR
**Impact:** Adapter failure, RunRecord incomplete
**Action:** Re-run roles_rls migration

---

### Example 4: FAIL - RLS Disabled

**Expected State:**
- All tables: RLS enabled (rowsecurity = true)

**Database State:**
- tools: **rowsecurity = false** (RLS disabled)

**Result:** ❌ FAIL - RLS disabled on tools table

**Classification:** CRITICAL
**Impact:** Security bypass, unauthorized access
**Action:** Enable RLS immediately

---

### Example 5: FAIL - Service_Role Violation

**Expected State:**
- service_role: 0 grants (forbidden)

**Database State:**
- service_role: **SELECT on all tables** (via direct GRANT)

**Result:** 🚫 CRITICAL FAIL - Service role quarantine violated

**Classification:** CRITICAL
**Impact:** Quarantine breached, unlimited access
**Action:** Revoke all grants immediately, investigate breach

---

### Example 6: FAIL - Deny-First Violation

**Expected State:**
- anon: 0 policies (implicit deny-all)

**Database State:**
- anon: **Policy exists on tools table**

**Result:** ❌ FAIL - Deny-first posture violated (public access)

**Classification:** ERROR
**Impact:** Unauthorized public access
**Action:** Drop anon policy immediately

---

## Authority Drift Detection Procedure

### Pre-Execution Check

**Before ANY execution (migration, adapter call, tool execution):**

1. **Extract Expected Authority:**
   - Parse AUTHORITY_ASSERTIONS.md for role definitions
   - Parse ROLES_AND_RLS.md for RLS policies
   - Parse 004_roles_rls.sql for grant statements

2. **Query Database Authority:**
   - Query pg_roles for role list
   - Query information_schema.role_table_grants for grants
   - Query pg_policies for RLS policies
   - Query pg_tables for RLS status

3. **Compare Authority States:**
   - Role list: Expected vs database
   - Grant list: Expected vs database
   - RLS policy list: Expected vs database
   - RLS enabled status: Expected vs database

4. **Classify Drift:**
   - CRITICAL: Service role violation, RLS disabled, missing roles
   - ERROR: Extra grants, missing grants, deny-first violated
   - WARNING: Policy definition differences
   - INFO: Cosmetic differences

5. **Emit Report:**
   - If drift detected: Emit CRITICAL RunRecord
   - Include drift classification
   - Include exact differences
   - HALT execution immediately

---

## Automated Authority Drift Detection SQL

**This SQL detects authority drift (DO NOT EXECUTE - design only):**

```sql
-- ============================================================
-- Authority Drift Detection Query (DESIGN ONLY)
-- ============================================================
-- Purpose: Detect authority model drift from frozen state
-- Status: DO NOT EXECUTE - Design artifact for future verification
-- ============================================================

-- Detect extra roles (not in STEP 10)
SELECT
  'EXTRA_ROLE' AS drift_type,
  rolname AS role_name,
  'Role exists but not defined in STEP 10' AS description
FROM pg_roles
WHERE rolname NOT IN (
  'anon', 'authenticated', 'service_role', 'pg_signal_backend', -- Supabase managed
  'internal_system', 'future_operator', -- STEP 10 roles
  'postgres', 'pg_database_owner', 'pg_monitor', 'pg_read_all_settings', 'pg_read_all_stats', 'pg_stat_scan_tables' -- PostgreSQL system
);

-- Detect missing roles (defined in STEP 10 but missing from database)
SELECT
  'MISSING_ROLE' AS drift_type,
  'internal_system' AS role_name,
  'Role defined in STEP 10 but missing from database' AS description
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'internal_system')
UNION ALL
SELECT
  'MISSING_ROLE' AS drift_type,
  'future_operator' AS role_name,
  'Role defined in STEP 10 but missing from database' AS description
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'future_operator');

-- Detect service_role grants (CRITICAL)
SELECT
  'SERVICE_ROLE_VIOLATION' AS drift_type,
  grantee,
  table_name,
  privilege_type,
  'Service role has application-level grant (QUARANTINE BREACH)' AS description
FROM information_schema.role_table_grants
WHERE grantee = 'service_role'
  AND table_schema = 'public';

-- Detect RLS disabled
SELECT
  'RLS_DISABLED' AS drift_type,
  tablename AS table_name,
  'RLS not enabled (security bypass)' AS description
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false
  AND tablename IN (
    'tools', 'tool_versions', 'run_records', 'run_artifacts',
    'intents', 'audit_log', 'validation_log', 'adapters',
    'adapter_events', 'execution_stats'
  );

-- Detect anon grants (deny-first violation)
SELECT
  'DENY_FIRST_VIOLATION' AS drift_type,
  'anon' AS role_name,
  table_name,
  privilege_type,
  'Anon has grant (deny-first violated)' AS description
FROM information_schema.role_table_grants
WHERE grantee = 'anon'
  AND table_schema = 'public';

-- Detect future_operator INSERT grants (privilege escalation)
SELECT
  'PRIVILEGE_ESCALATION' AS drift_type,
  'future_operator' AS role_name,
  table_name,
  privilege_type,
  'Future operator has write access' AS description
FROM information_schema.role_table_grants
WHERE grantee = 'future_operator'
  AND table_schema = 'public'
  AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE');

-- ============================================================
-- END OF AUTHORITY DRIFT DETECTION QUERIES
-- ============================================================
-- If any rows returned: DRIFT DETECTED
-- If zero rows returned: NO DRIFT
-- ============================================================
```

---

## Summary

**Authority Drift Detection Rules:** 6 (roles, grants, RLS, service_role, deny-first, privilege escalation)
**Drift Classifications:** 4 (CRITICAL, ERROR, WARNING, INFO)
**Detection Examples:** 6 (1 PASS, 5 FAIL)
**Detection Method:** Compare AUTHORITY_ASSERTIONS.md with database state via pg_roles, pg_policies

**Key Guarantees:**
- Authority model drift is detected BEFORE any execution
- Service role violation triggers CRITICAL halt
- Deny-first violations are detected immediately
- RLS bypass is detected and blocked
- Privilege escalation is prevented
- All differences emit CRITICAL RunRecords

**Authority model integrity is verified before every execution attempt.**
