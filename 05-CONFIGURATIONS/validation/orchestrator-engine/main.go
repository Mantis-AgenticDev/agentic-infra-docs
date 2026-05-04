package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/mantis-agentic/orchestrator-engine/dashboard"
	"github.com/mantis-agentic/orchestrator-engine/types"
	"github.com/mantis-agentic/orchestrator-engine/utils"
	"github.com/mantis-agentic/orchestrator-engine/validators"
)

// Version info
const (
	Version = "4.0.0"
	AppName = "orchestrator-engine"
)

func main() {
	// Parse flags
	opts := parseFlags()

	// Load norms matrix
	nm, err := utils.LoadNormsMatrix(opts.NormsMatrix)
	if err != nil {
		nm = &types.NormsMatrix{}
		fmt.Fprintf(os.Stderr, "Warning: Could not load norms-matrix.json: %v\n", err)
	}

	// Find files to validate
	files, err := findFiles(opts.Path, opts.Domain)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error finding files: %v\n", err)
		os.Exit(1)
	}

	if len(files) == 0 {
		fmt.Println("No files found to validate.")
		os.Exit(0)
	}

	fmt.Printf("Found %d files to validate...\n", len(files))

	// Run validation
	manifest := runValidation(files, nm, opts.Workers)

	// Calculate metrics
	calculateMetrics(manifest)

	// Output results
	if opts.OutputJSON != "" {
		if err := writeJSONOutput(manifest, opts.OutputJSON); err != nil {
			fmt.Fprintf(os.Stderr, "Error writing JSON: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("JSON output written to: %s\n", opts.OutputJSON)
	} else {
		// Print summary to stdout
		outputJSON, err := json.MarshalIndent(manifest, "", "  ")
		if err == nil {
			fmt.Println(string(outputJSON))
		}
	}

	if opts.TTY {
		printTTYSummary(manifest)
	}

	if opts.OutputDashboard != "" {
		html, err := dashboard.GenerateDashboardHTML(manifest)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error generating dashboard: %v\n", err)
			os.Exit(1)
		}
		if err := os.WriteFile(opts.OutputDashboard, []byte(html), 0644); err != nil {
			fmt.Fprintf(os.Stderr, "Error writing dashboard: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Dashboard written to: %s\n", opts.OutputDashboard)
	}

	// Exit code based on results
	if manifest.Metrics.Failed > 0 {
		os.Exit(2)
	}
	os.Exit(0)
}

func parseFlags() types.CLIOptions {
	opts := types.CLIOptions{}

	flag.StringVar(&opts.Path, "path", ".", "Path to file or directory")
	flag.StringVar(&opts.Domain, "domain", "", "Filter by domain")
	flag.BoolVar(&opts.Strict, "strict", false, "Convert warnings to failures")
	flag.StringVar(&opts.OutputJSON, "output-json", "", "Output JSON file path")
	flag.StringVar(&opts.OutputDashboard, "output-dashboard", "", "Output HTML dashboard path")
	flag.BoolVar(&opts.TTY, "tty", false, "Print TTY summary")
	flag.IntVar(&opts.Workers, "workers", 10, "Number of parallel workers")
	flag.StringVar(&opts.NormsMatrix, "norms-matrix", "05-CONFIGURATIONS/validation/norms-matrix.json", "Path to norms-matrix.json")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s [options]\n\nOptions:\n", AppName)
		flag.PrintDefaults()
	}

	flag.Parse()
	return opts
}

