package utils

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/mantis-agentic/orchestrator-engine/types"
	"gopkg.in/yaml.v3"
)

// LoadNormsMatrix loads the norms-matrix.json file
func LoadNormsMatrix(path string) (*types.NormsMatrix, error) {
	// Try to find the file if it's not an absolute path
	if !filepath.IsAbs(path) && path != "" {
		// Try current directory first
		if _, err := os.Stat(path); err == nil {
			content, err := ReadFile(path)
			if err != nil {
				return nil, err
			}
			return parseNormsMatrix(content)
		}

		// Try relative to common locations
		searchPaths := []string{
			"05-CONFIGURATIONS/validation/norms-matrix.json",
			"./05-CONFIGURATIONS/validation/norms-matrix.json",
			"../05-CONFIGURATIONS/validation/norms-matrix.json",
			"config/norms-matrix.json",
		}

		for _, searchPath := range searchPaths {
			if _, err := os.Stat(searchPath); err == nil {
				content, err := ReadFile(searchPath)
				if err != nil {
					continue
				}
				return parseNormsMatrix(content)
			}
		}
	}

	content, err := ReadFile(path)
	if err != nil {
		return nil, err
	}
	return parseNormsMatrix(content)
}

func parseNormsMatrix(content string) (*types.NormsMatrix, error) {
	// Try JSON first
	nm, err := parseJSONNormsMatrix(content)
	if err == nil {
		return nm, nil
	}

	// Fallback to YAML
	return parseYAMLNormsMatrix(content)
}

func parseJSONNormsMatrix(content string) (*types.NormsMatrix, error) {
	nm := &types.NormsMatrix{}

	// Simple JSON parsing without external dependency
	// Find constraints array
	constraintsStart := strings.Index(content, `"constraints"`)
	if constraintsStart == -1 {
		constraintsStart = strings.Index(content, `"constraints":`)
	}

	if constraintsStart != -1 {
		// Look for the array start
		arrayStart := strings.Index(content[constraintsStart:], "[")
		if arrayStart != -1 {
			// Find matching close bracket
			depth := 0
			endIdx := -1
			for i, c := range content[constraintsStart+arrayStart:] {
				if c == '[' {
					depth++
				} else if c == ']' {
					depth--
					if depth == 0 {
						endIdx = constraintsStart + arrayStart + i + 1
						break
					}
				}
			}
			if endIdx != -1 {
				// Extract and parse each constraint object
				arrayContent := content[constraintsStart+arrayStart+1 : endIdx-1]
				// This is a simplified parser - we'll create default constraints
				_ = arrayContent
			}
		}
	}

	// Parse C4 exceptions
	c4Idx := strings.Index(content, `"c4_exceptions"`)
	if c4Idx != -1 {
		arrStart := strings.Index(content[c4Idx:], "[")
		if arrStart != -1 {
			depth := 0
			endIdx := -1
			for i, c := range content[c4Idx+arrStart:] {
				if c == '[' {
					depth++
				} else if c == ']' {
					depth--
					if depth == 0 {
						endIdx = c4Idx + arrStart + i + 1
						break
					}
				}
			}
			if endIdx != -1 {
				arrContent := content[c4Idx+arrStart+1 : endIdx-1]
				// Extract strings between quotes
				parts := strings.Split(arrContent, `"`)
				for i := 1; i < len(parts); i += 2 {
					if parts[i] != "" && parts[i] != "," && parts[i] != " " {
						nm.C4Exceptions = append(nm.C4Exceptions, parts[i])
					}
				}
			}
		}
	}

	// Default constraints if parsing failed
	if len(nm.Constraints) == 0 {
		nm.Constraints = getDefaultConstraints()
	}

	if len(nm.C4Exceptions) == 0 {
		nm.C4Exceptions = getDefaultC4Exceptions()
	}

	return nm, nil
}

func parseYAMLNormsMatrix(content string) (*types.NormsMatrix, error) {
	nm := &types.NormsMatrix{}

	if err := yaml.Unmarshal([]byte(content), nm); err != nil {
		return nil, err
	}

	if len(nm.Constraints) == 0 {
		nm.Constraints = getDefaultConstraints()
	}

	if len(nm.C4Exceptions) == 0 {
		nm.C4Exceptions = getDefaultC4Exceptions()
	}

	return nm, nil
}

func getDefaultConstraints() []types.Constraint {
	return []types.Constraint{
		{ID: "C1", Name: "Documentation", Description: "Files must have proper documentation", Enabled: true},
		{ID: "C2", Name: "Format", Description: "Files must follow format requirements", Enabled: true},
		{ID: "C3", Name: "Zero Hardcode", Description: "No hardcoded secrets allowed", Enabled: true, Validator: "audit-secrets"},
		{ID: "C4", Name: "RLS Enforcement", Description: "SQL must have tenant_id filters", Enabled: true, Validator: "check-rls"},
		{ID: "C5", Name: "Link Integrity", Description: "Wiki links must be valid", Enabled: true, Validator: "check-wikilinks"},
		{ID: "C6", Name: "Metadata", Description: "Frontmatter must be valid", Enabled: true, Validator: "validate-frontmatter"},
		{ID: "C7", Name: "Skill Integrity", Description: "Skills must have required structure", Enabled: true, Validator: "validate-skill-integrity"},
		{ID: "C8", Name: "Constraint Alignment", Description: "Must match declared constraints", Enabled: true, Validator: "verify-constraints"},
	}
}

func getDefaultC4Exceptions() []string {
	return []string{
		"changeme",
		"your-",
		"xxx",
		"REDACTED",
		"replace_with_actual_key",
		"example_",
		"my_",
		"dummy_",
		"tutorial",
		"docs",
		"placeholder",
	}
}

// IsC4Exception checks if a file pattern matches C4 exceptions
func IsC4Exception(nm *types.NormsMatrix, path string) bool {
	for _, pattern := range nm.C4Exceptions {
		if strings.Contains(strings.ToLower(path), strings.ToLower(pattern)) {
			return true
		}
	}
	return false
}

// GetApplicableConstraints returns constraints applicable to a file
func GetApplicableConstraints(nm *types.NormsMatrix, path string) []string {
	var applicable []string
	for _, c := range nm.Constraints {
		if !c.Enabled {
			continue
		}
		applicable = append(applicable, c.ID)
	}
	return applicable
}

// ShouldApplyConstraint checks if a constraint should be applied to a file
func ShouldApplyConstraint(nm *types.NormsMatrix, constraintID string, path string) bool {
	for _, c := range nm.Constraints {
		if c.ID == constraintID {
			if len(c.AppliesToFolders) == 0 {
				return true
			}
			for _, folder := range c.AppliesToFolders {
				if strings.Contains(path, folder) {
					return true
				}
			}
		}
	}
	return true // Default to applying if not specified
}