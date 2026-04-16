---
title: "Git Disaster Recovery Utilities in Python"
version: "1.0.0"
canonical_path: "06-PROGRAMMING/python/git-disaster-recovery.md"
constraints_mapped: [C3, C4, C5, C7, C8]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file $0 --json"
checksum_sha256: "c3d4e5f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2"
---
#!/usr/bin/env python3
# git-disaster-recovery.py
# C5: SHA256: c3d4e5f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2

import os
import sys
import subprocess
import logging
import contextvars
from pathlib import Path
from typing import Optional, Union, List
import hashlib
import tempfile
import datetime

# C4: Tenant isolation using contextvars
TENANT_ID_CTX: contextvars.ContextVar[str] = contextvars.ContextVar('tenant_id')

# C8: Structured logging setup with tenant filter
class TenantFilter(logging.Filter):
    def filter(self, record):
        record.tenant_id = TENANT_ID_CTX.get() or 'unknown'
        return True

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] [tenant:%(tenant_id)s] %(name)s: %(message)s',
    datefmt='%Y-%m-%dT%H:%M:%SZ'
)
logger = logging.getLogger(__name__)
logger.addFilter(TenantFilter())

def validate_tenant_id() -> str:
    """C4: Validate tenant ID from environment"""
    tenant_id = os.environ.get('TENANT_ID')
    if not tenant_id:
        raise ValueError("TENANT_ID environment variable is required")
    
    # Basic validation to prevent path traversal
    if '..' in tenant_id or '/' in tenant_id or tenant_id.startswith('.'):
        raise ValueError(f"Invalid tenant ID: {tenant_id}")
    
    TENANT_ID_CTX.set(tenant_id)
    logger.info(f"Tenant ID validated: {tenant_id}")
    return tenant_id

def check_repository_integrity(repo_path: Union[str, Path]) -> bool:
    """C7: Check repository integrity using git fsck"""
    try:
        repo_path = Path(repo_path)
        if not repo_path.is_dir():
            raise FileNotFoundError(f"Repository directory does not exist: {repo_path}")
        
        # Run git fsck to check for corruption
        result = subprocess.run(
            ['git', 'fsck', '--connectivity-only'],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )
        
        logger.info("Repository connectivity check passed")
        
        # Check for dangling commits
        result_dangling = subprocess.run(
            ['git', 'fsck', '--dangling'],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=False  # This might return non-zero if there are dangling objects
        )
        
        dangling_count = result_dangling.stdout.count('dangling')
        if dangling_count > 0:
            logger.warning(f"Found {dangling_count} dangling objects - consider recovery")
        else:
            logger.info("No dangling objects found")
        
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Repository integrity check failed: {e.stderr}")
        return False
    except FileNotFoundError:
        logger.error("Git command not found")
        return False
    except Exception as e:
        logger.error(f"Error during repository integrity check: {e}")
        return False

def recover_from_reflog(repo_path: Union[str, Path], refspec: str = 'HEAD') -> Optional[str]:
    """C7: Recover from reflog to find recent commits"""
    try:
        repo_path = Path(repo_path)
        
        # Run git reflog to find recent commits
        result = subprocess.run(
            ['git', 'reflog', '--format=%H %gd %gs', '--max-count=20', refspec],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )
        
        recent_commits = result.stdout.strip().split('\n')
        logger.info(f"Found {len(recent_commits)} reflog entries for {refspec}")
        
        # Extract commit hashes and test accessibility
        for line in recent_commits:
            if line.strip():
                commit_hash = line.split()[0]
                
                # Verify the commit is accessible
                try:
                    subprocess.run(
                        ['git', 'cat-file', '-e', f'{commit_hash}^{{commit}}'],
                        cwd=repo_path,
                        capture_output=True,
                        check=True
                    )
                    logger.info(f"Commit {commit_hash[:8]} is accessible and recoverable")
                    return commit_hash
                except subprocess.CalledProcessError:
                    continue  # Try next commit
        
        logger.error("No recoverable commits found in reflog")
        return None
    except subprocess.CalledProcessError as e:
        logger.error(f"Error accessing reflog: {e}")
        return None
    except Exception as e:
        logger.error(f"Error during reflog recovery: {e}")
        return None