func findFiles(path, domain string) ([]string, error) {
	var files []string

	info, err := os.Stat(path)
	if err != nil {
		return nil, fmt.Errorf("path error: %w", err)
	}

	if info.IsDir() {
		err := filepath.Walk(path, func(filePath string, info os.FileInfo, err error) error {
			if err != nil {
				return nil
			}

			// Skip directories
			if info.IsDir() {
				// Skip excluded directories
				if utils.IsExcluded(filePath) {
					return filepath.SkipDir
				}
				return nil
			}

			// Skip excluded files
			if utils.IsExcluded(filePath) {
				return nil
			}

			// Only check certain file types
			ext := strings.ToLower(filepath.Ext(filePath))
			validExts := map[string]bool{
				".md":  true, ".mdx": true, ".sql": true,
				".yaml": true, ".yml": true, ".ts": true,
				".js": true, ".go": true, ".py": true, ".sh": true,
			}

			if !validExts[ext] {
				return nil
			}

			// Filter by domain if specified
			if domain != "" {
				fileDomain := utils.ExtractDomain(filePath)
				if strings.ToUpper(fileDomain) != strings.ToUpper(domain) {
					return nil
				}
			}

			files = append(files, filePath)
			return nil
		})
		if err != nil {
			return nil, err
		}
	} else {
		files = append(files, path)
	}

	return files, nil
}

func runValidation(files []string, nm *types.NormsMatrix, numWorkers int) *types.Manifest {
	manifest := &types.Manifest{
		Timestamp: time.Now().UTC(),
		Version:   Version,
		Artifacts: []types.ArtifactResult{},
		Validators: []string{
			validators.AuditSecretsName,
			validators.CheckRLSName,
			validators.CheckWikiLinksName,
			validators.ValidateFrontmatterName,
			validators.ValidateSkillIntegrityName,
			validators.VerifyConstraintsName,
		},
	}

	jobs := make(chan string, len(files))
	results := make(chan types.ArtifactResult, len(files))

	// Mutex for thread-safe append
	var mu sync.Mutex
	var wg sync.WaitGroup

	// Start workers
	for w := 0; w < numWorkers; w++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for file := range jobs {
				result := validateFile(file, nm)
				results <- result
			}
		}()
	}

	// Send jobs
	for _, file := range files {
		jobs <- file
	}
	close(jobs)

	// Collect results
	go func() {
		wg.Wait()
		close(results)
	}()

	for result := range results {
		mu.Lock()
		manifest.Artifacts = append(manifest.Artifacts, result)
		mu.Unlock()
	}

	manifest.Timestamp = time.Now().UTC()
	return manifest
}

func validateFile(filePath string, nm *types.NormsMatrix) types.ArtifactResult {
	startTime := time.Now()

	result := types.ArtifactResult{
		File:   utils.NormalizePath(filePath),
		Domain: utils.ExtractDomain(filePath),
		Passed: true,
		Issues: []types.ValidationIssue{},
	}

	// Read file content for metrics
	content, err := utils.ReadFile(filePath)
	if err == nil {
		result.LOC = utils.CountLines(content)
		result.Tokens = utils.EstimateTokens(content)
	}

	// Run all validators
	validators := []struct {
		name string
		fn   func() (*types.ValidationResult, error)
	}{
		{validators.AuditSecretsName, func() (*types.ValidationResult, error) {
			return validators.ValidateAuditSecrets(filePath)
		}},
		{validators.CheckRLSName, func() (*types.ValidationResult, error) {
			return validators.ValidateCheckRLS(filePath, nm)
		}},
		{validators.CheckWikiLinksName, func() (*types.ValidationResult, error) {
			return validators.ValidateCheckWikiLinks(filePath)
		}},
		{validators.ValidateFrontmatterName, func() (*types.ValidationResult, error) {
			return validators.ValidateValidateFrontmatter(filePath)
		}},
		{validators.ValidateSkillIntegrityName, func() (*types.ValidationResult, error) {
			return validators.ValidateValidateSkillIntegrity(filePath)
		}},
		{validators.VerifyConstraintsName, func() (*types.ValidationResult, error) {
			return validators.ValidateVerifyConstraints(filePath, nm)
		}},
	}

	for _, v := range validators {
		vr, err := v.fn()
		if err != nil {
			continue
		}
		if !vr.Passed {
			result.Passed = false
		}
		result.Issues = append(result.Issues, vr.Issues...)
	}

	result.TimeMs = time.Since(startTime).Milliseconds()
	return result
}

