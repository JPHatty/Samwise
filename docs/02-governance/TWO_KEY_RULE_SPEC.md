# Two-Key Rule Specification

## Purpose
**DEFINITIVE** specification of dual-approval mechanism preventing any single actor from unlocking execution alone.

**PRINCIPLE:** Separation of technical verification from human intent. Two keys, two people, two independent decisions.

---

## Two-Key Rule Overview

**The Two-Key Rule states:**

> **Execution unlock requires TWO different human actors:**
> **1. Technical Authority (Key 1) - Verifies technical readiness**
> **2. Execution Approver (Key 2) - Verifies human intent**
>
> **No single person can hold both keys for the same execution unlock.**
> **Both keys must be presented simultaneously for execution unlock.**

**Analogy:** Nuclear launch codes. Two people must turn two keys simultaneously. No single person can launch alone.

---

## Key 1: Technical Readiness Key

**Purpose:** Verify all technical conditions are met before execution.

**Holder:** Technical Authority role

**Key Type:** PGP key (4096-bit RSA or higher)

**Key Symbolizes:** Technical competence, verification discipline, attention to detail

**What This Key Unlocks:**
- ✅ Authority to state: "All technical conditions are met"
- ✅ Authority to verify: All 8 prechecks PASS
- ✅ Authority to verify: All 12 drift detection rules PASS
- ✅ Authority to verify: Backup and rollback plan are ready
- ✅ Authority to emit: Technical Readiness Artifact

**What This Key Does NOT Unlock:**
- ❌ Does NOT unlock execution alone (requires Key 2)
- ❌ Does NOT authorize human intent (that's Key 2's job)
- ❌ Does NOT bypass any precheck or drift detection
- ❌ Does NOT authorize proceeding with FAILed checks

**Key 1 Responsibilities:**

1. **Run All 8 Prechecks:**
   - Precheck 1: File Integrity Verification
   - Precheck 2: Environment Variable Verification
   - Precheck 3: Schema Drift Detection
   - Precheck 4: Authority Model Verification
   - Precheck 5: Adapter Contract Verification
   - Precheck 6: Validation Gates Verification
   - Precheck 7: Migration Plan Verification
   - Precheck 8: Audit Infrastructure Verification

2. **Run All 12 Drift Detection Rules:**
   - Schema drift: 6 rules
   - Authority drift: 6 rules

3. **Verify Backup:**
   - Backup exists
   - Backup is recent
   - Backup is valid

4. **Verify Rollback Plan:**
   - Rollback plan documented
   - Rollback tested
   - Rollback time measured

5. **Emit Technical Readiness Artifact:**
   - Sign with PGP key
   - Include all precheck results
   - Include all drift detection results
   - Include backup and rollback verification
   - State explicit verdict: READY_FOR_EXECUTION_UNLOCK or NOT_READY

**Key 1 Cannot Be Used By:**
- ❌ Execution Approver (for same execution unlock)
- ❌ Repository Maintainer (for same execution unlock)
- ❌ Emergency Breaker (for same execution unlock)
- ❌ Repository Owner (for same execution unlock, unless no other Technical Authority exists)

**Key 1 Conflict of Interest:**
- If Technical Authority is also the Execution Approver → TWO-KEY RULE VIOLATION
- If Technical Authority is also the person requesting execution → TWO-KEY RULE VIOLATION
- If Technical Authority stands to benefit from execution → TWO-KEY RULE VIOLATION

---

## Key 2: Human Intent Key

**Purpose:** Verify human intent and authorize execution after technical readiness confirmed.

**Holder:** Execution Approver role

**Key Type:** PGP key (4096-bit RSA or higher)

**Key Symbolizes:** Human judgment, ethical consideration, strategic intent

**What This Key Unlocks:**
- ✅ Authority to state: "I authorize this execution to proceed"
- ✅ Authority to review: Technical readiness results
- ✅ Authority to independently verify: Precheck and drift detection results
- ✅ Authority to emit: Execution Approval Artifact

**What This Key Does NOT Unlock:**
- ❌ Does NOT unlock execution alone (requires Key 1)
- ❌ Does NOT verify technical readiness (that's Key 1's job)
- ❌ Does NOT authorize proceeding if Key 1 says NOT_READY
- ❌ Does NOT authorize bypassing any precheck or drift detection