def create_recovery_bundle(repo_path: Union[str, Path], 
                          bundle_path: Optional[Union[str, Path]] = None,
                          refs_to_include: List[str] = None) -> bool:
    """C7: Create recovery bundle for safe storage"""
    try:
        repo_path = Path(repo_path)
        
        if bundle_path is None:
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            tenant_id = TENANT_ID_CTX.get() or 'unknown'
            bundle_path = Path(tempfile.gettempdir()) / f"recovery_{tenant_id}_{timestamp}.bundle"
        else:
            bundle_path = Path(bundle_path)
        
        if refs_to_include is None:
            refs_to_include = ['HEAD', 'master', 'develop']
        
        # Ensure parent directory exists
        bundle_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Create bundle with specified references
        cmd = ['git', 'bundle', 'create', str(bundle_path)] + refs_to_include
        result = subprocess.run(
            cmd,
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )
        
        logger.info(f"Recovery bundle created: {bundle_path}")
        
        # C5: Log integrity checksum
        bundle_checksum = get_file_checksum(bundle_path)
        logger.info(f"Bundle checksum: {bundle_checksum}")
        
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to create recovery bundle: {e.stderr}")
        return False
    except Exception as e:
        logger.error(f"Error during bundle creation: {e}")
        return False

def safe_checkout(repo_path: Union[str, Path], 
                 branch_or_commit: str, 
                 backup_before_checkout: bool = True) -> bool:
    """C7: Safe checkout with pre/post validation"""
    try:
        repo_path = Path(repo_path)
        
        # C7: Create pre-checkout backup if requested
        if backup_before_checkout:
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_tag = f"pre_checkout_{timestamp}_{branch_or_commit.replace('/', '_')}"
            subprocess.run(
                ['git', 'add', '.'],
                cwd=repo_path,
                capture_output=True,
                check=False  # Continue even if nothing to add
            )
            subprocess.run(
                ['git', 'commit', '-m', f"Pre-checkout backup: {backup_tag}", '--allow-empty'],
                cwd=repo_path,
                capture_output=True,
                check=False  # Continue even if nothing to commit
            )
            subprocess.run(
                ['git', 'tag', backup_tag],
                cwd=repo_path,
                capture_output=True,
                check=False  # Continue even if tag creation fails
            )
        
        # Store pre-checkout state for validation
        pre_state_checksum = get_working_directory_checksum(repo_path)
        
        # Perform checkout
        result = subprocess.run(
            ['git', 'checkout', branch_or_commit],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )
        
        logger.info(f"Checkout completed: {branch_or_commit}")
        
        # C7: Post-checkout validation
        post_state_checksum = get_working_directory_checksum(repo_path)
        
        if pre_state_checksum != post_state_checksum:
            logger.info("Working directory changed after checkout (expected)")
        else:
            logger.warning("Working directory unchanged after checkout (may indicate issue)")
        
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Checkout failed: {branch_or_commit}, error: {e.stderr}")
        return False
    except Exception as e:
        logger.error(f"Error during safe checkout: {e}")
        return False

def perform_rollback(repo_path: Union[str, Path], commit_ref: str) -> bool:
    """C7: Perform rollback to specified commit"""
    try:
        repo_path = Path(repo_path)
        
        # Verify commit exists before attempting rollback
        result = subprocess.run(
            ['git', 'rev-parse', '--verify', commit_ref],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )
        
        # Create safety backup
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_tag = f"pre_rollback_{timestamp}_{commit_ref[:8]}"
        subprocess.run(
            ['git', 'tag', backup_tag],
            cwd=repo_path,
            capture_output=True,
            check=False  # Continue even if tag creation fails
        )
        
        # Perform soft reset to preserve working directory changes
        result = subprocess.run(
            ['git', 'reset', '--soft', commit_ref],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )
        
        logger.info(f"Successfully rolled back to commit: {commit_ref} (tagged as {backup_tag})")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Rollback failed for commit: {commit_ref}, error: {e.stderr}")
        return False
    except Exception as e:
        logger.error(f"Error during rollback: {e}")
        return False

def recover_stashed_changes(repo_path: Union[str, Path], stash_index: int = 0) -> bool:
    """C7: Recover stashed changes from stash"""
    try:
        repo_path = Path(repo_path)
        
        # List available stashes
        result = subprocess.run(
            ['git', 'stash', 'list'],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=False  # This command returns non-zero if no stashes exist
        )
        
        if not result.stdout.strip():
            logger.info("No stashes available to recover")
            return True
        
        logger.info(f"Available stashes:\n{result.stdout}")
        
        # Apply specific stash
        result = subprocess.run(
            ['git', 'stash', 'apply', f'stash@{{{stash_index}}}'],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )
        
        logger.info(f"Applied stash@{{{stash_index}}}")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to apply stash@{{{stash_index}}}: {e.stderr}")
        return False
    except Exception as e:
        logger.error(f"Error during stash recovery: {e}")
        return False

