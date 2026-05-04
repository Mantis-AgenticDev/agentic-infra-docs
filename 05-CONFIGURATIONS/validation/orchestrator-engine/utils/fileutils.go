package utils

import (
	"io"
	"os"
	"path/filepath"
	"strings"
	"unicode"
)

// ReadFile reads a file and returns its content
func ReadFile(path string) (string, error) {
	file, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer file.Close()

	content, err := io.ReadAll(file)
	if err != nil {
		return "", err
	}
	return string(content), nil
}

// CountLines counts the number of lines in content
func CountLines(content string) int {
	count := 0
	for _, r := range content {
		if r == '\n' {
			count++
		}
	}
	// Add 1 if content doesn't end with newline
	if len(content) > 0 && content[len(content)-1] != '\n' {
		count++
	}
	return count
}

// EstimateTokens estimates token count (rough approximation)
func EstimateTokens(content string) int {
	// Simple estimation: ~4 chars per token for English, ~2 for CJK
	chars := 0
	for _, r := range content {
		if unicode.Is(unicode.Han, r) || unicode.In(r, unicode.Hiragana, unicode.Katakana, unicode.Hangul) {
			chars += 2
		} else {
			chars++
		}
	}
	return chars / 4
}

// ExtractDomain extracts the domain/folder from a file path
func ExtractDomain(path string) string {
	// Get relative path from common base
	parts := strings.Split(path, string(filepath.Separator))
	if len(parts) < 2 {
		return "ROOT"
	}

	// Skip ./ prefix if present
	startIdx := 0
	if parts[0] == "." {
		startIdx = 1
	}

	if len(parts) <= startIdx+1 {
		return "ROOT"
	}

	domain := parts[startIdx]

	// Map common folder names to domains
	switch strings.ToUpper(domain) {
	case "02-SKILLS":
		if len(parts) > startIdx+2 {
			subFolder := strings.ToUpper(parts[startIdx+2])
			switch {
			case strings.Contains(subFolder, "AI"):
				return "AI"
			case strings.Contains(subFolder, "BASE DE DATOS"), strings.Contains(subFolder, "DATABASE"), strings.Contains(subFolder, "RAG"):
				return "DATABASE"
			case strings.Contains(subFolder, "INFRA"):
				return "INFRASTRUCTURE"
			case strings.Contains(subFolder, "SEGUR"):
				return "SECURITY"
			case strings.Contains(subFolder, "COMUN"):
				return "COMMUNICATION"
			case strings.Contains(subFolder, "DEPLOY"):
				return "DEPLOYMENT"
			}
		}
		return "SKILLS"
	case "01-CORE":
		return "CORE"
	case "03-PIPELINES":
		return "PIPELINES"
	case "04-TERRAFORM":
		return "TERRAFORM"
	}

	return domain
}

// IsExcluded checks if a path should be excluded from scanning
func IsExcluded(path string) bool {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return false
	}

	// Get just the filename or directory name
	base := filepath.Base(absPath)

	// Exclude hidden files and directories
	if strings.HasPrefix(base, ".") && base != "." {
		return true
	}

	excludedDirs := []string{
		".git",
		"node_modules",
		"vendor",
		"__pycache__",
		"05-CONFIGURATIONS",
		"08-LOGS",
		"09-TEST-SANDBOX",
		"orchestrator-engine",
	}

	for _, excluded := range excludedDirs {
		if strings.Contains(absPath, excluded) {
			return true
		}
	}

	// Exclude checksum manifest
	if strings.HasSuffix(absPath, "checksum-manifest.json") {
		return true
	}

	return false
}

// FindSQLBlocks finds SQL code blocks in content
func FindSQLBlocks(content string) []struct {
	StartLine int
	Content   string
} {
	var blocks []struct {
		StartLine int
		Content   string
	}

	lines := strings.Split(content, "\n")
	inBlock := false
	blockStart := 0
	blockLines := []string{}

	for i, line := range lines {
		trimmed := strings.TrimSpace(line)

		// Check for SQL block start
		if strings.HasPrefix(trimmed, "```") {
			lang := strings.ToLower(strings.TrimPrefix(trimmed, "```"))
			if inBlock {
				// End of block
				blocks = append(blocks, struct {
					StartLine int
					Content  string
				}{blockStart, strings.Join(blockLines, "\n")})
				inBlock = false
				blockLines = nil
			} else if lang == "sql" || lang == "postgresql" || lang == "pgsql" || lang == "psql" || lang == "mysql" || lang == "sqlite" {
				// Start of SQL block
				inBlock = true
				blockStart = i + 1
			}
		} else if inBlock {
			blockLines = append(blockLines, line)
		}
	}

	return blocks
}

// ExtractSnippet extracts a snippet around a line number
func ExtractSnippet(content string, lineNum int, contextLines int) string {
	lines := strings.Split(content, "\n")
	if lineNum < 1 || lineNum > len(lines) {
		return ""
	}

	start := lineNum - contextLines - 1
	if start < 0 {
		start = 0
	}
	end := lineNum + contextLines
	if end > len(lines) {
		end = len(lines)
	}

	return strings.Join(lines[start:end], "\n")
}

// NormalizePath normalizes a file path
func NormalizePath(path string) string {
	// Remove ./ prefix if present
	path = strings.TrimPrefix(path, "./")
	// Convert to forward slashes
	path = filepath.ToSlash(path)
	return path
}