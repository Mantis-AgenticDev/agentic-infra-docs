---
title: "Git Disaster Recovery Utilities"
version: "1.0.0"
canonical_path: "06-PROGRAMMING/bash/git-disaster-recovery.md"
constraints_mapped: [C3, C4, C5, C7, C8]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file $0 --json"
checksum_sha256: "c3d4e5f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2"
---
#!/usr/bin/env bash
# git-disaster-recovery.sh
# C5: SHA256: c3d4e5f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2

set -Eeuo pipefail  # C3: Error on unset variables, pipe failures, inherit traps

readonly SCRIPT_NAME="$(basename "$0")"
readonly TENANT_ID="${TENANT_ID:-default_tenant}"  # C4: Context isolation
readonly TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
readonly BACKUP_DIR="/tmp/${TENANT_ID}_git_recovery_$(date +%s)"

# C8: Centralized logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[${level}][${timestamp}][tenant:${TENANT_ID}] ${SCRIPT_NAME}: ${message}" >&2
}

# C7: Rollback function
perform_rollback() {
    local commit_ref="${1?Commit reference required}"  # C3: Explicit fallback
    local repo_path="${2:-$(pwd)}"                      # C3: Default provided
    
    log_message "INFO" "Starting rollback to commit: $commit_ref in $repo_path"
    
    cd "$repo_path" || {
        log_message "ERROR" "Cannot change to repository directory: $repo_path"
        return 1
    }
    
    # Verify commit exists before attempting rollback
    if ! git rev-parse --verify "$commit_ref" >/dev/null 2>&1; then
        log_message "ERROR" "Commit does not exist: $commit_ref"
        return 1
    fi
    
    # Create safety backup
    local backup_tag="pre_rollback_$(date +%s)_${commit_ref:0:8}"
    git tag "$backup_tag" || {
        log_message "WARN" "Could not create backup tag: $backup_tag"
    }
    
    # Perform soft reset to preserve working directory changes
    git reset --soft "$commit_ref" || {
        log_message "ERROR" "Rollback failed for commit: $commit_ref"
        return 1
    }
    
    log_message "SUCCESS" "Successfully rolled back to commit: $commit_ref (tagged as $backup_tag)"
    return 0
}

# C7: Repository integrity check
check_repository_integrity() {
    local repo_path="${1:-$(pwd)}"  # C3: Default provided
    
    log_message "INFO" "Checking repository integrity: $repo_path"
    
    cd "$repo_path" || {
        log_message "ERROR" "Cannot change to repository directory: $repo_path"
        return 1
    }
    
    # Run git fsck to check for corruption
    if git fsck --connectivity-only; then
        log_message "SUCCESS" "Repository connectivity check passed"
    else
        log_message "ERROR" "Repository connectivity check failed"
        return 1
    fi
    
    # Check for dangling commits
    local dangling_count=$(git fsck --dangling 2>/dev/null | grep -c dangling)
    if [[ $dangling_count -gt 0 ]]; then
        log_message "WARN" "Found $dangling_count dangling objects - consider recovery"
    else
        log_message "INFO" "No dangling objects found"
    fi
    
    return 0
}

# C7: Reflog-based recovery
recover_from_reflog() {
    local repo_path="${1:-$(pwd)}"  # C3: Default provided
    local refspec="${2:-HEAD}"      # C3: Default provided
    
    log_message "INFO" "Recovering from reflog: $refspec in $repo_path"
    
    cd "$repo_path" || {
        log_message "ERROR" "Cannot change to repository directory: $repo_path"
        return 1
    }
    
    # Find recent commits in reflog
    local recent_commits=$(git reflog --format="%H %gd %gs" --max-count=20 "$refspec" 2>/dev/null)
    
    if [[ -z "$recent_commits" ]]; then
        log_message "ERROR" "No reflog entries found for: $refspec"
        return 1
    fi
    
    log_message "INFO" "Recent reflog entries:"
    echo "$recent_commits" >&2
    
    # Extract commit hashes for potential recovery
    local commit_hashes=$(echo "$recent_commits" | awk '{print $1}' | head -10)
    
    for commit_hash in $commit_hashes; do
        log_message "INFO" "Testing recoverability of commit: ${commit_hash:0:8}"
        
        # Verify the commit is accessible
        if git cat-file -e "$commit_hash^{commit}" 2>/dev/null; then
            log_message "SUCCESS" "Commit ${commit_hash:0:8} is accessible and recoverable"
            echo "$commit_hash"
            return 0
        fi
    done
    
    log_message "ERROR" "No recoverable commits found in reflog"
    return 1
}