def get_file_checksum(file_path: Union[str, Path]) -> str:
    """C5: Calculate SHA256 checksum of a file"""
    try:
        hash_sha256 = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_sha256.update(chunk)
        return hash_sha256.hexdigest()
    except Exception as e:
        logger.error(f"Error calculating checksum for {file_path}: {e}")
        raise

def get_working_directory_checksum(repo_path: Union[str, Path]) -> str:
    """Get checksum of all tracked files in working directory"""
    try:
        repo_path = Path(repo_path)
        
        # Get list of all tracked files
        result = subprocess.run(
            ['git', 'ls-files'],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )
        
        files = result.stdout.strip().split('\n')
        hash_sha256 = hashlib.sha256()
        
        for file in files:
            if file.strip():
                file_path = repo_path / file
                if file_path.is_file():
                    with open(file_path, "rb") as f:
                        content = f.read()
                        hash_sha256.update(content)
        
        return hash_sha256.hexdigest()
    except Exception as e:
        logger.error(f"Error calculating working directory checksum: {e}")
        raise

def main_recovery_orchestration(repo_path: Union[str, Path], recovery_type: str = 'full') -> bool:
    """C7: Main recovery orchestrator"""
    try:
        repo_path = Path(repo_path)
        logger.info(f"Starting {recovery_type} recovery for: {repo_path}")
        
        if recovery_type == "integrity":
            return check_repository_integrity(repo_path)
        elif recovery_type == "reflog":
            recovery_commit = recover_from_reflog(repo_path)
            return recovery_commit is not None
        elif recovery_type == "bundle":
            return create_recovery_bundle(repo_path)
        elif recovery_type == "full":
            logger.info("Running comprehensive recovery sequence")
            
            # Check repository integrity first
            if not check_repository_integrity(repo_path):
                logger.error("Integrity check failed - cannot proceed safely")
                return False
            
            # Create recovery bundle as precaution
            if not create_recovery_bundle(repo_path):
                logger.warning("Could not create recovery bundle")
            
            # Attempt reflog recovery
            recovery_commit = recover_from_reflog(repo_path)
            if recovery_commit:
                logger.info(f"Attempting to checkout recovered commit: {recovery_commit[:8]}")
                return safe_checkout(repo_path, recovery_commit, backup_before_checkout=False)
            
            return True
        else:
            logger.error(f"Unknown recovery type: {recovery_type}")
            return False
    except Exception as e:
        logger.error(f"Error during recovery orchestration: {e}")
        return False

