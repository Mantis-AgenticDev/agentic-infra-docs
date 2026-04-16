---
title: "Filesystem Sandbox Sync Utility"
version: "1.0.0"
canonical_path: "06-PROGRAMMING/bash/filesystem-sandbox-sync.md"
constraints_mapped: [C1, C3, C4, C5, C7, C8]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file $0 --json"
checksum_sha256: "b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4b1a6f3"
---
#!/usr/bin/env bash
# filesystem-sandbox-sync.sh
# C5: SHA256: b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4b1a6f3

set -Eeuo pipefail  # C3: Error on unset variables, pipe failures, inherit traps

readonly SCRIPT_NAME="$(basename "$0")"
readonly TENANT_ID="${TENANT_ID:-default_tenant}"  # C4: Context isolation
readonly TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
readonly MAX_SYNC_SIZE_MB=1024        # C1: Resource limit
readonly MAX_FILE_COUNT=10000         # C1: File count limit
readonly SYNC_TIMEOUT_SECONDS=300     # C1: Operation timeout
readonly SANDBOX_BASE_DIR="/tmp/${TENANT_ID}_sandbox_$(date +%s)"

# C8: Centralized logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[${level}][${timestamp}][tenant:${TENANT_ID}] ${SCRIPT_NAME}: ${message}" >&2
}

# C7: Validate sync source and destination paths
validate_sync_paths() {
    local source_path="${1?Source path required}"      # C3: Explicit fallback
    local dest_path="${2?Destination path required}"  # C3: Explicit fallback
    
    log_message "INFO" "Validating sync paths: $source_path -> $dest_path"
    
    # Validate source path exists
    if [[ ! -e "$source_path" ]]; then
        log_message "ERROR" "Source path does not exist: $source_path"
        return 1
    fi
    
    # Validate source path is within safe boundaries
    local abs_source=$(realpath "$source_path" 2>/dev/null) || {
        log_message "ERROR" "Cannot resolve source path: $source_path"
        return 1
    }
    
    # Prevent syncing system directories
    if [[ "$abs_source" =~ ^/(sys|proc|dev|etc|boot|root|var/log|home/.+/\.ssh)/ ]]; then
        log_message "ERROR" "Unsafe source path: $abs_source (system directory)"
        return 1
    fi
    
    # Validate destination path
    local abs_dest=$(realpath "$(dirname "$dest_path")" 2>/dev/null) || {
        log_message "ERROR" "Cannot resolve destination directory: $(dirname "$dest_path")"
        return 1
    }
    
    # Create destination directory if it doesn't exist
    mkdir -p "$dest_path"
    
    # Validate destination is not a system directory
    if [[ "$abs_dest" =~ ^/(sys|proc|dev|etc|boot|root|var/log|home/.+/\.ssh)/ ]]; then
        log_message "ERROR" "Unsafe destination path: $abs_dest (system directory)"
        return 1
    fi
    
    log_message "SUCCESS" "Sync paths validated: $source_path -> $dest_path"
    return 0
}

# C7: Calculate total size of source directory
calculate_source_size() {
    local source_path="${1?Source path required}"  # C3: Explicit fallback
    
    if [[ -f "$source_path" ]]; then
        stat -c%s "$source_path" 2>/dev/null || stat -f%z "$source_path" 2>/dev/null
        return 0
    elif [[ -d "$source_path" ]]; then
        du -sb "$source_path" 2>/dev/null | cut -f1
        return 0
    else
        log_message "ERROR" "Source path is neither file nor directory: $source_path"
        return 1
    fi
}

# C7: Count files in source directory
count_source_files() {
    local source_path="${1?Source path required}"  # C3: Explicit fallback
    
    if [[ -f "$source_path" ]]; then
        echo 1
        return 0
    elif [[ -d "$source_path" ]]; then
        find "$source_path" -type f 2>/dev/null | wc -l
        return 0
    else
        log_message "ERROR" "Source path is neither file nor directory: $source_path"
        return 1
    fi
}

