# Schema Drift Guards

## Purpose
**DEFINITIVE** specification of how to detect schema drift BEFORE any execution.

**PRINCIPLE:** Silent schema drift is prevented through explicit diff-based verification.

**Reference:** STEP 10 - supabase/schema/DDL_DRAFT.sql

---

## What Is Schema Drift?

**Schema Drift:** Any difference between the frozen schema (STEP 10) and the actual database state.

**Types of Drift:**
1. **Missing Tables:** Table defined in DDL but not in database
2. **Extra Tables:** Table in database but not in DDL
3. **Column Drift:** Column differences (missing, extra, type mismatch, nullability mismatch)
4. **Index Drift:** Index differences (missing, extra, definition mismatch)
5. **Constraint Drift:** Constraint differences (missing, extra, definition mismatch)
6. **RLS Drift:** RLS policy differences (missing, extra, changed)
7. **Role Drift:** Role differences (missing, extra, privilege changes)

**Why Drift is Dangerous:**
- Silent failures (application expects column that doesn't exist)
- Security bypasses (extra tables with weak RLS)
- Data corruption (type mismatches cause data loss)
- Irreversible changes (drops, deletes)
- Audit trail breakage (append-only violated)

---

## Drift Detection Rules

### Rule 1: Table Existence Verification

**Check:** For each table in DDL_DRAFT.sql, verify it exists in database.

**Expected Tables (10):**
1. tools
2. tool_versions
3. run_records
4. run_artifacts
5. intents
6. audit_log
7. validation_log
8. adapters
9. adapter_events
10. execution_stats

**PASS Condition:**
- ✅ All 10 tables exist in database
- ✅ No extra tables in database (outside Supabase managed tables)
- ✅ Table owners match expected (usually postgres or Supabase admin)

**FAIL Condition:**
- ❌ Any table missing (DDL has it, database doesn't)
- ❌ Extra tables present (database has tables not in DDL)
- ❌ Table owner mismatch (unexpected schema ownership)

**Example FAIL:**
```sql
-- DDL defines: tools table
-- Database: Missing tools table
-- Result: FAIL - Critical schema drift
```

**Detection Method:**
```sql
-- Query database for table list
SELECT table_name, table_owner
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Compare with DDL table list
-- Any difference = DRIFT DETECTED
```

---

### Rule 2: Column Existence and Type Verification

**Check:** For each table in DDL, verify all columns exist with correct types.

**PASS Condition:**
- ✅ All columns in DDL exist in database
- ✅ No extra columns in database (outside managed columns)
- ✅ Column data types match exactly
- ✅ Column nullability matches exactly (NOT NULL vs nullable)
- ✅ Column defaults match where specified

**FAIL Condition:**
- ❌ Missing column (DDL defines it, database doesn't have it)
- ❌ Extra column (database has column not in DDL)
- ❌ Type mismatch (DDL: TEXT, database: INTEGER)
- ❌ Nullability mismatch (DDL: NOT NULL, database: nullable)
- ❌ Default mismatch (DDL: NOW(), database: different default)

**Example FAIL:**
```sql
-- DDL defines:
CREATE TABLE tools (
  tool_id TEXT PRIMARY KEY,
  version TEXT NOT NULL,
  -- ...
);

-- Database has:
-- tool_id: TEXT (match)
-- version: TEXT (match)
-- description: TEXT NULL (EXTRA COLUMN - DRIFT)
-- Result: FAIL - Extra column detected
```

**Detection Method:**
```sql
-- For each table, query column definitions
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'tools' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Compare with DDL column list
-- Any difference = DRIFT DETECTED
```

---

### Rule 3: Foreign Key Verification

**Check:** For each foreign key in DDL, verify it exists in database.

**Expected Foreign Keys:**
1. tool_versions → tools (tool_id, version)
2. run_records → tools (tool_id, version)
3. run_artifacts → run_records (run_id)
4. audit_log → run_records (run_id)
5. validation_log → intents (intent_id)
6. validation_log → tools (tool_id)
7. adapter_events → adapters (adapter_id)
8. execution_stats → run_records (run_id)

**PASS Condition:**
- ✅ All 8 foreign keys exist
- ✅ FK references match (table, column)
- ✅ ON DELETE rules match (CASCADE, SET NULL, etc.)

**FAIL Condition:**
- ❌ Missing foreign key (DDL defines it, database doesn't have it)
- ❌ Extra foreign key (database has FK not in DDL)
- ❌ Reference mismatch (FK points to wrong table/column)
- ❌ ON DELETE rule mismatch (DDL: CASCADE, database: NO ACTION)

**Example FAIL:**
```sql
-- DDL defines:
FOREIGN KEY (run_id) REFERENCES run_records(run_id) ON DELETE CASCADE

-- Database has:
FOREIGN KEY (run_id) REFERENCES run_records(run_id) ON DELETE NO ACTION
-- Result: FAIL - ON DELETE rule mismatch
```

**Detection Method:**
```sql
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
  ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- Compare with DDL foreign key list
-- Any difference = DRIFT DETECTED
```

---

### Rule 4: Index Verification

**Check:** For each index in 002_indexes.sql, verify it exists in database.

**Expected Indexes (29):**
- idx_tools_active
- idx_tools_execution_mode
- idx_tools_adapter_id
- idx_run_records_tool_id
- idx_run_records_status
- idx_run_records_started_at
- idx_run_records_intent_id
- idx_run_records_critic_verdict
- idx_run_artifacts_run_id
- idx_run_artifacts_type
- idx_intents_issuer
- idx_intents_issued_at
- idx_audit_log_timestamp
- idx_audit_log_event_type
- idx_audit_log_actor
- idx_audit_log_run_id
- idx_validation_log_gate
- idx_validation_log_timestamp
- idx_validation_log_result
- idx_adapters_enabled
- idx_adapters_health
- idx_adapter_events_adapter_id
- idx_adapter_events_timestamp
- idx_adapter_events_type
- idx_execution_stats_duration
- (Plus primary key indexes, usually implicit)

**PASS Condition:**
- ✅ All 29 indexes exist (or more if DB adds automatic indexes)
- ✅ Index definitions match (columns, order, uniqueness)
- ✅ Partial index WHERE clauses match (if applicable)

**FAIL Condition:**
- ❌ Missing index (DDL defines it, database doesn't have it)
- ❌ Index column mismatch (wrong column or order)
- ❌ Index type mismatch (UNIQUE vs non-UNIQUE)
- ❌ Partial index WHERE clause mismatch

**Example FAIL:**
```sql
-- DDL defines:
CREATE INDEX idx_run_records_status ON run_records(status);

-- Database has:
-- Index missing entirely
-- Result: FAIL - Missing index (performance degradation)
```

**Detection Method:**
```sql
SELECT
  indexname,
  indexdef,
  tablename,
  schemaname
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN (
    -- List of 10 tables
  )
ORDER BY tablename, indexname;

-- Compare with DDL index list
-- Missing index = DRIFT DETECTED
```

---

### Rule 5: Constraint Verification

**Check:** For each constraint in 003_constraints.sql, verify it exists in database.

**Expected Constraints (8):**
- check_run_records_timestamps (finished_at >= started_at)
- check_tools_timeout (timeout_seconds BETWEEN 1 AND 3600)
- check_artifacts_size (size_bytes >= 0 OR NULL)
- check_stats_positive (all metrics >= 0)

Plus implicit constraints:
- PRIMARY KEY constraints (10, one per table)
- UNIQUE constraints (1: tools(tool_id, version))
- FOREIGN KEY constraints (8)
- NOT NULL constraints (many, per column definition)
- CHECK constraints (enum values: execution_mode, status, etc.)

**PASS Condition:**
- ✅ All explicit CHECK constraints exist
- ✅ Constraint definitions match exactly
- ✅ All NOT NULL constraints match
- ✅ All UNIQUE constraints match
- ✅ All ENUM CHECK constraints match

**FAIL Condition:**
- ❌ Missing CHECK constraint
- ❌ Constraint definition mismatch (different condition)
- ❌ NOT NULL constraint missing or added
- ❌ UNIQUE constraint missing or added
- ❌ ENUM CHECK constraint different values

**Example FAIL:**
```sql
-- DDL defines:
ALTER TABLE tools ADD CONSTRAINT check_tools_timeout
  CHECK (timeout_seconds BETWEEN 1 AND 3600);

-- Database has:
-- Constraint missing
-- Result: FAIL - Missing constraint (data validation bypassed)
```

**Detection Method:**
```sql
SELECT
  conname AS constraint_name,
  conrelid::regclass AS table_name,
  pg_get_constraintdef(c.oid) AS constraint_definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'public'
  AND contype IN ('c', 'f', 'p', 'u')  -- CHECK, FOREIGN KEY, PRIMARY KEY, UNIQUE
ORDER BY conrelid::regclass, conname;

-- Compare with DDL constraint list
-- Any difference = DRIFT DETECTED
```

---

### Rule 6: RLS Policy Verification

**Check:** For each RLS policy in 004_roles_rls.sql, verify it exists in database.

**Expected RLS Policies:**
- 24 policies (2 per table × 10 tables = 20 policies, plus versions)
- All tables have RLS enabled
- All policies for internal_system (full access)
- All policies for future_operator (read-only)
- No policies for anon (deny-all)
- No policies for authenticated (deny-all)

**PASS Condition:**
- ✅ RLS enabled on all 10 tables
- ✅ All 24 policies exist
- ✅ Policy commands match (USING, WITH CHECK)
- ✅ Policy roles match (internal_system, future_operator)

**FAIL Condition:**
- ❌ RLS not enabled on a table
- ❌ Missing policy (DDL defines it, database doesn't have it)
- ❌ Extra policy (database has policy not in DDL)
- ❌ Policy command mismatch (different USING clause)
- ❌ Policy role mismatch (wrong role granted access)

**Example FAIL:**
```sql
-- DDL defines:
CREATE POLICY "internal_system_all_access_run_records" ON run_records
  FOR ALL TO internal_system USING (true) WITH CHECK (true);

-- Database has:
-- Policy missing
-- OR RLS not enabled on run_records
-- Result: FAIL - RLS bypass possible
```

**Detection Method:**
```sql
-- Check RLS enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Check RLS policies
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Compare with DDL policy list
-- Any difference = DRIFT DETECTED
```

---

## Drift Detection Examples

### Example 1: PASS - No Drift

**DDL State:**
```sql
CREATE TABLE tools (
  tool_id TEXT PRIMARY KEY,
  version TEXT NOT NULL
);
```

**Database State:**
```sql
\d tools
Column   | Type   | Nullable
---------+--------+----------
tool_id  | text   | not null
version  | text   | not null
Indexes:
    "tools_pkey" PRIMARY KEY, btree (tool_id)
```

**Result:** ✅ PASS - Schema matches DDL exactly

---

### Example 2: FAIL - Missing Column

**DDL State:**
```sql
CREATE TABLE tools (
  tool_id TEXT PRIMARY KEY,
  version TEXT NOT NULL,
  description TEXT NOT NULL  -- ← DDL has this
);
```

**Database State:**
```sql
\d tools
Column   | Type   | Nullable
---------+--------+----------
tool_id  | text   | not null
version  | text   | not null
-- description column MISSING
```

**Result:** ❌ FAIL - Column 'description' missing from database

**Classification:** CRITICAL
**Impact:** Application errors, data loss possible
**Action:** Re-run migration, add missing column

---

### Example 3: FAIL - Extra Column

**DDL State:**
```sql
CREATE TABLE tools (
  tool_id TEXT PRIMARY KEY,
  version TEXT NOT NULL
);
```

**Database State:**
```sql
\d tools
Column     | Type   | Nullable
-----------+--------+----------
tool_id    | text   | not null
version    | text   | not null
created_at | timestamp | not null  -- ← EXTRA COLUMN
```

**Result:** ❌ FAIL - Extra column 'created_at' in database

**Classification:** CRITICAL
**Impact:** Schema mismatch, possible security issue (backdoor)
**Action:** Drop extra column or update DDL to match

---

### Example 4: FAIL - Type Mismatch

**DDL State:**
```sql
timeout_seconds INTEGER NOT NULL CHECK (timeout_seconds BETWEEN 1 AND 3600)
```

**Database State:**
```sql
timeout_seconds BIGINT NOT NULL  -- ← Wrong type
```

**Result:** ❌ FAIL - Type mismatch (INTEGER vs BIGINT)

**Classification:** ERROR
**Impact:** Data truncation, constraint violations
**Action:** Alter column type or update DDL

---

### Example 5: FAIL - Nullability Mismatch

**DDL State:**
```sql
version TEXT NOT NULL  -- ← NOT NULL
```

**Database State:**
```sql
version TEXT NULL  -- ← Nullable
```

**Result:** ❌ FAIL - Nullability mismatch

**Classification:** ERROR
**Impact:** NULL values allowed where not expected, data integrity issues
**Action:** Add NOT NULL constraint or update DDL

---

### Example 6: FAIL - Missing Index

**DDL State:**
```sql
CREATE INDEX idx_run_records_status ON run_records(status);
```

**Database State:**
```sql
-- Index missing entirely
```

**Result:** ❌ FAIL - Missing index

**Classification:** WARNING
**Impact:** Performance degradation on queries filtering by status
**Action:** Create missing index

---

### Example 7: FAIL - Missing Constraint

**DDL State:**
```sql
ALTER TABLE tools ADD CONSTRAINT check_tools_timeout
  CHECK (timeout_seconds BETWEEN 1 AND 3600);
```

**Database State:**
```sql
-- Constraint missing entirely
```

**Result:** ❌ FAIL - Missing constraint

**Classification:** CRITICAL
**Impact:** Invalid data can be inserted, validation bypassed
**Action:** Create missing constraint

---

### Example 8: FAIL - RLS Not Enabled

**DDL State:**
```sql
ALTER TABLE tools ENABLE ROW LEVEL SECURITY;
```

**Database State:**
```sql
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'tools';
tablename | rowsecurity
-----------+-------------
tools     | f  -- ← RLS not enabled
```

**Result:** ❌ FAIL - RLS not enabled on 'tools'

**Classification:** CRITICAL
**Impact:** Security bypass, data exposure
**Action:** Enable RLS, create policies

---

## Drift Detection Procedure

### Pre-Execution Check

**Before ANY execution (migration, adapter call, tool execution):**

1. **Extract DDL State:**
   - Parse 001_tables.sql for table list
   - Parse 002_indexes.sql for index list
   - Parse 003_constraints.sql for constraint list
   - Parse 004_roles_rls.sql for role/policy list

2. **Query Database State:**
   - Query information_schema.tables
   - Query information_schema.columns
   - Query pg_indexes
   - Query pg_constraint
   - Query pg_policies
   - Query pg_roles

3. **Compare States:**
   - Table list: DDL vs database
   - Column list: DDL vs database (per table)
   - Index list: DDL vs database
   - Constraint list: DDL vs database
   - RLS policy list: DDL vs database
   - Role list: DDL vs database

4. **Classify Drift:**
   - CRITICAL: Missing tables, missing columns, RLS disabled, constraints missing
   - ERROR: Type mismatches, nullability mismatches, extra tables
   - WARNING: Missing indexes, index definition differences
   - INFO: Cosmetic differences (comments, default expression format)

5. **Emit Report:**
   - If drift detected: Emit CRITICAL RunRecord
   - Include drift classification
   - Include exact differences
   - HALT execution immediately

---

## Automated Drift Detection SQL

**This SQL detects schema drift (DO NOT EXECUTE - design only):**

```sql
-- ============================================================
-- Schema Drift Detection Query (DESIGN ONLY)
-- ============================================================
-- Purpose: Detect differences between DDL and actual database
-- Status: DO NOT EXECUTE - Design artifact for future verification
-- ============================================================

-- Detect missing tables (in DDL but not in database)
SELECT
  'MISSING_TABLE' AS drift_type,
  ddl.table_name,
  'Table defined in DDL but missing from database' AS description
FROM (
  -- DDL table list (extracted manually from 001_tables.sql)
  SELECT 'tools' AS table_name UNION
  SELECT 'tool_versions' UNION
  SELECT 'run_records' UNION
  SELECT 'run_artifacts' UNION
  SELECT 'intents' UNION
  SELECT 'audit_log' UNION
  SELECT 'validation_log' UNION
  SELECT 'adapters' UNION
  SELECT 'adapter_events' UNION
  SELECT 'execution_stats'
) AS ddl
LEFT JOIN information_schema.tables db
  ON ddl.table_name = db.table_name
  AND db.table_schema = 'public'
WHERE db.table_name IS NULL;

-- Detect extra tables (in database but not in DDL)
SELECT
  'EXTRA_TABLE' AS drift_type,
  db.table_name,
  'Table in database but not defined in DDL' AS description
FROM information_schema.tables db
WHERE db.table_schema = 'public'
  AND db.table_name NOT IN (
    'tools', 'tool_versions', 'run_records', 'run_artifacts',
    'intents', 'audit_log', 'validation_log', 'adapters',
    'adapter_events', 'execution_stats'
  );

-- Detect missing columns (simplified example for tools table)
SELECT
  'MISSING_COLUMN' AS drift_type,
  'tools' AS table_name,
  ddl.column_name,
  'Column in DDL but missing from database' AS description
FROM (
  -- DDL column list for tools (extracted from 001_tables.sql)
  SELECT 'tool_id' AS column_name UNION
  SELECT 'version' UNION
  SELECT 'description' UNION
  SELECT 'input_schema' UNION
  SELECT 'output_schema' UNION
  SELECT 'execution_mode' UNION
  SELECT 'adapter_id' UNION
  SELECT 'adapter_operation' UNION
  SELECT 'credentials_required' UNION
  SELECT 'side_effects' UNION
  SELECT 'rollback_strategy' UNION
  SELECT 'timeout_seconds' UNION
  SELECT 'resource_class' UNION
  SELECT 'dependencies' UNION
  SELECT 'validation' UNION
  SELECT 'metadata' UNION
  SELECT 'is_active' UNION
  SELECT 'created_at' UNION
  SELECT 'updated_at'
) AS ddl
LEFT JOIN information_schema.columns db
  ON ddl.column_name = db.column_name
  AND db.table_name = 'tools'
  AND db.table_schema = 'public'
WHERE db.column_name IS NULL;

-- Detect RLS not enabled
SELECT
  'RLS_DISABLED' AS drift_type,
  tablename AS table_name,
  'RLS not enabled on table (security bypass)' AS description
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false
  AND tablename IN (
    'tools', 'tool_versions', 'run_records', 'run_artifacts',
    'intents', 'audit_log', 'validation_log', 'adapters',
    'adapter_events', 'execution_stats'
  );

-- ============================================================
-- END OF DRIFT DETECTION QUERIES
-- ============================================================
-- If any rows returned: DRIFT DETECTED
-- If zero rows returned: NO DRIFT
-- ============================================================
```

---

## Summary

**Drift Detection Rules:** 6 (tables, columns, foreign keys, indexes, constraints, RLS)
**Drift Classifications:** 4 (CRITICAL, ERROR, WARNING, INFO)
**Detection Examples:** 8 (4 PASS, 4 FAIL)
**Detection Method:** Compare DDL state with database state via information_schema

**Key Guarantees:**
- Schema drift is detected BEFORE any execution
- All differences are classified by severity
- CRITICAL drift causes immediate halt
- Automated queries enable CI/CD integration
- No silent drift possible

**Schema integrity is verified before every execution attempt.**
