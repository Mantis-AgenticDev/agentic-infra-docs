package validators

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/mantis-agentic/orchestrator-engine/types"
	"github.com/mantis-agentic/orchestrator-engine/utils"
)

const (
	CheckWikiLinksVersion = "4.0.0"
	CheckWikiLinksName    = "check-wikilinks"
)

// WikiLinkPattern matches [[...]] wiki-style links
var WikiLinkPattern = regexp.MustCompile(`\[\[([^\]|]+)(?:\|[^\]]+)?\]\]`)

// ValidExtensions for link resolution
var ValidExtensions = []string{".md", ".mdx", ""}

// ValidateCheckWikiLinks validates wiki links in markdown files
func ValidateCheckWikiLinks(filePath string) (*types.ValidationResult, error) {
	startTime := time.Now()

	result := &types.ValidationResult{
		Validator:  CheckWikiLinksName,
		Version:   CheckWikiLinksVersion,
		Timestamp: time.Now().UTC(),
		File:      utils.NormalizePath(filePath),
		Constraint: "C5",
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
			Constraint:  "C5",
			Category:    "file_read_error",
			Description: "Failed to read file: " + err.Error(),
			Severity:    types.SeverityHigh,
		})
		result.IssuesCount = len(result.Issues)
		result.PerformanceMs = time.Since(startTime).Milliseconds()
		return result, nil
	}

	lines := strings.Split(content, "\n")

	for lineNum, line := range lines {
		matches := WikiLinkPattern.FindAllStringSubmatchIndex(line, -1)

		for _, match := range matches {
			if len(match) < 4 {
				continue
			}

			// Extract the link target
			linkTarget := line[match[2]:match[3]]

			// Skip non-file links
			if isExcludedLink(linkTarget) {
				continue
			}

			// Resolve the link target to an actual file path
			resolvedPath := resolveWikiLink(filePath, linkTarget)

			// Check if the target file exists
			if !fileExists(resolvedPath) {
				result.Issues = append(result.Issues, types.ValidationIssue{
					Constraint:  "C5",
					Category:    "BROKEN_LINK",
					Description: "Wiki link target does not exist",
					Severity:    types.SeverityHigh,
					Line:        lineNum + 1,
					Snippet:     extractLinkSnippet(line, match[0], match[1]),
					Validator:   CheckWikiLinksName,
				})
			}
		}
	}

	result.Passed = len(result.Issues) == 0
	result.IssuesCount = len(result.Issues)
	result.PerformanceMs = time.Since(startTime).Milliseconds()

	return result, nil
}

func isExcludedLink(link string) bool {
	linkLower := strings.ToLower(link)

	// Exclude HTTP/HTTPS links
	if strings.HasPrefix(linkLower, "http://") || strings.HasPrefix(linkLower, "https://") {
		return true
	}

	// Exclude email links
	if strings.HasPrefix(linkLower, "mailto:") {
		return true
	}

	// Exclude anchor-only links (within page)
	if strings.HasPrefix(linkLower, "#") {
		return true
	}

	// Exclude educational/didactic indicators
	educational := []string{
		"enlaces",
		"verificar",
		"tutorial",
		"ejemplo",
		"example",
		"here",
		"this",
		"link",
		"documentación",
		"documentacion",
		"documentation",
	}

	for _, excl := range educational {
		if strings.Contains(linkLower, excl) {
			return true
		}
	}

	// Exclude human-readable text after pipe
	// [[target|display text]] - only check target
	if strings.Contains(link, "|") {
		return true // The part after | is display text
	}

	return false
}

func resolveWikiLink(sourcePath, linkTarget string) string {
	// Get the directory of the source file
	sourceDir := filepath.Dir(sourcePath)

	// Clean the link target
	linkTarget = strings.TrimSpace(linkTarget)

	// Handle different link types
	if filepath.IsAbs(linkTarget) {
		// Absolute path from repo root - try to make it relative
		return linkTarget
	}

	// Relative path
	resolved := filepath.Join(sourceDir, linkTarget)

	// Try with different extensions
	for _, ext := range ValidExtensions {
		candidate := resolved + ext
		if fileExists(candidate) {
			return candidate
		}
	}

	return resolved
}

func fileExists(path string) bool {
	// Try the path as-is first
	if _, err := os.Stat(path); err == nil {
		return true
	}

	// Try with .md extension
	if !strings.HasSuffix(path, ".md") {
		if _, err := os.Stat(path + ".md"); err == nil {
			return true
		}
	}

	// Try removing .md and checking
	if strings.HasSuffix(path, ".md") {
		base := strings.TrimSuffix(path, ".md")
		if _, err := os.Stat(base); err == nil {
			return true
		}
	}

	return false
}

func extractLinkSnippet(line string, start, end int) string {
	// Get a bit more context around the link
	ctxStart := start - 20
	if ctxStart < 0 {
		ctxStart = 0
	}
	ctxEnd := end + 20
	if ctxEnd > len(line) {
		ctxEnd = len(line)
	}

	snippet := strings.TrimSpace(line[ctxStart:ctxEnd])
	if len(snippet) > 100 {
		snippet = snippet[:100] + "..."
	}
	return snippet
}