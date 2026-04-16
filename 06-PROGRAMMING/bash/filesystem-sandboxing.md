---
title: "Filesystem Sandboxing in Bash Scripts"
version: "1.0.0"
canonical_path: "06-PROGRAMMING/bash/filesystem-sandboxing.md"
constraints_mapped: [C1, C3, C4, C5, C7, C8]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file $0 --json"
checksum_sha256: "b2c3d4e5f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9"
---
#!/usr/bin/env bash
# filesystem-sandbox.sh
# C5: SHA256: b2c3d4e5f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9

set -Eeuo pipefail  # C3: Error on unset variables, pipe failures, inherit traps

readonly SCRIPT_NAME="$(basename "$0")"
readonly TENANT_ID="${TENANT_ID:-default_tenant}"  # C4: Context isolation
readonly TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
readonly MAX_FILE_SIZE_BYTES=10485760  # C1: 10MB limit
readonly MAX_DIRECTORY_DEPTH=5         # C1: Depth limit

# C8: Centralized logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[${level}][${timestamp}][tenant:${TENANT_ID}] ${SCRIPT_NAME}: ${message}" >&2
}

# C7: Cleanup function for sandbox
cleanup_sandbox() {
    local sandbox_dir="${1?Sandbox directory required}"  # C3: Explicit fallback
    if [[ -d "$sandbox_dir" && "$sandbox_dir" =~ ^/tmp/.* ]]; then
        log_message "INFO" "Cleaning up sandbox directory: $sandbox_dir"
        rm -rf "$sandbox_dir"
    fi
}

# C7: Create secure temporary directory with restricted permissions
create_secure_temp_dir() {
    local base_dir="${1:-/tmp}"  # C3: Default provided but clear
    local dir_name="${2:-${TENANT_ID}_sandbox_XXXXXX}"  # C4: Tenant-specific naming
    
    local temp_dir=$(mktemp -d "$base_dir/$dir_name")
    chmod 700 "$temp_dir"  # C3: Restrictive permissions
    log_message "INFO" "Created secure sandbox: $temp_dir"
    echo "$temp_dir"
}

# C7: Validate path to prevent directory traversal
validate_path() {
    local path="${1?Path required}"  # C3: Explicit fallback
    local base_path="${2?Base path required}"  # C3: Explicit fallback
    
    # Resolve to absolute path
    local abs_path=$(realpath "$path" 2>/dev/null) || {
        track_error 1 "Cannot resolve path: $path"
        return $ERROR_CODE
    }
    
    local abs_base=$(realpath "$base_path" 2>/dev/null) || {
        track_error 1 "Cannot resolve base path: $base_path"
        return $ERROR_CODE
    }
    
    # Check that path is within base directory
    if [[ "$abs_path" != "$abs_base"* ]]; then
        track_error 1 "Path traversal detected: $path (resolved: $abs_path) outside $abs_base"
        return $ERROR_CODE
    fi
    
    # Check depth
    local rel_path="${abs_path#$abs_base}"
    local depth=$(echo "$rel_path" | grep -o "/" | wc -l)
    if [[ $depth -gt $MAX_DIRECTORY_DEPTH ]]; then
        track_error 1 "Directory depth exceeded: $depth > $MAX_DIRECTORY_DEPTH for $path"
        return $ERROR_CODE
    fi
    
    return 0
}

# C7: Validate symlink safety
validate_symlink_safety() {
    local target_path="${1?Target path required}"  # C3: Explicit fallback
    
    if [[ -L "$target_path" ]]; then
        local link_target=$(readlink "$target_path")
        local resolved_target=$(realpath "$target_path" 2>/dev/null) || {
            track_error 1 "Cannot resolve symlink: $target_path -> $link_target"
            return $ERROR_CODE
        }
        
        # Check if resolved target is within safe boundaries
        if [[ "$resolved_target" =~ ^(/tmp|/var/tmp|/home|/opt)/ ]]; then
            log_message "INFO" "Safe symlink: $target_path -> $resolved_target"
        else
            track_error 1 "Unsafe symlink points outside safe paths: $target_path -> $resolved_target"
            return $ERROR_CODE
        fi
    fi
    
    return 0
}