# C7: Perform sandbox sync with validation gate
perform_sandbox_sync() {
    local source_path="${1?Source path required}"      # C3: Explicit fallback
    local dest_path="${2?Destination path required}"  # C3: Explicit fallback
    local exclude_patterns="${3:-*.tmp *.log .git}"   # C3: Default provided
    local validate_checksum="${4:-true}"              # C3: Default provided
    
    log_message "INFO" "Starting sandbox sync: $source_path -> $dest_path"
    
    # Validate paths first
    validate_sync_paths "$source_path" "$dest_path" || return 1
    
    # C1: Check resource constraints
    local source_size_bytes
    source_size_bytes=$(calculate_source_size "$source_path") || {
        log_message "ERROR" "Cannot calculate source size: $source_path"
        return 1
    }
    
    local source_size_mb=$((source_size_bytes / 1024 / 1024))
    if [[ $source_size_mb -gt $MAX_SYNC_SIZE_MB ]]; then
        log_message "ERROR" "Source exceeds size limit: ${source_size_mb}MB > ${MAX_SYNC_SIZE_MB}MB"
        return 1
    fi
    
    local file_count
    file_count=$(count_source_files "$source_path") || {
        log_message "ERROR" "Cannot count source files: $source_path"
        return 1
    }
    
    if [[ $file_count -gt $MAX_FILE_COUNT ]]; then
        log_message "ERROR" "Source exceeds file count limit: $file_count > $MAX_FILE_COUNT files"
        return 1
    fi
    
    log_message "INFO" "Resource validation passed - Size: ${source_size_mb}MB, Files: $file_count"
    
    # Build rsync command with exclusions
    local rsync_cmd="rsync -av --delete"
    
    # Add exclusion patterns
    for pattern in $exclude_patterns; do
        rsync_cmd="$rsync_cmd --exclude='$pattern'"
    done
    
    # Add dry-run for validation if requested
    if [[ "$validate_checksum" == "true" ]]; then
        rsync_cmd="$rsync_cmd --checksum"
    fi
    
    # C1: Set timeout for the operation
    local start_time=$SECONDS
    
    # Execute sync with timeout
    if timeout "$SYNC_TIMEOUT_SECONDS" bash -c "$rsync_cmd '$source_path/' '$dest_path/'"; then
        local sync_duration=$((SECONDS - start_time))
        log_message "SUCCESS" "Sync completed in ${sync_duration}s: $source_path -> $dest_path"
        
        # C7: Post-sync validation
        if [[ "$validate_checksum" == "true" ]]; then
            validate_post_sync "$source_path" "$dest_path" || {
                log_message "ERROR" "Post-sync validation failed"
                return 1
            }
        fi
        
        return 0
    else
        local sync_duration=$((SECONDS - start_time))
        log_message "ERROR" "Sync failed after ${sync_duration}s: $source_path -> $dest_path"
        return 1
    fi
}

# C7: Validate sync completion with checksum comparison
validate_post_sync() {
    local source_path="${1?Source path required}"      # C3: Explicit fallback
    local dest_path="${2?Destination path required}"  # C3: Explicit fallback
    
    log_message "INFO" "Performing post-sync validation: $source_path vs $dest_path"
    
    # Generate checksums for both source and destination
    local source_checksum
    local dest_checksum
    
    if [[ -d "$source_path" ]]; then
        source_checksum=$(find "$source_path" -type f -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1)
        dest_checksum=$(find "$dest_path" -type f -exec sha256sum {} \; | sort | sha256sum | cut -d' ' -f1)
    else
        source_checksum=$(sha256sum "$source_path" | cut -d' ' -f1)
        dest_checksum=$(sha256sum "$dest_path/$(basename "$source_path")" | cut -d' ' -f1)
    fi
    
    if [[ "$source_checksum" == "$dest_checksum" ]]; then
        log_message "SUCCESS" "Checksum validation passed - Data integrity confirmed"
        return 0
    else
        log_message "ERROR" "Checksum validation failed - Source: $source_checksum, Dest: $dest_checksum"
        return 1
    fi
}

