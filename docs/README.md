# Samwise Documentation

Complete documentation for the Samwise self-governing AI agent system.

## Quick Navigation

- **New to Samwise?** Start with [01-architecture/ARCHITECTURE.md](01-architecture/ARCHITECTURE.md)
- **Setting up execution?** Read [02-governance/EXECUTION_UNLOCK_PROTOCOL.md](02-governance/EXECUTION_UNLOCK_PROTOCOL.md)
- **Troubleshooting?** Check [03-execution/RECOVERY.md](03-execution/RECOVERY.md)
- **Security concerns?** See [05-security/THREAT_MODEL.md](05-security/THREAT_MODEL.md)

---

## Documentation Categories

### 01. Architecture
System design, components, and data contracts.

- [ARCHITECTURE.md](01-architecture/ARCHITECTURE.md) - High-level system architecture and design principles
- [CLOUD_ADAPTER_INTERFACES.md](01-architecture/CLOUD_ADAPTER_INTERFACES.md) - Cloud service adapter specifications
- [ADAPTER_CONTRACT_ASSERTIONS.md](01-architecture/ADAPTER_CONTRACT_ASSERTIONS.md) - Adapter contract validation rules

**Read First:** Start here to understand the system architecture.

---

### 02. Governance
Human authorization, access control, and execution unlock procedures.

- [OPERATOR_AUTHORIZATION_MODEL.md](02-governance/OPERATOR_AUTHORIZATION_MODEL.md) - Human roles and permissions (5 roles defined)
- [EXECUTION_UNLOCK_PROTOCOL.md](02-governance/EXECUTION_UNLOCK_PROTOCOL.md) - **REQUIRED READING** - How to unlock execution (4-phase protocol)
- [TWO_KEY_RULE_SPEC.md](02-governance/TWO_KEY_RULE_SPEC.md) - Dual-approval mechanism (technical + human)
- [CHANGE_AUTHORIZATION_LOG.md](02-governance/CHANGE_AUTHORIZATION_LOG.md) - Append-only authorization records
- [EMERGENCY_BRAKE_SPEC.md](02-governance/EMERGENCY_BRAKE_SPEC.md) - Immediate halt mechanism

**Read Before:** Enabling any execution or deployment.

---

### 03. Execution
Runtime execution procedures, boundaries, and operations.

- [EXECUTION_BOUNDARIES.md](03-execution/EXECUTION_BOUNDARIES.md) - LOCAL vs CLOUD service boundaries
- [EXECUTION_GUARDRAILS.md](03-execution/EXECUTION_GUARDRAILS.md) - Preconditions and STOP conditions
- [EXECUTION_PRECHECK_SPEC.md](03-execution/EXECUTION_PRECHECK_SPEC.md) - **REQUIRED READING** - 8 prechecks before execution
- [OPERATING_RULES.md](03-execution/OPERATING_RULES.md) - Operational procedures and guidelines
- [RECOVERY.md](03-execution/RECOVERY.md) - Recovery and rollback procedures

**Read Before:** Running any tools, workflows, or deployments.

---

### 04. Validation
Quality assurance, testing, and drift detection.

- [SCHEMA_DRIFT_GUARDS.md](04-validation/SCHEMA_DRIFT_GUARDS.md) - Database schema drift detection (6 rules)
- [AUTHORITY_DRIFT_GUARDS.md](04-validation/AUTHORITY_DRIFT_GUARDS.md) - Authority model drift detection (6 rules)
- [DRY_RUN_VALIDATION.md](04-validation/DRY_RUN_VALIDATION.md) - Dry-run validation methodology
- [INVARIANT_VERIFICATION.md](04-validation/INVARIANT_VERIFICATION.md) - System invariant tests (16 tests)
- [FAULT_INJECTION.md](04-validation/FAULT_INJECTION.md) - Fault injection testing (8 scenarios)
- [SIMULATED_RUNS.md](04-validation/SIMULATED_RUNS.md) - Simulated execution examples (6 simulations)
- [FAILURE_PROOF_ARTIFACTS.md](04-validation/FAILURE_PROOF_ARTIFACTS.md) - Verification methods for failures
- [CI_GUARDRAILS_DESIGN.md](04-validation/CI_GUARDRAILS_DESIGN.md) - CI checks for merges (DESIGN ONLY)

