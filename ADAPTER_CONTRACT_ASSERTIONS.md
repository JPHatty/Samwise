# Adapter Contract Assertions

## Purpose
**DEFINITIVE** specification of ToolSpec → Adapter mapping invariants to prevent silent breaking changes.

**PRINCIPLE:** Adapter contracts are versioned and immutable. Changes require explicit version bumps.

**Reference:** STEP 10 - supabase/adapters/ADAPTER_CONTRACTS.md

---

## What Are Adapter Contract Assertions?

**Adapter Contract Assertion:** A guarantee that the ToolSpec → Adapter mapping cannot change silently.

**Why Assertions Matter:**
1. **Breaking Changes Detection:** ToolSpecs that reference non-existent adapters fail immediately
2. **Version Compatibility:** Adapter version changes require explicit ToolSpec updates
3. **Interface Stability:** Adapter operations cannot change without version bump
4. **Runtime Safety:** Adapter failures are detected before execution

**What Assertions Prevent:**
- Silent breaking changes (adapter removed, operation changed)
- Contract violations (ToolSpec references invalid adapter)
- Interface drift (adapter operation signature changed)
- Version confusion (wrong adapter version in use)

---

## Assertion 1: Required adapter_id Invariant

**Statement:** All ToolSpecs with execution_mode="remote" MUST specify adapter_id.

**Invariant:**
```json
{
  "execution_mode": "remote",
  "adapter_id": "TEXT (not null, matches pattern ^[a-z0-9-]+$)"
}
```

**Assertion Logic:**
- IF execution_mode = "remote" AND adapter_id IS NULL → FAIL
- IF execution_mode = "remote" AND adapter_id DOES NOT MATCH PATTERN → FAIL
- IF execution_mode = "local" AND adapter_id IS NOT NULL → FAIL (local tools have no adapters)

**PASS Example:**
```json
{
  "tool_id": "vector-search",
  "execution_mode": "remote",
  "adapter_id": "qdrant-vector",  // ← Valid adapter_id
  "adapter_operation": "search"
}
```

**FAIL Example:**
```json
{
  "tool_id": "vector-search",
  "execution_mode": "remote",
  // adapter_id is MISSING  // ← VIOLATION
  "adapter_operation": "search"
}
```

**Detection:**
```javascript
// Validation gate check (STEP 5, GATE 4)
if (toolspec.execution_mode === 'remote') {
  if (!toolspec.adapter_id) {
    throw new Error('REMOTE tools MUST specify adapter_id');
  }
  if (!/^[a-z0-9-]+$/.test(toolspec.adapter_id)) {
    throw new Error('adapter_id must match pattern ^[a-z0-9-]+$');
  }
}
```

**Runtime Enforcement:**
- GATE 4: ToolSpec Validation (Rule 7)
- Fails immediately if adapter_id is missing or invalid
- No ToolSpec without adapter_id proceeds to execution

---

## Assertion 2: Adapter Existence Invariant

**Statement:** All adapter_id values MUST reference existing adapters.

**Valid Adapter IDs (from STEP 10):**
1. `supabase-postgres`
2. `qdrant-vector`
3. `meilisearch`
4. `cloudflare-r2`
5. `prometheus`
6. `loki`
7. `grafana`
8. `livekit`

**Invariant:**
- IF ToolSpec.adapter_id IS NOT IN VALID LIST → FAIL
- IF ToolSpec.adapter_id DOES NOT EXIST IN ADAPTER_REGISTRY → FAIL

**PASS Example:**
```json
{
  "adapter_id": "qdrant-vector",  // ← Valid adapter
  "adapter_operation": "search"
}
```

**FAIL Example:**
```json
{
  "adapter_id": "invalid-adapter",  // ← Not in valid list
  "adapter_operation": "search"
}
```

**Detection:**
```javascript
// Adapter registry lookup
const validAdapters = [
  'supabase-postgres',
  'qdrant-vector',
  'meilisearch',
  'cloudflare-r2',
  'prometheus',
  'loki',
  'grafana',
  'livekit'
];

if (toolspec.adapter_id && !validAdapters.includes(toolspec.adapter_id)) {
  throw new Error(`Invalid adapter_id: ${toolspec.adapter_id}`);
}
```

**Runtime Enforcement:**
- GATE 4: ToolSpec Validation (Rule 8)
- Queries adapter registry for existence check
- Fails immediately if adapter does not exist