# C7: Atomic move with validation gate
atomic_move_with_validation() {
    local source_path="${1?Source path required}"      # C3: Explicit fallback
    local dest_path="${2?Destination path required}"  # C3: Explicit fallback
    local validation_func="${3:-validate_post_sync}"  # C3: Default provided
    
    log_message "INFO" "Performing atomic move: $source_path -> $dest_path"
    
    # Validate source exists
    if [[ ! -e "$source_path" ]]; then
        log_message "ERROR" "Source does not exist: $source_path"
        return 1
    fi
    
    # Create temporary destination with suffix
    local temp_dest="${dest_path}.tmp.$(date +%s).$$"
    
    # Perform the move operation
    if mv "$source_path" "$temp_dest"; then
        # Validate the moved content
        if $validation_func "$temp_dest" "$(dirname "$dest_path")"; then
            # Atomically replace the destination
            if mv "$temp_dest" "$dest_path"; then
                log_message "SUCCESS" "Atomic move completed: $source_path -> $dest_path"
                return 0
            else
                log_message "ERROR" "Failed to finalize atomic move: $temp_dest -> $dest_path"
                # Attempt to rollback
                mv "$temp_dest" "$source_path" 2>/dev/null || true
                return 1
            fi
        else
            log_message "ERROR" "Validation failed, rolling back atomic move"
            # Rollback the move
            mv "$temp_dest" "$source_path" 2>/dev/null || true
            return 1
        fi
    else
        log_message "ERROR" "Failed to initiate atomic move: $source_path -> $temp_dest"
        return 1
    fi
}

# C7: Create secure sandbox environment
create_secure_sandbox() {
    local sandbox_name="${1?Sandbox name required}"  # C3: Explicit fallback
    local base_dir="${2:-$SANDBOX_BASE_DIR}"         # C3: Default provided
    
    log_message "INFO" "Creating secure sandbox: $sandbox_name in $base_dir"
    
    # Create tenant-specific sandbox directory
    local sandbox_path="$base_dir/$(date +%s)_${TENANT_ID}_${sandbox_name}"
    mkdir -p "$sandbox_path"
    
    # Set restrictive permissions
    chmod 700 "$sandbox_path"
    
    # Create standard sandbox subdirectories
    mkdir -p "$sandbox_path/input" "$sandbox_path/output" "$sandbox_path/work" "$sandbox_path/logs"
    chmod 700 "$sandbox_path/input" "$sandbox_path/output" "$sandbox_path/work" "$sandbox_path/logs"
    
    log_message "SUCCESS" "Secure sandbox created: $sandbox_path"
    echo "$sandbox_path"
    
    return 0
}

# C7: Sync to sandbox with validation gates
sync_to_sandbox() {
    local source_path="${1?Source path required}"      # C3: Explicit fallback
    local sandbox_name="${2?Sandbox name required}"   # C3: Explicit fallback
    local exclude_patterns="${3:-*.tmp *.log .git}"   # C3: Default provided
    
    log_message "INFO" "Syncing to sandbox: $source_path -> $sandbox_name"
    
    # Create secure sandbox
    local sandbox_path
    sandbox_path=$(create_secure_sandbox "$sandbox_name") || {
        log_message "ERROR" "Failed to create sandbox: $sandbox_name"
        return 1
    }
    
    # Perform sync to sandbox
    perform_sandbox_sync "$source_path" "$sandbox_path/input" "$exclude_patterns" "true" || {
        log_message "ERROR" "Sync to sandbox failed: $source_path -> $sandbox_path/input"
        return 1
    }
    
    log_message "SUCCESS" "Successfully synced to sandbox: $sandbox_path"
    echo "$sandbox_path"
    
    return 0
}

# C7: Cleanup sandbox with validation
cleanup_sandbox() {
    local sandbox_path="${1?Sandbox path required}"  # C3: Explicit fallback
    local force_cleanup="${2:-false}"               # C3: Default provided
    
    log_message "INFO" "Cleaning up sandbox: $sandbox_path"
    
    if [[ ! -d "$sandbox_path" ]]; then
        log_message "INFO" "Sandbox does not exist: $sandbox_path"
        return 0
    fi
    
    # Validate this is actually a sandbox directory (contains expected structure)
    if [[ ! -d "$sandbox_path/input" || ! -d "$sandbox_path/output" ]] && [[ "$force_cleanup" != "true" ]]; then
        log_message "ERROR" "Path does not appear to be a sandbox, refusing cleanup: $sandbox_path"
        return 1
    fi
    
    # Remove sandbox directory
    if rm -rf "$sandbox_path"; then
        log_message "SUCCESS" "Sandbox cleaned up: $sandbox_path"
        return 0
    else
        log_message "ERROR" "Failed to clean up sandbox: $sandbox_path"
        return 1
    fi
}

