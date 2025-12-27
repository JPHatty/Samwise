# Definition of Done

## Purpose
**DEFINITIVE** acceptance criteria for each development step in the Samwise system.

**PRINCIPLE:** Each step is complete when all artifacts exist, all validations pass, and no silent drift can occur.

---

## STEP 5: n8n TOOLFORGE WORKFLOW DEVELOPMENT

### Acceptance Criteria

**Required Artifacts:**
- ✅ 7 n8n workflow JSON files created:
  - [ ] n8n/toolforge/workflows/toolforge_intake.json
  - [ ] n8n/toolforge/workflows/toolforge_validate_intent.json
  - [ ] n8n/toolforge/workflows/toolforge_generate_toolspec.json
  - [ ] n8n/toolforge/workflows/toolforge_validate_toolspec.json
  - [ ] n8n/toolforge/workflows/toolforge_compile_workflow.json
  - [ ] n8n/toolforge/workflows/toolforge_register_tool.json
  - [ ] n8n/toolforge/workflows/toolforge_fail_and_log.json
- ✅ VALIDATION_GATES.md created with 6 gate specifications
- ✅ RUNRECORD_EXAMPLES.md created with 5 canonical examples
- ✅ TOOL_REGISTRY_CONTRACT.md created with registry schema
- ✅ TEST_VECTORS.md created with valid/invalid examples

**Validation:**
- [ ] All 7 workflow JSON files are valid JSON
- [ ] All 6 validation gates have explicit pass/fail conditions
- [ ] All 5 RunRecord examples match run-record.schema.json
- [ ] Tool registry schema includes versioning, deprecation, metadata
- [ ] Test vectors include boundary conditions

**NO EXECUTION:**
- [ ] No n8n workflows were executed
- [ ] No tools were registered
- [ ] No cloud services were called

---

## STEP 6: EXECUTION BOUNDARY ENFORCEMENT

### Acceptance Criteria

**Required Artifacts:**
- ✅ EXECUTION_BOUNDARIES.md created with LOCAL vs CLOUD mapping
- ✅ compose.yaml modified with cloud service stubs
- ✅ ENV_VAR_MAPPING.md created with variable documentation
- ✅ FAILURE_GUARANTEES.md created with startup validation

**Validation:**
- [ ] All 7 cloud services marked as stubs in compose.yaml
- [ ] All cloud stubs have failing healthchecks
- [ ] EXECUTION_BOUNDARIES.md has complete LOCAL vs CLOUD table
- [ ] ENV_VAR_MAPPING.md has all required variables documented
- [ ] FAILURE_GUARANTEES.md has 5-phase startup validation

**Boundary Verification:**
- [ ] LOCAL = control plane only (traefik, n8n, redis)
- [ ] CLOUD = state + compute (Supabase, Qdrant, Meilisearch, R2, Prometheus, Loki, Grafana, LiveKit)
- [ ] No overlap between LOCAL and CLOUD services
- [ ] No cloud services have reachable endpoints in compose.yaml

**NO EXECUTION:**
- [ ] No Docker containers were started
- [ ] No cloud services were provisioned
- [ ] No environment variables were modified

---

## STEP 7: RUNTIME INTEGRATION (DRY, NON-EXECUTING)

### Acceptance Criteria

**Required Artifacts:**
- ✅ CLOUD_ADAPTER_INTERFACES.md created with 8 adapter specifications
- ✅ tool-spec.schema.json modified with adapter_id, adapter_operation
- ✅ toolforge_validate_toolspec.json modified with Rules 7-10
- ✅ ENVIRONMENT_RESOLUTION.md created with resolution priority
- ✅ DRY_RUN_VALIDATION.md created with 3-stage validation
- ✅ STOP_CONDITIONS.md created with explicit constraints

**Validation:**
- [ ] All 8 adapters have complete interface specifications (operations, inputs, outputs, timeouts, failures)
- [ ] tool-spec.schema.json requires adapter_id for remote tools
- [ ] tool-spec.schema.json forbids direct cloud URLs in credentials_required
- [ ] Rules 7-10 validate adapter mappings
- [ ] ENVIRONMENT_RESOLUTION.md has 5-phase startup validation
- [ ] DRY_RUN_VALIDATION.md has 3 validation stages (config, routing, simulation)
- [ ] STOP_CONDITIONS.md has explicit constraints

**Adapter Interface Completeness:**
- [ ] supabase-postgres adapter: query, vector_search operations
- [ ] qdrant-vector adapter: collection_create, collection_delete, vector_insert, vector_search operations
- [ ] meilisearch-search adapter: index_create, document_add, document_search operations
- [ ] cloudflare-r2 adapter: object_put, object_get, object_delete operations
- [ ] prometheus-metrics adapter: metric_query, metric_write operations
- [ ] grafana-obs adapter: dashboard_create, dashboard_query operations
- [ ] loki-log adapter: log_push, log_query operations
- [ ] livekit-realtime adapter: room_create, room_delete, token_issue operations

