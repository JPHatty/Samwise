# Roles and Row-Level Security Design

## Purpose
**DEFINITIVE** specification of database roles, access controls, and Row-Level Security (RLS) policies for Samwise.

**PRINCIPLE:** Deny-first posture. Explicitly state who CANNOT access before defining who CAN.

**STATUS:** DESIGN ONLY - DO NOT EXECUTE

---

## Database Roles

### Role Definitions

#### 1. anon
**Purpose:** Unauthenticated access (public API)
**Capabilities:** NONE (by default)
**Usage:** Placeholder for future public read-only endpoints

**Explicit DENY:**
- ❌ Cannot SELECT from any table (until explicitly granted)
- ❌ Cannot INSERT, UPDATE, DELETE on any table
- ❌ Cannot execute any functions
- ❌ Cannot access admin interfaces

**Future Grants (to be defined later):**
- May be granted SELECT on specific public endpoints (if needed)
- No current grants planned

---

#### 2. authenticated
**Purpose:** Authenticated users (future JWT-based access)
**Capabilities:** NONE (by default)
**Usage:** Reserved for future multi-user scenarios

**Explicit DENY:**
- ❌ Cannot SELECT from system tables (tools, adapters, audit_log)
- ❌ Cannot INSERT, UPDATE, DELETE on any registry table
- ❌ Cannot modify tools or adapters
- ❌ Cannot access other users' run_records

**Future Grants (to be defined later):**
- May be granted SELECT on own run_records
- No current grants planned

---

#### 3. service_role
**Purpose:** Supabase system administrator
**Capabilities:** Bypasses RLS (built into Supabase)
**Usage:** FORBIDDEN until explicitly required

**EXPLICIT DENY (until later step):**
- 🚫 **FORBIDDEN** from use in application code
- 🚫 **FORBIDDEN** from adapter operations
- 🚫 **FORBIDDEN** from ToolForge workflows
- 🚫 **FORBIDDEN** from any automated operations

**When WILL be allowed (future step, not now):**
- Manual migrations only
- Manual schema updates
- Emergency troubleshooting by operator
- NEVER in application code

**Required safeguard:**
- service_role key MUST NOT be referenced in any .env file
- service_role key MUST NOT be used in any adapter code
- Any use MUST require explicit operator approval

---

#### 4. internal_system
**Purpose:** Internal system operations (n8n, adapters)
**Capabilities:** Controlled write access to specific tables
**Usage:** Automated system operations only

**Allowed Operations:**
- ✅ Can INSERT into run_records
- ✅ Can INSERT into run_artifacts
- ✅ Can INSERT into audit_log
- ✅ Can INSERT into validation_log
- ✅ Can INSERT into adapter_events
- ✅ Can UPDATE tool status (is_active flag only)
- ✅ Can SELECT from all tables (for validation and execution)

**Explicit DENY:**
- ❌ Cannot DELETE from tools (use soft delete via is_active)
- ❌ Cannot MODIFY tool definitions (tool_id, version, schemas)
- ❌ Cannot DELETE from audit_log (append-only)
- ❌ Cannot DELETE from run_records (append-only)
- ❌ Cannot MODIFY adapter configurations
- ❌ Cannot access service_role operations

---

#### 5. future_operator
**Purpose:** Human operator for manual operations
**Capabilities:** Read-only access to all data
**Usage:** Troubleshooting, monitoring, manual verification

**Allowed Operations:**
- ✅ Can SELECT from all tables
- ✅ Can VIEW run_records and audit logs
- ✅ Can MONITOR adapter status

**Explicit DENY:**
- ❌ Cannot INSERT, UPDATE, DELETE on any table
- ❌ Cannot modify tools or adapters
- ❌ Cannot execute system operations

**Future capability (if needed):**
- May be granted UPDATE on specific flags via explicit approval
- No current write capabilities planned

---

## Table-Specific Access Controls

### tools Table

**Who can SELECT:**
- ✅ internal_system (for validation and registration)
- ✅ future_operator (read-only monitoring)
- ❌ anon (denied)
- ❌ authenticated (denied)
- ❌ service_role (forbidden until migrations)