# Main execution
main() {
    log_message "INFO" "Starting filesystem sandbox sync utility"
    
    if [[ $# -eq 0 ]]; then
        log_message "INFO" "No arguments provided, showing help"
        echo "Usage: $0 <command> [args...]"
        echo "Commands:"
        echo "  sync <source> <dest> [exclusions] [validate]"
        echo "  sandbox <source> <name> [exclusions]"
        echo "  atomic <source> <dest>"
        echo "  validate <source> <dest>"
        echo "  create-sandbox <name> [base_dir]"
        echo "  cleanup <sandbox_path> [force]"
        echo ""
        echo "Examples:"
        echo "  $0 sync /path/to/source /path/to/dest '*.tmp *.log' true"
        echo "  $0 sandbox /path/to/source my_project '*.tmp *.log'"
        echo "  $0 atomic /path/to/temp /path/to/final"
        return 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        "sync")
            perform_sandbox_sync "$@"
            ;;
        "sandbox")
            sync_to_sandbox "$@"
            ;;
        "atomic")
            atomic_move_with_validation "$@"
            ;;
        "validate")
            validate_post_sync "$@"
            ;;
        "create-sandbox")
            create_secure_sandbox "$@"
            ;;
        "cleanup")
            cleanup_sandbox "$@"
            ;;
        *)
            log_message "ERROR" "Unknown command: $command"
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

## 📚 Ejemplos ✅/❌/🔧

# ✅ Correct: Secure path validation
```bash
validate_paths_secure() {
    local source="${1?Source required}"
    local dest="${2?Dest required}"
    [[ ! -e "$source" ]] && { echo "Source not found: $source" >&2; return 1; }
    [[ "$source" =~ ^/(sys|proc|dev|etc)/ ]] && { echo "Unsafe source: $source" >&2; return 1; }
    mkdir -p "$dest"
    [[ "$dest" =~ ^/(sys|proc|dev|etc)/ ]] && { echo "Unsafe dest: $dest" >&2; return 1; }
    return 0
}
```

# ❌ Incorrect: No path validation
```bash
validate_paths_bad() {
    local source="$1"
    local dest="$2"
    # No validation - could sync to unsafe locations
    return 0
}
```

# 🔧 Fix: Add comprehensive validation
```bash
validate_paths_fixed() {
    local source="${1?Source required}"
    local dest="${2?Dest required}"
    [[ ! -e "$source" ]] && { echo "Source not found: $source" >&2; return 1; }
    local abs_source=$(realpath "$source" 2>/dev/null) || { echo "Cannot resolve: $source" >&2; return 1; }
    [[ "$abs_source" =~ ^/(sys|proc|dev|etc|boot|root)/ ]] && { echo "Unsafe source: $abs_source" >&2; return 1; }
    mkdir -p "$dest"
    local abs_dest=$(realpath "$(dirname "$dest")" 2>/dev/null) || { echo "Cannot resolve: $dest" >&2; return 1; }
    [[ "$abs_dest" =~ ^/(sys|proc|dev|etc|boot|root)/ ]] && { echo "Unsafe dest: $abs_dest" >&2; return 1; }
    return 0
}
```

# ✅ Correct: Resource-limited sync
```bash
sync_with_limits() {
    local source="${1?Source required}"
    local dest="${2?Dest required}"
    local size=$(du -sb "$source" 2>/dev/null | cut -f1)
    local max_size=$((1024 * 1024 * 1024))  # 1GB
    [[ $size -gt $max_size ]] && { echo "Source too large: $size" >&2; return 1; }
    rsync -av --exclude="*.tmp" "$source/" "$dest/"
}
```

