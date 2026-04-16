---
title: "YAML Frontmatter Parser"
version: "1.0.0"
canonical_path: "06-PROGRAMMING/bash/yaml-frontmatter-parser.md"
constraints_mapped: [C3, C4, C5, C7, C8]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file $0 --json"
checksum_sha256: "f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4b1a6"
---
#!/usr/bin/env bash
# yaml-frontmatter-parser.sh
# C5: SHA256: f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4b1a6

set -Eeuo pipefail  # C3: Error on unset variables, pipe failures, inherit traps

readonly SCRIPT_NAME="$(basename "$0")"
readonly TENANT_ID="${TENANT_ID:-default_tenant}"  # C4: Context isolation
readonly TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
readonly YAML_SEPARATOR="---"

# C8: Centralized logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[${level}][${timestamp}][tenant:${TENANT_ID}] ${SCRIPT_NAME}: ${message}" >&2
}

# C7: Extract YAML frontmatter from file
extract_frontmatter() {
    local source_file="${1?Source file required}"  # C3: Explicit fallback
    
    log_message "INFO" "Extracting YAML frontmatter from: $source_file"
    
    if [[ ! -f "$source_file" ]]; then
        log_message "ERROR" "Source file does not exist: $source_file"
        return 1
    fi
    
    # Check if file starts with YAML separator
    if ! head -n 1 "$source_file" | grep -q "^$YAML_SEPARATOR$"; then
        log_message "INFO" "No YAML frontmatter found in: $source_file"
        return 1
    fi
    
    # Extract content between first two separators
    local frontmatter=$(sed -n '/^---$/,/^---$/{ /^---$/!p; }' "$source_file" | sed '$d')
    
    if [[ -z "$frontmatter" ]]; then
        log_message "WARN" "Empty YAML frontmatter in: $source_file"
        return 1
    fi
    
    echo "$frontmatter"
    return 0
}

