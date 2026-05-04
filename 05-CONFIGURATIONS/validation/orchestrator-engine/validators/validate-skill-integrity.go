package validators

import (
	"regexp"
	"strings"
	"time"

	"github.com/mantis-agentic/orchestrator-engine/types"
	"github.com/mantis-agentic/orchestrator-engine/utils"
)

const (
	ValidateSkillIntegrityVersion = "4.0.0"
	ValidateSkillIntegrityName   = "validate-skill-integrity"
)

// Skill-related patterns
var (
	// H1 heading pattern
	H1Pattern = regexp.MustCompile(`(?m)^#\s+(.+)$`)

	// Code block pattern
	CodeBlockPattern = regexp.MustCompile("```")

	// Skill type patterns
	SkillTypePatterns = map[string]*regexp.Regexp{
		"skill_api":      regexp.MustCompile(`(?i)artifact_type\s*:\s*.*skill_api`),
		"skill_cli":      regexp.MustCompile(`(?i)artifact_type\s*:\s*.*skill_cli`),
		"skill_database": regexp.MustCompile(`(?i)artifact_type\s*:\s*.*skill_database`),
		"skill_deploy":   regexp.MustCompile(`(?i)artifact_type\s*:\s*.*skill_deploy`),
		"skill_general":  regexp.MustCompile(`(?i)artifact_type\s*:\s*.*skill_`),
	}
)

// ValidateValidateSkillIntegrity validates skill file structure
func ValidateValidateSkillIntegrity(filePath string) (*types.ValidationResult, error) {
	startTime := time.Now()

	result := &types.ValidationResult{
		Validator:  ValidateSkillIntegrityName,
		Version:    ValidateSkillIntegrityVersion,
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

	// Check if this is a skill file
	isSkill := false
	for _, pattern := range SkillTypePatterns {
		if pattern.MatchString(content) {
			isSkill = true
			break
		}
	}

	if !isSkill {
		// Not a skill file, skip validation
		result.PerformanceMs = time.Since(startTime).Milliseconds()
		return result, nil
	}

	// Validate H1 heading
	if !hasH1Heading(content) {
		result.Issues = append(result.Issues, types.ValidationIssue{
			Constraint:  "C5",
			Category:    "missing_h1",
			Description: "Skill file must have a H1 heading (# Title)",
			Severity:    types.SeverityHigh,
			Line:        1,
			Validator:   ValidateSkillIntegrityName,
		})
	}

	// Check if code blocks are required
	requiresCodeBlocks := false
	for _, pattern := range SkillTypePatterns {
		if pattern.MatchString(content) && pattern != SkillTypePatterns["skill_general"] {
			requiresCodeBlocks = true
			break
		}
	}

	if requiresCodeBlocks && !hasCodeBlocks(content) {
		result.Issues = append(result.Issues, types.ValidationIssue{
			Constraint:  "C5",
			Category:    "missing_code_blocks",
			Description: "Skill file should contain code examples/blocks",
			Severity:    types.SeverityMedium,
			Validator:   ValidateSkillIntegrityName,
		})
	}

	result.Passed = len(result.Issues) == 0
	result.IssuesCount = len(result.Issues)
	result.PerformanceMs = time.Since(startTime).Milliseconds()

	return result, nil
}

func hasH1Heading(content string) bool {
	// Check for H1 heading (must be at the beginning of file or after frontmatter)
	lines := strings.Split(content, "\n")

	inFrontmatter := false
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)

		if trimmed == "---" {
			if !inFrontmatter {
				inFrontmatter = true
			} else {
				inFrontmatter = false
			}
			continue
		}

		if !inFrontmatter && strings.HasPrefix(trimmed, "# ") {
			return true
		}
	}

	return false
}

func hasCodeBlocks(content string) bool {
	// Simple check: count code block markers
	matches := CodeBlockPattern.FindAllStringIndex(content, -1)
	return len(matches) >= 2 // Opening and closing ```
}

// GetSkillType returns the type of skill from content
func GetSkillType(content string) string {
	for skillType, pattern := range SkillTypePatterns {
		if pattern.MatchString(content) {
			return skillType
		}
	}
	return ""
}