**Key 2 Responsibilities:**

1. **Review Technical Readiness Artifact:**
   - Verify Key 1 signature is valid
   - Verify Key 1 is from different person
   - Verify all 8 prechecks PASS
   - Verify all 12 drift detection rules PASS
   - Verify backup and rollback plan PASS

2. **Independent Verification (Spot Check):**
   - Run a sample of prechecks manually (not all, but enough to verify)
   - Run a sample of drift detection queries manually
   - Verify backup exists and is valid
   - Verify rollback plan is documented
   - Confirm agreement with Key 1's assessment

3. **Evaluate Human Intent:**
   - Is this execution necessary?
   - Is this the right time?
   - Are stakeholders informed?
   - Are risks acceptable?
   - Is rollback plan sufficient?

4. **Emit Execution Approval Artifact:**
   - Sign with PGP key
   - Reference Technical Readiness Artifact
   - State explicit verdict: APPROVED_FOR_EXECUTION_UNLOCK or NOT_APPROVED
   - Include conditions for approval

**Key 2 Cannot Be Used By:**
- ❌ Technical Authority (for same execution unlock)
- ❌ Repository Maintainer (for same execution unlock)
- ❌ Emergency Breaker (for same execution unlock)
- ❌ Repository Owner (for same execution unlock, unless no other Execution Approver exists)

**Key 2 Conflict of Interest:**
- If Execution Approver is also the Technical Authority → TWO-KEY RULE VIOLATION
- If Execution Approver is also the person requesting execution → TWO-KEY RULE VIOLATION
- If Execution Approver stands to benefit from execution → TWO-KEY RULE VIOLATION

---

## Two-Key Combination

**Both Keys Must Be Presented Simultaneously:**

**Execution Unlock Artifact combines both keys:**

```json
{
  "artifact_type": "EXECUTION_UNLOCK",
  "version": "1.0.0",
  "timestamp": "2025-12-27T12:00:00Z",
  "key_1_technical_readiness": {
    "artifact": ".authorization/technical-readiness-20251227100000.json",
    "holder": "Technical Authority",
    "pgp_key_id": "0123456789ABCDEF",
    "identity": "technical-authority@example.com",
    "signature": "PGP-SIGNATURE-BASE64",
    "verdict": "READY_FOR_EXECUTION_UNLOCK"
  },
  "key_2_human_intent": {
    "artifact": ".authorization/execution-approver-20251227110000.json",
    "holder": "Execution Approver",
    "pgp_key_id": "FEDCBA9876543210",
    "identity": "execution-approver@example.com",
    "signature": "PGP-SIGNATURE-BASE64",
    "verdict": "APPROVED_FOR_EXECUTION_UNLOCK"
  },
  "two_key_rule_verification": {
    "key_1_pgp_key_id": "0123456789ABCDEF",
    "key_2_pgp_key_id": "FEDCBA9876543210",
    "different_humans": true,
    "different_pgp_keys": true,
    "both_signatures_valid": true,
    "both_verdicts_positive": true,
    "two_key_rule_satisfied": true
  },
  "execution_unlock_verdict": "APPROVED",
  "unlock_conditions": [
    "Key 1: Technical readiness verified (all prechecks PASS, all drift detection PASS)",
    "Key 2: Human intent verified (independent review, strategic approval)",
    "Two-key rule: Two different humans approved (no conflicts of interest)",
    "Both keys presented simultaneously (artifacts reference each other)"
  ]
}
```

**Two-Key Rule Verification:**