---

## Assertion 3: Adapter Operation Invariant

**Statement:** adapter_operation MUST match operations defined in adapter interface.

**Adapter Operation Mappings:**

**supabase-postgres operations:**
- query
- vector_search

**qdrant-vector operations:**
- search
- upsert
- create_collection
- health_check

**meilisearch operations:**
- search

**cloudflare-r2 operations:**
- put_object
- get_object

**prometheus operations:**
- query_metrics

**loki operations:**
- query_logs

**grafana operations:**
- query_dashboard

**livekit operations:**
- create_room
- join_room

**Invariant:**
- IF ToolSpec.adapter_operation NOT IN ADAPTER.OPERATIONS → FAIL

**PASS Example:**
```json
{
  "adapter_id": "qdrant-vector",
  "adapter_operation": "search"  // ← Valid operation for qdrant-vector
}
```

**FAIL Example:**
```json
{
  "adapter_id": "qdrant-vector",
  "adapter_operation": "drop_all_collections"  // ← Invalid operation
}
```

**Detection:**
```javascript
// Adapter interface lookup
const adapterInterfaces = {
  'qdrant-vector': {
    operations: ['search', 'upsert', 'create_collection', 'health_check']
  },
  'supabase-postgres': {
    operations: ['query', 'vector_search']
  }
  // ... other adapters
};

const adapter = adapterInterfaces[toolspec.adapter_id];
if (adapter && !adapter.operations.includes(toolspec.adapter_operation)) {
  throw new Error(`Invalid operation '${toolspec.adapter_operation}' for adapter '${toolspec.adapter_id}'`);
}
```

**Runtime Enforcement:**
- GATE 4: ToolSpec Validation (Rule 9)
- Queries adapter interface for operation list
- Fails immediately if operation is not in interface

---

## Assertion 4: Contract Version Invariant

**Statement:** Adapter contracts are versioned. Breaking changes require version bump.

**Contract Versioning:**
- Contract version: 1.0.0 (defined in STEP 10)
- Semantic versioning: MAJOR.MINOR.PATCH
- MAJOR: Breaking changes (operation removed, interface changed)
- MINOR: New operations added (backwards compatible)
- PATCH: Bug fixes, documentation

**Breaking Changes:**
- Removing an adapter operation
- Changing an operation signature
- Adding required input field
- Changing output structure
- Removing adapter entirely

**Non-Breaking Changes:**
- Adding new optional input field
- Adding new operation (backwards compatible)
- Expanding allowed values for enum field
- Updating documentation

**Invariant:**
- IF CONTRACT MAJOR VERSION CHANGES → ALL TOOLSCIPS MUST UPDATE
- IF CONTRACT MINOR VERSION INCREASES → EXISTING TOOLSCIPS STILL VALID
- IF ADAPTER REMOVED → ALL TOOLSCIPS USING IT MUST FAIL

**PASS Example (Version Compatible):**
```json
// Contract: 1.0.0
// ToolSpec using valid operation
{
  "adapter_id": "qdrant-vector",
  "adapter_operation": "search",
  "adapter_contract_version": "1.0.0"  // ← Explicit version
}
```

**FAIL Example (Version Incompatible):**
```json
// Contract: 2.0.0 (breaking change - 'search' operation removed)
// ToolSpec using removed operation
{
  "adapter_id": "qdrant-vector",
  "adapter_operation": "search",  // ← Operation removed in v2.0.0
  "adapter_contract_version": "1.0.0"
}
```

**Detection:**
```javascript
// Version compatibility check
const adapterVersion = getAdapterVersion(toolspec.adapter_id); // "1.0.0"
const contractVersion = toolspec.adapter_contract_version || "1.0.0";

if (semver.major(adapterVersion) !== semver.major(contractVersion)) {
  throw new Error(`Contract version mismatch: adapter v${adapterVersion} != ToolSpec v${contractVersion}`);
}

// Also check operation still exists in current adapter version
if (!operationExistsInVersion(toolspec.adapter_id, toolspec.adapter_operation, adapterVersion)) {
  throw new Error(`Operation '${toolspec.adapter_operation}' removed in adapter v${adapterVersion}`);
}
```

**Runtime Enforcement:**
- Adapter registry stores contract version for each adapter
- ToolSpec validation checks version compatibility
- Breaking changes cause immediate failure

---

