-- ============================================================
-- Samwise Migration: Constraints
-- ============================================================
-- Status: DRY RUN ONLY — NOT APPLIED
-- Purpose: Define data integrity constraints
-- Dependencies: 001_tables.sql must be applied first
-- Order: Must be executed after 001_tables.sql
-- Version: 1.0.0
-- Date Planned: 2025-12-27
-- ============================================================
-- ⚠️  DO NOT EXECUTE THIS MIGRATION WITHOUT:
-- 1. Tables created successfully (001_tables.sql)
-- 2. Constraint validation tested
-- 3. Impact on existing data evaluated (if any)
-- 4. Rollback plan confirmed
-- ============================================================

-- ============================================================
-- RUN RECORDS CONSTRAINTS
-- ============================================================

-- Ensure run records have valid timestamps (finished_at >= started_at)
ALTER TABLE run_records ADD CONSTRAINT check_run_records_timestamps
  CHECK (finished_at >= started_at);

-- ============================================================
-- TOOLS CONSTRAINTS
-- ============================================================

-- Ensure timeout_seconds is within reasonable bounds
ALTER TABLE tools ADD CONSTRAINT check_tools_timeout
  CHECK (timeout_seconds BETWEEN 1 AND 3600);

-- ============================================================
-- RUN ARTIFACTS CONSTRAINTS
-- ============================================================

-- Ensure artifact sizes are non-negative (or null)
ALTER TABLE run_artifacts ADD CONSTRAINT check_artifacts_size
  CHECK (size_bytes IS NULL OR size_bytes >= 0);

-- ============================================================
-- EXECUTION STATS CONSTRAINTS
-- ============================================================

-- Ensure all performance metrics are non-negative
ALTER TABLE execution_stats ADD CONSTRAINT check_stats_positive
  CHECK (
    duration_ms >= 0 AND
    cpu_time_ms >= 0 AND
    memory_peak_mb >= 0 AND
    network_bytes_sent >= 0 AND
    network_bytes_received >= 0 AND
    disk_read_bytes >= 0 AND
    disk_write_bytes >= 0
  );

-- ============================================================
-- END OF CONSTRAINT DEFINITIONS
-- ============================================================
-- Rollback Strategy:
-- ALTER TABLE execution_stats DROP CONSTRAINT IF EXISTS check_stats_positive;
-- ALTER TABLE run_artifacts DROP CONSTRAINT IF EXISTS check_artifacts_size;
-- ALTER TABLE tools DROP CONSTRAINT IF EXISTS check_tools_timeout;
-- ALTER TABLE run_records DROP CONSTRAINT IF EXISTS check_run_records_timestamps;
-- ============================================================
-- Constraint Validation:
-- All constraints use CHECK clauses for automatic validation
-- PostgreSQL will enforce these on INSERT/UPDATE operations
-- Invalid data will be rejected with constraint violation error
-- ============================================================
-- Performance Impact:
-- Constraints add validation overhead (~1-5% per INSERT/UPDATE)
-- This is acceptable for data integrity guarantees
-- No indexes required for these constraints
-- ============================================================
