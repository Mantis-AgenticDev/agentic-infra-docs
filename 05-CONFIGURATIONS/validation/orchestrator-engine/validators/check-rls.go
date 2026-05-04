package validators

import (
	"regexp"
	"strings"
	"time"

	"github.com/mantis-agentic/orchestrator-engine/types"
	"github.com/mantis-agentic/orchestrator-engine/utils"
)

const (
	CheckRLSVersion = "4.0.0"
	CheckRLSName    = "check-rls"
)

// DMLPatterns defines regex patterns for DML operations without tenant filtering
var DMLPatterns = []struct {
	Pattern     *regexp.Regexp
	Description string
}{
	// SELECT statements
	{regexp.MustCompile(`(?i)\bSELECT\b(?:\s+(?:DISTINCT|ALL|TOP\s+\d+))?(?:\s+\*\s+|\s+[\w\s,.*()]+)\s+FROM\b`), "SELECT without WHERE clause"},

	// INSERT statements
	{regexp.MustCompile(`(?i)\bINSERT\s+INTO\b`), "INSERT statement"},

	// UPDATE statements
	{regexp.MustCompile(`(?i)\bUPDATE\s+\w+`), "UPDATE statement"},

	// DELETE statements
	{regexp.MustCompile(`(?i)\bDELETE\s+FROM\b`), "DELETE statement"},

	// CREATE TABLE with REFERENCES (FK without tenant)
	{regexp.MustCompile(`(?i)\bREFERENCES\s+\w+\s*\(`), "FOREIGN KEY without tenant scoping"},

	// GRANT statements
	{regexp.MustCompile(`(?i)\bGRANT\s+(?:SELECT|INSERT|UPDATE|DELETE|ALL)\s+ON\b`), "GRANT statement (potential RLS bypass)"},

	// ON DELETE/UPDATE without tenant check
	{regexp.MustCompile(`(?i)\bON\s+(?:DELETE|UPDATE)\s+(?:CASCADE|SET\s+NULL|RESTRICT|NO\s+ACTION)`), "FOREIGN KEY constraint without tenant isolation"},
}

// TenantFilterPatterns patterns that indicate proper tenant filtering
var TenantFilterPatterns = []*regexp.Regexp{
	regexp.MustCompile(`(?i)WHERE\s+.*tenant_id\s*=`),
	regexp.MustCompile(`(?i)WHERE\s+.*tenant_id\s+IN\s*\(`),
	regexp.MustCompile(`(?i)WHERE\s+.*\.tenant_id\s*=`),
	regexp.MustCompile(`(?i)USING\s*\(.*tenant_id.*\)`),
	regexp.MustCompile(`(?i)AND\s+.*\.tenant_id\s*=\s+.*\.tenant_id`),
	regexp.MustCompile(`(?i)JOIN\s+.*\s+ON\s+.*tenant_id\s*=\s*.*tenant_id`),
	regexp.MustCompile(`(?i)set_tenant\s*\(`),
	regexp.MustCompile(`(?i)current_setting\s*\(\s*['"]app\.current_tenant`),
	regexp.MustCompile(`(?i)FOR\s+(?:SELECT|INSERT|UPDATE|DELETE)\s+.*USING\s*\(`),
}

// BypassPatterns patterns that indicate explicit RLS bypass
var BypassPatterns = []*regexp.Regexp{
	regexp.MustCompile(`(?i)\bsetsession\s+characteristics\s+as\s+transaction\s+isolation\s+level`),
	regexp.MustCompile(`(?i)\bSET\s+rls\s*=\s*off\b`),
	regexp.MustCompile(`(?i)\bALTER\s+table\s+\w+\s+enable\s+row\s+level\s+security\b`),
	regexp.MustCompile(`(?i)--.*bypass-rls`),
	regexp.MustCompile(`(?i)/\*.*bypass-rls.*\*/`),
}