## Assertion 5: Contract Immutability Invariant

**Statement:** Adapter contracts in STEP 10 are FROZEN and cannot change without explicit approval.

**Frozen Contracts:**
- supabase-postgres: v1.0.0 (FROZEN)
- qdrant-vector: v1.0.0 (FROZEN)
- meilisearch: v1.0.0 (FROZEN)
- cloudflare-r2: v1.0.0 (FROZEN)
- prometheus: v1.0.0 (FROZEN)
- loki: v1.0.0 (FROZEN)
- grafana: v1.0.0 (FROZEN)
- livekit: v1.0.0 (FROZEN)

**Invariant:**
- ADAPTER_CONTRACTS.md CANNOT BE MODIFIED WITHOUT VERSION BUMP
- ADAPTER_CONTRACTS.md MODIFICATION REQUIRES:
  1. Explicit documentation update
  2. Version number increment
  3. All affected ToolSpecs updated
  4. Re-validation of all invariants
  5. Re-testing of all adapter operations

**PASS Condition:**
- ✅ ADAPTER_CONTRACTS.md exists and matches STEP 10
- ✅ No breaking changes since STEP 10
- ✅ All ToolSpecs reference v1.0.0 contracts

**FAIL Condition:**
- ❌ ADAPTER_CONTRACTS.md modified without version bump
- ❌ Breaking change detected (operation removed, signature changed)
- ❌ Adapter added or removed without documentation

**Detection:**
```bash
# Verify ADAPTER_CONTRACTS.md matches frozen state
git diff --quiet supabase/adapters/ADAPTER_CONTRACTS.md
# Exit code 0 = No changes (PASS)
# Exit code 1 = Changes detected (FAIL)

# If changes detected, verify version bump
grep "Version:" supabase/adapters/ADAPTER_CONTRACTS.md
# Should match frozen version (1.0.0) or be incremented
```

**Runtime Enforcement:**
- Pre-flight check compares contract file with frozen state
- Any change requires version verification
- Breaking changes require all ToolSpecs to update

---

## Assertion 6: ToolSpec → Adapter Mapping Invariant

**Statement:** ToolSpec → Adapter mapping is validated at registration time and cannot change silently.

**Mapping Rules:**
1. REMOTE tools MUST have adapter_id
2. adapter_id MUST reference existing adapter
3. adapter_operation MUST be in adapter's operation list
4. Contract version MUST be compatible
5. LOCAL tools CANNOT have adapter_id

**Invariant:**
- IF ToolSpec IS REGISTERED → MAPPING IS VALIDATED
- IF ToolSpec MODIFIED → MAPPING IS RE-VALIDATED
- IF ADAPTER CONTRACT CHANGES → ALL TOOLSCIPS MUST RE-VALIDATE

**PASS Example:**
```json
// ToolSpec registration
{
  "tool_id": "vector-search",
  "execution_mode": "remote",
  "adapter_id": "qdrant-vector",
  "adapter_operation": "search",
  "adapter_contract_version": "1.0.0"
}

// Validation:
// ✅ execution_mode = remote → adapter_id required
// ✅ adapter_id "qdrant-vector" exists
// ✅ operation "search" is in qdrant-vector interface
// ✅ contract version 1.0.0 is current
// Result: ToolSpec registered successfully
```

**FAIL Example:**
```json
// ToolSpec registration
{
  "tool_id": "vector-search",
  "execution_mode": "remote",
  "adapter_id": "qdrant-vector",
  "adapter_operation": "drop_all_collections",  // ← Invalid operation
  "adapter_contract_version": "1.0.0"
}

// Validation:
// ❌ operation "drop_all_collections" not in qdrant-vector interface
// Result: ToolSpec rejected
```

