package validators

import (
	"regexp"
	"strings"
	"time"
	"unicode"

	"github.com/mantis-agentic/orchestrator-engine/types"
	"github.com/mantis-agentic/orchestrator-engine/utils"
)

const (
	AuditSecretsVersion = "4.0.0"
	AuditSecretsName    = "audit-secrets"
)

// SecretPattern represents a pattern to detect secrets
type SecretPattern struct {
	Pattern     *regexp.Regexp
	Severity    types.Severity
	Description string
	Category    string
}

// GetSecretPatterns returns all secret detection patterns
func GetSecretPatterns() []SecretPattern {
	return []SecretPattern{
		// API Keys
		{Pattern: regexp.MustCompile(`(?i)(api[_-]?key|apikey|api[_-]?secret)['":\s=]+['\"]?(sk[-_]?\w{20,})['"\s]`), Severity: types.SeverityCritical, Description: "OpenAI/Stripe secret key pattern", Category: "API_KEY"},
		{Pattern: regexp.MustCompile(`(?i)(api[_-]?key|apikey|api[_-]?secret)['":\s=]+['\"]?(ghp_[a-zA-Z0-9]{36,})['"\s]`), Severity: types.SeverityCritical, Description: "GitHub Personal Access Token", Category: "GITHUB_TOKEN"},
		{Pattern: regexp.MustCompile(`(?i)(api[_-]?key|apikey|api[_-]?secret)['":\s=]+['\"]?(AKIA[0-9A-Z]{16})['"\s]`), Severity: types.SeverityCritical, Description: "AWS Access Key ID", Category: "AWS_CRED"},
		{Pattern: regexp.MustCompile(`(?i)(secret|token|key)['":\s=]+['\"]?(xox[baprs]-[a-zA-Z0-9]{10,})['"\s]`), Severity: types.SeverityCritical, Description: "Slack Token", Category: "SLACK_TOKEN"},
		{Pattern: regexp.MustCompile(`(?i)(api[_-]?key|apikey)['":\s=]+['\"]?(sk[-_]?or[-_]?v1[-_]?\w{30,})['"\s]`), Severity: types.SeverityCritical, Description: "OpenRouter API Key", Category: "API_KEY"},
		{Pattern: regexp.MustCompile(`(?i)(api[_-]?key|apikey|subscription[_-]?key)['":\s=]+['\"]?(FCI[a-zA-Z0-9]{28,})['"\s]`), Severity: types.SeverityCritical, Description: "Azure AI Services Key", Category: "API_KEY"},
		{Pattern: regexp.MustCompile(`(?i)(gemini[_-]?api[_-]?key)['":\s=]+['\"]?([a-zA-Z0-9_-]{30,})['"\s]`), Severity: types.SeverityCritical, Description: "Google Gemini API Key", Category: "API_KEY"},
		{Pattern: regexp.MustCompile(`(?i)(openai[_-]?api[_-]?key|openai[_-]?key)['":\s=]+['\"]?(sk[-_]?[-a-zA-Z0-9]{30,})['"\s]`), Severity: types.SeverityCritical, Description: "OpenAI API Key", Category: "API_KEY"},
		{Pattern: regexp.MustCompile(`(?i)(anthropic[_-]?api[_-]?key|claude[_-]?api[_-]?key)['":\s=]+['\"]?(sk[-_]?ant[a-zA-Z0-9_-]{30,})['"\s]`), Severity: types.SeverityCritical, Description: "Anthropic/Claude API Key", Category: "API_KEY"},

		// Private Keys
		{Pattern: regexp.MustCompile(`-----BEGIN (RSA |DSA |EC |OPENSSH |PGP )?PRIVATE KEY-----`), Severity: types.SeverityCritical, Description: "Private Key header detected", Category: "PRIVATE_KEY"},
		{Pattern: regexp.MustCompile(`-----BEGIN CERTIFICATE-----`), Severity: types.SeverityHigh, Description: "Certificate detected", Category: "CERTIFICATE"},

		// Database Passwords
		{Pattern: regexp.MustCompile(`(?i)(password|passwd|pwd|db[_-]?pass)['":\s=]+['\"]?([a-zA-Z0-9@#$%^&*]{6,})['"\s]`), Severity: types.SeverityHigh, Description: "Database password pattern", Category: "DB_PASSWORD"},
		{Pattern: regexp.MustCompile(`(?i)(mysql[_-]?password|postgres[_-]?password|mongodb[_-]?password)['":\s=]+['\"]?([a-zA-Z0-9@#$%^&*]{6,})['"\s]`), Severity: types.SeverityCritical, Description: "Database credentials", Category: "DB_PASSWORD"},
		{Pattern: regexp.MustCompile(`(?i)(connection[_-]?string|database[_-]?url|db[_-]?url)['":\s=]+['\"]?.*://[^/]+:([^@]+)@`), Severity: types.SeverityCritical, Description: "Database connection string with password", Category: "DB_PASSWORD"},

		// AWS Secrets
		{Pattern: regexp.MustCompile(`(?i)(aws[_-]?secret[_-]?access[_-]?key)['":\s=]+['\"]?([a-zA-Z0-9/+=]{40})['"\s]`), Severity: types.SeverityCritical, Description: "AWS Secret Access Key", Category: "AWS_CRED"},
		{Pattern: regexp.MustCompile(`(?i)(aws[_-]?session[_-]?token)['":\s=]+['\"]?([a-zA-Z0-9/+=]{200,})['"\s]`), Severity: types.SeverityCritical, Description: "AWS Session Token", Category: "AWS_CRED"},

		// Generic Secret Patterns
		{Pattern: regexp.MustCompile(`(?i)(secret[_-]?key|secret[_-]?token)['":\s=]+['\"]?([a-zA-Z0-9_-]{20,})['"\s]`), Severity: types.SeverityHigh, Description: "Generic secret key/token", Category: "SECRET_KEY"},
		{Pattern: regexp.MustCompile(`(?i)(bearer|authorization)[_-]?token['":\s=]+['\"]?(eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+)['"\s]`), Severity: types.SeverityCritical, Description: "JWT/Bearer Token", Category: "JWT_TOKEN"},

		// Azure
		{Pattern: regexp.MustCompile(`(?i)(azure[_-]?storage[_-]?key|azure[_-]?connection[_-]?string)['":\s=]+['\"]?([a-zA-Z0-9+/]{60,})['"\s]`), Severity: types.SeverityCritical, Description: "Azure Storage Key", Category: "AZURE_CRED"},

		// Google Cloud
		{Pattern: regexp.MustCompile(`(?i)(gcp[_-]?credentials|google[_-]?credentials|service[_-]?account)['":\s=]+['\"]?({[^}]*})['"\s]`), Severity: types.SeverityCritical, Description: "GCP Service Account JSON", Category: "GCP_CRED"},

		// Generic "=" patterns without quotes
		{Pattern: regexp.MustCompile(`(?i)(api[_-]?key|api[_-]?secret|password|token|secret)\s*=\s*[a-zA-Z0-9_-]{20,}`), Severity: types.SeverityMedium, Description: "Unquoted secret value", Category: "HARDCODED_SECRET"},
	}
}