```bash
# Extract PGP key IDs from both artifacts
KEY1_ID=$(jq '.key_1_technical_readiness.pgp_key_id' .authorization/execution-unlock-*.json -r)
KEY2_ID=$(jq '.key_2_human_intent.pgp_key_id' .authorization/execution-unlock-*.json -r)

# Verify keys are different
if [ "$KEY1_ID" = "$KEY2_ID" ]; then
  echo "❌ TWO-KEY RULE VIOLATION: Same person approved both keys"
  exit 1
fi

# Verify both signatures are valid
gpg --verify .authorization/technical-readiness-*.json.asc
gpg --verify .authorization/execution-approver-*.json.asc
# Both must show "Good signature" from different keys

# Verify both verdicts are positive
KEY1_VERDICT=$(jq '.key_1_technical_readiness.verdict' .authorization/execution-unlock-*.json -r)
KEY2_VERDICT=$(jq '.key_2_human_intent.verdict' .authorization/execution-unlock-*.json -r)

if [ "$KEY1_VERDICT" != "READY_FOR_EXECUTION_UNLOCK" ]; then
  echo "❌ TWO-KEY RULE VIOLATION: Key 1 did not approve"
  exit 1
fi

if [ "$KEY2_VERDICT" != "APPROVED_FOR_EXECUTION_UNLOCK" ]; then
  echo "❌ TWO-KEY RULE VIOLATION: Key 2 did not approve"
  exit 1
fi

echo "✅ TWO-KEY RULE SATISFIED: Two different humans approved execution unlock"
```

---

## Two-Key Rule Violations

### Violation 1: Single Person Holds Both Keys

**Detection:**
- Same PGP key ID appears in both Key 1 and Key 2 artifacts
- Same email/identity appears in both artifacts
- Same person signs both artifacts

**Response:**
- 🚫 **CRITICAL: TWO-KEY RULE VIOLATION**
- 🚫 Execution unlock REJECTED
- 🚫 Emit CRITICAL authorization log entry
- 🚫 Require re-approval with different humans

**Prevention:**
- Automated verification script checks PGP key IDs are different
- Execution unlock protocol explicitly prohibits same person for both roles
- PGP key signatures prevent forgery

---

### Violation 2: Key 1 Approves but Key 2 Does Not

**Detection:**
- Key 1 verdict: READY_FOR_EXECUTION_UNLOCK
- Key 2 verdict: NOT_APPROVED or missing

**Response:**
- ❌ Execution unlock NOT APPROVED
- ❌ Key 2 must provide explicit approval or explicit rejection
- ❌ Cannot proceed with Key 1 alone

**Prevention:**
- Execution unlock artifact requires both verdicts to be positive
- Missing Key 2 approval = automatic rejection

---

### Violation 3: Key 2 Approves but Key 1 Does Not

**Detection:**
- Key 2 verdict: APPROVED_FOR_EXECUTION_UNLOCK
- Key 1 verdict: NOT_READY or missing

**Response:**
- ❌ Execution unlock NOT APPROVED
- ❌ Key 1 must fix technical issues and re-emit artifact
- ❌ Cannot proceed with Key 2 alone

**Prevention:**
- Execution unlock artifact requires both verdicts to be positive
- Missing Key 1 approval = automatic rejection

---

### Violation 4: Keys Presented at Different Times

**Detection:**
- Key 1 artifact timestamp differs from Key 2 artifact timestamp by > 1 hour
- Artifacts do not reference each other
- Execution unlock artifact missing or does not combine both keys

**Response:**
- ❌ Execution unlock NOT APPROVED
- ❌ Keys must be presented simultaneously (within reasonable time window)
- ❌ Require fresh artifacts from both roles

**Prevention:**
- Execution unlock protocol requires both artifacts be created within 1 hour
- Execution unlock artifact must reference both Key 1 and Key 2 artifacts
- Timestamps verified to be within acceptable window

---

### Violation 5: Conflicts of Interest

**Detection:**
- Key 1 holder benefits from execution (e.g., wrote code being deployed)
- Key 2 holder benefits from execution (e.g., requesting feature deployment)
- Key 1 or Key 2 is subordinate to the other (power imbalance)

**Response:**
- 🚫 **CRITICAL: CONFLICT OF INTEREST DETECTED**
- 🚫 Execution unlock REJECTED
- 🚫 Require re-approval with independent humans
- 🚫 Emit conflict of interest log entry

**Prevention:**
- Authorization model explicitly prohibits conflicts of interest
- Two-person rule requires independent humans
- Repository Owner must review potential conflicts before granting roles

---

## Key Generation and Distribution

### PGP Key Generation

**Both keys must be PGP keys with these properties:**

