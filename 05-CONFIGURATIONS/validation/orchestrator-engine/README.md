# MANTIS Orchestrator Engine

**Version 4.0.0** - A high-performance validation orchestrator built entirely in Go.

## Overview

The `orchestrator-engine` is a monolithic binary that replaces the previous multi-script Bash validation system. It provides:

- **Native Go Implementation**: No external dependencies (jq, yq, sed, awk)
- **Parallel Processing**: Concurrent validation using goroutines
- **Standalone Dashboard**: Self-contained HTML with no CDN dependencies
- **RLS Enforcement**: PostgreSQL Row-Level Security validation
- **Secret Scanning**: Hardcoded credential detection
- **Link Validation**: Wiki link integrity checking
- **Frontmatter Validation**: YAML metadata verification
- **Skill Integrity**: Structure validation for skill files

## Installation

### Prerequisites

- Go 1.21 or later
- Linux (amd64)

### Build

```bash
# Clone or navigate to the project directory
cd orchestrator-engine

# Download dependencies
go mod download

# Build static binary
CGO_ENABLED=0 go build -a -ldflags '-extldflags "-static"' -o orchestrator-engine .

# Or simply
go build -o orchestrator-engine .
```

### Quick Start

```bash
# Analyze a single file
./orchestrator-engine --path ./02-SKILLS/AI/deepseek-integration.md

# Analyze entire directory with dashboard
./orchestrator-engine --path ./02-SKILLS/ --output-dashboard report.html --tty

# Analyze with domain filter
./orchestrator-engine --domain AI --output-json results.json

# Parallel processing with 20 workers
./orchestrator-engine --path ./02-SKILLS/ --workers 20 --output-dashboard report.html
```

## CLI Options

| Flag | Description | Default |
|------|-------------|---------|
| `--path` | Path to file or directory (recursive) | `.` |
| `--domain` | Filter by domain (AI, DATABASE, etc.) | - |
| `--strict` | Convert warnings to failures | `false` |
| `--output-json` | Write results to JSON file | - |
| `--output-dashboard` | Generate standalone HTML dashboard | - |
| `--tty` | Print colored TTY summary | `false` |
| `--workers` | Number of parallel workers | `10` |
| `--norms-matrix` | Path to norms-matrix.json | `05-CONFIGURATIONS/validation/norms-matrix.json` |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All artifacts passed validation |
| `2` | One or more artifacts failed |
| `1` | Internal orchestrator error |

## Validators

### 1. audit-secrets (C3)
Scans for hardcoded secrets:
- API Keys (OpenAI, GitHub, AWS, etc.)
- Database passwords
- Private keys
- JWT tokens

### 2. check-rls (C4)
Validates Row-Level Security in SQL:
- DML without tenant_id filter
- JOINs without tenant scoping
- Explicit RLS bypass attempts

### 3. check-wikilinks (C5)
Verifies wiki-style links `[[...]]`:
- Resolves link targets
- Verifies file existence
- Ignores HTTP and anchor links

### 4. validate-frontmatter (C5/C6)
Validates YAML frontmatter:
- Required fields (artifact_id, artifact_type)
- Semver version format
- Valid constraint IDs (C1-C8, V1-V3)

### 5. validate-skill-integrity (C5/C7)
Checks skill file structure:
- H1 heading presence
- Code block examples

### 6. verify-constraints (C8)
Validates constraint alignment:
- Declared vs applicable constraints
- Constraint validity

## Exclusions

The engine automatically excludes:
- The binary's own directory
- `05-CONFIGURATIONS/validation/`
- `08-LOGS/`
- `09-TEST-SANDBOX/`
- Hidden files (`.git`, `.gitignore`, etc.)
- `checksum-manifest.json`

## Dashboard

The generated dashboard is **fully standalone**:
- No CDN dependencies
- No external fonts (uses system fonts)
- Embedded data (JSON in script tag)
- Vanilla JavaScript interactivity

### Dashboard Features

- **Global Metrics**: Total artifacts, pass/fail rates
- **Domain Tree**: Filter by domain
- **Search**: Filter by filename
- **Issue Modal**: View detailed issues with fix hints
- **Pagination**: Navigate large result sets

## Architecture

```
orchestrator-engine/
├── main.go              # CLI entry point
├── go.mod               # Module definition
├── types/
│   └── types.go         # Core data structures
├── utils/
│   ├── fileutils.go     # File operations
│   └── normsmatrix.go   # Norms matrix loading
├── validators/
│   ├── audit-secrets.go         # C3: Secret scanning
│   ├── check-rls.go              # C4: RLS validation
│   ├── check-wikilinks.go        # C5: Link validation
│   ├── validate-frontmatter.go   # C6: Metadata validation
│   ├── validate-skill-integrity.go # C7: Skill structure
│   └── verify-constraints.go     # C8: Constraint alignment
└── dashboard/
    └── generator.go     # HTML dashboard generation
```

## Performance

- Goroutine pool for parallel processing
- Channel-based job distribution
- Mutex-protected result collection
- No shared temporary files
- In-memory processing

## Output Format

### JSON Output

```json
{
  "timestamp": "2026-05-02T14:30:00Z",
  "version": "4.0.0",
  "metrics": {
    "total_artifacts": 49,
    "passed": 45,
    "failed": 4,
    "pass_rate_pct": 91.84,
    "fail_rate_pct": 8.16,
    "total_loc": 47241,
    "total_tokens": 483868,
    "total_time_ms": 13159
  },
  "artifacts": [
    {
      "file": "./02-SKILLS/AI/deepseek-integration.md",
      "domain": "AI",
      "passed": true,
      "time_ms": 123,
      "loc": 591,
      "tokens": 5624,
      "issues": []
    }
  ]
}
```

### Dashboard Colors

| Element | Color |
|---------|-------|
| Background | `#111111` |
| Surface | `#1a1a1a` |
| Border | `#333333` |
| Gold (MANTIS) | `#E0AF68` |
| Green (PASS) | `#2e8b57` |
| Red (FAIL) | `#c0392b` |
| Text Primary | `#cccccc` |
| Text Secondary | `#888888` |

## License

Internal MANTIS AGENTIC project use only.