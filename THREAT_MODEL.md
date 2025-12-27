# Threat Model

## Purpose
Identify security threats, attack vectors, and mitigation strategies.

## Trust Boundaries

### External → Traefik
- **Threat**: Unauthorized access, DDoS, credential stuffing
- **Mitigation**: Rate limiting, HTTPS only, authentication required

### Traefik → Services
- **Threat**: Service enumeration, lateral movement
- **Mitigation**: Internal network isolation, service authentication

### Services → External APIs
- **Threat**: Credential exposure, man-in-the-middle
- **Mitigation**: TLS verification, credential rotation, least privilege

### User → n8n Workflows
- **Threat**: Malicious workflow injection, data exfiltration
- **Mitigation**: Workflow validation, sandboxed execution, audit logging

## Assets & Impact

| Asset | Confidentiality | Integrity | Availability |
|-------|----------------|-----------|--------------|
| n8n Credentials | CRITICAL | HIGH | MEDIUM |
| Workflow Definitions | MEDIUM | CRITICAL | HIGH |
| LiveKit Sessions | HIGH | MEDIUM | CRITICAL |
| Redis State | MEDIUM | HIGH | CRITICAL |
| API Keys | CRITICAL | HIGH | MEDIUM |

## Attack Scenarios

### Scenario 1: Compromised Credential
- **Mitigation**: Immediate rotation, audit log review, service restart

### Scenario 2: Container Escape
- **Mitigation**: Non-root containers, read-only filesystems, AppArmor/SELinux

### Scenario 3: Supply Chain Attack
- **Mitigation**: Image scanning, signature verification, pinned versions

## Security Controls
- Network segmentation
- Principle of least privilege
- Defense in depth
- Audit logging
- Regular security updates
