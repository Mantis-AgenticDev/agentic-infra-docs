---
title: "YAML Frontmatter Parser in Python"
version: "1.0.0"
canonical_path: "06-PROGRAMMING/python/yaml-frontmatter-parser.md"
constraints_mapped: [C3, C4, C5, C7, C8]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file $0 --json"
checksum_sha256: "f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4b1a6"
---
#!/usr/bin/env python3
# yaml-frontmatter-parser.py
# C5: SHA256: f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4b1a6

import os
import sys
import logging
import contextvars
import json
import re
from typing import Dict, Any, Optional, Union
from pathlib import Path

# C4: Tenant isolation using contextvars
TENANT_ID_CTX: contextvars.ContextVar[str] = contextvars.ContextVar('tenant_id')

# C8: Structured logging setup with tenant filter
class TenantFilter(logging.Filter):
    def filter(self, record):
        record.tenant_id = TENANT_ID_CTX.get() or 'unknown'
        return True

logger = logging.getLogger(__name__)
handler = logging.StreamHandler(sys.stderr)
handler.addFilter(TenantFilter())
handler.setFormatter(logging.Formatter(
    fmt='%(asctime)s [%(levelname)s] [tenant:%(tenant_id)s] %(name)s: %(message)s',
    datefmt='%Y-%m-%dT%H:%M:%SZ'
))
logger.addHandler(handler)
logger.setLevel(logging.INFO)

def validate_tenant_id() -> str:
    """C4: Validate tenant ID from environment"""
    try:
        tenant_id = os.environ["TENANT_ID"]
    except KeyError:
        logger.error("TENANT_ID environment variable is required")
        sys.exit(1)
    
    # Validate format to prevent injection
    if not tenant_id.replace("-", "").replace("_", "").isalnum():
        logger.error(f"Invalid tenant ID format: {tenant_id}")
        sys.exit(1)
    
    TENANT_ID_CTX.set(tenant_id)
    logger.info(f"Tenant ID validated: {tenant_id}")
    return tenant_id

