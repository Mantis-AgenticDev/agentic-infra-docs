# Security Policy - MANTIS AGENTIC

## Supported Versions

| Version | Supported          |
|---------|-------------------|
| 3.0.x   | ✅ Current (HARNESS NORMS v3.0-SELECTIVE) |
| 2.1.x   | ⚠️ Legacy (no longer maintained) |
| < 2.0   | ❌ Unsupported |

## Reporting a Vulnerability

We take security seriously. If you discover a vulnerability, please report it privately:

### 📧 Preferred Channel
- Email: `security@mantis-agentic.dev` (PGP key available upon request)
- GitHub: Use **Private vulnerability reporting** (enabled for this repo)

### 📋 What to Include
1. Description of the vulnerability (CWE ID if known)
2. Steps to reproduce (minimal PoC preferred)
3. Affected files/paths (canonical_path format)
4. Potential impact (C3/C4/C5 constraint violation?)
5. Suggested mitigation (if any)

### 🔐 Response Timeline
- **Acknowledgment**: Within 24 hours
- **Assessment**: Within 72 hours
- **Fix/Workaround**: Within 7 days for critical issues
- **Public Disclosure**: Coordinated after fix deployment

### 🚫 What NOT to Do
- Do NOT open a public issue for security vulnerabilities
- Do NOT exploit the vulnerability beyond minimal PoC
- Do NOT share details with third parties before coordinated disclosure

## Security Constraints (HARNESS NORMS v3.0)

This project enforces strict security constraints:

| Constraint | Description | Enforcement |
|------------|-------------|-------------|
| **C3** | Secrets & Environment Validation | `audit-secrets.sh` + secret scanning |
| **C4** | Multi-Tenant Isolation | RLS policies + tenant_id filters |
| **C5** | Integrity Verification via Checksums | SHA256 checksums + signature verification |
| **C7** | Path Safety & Cleanup Guarantees | `realpath` validation + `trap` cleanup |
| **C8** | Structured Logging to stderr | JSON logs + no print/console.log |

## Security Testing

Before submitting PRs, ensure:
```bash
# Run secret audit
bash 05-CONFIGURATIONS/validation/audit-secrets.sh

# Run constraint verification
bash 05-CONFIGURATIONS/validation/verify-constraints.sh --file <your-file> --json

# Run orchestrator validation
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <your-file> --json

Bug Bounty
Currently, we do not offer monetary bounties. However, significant contributions to security will be acknowledged in release notes and contributor lists.
Last updated: 2026-04-19 | HARNESS NORMS v3.0-SELECTIVE compliant