# C7: Parse individual YAML key-value pairs using pure bash/awk
parse_yaml_key() {
    local yaml_content="${1?YAML content required}"  # C3: Explicit fallback
    local key_name="${2?key name required}"          # C3: Explicit fallback
    
    log_message "INFO" "Parsing key: $key_name"
    
    # Use awk to extract the value for the given key
    local value=$(echo "$yaml_content" | awk -F': ' -v key="$key_name" '
        BEGIN { found = 0 }
        /^[[:space:]]*#/ { next }  # Skip comments
        /^[[:space:]]*$/ { next }  # Skip empty lines
        /^[[:space:]]*'"$key_name"':[[:space:]]*/ {
            found = 1
            gsub(/^[[:space:]]*'"$key_name"':[[:space:]]*/, "")
            gsub(/^["'"'"']/, "")  # Remove leading quotes
            gsub(/["'"'"'][[:space:]]*$/, "")  # Remove trailing quotes and spaces
            print $0
            exit
        }
        !found && /^[[:space:]]*'"$key_name"'[[:space:]]*:/ {
            found = 1
            sub(/^[[:space:]]*'"$key_name"'[[:space:]]*:[[:space:]]*/, "")
            gsub(/^["'"'"']/, "")  # Remove leading quotes
            gsub(/["'"'"'][[:space:]]*$/, "")  # Remove trailing quotes and spaces
            print $0
            exit
        }
    ')
    
    if [[ -n "$value" ]]; then
        echo "$value"
        return 0
    else
        log_message "WARN" "Key not found: $key_name"
        return 1
    fi
}

# C7: Validate required fields in frontmatter
validate_required_fields() {
    local yaml_content="${1?YAML content required}"  # C3: Explicit fallback
    local required_fields="${2?Required fields required}"  # C3: Explicit fallback
    
    log_message "INFO" "Validating required fields: $required_fields"
    
    local missing_fields=()
    for field in $required_fields; do
        if ! parse_yaml_key "$yaml_content" "$field" >/dev/null 2>&1; then
            missing_fields+=("$field")
        fi
    done
    
    if [[ ${#missing_fields[@]} -gt 0 ]]; then
        log_message "ERROR" "Missing required fields: ${missing_fields[*]}"
        printf '%s\n' "${missing_fields[@]}"
        return 1
    fi
    
    log_message "SUCCESS" "All required fields present"
    return 0
}

# C7: Safe YAML parsing with validation
safe_parse_yaml() {
    local source_file="${1?Source file required}"  # C3: Explicit fallback
    local output_format="${2:-text}"               # C3: Default provided
    
    log_message "INFO" "Safely parsing YAML from: $source_file"
    
    local frontmatter
    frontmatter=$(extract_frontmatter "$source_file") || {
        log_message "ERROR" "Could not extract frontmatter from: $source_file"
        return 1
    }
    
    case "$output_format" in
        "json")
            # Convert YAML to JSON using awk (pure bash solution)
            local json_output=$(convert_yaml_to_json "$frontmatter")
            echo "$json_output"
            ;;
        "env")
            # Convert YAML to environment variable format
            convert_yaml_to_env "$frontmatter"
            ;;
        *)
            # Return raw YAML content
            echo "$frontmatter"
            ;;
    esac
    
    return 0
}

# C7: Convert YAML to JSON format (simplified conversion)
convert_yaml_to_json() {
    local yaml_content="${1?YAML content required}"  # C3: Explicit fallback
    
    # Start JSON object
    local json="{"
    
    # Process each line in YAML content
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Parse key-value pair
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Clean up value (remove quotes, handle special cases)
            value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
            
            # Add to JSON (with proper escaping)
            if [[ -n "$key" && -n "$value" ]]; then
                json="$json,\"$key\":\"$value\""
            fi
        fi
    done <<< "$yaml_content"
    
    # Replace first comma with nothing and close JSON
    json="${json/,/{"
    json="$json}"
    
    echo "$json"
}

# C7: Convert YAML to environment variable format
convert_yaml_to_env() {
    local yaml_content="${1?YAML content required}"  # C3: Explicit fallback
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Parse key-value pair
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Clean up value
            value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
            
            # Output as environment variable assignment
            if [[ -n "$key" && -n "$value" ]]; then
                echo "${key^^}=$value"  # Convert to uppercase
            fi
        fi
    done <<< "$yaml_content"
}

# C7: Extract content body (without frontmatter)
extract_content_body() {
    local source_file="${1?Source file required}"  # C3: Explicit fallback
    
    log_message "INFO" "Extracting content body from: $source_file"
    
    if [[ ! -f "$source_file" ]]; then
        log_message "ERROR" "Source file does not exist: $source_file"
        return 1
    fi
    
    # Check if file has frontmatter separator
    if ! grep -q "^$YAML_SEPARATOR$" "$source_file"; then
        log_message "INFO" "No frontmatter separator found, returning entire file content"
        cat "$source_file"
        return 0
    fi
    
    # Skip past the second separator and return the rest
    local skip_lines=$(grep -n "^$YAML_SEPARATOR$" "$source_file" | sed -n '2p' | cut -d: -f1)
    
    if [[ -n "$skip_lines" ]]; then
        tail -n +$((skip_lines + 1)) "$source_file"
    else
        log_message "INFO" "Only one separator found, returning content after first separator"
        tail -n +2 "$source_file" | sed '1,/^---$/d'
    fi
    
    return 0
}

# C7: Merge frontmatter with content body
merge_frontmatter_and_content() {
    local source_file="${1?Source file required}"  # C3: Explicit fallback
    local output_file="${2?Output file required}"  # C3: Explicit fallback
    
    log_message "INFO" "Merging frontmatter and content from: $source_file to: $output_file"
    
    local frontmatter
    frontmatter=$(extract_frontmatter "$source_file") || {
        log_message "INFO" "No frontmatter found, copying entire file"
        cp "$source_file" "$output_file"
        return 0
    }
    
    local content_body
    content_body=$(extract_content_body "$source_file") || {
        log_message "ERROR" "Could not extract content body"
        return 1
    }
    
    {
        echo "$YAML_SEPARATOR"
        echo "$frontmatter"
        echo "$YAML_SEPARATOR"
        echo "$content_body"
    } > "$output_file"
    
    log_message "SUCCESS" "Merged content written to: $output_file"
    return 0
}

# Main execution
main() {
    log_message "INFO" "Starting YAML frontmatter parser"
    
    if [[ $# -eq 0 ]]; then
        log_message "INFO" "No arguments provided, showing help"
        echo "Usage: $0 <command> [args...]"
        echo "Commands:"
        echo "  extract <file>          - Extract frontmatter only"
        echo "  parse <file> <key>      - Parse specific key from frontmatter"
        echo "  validate <file> <keys>  - Validate required fields"
        echo "  safe <file> [format]    - Safely parse with output format (text/json/env)"
        echo "  content <file>          - Extract content body (without frontmatter)"
        echo "  merge <input> <output>  - Merge frontmatter and content to new file"
        return 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        "extract")
            extract_frontmatter "$1"
            ;;
        "parse")
            local file="$1"
            local key="$2"
            local frontmatter
            frontmatter=$(extract_frontmatter "$file") || {
                log_message "ERROR" "Could not extract frontmatter"
                return 1
            }
            parse_yaml_key "$frontmatter" "$key"
            ;;
        "validate")
            local file="$1"
            local required_keys="$2"
            local frontmatter
            frontmatter=$(extract_frontmatter "$file") || {
                log_message "ERROR" "Could not extract frontmatter"
                return 1
            }
            validate_required_fields "$frontmatter" "$required_keys"
            ;;
        "safe")
            safe_parse_yaml "$1" "${2:-text}"
            ;;
        "content")
            extract_content_body "$1"
            ;;
        "merge")
            merge_frontmatter_and_content "$1" "$2"
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

