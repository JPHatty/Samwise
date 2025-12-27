-- ============================================================
-- Samwise Migration: Indexes
-- ============================================================
-- Status: DRY RUN ONLY — NOT APPLIED
-- Purpose: Define indexes for query performance
-- Dependencies: 001_tables.sql must be applied first
-- Order: Must be executed after 001_tables.sql, before 003_constraints.sql
-- Version: 1.0.0
-- Date Planned: 2025-12-27
-- ============================================================
-- ⚠️  DO NOT EXECUTE THIS MIGRATION WITHOUT:
-- 1. Tables created successfully (001_tables.sql)
-- 2. Index creation tested on staging
-- 3. Performance impact evaluated
-- 4. Rollback plan confirmed
-- ============================================================

-- ============================================================
-- TOOLS INDEXES
-- ============================================================

-- Active tools lookup (for validation)
CREATE INDEX idx_tools_active ON tools(is_active) WHERE is_active = TRUE;

-- Filter tools by execution mode
CREATE INDEX idx_tools_execution_mode ON tools(execution_mode);

-- Filter tools by adapter
CREATE INDEX idx_tools_adapter_id ON tools(adapter_id) WHERE adapter_id IS NOT NULL;

-- ============================================================
-- RUN RECORDS INDEXES
-- ============================================================

-- Query runs by tool
CREATE INDEX idx_run_records_tool_id ON run_records(tool_id);

-- Filter runs by status
CREATE INDEX idx_run_records_status ON run_records(status);

-- Time-series queries on runs (newest first)
CREATE INDEX idx_run_records_started_at ON run_records(started_at DESC);

-- Query runs by intent
CREATE INDEX idx_run_records_intent_id ON run_records(intent_id);

-- Filter runs by critic verdict
CREATE INDEX idx_run_records_critic_verdict ON run_records(critic_verdict);

-- ============================================================
-- RUN ARTIFACTS INDEXES
-- ============================================================

-- Query artifacts by run
CREATE INDEX idx_run_artifacts_run_id ON run_artifacts(run_id);

-- Filter artifacts by type
CREATE INDEX idx_run_artifacts_type ON run_artifacts(artifact_type);

-- ============================================================
-- INTENTS INDEXES
-- ============================================================

-- Filter intents by issuer
CREATE INDEX idx_intents_issuer ON intents(issuer);

-- Time-series queries on intents (newest first)
CREATE INDEX idx_intents_issued_at ON intents(issued_at DESC);

-- ============================================================
-- AUDIT LOG INDEXES
-- ============================================================

-- Time-series queries on audit log (newest first)
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp DESC);

-- Filter audit log by event type
CREATE INDEX idx_audit_log_event_type ON audit_log(event_type);

-- Filter audit log by actor
CREATE INDEX idx_audit_log_actor ON audit_log(actor);

-- Query audit log by run_id
CREATE INDEX idx_audit_log_run_id ON audit_log(run_id) WHERE run_id IS NOT NULL;

-- ============================================================
-- VALIDATION LOG INDEXES
-- ============================================================

-- Filter validation log by gate
CREATE INDEX idx_validation_log_gate ON validation_log(gate);

-- Time-series queries on validation log
CREATE INDEX idx_validation_log_timestamp ON validation_log(timestamp DESC);

-- Filter validation log by result
CREATE INDEX idx_validation_log_result ON validation_log(validation_result);

-- ============================================================
-- ADAPTER INDEXES
-- ============================================================

-- Filter enabled adapters
CREATE INDEX idx_adapters_enabled ON adapters(is_enabled) WHERE is_enabled = TRUE;

-- Filter adapters by health status
CREATE INDEX idx_adapters_health ON adapters(health_status);

-- ============================================================
-- ADAPTER EVENTS INDEXES
-- ============================================================

-- Query adapter events by adapter
CREATE INDEX idx_adapter_events_adapter_id ON adapter_events(adapter_id);

-- Time-series queries on adapter events
CREATE INDEX idx_adapter_events_timestamp ON adapter_events(timestamp DESC);

-- Filter adapter events by type
CREATE INDEX idx_adapter_events_type ON adapter_events(event_type);

-- ============================================================
-- EXECUTION STATS INDEXES
-- ============================================================

-- Order execution stats by duration (for performance analysis)
CREATE INDEX idx_execution_stats_duration ON execution_stats(duration_ms);

-- ============================================================
-- END OF INDEX DEFINITIONS
-- ============================================================
-- Rollback Strategy:
-- DROP INDEX IF EXISTS idx_execution_stats_duration;
-- DROP INDEX IF EXISTS idx_adapter_events_type;
-- DROP INDEX IF EXISTS idx_adapter_events_timestamp;
-- DROP INDEX IF EXISTS idx_adapter_events_adapter_id;
-- DROP INDEX IF EXISTS idx_adapters_health;
-- DROP INDEX IF EXISTS idx_adapters_enabled;
-- DROP INDEX IF EXISTS idx_validation_log_result;
-- DROP INDEX IF EXISTS idx_validation_log_timestamp;
-- DROP INDEX IF EXISTS idx_validation_log_gate;
-- DROP INDEX IF EXISTS idx_audit_log_run_id;
-- DROP INDEX IF EXISTS idx_audit_log_actor;
-- DROP INDEX IF EXISTS idx_audit_log_event_type;
-- DROP INDEX IF EXISTS idx_audit_log_timestamp;
-- DROP INDEX IF EXISTS idx_intents_issued_at;
-- DROP INDEX IF EXISTS idx_intents_issuer;
-- DROP INDEX IF EXISTS idx_run_artifacts_type;
-- DROP INDEX IF EXISTS idx_run_artifacts_run_id;
-- DROP INDEX IF EXISTS idx_run_records_critic_verdict;
-- DROP INDEX IF EXISTS idx_run_records_intent_id;
-- DROP INDEX IF EXISTS idx_run_records_started_at;
-- DROP INDEX IF EXISTS idx_run_records_status;
-- DROP INDEX IF EXISTS idx_run_records_tool_id;
-- DROP INDEX IF EXISTS idx_tools_adapter_id;
-- DROP INDEX IF EXISTS idx_tools_execution_mode;
-- DROP INDEX IF EXISTS idx_tools_active;
-- ============================================================
-- Performance Notes:
-- - All indexes are B-tree (default for PostgreSQL)
-- - Partial indexes used WHERE appropriate to reduce size
-- - No CONCURRENTLY option (blocking during migration)
-- - Estimated total index size: ~5-10 MB for 100k rows
-- ============================================================