**Who can INSERT:**
- ✅ internal_system (tool registration only)
- ❌ All others denied

**Who can UPDATE:**
- ✅ internal_system (is_active flag only for deprecation)
- ❌ All others denied

**Who can DELETE:**
- ❌ **NO ONE** - Use soft delete via is_active flag
- ❌ Direct DELETE operations explicitly forbidden

**RLS Policy Intent:**
- internal_system can read all tools for validation
- No one can delete tools (soft delete only)
- Tool definitions immutable after creation (versioned updates only)

---

### tool_versions Table

**Who can SELECT:**
- ✅ internal_system
- ✅ future_operator
- ❌ anon, authenticated, service_role (forbidden)

**Who can INSERT:**
- ✅ internal_system (when deprecating tools)
- ❌ All others denied

**Who can UPDATE:**
- ❌ **NO ONE** - Historical versions immutable
- ❌ All denied

**Who can DELETE:**
- ❌ **NO ONE** - Historical versions preserved

**RLS Policy Intent:**
- Append-only version history
- No modifications to historical data
- Deprecation tracked via status changes

---

### run_records Table

**Who can SELECT:**
- ✅ internal_system (for execution and validation)
- ✅ future_operator (monitoring and troubleshooting)
- ❌ anon (denied)
- ❌ authenticated (denied - future: may allow own records)
- ❌ service_role (forbidden)

**Who can INSERT:**
- ✅ internal_system (ToolForge execution only)
- ❌ All others denied

**Who can UPDATE:**
- ❌ **NO ONE** - Run records immutable
- ❌ All denied

**Who can DELETE:**
- ❌ **NO ONE** - Append-only audit trail
- ❌ All denied

**RLS Policy Intent:**
- Append-only execution history
- No modifications after creation
- Complete audit trail preserved

---

### run_artifacts Table

**Who can SELECT:**
- ✅ internal_system
- ✅ future_operator
- ❌ anon, authenticated, service_role

**Who can INSERT:**
- ✅ internal_system (execution artifacts)
- ❌ All others denied

**Who can UPDATE:**
- ✅ internal_system (rolled_back flag only)
- ❌ All others denied

**Who can DELETE:**
- ❌ **NO ONE** - Artifacts preserved

**RLS Policy Intent:**
- Append-only artifact tracking
- Rollback status can be updated
- No artifact deletion

---

### intents Table

**Who can SELECT:**
- ✅ internal_system
- ✅ future_operator
- ❌ anon, authenticated, service_role

**Who can INSERT:**
- ✅ internal_system (intent registration)
- ❌ All others denied

**Who can UPDATE:**
- ❌ **NO ONE** - Intents immutable
- ❌ All denied

**Who can DELETE:**
- ❌ **NO ONE** - Intents preserved

**RLS Policy Intent:**
- Append-only intent history
- No modifications after creation

---

### audit_log Table

**Who can SELECT:**
- ✅ internal_system
- ✅ future_operator
- ❌ anon, authenticated, service_role

**Who can INSERT:**
- ✅ internal_system (audit logging)
- ❌ All others denied

**Who can UPDATE:**
- ❌ **NO ONE** - Audit log immutable
- ❌ All denied

**Who can DELETE:**
- ❌ **NO ONE** - Audit log append-only, never deleted
- ❌ All denied

**RLS Policy Intent:**
- **STRICT APPEND-ONLY**
- No modifications under any circumstances
- No deletions under any circumstances
- Complete audit trail preserved forever

---

### validation_log Table

**Who can SELECT:**
- ✅ internal_system
- ✅ future_operator
- ❌ anon, authenticated, service_role

**Who can INSERT:**
- ✅ internal_system (validation results)
- ❌ All others denied

**Who can UPDATE:**
- ❌ **NO ONE** - Validation results immutable
- ❌ All denied

**Who can DELETE:**
- ❌ **NO ONE** - Validation history preserved
- ❌ All denied

**RLS Policy Intent:**
- Append-only validation history
- Complete record of all validation gate results

---

### adapters Table

**Who can SELECT:**
- ✅ internal_system
- ✅ future_operator
- ❌ anon, authenticated, service_role