// GetExclusionPatterns returns patterns that should be excluded
func GetExclusionPatterns() []string {
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
		"REEMPLAZAR",
		"REEMPLAZAME",
		"<your_",
		"// TODO",
		"# TODO",
		"sk-or-v1-REEMPLAZAR",
	}
}

// IsExcluded checks if a match should be excluded based on context
func IsExcluded(content string, start int, end int) bool {
	exclusions := GetExclusionPatterns()

	// Get surrounding context (200 chars before and after)
	contextStart := start - 200
	if contextStart < 0 {
		contextStart = 0
	}
	contextEnd := end + 200
	if contextEnd > len(content) {
		contextEnd = len(content)
	}

	context := strings.ToLower(content[contextStart:contextEnd])

	for _, excl := range exclusions {
		if strings.Contains(context, strings.ToLower(excl)) {
			return true
		}
	}

	return false
}

// ValidateAuditSecrets performs secrets audit on a file
func ValidateAuditSecrets(filePath string) (*types.ValidationResult, error) {
	startTime := time.Now()

	result := &types.ValidationResult{
		Validator:  AuditSecretsName,
		Version:    AuditSecretsVersion,
		Timestamp:  time.Now().UTC(),
		File:       utils.NormalizePath(filePath),
		Constraint: "C3",
		Passed:     true,
		Issues:     []types.ValidationIssue{},
	}

	content, err := utils.ReadFile(filePath)
	if err != nil {
		result.Passed = false
		result.Issues = append(result.Issues, types.ValidationIssue{
			Constraint:  "C3",
			Category:    "file_read_error",
			Description: "Failed to read file: " + err.Error(),
			Severity:    types.SeverityHigh,
		})
		result.IssuesCount = len(result.Issues)
		result.PerformanceMs = time.Since(startTime).Milliseconds()
		return result, nil
	}

	// Skip binary files
	if isBinaryContent(content) {
		result.PerformanceMs = time.Since(startTime).Milliseconds()
		return result, nil
	}

	patterns := GetSecretPatterns()

	for _, pattern := range patterns {
		matches := pattern.Pattern.FindAllStringIndex(content, -1)
		for _, match := range matches {
			start := match[0]
			end := match[1]

			// Check if this match should be excluded
			if IsExcluded(content, start, end) {
				continue
			}

			// Extract line number
			lineNum := countLinesUpTo(content, start)

			// Extract snippet (the actual line)
			snippet := extractLine(content, start)

			result.Issues = append(result.Issues, types.ValidationIssue{
				Constraint:  "C3",
				Category:    pattern.Category,
				Description: pattern.Description,
				Severity:    pattern.Severity,
				Line:        lineNum,
				Snippet:     snippet,
				Validator:   AuditSecretsName,
			})
		}
	}

	result.Passed = len(result.Issues) == 0
	result.IssuesCount = len(result.Issues)
	result.PerformanceMs = time.Since(startTime).Milliseconds()

	return result, nil
}

