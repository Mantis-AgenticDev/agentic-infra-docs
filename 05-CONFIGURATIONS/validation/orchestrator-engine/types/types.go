package types

import (
	"time"
)

// Severity levels for validation issues
type Severity string

const (
	SeverityCritical Severity = "CRITICAL"
	SeverityHigh     Severity = "HIGH"
	SeverityMedium   Severity = "MEDIUM"
	SeverityLow      Severity = "LOW"
	SeverityWarning  Severity = "WARNING"
)

// ValidationIssue represents a single issue found during validation
type ValidationIssue struct {
	Constraint  string    `json:"constraint"`
	Category    string    `json:"category"`
	Description string    `json:"description"`
	Severity    Severity `json:"severity"`
	Line        int       `json:"line,omitempty"`
	Snippet     string    `json:"snippet,omitempty"`
	Validator   string    `json:"validator,omitempty"`
}

// ValidationResult represents the result of a single validator on a file
type ValidationResult struct {
	Validator     string            `json:"validator"`
	Version       string            `json:"version"`
	Timestamp     time.Time         `json:"timestamp"`
	File          string            `json:"file"`
	Constraint    string            `json:"constraint"`
	Passed        bool              `json:"passed"`
	Issues        []ValidationIssue `json:"issues,omitempty"`
	IssuesCount   int               `json:"issues_count"`
	PerformanceMs int64             `json:"performance_ms"`
}

// ArtifactResult represents the aggregated result for a single artifact
type ArtifactResult struct {
	File         string            `json:"file"`
	Domain       string            `json:"domain"`
	Passed       bool              `json:"passed"`
	TimeMs       int64             `json:"time_ms"`
	LOC          int               `json:"loc"`
	Tokens       int               `json:"tokens"`
	Issues       []ValidationIssue `json:"issues,omitempty"`
}

// Manifest represents the complete validation manifest
type Manifest struct {
	Timestamp       time.Time         `json:"timestamp"`
	Metrics         ManifestMetrics   `json:"metrics"`
	Artifacts       []ArtifactResult  `json:"artifacts"`
	Validators      []string          `json:"validators,omitempty"`
	Version         string            `json:"version"`
}

// ManifestMetrics holds aggregate metrics
type ManifestMetrics struct {
	TotalArtifacts int     `json:"total_artifacts"`
	Passed         int     `json:"passed"`
	Failed         int     `json:"failed"`
	PassRatePct    float64 `json:"pass_rate_pct"`
	FailRatePct    float64 `json:"fail_rate_pct"`
	TotalLOC       int     `json:"total_loc"`
	TotalTokens    int     `json:"total_tokens"`
	TotalTimeMs    int64   `json:"total_time_ms"`
}

// NormsMatrix represents the constraints matrix configuration
type NormsMatrix struct {
	Version      string            `json:"version" yaml:"version"`
	Constraints  []Constraint      `json:"constraints" yaml:"constraints"`
	Domains      []Domain          `json:"domains" yaml:"domains"`
	C4Exceptions []string          `json:"c4_exceptions" yaml:"c4_exceptions"`
}

// Constraint represents a single constraint in the norms matrix
type Constraint struct {
	ID              string   `json:"id" yaml:"id"`
	Name            string   `json:"name" yaml:"name"`
	Description     string   `json:"description" yaml:"description"`
	Severity        string   `json:"severity" yaml:"severity"`
	AppliesToFolders []string `json:"applies_to_folders" yaml:"applies_to_folders"`
	AppliesToLanguages []string `json:"applies_to_languages" yaml:"applies_to_languages"`
	Validator       string   `json:"validator" yaml:"validator"`
	Enabled         bool     `json:"enabled" yaml:"enabled"`
}

// Domain represents a domain/folder structure
type Domain struct {
	Name        string   `json:"name" yaml:"name"`
	Path        string   `json:"path" yaml:"path"`
	Constraints []string `json:"constraints" yaml:"constraints"`
	Subdomains  []Domain `json:"subdomains,omitempty" yaml:"subdomains,omitempty"`
}

// Frontmatter represents parsed YAML frontmatter from a file
type Frontmatter struct {
	ArtifactID        string   `json:"artifact_id"`
	ArtifactType      string   `json:"artifact_type"`
	Version           string   `json:"version"`
	CanonicalPath     string   `json:"canonical_path"`
	ConstraintsMapped []string `json:"constraints_mapped"`
	Title             string   `json:"title,omitempty"`
	Description       string   `json:"description,omitempty"`
}

// CLIOptions represents command line options
type CLIOptions struct {
	Path          string
	Domain        string
	Strict        bool
	OutputJSON    string
	OutputDashboard string
	TTY           bool
	Workers       int
	NormsMatrix   string
}

// LogEntry represents a log entry for JSONL output
type LogEntry struct {
	Timestamp time.Time `json:"ts"`
	Level     string    `json:"level"`
	Script    string    `json:"script,omitempty"`
	File      string    `json:"file,omitempty"`
	Msg       string    `json:"msg"`
}