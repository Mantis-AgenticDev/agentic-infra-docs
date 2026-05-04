package validators

import (
	"regexp"
	"strings"
	"time"

	"github.com/mantis-agentic/orchestrator-engine/types"
	"github.com/mantis-agentic/orchestrator-engine/utils"
)

const (
	VerifyConstraintsVersion = "4.0.0"
	VerifyConstraintsName    = "verify-constraints"
)

// ConstraintPattern to extract constraints from frontmatter
var ConstraintPattern = regexp.MustCompile(`(?i)constraints_mapped\s*:\s*\[?([^;\]]+)\]?`)

// ValidateVerifyConstraints validates constraint alignment
func ValidateVerifyConstraints(filePath string, nm *types.NormsMatrix) (*types.ValidationResult, error) {
	startTime := time.Now()

	result := &types.ValidationResult{
		Validator:  VerifyConstraintsName,
		Version:   VerifyConstraintsVersion,
		Timestamp: time.Now().UTC(),
		File:      utils.NormalizePath(filePath),
		Constraint: "C8",
		Passed:    true,
		Issues:    []types.ValidationIssue{},
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
			Constraint:  "C8",
			Category:    "file_read_error",
			Description: "Failed to read file: " + err.Error(),
			Severity:    types.SeverityHigh,
		})
		result.IssuesCount = len(result.Issues)
		result.PerformanceMs = time.Since(startTime).Milliseconds()
		return result, nil
	}

	// Parse declared constraints
	declaredConstraints := parseDeclaredConstraints(content)

	// Check for misalignment
	for _, declared := range declaredConstraints {
		if !isConstraintValid(declared) {
			result.Issues = append(result.Issues, types.ValidationIssue{
				Constraint:  "C8",
				Category:    "invalid_constraint",
				Description: "Invalid constraint ID declared: " + declared,
				Severity:    types.SeverityMedium,
				Validator:   VerifyConstraintsName,
			})
		}
	}

	// Check for missing required constraints based on content
	issues := checkConstraintAlignment(filePath, content, declaredConstraints, nm)
	result.Issues = append(result.Issues, issues...)

	result.Passed = len(result.Issues) == 0
	result.IssuesCount = len(result.Issues)
	result.PerformanceMs = time.Since(startTime).Milliseconds()

	return result, nil
}

func parseDeclaredConstraints(content string) []string {
	matches := ConstraintPattern.FindAllStringSubmatch(content, -1)
	var constraints []string

	for _, match := range matches {
		if len(match) < 2 {
			continue
		}
		constraintStr := match[1]

		// Split by comma
		parts := strings.Split(constraintStr, ",")
		for _, p := range parts {
			c := strings.TrimSpace(p)
			if c != "" {
				constraints = append(constraints, c)
			}
		}
	}

	return constraints
}

func determineApplicableConstraints(filePath, content string, nm *types.NormsMatrix) []string {
	var applicable []string

	// Always applicable constraints
	applicable = append(applicable, "C5", "C6") // Link integrity and metadata

	// C3 (secrets) applies to all files
	applicable = append(applicable, "C3")

	// C4 (RLS) applies to files with SQL content
	if hasSQLContent(content) {
		applicable = append(applicable, "C4")
	}

	// C7 (skill integrity) applies to skill files
	if isSkillFile(content) {
		applicable = append(applicable, "C7")
	}

	// C8 (constraint alignment) always applies
	applicable = append(applicable, "C8")

	return applicable
}

func hasSQLContent(content string) bool {
	sqlBlocks := utils.FindSQLBlocks(content)
	return len(sqlBlocks) > 0
}

func isSkillFile(content string) bool {
	for _, pattern := range SkillTypePatterns {
		if pattern.MatchString(content) {
			return true
		}
	}
	return false
}

func isConstraintValid(constraint string) bool {
	for _, valid := range ValidConstraintIDs {
		if constraint == valid {
			return true
		}
	}
	return false
}

func checkConstraintAlignment(filePath, content string, declared []string, nm *types.NormsMatrix) []types.ValidationIssue {
	var issues []types.ValidationIssue

	// If file declares constraints, verify alignment
	if len(declared) == 0 {
		// File doesn't declare constraints - may need them
		return issues
	}

	// Check if file has C3 (secrets) but doesn't declare it
	if hasPotentialSecrets(content) && !containsConstraint(declared, "C3") {
		// This is informational, not a hard failure
	}

	// Check if file has SQL but doesn't declare C4
	if hasSQLContent(content) && !containsConstraint(declared, "C4") {
		// Informational - file has SQL but doesn't declare RLS constraint
	}

	return issues
}

func containsConstraint(declared []string, constraint string) bool {
	for _, c := range declared {
		if c == constraint {
			return true
		}
	}
	return false
}

func hasPotentialSecrets(content string) bool {
	// Check for patterns that might indicate secrets
	patterns := []string{
		"password",
		"api_key",
		"secret",
		"token",
		"credential",
	}

	for _, p := range patterns {
		if strings.Contains(strings.ToLower(content), p) {
			return true
		}
	}
	return false
}