func isBinaryContent(content string) bool {
	// Check for null bytes or high ratio of non-printable characters
	nullCount := 0
	nonPrintable := 0
	sampleSize := 1000

	if len(content) < sampleSize {
		sampleSize = len(content)
	}

	for i := 0; i < sampleSize; i++ {
		c := content[i]
		if c == 0 {
			nullCount++
		}
		if c < 32 && c != '\n' && c != '\r' && c != '\t' {
			nonPrintable++
		}
	}

	return nullCount > 0 || (len(content) > 0 && float64(nonPrintable)/float64(sampleSize) > 0.3)
}

func countLinesUpTo(content string, pos int) int {
	count := 1
	for i := 0; i < pos && i < len(content); i++ {
		if content[i] == '\n' {
			count++
		}
	}
	return count
}

func extractLine(content string, pos int) string {
	// Find line start
	start := pos
	for start > 0 && content[start-1] != '\n' {
		start--
	}

	// Find line end
	end := pos
	for end < len(content) && content[end] != '\n' {
		end++
	}

	// Trim and return
	line := strings.TrimSpace(content[start:end])
	if len(line) > 150 {
		line = line[:150] + "..."
	}

	return line
}

// CheckSingleLineSecrets specifically checks for single-line secrets like sk-or-v1-xxx
func CheckSingleLineSecrets(content string) []types.ValidationIssue {
	var issues []types.ValidationIssue

	lines := strings.Split(content, "\n")
	for lineNum, line := range lines {
		// Check for patterns that might be missed by regex
		if strings.Contains(strings.ToLower(line), "sk-or-v1-") ||
			strings.Contains(strings.ToLower(line), "openrouter_api_key") ||
			strings.Contains(strings.ToLower(line), "ghp_") {

			// Check if it's a real secret (not a placeholder)
			if !IsExcluded(content, 0, len(content)) {
				issues = append(issues, types.ValidationIssue{
					Constraint:  "C3",
					Category:    "API_KEY",
					Description: "Potential hardcoded API key",
					Severity:    types.SeverityCritical,
					Line:        lineNum + 1,
					Snippet:     strings.TrimSpace(line),
					Validator:   AuditSecretsName,
				})
			}
		}
	}

	return issues
}

func containsOnlyPrintable(s string) bool {
	for _, r := range s {
		if !unicode.IsPrint(r) && r != '\n' && r != '\r' && r != '\t' {
			return false
		}
	}
	return true
}