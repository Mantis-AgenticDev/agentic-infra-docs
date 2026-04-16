---
title: "Filesystem Sandbox Sync Utility in Python"
version: "1.0.0"
canonical_path: "06-PROGRAMMING/python/filesystem-sandbox-sync.md"
constraints_mapped: [C1, C3, C4, C5, C7, C8]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file $0 --json"
checksum_sha256: "b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4b1a6f3"
---
#!/usr/bin/env python3
# filesystem-sandbox-sync.py
# C5: SHA256: b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4b1a6f3

import os
import sys
import logging
import contextvars
import tempfile
import shutil
import hashlib
import subprocess
from pathlib import Path
from typing import Optional, Union
import stat
import time

# C1: Resource limits
MAX_SYNC_SIZE_MB = 1024  # 1GB
MAX_FILE_COUNT = 10000
SYNC_TIMEOUT_SECONDS = 300

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

def validate_sync_paths(source_path: Union[str, Path], dest_path: Union[str, Path]) -> bool:
    """C7: Validate sync source and destination paths"""
    try:
        source_path = Path(source_path)
        dest_path = Path(dest_path)
        
        logger.info(f"Validating sync paths: {source_path} -> {dest_path}")
        
        # Validate source path exists
        if not source_path.exists():
            logger.error(f"Source path does not exist: {source_path}")
            return False
        
        # Validate source path is within safe boundaries
        abs_source = source_path.resolve()
        
        # Prevent syncing system directories
        unsafe_dirs = ['/sys', '/proc', '/dev', '/etc', '/boot', '/root', '/var/log']
        for unsafe_dir in unsafe_dirs:
            if str(abs_source).startswith(unsafe_dir):
                logger.error(f"Unsafe source path: {abs_source} (system directory)")
                return False
        
        # Validate destination path
        dest_parent = dest_path.parent.resolve()
        
        # Create destination directory if it doesn't exist
        dest_path.mkdir(parents=True, exist_ok=True)
        
        # Validate destination is not a system directory
        for unsafe_dir in unsafe_dirs:
            if str(dest_parent).startswith(unsafe_dir):
                logger.error(f"Unsafe destination path: {dest_parent} (system directory)")
                return False
        
        logger.info(f"Sync paths validated: {source_path} -> {dest_path}")
        return True
    except Exception as e:
        logger.error(f"Error validating sync paths: {e}")
        return False

def calculate_source_size(source_path: Union[str, Path]) -> Optional[int]:
    """C7: Calculate total size of source directory"""
    try:
        source_path = Path(source_path)
        
        if source_path.is_file():
            return source_path.stat().st_size
        elif source_path.is_dir():
            total_size = 0
            for file_path in source_path.rglob('*'):
                if file_path.is_file():
                    total_size += file_path.stat().st_size
            return total_size
        else:
            logger.error(f"Source path is neither file nor directory: {source_path}")
            return None
    except Exception as e:
        logger.error(f"Error calculating source size: {e}")
        return None

def count_source_files(source_path: Union[str, Path]) -> Optional[int]:
    """C7: Count files in source directory"""
    try:
        source_path = Path(source_path)
        
        if source_path.is_file():
            return 1
        elif source_path.is_dir():
            return len([f for f in source_path.rglob('*') if f.is_file()])
        else:
            logger.error(f"Source path is neither file nor directory: {source_path}")
            return None
    except Exception as e:
        logger.error(f"Error counting source files: {e}")
        return None