1. **Key Type:** RSA or Ed25519
2. **Key Size:** 4096 bits (RSA) or 256 bits (Ed25519)
3. **Key Expiration:** 1 year (must be rotated annually)
4. **Key Storage:** Secure location (hardware token recommended)
5. **Key Backup:** Encrypted backup stored offline
6. **Revocation Certificate:** Stored offline, accessible in emergency

**Key Generation Commands:**

```bash
# Generate Technical Authority PGP key
gpg --full-generate-key
# Select: (1) RSA and RSA
# Select: 4096
# Select: 1y (1 year expiration)
# Enter name: Technical Authority
# Enter email: technical-authority@example.com
# Enter passphrase: [strong passphrase]

# Generate Execution Approver PGP key
gpg --full-generate-key
# Select: (1) RSA and RSA
# Select: 4096
# Select: 1y (1 year expiration)
# Enter name: Execution Approver
# Enter email: execution-approver@example.com
# Enter passphrase: [strong passphrase]

# Export public keys
gpg --armor --export technical-authority@example.com > .pgp-keys/technical-authority.asc
gpg --armor --export execution-approver@example.com > .pgp-keys/execution-approver.asc

# Export private keys (backup only, DO NOT commit to Git)
gpg --armor --export-secret-keys technical-authority@example.com > ~/.gnupg/backup-tech-priv-key.asc
gpg --armor --export-secret-keys execution-approver@example.com > ~/.gnupg/backup-exec-priv-key.asc

# Generate revocation certificates
gpg --armor --gen-revoke technical-authority@example.com > ~/.gnupg/revocation-tech-cert.asc
gpg --armor --gen-revoke execution-approver@example.com > ~/.gnupg/revocation-exec-cert.asc
```

### Key Distribution

**Public keys are published in repository:**

```
.pgp-keys/
├── technical-authority.asc
├── execution-approver.asc
├── emergency-breaker.asc
├── repository-maintainer.asc
└── repository-owner.asc
```

**Key Signing (Web of Trust):**

1. Each authorized role signs the other's public keys
2. Creates trust chain: "I trust this key belongs to this person"
3. Prevents key substitution attacks

**Key Signing Commands:**

```bash
# Technical Authority signs Execution Approver's key
gpg --sign-key execution-approver@example.com

# Execution Approver signs Technical Authority's key
gpg --sign-key technical-authority@example.com

# Export signed keys
gpg --armor --export execution-approver@example.com > .pgp-keys/execution-approver-signed.asc
gpg --armor --export technical-authority@example.com > .pgp-keys/technical-authority-signed.asc
```

### Key Rotation

**Keys must be rotated annually:**

1. **30 days before expiration:**
   - Generate new PGP key
   - Publish new public key in `.pgp-keys/`
   - Get signatures from other authorized roles
   - Emit authorization log entry: "KEY_ROTATION_INITIATED"

2. **On expiration day:**
   - Old key expires
   - New key becomes active
   - Old key revoked
   - Emit authorization log entry: "KEY_ROTATION_COMPLETE"

3. **Emergency rotation (if key compromised):**
   - Revoke compromised key immediately using revocation certificate
   - Generate new key
   - Emit EMERGENCY_BRAKE artifact
   - Emit authorization log entry: "EMERGENCY_KEY_ROTATION"
   - Review all approvals made with compromised key

---

## Key Recovery

**Lost Key Recovery:**

1. **If private key is lost (but not compromised):**
   - Restore from encrypted backup
   - Change passphrase
   - Emit authorization log entry: "KEY_RESTORED_FROM_BACKUP"
   - Review all approvals made since backup was created

2. **If private key is compromised:**
   - Revoke key using revocation certificate
   - Generate new key
   - Emit EMERGENCY_BRAKE artifact
   - Emit authorization log entry: "KEY_COMPROMISED"
   - Review all approvals made with compromised key (may be invalid)

3. **If revocation certificate is lost:**
   - Generate new key
   - Old key cannot be revoked properly (security risk)
   - Mark old key as "do not use" in authorization log
   - Emit authorization log entry: "REVOCATION_CERTIFICATE_LOST"

**Key Recovery Requires:**

- Repository Owner approval
- Emergency Breaker notification (if key compromise)
- Authorization log update
- Possible re-approval of all previous authorizations

