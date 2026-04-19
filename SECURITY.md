# Security Policy - MANTIS AGENTIC
## Reporting Vulnerabilities
Use **Private vulnerability reporting** (enabled) or email `security@tudominio.com`.
## Constraints Enforced
- C3: Secrets validation (`audit-secrets.sh`)
- C4: Multi-tenant isolation
- C5: Integrity checksums
- C7: Path safety
- C8: Structured logging
## Pre-PR Checklist
- [ ] No hardcoded secrets
- [ ] Frontmatter válido
- [ ] `orchestrator-engine.sh` pasa con `score >= 30`