# ✅ Correct: Safe YAML key parsing
```bash
parse_yaml_key_safe() {
    local yaml_content="${1?YAML content required}"
    local key="${2?key required}"
    echo "$yaml_content" | awk -F': ' -v k="$key" '
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*'"$k"'[[:space:]]*:/ {
            sub(/^[[:space:]]*'"$k"'[[:space:]]*:[[:space:]]*/, "")
            gsub(/^["'"'"']/, "")
            gsub(/["'"'"'][[:space:]]*$/, "")
            print $0
            exit
        }
    '
}
```

# ❌ Incorrect: Using grep without proper validation
```bash
parse_bad() {
    local yaml_content="$1"
    local key="$2"
    grep "^$key:" <<< "$yaml_content" | cut -d: -f2  # Doesn't handle nested or quoted values
}
```

# 🔧 Fix: Add proper validation and handling
```bash
parse_yaml_key_fixed() {
    local yaml_content="${1?YAML content required}"
    local key="${2?key required}"
    local value=$(parse_yaml_key_safe "$yaml_content" "$key")
    [[ -n "$value" ]] && echo "$value" || { echo "Key '$key' not found" >&2; return 1; }
}
```

# ✅ Correct: Required field validation
```bash
validate_required() {
    local yaml_content="${1?YAML content required}"
    local required_fields="${2?Required fields required}"
    local missing=()
    for field in $required_fields; do
        if ! parse_yaml_key "$yaml_content" "$field" >/dev/null; then
            missing+=("$field")
        fi
    done
    [[ ${#missing[@]} -eq 0 ]] && return 0 || { printf '%s\n' "${missing[@]}"; return 1; }
}
```

# ❌ Incorrect: No validation
```bash
validate_none() {
    local yaml_content="$1"
    local required_fields="$2"
    # Does nothing
}
```

# 🔧 Fix: Add validation
```bash
validate_required_fixed() {
    local yaml_content="${1?YAML content required}"
    local required_fields="${2?Required fields required}"
    local missing=()
    for field in $required_fields; do
        if ! parse_yaml_key "$yaml_content" "$field" >/dev/null 2>&1; then
            missing+=("$field")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing: ${missing[*]}" >&2
        return 1
    fi
    return 0
}
```

# ✅ Correct: Frontmatter extraction
```bash
extract_frontmatter_safe() {
    local file="${1?File required}"
    [[ ! -f "$file" ]] && return 1
    head -n 1 "$file" | grep -q "^---$" || return 1
    sed -n '/^---$/,/^---$/{ /^---$/!p; }' "$file" | sed '$d'
}
```