**Read For:** Understanding validation and testing methodology.

---

### 05. Security
Security models, threat analysis, and trust assumptions.

- [THREAT_MODEL.md](05-security/THREAT_MODEL.md) - Security threat analysis
- [FAILURE_OF_TRUST.md](05-security/FAILURE_OF_TRUST.md) - **CRITICAL** - System protects against untrustworthy operators (10 protections)
- [STOP_CONDITIONS.md](05-security/STOP_CONDITIONS.md) - When to halt execution
- [STOP_CONDITIONS_STEP8.md](05-security/STOP_CONDITIONS_STEP8.md) - STOP conditions for simulated execution
- [FAILURE_GUARANTEES.md](05-security/FAILURE_GUARANTEES.md) - Failure mode specifications

**Read For:** Understanding security posture and failure handling.

---

### 06. Configuration
Configuration reference and environment setup.

- [ENV_VAR_MAPPING.md](06-configuration/ENV_VAR_MAPPING.md) - Environment variable documentation
- [ENVIRONMENT_RESOLUTION.md](06-configuration/ENVIRONMENT_RESOLUTION.md) - Environment variable resolution priority
- [PORTS_AND_LIMITS.md](06-configuration/PORTS_AND_LIMITS.md) - Port assignments and resource limits

**Read For:** Setting up environment and configuration.

---

### 07. Project
Project management, milestones, and completion criteria.

- [DEFINITION_OF_DONE.md](07-project/DEFINITION_OF_DONE.md) - **REQUIRED READING** - Acceptance criteria for all 13 steps
- [DECISIONS.md](07-project/DECISIONS.md) - Project decision log
- [FINAL_SUMMARY.md](07-project/FINAL_SUMMARY.md) - Why STEP 12 makes execution boring, safe, irreversible
- [STEP_13_FINAL_SUMMARY.md](07-project/STEP_13_FINAL_SUMMARY.md) - Why STEP 13 makes power boring and mistakes survivable

#### Milestones
Historical milestone reports:
- [STEP9_FAILURE_REPORT.md](07-project/milestones/STEP9_FAILURE_REPORT.md) - STEP 9 initial failure (missing credentials)
- [STEP9_SUCCESS_REPORT.md](07-project/milestones/STEP9_SUCCESS_REPORT.md) - STEP 9 success (connectivity verified)

**Read For:** Understanding project progress and completion status.

---

## Reading Order (Recommended)

### For New Contributors

1. **Architecture First** (30 minutes)
   - [01-architecture/ARCHITECTURE.md](01-architecture/ARCHITECTURE.md)
   - [01-architecture/CLOUD_ADAPTER_INTERFACES.md](01-architecture/CLOUD_ADAPTER_INTERFACES.md)

2. **Then Security** (15 minutes)
   - [05-security/FAILURE_OF_TRUST.md](05-security/FAILURE_OF_TRUST.md)
   - [05-security/THREAT_MODEL.md](05-security/THREAT_MODEL.md)

3. **Then Governance** (45 minutes)
   - [02-governance/OPERATOR_AUTHORIZATION_MODEL.md](02-governance/OPERATOR_AUTHORIZATION_MODEL.md)
   - [02-governance/EXECUTION_UNLOCK_PROTOCOL.md](02-governance/EXECUTION_UNLOCK_PROTOCOL.md)

4. **Then Execution** (30 minutes)
   - [03-execution/EXECUTION_PRECHECK_SPEC.md](03-execution/EXECUTION_PRECHECK_SPEC.md)
   - [03-execution/EXECUTION_BOUNDARIES.md](03-execution/EXECUTION_BOUNDARIES.md)

### Before Enabling Execution

**REQUIRED READ:**
1. [02-governance/EXECUTION_UNLOCK_PROTOCOL.md](02-governance/EXECUTION_UNLOCK_PROTOCOL.md) - Two-key rule
2. [03-execution/EXECUTION_PRECHECK_SPEC.md](03-execution/EXECUTION_PRECHECK_SPEC.md) - All 8 prechecks
3. [04-validation/SCHEMA_DRIFT_GUARDS.md](04-validation/SCHEMA_DRIFT_GUARDS.md) - Drift detection
4. [07-project/DEFINITION_OF_DONE.md](07-project/DEFINITION_OF_DONE.md) - Completion criteria