func calculateMetrics(manifest *types.Manifest) {
	manifest.Metrics.TotalArtifacts = len(manifest.Artifacts)
	manifest.Metrics.Passed = 0
	manifest.Metrics.Failed = 0
	manifest.Metrics.TotalLOC = 0
	manifest.Metrics.TotalTokens = 0
	manifest.Metrics.TotalTimeMs = 0

	for _, a := range manifest.Artifacts {
		if a.Passed {
			manifest.Metrics.Passed++
		} else {
			manifest.Metrics.Failed++
		}
		manifest.Metrics.TotalLOC += a.LOC
		manifest.Metrics.TotalTokens += a.Tokens
		manifest.Metrics.TotalTimeMs += a.TimeMs
	}

	if manifest.Metrics.TotalArtifacts > 0 {
		manifest.Metrics.PassRatePct = float64(manifest.Metrics.Passed) / float64(manifest.Metrics.TotalArtifacts) * 100
		manifest.Metrics.FailRatePct = float64(manifest.Metrics.Failed) / float64(manifest.Metrics.TotalArtifacts) * 100
	}
}

func writeJSONOutput(manifest *types.Manifest, path string) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	encoder := json.NewEncoder(f)
	encoder.SetIndent("", "  ")
	return encoder.Encode(manifest)
}

func printTTYSummary(manifest *types.Manifest) {
	// Colors
	reset := "\033[0m"
	green := "\033[32m"
	red := "\033[31m"
	gold := "\033[33m"
	dim := "\033[2m"

	fmt.Println()
	fmt.Println("╔══════════════════════════════════════════════════════════════╗")
	fmt.Printf("║              %s MANTIS ORCHESTRATOR ENGINE v%s %s║\n", gold, Version, reset)
	fmt.Println("╠══════════════════════════════════════════════════════════════╣")
	fmt.Printf("║  Total Artifacts:  %d                                     ║\n", manifest.Metrics.TotalArtifacts)
	fmt.Printf("║  %s Passed:           %d%s                                     ║\n", green, manifest.Metrics.Passed, reset)
	fmt.Printf("║  %s Failed:           %d%s                                     ║\n", red, manifest.Metrics.Failed, reset)
	fmt.Printf("║  Pass Rate:          %.2f%%                                 ║\n", manifest.Metrics.PassRatePct)
	fmt.Printf("║  Total LOC:          %d                                     ║\n", manifest.Metrics.TotalLOC)
	fmt.Printf("║  Total Tokens:       %d                                     ║\n", manifest.Metrics.TotalTokens)
	fmt.Printf("║  Total Time:         %s                                     ║\n", formatDuration(manifest.Metrics.TotalTimeMs))
	fmt.Println("╚══════════════════════════════════════════════════════════════╝")
	fmt.Println()

	// Show failed artifacts
	if manifest.Metrics.Failed > 0 {
		fmt.Printf("%sFailed Artifacts:%s\n", red, reset)
		fmt.Println(strings.Repeat("─", 60))
		for _, a := range manifest.Artifacts {
			if !a.Passed {
				fmt.Printf("  %s✗%s %s\n", red, reset, a.File)
				fmt.Printf("      %sDomain:%s %s  %sIssues:%s %d\n", dim, reset, a.Domain, dim, reset, len(a.Issues))
			}
		}
	}
}

func formatDuration(ms int64) string {
	if ms < 1000 {
		return fmt.Sprintf("%dms", ms)
	}
	seconds := float64(ms) / 1000
	if seconds < 60 {
		return fmt.Sprintf("%.2fs", seconds)
	}
	minutes := int(seconds) / 60
	remainingSeconds := int(seconds) % 60
	return fmt.Sprintf("%dm %ds", minutes, remainingSeconds)
}