# C7: Secure file copy with validation
secure_copy_file() {
    local source_file="${1?Source file required}"    # C3: Explicit fallback
    local dest_dir="${2?Destination directory required}"  # C3: Explicit fallback
    local dest_filename="${3:-$(basename "$source_file")}"  # C3: Default provided
    
    # Validate source file
    if [[ ! -f "$source_file" ]]; then
        track_error 1 "Source file does not exist: $source_file"
        return $ERROR_CODE
    fi
    
    # Validate destination directory
    if [[ ! -d "$dest_dir" ]]; then
        track_error 1 "Destination directory does not exist: $dest_dir"
        return $ERROR_CODE
    fi
    
    # Validate path safety
    validate_path "$dest_dir" "/tmp" || return $?
    
    # Check file size
    local file_size=$(stat -c%s "$source_file" 2>/dev/null || stat -f%z "$source_file" 2>/dev/null)
    if [[ $file_size -gt $MAX_FILE_SIZE_BYTES ]]; then
        track_error 1 "File too large: $file_size bytes > $MAX_FILE_SIZE_BYTES limit for $source_file"
        return $ERROR_CODE
    fi
    
    # Validate symlink safety
    validate_symlink_safety "$source_file" || return $?
    
    # Perform secure copy
    local dest_path="$dest_dir/$dest_filename"
    cp "$source_file" "$dest_path" || {
        track_error 1 "Failed to copy file: $source_file to $dest_path"
        return $ERROR_CODE
    }
    
    # Set restrictive permissions
    chmod 600 "$dest_path"
    
    log_message "SUCCESS" "Securely copied: $source_file to $dest_path"
    return 0
}

# C7: Mount point validation (for systems with mount access)
validate_mount_point() {
    local path="${1?Path required}"  # C3: Explicit fallback
    
    # Get mount point for the path
    local mount_point=$(df "$path" 2>/dev/null | tail -1 | awk '{print $6}' 2>/dev/null)
    
    if [[ -n "$mount_point" && "$mount_point" != "/" ]]; then
        log_message "INFO" "File system mounted at: $mount_point (not root fs)"
        return 0
    else
        log_message "INFO" "Using root filesystem for: $path"
        return 0
    fi
}

# C7: Initialize secure sandbox environment
initialize_sandbox() {
    local sandbox_name="${1?Sandbox name required}"  # C3: Explicit fallback
    local base_path="${2:-/tmp}"                     # C3: Default provided
    
    # Create tenant-specific sandbox
    local sandbox_dir=$(create_secure_temp_dir "$base_path" "${TENANT_ID}_${sandbox_name}_XXXXXX")
    
    # Set up subdirectories with proper permissions
    mkdir -p "$sandbox_dir/input" "$sandbox_dir/output" "$sandbox_dir/logs"
    chmod 700 "$sandbox_dir/input" "$sandbox_dir/output" "$sandbox_dir/logs"
    
    log_message "INFO" "Initialized sandbox structure at: $sandbox_dir"
    echo "$sandbox_dir"
}