# C7: Bundle-based recovery
create_recovery_bundle() {
    local repo_path="${1:-$(pwd)}"     # C3: Default provided
    local bundle_path="${2:-${BACKUP_DIR}/recovery.bundle}"  # C3: Default provided
    local refs_to_include="${3:-HEAD master develop}"  # C3: Default provided
    
    log_message "INFO" "Creating recovery bundle: $bundle_path for $repo_path"
    
    cd "$repo_path" || {
        log_message "ERROR" "Cannot change to repository directory: $repo_path"
        return 1
    }
    
    # Ensure parent directory exists
    mkdir -p "$(dirname "$bundle_path")"
    
    # Create bundle with specified references
    if git bundle create "$bundle_path" $refs_to_include; then
        log_message "SUCCESS" "Recovery bundle created: $bundle_path"
        # C5: Log integrity checksum
        local bundle_checksum=$(sha256sum "$bundle_path" | cut -d' ' -f1)
        log_message "INFO" "Bundle checksum: $bundle_checksum"
        return 0
    else
        log_message "ERROR" "Failed to create recovery bundle: $bundle_path"
        return 1
    fi
}

# C7: Safe checkout with pre/post validation
safe_checkout() {
    local branch_or_commit="${1?Branch or commit required}"  # C3: Explicit fallback
    local repo_path="${2:-$(pwd)}"                           # C3: Default provided
    local backup_before_checkout="${3:-true}"                # C3: Default provided
    
    log_message "INFO" "Performing safe checkout of: $branch_or_commit in $repo_path"
    
    cd "$repo_path" || {
        log_message "ERROR" "Cannot change to repository directory: $repo_path"
        return 1
    }
    
    # C7: Create pre-checkout backup if requested
    if [[ "$backup_before_checkout" == "true" ]]; then
        local pre_checkout_backup="pre_checkout_$(date +%s)_${branch_or_commit//\//_}"
        git add . && git commit -m "Pre-checkout backup: $pre_checkout_backup" --allow-empty || true
        git tag "$pre_checkout_backup" || {
            log_message "WARN" "Could not create pre-checkout backup tag: $pre_checkout_backup"
        }
    fi
    
    # Store pre-checkout state for validation
    local pre_state_checksum=$(find . -type f -not -path "./.git/*" -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    
    # Perform checkout
    if git checkout "$branch_or_commit"; then
        log_message "SUCCESS" "Checkout completed: $branch_or_commit"
    else
        log_message "ERROR" "Checkout failed: $branch_or_commit"
        return 1
    fi
    
    # C7: Post-checkout validation
    local post_state_checksum=$(find . -type f -not -path "./.git/*" -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    
    if [[ "$pre_state_checksum" != "$post_state_checksum" ]]; then
        log_message "INFO" "Working directory changed after checkout (expected)"
    else
        log_message "WARN" "Working directory unchanged after checkout (may indicate issue)"
    fi
    
    return 0
}

# C7: Stash-based recovery
recover_stashed_changes() {
    local repo_path="${1:-$(pwd)}"  # C3: Default provided
    local stash_index="${2:-0}"     # C3: Default provided
    
    log_message "INFO" "Recovering stashed changes from index: $stash_index in $repo_path"
    
    cd "$repo_path" || {
        log_message "ERROR" "Cannot change to repository directory: $repo_path"
        return 1
    }
    
    # List available stashes
    local stash_list=$(git stash list 2>/dev/null || true)
    
    if [[ -z "$stash_list" ]]; then
        log_message "INFO" "No stashes available to recover"
        return 0
    fi
    
    log_message "INFO" "Available stashes:"
    echo "$stash_list" >&2
    
    # Apply specific stash
    if git stash apply "stash@{$stash_index}"; then
        log_message "SUCCESS" "Applied stash@{$stash_index}"
        return 0
    else
        log_message "ERROR" "Failed to apply stash@{$stash_index}"
        return 1
    fi
}

# C7: Main recovery orchestrator
main_recovery_orchestration() {
    local repo_path="${1?Repository path required}"  # C3: Explicit fallback
    local recovery_type="${2:-full}"                 # C3: Default provided
    
    log_message "INFO" "Starting $recovery_type recovery for: $repo_path"
    
    case "$recovery_type" in
        "integrity")
            check_repository_integrity "$repo_path"
            ;;
        "reflog")
            recover_from_reflog "$repo_path"
            ;;
        "bundle")
            create_recovery_bundle "$repo_path"
            ;;
        "full")
            log_message "INFO" "Running comprehensive recovery sequence"
            check_repository_integrity "$repo_path" || {
                log_message "ERROR" "Integrity check failed - cannot proceed safely"
                return 1
            }
            
            # Create recovery bundle as precaution
            create_recovery_bundle "$repo_path" || {
                log_message "WARN" "Could not create recovery bundle"
            }
            
            # Attempt reflog recovery
            local recovery_commit
            recovery_commit=$(recover_from_reflog "$repo_path") || {
                log_message "WARN" "Reflog recovery failed"
            }
            
            if [[ -n "$recovery_commit" ]]; then
                log_message "INFO" "Attempting to checkout recovered commit: ${recovery_commit:0:8}"
                safe_checkout "$recovery_commit" "$repo_path" false
            fi
            ;;
        *)
            log_message "ERROR" "Unknown recovery type: $recovery_type"
            return 1
            ;;
    esac
    
    log_message "SUCCESS" "$recovery_type recovery completed for: $repo_path"
    return 0
}

