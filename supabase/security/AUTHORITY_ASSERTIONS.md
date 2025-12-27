# Authority Assertions

## Purpose
**DEFINITIVE** specification of allow/deny matrix per role with explicit prohibitions.

**PRINCIPLE:** Explicitly state what each role MUST NEVER do before defining what they CAN do.

**Reference:** STEP 10 - supabase/security/ROLES_AND_RLS.md

---

## Role Authority Matrix

### Role 1: anon (Unauthenticated Public)

**ALLOWED OPERATIONS:**
- ❌ **NONE** - No access granted by default

**EXPLICIT DENIALS:**
- ❌ MUST NOT SELECT from any table
- ❌ MUST NOT INSERT into any table
- ❌ MUST NOT UPDATE any table
- ❌ MUST NOT DELETE from any table
- ❌ MUST NOT execute any functions
- ❌ MUST NOT access admin interfaces
- ❌ MUST NOT bypass RLS policies

**RATIONALE:**
Public API access is not yet required. Default-deny posture prevents accidental exposure.

**FUTURE GRANTS (NOT NOW):**
- May be granted SELECT on specific public endpoints if required
- No current use cases identified

**BOUNDARY ENFORCEMENT:**
- RLS enabled with no policies = automatic denial
- No GRANT statements issued to anon role
- All access attempts will return HTTP 401/403

---

### Role 2: authenticated (Authenticated Users)

**ALLOWED OPERATIONS:**
- ❌ **NONE** - No access granted by default

**EXPLICIT DENIALS:**
- ❌ MUST NOT SELECT from system tables (tools, adapters, audit_log)
- ❌ MUST NOT SELECT from other users' run_records
- ❌ MUST NOT INSERT into any registry table (tools, adapters)
- ❌ MUST NOT UPDATE tool or adapter definitions
- ❌ MUST NOT DELETE from any table
- ❌ MUST NOT access system-level operations
- ❌ MUST NOT modify validation gates
- ❌ MUST NOT access audit logs

**RATIONALE:**
Multi-user system is not yet implemented. Default-deny prevents data leakage.

**FUTURE GRANTS (NOT NOW):**
- May be granted SELECT on own run_records (if multi-user support added)
- May be granted SELECT on own intents (if multi-user support added)
- No current grants planned

**BOUNDARY ENFORCEMENT:**
- RLS enabled with no policies = automatic denial
- No GRANT statements issued to authenticated role
- Future policies must include user_id filtering

---

### Role 3: service_role (Supabase System Administrator)

**ALLOWED OPERATIONS:**
- ❌ **FORBIDDEN** - Not granted any application-level permissions

**EXPLICIT DENIALS:**
- 🚫 **MUST NEVER** be used in application code
- 🚫 **MUST NEVER** be used in adapter operations
- 🚫 **MUST NEVER** be used in ToolForge workflows
- 🚫 **MUST NEVER** be used in automated scripts
- 🚫 **MUST NEVER** be referenced in .env files (except SUPABASE_SERVICE_KEY placeholder)
- 🚫 **MUST NEVER** bypass validation gates
- 🚫 **MUST NEVER** be used for runtime operations

**QUARANTINE RATIONALE:**
service_role key bypasses RLS and has unlimited privileges. Using it in application code would:
- Bypass all security boundaries defined in STEP 10
- Violate the deny-first access posture
- Create irreversible security vulnerabilities
- Undermine the entire authority model

**ONLY PERMITTED USE:**
- ✅ Manual database migrations (explicit operator action)
- ✅ Emergency troubleshooting (explicit operator approval)
- ✅ Schema updates (explicit operator approval)
- ✅ Policy management (explicit operator approval)

**REQUIRED SAFEGUARDS:**
When service_role usage is required (future migrations):
1. MUST be explicitly approved by system operator
2. MUST be executed manually (not from application code)
3. MUST be documented in migration notes
4. MUST be reviewed post-execution
5. MUST be rotated after use

**ENFORCEMENT:**
- SUPABASE_SERVICE_KEY variable in .env must remain empty
- No code references service_role key
- Adapter contracts explicitly forbid service_role usage
- Validation gates reject service_role authentication attempts

---

### Role 4: internal_system (System Operations)

**ALLOWED OPERATIONS:**

**READ ACCESS:**
- ✅ CAN SELECT from all tables (for validation and execution)
- ✅ CAN read tool definitions (for validation gates)
- ✅ CAN read run_records (for execution tracking)
- ✅ CAN read audit_log (for verification)

**WRITE ACCESS (Controlled):**
- ✅ CAN INSERT into run_records (ToolForge execution)
- ✅ CAN INSERT into run_artifacts (execution outputs)
- ✅ CAN INSERT into audit_log (audit events)
- ✅ CAN INSERT into validation_log (validation results)
- ✅ CAN INSERT into adapter_events (lifecycle events)
- ✅ CAN INSERT into execution_stats (performance metrics)