// JoinPatterns patterns to detect JOINs
var JoinPatterns = []*regexp.Regexp{
	regexp.MustCompile(`(?i)\bJOIN\s+\w+(?:\s+\w+)?\s+ON\s+([\w.]+)\s*=\s*([\w.]+)`),
	regexp.MustCompile(`(?i)\bLEFT\s+JOIN\s+\w+(?:\s+\w+)?\s+ON\s+([\w.]+)\s*=\s*([\w.]+)`),
	regexp.MustCompile(`(?i)\bRIGHT\s+JOIN\s+\w+(?:\s+\w+)?\s+ON\s+([\w.]+)\s*=\s*([\w.]+)`),
	regexp.MustCompile(`(?i)\bINNER\s+JOIN\s+\w+(?:\s+\w+)?\s+ON\s+([\w.]+)\s*=\s*([\w.]+)`),
	regexp.MustCompile(`(?i)\bOUTER\s+JOIN\s+\w+(?:\s+\w+)?\s+ON\s+([\w.]+)\s*=\s*([\w.]+)`),
}

// ValidateCheckRLS performs RLS enforcement validation
func ValidateCheckRLS(filePath string, nm *types.NormsMatrix) (*types.ValidationResult, error) {
	startTime := time.Now()

	result := &types.ValidationResult{
		Validator:  CheckRLSName,
		Version:    CheckRLSVersion,
		Timestamp:  time.Now().UTC(),
		File:       utils.NormalizePath(filePath),
		Constraint: "C4",
		Passed:     true,
		Issues:     []types.ValidationIssue{},
	}

	// Skip non-SQL files
	ext := strings.ToLower(filePath)
	isSQLFile := strings.HasSuffix(ext, ".sql") ||
		strings.HasSuffix(ext, ".pgsql") ||
		strings.HasSuffix(ext, ".psql") ||
		strings.HasSuffix(ext, ".md") || // Markdown with SQL blocks
		strings.HasSuffix(ext, ".yaml") ||
		strings.HasSuffix(ext, ".yml")

	if !isSQLFile {
		result.PerformanceMs = time.Since(startTime).Milliseconds()
		return result, nil
	}

	// Check C4 exceptions
	if utils.IsC4Exception(nm, filePath) {
		result.PerformanceMs = time.Since(startTime).Milliseconds()
		return result, nil
	}

	content, err := utils.ReadFile(filePath)
	if err != nil {
		result.Passed = false
		result.Issues = append(result.Issues, types.ValidationIssue{
			Constraint:  "C4",
			Category:    "file_read_error",
			Description: "Failed to read file: " + err.Error(),
			Severity:    types.SeverityHigh,
		})
		result.IssuesCount = len(result.Issues)
		result.PerformanceMs = time.Since(startTime).Milliseconds()
		return result, nil
	}

	// Find SQL blocks in markdown files
	sqlBlocks := utils.FindSQLBlocks(content)

	if len(sqlBlocks) == 0 {
		// No SQL blocks, check the whole content
		sqlBlocks = append(sqlBlocks, struct {
			StartLine int
			Content  string
		}{1, content})
	}

	for _, block := range sqlBlocks {
		issues := analyzeSQLContent(block.Content, block.StartLine, nm)
		result.Issues = append(result.Issues, issues...)
	}

	result.Passed = len(result.Issues) == 0
	result.IssuesCount = len(result.Issues)
	result.PerformanceMs = time.Since(startTime).Milliseconds()

	return result, nil
}