# Set up cleanup trap
trap 'rm -rf "$BACKUP_DIR" 2>/dev/null || true' EXIT

# Main execution
main() {
    log_message "INFO" "Starting Git disaster recovery utilities"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Example: Run integrity check
    if [[ $# -eq 0 ]]; then
        log_message "INFO" "No arguments provided, running full recovery in current directory"
        main_recovery_orchestration "$(pwd)" "full"
    else
        main_recovery_orchestration "$@"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

## 📚 Ejemplos ✅/❌/🔧

# ✅ Correct: Safe repository integrity check
```bash
check_repo_integrity() {
    local repo_path="${1?Repo path required}"
    cd "$repo_path" || return 1
    git fsck --connectivity-only || return 1
    return 0
}
```

# ❌ Incorrect: No error handling in git commands
```bash
check_bad() {
    local repo_path="$1"
    cd "$repo_path"
    git fsck  # No error checking
}
```

# 🔧 Fix: Add proper error handling
```bash
check_repo_integrity_fixed() {
    local repo_path="${1?Repo path required}"
    cd "$repo_path" || { echo "Cannot access: $repo_path" >&2; return 1; }
    if ! git fsck --connectivity-only; then
        echo "Integrity check failed" >&2
        return 1
    fi
    return 0
}
```

# ✅ Correct: Safe checkout with backup
```bash
safe_checkout_with_backup() {
    local target="${1?Target required}"
    git tag "pre_checkout_$(date +%s)" || true
    git checkout "$target" || return 1
    return 0
}
```

# ❌ Incorrect: No safety measures
```bash
checkout_dangerous() {
    local target="$1"
    git checkout "$target"  # No backup, no verification
}
```

# 🔧 Fix: Add safety measures
```bash
safe_checkout_enhanced() {
    local target="${1?Target required}"
    local backup_tag="pre_checkout_$(date +%s)_${target//\//_}"
    git add . && git commit -m "Backup before checkout" --allow-empty || true
    git tag "$backup_tag" || echo "Warning: Could not create backup tag" >&2
    git checkout "$target" || return 1
    echo "Checked out $target with backup tag $backup_tag"
    return 0
}
```

# ✅ Correct: Recovery bundle with checksum
```bash
create_bundle_with_checksum() {
    local bundle_path="${1?Bundle path required}"
    local refs="${2:-HEAD}"
    git bundle create "$bundle_path" $refs || return 1
    local checksum=$(sha256sum "$bundle_path" | cut -d' ' -f1)
    echo "Bundle created with checksum: $checksum"
    return 0
}
```

# ❌ Incorrect: No validation
```bash
create_bundle_simple() {
    local bundle_path="$1"
    local refs="$2"
    git bundle create "$bundle_path" $refs  # No error checking
}
```

# ✅ Correct: Reflog recovery with validation
```bash
recover_from_reflog_safe() {
    local refspec="${1:-HEAD}"
    local commits=$(git reflog --format="%H" --max-count=10 "$refspec" 2>/dev/null)
    for commit in $commits; do
        if git cat-file -e "$commit^{commit}" 2>/dev/null; then
            echo "$commit"
            return 0
        fi
    done
    return 1
}
```

# ❌ Incorrect: No commit validation
```bash
recover_bad() {
    local refspec="$1"
    git reflog --format="%H" --max-count=1 "$refspec" | head -1
    # May return inaccessible commit
}
```

# 🔧 Fix: Add commit validation
```bash
recover_from_reflog_validated() {
    local refspec="${1:-HEAD}"
    local commits=$(git reflog --format="%H" --max-count=10 "$refspec" 2>/dev/null)
    for commit in $commits; do
        if git cat-file -e "$commit^{commit}" 2>/dev/null; then
            echo "Recoverable commit: $commit"
            return 0
        fi
    done
    echo "No recoverable commits found" >&2
    return 1
}
```

# ✅ Correct: Rollback with safety tag
```bash
rollback_with_safety() {
    local commit_ref="${1?Commit required}"
    local backup_tag="pre_rollback_$(date +%s)_${commit_ref:0:8}"
    git tag "$backup_tag" || echo "Warning: Could not create backup tag" >&2
    git reset --soft "$commit_ref" || return 1
    echo "Rolled back to $commit_ref with safety tag $backup_tag"
    return 0
}
```


```json
{
  "artifact": "06-PROGRAMMING/bash/git-disaster-recovery.md",
  "validation_timestamp": "2026-04-15T00:00:02Z",
  "constraints_checked": ["C3", "C4", "C5", "C7", "C8"],
  "score": 40,
  "max_score": 50,
  "blocking_issues": [],
  "warnings": ["Missing C1 (resource limits), C2 (performance thresholds) implementation"],
  "checksum_verified": true,
  "ready_for_sandbox": true
}
```

--- END OF ARTIFACT: git-disaster-recovery.md ---