**Who can INSERT:**
- ❌ **NO ONE** - Adapters defined at schema creation
- ❌ All denied

**Who can UPDATE:**
- ✅ internal_system (health_status only)
- ❌ All other updates denied

**Who can DELETE:**
- ❌ **NO ONE** - Adapters cannot be deleted
- ❌ All denied

**RLS Policy Intent:**
- Adapter configuration immutable
- Only health status can be updated
- No adapter deletion

---

### adapter_events Table

**Who can SELECT:**
- ✅ internal_system
- ✅ future_operator
- ❌ anon, authenticated, service_role

**Who can INSERT:**
- ✅ internal_system (adapter lifecycle events)
- ❌ All others denied

**Who can UPDATE:**
- ❌ **NO ONE** - Adapter events immutable
- ❌ All denied

**Who can DELETE:**
- ❌ **NO ONE** - Adapter history preserved
- ❌ All denied

**RLS Policy Intent:**
- Append-only adapter event log
- Complete adapter lifecycle history

---

### execution_stats Table

**Who can SELECT:**
- ✅ internal_system
- ✅ future_operator
- ❌ anon, authenticated, service_role

**Who can INSERT:**
- ✅ internal_system (execution metrics)
- ❌ All others denied

**Who can UPDATE:**
- ❌ **NO ONE** - Stats immutable
- ❌ All denied

**Who can DELETE:**
- ❌ **NO ONE** - Stats preserved
- ❌ All denied

**RLS Policy Intent:**
- Append-only performance metrics
- No modifications after creation

---

## Cross-Cutting Security Principles

### 1. Append-Only Audit Trail
**Tables:** audit_log, validation_log, adapter_events, execution_stats, run_records
**Rule:** Once written, NEVER modified or deleted
**Enforcement:** No UPDATE or DELETE grants for any role

### 2. Immutable Configuration
**Tables:** tools, adapters
**Rule:** Core schema structure immutable
**Enforcement:** No DELETE operations, limited UPDATE

### 3. Soft Delete Pattern
**Tables:** tools
**Rule:** Use is_active flag instead of DELETE
**Enforcement:** No DELETE grants for any role

### 4. Version History
**Tables:** tool_versions
**Rule:** All versions preserved, no historical modifications
**Enforcement:** No UPDATE or DELETE on version records

### 5. Service_Role Isolation
**Rule:** service_role key NEVER used in application code
**Enforcement:** Explicit forbidden status until migrations
**Future Use:** Manual operations only with operator approval

### 6. Internal System Boundaries
**Role:** internal_system
**Capabilities:** Controlled writes to execution tables only
**Restrictions:** Cannot modify schema structure, cannot delete audit data
**Enforcement:** Explicit GRANT/REVOKE statements

---

## Future RLS Implementation Notes

**THIS DOCUMENT DEFINES INTENT, NOT IMPLEMENTATION**

When implementing RLS policies (future step), follow these principles:

1. **Enable RLS on ALL tables** (ALTER TABLE ... ENABLE ROW LEVEL SECURITY)
2. **Default policy:** DENY ALL (no implicit access)
3. **Explicit policies:** GRANT only what's defined above
4. **Policy names:** Use descriptive names matching this document
5. **Policy checks:** Use role-based checks (auth.uid() = role_id or similar)
6. **No service_role policies:** Service role bypasses RLS by design, so forbid via application logic

---

## Summary

**Roles Defined:** 5 (anon, authenticated, service_role, internal_system, future_operator)
**Tables Protected:** 10 (all tables)
**Access Posture:** Deny-first (explicit DENY before any GRANT)
**Append-Only Tables:** 5 (audit_log, validation_log, adapter_events, execution_stats, run_records)
**Immutable Tables:** 3 (tools versions, intents, tool definitions)
**Service_Role Status:** FORBIDDEN until migrations

**Key Constraints:**
- No DELETE operations on core tables (soft delete only)
- No UPDATE on audit/history tables
- No service_role use in application code
- All access explicitly defined, no implicit permissions

**This design freezes the authority model. Future changes require explicit review and documentation update.**