**UPDATE ACCESS (Limited):**
- ✅ CAN UPDATE tools.is_active (soft delete / deprecation)
- ✅ CAN UPDATE run_artifacts.rolled_back (rollback status)
- ✅ CAN UPDATE adapters.health_status (health monitoring)

**EXPLICIT DENIALS:**
- ❌ MUST NOT DELETE from tools (use is_active flag instead)
- ❌ MUST NOT DELETE from run_records (append-only audit trail)
- ❌ MUST NOT DELETE from audit_log (strictly append-only)
- ❌ MUST NOT DELETE from validation_log (history preservation)
- ❌ MUST NOT UPDATE run_records (immutable after creation)
- ❌ MUST NOT UPDATE validation_log (immutable after creation)
- ❌ MUST NOT UPDATE adapter_events (immutable after creation)
- ❌ MUST NOT UPDATE tool definitions (tool_id, version, schemas)
- ❌ MUST NOT UPDATE adapter configurations (config_required)
- ❌ MUST NOT MODIFY schema (DDL operations)
- ❌ MUST NOT MODIFY RLS policies
- ❌ MUST NOT access service_role operations

**RATIONALE:**
internal_system role is for automated operations (n8n, adapters). It has controlled write access to execution tables only. Core schema structure is immutable.

**BOUNDARY ENFORCEMENT:**
- Explicit GRANT statements define allowed operations
- RLS policies enforce table-level access
- CHECK constraints validate data on INSERT
- No DELETE grants on append-only tables
- No UPDATE grants on immutable columns

**AUDIT REQUIREMENTS:**
- All INSERT operations must include audit_id
- All write operations must emit audit_log entry
- All failures must emit validation_log entry
- All adapter operations must emit adapter_events entry

---

### Role 5: future_operator (Human Monitoring)

**ALLOWED OPERATIONS:**

**READ ACCESS:**
- ✅ CAN SELECT from all tables (read-only monitoring)
- ✅ CAN VIEW run_records and execution history
- ✅ CAN VIEW audit_log and validation_log
- ✅ CAN VIEW adapter status and events
- ✅ CAN VIEW tool registry

**WRITE ACCESS:**
- ❌ **NONE** - Read-only by design

**EXPLICIT DENIALS:**
- ❌ MUST NOT INSERT into any table
- ❌ MUST NOT UPDATE any table
- ❌ MUST NOT DELETE from any table
- ❌ MUST NOT modify tool or adapter definitions
- ❌ MUST NOT execute system operations
- ❌ MUST NOT access service_role privileges

**RATIONALE:**
Human operators need read-only access for troubleshooting and monitoring. Write operations should go through controlled interfaces (ToolForge) with audit trails.

**BOUNDARY ENFORCEMENT:**
- Only SELECT privileges granted
- No INSERT, UPDATE, or DELETE grants
- RLS policies enforce read-only access
- Any write attempt will return permission error

**FUTURE CAPABILITIES (IF NEEDED):**
- May be granted UPDATE on specific flags via explicit approval
- May be granted access to administrative interfaces
- No current write capabilities planned

---

## Cross-Role Prohibitions

### Universal Denials (ALL Roles)

**These operations are FORBIDDEN for ALL roles:**

1. **No Direct Schema Modifications:**
   - ❌ No CREATE TABLE (except via migrations)
   - ❌ No ALTER TABLE (except via migrations)
   - ❌ No DROP TABLE (forbidden, use soft delete)
   - ❌ No TRUNCATE TABLE (forbidden)

2. **No RLS Policy Bypass:**
   - ❌ No modification of RLS policies outside migrations
   - ❌ No temporary disabling of RLS
   - ❌ No SET ROW SECURITY OFF operations

3. **No Check Constraint Bypass:**
   - ❌ No temporary disabling of constraints
   - ❌ No NOT NULL bypass
   - ❌ No FOREIGN KEY bypass

4. **No Service Role Usage:**
   - 🚫 **FORBIDDEN** for anon, authenticated, internal_system, future_operator
   - 🚫 Only permitted for manual migrations (explicit operator action)

---

## Table-Specific Authority Assertions

### Append-Only Tables (audit_log, validation_log, adapter_events, execution_stats, run_records)

**ALL ROLES:**
- ❌ MUST NOT DELETE from these tables
- ❌ MUST NOT UPDATE these tables (except specific flags)
- ✅ CAN INSERT (internal_system only)

**RATIONALE:**
Complete audit trail preservation. No history modification or deletion.

**ENFORCEMENT:**
- No DELETE grants to any role
- No UPDATE grants on core columns
- CHECK constraints validate data integrity
- RLS policies enforce append-only

---

### Immutable Tables (tool_versions, intents)

