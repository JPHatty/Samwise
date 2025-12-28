-- ============================================================
-- Samwise Database Schema - DDL Draft
-- ============================================================
-- Purpose: Define core tables for ToolForge, execution tracking, and audit
-- Status: DESIGN ONLY - DO NOT EXECUTE
-- Version: 1.0.0
-- Date: 2025-12-27
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
-- INDEXES
-- ============================================================

-- Tools indexes
CREATE INDEX idx_tools_active ON tools(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_tools_execution_mode ON tools(execution_mode);
CREATE INDEX idx_tools_adapter_id ON tools(adapter_id) WHERE adapter_id IS NOT NULL;

-- Run records indexes
CREATE INDEX idx_run_records_tool_id ON run_records(tool_id);
CREATE INDEX idx_run_records_status ON run_records(status);
CREATE INDEX idx_run_records_started_at ON run_records(started_at DESC);
CREATE INDEX idx_run_records_intent_id ON run_records(intent_id);
CREATE INDEX idx_run_records_critic_verdict ON run_records(critic_verdict);

-- Run artifacts indexes
CREATE INDEX idx_run_artifacts_run_id ON run_artifacts(run_id);
CREATE INDEX idx_run_artifacts_type ON run_artifacts(artifact_type);

-- Intents indexes
CREATE INDEX idx_intents_issuer ON intents(issuer);
CREATE INDEX idx_intents_issued_at ON intents(issued_at DESC);

-- Audit log indexes
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp DESC);
CREATE INDEX idx_audit_log_event_type ON audit_log(event_type);
CREATE INDEX idx_audit_log_actor ON audit_log(actor);
CREATE INDEX idx_audit_log_run_id ON audit_log(run_id) WHERE run_id IS NOT NULL;

-- Validation log indexes
CREATE INDEX idx_validation_log_gate ON validation_log(gate);
CREATE INDEX idx_validation_log_timestamp ON validation_log(timestamp DESC);
CREATE INDEX idx_validation_log_result ON validation_log(validation_result);

-- Adapter indexes
CREATE INDEX idx_adapters_enabled ON adapters(is_enabled) WHERE is_enabled = TRUE;
CREATE INDEX idx_adapters_health ON adapters(health_status);

-- Adapter events indexes
CREATE INDEX idx_adapter_events_adapter_id ON adapter_events(adapter_id);
CREATE INDEX idx_adapter_events_timestamp ON adapter_events(timestamp DESC);
CREATE INDEX idx_adapter_events_type ON adapter_events(event_type);

-- Execution stats indexes
CREATE INDEX idx_execution_stats_duration ON execution_stats(duration_ms);

-- ============================================================
-- CONSTRAINTS
-- ============================================================

-- Ensure run records have valid timestamps
ALTER TABLE run_records ADD CONSTRAINT check_run_records_timestamps
  CHECK (finished_at >= started_at);

-- Ensure timeout_seconds is reasonable
ALTER TABLE tools ADD CONSTRAINT check_tools_timeout
  CHECK (timeout_seconds BETWEEN 1 AND 3600);

-- Ensure artifact sizes are non-negative
ALTER TABLE run_artifacts ADD CONSTRAINT check_artifacts_size
  CHECK (size_bytes IS NULL OR size_bytes >= 0);

-- Ensure performance metrics are non-negative
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
-- END OF DDL
-- ============================================================
-- No triggers
-- No functions
-- No policies
-- No RLS
-- No comments
-- Pure schema definition only
