-- ============================================================
-- Samwise Migration: Roles and Row-Level Security
-- ============================================================
-- Status: DRY RUN ONLY — NOT APPLIED
-- Purpose: Define roles and enable RLS (policies to be added separately)
-- Dependencies: 001_tables.sql must be applied first
-- Order: Must be executed after 001_tables.sql
-- Version: 1.0.0
-- Date Planned: 2025-12-27
-- ============================================================
-- ⚠️  DO NOT EXECUTE THIS MIGRATION WITHOUT:
-- 1. Tables created successfully (001_tables.sql)
-- 2. Role requirements clearly defined
-- 3. RLS policies designed and reviewed
-- 4. Rollback plan tested
-- ============================================================
-- ⚠️  CRITICAL: SERVICE_ROLE USAGE
-- This migration does NOT grant service_role any permissions
-- service_role key MUST NOT be used in application code
-- service_role usage is FORBIDDEN until explicit migration step
-- ============================================================

-- ============================================================
-- ROLE CREATION
-- ============================================================

-- Application system role (for n8n, adapters)
-- This role has controlled write access to execution tables
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'internal_system') THEN
    CREATE ROLE internal_system WITH NOLOGIN;
  END IF;
END
$$;

-- Future operator role (for human monitoring)
-- This role has read-only access for troubleshooting
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'future_operator') THEN
    CREATE ROLE future_operator WITH NOLOGIN;
  END IF;
END
$$;

-- Note: anon and authenticated roles are managed by Supabase
-- Note: service_role exists but is NOT granted any permissions here

-- ============================================================
-- ROLE PRIVILEGES
-- ============================================================

-- internal_system role: SELECT on all tables (for validation and execution)
GRANT USAGE ON SCHEMA public TO internal_system;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO internal_system;

-- internal_system role: INSERT on execution tables
GRANT INSERT ON run_records TO internal_system;
GRANT INSERT ON run_artifacts TO internal_system;
GRANT INSERT ON audit_log TO internal_system;
GRANT INSERT ON validation_log TO internal_system;
GRANT INSERT ON adapter_events TO internal_system;
GRANT INSERT ON execution_stats TO internal_system;

-- internal_system role: UPDATE on specific flags only
GRANT UPDATE(is_active) ON tools TO internal_system;
GRANT UPDATE(rolled_back) ON run_artifacts TO internal_system;
GRANT UPDATE(health_status) ON adapters TO internal_system;

-- future_operator role: SELECT on all tables (read-only monitoring)
GRANT USAGE ON SCHEMA public TO future_operator;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO future_operator;

-- Note: anon and authenticated roles have NO grants (deny-first posture)
-- Note: service_role has NO grants (forbidden until migrations)

-- ============================================================
-- ROW LEVEL SECURITY (RLS) ENABLEMENT
-- ============================================================

-- Enable RLS on ALL tables (deny-first posture)
ALTER TABLE tools ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE run_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE run_artifacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE intents ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE adapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE adapter_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE execution_stats ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- DEFAULT RLS POLICIES (DENY ALL)
-- ============================================================

-- Default policy: Deny all access (must be explicitly overridden)
-- Per Supabase RLS behavior, enabling RLS with no policies = deny all

-- tools table: Internal system can read/write (managed via GRANT above)
CREATE POLICY "internal_system_all_access_tools" ON tools
  FOR ALL
  TO internal_system
  USING (true)
  WITH CHECK (true);

-- tools table: Future operator can read (read-only)
CREATE POLICY "future_operator_select_tools" ON tools
  FOR SELECT
  TO future_operator
  USING (true);

-- run_records table: Internal system can read/write
CREATE POLICY "internal_system_all_access_run_records" ON run_records
  FOR ALL
  TO internal_system
  USING (true)
  WITH CHECK (true);

-- run_records table: Future operator can read
CREATE POLICY "future_operator_select_run_records" ON run_records
  FOR SELECT
  TO future_operator
  USING (true);

-- run_artifacts table: Internal system can read/write
CREATE POLICY "internal_system_all_access_run_artifacts" ON run_artifacts
  FOR ALL
  TO internal_system
  USING (true)
  WITH CHECK (true);

-- run_artifacts table: Future operator can read
CREATE POLICY "future_operator_select_run_artifacts" ON run_artifacts
  FOR SELECT
  TO future_operator
  USING (true);

-- intents table: Internal system can read/write
CREATE POLICY "internal_system_all_access_intents" ON intents
  FOR ALL
  TO internal_system
  USING (true)
  WITH CHECK (true);

-- intents table: Future operator can read
CREATE POLICY "future_operator_select_intents" ON intents
  FOR SELECT
  TO future_operator
  USING (true);

-- audit_log table: Internal system can read/write
CREATE POLICY "internal_system_all_access_audit_log" ON audit_log
  FOR ALL
  TO internal_system
  USING (true)
  WITH CHECK (true);

-- audit_log table: Future operator can read
CREATE POLICY "future_operator_select_audit_log" ON audit_log
  FOR SELECT
  TO future_operator
  USING (true);

-- validation_log table: Internal system can read/write
CREATE POLICY "internal_system_all_access_validation_log" ON validation_log
  FOR ALL
  TO internal_system
  USING (true)
  WITH CHECK (true);