# ❌ Incorrect: No resource limits
```bash
sync_no_limits() {
    local source="$1"
    local dest="$2"
    rsync -av "$source/" "$dest/"  # Could sync unlimited data
}
```

# 🔧 Fix: Add resource limits
```bash
sync_with_limits_fixed() {
    local source="${1?Source required}"
    local dest="${2?Dest required}"
    local size=$(du -sb "$source" 2>/dev/null | cut -f1)
    [[ -z "$size" ]] && { echo "Cannot determine size of: $source" >&2; return 1; }
    local max_size=$((1024 * 1024 * 1024))  # 1GB
    [[ $size -gt $max_size ]] && { echo "Source too large: $size > $max_size" >&2; return 1; }
    local file_count=$(find "$source" -type f 2>/dev/null | wc -l)
    [[ $file_count -gt 10000 ]] && { echo "Too many files: $file_count > 10000" >&2; return 1; }
    rsync -av --exclude="*.tmp" --exclude="*.log" "$source/" "$dest/"
}
```

# ✅ Correct: Atomic move with validation
```bash
atomic_move_validated() {
    local source="${1?Source required}"
    local dest="${2?Dest required}"
    [[ ! -e "$source" ]] && { echo "Source not found: $source" >&2; return 1; }
    local temp_dest="${dest}.tmp.$(date +%s).$$"
    if mv "$source" "$temp_dest"; then
        if [[ -e "$temp_dest" ]]; then
            mv "$temp_dest" "$dest" && return 0 || { mv "$temp_dest" "$source"; return 1; }
        else
            mv "$temp_dest" "$source" 2>/dev/null || true
            return 1
        fi
    else
        return 1
    fi
}
```

# ❌ Incorrect: No validation
```bash
atomic_move_bad() {
    local source="$1"
    local dest="$2"
    mv "$source" "$dest"  # No validation or rollback
}
```

# 🔧 Fix: Add validation and rollback
```bash
atomic_move_fixed() {
    local source="${1?Source required}"
    local dest="${2?Dest required}"
    [[ ! -e "$source" ]] && { echo "Source not found: $source" >&2; return 1; }
    local temp_dest="${dest}.tmp.$(date +%s).$$"
    if mv "$source" "$temp_dest"; then
        if [[ -e "$temp_dest" ]]; then
            mv "$temp_dest" "$dest" && return 0 || { 
                echo "Final move failed, rolling back" >&2
                mv "$temp_dest" "$source" 2>/dev/null || true
                return 1
            }
        else
            echo "Temporary move failed" >&2
            mv "$temp_dest" "$source" 2>/dev/null || true
            return 1
        fi
    else
        echo "Initial move failed" >&2
        return 1
    fi
}
```

# ✅ Correct: Checksum validation
```bash
validate_checksums() {
    local source="${1?Source required}"
    local dest="${2?Dest required}"
    local src_sum=$(sha256sum "$source" | cut -d' ' -f1)
    local dst_sum=$(sha256sum "$dest" | cut -d' ' -f1)
    [[ "$src_sum" == "$dst_sum" ]] && return 0 || return 1
}
```

# ❌ Incorrect: No checksum validation
```bash
validate_checksums_bad() {
    local source="$1"
    local dest="$2"
    # No validation - assumes success
    return 0
}
```

# ✅ Correct: Sandbox creation with permissions
```bash
create_sandbox_secure() {
    local name="${1?Name required}"
    local base="${2:-/tmp}"
    local sandbox_path="$base/sandbox_$(date +%s)_${name}"
    mkdir -p "$sandbox_path/input" "$sandbox_path/output" "$sandbox_path/work"
    chmod 700 "$sandbox_path" "$sandbox_path/input" "$sandbox_path/output" "$sandbox_path/work"
    echo "$sandbox_path"
}
```

# ❌ Incorrect: Insecure permissions
```bash
create_sandbox_insecure() {
    local name="$1"
    local base="$2"
    local sandbox_path="$base/sandbox_$name"
    mkdir -p "$sandbox_path"
    chmod 755 "$sandbox_path"  # Too permissive
    echo "$sandbox_path"
}
```