### Before Making Changes

1. [04-validation/CI_GUARDRAILS_DESIGN.md](04-validation/CI_GUARDRAILS_DESIGN.md) - What changes require approval
2. [02-governance/TWO_KEY_RULE_SPEC.md](02-governance/TWO_KEY_RULE_SPEC.md) - Dual approval requirements
3. [02-governance/EMERGENCY_BRAKE_SPEC.md](02-governance/EMERGENCY_BRAKE_SPEC.md) - Emergency procedures

---

## Most-Used Quick Links

### I want to...

- **Understand the system:** [01-architecture/ARCHITECTURE.md](01-architecture/ARCHITECTURE.md)
- **Enable execution:** [02-governance/EXECUTION_UNLOCK_PROTOCOL.md](02-governance/EXECUTION_UNLOCK_PROTOCOL.md)
- **Troubleshoot:** [03-execution/RECOVERY.md](03-execution/RECOVERY.md)
- **Verify schema:** [04-validation/SCHEMA_DRIFT_GUARDS.md](04-validation/SCHEMA_DRIFT_GUARDS.md)
- **Understand security:** [05-security/FAILURE_OF_TRUST.md](05-security/FAILURE_OF_TRUST.md)
- **Configure environment:** [06-configuration/ENV_VAR_MAPPING.md](06-configuration/ENV_VAR_MAPPING.md)
- **Check completion:** [07-project/DEFINITION_OF_DONE.md](07-project/DEFINITION_OF_DONE.md)

---

## System Status

**Current Phase:** Design Complete (STEP 13)

**All 13 Steps Complete:**
- ✅ STEP 5: n8n ToolForge Development
- ✅ STEP 6: Execution Boundary Enforcement
- ✅ STEP 7: Runtime Integration
- ✅ STEP 8: Controlled Execution Simulation
- ✅ STEP 9: Read-Only Cloud State Verification
- ✅ STEP 10: Freeze Data Schema and Authority Model
- ✅ STEP 11: Controlled Instantiation
- ✅ STEP 12: Drift Detection and Structural Verification
- ✅ STEP 13: Human Authorization and Execution Unlock Protocols

**Execution Status:** DISABLED (requires two-key unlock)

**Next Action:** See [EXECUTION_UNLOCK_PROTOCOL.md](02-governance/EXECUTION_UNLOCK_PROTOCOL.md)

---

## Key Principles

1. **No Silent Drift:** All schema/authority changes require approval and detection
2. **Two-Person Rule:** Execution unlock requires two different humans
3. **Emergency Brake:** Anyone can halt execution immediately
4. **Trust-Minimized:** System protects against untrustworthy operators
5. **Append-Only Logs:** All actions are logged permanently
6. **Precheck First:** All 8 prechecks must PASS before execution

---

## Additional Documentation

### Service Documentation
- [services/n8n/toolforge/](../services/n8n/toolforge/) - n8n ToolForge workflows
- [services/supabase/schema/](../services/supabase/schema/) - Database schema
- [services/supabase/security/](../services/supabase/security/) - Security policies
- [services/docker/](../services/docker/) - Docker service configurations

### Data Contracts
- [../claude-flow/contracts/](../claude-flow/contracts/) - Intent/Tool/Run record schemas

### Migration Files
- [../migrations/planned/](../migrations/planned/) - SQL migration files (DRY RUN ONLY)

---

## Getting Help

1. **Check Documentation First:** Most answers are in the docs above
2. **Check Milestones:** See [07-project/milestones/](07-project/milestones/) for historical issues
3. **Read FAILURE_OF_TRUST:** Understand how the system protects itself
4. **Emergency?** See [EMERGENCY_BRAKE_SPEC.md](02-governance/EMERGENCY_BRAKE_SPEC.md)

---

**Last Updated:** STEP 13 (Human Authorization and Execution Unlock Protocols)

**Documentation Version:** 13.0
