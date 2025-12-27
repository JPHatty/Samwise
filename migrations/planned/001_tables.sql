-- ============================================================
-- Samwise Migration: Tables
-- ============================================================
-- Status: DRY RUN ONLY — NOT APPLIED
-- Purpose: Define core table structure for ToolForge execution tracking
-- Dependencies: None
-- Order: Must be executed before indexes.sql, constraints.sql, roles_rls.sql
-- Version: 1.0.0
-- Date Planned: 2025-12-27
-- ============================================================
-- ⚠️  DO NOT EXECUTE THIS MIGRATION WITHOUT:
-- 1. Explicit operator approval
-- 2. Full database backup
-- 3. Rollback plan tested
-- 4. STEP 10 authority model verified
-- ============================================================

-- ============================================================
-- TOOL REGISTRY
-- ============================================================

-- Tools registered in the system
CREATE TABLE tools (
  tool_id TEXT PRIMARY KEY,
  version TEXT NOT NULL,
  description TEXT NOT NULL,
  input_schema JSONB NOT NULL,
  output_schema JSONB NOT NULL,
  execution_mode TEXT NOT NULL CHECK (execution_mode IN ('local', 'remote', 'browser')),
  adapter_id TEXT,
  adapter_operation TEXT,
  credentials_required JSONB NOT NULL,
  side_effects JSONB NOT NULL,
  rollback_strategy TEXT NOT NULL CHECK (rollback_strategy IN ('none', 'compensating', 'snapshot')),
  timeout_seconds INTEGER NOT NULL CHECK (timeout_seconds BETWEEN 1 AND 3600),
  resource_class TEXT NOT NULL CHECK (resource_class IN ('control', 'compute', 'state')),
  dependencies JSONB,
  validation JSONB,
  metadata JSONB,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tool_id, version)
);

-- Tool versions and deprecations
CREATE TABLE tool_versions (
  tool_id TEXT NOT NULL,
  version TEXT NOT NULL,
  previous_version TEXT,
  status TEXT NOT NULL CHECK (status IN ('active', 'deprecated', 'deleted')),
  deprecated_at TIMESTAMPTZ,
  reason TEXT,
  PRIMARY KEY (tool_id, version),
  FOREIGN KEY (tool_id, version) REFERENCES tools(tool_id, version) ON DELETE CASCADE
);

-- ============================================================
-- RUN RECORDS
-- ============================================================

-- Execution records for all tool invocations
CREATE TABLE run_records (
  run_id TEXT PRIMARY KEY,
  intent_id TEXT NOT NULL,
  tool_id TEXT NOT NULL,
  tool_version TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL,
  finished_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('success', 'failure', 'timeout', 'degraded')),
  inputs_hash TEXT NOT NULL,
  outputs_hash TEXT,
  artifacts JSONB NOT NULL,
  logs_ref TEXT,
  rollback_executed BOOLEAN NOT NULL DEFAULT FALSE,
  rollback_details JSONB,
  critic_verdict TEXT NOT NULL CHECK (critic_verdict IN ('pass', 'fail')),
  critic_details JSONB,
  errors JSONB,
  warnings JSONB,
  performance JSONB,
  metadata JSONB NOT NULL,
  FOREIGN KEY (tool_id, tool_version) REFERENCES tools(tool_id, version)
);

-- Run record artifacts (files, outputs, etc.)
CREATE TABLE run_artifacts (
  artifact_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL,
  artifact_type TEXT NOT NULL,
  location TEXT NOT NULL,
  size_bytes INTEGER,
  checksum TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  rolled_back BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (run_id) REFERENCES run_records(run_id) ON DELETE CASCADE
);

-- ============================================================
-- INTENT SPECIFICATIONS
-- ============================================================

-- Intent specifications that generated tool executions
CREATE TABLE intents (
  intent_id TEXT PRIMARY KEY,
  issued_at TIMESTAMPTZ NOT NULL,
  issuer TEXT NOT NULL CHECK (issuer IN ('human', 'agent', 'system')),
  objective TEXT NOT NULL,
  constraints JSONB NOT NULL,
  forbidden_actions JSONB NOT NULL,
  required_outputs JSONB NOT NULL,
  validation_level TEXT NOT NULL CHECK (validation_level IN ('strict', 'normal', 'permissive')),
  rollback_required BOOLEAN NOT NULL DEFAULT FALSE,
  audit_required BOOLEAN NOT NULL DEFAULT FALSE
);