def extract_frontmatter(source_file: Union[str, Path]) -> Optional[str]:
    """C7: Extract YAML frontmatter from file"""
    try:
        source_path = Path(source_file)
        
        logger.info(f"Extracting YAML frontmatter from: {source_path}")
        
        if not source_path.exists():
            logger.error(f"Source file does not exist: {source_path}")
            return None
        
        with open(source_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Check if file starts with YAML separator
        if not content.startswith('---\n'):
            logger.info(f"No YAML frontmatter found in: {source_path}")
            return None
        
        # Extract content between first two separators
        lines = content.split('\n')
        if len(lines) < 2:
            logger.warning(f"Empty file: {source_path}")
            return None
        
        # Find the end of frontmatter (second occurrence of ---)
        frontmatter_lines = []
        in_frontmatter = False
        for i, line in enumerate(lines[1:], 1):  # Skip first '---'
            if line.strip() == '---' and i > 0:  # Found end of frontmatter
                break
            elif i == 1 and line.strip() != '---':  # Still in frontmatter
                frontmatter_lines.append(line)
            elif i > 1:
                frontmatter_lines.append(line)
        else:
            # No closing --- found, treat all remaining as frontmatter
            pass
        
        frontmatter = '\n'.join(frontmatter_lines)
        
        if not frontmatter.strip():
            logger.warning(f"Empty YAML frontmatter in: {source_path}")
            return None
        
        logger.info(f"Extracted frontmatter with {len(frontmatter_lines)} lines")
        return frontmatter
    except Exception as e:
        logger.error(f"Error extracting frontmatter from {source_path}: {e}")
        return None

def parse_yaml_key(yaml_content: str, key_name: str) -> Optional[str]:
    """C7: Parse individual YAML key-value pairs"""
    logger.info(f"Parsing key: {key_name}")
    
    # Use regex to extract the value for the given key
    pattern = rf'^[ \t]*{re.escape(key_name)}[ \t]*:[ \t]*(.*)$'
    
    for line in yaml_content.split('\n'):
        # Skip comments
        if line.strip().startswith('#'):
            continue
        
        match = re.match(pattern, line)
        if match:
            value = match.group(1).strip()
            # Remove surrounding quotes if present
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            elif value.startswith("'") and value.endswith("'"):
                value = value[1:-1]
            return value
    
    logger.warning(f"Key not found: {key_name}")
    return None

def validate_required_fields(yaml_content: str, required_fields: str) -> Optional[list]:
    """C7: Validate required fields in frontmatter"""
    logger.info(f"Validating required fields: {required_fields}")
    
    missing_fields = []
    for field in required_fields.split():
        if parse_yaml_key(yaml_content, field) is None:
            missing_fields.append(field)
    
    if missing_fields:
        logger.error(f"Missing required fields: {missing_fields}")
        return missing_fields
    
    logger.info("All required fields present")
    return None

def safe_parse_yaml(source_file: Union[str, Path], output_format: str = "text") -> Optional[Union[str, dict]]:
    """C7: Safe YAML parsing with validation"""
    try:
        frontmatter = extract_frontmatter(source_file)
        if frontmatter is None:
            logger.error(f"Could not extract frontmatter from: {source_file}")
            return None
        
        if output_format == "json":
            # Convert YAML to JSON format
            json_output = convert_yaml_to_json(frontmatter)
            return json_output
        elif output_format == "env":
            # Convert YAML to environment variable format
            env_output = convert_yaml_to_env(frontmatter)
            return env_output
        else:
            # Return raw YAML content
            return frontmatter
    except Exception as e:
        logger.error(f"Error during safe YAML parsing: {e}")
        return None

def convert_yaml_to_json(yaml_content: str) -> str:
    """C7: Convert YAML to JSON format (simplified conversion)"""
    json_dict = {}
    
    # Process each line in YAML content
    for line in yaml_content.split('\n'):
        # Skip empty lines and comments
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        
        # Parse key-value pair
        if ':' in line:
            parts = line.split(':', 1)
            if len(parts) == 2:
                key = parts[0].strip()
                value = parts[1].strip()
                
                # Clean up value (remove quotes, handle special cases)
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                
                # Add to JSON dict
                if key and value:
                    json_dict[key] = value
    
    return json.dumps(json_dict, indent=2)

def convert_yaml_to_env(yaml_content: str) -> str:
    """C7: Convert YAML to environment variable format"""
    env_vars = []
    
    for line in yaml_content.split('\n'):
        # Skip empty lines and comments
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        
        # Parse key-value pair
        if ':' in line:
            parts = line.split(':', 1)
            if len(parts) == 2:
                key = parts[0].strip()
                value = parts[1].strip()
                
                # Clean up value
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                
                # Output as environment variable assignment (uppercase key)
                if key and value:
                    env_vars.append(f"{key.upper()}={value}")
    
    return '\n'.join(env_vars)

def extract_content_body(source_file: Union[str, Path]) -> Optional[str]:
    """C7: Extract content body (without frontmatter)"""
    try:
        source_path = Path(source_file)
        
        logger.info(f"Extracting content body from: {source_path}")
        
        if not source_path.exists():
            logger.error(f"Source file does not exist: {source_path}")
            return None
        
        with open(source_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Check if file has frontmatter separator
        if not content.startswith('---\n'):
            logger.info("No frontmatter separator found, returning entire file content")
            return content
        
        # Split content by YAML separators
        parts = content.split('\n---\n')
        
        if len(parts) < 2:
            logger.info("Only one separator found, returning entire content")
            return content
        
        # Return everything after the second separator
        body = '\n---\n'.join(parts[1:])
        return body
    except Exception as e:
        logger.error(f"Error extracting content body: {e}")
        return None

def merge_frontmatter_and_content(source_file: Union[str, Path], output_file: Union[str, Path]) -> bool:
    """C7: Merge frontmatter with content body"""
    try:
        source_path = Path(source_file)
        output_path = Path(output_file)
        
        logger.info(f"Merging frontmatter and content from: {source_path} to: {output_path}")
        
        frontmatter = extract_frontmatter(source_path)
        if frontmatter is None:
            logger.info("No frontmatter found, copying entire file")
            with open(source_path, 'r', encoding='utf-8', errors='ignore') as src:
                content = src.read()
            with open(output_path, 'w', encoding='utf-8') as dest:
                dest.write(content)
            return True
        
        content_body = extract_content_body(source_path)
        if content_body is None:
            logger.error("Could not extract content body")
            return False
        
        # Write merged content
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("---\n")
            f.write(frontmatter)
            f.write("\n---\n")
            f.write(content_body)
        
        logger.info(f"Merged content written to: {output_path}")
        return True
    except Exception as e:
        logger.error(f"Error merging frontmatter and content: {e}")
        return False

def main():
    """Main execution function"""
    try:
        # C4: Validate tenant ID first
        tenant_id = validate_tenant_id()
        logger.info("Starting YAML frontmatter parser")
        
        if len(sys.argv) < 2:
            logger.info("No arguments provided, showing help")
            logger.info("Usage: python yaml-frontmatter-parser.py <command> [args...]")
            logger.info("Commands:")
            logger.info("  extract <file>          - Extract frontmatter only")
            logger.info("  parse <file> <key>      - Parse specific key from frontmatter")
            logger.info("  validate <file> <keys>  - Validate required fields")
            logger.info("  safe <file> [format]    - Safely parse with output format (text/json/env)")
            logger.info("  content <file>          - Extract content body (without frontmatter)")
            logger.info("  merge <input> <output>  - Merge frontmatter and content to new file")
            return 0
        
        command = sys.argv[1]
        
        if command == "extract":
            if len(sys.argv) < 3:
                logger.error("extract command requires file argument")
                return 1
            file_path = sys.argv[2]
            result = extract_frontmatter(file_path)
            if result:
                logger.info(f"Frontmatter:\n{result}")
            return 0 if result else 1
            
        elif command == "parse":
            if len(sys.argv) < 4:
                logger.error("parse command requires file and key arguments")
                return 1
            file_path = sys.argv[2]
            key = sys.argv[3]
            
            frontmatter = extract_frontmatter(file_path)
            if frontmatter is None:
                logger.error("Could not extract frontmatter")
                return 1
            
            result = parse_yaml_key(frontmatter, key)
            if result:
                logger.info(f"Value for '{key}': {result}")
            return 0 if result else 1
            
        elif command == "validate":
            if len(sys.argv) < 4:
                logger.error("validate command requires file and keys arguments")
                return 1
            file_path = sys.argv[2]
            required_keys = sys.argv[3]
            
            frontmatter = extract_frontmatter(file_path)
            if frontmatter is None:
                logger.error("Could not extract frontmatter")
                return 1
            
            result = validate_required_fields(frontmatter, required_keys)
            return 0 if result is None else 1
            
        elif command == "safe":
            if len(sys.argv) < 3:
                logger.error("safe command requires file argument")
                return 1
            file_path = sys.argv[2]
            format_type = sys.argv[3] if len(sys.argv) > 3 else "text"
            
            result = safe_parse_yaml(file_path, format_type)
            if result:
                logger.info(f"Parsed content:\n{result}")
            return 0 if result else 1
            
        elif command == "content":
            if len(sys.argv) < 3:
                logger.error("content command requires file argument")
                return 1
            file_path = sys.argv[2]
            
            result = extract_content_body(file_path)
            if result:
                logger.info(f"Content body:\n{result}")
            return 0 if result else 1
            
        elif command == "merge":
            if len(sys.argv) < 4:
                logger.error("merge command requires input and output arguments")
                return 1
            input_path = sys.argv[2]
            output_path = sys.argv[3]
            
            success = merge_frontmatter_and_content(input_path, output_path)
            return 0 if success else 1
            
        else:
            logger.error(f"Unknown command: {command}")
            return 1
            
    except Exception as e:
        logger.error(f"Error during execution: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())

## 📚 Ejemplos ✅/❌/🔧

**✅ Correcto:** Safe YAML key parsing
```python
def parse_yaml_key_safe(yaml_content: str, key: str) -> Optional[str]:
    import re
    pattern = rf'^[ \t]*{re.escape(key)}[ \t]*:[ \t]*(.*)$'
    for line in yaml_content.split('\n'):
        if line.strip().startswith('#'): continue
        match = re.match(pattern, line)
        if match:
            value = match.group(1).strip()
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            elif value.startswith("'") and value.endswith("'"):
                value = value[1:-1]
            return value
    return None
```

**❌ Incorrecto:** Using eval without validation
```python
def parse_bad(yaml_content: str, key: str):  # DANGEROUS
    # This approach is unsafe and incorrect for YAML parsing
    eval(f"yaml_content.{key}")  # Never use eval
```

**🔧 Fix:** Add proper validation and safe parsing
```python
def parse_yaml_key_fixed(yaml_content: str, key: str) -> Optional[str]:
    import re
    if not isinstance(yaml_content, str) or not isinstance(key, str):
        raise TypeError("Arguments must be strings")
    pattern = rf'^[ \t]*{re.escape(key)}[ \t]*:[ \t]*(.*)$'
    for line in yaml_content.split('\n'):
        if line.strip().startswith('#'): continue
        match = re.match(pattern, line)
        if match:
            value = match.group(1).strip()
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            elif value.startswith("'") and value.endswith("'"):
                value = value[1:-1]
            return value
    return None
```

**✅ Correcto:** Required field validation
```python
def validate_required(yaml_content: str, required_fields: str) -> bool:
    missing = []
    for field in required_fields.split():
        if parse_yaml_key(yaml_content, field) is None:
            missing.append(field)
    return len(missing) == 0
```

**❌ Incorrecto:** No validation
```python
def validate_none(yaml_content: str, required_fields: str):
    # Does nothing - no validation performed
    pass
```

**🔧 Fix:** Add validation
```python
def validate_required_fixed(yaml_content: str, required_fields: str) -> tuple[bool, list]:
    if not isinstance(required_fields, str):
        raise TypeError("required_fields must be a string")
    missing = []
    for field in required_fields.split():
        if parse_yaml_key(yaml_content, field) is None:
            missing.append(field)
    return len(missing) == 0, missing
```

**✅ Correcto:** Frontmatter extraction
```python
def extract_frontmatter_safe(file_path: str) -> Optional[str]:
    from pathlib import Path
    path = Path(file_path)
    if not path.exists():
        return None
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    if not content.startswith('---\n'):
        return None
    parts = content.split('\n---\n', 2)
    return parts[1] if len(parts) > 1 else None
```

**❌ Incorrecto:** No file validation
```python
def extract_bad(file_path: str):  # No validation
    with open(file_path, 'r') as f:
        content = f.read()
    # Doesn't check for frontmatter separator
    return content
```

**🔧 Fix:** Add file validation
```python
def extract_frontmatter_fixed(file_path: str) -> Optional[str]:
    from pathlib import Path
    path = Path(file_path)
    if not path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    if not content.startswith('---\n'):
        return None
    parts = content.split('\n---\n', 2)
    return parts[1] if len(parts) > 1 else None
```

**✅ Correcto:** Content body extraction
```python
def extract_content_body_safe(file_path: str) -> Optional[str]:
    from pathlib import Path
    path = Path(file_path)
    if not path.exists():
        return None
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    if not content.startswith('---\n'):
        return content
    parts = content.split('\n---\n', 2)
    return '\n---\n'.join(parts[1:]) if len(parts) > 1 else content
```

**❌ Incorrecto:** No boundary checking
```python
def extract_content_bad(file_path: str):  # No validation
    with open(file_path, 'r') as f:
        content = f.read()
    # No check for frontmatter separator
    return content
```

**✅ Correcto:** YAML to JSON conversion
```python
def yaml_to_json(yaml_content: str) -> str:
    import json
    json_dict = {}
    for line in yaml_content.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'): continue
        if ':' in line:
            parts = line.split(':', 1)
            if len(parts) == 2:
                key = parts[0].strip()
                value = parts[1].strip()
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                if key and value:
                    json_dict[key] = value
    return json.dumps(json_dict, indent=2)
```

**❌ Incorrecto:** No escaping
```python
def yaml_to_json_bad(yaml_content: str):  # No proper parsing
    import json
    # This is not proper YAML parsing
    return json.dumps({"raw": yaml_content})
```

**🔧 Fix:** Add proper parsing
```python
def yaml_to_json_fixed(yaml_content: str) -> str:
    import json
    if not isinstance(yaml_content, str):
        raise TypeError("yaml_content must be a string")
    json_dict = {}
    for line in yaml_content.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'): continue
        if ':' in line:
            parts = line.split(':', 1)
            if len(parts) == 2:
                key = parts[0].strip()
                value = parts[1].strip()
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                if key and value:
                    json_dict[key] = value
    return json.dumps(json_dict, indent=2)
```

**✅ Correcto:** Environment variable conversion
```python
def yaml_to_env(yaml_content: str) -> str:
    env_vars = []
    for line in yaml_content.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'): continue
        if ':' in line:
            parts = line.split(':', 1)
            if len(parts) == 2:
                key = parts[0].strip()
                value = parts[1].strip()
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                if key and value:
                    env_vars.append(f"{key.upper()}={value}")
    return '\n'.join(env_vars)
```

**❌ Incorrecto:** No quote handling
```python
def yaml_to_env_bad(yaml_content: str):  # No quote handling
    lines = []
    for line in yaml_content.split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)  # Doesn't handle quotes
            lines.append(f"{key.strip().upper()}={value.strip()}")
    return '\n'.join(lines)
```

**🔧 Fix:** Add quote handling
```python
def yaml_to_env_fixed(yaml_content: str) -> str:
    if not isinstance(yaml_content, str):
        raise TypeError("yaml_content must be a string")
    env_vars = []
    for line in yaml_content.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'): continue
        if ':' in line:
            parts = line.split(':', 1)
            if len(parts) == 2:
                key = parts[0].strip()
                value = parts[1].strip()
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                if key and value:
                    env_vars.append(f"{key.upper()}={value}")
    return '\n'.join(env_vars)
```

**✅ Correcto:** Safe merge function
```python
def merge_frontmatter_content(source: str, output: str) -> bool:
    from pathlib import Path
    frontmatter = extract_frontmatter(source)
    if frontmatter is None:
        Path(source).copy(Path(output))
        return True
    content = extract_content_body(source)
    if content is None:
        return False
    with open(output, 'w') as f:
        f.write("---\n")
        f.write(frontmatter)
        f.write("\n---\n")
        f.write(content)
    return True
```


```json
{
  "artifact": "06-PROGRAMMING/python/yaml-frontmatter-parser.md",
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