**NO EXECUTION:**
- [ ] No adapters were called
- [ ] No cloud services were reached
- [ ] No environment variables were resolved

---

## STEP 8: CONTROLLED EXECUTION SIMULATION (NO LIVE CALLS)

### Acceptance Criteria

**Required Artifacts:**
- ✅ FAULT_INJECTION.md created with 8 fault scenarios
- ✅ SIMULATED_RUNS.md created with 6 simulated executions
- ✅ FAILURE_PROOF_ARTIFACTS.md created with 5 proof categories
- ✅ INVARIANT_VERIFICATION.md created with 16 invariant tests
- ✅ STOP_CONDITIONS_STEP8.md created with 5+1 STOP conditions

**Validation:**
- [ ] All 8 fault scenarios have injection points, expected failures, RunRecord formats
- [ ] All 6 simulated runs have complete IntentSpec, ToolSpec, expected result, RunRecord format
- [ ] All 5 proof artifact categories have verification methods
- [ ] All 16 invariant tests have explicit pass/fail conditions
- [ ] All 5 STOP conditions have detection methods and responses
- [ ] Forbidden progression condition (6th STOP condition) documented

**Fault Coverage:**
- [ ] Validation faults (2 scenarios)
- [ ] Configuration faults (2 scenarios)
- [ ] Boundary faults (1 scenario)
- [ ] Credential faults (1 scenario)
- [ ] Execution faults (1 scenario)
- [ ] Critic faults (1 scenario)

**Invariant Tests:**
- [ ] Schema invariants (3/3 tests)
- [ ] ToolForge invariants (5/5 tests)
- [ ] Adapter invariants (4/4 tests)
- [ ] Boundary invariants (4/4 tests)

**NO EXECUTION:**
- [ ] No real tools were executed
- [ ] No cloud services were called
- [ ] No faults were actually injected

---

## STEP 9: READ-ONLY CLOUD STATE VERIFICATION

### Acceptance Criteria

**Required Artifacts:**
- ✅ STEP9_SUCCESS_REPORT.md created with PASS result
- ✅ .env file contains SUPABASE_URL and SUPABASE_ANON_KEY

**Validation:**
- [ ] Supabase REST API endpoint is reachable
- [ ] HTTP 200 OK response received from /rest/v1/ HEAD request
- [ ] SUPABASE_URL is valid HTTPS URL
- [ ] SUPABASE_ANON_KEY is valid JWT (starts with "eyJ")
- [ ] SUPABASE_SERVICE_KEY is unset or empty

**STOP Conditions:**
- [ ] If STEP9_FAILURE_REPORT.md exists, STEP 9 is FAILED
- [ ] STEP 9 must PASS before proceeding to STEP 10
- [ ] Forbidden progression condition triggers permanent STEP 9 block

**NO EXECUTION:**
- [ ] No data was queried from Supabase
- [ ] No data was written to Supabase
- [ ] Only read-only connectivity was verified

---

## STEP 10: FREEZE DATA SCHEMA AND AUTHORITY MODEL

### Acceptance Criteria

**Required Artifacts:**
- ✅ supabase/schema/DDL_DRAFT.sql created with 10 tables
- ✅ supabase/security/ROLES_AND_RLS.md created with 5 roles
- ✅ supabase/adapters/ADAPTER_CONTRACTS.md created with 3 adapters
- ✅ .gitignore updated to exclude .claude/, .claude-flow/, .swarm/

**Validation:**
- [ ] DDL_DRAFT.sql has exactly 10 tables
- [ ] DDL_DRAFT.sql has 29 foreign keys
- [ ] DDL_DRAFT.sql has NO triggers, NO functions, NO policies, NO comments
- [ ] ROLES_AND_RLS.md has 5 roles defined
- [ ] Deny-first posture documented (anon, authenticated have 0 policies)
- [ ] Service_role quarantine explicitly stated
- [ ] ADAPTER_CONTRACTS.md has 3 adapter contracts
- [ ] All adapters have allowed operations, required inputs, returned outputs, 6 failure modes
- [ ] All adapters have explicit denials (what they cannot do)
- [ ] .gitignore excludes Claude Code runtime directories

**Schema Completeness:**
- [ ] tools table (tool registry)
- [ ] tool_versions table (version history)
- [ ] run_records table (execution records)
- [ ] run_artifacts table (execution outputs)
- [ ] intents table (intent history)
- [ ] audit_log table (audit trail)
- [ ] validation_log table (validation results)
- [ ] adapters table (adapter registry)
- [ ] adapter_events table (adapter lifecycle)
- [ ] execution_stats table (performance metrics)