-- ============================================================
-- AUDIT TRAILS
-- ============================================================

-- Complete audit log of all operations
CREATE TABLE audit_log (
  audit_id TEXT PRIMARY KEY,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  event_type TEXT NOT NULL,
  actor TEXT NOT NULL,
  operation TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  details JSONB NOT NULL,
  severity TEXT CHECK (severity IN ('info', 'warning', 'error', 'critical')),
  run_id TEXT,
  FOREIGN KEY (run_id) REFERENCES run_records(run_id) ON DELETE SET NULL
);

-- Validation gate results
CREATE TABLE validation_log (
  validation_id TEXT PRIMARY KEY,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  gate TEXT NOT NULL,
  intent_id TEXT,
  tool_id TEXT,
  validation_result TEXT NOT NULL CHECK (validation_result IN ('pass', 'fail')),
  errors JSONB,
  halted BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (intent_id) REFERENCES intents(intent_id) ON DELETE CASCADE,
  FOREIGN KEY (tool_id) REFERENCES tools(tool_id) ON DELETE SET NULL
);

-- ============================================================
-- ADAPTER BINDINGS
-- ============================================================

-- Cloud adapter configurations
CREATE TABLE adapters (
  adapter_id TEXT PRIMARY KEY,
  version TEXT NOT NULL,
  provider TEXT NOT NULL,
  service TEXT NOT NULL,
  config_required JSONB NOT NULL,
  is_critical BOOLEAN NOT NULL DEFAULT FALSE,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  initialized_at TIMESTAMPTZ,
  last_health_check TIMESTAMPTZ,
  health_status TEXT CHECK (health_status IN ('healthy', 'degraded', 'failed'))
);

-- Adapter initialization events
CREATE TABLE adapter_events (
  event_id TEXT PRIMARY KEY,
  adapter_id TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  event_type TEXT NOT NULL CHECK (event_type IN ('initialization', 'resolution', 'degradation', 'failure')),
  status TEXT NOT NULL CHECK (status IN ('success', 'failure')),
  error_code TEXT,
  error_details JSONB,
  config_resolved JSONB,
  FOREIGN KEY (adapter_id) REFERENCES adapters(adapter_id) ON DELETE CASCADE
);

-- ============================================================
-- EXECUTION METADATA
-- ============================================================

-- Execution statistics and metrics
CREATE TABLE execution_stats (
  stat_id TEXT PRIMARY KEY,
  run_id TEXT NOT NULL UNIQUE,
  duration_ms INTEGER NOT NULL,
  cpu_time_ms INTEGER NOT NULL,
  memory_peak_mb NUMERIC NOT NULL,
  network_bytes_sent INTEGER DEFAULT 0,
  network_bytes_received INTEGER DEFAULT 0,
  disk_read_bytes INTEGER DEFAULT 0,
  disk_write_bytes INTEGER DEFAULT 0,
  FOREIGN KEY (run_id) REFERENCES run_records(run_id) ON DELETE CASCADE
);

-- ============================================================
-- END OF TABLE DEFINITIONS
-- ============================================================
-- Rollback Strategy:
-- DROP TABLE IF EXISTS execution_stats CASCADE;
-- DROP TABLE IF EXISTS adapter_events CASCADE;
-- DROP TABLE IF EXISTS adapters CASCADE;
-- DROP TABLE IF EXISTS validation_log CASCADE;
-- DROP TABLE IF EXISTS audit_log CASCADE;
-- DROP TABLE IF EXISTS intents CASCADE;
-- DROP TABLE IF EXISTS run_artifacts CASCADE;
-- DROP TABLE IF EXISTS run_records CASCADE;
-- DROP TABLE IF EXISTS tool_versions CASCADE;
-- DROP TABLE IF EXISTS tools CASCADE;
-- ============================================================