-- validation_log table: Future operator can read
CREATE POLICY "future_operator_select_validation_log" ON validation_log
  FOR SELECT
  TO future_operator
  USING (true);

-- adapters table: Internal system can read/write
CREATE POLICY "internal_system_all_access_adapters" ON adapters
  FOR ALL
  TO internal_system
  USING (true)
  WITH CHECK (true);

-- adapters table: Future operator can read
CREATE POLICY "future_operator_select_adapters" ON adapters
  FOR SELECT
  TO future_operator
  USING (true);

-- adapter_events table: Internal system can read/write
CREATE POLICY "internal_system_all_access_adapter_events" ON adapter_events
  FOR ALL
  TO internal_system
  USING (true)
  WITH CHECK (true);

-- adapter_events table: Future operator can read
CREATE POLICY "future_operator_select_adapter_events" ON adapter_events
  FOR SELECT
  TO future_operator
  USING (true);

-- execution_stats table: Internal system can read/write
CREATE POLICY "internal_system_all_access_execution_stats" ON execution_stats
  FOR ALL
  TO internal_system
  USING (true)
  WITH CHECK (true);

-- execution_stats table: Future operator can read
CREATE POLICY "future_operator_select_execution_stats" ON execution_stats
  FOR SELECT
  TO future_operator
  USING (true);

-- Note: tool_versions follows same pattern
CREATE POLICY "internal_system_all_access_tool_versions" ON tool_versions
  FOR ALL
  TO internal_system
  USING (true)
  WITH CHECK (true);

CREATE POLICY "future_operator_select_tool_versions" ON tool_versions
  FOR SELECT
  TO future_operator
  USING (true);

-- ============================================================
-- IMPORTANT RLS NOTES
-- ============================================================
-- 1. anon role: No policies = DENY ALL (intentional)
-- 2. authenticated role: No policies = DENY ALL (intentional)
-- 3. service_role: Bypasses RLS by design, but NO GRANTS = no access
-- 4. internal_system: Full access for system operations
-- 5. future_operator: Read-only access for monitoring
--
-- Future policy additions MUST be explicitly documented in:
-- - supabase/security/ROLES_AND_RLS.md
-- - Migration notes
-- - Security review approval
-- ============================================================

-- ============================================================
-- END OF RLS DEFINITIONS
-- ============================================================
-- Rollback Strategy:
-- DROP POLICY IF EXISTS "future_operator_select_tool_versions" ON tool_versions;
-- DROP POLICY IF EXISTS "internal_system_all_access_tool_versions" ON tool_versions;
-- DROP POLICY IF EXISTS "future_operator_select_execution_stats" ON execution_stats;
-- DROP POLICY IF EXISTS "internal_system_all_access_execution_stats" ON execution_stats;
-- DROP POLICY IF EXISTS "future_operator_select_adapter_events" ON adapter_events;
-- DROP POLICY IF EXISTS "internal_system_all_access_adapter_events" ON adapter_events;
-- DROP POLICY IF EXISTS "future_operator_select_adapters" ON adapters;
-- DROP POLICY IF EXISTS "internal_system_all_access_adapters" ON adapters;
-- DROP POLICY IF EXISTS "future_operator_select_validation_log" ON validation_log;
-- DROP POLICY IF EXISTS "internal_system_all_access_validation_log" ON validation_log;
-- DROP POLICY IF EXISTS "future_operator_select_audit_log" ON audit_log;
-- DROP POLICY IF EXISTS "internal_system_all_access_audit_log" ON audit_log;
-- DROP POLICY IF EXISTS "future_operator_select_intents" ON intents;
-- DROP POLICY IF EXISTS "internal_system_all_access_intents" ON intents;
-- DROP POLICY IF EXISTS "future_operator_select_run_artifacts" ON run_artifacts;
-- DROP POLICY IF EXISTS "internal_system_all_access_run_artifacts" ON run_artifacts;
-- DROP POLICY IF EXISTS "future_operator_select_run_records" ON run_records;
-- DROP POLICY IF EXISTS "internal_system_all_access_run_records" ON run_records;
-- DROP POLICY IF EXISTS "future_operator_select_tools" ON tools;
-- DROP POLICY IF EXISTS "internal_system_all_access_tools" ON tools;
--
-- ALTER TABLE execution_stats DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE adapter_events DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE adapters DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE validation_log DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE audit_log DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE intents DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE run_artifacts DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE run_records DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE tool_versions DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE tools DISABLE ROW LEVEL SECURITY;
--
-- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM future_operator;
-- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM internal_system;
-- REVOKE USAGE ON SCHEMA public FROM future_operator;
-- REVOKE USAGE ON SCHEMA public FROM internal_system;
--
-- DROP ROLE IF EXISTS future_operator;
-- DROP ROLE IF EXISTS internal_system;
-- ============================================================
-- Security Notes:
-- - RLS enabled on all tables (deny-all default)
-- - internal_system has full access (system operations)
-- - future_operator has read-only access (monitoring)
-- - anon/authenticated have NO access (no policies)
-- - service_role has NO grants (forbidden)
-- ============================================================