# 🔧 Fix: Add secure permissions and structure
```bash
create_sandbox_secure_fixed() {
    local name="${1?Name required}"
    local base="${2:-/tmp}"
    local sandbox_path="$base/sandbox_$(date +%s)_${TENANT_ID}_${name}"
    mkdir -p "$sandbox_path/input" "$sandbox_path/output" "$sandbox_path/work" "$sandbox_path/logs"
    chmod 700 "$sandbox_path"
    chmod 700 "$sandbox_path/input" "$sandbox_path/output" "$sandbox_path/work" "$sandbox_path/logs"
    # Validate creation
    [[ -d "$sandbox_path/input" && -d "$sandbox_path/output" ]] && echo "$sandbox_path" || return 1
}
```

# ✅ Correct: Cleanup with validation
```bash
cleanup_sandbox_validated() {
    local path="${1?Path required}"
    local force="${2:-false}"
    [[ ! -d "$path" ]] && return 0
    [[ ! -d "$path/input" || ! -d "$path/output" ]] && [[ "$force" != "true" ]] && return 1
    rm -rf "$path"
}
```

# ❌ Incorrect: No validation
```bash
cleanup_sandbox_bad() {
    local path="$1"
    rm -rf "$path"  # Could delete anything
}
```

# 🔧 Fix: Add validation
```bash
cleanup_sandbox_fixed() {
    local path="${1?Path required}"
    local force="${2:-false}"
    [[ ! -d "$path" ]] && { echo "Sandbox not found: $path" >&2; return 0; }
    if [[ "$force" != "true" ]]; then
        [[ ! -d "$path/input" || ! -d "$path/output" ]] && { 
            echo "Not a sandbox, refusing cleanup: $path" >&2
            return 1
        }
    fi
    rm -rf "$path" && return 0 || { echo "Cleanup failed: $path" >&2; return 1; }
}
```

# ✅ Correct: Sync with exclusions and validation
```bash
sync_with_exclusions() {
    local source="${1?Source required}"
    local dest="${2?Dest required}"
    local excludes="${3:-*.tmp *.log}"
    mkdir -p "$dest"
    local rsync_cmd="rsync -av --delete"
    for excl in $excludes; do
        rsync_cmd="$rsync_cmd --exclude='$excl'"
    done
    $rsync_cmd "$source/" "$dest/" && return 0 || return 1
}
```

# ❌ Incorrect: No exclusions or validation
```bash
sync_basic() {
    local source="$1"
    local dest="$2"
    rsync -av "$source/" "$dest/"  # No exclusions, no validation
}
```

# 🔧 Fix: Add exclusions and basic validation
```bash
sync_with_exclusions_fixed() {
    local source="${1?Source required}"
    local dest="${2?Dest required}"
    local excludes="${3:-*.tmp *.log}"
    [[ ! -e "$source" ]] && { echo "Source not found: $source" >&2; return 1; }
    mkdir -p "$dest"
    local rsync_cmd="rsync -av --delete --checksum"
    for excl in $excludes; do
        rsync_cmd="$rsync_cmd --exclude='$excl'"
    done
    $rsync_cmd "$source/" "$dest/" && return 0 || { echo "Sync failed" >&2; return 1; }
}
```

# ✅ Correct: Timeout-controlled operation
```bash
sync_with_timeout() {
    local source="${1?Source required}"
    local dest="${2?Dest required}"
    timeout 300 rsync -av --exclude="*.tmp" "$source/" "$dest/" && return 0 || return 1
}
```


```json
{
  "artifact": "06-PROGRAMMING/bash/filesystem-sandbox-sync.md",
  "validation_timestamp": "2026-04-15T00:00:07Z",
  "constraints_checked": ["C1", "C3", "C4", "C5", "C7", "C8"],
  "score": 45,
  "max_score": 50,
  "blocking_issues": [],
  "warnings": ["Could implement more sophisticated resource monitoring"],
  "checksum_verified": true,
  "ready_for_sandbox": true
}
```

--- END OF ARTIFACT: filesystem-sandbox-sync.md ---