**ALL ROLES:**
- ❌ MUST NOT DELETE from these tables
- ❌ MUST NOT UPDATE these tables
- ✅ CAN INSERT (internal_system only)

**RATIONALE:**
Historical versions and intents must be preserved. No modifications.

**ENFORCEMENT:**
- No DELETE grants
- No UPDATE grants
- Historical data locked after creation

---

### Soft-Delete Tables (tools)

**internal_system:**
- ✅ CAN UPDATE is_active flag (for deprecation)
- ❌ MUST NOT DELETE rows
- ❌ MUST NOT UPDATE other columns

**RATIONALE:**
Tools are versioned. Use is_active flag for soft delete. Preserve all versions.

**ENFORCEMENT:**
- UPDATE grant limited to is_active column only
- No DELETE grant
- Version history preserved in tool_versions

---

## Service_Role Quarantine Rationale

### Why Service_Role is Forbidden

**service_role bypasses ALL RLS policies.** Using it in application code would:

1. **Violate the deny-first posture:**
   - RLS is designed to deny by default
   - service_role bypasses this entirely
   - Creates a security backdoor

2. **Undermine the authority model:**
   - All roles are defined with explicit grants
   - service_role has implicit unlimited access
   - Breaks the principle of least privilege

3. **Prevent audit trail integrity:**
   - service_role can modify audit_log
   - service_role can delete run_records
   - Destroys the append-only guarantee

4. **Enable irreversible actions:**
   - service_role can DROP TABLES
   - service_role can DELETE data
   - service_role can modify schema
   - These actions cannot be undone

### When Service_Role WILL Be Allowed

**ONLY in these specific scenarios:**

1. **Manual Migrations:**
   - Schema updates (DDL)
   - RLS policy changes
   - Constraint additions
   - Index creation

2. **Emergency Troubleshooting:**
   - Direct database access for debugging
   - Data recovery operations
   - Performance analysis

3. **Explicit Operator Actions:**
   - Operator-initiated (not automated)
   - Documented in migration notes
   - Reviewed and approved
   - Time-limited (key rotation after use)

### Safeguards for Service_Role Usage

When service_role is used (future migrations):

**Pre-Execution:**
1. ✅ Explicit operator approval required
2. ✅ Migration plan documented
3. ✅ Rollback plan tested
4. ✅ Database backup verified
5. ✅ Impact analysis completed

**During Execution:**
1. ✅ Manual execution only (no automation)
2. ✅ Transaction logged
3. ✅ Each step verified
4. ✅ Ready to rollback on error

**Post-Execution:**
1. ✅ Changes verified
2. ✅ RLS policies tested
3. ✅ Role grants re-verified
4. ✅ Service role key rotated
5. ✅ Audit log reviewed

---

## Authority Violation Detection

### What Constitutes a Violation

**VIOLATION: Any role performing an operation not explicitly allowed:**

1. **anon or authenticated attempting SELECT:**
   - Violation of deny-first posture
   - Should be blocked by RLS

2. **internal_system attempting DELETE on append-only table:**
   - Violation of audit trail integrity
   - Should be blocked by missing GRANT

3. **internal_system attempting UPDATE on immutable column:**
   - Violation of data immutability
   - Should be blocked by missing GRANT or RLS

4. **future_operator attempting INSERT:**
   - Violation of read-only posture
   - Should be blocked by missing GRANT

5. **Any role using service_role in application code:**
   - CRITICAL violation of service_role quarantine
   - Should be blocked by validation gates
   - Should emit CRITICAL audit event

### Violation Response

**When a violation is detected:**

1. **Halt Operation Immediately:**
   - Stop the operation
   - Prevent completion
   - Preserve state for investigation

2. **Emit CRITICAL Audit Event:**
   - Log violation attempt
   - Include role, operation, table, timestamp
   - Include stack trace if available

3. **Alert Operator:**
   - CRITICAL RunRecord emitted
   - Security violation flagged
   - Requires immediate investigation

4. **Do Not Retry:**
   - Violations are persistent (not transient errors)
   - Retry will not fix permission issue
   - Requires explicit role/permission fix

---

## Summary

**Roles Defined:** 5 (anon, authenticated, service_role, internal_system, future_operator)
**Explicit Denials:** 30+ specific prohibitions documented
**Service_Role Status:** QUARANTINED - forbidden in application code
**Violation Detection:** All violations emit CRITICAL audit events
**Authority Model:** Frozen, deny-first, explicit grants only

**Key Assertions:**
- All access explicitly defined, no implicit permissions
- Service role forbidden until migrations
- Append-only tables protected (no DELETE/UPDATE)
- Immutable data protected (no UPDATE)
- Soft delete pattern enforced
- All violations logged and halted

**This authority model is irreversible without explicit review and documentation update.**