**Authority Model Completeness:**
- [ ] anon role (unauthenticated public) - 0 policies
- [ ] authenticated role (authenticated users) - 0 policies
- [ ] service_role role (Supabase admin) - quarantined
- [ ] internal_system role (system operations) - defined
- [ ] future_operator role (human monitoring) - defined

**FROZEN STATE:**
- [ ] All STEP 10 artifacts committed to git
- [ ] All artifacts marked as FROZEN or IRREVERSIBLE
- [ ] No changes to STEP 10 artifacts without explicit approval

---

## STEP 11: CONTROLLED INSTANTIATION (DRY, REVERSIBLE, NON-MUTATING)

### Acceptance Criteria

**Required Artifacts:**
- ✅ migrations/planned/001_tables.sql created (DRY RUN ONLY)
- ✅ migrations/planned/002_indexes.sql created (DRY RUN ONLY)
- ✅ migrations/planned/003_constraints.sql created (DRY RUN ONLY)
- ✅ migrations/planned/004_roles_rls.sql created (DRY RUN ONLY)
- ✅ AUTHORITY_ASSERTIONS.md created with allow/deny matrix
- ✅ ADAPTER_READINESS.md created with SAFE vs UNSAFE invocation
- ✅ EXECUTION_GUARDRAILS.md created with preconditions and STOP conditions

**Validation:**
- [ ] All 4 migration files have "DRY RUN ONLY — NOT APPLIED" status header
- [ ] All 4 migration files have rollback strategies documented
- [ ] All 4 migration files have warning headers with approval requirements
- [ ] 001_tables.sql has all 10 tables with complete DDL
- [ ] 002_indexes.sql has 29 performance indexes
- [ ] 003_constraints.sql has 8 data integrity constraints
- [ ] 004_roles_rls.sql has 5 roles + RLS policies
- [ ] 004_roles_rls.sql explicitly states service_role quarantine
- [ ] AUTHORITY_ASSERTIONS.md has allow/deny matrix for all 5 roles
- [ ] AUTHORITY_ASSERTIONS.md has 30+ explicit denials
- [ ] AUTHORITY_ASSERTIONS.md has service_role quarantine rationale and safeguards
- [ ] AUTHORITY_ASSERTIONS.md has violation detection and response procedures
- [ ] ADAPTER_READINESS.md has SAFE vs UNSAFE invocation conditions
- [ ] ADAPTER_READINESS.md has 6 failure modes per adapter with recovery strategies
- [ ] ADAPTER_READINESS.md has preconditions checklist for adapter invocation
- [ ] ADAPTER_READINESS.md has universal prohibitions across all adapters
- [ ] EXECUTION_GUARDRAILS.md has 6 precondition categories (40+ individual checks)
- [ ] EXECUTION_GUARDRAILS.md has 7 STOP conditions with halt triggers
- [ ] EXECUTION_GUARDRAILS.md has 10 runtime halt conditions
- [ ] EXECUTION_GUARDRAILS.md has pre-execution checklist

**NO EXECUTION:**
- [ ] No migrations were applied to database
- [ ] No tables were created in Supabase
- [ ] No roles were created in Supabase
- [ ] No RLS policies were applied

**REVERSIBLE:**
- [ ] All migrations have documented rollback strategies
- [ ] All migrations can be rolled back without data loss
- [ ] No mutations have occurred yet

---

## STEP 12: DRIFT DETECTION AND STRUCTURAL VERIFICATION

### Acceptance Criteria

**Required Artifacts:**
- ✅ SCHEMA_DRIFT_GUARDS.md created with 6 drift detection rules
- ✅ AUTHORITY_DRIFT_GUARDS.md created with 6 authority drift rules
- ✅ ADAPTER_CONTRACT_ASSERTIONS.md created with 6 contract assertions
- ✅ EXECUTION_PRECHECK_SPEC.md created with 8 ordered prechecks
- ✅ CI_GUARDRAILS_DESIGN.md created with 6 CI guardrails (DESIGN ONLY)
- ✅ DEFINITION_OF_DONE.md updated with STEP 12 acceptance criteria
- ✅ FINAL_SUMMARY.md created with STEP 12 rationale

