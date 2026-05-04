package validators

import (
	"regexp"
	"strings"
	"time"

	"github.com/mantis-agentic/orchestrator-engine/types"
	"github.com/mantis-agentic/orchestrator-engine/utils"
)

const (
	ValidateFrontmatterVersion = "4.0.0"
	ValidateFrontmatterName    = "validate-frontmatter"
)

// Frontmatter patterns
var (
	// Pattern to match frontmatter block
	FrontmatterPattern = regexp.MustCompile(`(?s)^---\s*\n(.*?)\n---\s*\n`)

	// Pattern to match YAML key: value pairs
	KeyValuePattern = regexp.MustCompile(`^(\w+):\s*(.*)$`)

	// Semver pattern
	SemverPattern = regexp.MustCompile(`^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$`)
)

// ValidConstraintIDs list of valid constraint IDs
var ValidConstraintIDs = []string{
	"C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8",
	"V1", "V2", "V3",
}

// ValidateValidateFrontmatter validates frontmatter in markdown files
func ValidateValidateFrontmatter(filePath string) (*types.ValidationResult, error) {
	startTime := time.Now()

	result := &types.ValidationResult{
		Validator:  ValidateFrontmatterName,
		Version:    ValidateFrontmatterVersion,
		Timestamp:  time.Now().UTC(),
		File:       utils.NormalizePath(filePath),
		Constraint: "C5",
		Passed:     true,
		Issues:     []types.ValidationIssue{},
	}

	// Only check markdown files
	ext := strings.ToLower(filePath)
	if !strings.HasSuffix(ext, ".md") && !strings.HasSuffix(ext, ".mdx") {
		result.PerformanceMs = time.Since(startTime).Milliseconds()
		return result, nil
	}

	content, err := utils.ReadFile(filePath)
	if err != nil {
		result.Passed = false
		result.Issues = append(result.Issues, types.ValidationIssue{
			Constraint:  "C5",
			Category:    "file_read_error",
			Description: "Failed to read file: " + err.Error(),
			Severity:    types.SeverityHigh,
		})
		result.IssuesCount = len(result.Issues)
		result.PerformanceMs = time.Since(startTime).Milliseconds()
		return result, nil
	}

	// Parse frontmatter
	fm, err := parseFrontmatter(content)
	if err != nil {
		result.Issues = append(result.Issues, types.ValidationIssue{
			Constraint:  "C5",
			Category:    "invalid_frontmatter",
			Description: "Failed to parse frontmatter: " + err.Error(),
			Severity:    types.SeverityHigh,
			Line:        1,
			Snippet:     "Frontmatter parsing failed",
			Validator:   ValidateFrontmatterName,
		})
		result.Passed = false
		result.IssuesCount = len(result.Issues)
		result.PerformanceMs = time.Since(startTime).Milliseconds()
		return result, nil
	}

	// Validate required fields
	issues := validateFrontmatterFields(fm, content)
	result.Issues = append(result.Issues, issues...)

	result.Passed = len(result.Issues) == 0
	result.IssuesCount = len(result.Issues)
	result.PerformanceMs = time.Since(startTime).Milliseconds()

	return result, nil
}

func parseFrontmatter(content string) (*types.Frontmatter, error) {
	fm := &types.Frontmatter{}

	matches := FrontmatterPattern.FindStringSubmatch(content)
	if len(matches) < 2 {
		return fm, nil // No frontmatter found, may be valid
	}

	frontmatterContent := matches[1]
	lines := strings.Split(frontmatterContent, "\n")

	for _, line := range lines {
		kvMatch := KeyValuePattern.FindStringSubmatch(strings.TrimSpace(line))
		if len(kvMatch) < 3 {
			continue
		}

		key := strings.TrimSpace(kvMatch[1])
		value := strings.TrimSpace(kvMatch[2])

		// Remove quotes if present
		value = strings.Trim(value, "\"'")

		switch key {
		case "artifact_id":
			fm.ArtifactID = value
		case "artifact_type":
			fm.ArtifactType = value
		case "version":
			fm.Version = value
		case "canonical_path":
			fm.CanonicalPath = value
		case "constraints_mapped":
			fm.ConstraintsMapped = parseConstraintsList(value)
		case "title":
			fm.Title = value
		case "description":
			fm.Description = value
		}
	}

	return fm, nil
}

func parseConstraintsList(value string) []string {
	// Handle both inline list [C1, C2, C3] and newline-separated format
	value = strings.TrimSpace(value)

	if strings.HasPrefix(value, "[") && strings.HasSuffix(value, "]") {
		// Inline list format
		value = strings.Trim(value, "[]")
		parts := strings.Split(value, ",")
		var constraints []string
		for _, p := range parts {
			c := strings.TrimSpace(p)
			if c != "" {
				constraints = append(constraints, c)
			}
		}
		return constraints
	}

	// Single value or newline-separated
	return []string{value}
}

func validateFrontmatterFields(fm *types.Frontmatter, content string) []types.ValidationIssue {
	var issues []types.ValidationIssue

	// Check required fields
	if fm.ArtifactID == "" {
		issues = append(issues, types.ValidationIssue{
			Constraint:  "C5",
			Category:    "missing_artifact_id",
			Description: "Missing required frontmatter field: artifact_id",
			Severity:    types.SeverityHigh,
			Validator:   ValidateFrontmatterName,
		})
	}

	if fm.ArtifactType == "" {
		issues = append(issues, types.ValidationIssue{
			Constraint:  "C5",
			Category:    "missing_artifact_type",
			Description: "Missing required frontmatter field: artifact_type",
			Severity:    types.SeverityHigh,
			Validator:   ValidateFrontmatterName,
		})
	}

	// Validate version format (semver)
	if fm.Version != "" && !isValidSemver(fm.Version) {
		issues = append(issues, types.ValidationIssue{
			Constraint:  "C5",
			Category:    "invalid_version",
			Description: "Invalid semver format for version: " + fm.Version,
			Severity:    types.SeverityMedium,
			Validator:   ValidateFrontmatterName,
		})
	}

	// Validate constraints_mapped
	if len(fm.ConstraintsMapped) > 0 {
		for _, c := range fm.ConstraintsMapped {
			if !isValidConstraint(c) {
				issues = append(issues, types.ValidationIssue{
					Constraint:  "C5",
					Category:    "invalid_constraint",
					Description: "Invalid constraint ID: " + c + ". Valid: C1-C8, V1-V3",
					Severity:    types.SeverityMedium,
					Validator:   ValidateFrontmatterName,
				})
			}
		}
	}

	return issues
}

func isValidSemver(version string) bool {
	return SemverPattern.MatchString(version)
}

func isValidConstraint(constraint string) bool {
	for _, valid := range ValidConstraintIDs {
		if constraint == valid {
			return true
		}
	}
	return false
}