func analyzeSQLContent(sqlContent string, startLine int, nm *types.NormsMatrix) []types.ValidationIssue {
	var issues []types.ValidationIssue

	lines := strings.Split(sqlContent, "\n")

	for lineNum, line := range lines {
		trimmedLine := strings.TrimSpace(line)
		absoluteLine := startLine + lineNum

		// Check for explicit bypass
		for _, bypass := range BypassPatterns {
			if bypass.MatchString(trimmedLine) {
				issues = append(issues, types.ValidationIssue{
					Constraint:  "C4",
					Category:    "explicit_bypass",
					Description: "Explicit RLS bypass detected - this is strictly prohibited",
					Severity:    types.SeverityCritical,
					Line:        absoluteLine,
					Snippet:     trimmedLine,
					Validator:   CheckRLSName,
				})
				continue
			}
		}

		// Check for DML without tenant filter
		isDML := false
		var dmlDescription string

		for _, dml := range DMLPatterns {
			if dml.Pattern.MatchString(trimmedLine) {
				isDML = true
				dmlDescription = dml.Description
				break
			}
		}

		if isDML {
			// Check if there's a tenant filter
			hasTenantFilter := hasTenantFilterInScope(sqlContent, lineNum)

			if !hasTenantFilter {
				// Skip certain patterns that are not actual DML issues
				if isSchemaDefinitionOnly(trimmedLine) && !hasDMLKeywords(trimmedLine) {
					continue
				}

				severity := types.SeverityCritical
				if strings.Contains(strings.ToLower(dmlDescription), "foreign key") {
					severity = types.SeverityHigh
				}

				issues = append(issues, types.ValidationIssue{
					Constraint:  "C4",
					Category:    "missing_tenant_filter",
					Description: "DML without tenant_id filter: " + dmlDescription,
					Severity:    severity,
					Line:        absoluteLine,
					Snippet:     trimmedLine,
					Validator:   CheckRLSName,
				})
			}
		}

		// Check for JOINs without tenant scoping
		for _, joinPattern := range JoinPatterns {
			matches := joinPattern.FindAllStringSubmatch(trimmedLine, -1)
			for _, match := range matches {
				if len(match) >= 3 {
					leftSide := match[1]
					rightSide := match[2]

					// Check if tenant_id is involved in the JOIN condition
					if !strings.Contains(strings.ToLower(leftSide), "tenant_id") &&
						!strings.Contains(strings.ToLower(rightSide), "tenant_id") {
						// This JOIN doesn't include tenant scoping
						// Check if there's a tenant_id somewhere in the query
						hasTenant := false
						for _, filter := range TenantFilterPatterns {
							if filter.MatchString(sqlContent) {
								hasTenant = true
								break
							}
						}

						if !hasTenant {
							issues = append(issues, types.ValidationIssue{
								Constraint:  "C4",
								Category:    "missing_join_scoping",
								Description: "JOIN without tenant_id cross-scoping",
								Severity:    types.SeverityHigh,
								Line:        absoluteLine,
								Snippet:     trimmedLine,
								Validator:   CheckRLSName,
							})
						}
					}
				}
			}
		}
	}

	return issues
}

func hasTenantFilterInScope(content string, currentLine int) bool {
	lines := strings.Split(content, "\n")

	// Look at the current line and a few lines before for context
	start := currentLine - 5
	if start < 0 {
		start = 0
	}
	end := currentLine + 1
	if end > len(lines) {
		end = len(lines)
	}

	scope := strings.Join(lines[start:end], " ")

	for _, pattern := range TenantFilterPatterns {
		if pattern.MatchString(scope) {
			return true
		}
	}

	return false
}

func isSchemaDefinitionOnly(line string) bool {
	// Check if line is just a schema definition (column type, constraint, etc.)
	schemaKeywords := []string{
		"PRIMARY KEY",
		"FOREIGN KEY",
		"REFERENCES",
		"ON DELETE",
		"ON UPDATE",
		"DEFAULT",
		"NOT NULL",
		"AUTO_INCREMENT",
		"SERIAL",
		"BIGSERIAL",
		"UNIQUE",
		"INDEX",
		"CHECK",
		"CONSTRAINT",
	}

	for _, keyword := range schemaKeywords {
		if strings.Contains(strings.ToUpper(line), keyword) {
			return true
		}
	}

	return false
}

func hasDMLKeywords(line string) bool {
	dmlKeywords := []string{"SELECT ", "INSERT ", "UPDATE ", "DELETE ", "GRANT ", "REVOKE "}
	for _, keyword := range dmlKeywords {
		if strings.Contains(strings.ToUpper(line), keyword) {
			return true
		}
	}
	return false
}