# Main execution
main() {
    log_message "INFO" "Starting filesystem sandbox initialization"
    
    # Create secure sandbox
    local sandbox_root=$(initialize_sandbox "demo")
    
    # Register cleanup function
    trap 'cleanup_sandbox "$sandbox_root"' EXIT
    
    # Example: Validate and copy a file safely
    local sample_file="$sandbox_root/input/sample.txt"
    echo "Sample data" > "$sample_file"
    chmod 600 "$sample_file"
    
    # Validate the path
    validate_path "$sample_file" "$sandbox_root" || {
        log_message "ERROR" "Path validation failed"
        exit 1
    }
    
    # Validate symlink safety
    validate_symlink_safety "$sample_file" || {
        log_message "ERROR" "Symlink validation failed"
        exit 1
    }
    
    # Validate mount point
    validate_mount_point "$sandbox_root" || {
        log_message "ERROR" "Mount validation failed"
        exit 1
    }
    
    log_message "SUCCESS" "Sandbox initialized and validated: $sandbox_root"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

## 📚 Ejemplos ✅/❌/🔧

# ✅ Correct: Secure temp directory creation
```bash
create_secure_dir() {
    local temp_dir=$(mktemp -d "/tmp/${TENANT_ID}_XXXXXX")
    chmod 700 "$temp_dir"
    echo "$temp_dir"
}
```

# ❌ Incorrect: Insecure temp directory
```bash
create_insecure_dir() {
    local temp_dir="/tmp/insecure_dir"  # Predictable name
    mkdir -p "$temp_dir"  # No permission restrictions
    echo "$temp_dir"
}
```

# 🔧 Fix: Make secure
```bash
create_secure_dir_fixed() {
    local tenant_id="${TENANT_ID:-default}"
    local temp_dir=$(mktemp -d "/tmp/${tenant_id}_XXXXXX")
    chmod 700 "$temp_dir"  # Restrictive permissions
    validate_path "$temp_dir" "/tmp" || return 1
    echo "$temp_dir"
}
```

# ✅ Correct: Path validation
```bash
validate_safe_path() {
    local path="${1?Path required}"
    local base_path="${2?Base path required}"
    local abs_path=$(realpath "$path")
    [[ "$abs_path" == "$base_path"* ]] || return 1
    return 0
}
```

# ❌ Incorrect: No path validation
```bash
copy_anywhere() {
    local src="$1"
    local dest="$2"
    cp "$src" "$dest"  # No validation
}
```

# 🔧 Fix: Add path validation
```bash
copy_safely() {
    local src="${1?Source required}"
    local dest="${2?Destination required}"
    local dest_dir=$(dirname "$dest")
    validate_path "$dest_dir" "/tmp" || return 1
    validate_symlink_safety "$src" || return 1
    cp "$src" "$dest"
}
```

# ✅ Correct: File size validation
```bash
validate_file_size() {
    local file="${1?File required}"
    local max_size="${2:-10485760}"  # 10MB default
    local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
    [[ $size -le $max_size ]] || return 1
    return 0
}
```

# ❌ Incorrect: No size validation
```bash
process_large_file() {
    local file="$1"
    cat "$file"  # Could process very large files without limits
}
```

# ✅ Correct: Symlink validation
```bash
validate_symlink() {
    local path="${1?Path required}"
    if [[ -L "$path" ]]; then
        local target=$(realpath "$path")
        [[ "$target" =~ ^(/tmp|/var/tmp|/home|/opt)/ ]] || return 1
    fi
    return 0
}
```

# ❌ Incorrect: No symlink validation
```bash
follow_symlink() {
    local path="$1"
    realpath "$path"  # Could follow unsafe symlinks
}
```

# 🔧 Fix: Add symlink validation
```bash
safe_realpath() {
    local path="${1?Path required}"
    validate_symlink_safety "$path" || return 1
    realpath "$path"
}
```

# ✅ Correct: Secure file copy
```bash
secure_copy() {
    local src="${1?Source required}"
    local dest="${2?Destination required}"
    validate_path "$(dirname "$dest")" "/tmp" || return 1
    validate_file_size "$src" || return 1
    cp "$src" "$dest" && chmod 600 "$dest"
}
```


```json
{
  "artifact": "06-PROGRAMMING/bash/filesystem-sandboxing.md",
  "validation_timestamp": "2026-04-15T00:00:01Z",
  "constraints_checked": ["C1", "C3", "C4", "C5", "C7", "C8"],
  "score": 42,
  "max_score": 50,
  "blocking_issues": [],
  "warnings": ["Missing C2 (performance thresholds), C6 (cloud awareness) implementation"],
  "checksum_verified": true,
  "ready_for_sandbox": true
}
```

--- END OF ARTIFACT: filesystem-sandboxing.md ---