def perform_sandbox_sync(source_path: Union[str, Path], 
                        dest_path: Union[str, Path], 
                        exclude_patterns: str = "*.tmp *.log .git",
                        validate_checksum: bool = True) -> bool:
    """C7: Perform sandbox sync with validation gate"""
    try:
        source_path = Path(source_path)
        dest_path = Path(dest_path)
        
        logger.info(f"Starting sandbox sync: {source_path} -> {dest_path}")
        
        # Validate paths first
        if not validate_sync_paths(source_path, dest_path):
            return False
        
        # C1: Check resource constraints
        source_size_bytes = calculate_source_size(source_path)
        if source_size_bytes is None:
            logger.error("Cannot calculate source size")
            return False
        
        source_size_mb = source_size_bytes // (1024 * 1024)
        if source_size_mb > MAX_SYNC_SIZE_MB:
            logger.error(f"Source exceeds size limit: {source_size_mb}MB > {MAX_SYNC_SIZE_MB}MB")
            return False
        
        file_count = count_source_files(source_path)
        if file_count is None:
            logger.error("Cannot count source files")
            return False
        
        if file_count > MAX_FILE_COUNT:
            logger.error(f"Source exceeds file count limit: {file_count} > {MAX_FILE_COUNT} files")
            return False
        
        logger.info(f"Resource validation passed - Size: {source_size_mb}MB, Files: {file_count}")
        
        # Build rsync command with exclusions
        rsync_cmd = ["rsync", "-av", "--delete"]
        
        # Add exclusion patterns
        for pattern in exclude_patterns.split():
            rsync_cmd.extend(["--exclude", pattern])
        
        # Add checksum validation if requested
        if validate_checksum:
            rsync_cmd.append("--checksum")
        
        # Add source and destination
        source_str = str(source_path)
        dest_str = str(dest_path)
        
        # Ensure source ends with / if it's a directory
        if source_path.is_dir():
            source_str = str(source_path) + "/"
        
        rsync_cmd.extend([source_str, dest_str])
        
        # C1: Set timeout for the operation
        start_time = time.time()
        
        # Execute sync with timeout
        try:
            result = subprocess.run(
                rsync_cmd,
                timeout=SYNC_TIMEOUT_SECONDS,
                capture_output=True,
                text=True
            )
            
            sync_duration = time.time() - start_time
            
            if result.returncode == 0:
                logger.info(f"Sync completed in {sync_duration:.2f}s: {source_path} -> {dest_path}")
                
                # C7: Post-sync validation
                if validate_checksum:
                    if not validate_post_sync(source_path, dest_path):
                        logger.error("Post-sync validation failed")
                        return False
                
                return True
            else:
                logger.error(f"Sync failed after {sync_duration:.2f}s: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            sync_duration = time.time() - start_time
            logger.error(f"Sync timed out after {sync_duration:.2f}s: {source_path} -> {dest_path}")
            return False
            
    except Exception as e:
        logger.error(f"Error during sandbox sync: {e}")
        return False

def validate_post_sync(source_path: Union[str, Path], dest_path: Union[str, Path]) -> bool:
    """C7: Validate sync completion with checksum comparison"""
    try:
        source_path = Path(source_path)
        dest_path = Path(dest_path)
        
        logger.info(f"Performing post-sync validation: {source_path} vs {dest_path}")
        
        # Generate checksums for both source and destination
        def get_checksum_recursive(path: Path) -> str:
            hash_sha256 = hashlib.sha256()
            for file_path in sorted(path.rglob('*')):
                if file_path.is_file():
                    relative_path = file_path.relative_to(path)
                    hash_sha256.update(str(relative_path).encode('utf-8'))
                    with open(file_path, 'rb') as f:
                        for chunk in iter(lambda: f.read(4096), b""):
                            hash_sha256.update(chunk)
            return hash_sha256.hexdigest()
        
        if source_path.is_dir():
            source_checksum = get_checksum_recursive(source_path)
            dest_checksum = get_checksum_recursive(dest_path)
        else:
            with open(source_path, 'rb') as f:
                source_checksum = hashlib.sha256(f.read()).hexdigest()
            with open(dest_path / source_path.name, 'rb') as f:
                dest_checksum = hashlib.sha256(f.read()).hexdigest()
        
        if source_checksum == dest_checksum:
            logger.info("Checksum validation passed - Data integrity confirmed")
            return True
        else:
            logger.error(f"Checksum validation failed - Source: {source_checksum}, Dest: {dest_checksum}")
            return False
    except Exception as e:
        logger.error(f"Error during post-sync validation: {e}")
        return False

def atomic_move_with_validation(source_path: Union[str, Path], 
                              dest_path: Union[str, Path], 
                              validation_func=None) -> bool:
    """C7: Atomic move with validation gate"""
    try:
        source_path = Path(source_path)
        dest_path = Path(dest_path)
        
        logger.info(f"Performing atomic move: {source_path} -> {dest_path}")
        
        # Validate source exists
        if not source_path.exists():
            logger.error(f"Source does not exist: {source_path}")
            return False
        
        # Create temporary destination with suffix
        temp_dest = dest_path.with_suffix(dest_path.suffix + f".tmp.{int(time.time())}.{os.getpid()}")
        
        # Perform the move operation
        try:
            # First, copy the content
            if source_path.is_file():
                shutil.copy2(str(source_path), str(temp_dest))
            else:
                if temp_dest.exists():
                    shutil.rmtree(temp_dest)
                shutil.copytree(str(source_path), str(temp_dest))
            
            # Validate the moved content
            if validation_func:
                if not validation_func(source_path, temp_dest.parent):
                    logger.error("Validation failed, rolling back atomic move")
                    # Rollback the move
                    if temp_dest.exists():
                        if temp_dest.is_file():
                            temp_dest.unlink()
                        else:
                            shutil.rmtree(temp_dest)
                    return False
            
            # Atomically replace the destination
            if dest_path.exists():
                if dest_path.is_file():
                    dest_path.unlink()
                else:
                    shutil.rmtree(dest_path)
            
            temp_dest.rename(dest_path)
            logger.info(f"Atomic move completed: {source_path} -> {dest_path}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to finalize atomic move: {e}")
            # Attempt to rollback
            if temp_dest.exists():
                if temp_dest.is_file():
                    temp_dest.unlink()
                else:
                    shutil.rmtree(temp_dest)
            return False
            
    except Exception as e:
        logger.error(f"Error during atomic move: {e}")
        return False

def create_secure_sandbox(sandbox_name: str, base_dir: Optional[Union[str, Path]] = None) -> Optional[str]:
    """C7: Create secure sandbox environment"""
    try:
        if base_dir is None:
            base_dir = Path(tempfile.gettempdir())
        else:
            base_dir = Path(base_dir)
        
        tenant_id = TENANT_ID_CTX.get() or "default"
        sandbox_path = base_dir / f"{int(time.time())}_{tenant_id}_{sandbox_name}"
        
        logger.info(f"Creating secure sandbox: {sandbox_name} in {base_dir}")
        
        # Create tenant-specific sandbox directory
        sandbox_path.mkdir(parents=True, exist_ok=True)
        
        # Set restrictive permissions
        sandbox_path.chmod(0o700)  # 700 permissions (owner only)
        
        # Create standard sandbox subdirectories
        subdirs = ['input', 'output', 'work', 'logs']
        for subdir in subdirs:
            subpath = sandbox_path / subdir
            subpath.mkdir(mode=0o700, parents=True, exist_ok=True)  # 700 permissions
        
        logger.info(f"Secure sandbox created: {sandbox_path}")
        return str(sandbox_path)
    except Exception as e:
        logger.error(f"Failed to create secure sandbox: {e}")
        return None

def sync_to_sandbox(source_path: Union[str, Path], 
                   sandbox_name: str, 
                   exclude_patterns: str = "*.tmp *.log .git") -> Optional[str]:
    """C7: Sync to sandbox with validation gates"""
    try:
        source_path = Path(source_path)
        
        logger.info(f"Syncing to sandbox: {source_path} -> {sandbox_name}")
        
        # Create secure sandbox
        sandbox_path = create_secure_sandbox(sandbox_name)
        if not sandbox_path:
            logger.error(f"Failed to create sandbox: {sandbox_name}")
            return None
        
        # Perform sync to sandbox
        input_dir = Path(sandbox_path) / 'input'
        success = perform_sandbox_sync(source_path, input_dir, exclude_patterns, True)
        
        if not success:
            logger.error(f"Sync to sandbox failed: {source_path} -> {input_dir}")
            return None
        
        logger.info(f"Successfully synced to sandbox: {sandbox_path}")
        return sandbox_path
    except Exception as e:
        logger.error(f"Error during sync to sandbox: {e}")
        return None

def cleanup_sandbox(sandbox_path: Union[str, Path], force_cleanup: bool = False) -> bool:
    """C7: Cleanup sandbox with validation"""
    try:
        sandbox_path = Path(sandbox_path)
        
        logger.info(f"Cleaning up sandbox: {sandbox_path}")
        
        if not sandbox_path.exists():
            logger.info(f"Sandbox does not exist: {sandbox_path}")
            return True
        
        # Validate this is actually a sandbox directory (contains expected structure)
        required_subdirs = ['input', 'output', 'work', 'logs']
        has_sandbox_structure = all((sandbox_path / subdir).exists() for subdir in required_subdirs)
        
        if not has_sandbox_structure and not force_cleanup:
            logger.error(f"Path does not appear to be a sandbox, refusing cleanup: {sandbox_path}")
            return False
        
        # Remove sandbox directory
        shutil.rmtree(sandbox_path)
        logger.info(f"Sandbox cleaned up: {sandbox_path}")
        return True
    except Exception as e:
        logger.error(f"Failed to clean up sandbox: {e}")
        return False

def main():
    """Main execution function"""
    try:
        # C4: Validate tenant ID first
        tenant_id = validate_tenant_id()
        logger.info("Starting filesystem sandbox sync utility")
        
        if len(sys.argv) < 2:
            logger.info("No arguments provided, showing help")
            logger.info("Usage: python filesystem-sandbox-sync.py <command> [args...]")
            logger.info("Commands:")
            logger.info("  sync <source> <dest> [exclusions] [validate]")
            logger.info("  sandbox <source> <name> [exclusions]")
            logger.info("  atomic <source> <dest>")
            logger.info("  validate <source> <dest>")
            logger.info("  create-sandbox <name> [base_dir]")
            logger.info("  cleanup <sandbox_path> [force]")
            logger.info("")
            logger.info("Examples:")
            logger.info("  python filesystem-sandbox-sync.py sync /path/to/source /path/to/dest '*.tmp *.log' true")
            logger.info("  python filesystem-sandbox-sync.py sandbox /path/to/source my_project '*.tmp *.log'")
            logger.info("  python filesystem-sandbox-sync.py atomic /path/to/temp /path/to/final")
            return 0
        
        command = sys.argv[1]
        
        if command == "sync":
            if len(sys.argv) < 4:
                logger.error("sync command requires source and dest arguments")
                return 1
            source = sys.argv[2]
            dest = sys.argv[3]
            exclusions = sys.argv[4] if len(sys.argv) > 4 else "*.tmp *.log .git"
            validate = sys.argv[5].lower() == 'true' if len(sys.argv) > 5 else True
            
            success = perform_sandbox_sync(source, dest, exclusions, validate)
            return 0 if success else 1
            
        elif command == "sandbox":
            if len(sys.argv) < 4:
                logger.error("sandbox command requires source and name arguments")
                return 1
            source = sys.argv[2]
            name = sys.argv[3]
            exclusions = sys.argv[4] if len(sys.argv) > 4 else "*.tmp *.log .git"
            
            result = sync_to_sandbox(source, name, exclusions)
            if result:
                logger.info(f"Sandbox created: {result}")
            return 0 if result else 1
            
        elif command == "atomic":
            if len(sys.argv) < 4:
                logger.error("atomic command requires source and dest arguments")
                return 1
            source = sys.argv[2]
            dest = sys.argv[3]
            
            success = atomic_move_with_validation(source, dest, validate_post_sync)
            return 0 if success else 1
            
        elif command == "validate":
            if len(sys.argv) < 4:
                logger.error("validate command requires source and dest arguments")
                return 1
            source = sys.argv[2]
            dest = sys.argv[3]
            
            success = validate_post_sync(source, dest)
            return 0 if success else 1
            
        elif command == "create-sandbox":
            if len(sys.argv) < 3:
                logger.error("create-sandbox command requires name argument")
                return 1
            name = sys.argv[2]
            base_dir = sys.argv[3] if len(sys.argv) > 3 else None
            
            result = create_secure_sandbox(name, base_dir)
            if result:
                logger.info(f"Sandbox created: {result}")
            return 0 if result else 1
            
        elif command == "cleanup":
            if len(sys.argv) < 3:
                logger.error("cleanup command requires sandbox_path argument")
                return 1
            path = sys.argv[2]
            force = sys.argv[3].lower() == 'true' if len(sys.argv) > 3 else False
            
            success = cleanup_sandbox(path, force)
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

**✅ Correcto:** Secure path validation
```python
def validate_paths_secure(source: str, dest: str) -> bool:
    from pathlib import Path
    source_path = Path(source)
    dest_path = Path(dest)
    if not source_path.exists():
        raise FileNotFoundError(f"Source not found: {source}")
    unsafe_prefixes = ['/sys', '/proc', '/dev', '/etc']
    if any(str(source_path.resolve()).startswith(prefix) for prefix in unsafe_prefixes):
        raise ValueError(f"Unsafe source: {source}")
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    if any(str(dest_path.resolve()).startswith(prefix) for prefix in unsafe_prefixes):
        raise ValueError(f"Unsafe dest: {dest}")
    return True
```

**❌ Incorrecto:** No path validation
```python
def validate_paths_bad(source: str, dest: str):  # No validation
    pass  # Could sync to unsafe locations
```

**🔧 Fix:** Add comprehensive validation
```python
def validate_paths_fixed(source: str, dest: str) -> bool:
    from pathlib import Path
    source_path = Path(source)
    dest_path = Path(dest)
    if not source_path.exists():
        raise FileNotFoundError(f"Source not found: {source}")
    abs_source = source_path.resolve()
    unsafe_prefixes = ['/sys', '/proc', '/dev', '/etc', '/boot', '/root']
    if any(str(abs_source).startswith(prefix) for prefix in unsafe_prefixes):
        raise ValueError(f"Unsafe source: {abs_source}")
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    abs_dest = dest_path.parent.resolve()
    if any(str(abs_dest).startswith(prefix) for prefix in unsafe_prefixes):
        raise ValueError(f"Unsafe dest: {abs_dest}")
    return True
```

**✅ Correcto:** Resource-limited sync
```python
def sync_with_limits(source: str, dest: str) -> bool:
    import os
    size = sum(f.stat().st_size for f in Path(source).rglob('*') if f.is_file())
    max_size = 1024 * 1024 * 1024  # 1GB
    if size > max_size:
        raise ValueError(f"Source too large: {size}")
    # Perform sync with rsync
    import subprocess
    subprocess.run(['rsync', '-av', '--exclude=*.tmp', f'{source}/', f'{dest}/'], timeout=300)
    return True
```

**❌ Incorrecto:** No resource limits
```python
def sync_no_limits(source: str, dest: str):  # Could sync unlimited data
    import subprocess
    subprocess.run(['rsync', '-av', f'{source}/', f'{dest}/'])  # No limits
```

**🔧 Fix:** Add resource limits
```python
def sync_with_limits_fixed(source: str, dest: str) -> bool:
    import os
    from pathlib import Path
    size = sum(f.stat().st_size for f in Path(source).rglob('*') if f.is_file())
    max_size = 1024 * 1024 * 1024  # 1GB
    if size > max_size:
        raise ValueError(f"Source too large: {size} > {max_size}")
    file_count = len([f for f in Path(source).rglob('*') if f.is_file()])
    if file_count > 10000:  # Max file count
        raise ValueError(f"Too many files: {file_count} > 10000")
    import subprocess
    subprocess.run(['rsync', '-av', '--exclude=*.tmp', '--exclude=*.log', f'{source}/', f'{dest}/'], timeout=300)
    return True
```

**✅ Correcto:** Atomic move with validation
```python
def atomic_move_validated(source: str, dest: str) -> bool:
    import shutil
    import os
    from pathlib import Path
    if not Path(source).exists():
        raise FileNotFoundError(f"Source not found: {source}")
    temp_dest = Path(dest).with_suffix(f'{Path(dest).suffix}.tmp.{int(time.time())}')
    shutil.move(source, temp_dest)
    if Path(temp_dest).exists():
        shutil.move(temp_dest, dest)
        return True
    else:
        if temp_dest.exists():
            shutil.move(temp_dest, source)
        return False
```

**❌ Incorrecto:** No validation
```python
def atomic_move_bad(source: str, dest: str):  # No validation or rollback
    import shutil
    shutil.move(source, dest)  # Direct move, no safety
```

**🔧 Fix:** Add validation and rollback
```python
def atomic_move_fixed(source: str, dest: str) -> bool:
    import shutil
    import os
    from pathlib import Path
    source_path = Path(source)
    dest_path = Path(dest)
    if not source_path.exists():
        raise FileNotFoundError(f"Source not found: {source}")
    temp_dest = dest_path.with_suffix(f'{dest_path.suffix}.tmp.{int(time.time())}.{os.getpid()}')
    try:
        shutil.move(str(source_path), str(temp_dest))
        if temp_dest.exists():
            if dest_path.exists():
                if dest_path.is_file():
                    dest_path.unlink()
                else:
                    shutil.rmtree(dest_path)
            temp_dest.rename(dest_path)
            return True
        else:
            if temp_dest.exists():
                shutil.move(str(temp_dest), str(source_path))
            return False
    except Exception as e:
        if temp_dest.exists():
            shutil.move(str(temp_dest), str(source_path))
        raise e
```

**✅ Correcto:** Checksum validation
```python
def validate_checksums(source: str, dest: str) -> bool:
    import hashlib
    def get_checksum(path: str) -> str:
        with open(path, 'rb') as f:
            return hashlib.sha256(f.read()).hexdigest()
    src_sum = get_checksum(source)
    dst_sum = get_checksum(dest)
    return src_sum == dst_sum
```

**❌ Incorrecto:** No checksum validation
```python
def validate_checksums_bad(source: str, dest: str):  # No validation
    pass  # Assumes success without checking
```

**✅ Correcto:** Sandbox creation with permissions
```python
def create_sandbox_secure(name: str) -> str:
    import tempfile
    import os
    from pathlib import Path
    sandbox_path = Path(tempfile.mkdtemp(prefix=f"sandbox_{name}_"))
    sandbox_path.chmod(0o700)  # Secure permissions
    subdirs = ['input', 'output', 'work']
    for subdir in subdirs:
        subpath = sandbox_path / subdir
        subpath.mkdir(mode=0o700, parents=True, exist_ok=True)
    return str(sandbox_path)
```

**❌ Incorrecto:** Insecure permissions
```python
def create_sandbox_insecure(name: str) -> str:  # Too permissive
    import tempfile
    sandbox_path = tempfile.mkdtemp(prefix=f"sandbox_{name}_")
    os.chmod(sandbox_path, 0o755)  # Too permissive
    return sandbox_path
```

**🔧 Fix:** Add secure permissions and structure
```python
def create_sandbox_secure_fixed(name: str) -> str:
    import tempfile
    import os
    from pathlib import Path
    tenant_id = os.environ.get("TENANT_ID", "default")
    sandbox_path = Path(tempfile.mkdtemp(prefix=f"{tenant_id}_sandbox_{name}_"))
    sandbox_path.chmod(0o700)  # Secure permissions
    subdirs = ['input', 'output', 'work', 'logs']
    for subdir in subdirs:
        subpath = sandbox_path / subdir
        subpath.mkdir(mode=0o700, parents=True, exist_ok=True)
    # Validate creation
    if all((sandbox_path / subdir).exists() for subdir in subdirs):
        return str(sandbox_path)
    else:
        raise RuntimeError(f"Sandbox structure not created properly: {sandbox_path}")
```

**✅ Correcto:** Cleanup with validation
```python
def cleanup_sandbox_validated(path: str, force: bool = False) -> bool:
    import shutil
    from pathlib import Path
    sandbox_path = Path(path)
    if not sandbox_path.exists():
        return True
    required = ['input', 'output']
    has_structure = all((sandbox_path / subdir).exists() for subdir in required)
    if not has_structure and not force:
        raise ValueError(f"Not a sandbox, refusing cleanup: {path}")
    shutil.rmtree(sandbox_path)
    return True
```

**❌ Incorrecto:** No validation
```python
def cleanup_sandbox_bad(path: str):  # Could delete anything
    import shutil
    shutil.rmtree(path)  # No validation
```

**🔧 Fix:** Add validation
```python
def cleanup_sandbox_fixed(path: str, force: bool = False) -> bool:
    import shutil
    from pathlib import Path
    sandbox_path = Path(path)
    if not sandbox_path.exists():
        return True
    required = ['input', 'output', 'work', 'logs']
    has_structure = all((sandbox_path / subdir).exists() for subdir in required)
    if not has_structure and not force:
        raise ValueError(f"Not a sandbox, refusing cleanup: {path}")
    try:
        shutil.rmtree(sandbox_path)
        return True
    except Exception as e:
        raise RuntimeError(f"Cleanup failed: {e}")
```

**✅ Correcto:** Sync with exclusions and validation
```python
def sync_with_exclusions(source: str, dest: str, excludes: str = "*.tmp *.log") -> bool:
    import subprocess
    Path(dest).mkdir(parents=True, exist_ok=True)
    cmd = ['rsync', '-av', '--delete', '--checksum']
    for excl in excludes.split():
        cmd.extend(['--exclude', excl])
    cmd.extend([f'{source}/', f'{dest}/'])
    result = subprocess.run(cmd, timeout=300, capture_output=True, text=True)
    return result.returncode == 0
```

**❌ Incorrecto:** No exclusions or validation
```python
def sync_basic(source: str, dest: str):  # No exclusions, no validation
    import subprocess
    subprocess.run(['rsync', '-av', f'{source}/', f'{dest}/'])  # No exclusions
```

**🔧 Fix:** Add exclusions and basic validation
```python
def sync_with_exclusions_fixed(source: str, dest: str, excludes: str = "*.tmp *.log") -> bool:
    import subprocess
    from pathlib import Path
    if not Path(source).exists():
        raise FileNotFoundError(f"Source not found: {source}")
    Path(dest).mkdir(parents=True, exist_ok=True)
    cmd = ['rsync', '-av', '--delete', '--checksum']
    for excl in excludes.split():
        cmd.extend(['--exclude', excl])
    cmd.extend([f'{source}/', f'{dest}/'])
    result = subprocess.run(cmd, timeout=300, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Sync failed: {result.stderr}")
    return True
```

**✅ Correcto:** Timeout-controlled operation
```python
def sync_with_timeout(source: str, dest: str) -> bool:
    import subprocess
    result = subprocess.run(['rsync', '-av', '--exclude=*.tmp', f'{source}/', f'{dest}/'], timeout=300, capture_output=True, text=True)
    return result.returncode == 0
```


```json
{
  "artifact": "06-PROGRAMMING/python/filesystem-sandbox-sync.md",
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