**Detection:**
```javascript
// ToolSpec registration validation
function validateToolSpecAdapterMapping(toolspec) {
  // Check 1: REMOTE tools must have adapter_id
  if (toolspec.execution_mode === 'remote' && !toolspec.adapter_id) {
    return { valid: false, error: 'REMOTE tools MUST specify adapter_id' };
  }

  // Check 2: LOCAL tools must NOT have adapter_id
  if (toolspec.execution_mode === 'local' && toolspec.adapter_id) {
    return { valid: false, error: 'LOCAL tools MUST NOT specify adapter_id' };
  }

  // Check 3: adapter_id must exist
  const adapter = adapterRegistry.get(toolspec.adapter_id);
  if (!adapter) {
    return { valid: false, error: `Adapter '${toolspec.adapter_id}' does not exist` };
  }

  // Check 4: adapter_operation must be valid
  if (!adapter.operations.includes(toolspec.adapter_operation)) {
    return {
      valid: false,
      error: `Invalid operation '${toolspec.adapter_operation}' for adapter '${toolspec.adapter_id}'`
    };
  }

  // Check 5: contract version compatibility
  const contractVersion = toolspec.adapter_contract_version || "1.0.0";
  if (semver.major(adapter.version) !== semver.major(contractVersion)) {
    return {
      valid: false,
      error: `Contract version mismatch: adapter v${adapter.version} != ToolSpec v${contractVersion}`
    };
  }

  return { valid: true };
}
```

**Runtime Enforcement:**
- GATE 6: Tool Registration (STEP 5)
- Validates all 6 mapping rules
- Rejects ToolSpec if any rule violated
- ToolSpec cannot be registered if validation fails

---

## Contract Change Examples

### Example 1: Non-Breaking Change (Allowed)

**Change:** Add new optional parameter to input_schema

**Contract v1.0.0:**
```json
{
  "adapter_id": "qdrant-vector",
  "operation": "search",
  "inputs": {
    "vector": "array of numbers",
    "limit": "integer (default 10)"
  }
}
```

**Contract v1.1.0:**
```json
{
  "adapter_id": "qdrant-vector",
  "operation": "search",
  "inputs": {
    "vector": "array of numbers",
    "limit": "integer (default 10)",
    "filter": "object (optional)"  // ← NEW OPTIONAL FIELD
  }
}
```

**Impact:** MINOR version bump (1.0.0 → 1.1.0)
**Backwards Compatible:** YES (old ToolSpecs still work)
**ToolSpec Update Required:** NO (unless using new field)

---

### Example 2: Breaking Change (Not Allowed)

**Change:** Remove operation from adapter interface

**Contract v1.0.0:**
```json
{
  "adapter_id": "qdrant-vector",
  "operations": ["search", "upsert", "create_collection", "health_check"]
}
```

**Contract v2.0.0:**
```json
{
  "adapter_id": "qdrant-vector",
  "operations": ["search", "upsert", "health_check"]  // ← create_collection REMOVED
}
```

**Impact:** MAJOR version bump (1.0.0 → 2.0.0)
**Backwards Compatible:** NO (old ToolSpecs will fail)
**ToolSpec Update Required:** YES (all ToolSpecs using removed operation must update)

**Response:**
- 🚫 Contract change FORBIDDEN without explicit approval
- 🚫 All ToolSpecs using removed operation must be identified
- 🚫 All ToolSpecs must be updated before contract change
- 🚫 ADAPTER_CONTRACTS.md must be updated with v2.0.0

---

## Adapter Contract Assertion Checklist

**Before ANY ToolSpec registration, verify:**

- [ ] ToolSpec has adapter_id (if execution_mode = "remote")
- [ ] adapter_id is in valid adapter list
- [ ] adapter_id exists in adapter registry
- [ ] adapter_operation is in adapter's operation list
- [ ] Contract version is compatible
- [ ] ToolSpec → Adapter mapping validated
- [ ] No breaking changes since STEP 10
- [ ] ADAPTER_CONTRACTS.md matches frozen state (or version bumped)

**If ANY check fails:**
- 🚫 **DO NOT REGISTER TOOLSPEC**
- 🚫 Emit ERROR RunRecord
- 🚫 Fix validation error
- 🚫 Re-validate all checks

---

## Summary

**Assertions Defined:** 6 (required adapter_id, adapter existence, operation validity, contract version, contract immutability, ToolSpec mapping)
**Contract Version:** 1.0.0 (FROZEN)
**Breaking Changes:** FORBIDDEN without explicit approval
**Non-Breaking Changes:** Allowed with MINOR version bump
**Detection Method:** Validation gates (GATE 4, GATE 6), adapter registry lookup, contract file verification

**Key Guarantees:**
- ToolSpec → Adapter mapping cannot change silently
- Invalid adapters are detected before registration
- Invalid operations are detected before execution
- Contract changes require explicit version bumps
- Breaking changes require all ToolSpecs to update
- Contract immutability enforced via git diff verification

**Adapter contract integrity is enforced at ToolSpec registration and execution time.**