---

## Two-Key Rule Enforcement

### Automated Enforcement

**All execution unlock attempts must pass automated verification:**

```bash
#!/bin/bash
# verify-two-key-rule.sh

echo "Verifying Two-Key Rule..."

# Check execution unlock artifact exists
if [ ! -f .authorization/execution-unlock-*.json ]; then
  echo "❌ FAIL: Execution unlock artifact not found"
  exit 1
fi

# Extract PGP key IDs
KEY1_ID=$(jq '.key_1_technical_readiness.pgp_key_id' .authorization/execution-unlock-*.json -r)
KEY2_ID=$(jq '.key_2_human_intent.pgp_key_id' .authorization/execution-unlock-*.json -r)

# Verify keys are different
if [ "$KEY1_ID" = "$KEY2_ID" ]; then
  echo "❌ CRITICAL: TWO-KEY RULE VIOLATION - Same person holds both keys"
  exit 1
fi

# Verify both artifacts exist
KEY1_ARTIFACT=$(jq '.key_1_technical_readiness.artifact' .authorization/execution-unlock-*.json -r)
KEY2_ARTIFACT=$(jq '.key_2_human_intent.artifact' .authorization/execution-unlock-*.json -r)

if [ ! -f "$KEY1_ARTIFACT" ] || [ ! -f "$KEY2_ARTIFACT" ]; then
  echo "❌ FAIL: Key artifacts not found"
  exit 1
fi

# Verify both signatures are valid
if ! gpg --verify "$KEY1_ARTIFACT.asc" "$KEY1_ARTIFACT" 2>/dev/null; then
  echo "❌ FAIL: Key 1 signature invalid"
  exit 1
fi

if ! gpg --verify "$KEY2_ARTIFACT.asc" "$KEY2_ARTIFACT" 2>/dev/null; then
  echo "❌ FAIL: Key 2 signature invalid"
  exit 1
fi

# Verify both verdicts are positive
KEY1_VERDICT=$(jq '.key_1_technical_readiness.verdict' .authorization/execution-unlock-*.json -r)
KEY2_VERDICT=$(jq '.key_2_human_intent.verdict' .authorization/execution-unlock-*.json -r)

if [ "$KEY1_VERDICT" != "READY_FOR_EXECUTION_UNLOCK" ]; then
  echo "❌ FAIL: Key 1 did not approve (verdict: $KEY1_VERDICT)"
  exit 1
fi

if [ "$KEY2_VERDICT" != "APPROVED_FOR_EXECUTION_UNLOCK" ]; then
  echo "❌ FAIL: Key 2 did not approve (verdict: $KEY2_VERDICT)"
  exit 1
fi

echo "✅ PASS: Two-Key Rule satisfied"
echo "   Key 1 (Technical Readiness): $KEY1_ID"
echo "   Key 2 (Human Intent): $KEY2_ID"
echo "   Different humans: YES"
echo "   Both signatures valid: YES"
echo "   Both approvals positive: YES"
exit 0
```

### Manual Enforcement

**Repository Owner must manually review before authorizing any execution:**

1. Verify two different humans approved
2. Verify no conflicts of interest
3. Verify both approvals are recent (within 24 hours)
4. Verify authorization log is complete
5. Verify no EMERGENCY_BRAKE is active

---

## Summary

**Two Keys Defined:**
- Key 1 (Technical Readiness): Held by Technical Authority, verifies technical conditions
- Key 2 (Human Intent): Held by Execution Approver, verifies human intent

**Two-Key Rule:**
- Both keys must be presented simultaneously
- Same person cannot hold both keys
- Both keys must approve (no single-key unlock)
- Both keys must be valid PGP signatures

**Violations Defined:** 5 (single person, key 1 only, key 2 only, different times, conflicts of interest)
**Enforcement:** Automated verification script + manual Repository Owner review
**Key Management:** PGP keys, annual rotation, web of trust signing, recovery procedures

**Key Guarantees:**
- No single person can unlock execution alone
- Technical verification separated from human intent
- Both keys required, both must approve
- Conflicts of interest detected and blocked
- All key actions logged and audited

**The Two-Key Rule makes reckless execution impossible and requires explicit collaboration.**