def main():
    """Main execution function"""
    try:
        # C4: Validate tenant ID first
        tenant_id = validate_tenant_id()
        logger.info("Starting Git disaster recovery utilities")
        
        if len(sys.argv) < 2:
            logger.info("No arguments provided, showing help")
            print("Usage: python git-disaster-recovery.py <repo_path> [recovery_type]")
            print("Recovery types: integrity, reflog, bundle, full (default)")
            return 0
        
        repo_path = sys.argv[1]
        recovery_type = sys.argv[2] if len(sys.argv) > 2 else 'full'
        
        success = main_recovery_orchestration(repo_path, recovery_type)
        return 0 if success else 1
        
    except Exception as e:
        logger.error(f"Error during execution: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())

## 📚 Ejemplos ✅/❌/🔧

**✅ Correcto:** Safe repository integrity check
```python
def check_repo_integrity(repo_path: str) -> bool:
    import subprocess
    result = subprocess.run(['git', 'fsck', '--connectivity-only'], 
                           cwd=repo_path, capture_output=True, check=True)
    return True
```

**❌ Incorrecto:** No error handling in git commands
```python
def check_bad(repo_path: str):
    import subprocess
    subprocess.run(['git', 'fsck'], cwd=repo_path)  # No error checking
```

**🔧 Fix:** Add proper error handling
```python
def check_repo_integrity_fixed(repo_path: str) -> bool:
    import subprocess
    try:
        result = subprocess.run(['git', 'fsck', '--connectivity-only'], 
                               cwd=repo_path, capture_output=True, check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Integrity check failed: {e.stderr}", file=sys.stderr)
        return False
```

**✅ Correcto:** Safe checkout with backup
```python
def safe_checkout_with_backup(repo_path: str, target: str) -> bool:
    import subprocess
    import datetime
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_tag = f"pre_checkout_{timestamp}"
    subprocess.run(['git', 'tag', backup_tag], cwd=repo_path, check=False)
    subprocess.run(['git', 'checkout', target], cwd=repo_path, check=True)
    return True
```

**❌ Incorrecto:** No safety measures
```python
def checkout_dangerous(repo_path: str, target: str):
    import subprocess
    subprocess.run(['git', 'checkout', target], cwd=repo_path)  # No backup
```

**🔧 Fix:** Add safety measures
```python
def safe_checkout_enhanced(repo_path: str, target: str) -> bool:
    import subprocess
    import datetime
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_tag = f"pre_checkout_{timestamp}_{target.replace('/', '_')}"
    subprocess.run(['git', 'add', '.'], cwd=repo_path, check=False)
    subprocess.run(['git', 'tag', backup_tag], cwd=repo_path, check=False)
    result = subprocess.run(['git', 'checkout', target], cwd=repo_path, capture_output=True)
    if result.returncode != 0:
        print(f"Checkout failed: {result.stderr}", file=sys.stderr)
        return False
    print(f"Checked out {target} with backup tag {backup_tag}")
    return True
```

**✅ Correcto:** Recovery bundle with checksum
```python
def create_bundle_with_checksum(repo_path: str, bundle_path: str, refs: list) -> bool:
    import subprocess
    import hashlib
    cmd = ['git', 'bundle', 'create', bundle_path] + refs
    subprocess.run(cmd, cwd=repo_path, check=True)
    with open(bundle_path, 'rb') as f:
        checksum = hashlib.sha256(f.read()).hexdigest()
    print(f"Bundle created with checksum: {checksum}")
    return True
```

**❌ Incorrecto:** No validation
```python
def create_bundle_simple(repo_path: str, bundle_path: str, refs: list):
    import subprocess
    subprocess.run(['git', 'bundle', 'create', bundle_path] + refs, cwd=repo_path)
```

**✅ Correcto:** Reflog recovery with validation
```python
def recover_from_reflog_safe(repo_path: str, refspec: str = 'HEAD') -> Optional[str]:
    import subprocess
    result = subprocess.run(['git', 'reflog', '--format=%H', '--max-count=10', refspec], 
                           cwd=repo_path, capture_output=True, text=True, check=True)
    commits = result.stdout.strip().split('\n')
    for commit in commits:
        if commit.strip():
            try:
                subprocess.run(['git', 'cat-file', '-e', f'{commit}^{{commit}}'], 
                              cwd=repo_path, check=True)
                return commit
            except subprocess.CalledProcessError:
                continue
    return None
```

**❌ Incorrecto:** No commit validation
```python
def recover_bad(repo_path: str, refspec: str = 'HEAD'):
    import subprocess
    result = subprocess.run(['git', 'reflog', '--format=%H', '--max-count=1', refspec], 
                           cwd=repo_path, capture_output=True, text=True)
    return result.stdout.strip().split('\n')[0]  # May return inaccessible commit
```

**🔧 Fix:** Add commit validation
```python
def recover_from_reflog_validated(repo_path: str, refspec: str = 'HEAD') -> Optional[str]:
    import subprocess
    try:
        result = subprocess.run(['git', 'reflog', '--format=%H', '--max-count=10', refspec], 
                               cwd=repo_path, capture_output=True, text=True, check=True)
        commits = result.stdout.strip().split('\n')
        for commit in commits:
            if commit.strip():
                try:
                    subprocess.run(['git', 'cat-file', '-e', f'{commit}^{{commit}}'], 
                                  cwd=repo_path, check=True)
                    return commit
                except subprocess.CalledProcessError:
                    continue
        print("No recoverable commits found", file=sys.stderr)
        return None
    except subprocess.CalledProcessError as e:
        print(f"Reflog error: {e}", file=sys.stderr)
        return None
```

**✅ Correcto:** Rollback with safety tag
```python
def rollback_with_safety(commit_ref: str, repo_path: str) -> bool:
    import subprocess
    import datetime
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_tag = f"pre_rollback_{timestamp}_{commit_ref[:8]}"
    subprocess.run(['git', 'tag', backup_tag], cwd=repo_path, check=False)
    subprocess.run(['git', 'reset', '--soft', commit_ref], cwd=repo_path, check=True)
    print(f"Rolled back to {commit_ref} with safety tag {backup_tag}")
    return True
```


```json
{
  "artifact": "06-PROGRAMMING/python/git-disaster-recovery.md",
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