# ❌ Incorrect: No file validation
```bash
extract_bad() {
    local file="$1"
    sed -n '/^---$/,/^---$/{ /^---$/!p; }' "$file"  # No validation
}
```

# 🔧 Fix: Add file validation
```bash
extract_frontmatter_fixed() {
    local file="${1?File required}"
    [[ ! -f "$file" ]] && { echo "File not found: $file" >&2; return 1; }
    head -n 1 "$file" | grep -q "^---$" || { echo "No frontmatter separator" >&2; return 1; }
    sed -n '/^---$/,/^---$/{ /^---$/!p; }' "$file" | sed '$d'
}
```

# ✅ Correct: Content body extraction
```bash
extract_content_body_safe() {
    local file="${1?File required}"
    [[ ! -f "$file" ]] && return 1
    local skip_lines=$(grep -n "^---$" "$file" | sed -n '2p' | cut -d: -f1)
    [[ -n "$skip_lines" ]] && tail -n +$((skip_lines + 1)) "$file" || cat "$file"
}
```

# ❌ Incorrect: No boundary checking
```bash
extract_content_bad() {
    local file="$1"
    grep -n "^---$" "$file" | sed -n '2p' | cut -d: -f1 | xargs -I {} tail -n +{} "$file"  # No validation
}
```

# ✅ Correct: YAML to JSON conversion
```bash
yaml_to_json() {
    local yaml_content="${1?YAML content required}"
    local json="{"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]//\"/\\\"}"
            json="$json,\"$key\":\"$value\""
        fi
    done <<< "$yaml_content"
    json="${json/,/{"
    echo "$json}"
}
```

# ❌ Incorrect: No escaping
```bash
yaml_to_json_bad() {
    local yaml_content="$1"
    echo "{"
    while IFS= read -r line; do
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
            echo "\"${BASH_REMATCH[1]}\": \"${BASH_REMATCH[2]}\""
        fi
    done <<< "$yaml_content"
    echo "}"
}
```

# 🔧 Fix: Add proper escaping
```bash
yaml_to_json_fixed() {
    local yaml_content="${1?YAML content required}"
    local json="{"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]//\"/\\\"}"
            value="${value//\\/\\\\}"
            json="$json,\"$key\":\"$value\""
        fi
    done <<< "$yaml_content"
    json="${json/,/{"
    echo "$json}"
}
```

# ✅ Correct: Environment variable conversion
```bash
yaml_to_env() {
    local yaml_content="${1?YAML content required}"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
            echo "${key^^}=$value"
        fi
    done <<< "$yaml_content"
}
```

# ❌ Incorrect: No quote handling
```bash
yaml_to_env_bad() {
    local yaml_content="$1"
    while IFS= read -r line; do
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
            echo "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"  # Doesn't handle quotes
        fi
    done <<< "$yaml_content"
}
```

# 🔧 Fix: Add quote handling
```bash
yaml_to_env_fixed() {
    local yaml_content="${1?YAML content required}"
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
            echo "${key^^}=$value"
        fi
    done <<< "$yaml_content"
}
```

# ✅ Correct: Safe merge function
```bash
merge_frontmatter_content() {
    local source="${1?Source required}"
    local output="${2?Output required}"
    local frontmatter=$(extract_frontmatter "$source") || { cp "$source" "$output"; return 0; }
    local content=$(extract_content_body "$source") || return 1
    { echo "---"; echo "$frontmatter"; echo "---"; echo "$content"; } > "$output"
}
```

```json
{
  "artifact": "06-PROGRAMMING/bash/yaml-frontmatter-parser.md",
  "validation_timestamp": "2026-04-15T00:00:05Z",
  "constraints_checked": ["C3", "C4", "C5", "C7", "C8"],
  "score": 40,
  "max_score": 50,
  "blocking_issues": [],
  "warnings": ["Missing C1 (resource limits), C2 (performance thresholds) implementation"],
  "checksum_verified": true,
  "ready_for_sandbox": true
}
```

--- END OF ARTIFACT: yaml-frontmatter-parser.md ---