**Validation:**
- [ ] SCHEMA_DRIFT_GUARDS.md has 6 drift detection rules
- [ ] SCHEMA_DRIFT_GUARDS.md has automated SQL queries for each rule
- [ ] SCHEMA_DRIFT_GUARDS.md has examples of FAIL vs PASS conditions
- [ ] AUTHORITY_DRIFT_GUARDS.md has 6 authority drift detection rules
- [ ] AUTHORITY_DRIFT_GUARDS.md has automated SQL queries for each rule
- [ ] AUTHORITY_DRIFT_GUARDS.md has CRITICAL response for service_role violation
- [ ] ADAPTER_CONTRACT_ASSERTIONS.md has 6 contract assertions
- [ ] ADAPTER_CONTRACT_ASSERTIONS.md has contract versioning (1.0.0 FROZEN)
- [ ] ADAPTER_CONTRACT_ASSERTIONS.md has breaking change rules (MAJOR version bump)
- [ ] EXECUTION_PRECHECK_SPEC.md has 8 prechecks in fixed order
- [ ] EXECUTION_PRECHECK_SPEC.md has STOP condition (any FAIL halts subsequent checks)
- [ ] EXECUTION_PRECHECK_SPEC.md has PASS/FAIL conditions for each precheck
- [ ] EXECUTION_PRECHECK_SPEC.md has classification (CRITICAL, ERROR) for each precheck
- [ ] CI_GUARDRAILS_DESIGN.md has 6 CI guardrails (DESIGN ONLY, NO CI CONFIG)
- [ ] CI_GUARDRAILS_DESIGN.md has approval tokens for each guardrail
- [ ] CI_GUARDRAILS_DESIGN.md has block conditions for each guardrail
- [ ] DEFINITION_OF_DONE.md has STEP 12 acceptance criteria
- [ ] DEFINITION_OF_DONE.md has STEP 12 STOP conditions for drift detection failure
- [ ] FINAL_SUMMARY.md has STEP 12 rationale

**Drift Detection Coverage:**
- [ ] Schema drift: 6 rules (tables, columns, foreign keys, indexes, constraints, RLS)
- [ ] Authority drift: 6 rules (roles, grants, RLS, service_role, deny-first, privilege escalation)
- [ ] Adapter contract drift: 6 assertions (adapter_id, existence, operations, version, immutability, mapping)
- [ ] Precheck coverage: 8 prechecks (file integrity, environment, schema, authority, adapter, validation, migration, audit)
- [ ] CI guardrails: 6 guardrails (schema, authority, boundaries, adapters, service_role, prechecks)

**NO EXECUTION:**
- [ ] No drift detection queries were executed
- [ ] No prechecks were run
- [ ] No CI pipeline was created or executed

**STOP Conditions for STEP 12:**
- [ ] If ANY drift detection rule cannot detect violations → STEP 12 FAILED
- [ ] If ANY precheck is missing or incomplete → STEP 12 FAILED
- [ ] If ANY CI guardrail is undefined → STEP 12 FAILED
- [ ] If DEFINITION_OF_DONE.md is not updated → STEP 12 FAILED
- [ ] If FINAL_SUMMARY.md is not created → STEP 12 FAILED

**STEP 12 SUCCESS CONDITIONS:**
- [ ] All 7 required artifacts created
- [ ] All drift detection rules have automated detection queries
- [ ] All authority drift rules have CRITICAL response for violations
- [ ] All adapter contract assertions have versioning rules
- [ ] All 8 prechecks are in fixed order with STOP condition
- [ ] All 6 CI guardrails have approval tokens and block conditions
- [ ] DEFINITION_OF_DONE.md has complete STEP 12 acceptance criteria
- [ ] FINAL_SUMMARY.md explains why STEP 12 makes execution boring, safe, irreversible

---

## FINAL STOP CONDITION

**NO PROGRESSION BEYOND STEP 12 WITHOUT EXPLICIT APPROVAL:**
- [ ] All 12 steps (STEP 5 through STEP 12) are COMPLETE
- [ ] All acceptance criteria for STEP 5 through STEP 12 are MET
- [ ] All artifacts for STEP 5 through STEP 12 are COMMITTED
- [ ] NO execution has occurred in any step (DESIGN + ARTIFACT GENERATION ONLY)
- [ ] All drift detection mechanisms are in place
- [ ] All precheck specifications are defined
- [ ] All CI guardrails are designed (not implemented)

**BEFORE ANY EXECUTION (STEP 13+):**
- [ ] Explicit operator approval required
- [ ] All prechecks must PASS
- [ ] All drift detection must PASS
- [ ] All CI guardrails must PASS (if CI implemented)
- [ ] All STOP conditions must be CLEAR
- [ ] Database backup verified
- [ ] Rollback plan tested
- [ ] Audit infrastructure ready

---

## Summary

**Steps Defined:** 12 (STEP 5 through STEP 12)
**Acceptance Criteria:** Complete for all 12 steps
**Artifacts Required:** 50+ documents, schemas, workflows, specifications
**NO EXECUTION:** No execution in any step (DESIGN + ARTIFACT GENERATION ONLY)
**Drift Detection:** Complete coverage for schema, authority, adapters, prechecks, CI
**STOP Conditions:** Defined for all critical failure modes

**Key Principle:**
Each step is COMPLETE when all acceptance criteria are MET, all artifacts exist, all validations pass, and NO silent drift can occur.

**Definition of Done is IRREVERSIBLE once STEP 12 is COMPLETE.**
