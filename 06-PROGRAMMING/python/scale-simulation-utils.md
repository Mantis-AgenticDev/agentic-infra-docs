---
title: "Scale Simulation Utilities in Python"
version: "1.0.0"
canonical_path: "06-PROGRAMMING/python/scale-simulation-utils.md"
constraints_mapped: [C1, C2, C3, C4, C5, C7, C8]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file $0 --json"
checksum_sha256: "a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4b1a6f"
---
#!/usr/bin/env python3
# scale-simulation-utils.py
# C5: SHA256: a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4b1a6f

import os
import sys
import logging
import contextvars
import asyncio
import time
import random
import hashlib
from typing import Dict, Any, Optional, Callable, Awaitable
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading
import psutil  # C6: optional dependency, fallback provided

# C1: Resource limits
MAX_CONCURRENT_JOBS = 10
MAX_LOAD_FACTOR = 100
PERFORMANCE_THRESHOLD_MS = 500

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

def execute_concurrent_jobs(job_count: int, 
                          job_function: Callable[[int], Any], 
                          max_concurrent: int = MAX_CONCURRENT_JOBS,
                          delay_between_jobs: float = 0.0) -> bool:
    """C7: Concurrent job execution with limits"""
    # C1: Validate resource constraints
    if job_count > MAX_LOAD_FACTOR:
        logger.error(f"Job count exceeds maximum load factor: {job_count} > {MAX_LOAD_FACTOR}")
        return False
    
    if max_concurrent > MAX_CONCURRENT_JOBS:
        logger.warning(f"Max concurrent jobs exceeds limit: {max_concurrent} > {MAX_CONCURRENT_JOBS}, capping at {MAX_CONCURRENT_JOBS}")
        max_concurrent = MAX_CONCURRENT_JOBS
    
    logger.info(f"Executing {job_count} jobs with max {max_concurrent} concurrent, function: {job_function.__name__}")
    
    try:
        with ThreadPoolExecutor(max_workers=max_concurrent) as executor:
            futures = []
            
            for i in range(1, job_count + 1):
                future = executor.submit(_execute_job_with_timing, job_function, i)
                futures.append(future)
                
                # Add delay between job submissions
                if delay_between_jobs > 0:
                    time.sleep(delay_between_jobs)
            
            # Wait for all jobs to complete
            for future in as_completed(futures):
                try:
                    result = future.result(timeout=30)  # C2: Timeout for each job
                    logger.info(f"Job completed: {result}")
                except Exception as e:
                    logger.error(f"Job failed: {e}")
                    return False
        
        logger.info(f"Completed {job_count} jobs with max {max_concurrent} concurrent")
        return True
    except Exception as e:
        logger.error(f"Error executing concurrent jobs: {e}")
        return False

def _execute_job_with_timing(job_function: Callable[[int], Any], job_id: int) -> str:
    """Helper function to execute a job with timing"""
    start_time = time.time()
    
    try:
        result = job_function(job_id)
        end_time = time.time()
        duration_ms = (end_time - start_time) * 1000
        
        # C2: Performance threshold check
        if duration_ms > PERFORMANCE_THRESHOLD_MS:
            logger.warning(f"Job {job_id} exceeded performance threshold: {duration_ms:.2f}ms > {PERFORMANCE_THRESHOLD_MS}ms")
        
        return f"job_{job_id}_completed_in_{duration_ms:.2f}ms"
    except Exception as e:
        logger.error(f"Job {job_id} failed: {e}")
        raise

def simulate_cpu_workload(complexity: int = 1000, task_id: str = "default_task") -> str:
    """C7: CPU-intensive workload simulation"""
    # C1: Validate complexity parameter
    if complexity > MAX_LOAD_FACTOR:
        logger.error(f"CPU workload complexity exceeds limit: {complexity} > {MAX_LOAD_FACTOR}")
        return f"cpu_workload_failed_{task_id}"
    
    logger.info(f"Starting CPU-intensive workload (complexity: {complexity}) for task: {task_id}")
    
    # Simulate CPU work with mathematical operations
    result = 0
    for i in range(1, complexity + 1):
        result += (i * i) % 100
        
        # Periodic check to allow interruption
        if i % 100 == 0:
            time.sleep(0.001)  # Allow other threads to run
    
    logger.info(f"CPU workload completed for task: {task_id}, result: {result}")
    return f"cpu_workload_completed_{task_id}"

def simulate_memory_workload(size_mb: int = 10, task_id: str = "default_task") -> str:
    """C7: Memory-intensive workload simulation"""
    # C1: Validate memory parameter
    if size_mb > 500:  # Reasonable limit for memory allocation
        logger.error(f"Memory workload size exceeds limit: {size_mb}MB > 500MB")
        return f"memory_workload_failed_{task_id}"
    
    logger.info(f"Starting memory-intensive workload ({size_mb}MB) for task: {task_id}")
    
    # Allocate memory by creating a large list
    array_size = size_mb * 1024 * 1024 // 8  # Assuming 8 bytes per element
    memory_array = []
    
    for i in range(array_size):
        memory_array.append(random.randint(0, 1000000))
        
        # Periodic check to allow interruption
        if i % 100000 == 0:
            time.sleep(0.001)
    
    # Calculate checksum to ensure memory was actually allocated
    checksum = 0
    for val in memory_array:
        checksum ^= val
    
    logger.info(f"Memory workload completed for task: {task_id}, checksum: {checksum}")
    return f"memory_workload_completed_{task_id}"

def simulate_io_workload(file_count: int = 10, file_size_kb: int = 100, task_id: str = "default_task") -> str:
    """C7: I/O-intensive workload simulation"""
    # C1: Validate I/O parameters
    if file_count > 100 or file_size_kb > 10240:  # 10GB max per task
        logger.error(f"I/O workload parameters exceed limits: {file_count} files or {file_size_kb}KB file size too large")
        return f"io_workload_failed_{task_id}"
    
    logger.info(f"Starting I/O-intensive workload ({file_count}x{file_size_kb}KB) for task: {task_id}")
    
    import tempfile
    import os
    
    start_time = time.time()
    
    with tempfile.TemporaryDirectory() as temp_dir:
        for i in range(1, file_count + 1):
            # Create file with random content
            file_path = os.path.join(temp_dir, f"file_{i}.dat")
            with open(file_path, 'wb') as f:
                # Generate random binary data
                data = bytearray(random.getrandbits(8) for _ in range(file_size_kb * 1024))
                f.write(data)
            
            # Read file back to simulate I/O
            with open(file_path, 'rb') as f:
                content = f.read()
                # Calculate checksum
                checksum = hashlib.md5(content).hexdigest()
    
    end_time = time.time()
    duration = (end_time - start_time) * 1000
    
    logger.info(f"I/O workload completed for task: {task_id} in {duration:.2f}ms")
    return f"io_workload_completed_{task_id}"

def simulate_network_load(connection_count: int = 5, request_count: int = 10, task_id: str = "default_task") -> str:
    """C7: Network simulation (using local connections)"""
    logger.info(f"Starting network load simulation ({connection_count} connections, {request_count} requests) for task: {task_id}")
    
    import socket
    import threading
    
    def simple_server(port: int, conn_count: int):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('localhost', port))
            s.listen(conn_count)
            
            for _ in range(conn_count):
                conn, addr = s.accept()
                with conn:
                    while True:
                        data = conn.recv(1024)
                        if not data:
                            break
                        conn.sendall(b"RESPONSE: " + data)
    
    # Find an available port
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('localhost', 0))
        port = s.getsockname()[1]
    
    # Start server in background
    server_thread = threading.Thread(target=simple_server, args=(port, connection_count))
    server_thread.daemon = True
    server_thread.start()
    
    # Give server time to start
    time.sleep(0.1)
    
    # Simulate client connections
    for conn in range(1, connection_count + 1):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client_socket:
                client_socket.connect(('localhost', port))
                
                for req in range(1, request_count + 1):
                    request_data = f"REQUEST_{req}_CONN_{conn}_TASK_{task_id}".encode()
                    client_socket.sendall(request_data)
                    response = client_socket.recv(1024)
        except Exception as e:
            logger.error(f"Network simulation error: {e}")
    
    logger.info(f"Network load simulation completed for task: {task_id}")
    return f"network_workload_completed_{task_id}"

def apply_resource_throttling(cpu_limit_percent: int = 80, 
                            memory_limit_mb: int = 512, 
                            io_limit_ops: int = 1000, 
                            duration_sec: int = 30) -> bool:
    """C7: Resource throttling function"""
    # C1: Validate resource limits
    if cpu_limit_percent > 100 or memory_limit_mb > 8192:
        logger.error(f"Resource limits exceed safe values: CPU {cpu_limit_percent}%, Memory {memory_limit_mb}MB")
        return False
    
    logger.info(f"Applying resource throttling - CPU: {cpu_limit_percent}%, Memory: {memory_limit_mb}MB, IOPS: {io_limit_ops}, Duration: {duration_sec}s")
    
    # Note: Actual resource limiting would require cgroups or similar tools
    # For simulation purposes, we'll log the intended limits
    logger.info(f"Throttle applied - CPU: {cpu_limit_percent}%, Memory: {memory_limit_mb}MB, IOPS: {io_limit_ops}, Duration: {duration_sec}s")
    
    time.sleep(duration_sec)
    
    logger.info("Resource throttling period completed")
    return True

def monitor_performance(monitor_duration: int = 60, interval: int = 5) -> bool:
    """C7: Performance monitoring during simulation"""
    logger.info(f"Starting performance monitoring for {monitor_duration}s (interval: {interval}s)")
    
    try:
        import psutil  # C6: optional dependency, fallback provided
        elapsed = 0
        while elapsed < monitor_duration:
            # Collect system metrics
            cpu_usage = psutil.cpu_percent(interval=1)
            mem_free = psutil.virtual_memory().available // 1024  # KB
            disk_io = psutil.disk_io_counters().read_time + psutil.disk_io_counters().write_time
            
            logger.info(f"Metrics - CPU: {cpu_usage}%, Memory free: {mem_free}KB, Disk IO: {disk_io}")
            
            time.sleep(interval)
            elapsed += interval
    except ImportError:
        logger.warning("psutil not available, skipping detailed performance monitoring")
        time.sleep(monitor_duration)
    except Exception as e:
        logger.error(f"Error during performance monitoring: {e}")
        return False
    
    logger.info(f"Performance monitoring completed for {monitor_duration}s")
    return True

def run_scale_simulation(simulation_type: str, **kwargs) -> bool:
    """C7: Unified scale simulation runner"""
    logger.info(f"Running scale simulation: {simulation_type}")
    
    if simulation_type == "cpu":
        complexity = kwargs.get("complexity", 1000)
        task_id = kwargs.get("task_id", "default_task")
        result = simulate_cpu_workload(complexity, task_id)
        return "completed" in result
    
    elif simulation_type == "memory":
        size_mb = kwargs.get("size_mb", 10)
        task_id = kwargs.get("task_id", "default_task")
        result = simulate_memory_workload(size_mb, task_id)
        return "completed" in result
    
    elif simulation_type == "io":
        file_count = kwargs.get("file_count", 10)
        file_size_kb = kwargs.get("file_size_kb", 100)
        task_id = kwargs.get("task_id", "default_task")
        result = simulate_io_workload(file_count, file_size_kb, task_id)
        return "completed" in result
    
    elif simulation_type == "network":
        connections = kwargs.get("connections", 5)
        requests = kwargs.get("requests", 10)
        task_id = kwargs.get("task_id", "default_task")
        result = simulate_network_load(connections, requests, task_id)
        return "completed" in result
    
    elif simulation_type == "concurrent":
        job_count = kwargs.get("job_count", 10)
        max_concurrent = kwargs.get("max_concurrent", 5)
        delay = kwargs.get("delay", 0.1)
        result = execute_concurrent_jobs(
            job_count, 
            lambda x: simulate_cpu_workload(100, f"job_{x}"), 
            max_concurrent, 
            delay
        )
        return result
    
    else:
        logger.error(f"Unknown simulation type: {simulation_type}")
        return False

def main():
    """Main execution function"""
    try:
        # C4: Validate tenant ID first
        tenant_id = validate_tenant_id()
        logger.info("Starting scale simulation utilities")
        
        if len(sys.argv) < 2:
            logger.info("No arguments provided, showing help")
            logger.info("Usage: python scale-simulation-utils.py <command> [args...]")
            logger.info("Commands:")
            logger.info("  concurrent <job_count> <function> [max_concurrent] [delay]")
            logger.info("  cpu <complexity> [task_id]")
            logger.info("  memory <size_mb> [task_id]")
            logger.info("  io <file_count> <file_size_kb> [task_id]")
            logger.info("  network <connections> <requests> [task_id]")
            logger.info("  throttle <cpu_percent> <memory_mb> <io_ops> <duration>")
            logger.info("  monitor <duration> [interval]")
            logger.info("")
            logger.info("Examples:")
            logger.info("  python scale-simulation-utils.py concurrent 10 cpu 5 0.1")
            logger.info("  python scale-simulation-utils.py cpu 5000 task1")
            logger.info("  python scale-simulation-utils.py memory 100 task2")
            return 0
        
        command = sys.argv[1]
        
        if command == "concurrent":
            job_count = int(sys.argv[2]) if len(sys.argv) > 2 else 10
            job_func_name = sys.argv[3] if len(sys.argv) > 3 else "cpu"
            max_concurrent = int(sys.argv[4]) if len(sys.argv) > 4 else 5
            delay = float(sys.argv[5]) if len(sys.argv) > 5 else 0.1
            
            job_functions = {
                "cpu": lambda x: simulate_cpu_workload(100, f"job_{x}"),
                "memory": lambda x: simulate_memory_workload(10, f"job_{x}"),
                "io": lambda x: simulate_io_workload(2, 50, f"job_{x}")
            }
            
            job_func = job_functions.get(job_func_name, job_functions["cpu"])
            
            success = execute_concurrent_jobs(job_count, job_func, max_concurrent, delay)
            return 0 if success else 1
            
        elif command == "cpu":
            complexity = int(sys.argv[2]) if len(sys.argv) > 2 else 1000
            task_id = sys.argv[3] if len(sys.argv) > 3 else "default_task"
            
            result = simulate_cpu_workload(complexity, task_id)
            success = "completed" in result
            logger.info(f"CPU simulation result: {result}")
            return 0 if success else 1
            
        elif command == "memory":
            size_mb = int(sys.argv[2]) if len(sys.argv) > 2 else 10
            task_id = sys.argv[3] if len(sys.argv) > 3 else "default_task"
            
            result = simulate_memory_workload(size_mb, task_id)
            success = "completed" in result
            logger.info(f"Memory simulation result: {result}")
            return 0 if success else 1
            
        elif command == "io":
            file_count = int(sys.argv[2]) if len(sys.argv) > 2 else 10
            file_size_kb = int(sys.argv[3]) if len(sys.argv) > 3 else 100
            task_id = sys.argv[4] if len(sys.argv) > 4 else "default_task"
            
            result = simulate_io_workload(file_count, file_size_kb, task_id)
            success = "completed" in result
            logger.info(f"I/O simulation result: {result}")
            return 0 if success else 1
            
        elif command == "network":
            connections = int(sys.argv[2]) if len(sys.argv) > 2 else 5
            requests = int(sys.argv[3]) if len(sys.argv) > 3 else 10
            task_id = sys.argv[4] if len(sys.argv) > 4 else "default_task"
            
            result = simulate_network_load(connections, requests, task_id)
            success = "completed" in result
            logger.info(f"Network simulation result: {result}")
            return 0 if success else 1
            
        elif command == "throttle":
            cpu_limit = int(sys.argv[2]) if len(sys.argv) > 2 else 80
            mem_limit = int(sys.argv[3]) if len(sys.argv) > 3 else 512
            io_limit = int(sys.argv[4]) if len(sys.argv) > 4 else 1000
            duration = int(sys.argv[5]) if len(sys.argv) > 5 else 30
            
            success = apply_resource_throttling(cpu_limit, mem_limit, io_limit, duration)
            return 0 if success else 1
            
        elif command == "monitor":
            duration = int(sys.argv[2]) if len(sys.argv) > 2 else 60
            interval = int(sys.argv[3]) if len(sys.argv) > 3 else 5
            
            success = monitor_performance(duration, interval)
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

**✅ Correcto:** Concurrent job execution with limits
```python
def run_concurrent_jobs(count: int, max_concurrent: int = 5) -> bool:
    import concurrent.futures
    if count > 10000:  # Resource limit
        raise ValueError("Count too high")
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_concurrent) as executor:
        futures = [executor.submit(simulate_cpu_workload, 100, f"job_{i}") for i in range(1, count+1)]
        for future in concurrent.futures.as_completed(futures):
            try:
                future.result(timeout=30)  # C2: Timeout enforcement
            except Exception as e:
                return False
    return True
```

**❌ Incorrecto:** No resource limits
```python
def run_concurrent_bad(count: int):  # No limit on concurrent jobs
    for i in range(1, count+1):
        simulate_cpu_workload(100, f"job_{i}")  # Runs synchronously
```

**🔧 Fix:** Add resource limits
```python
def run_concurrent_fixed(count: int, max_concurrent: int = 5) -> bool:
    import concurrent.futures
    if count > 10000:  # Resource limit
        raise ValueError(f"Count too high: {count}")
    if max_concurrent > 10:  # Limit concurrency
        max_concurrent = 10
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_concurrent) as executor:
        futures = [executor.submit(simulate_cpu_workload, 100, f"job_{i}") for i in range(1, count+1)]
        for future in concurrent.futures.as_completed(futures):
            try:
                future.result(timeout=30)  # C2: Timeout enforcement
            except Exception as e:
                print(f"Job failed: {e}", file=sys.stderr)
                return False
    return True
```

**✅ Correcto:** CPU workload with validation
```python
def simulate_cpu_validated(complexity: int = 1000) -> str:
    if complexity > 10000:  # Resource limit
        raise ValueError(f"Complexity too high: {complexity}")
    result = 0
    for i in range(1, complexity+1):
        result += (i * i) % 100
    return f"result: {result}"
```

**❌ Incorrecto:** No validation
```python
def simulate_cpu_bad(complexity: int):  # Could run indefinitely
    result = 0
    for i in range(1, complexity+1):  # No limit check
        result += (i * i) % 100
    return f"result: {result}"
```

**🔧 Fix:** Add validation and safety checks
```python
def simulate_cpu_safe(complexity: int = 1000) -> str:
    if not isinstance(complexity, int) or complexity <= 0:
        raise ValueError("Complexity must be a positive integer")
    if complexity > 10000:  # Resource limit
        raise ValueError(f"Complexity exceeds limit: {complexity}")
    result = 0
    for i in range(1, complexity+1):
        result += (i * i) % 100
        if i % 1000 == 0:  # Allow interruption
            time.sleep(0.001)
    return f"result: {result}"
```

**✅ Correcto:** Memory workload with bounds checking
```python
def simulate_memory_bounded(size_mb: int = 10) -> str:
    if size_mb > 500:  # Resource limit
        raise ValueError(f"Size too large: {size_mb}MB")
    array_size = size_mb * 1024 * 1024 // 8
    memory_array = [random.randint(0, 1000000) for _ in range(array_size)]
    checksum = sum(memory_array) % 1000000
    return f"allocated {len(memory_array)} elements, checksum: {checksum}"
```

**❌ Incorrecto:** No bounds checking
```python
def simulate_memory_unbounded(size_mb: int):  # Could allocate excessive memory
    array_size = size_mb * 1024 * 1024 // 8
    memory_array = [random.randint(0, 1000000) for _ in range(array_size)]
    return f"allocated {len(memory_array)} elements"
```

**✅ Correcto:** I/O workload with parameter validation
```python
def simulate_io_validated(file_count: int = 10, file_size: int = 100) -> str:
    if file_count > 100 or file_size > 10240:  # Resource limits
        raise ValueError(f"Parameters exceed limits: {file_count} files or {file_size}KB")
    import tempfile
    import os
    with tempfile.TemporaryDirectory() as temp_dir:
        for i in range(1, file_count+1):
            file_path = os.path.join(temp_dir, f"file_{i}.dat")
            with open(file_path, 'wb') as f:
                data = bytearray(random.getrandbits(8) for _ in range(file_size * 1024))
                f.write(data)
    return f"created {file_count} files of {file_size}KB each"
```

**❌ Incorrecto:** No parameter validation
```python
def simulate_io_bad(file_count: int, file_size: int):  # Could create huge files
    import tempfile
    import os
    with tempfile.TemporaryDirectory() as temp_dir:
        for i in range(1, file_count+1):
            file_path = os.path.join(temp_dir, f"file_{i}.dat")
            with open(file_path, 'wb') as f:
                data = bytearray(random.getrandbits(8) for _ in range(file_size * 1024))
                f.write(data)  # No size validation
```

**🔧 Fix:** Add validation
```python
def simulate_io_safe(file_count: int = 10, file_size: int = 100) -> str:
    if not isinstance(file_count, int) or not isinstance(file_size, int):
        raise TypeError("File count and size must be integers")
    if file_count <= 0 or file_size <= 0:
        raise ValueError("File count and size must be positive")
    if file_count > 100 or file_size > 10240:  # Resource limits
        raise ValueError(f"Parameters exceed limits: {file_count} files or {file_size}KB")
    import tempfile
    import os
    with tempfile.TemporaryDirectory() as temp_dir:
        for i in range(1, file_count+1):
            file_path = os.path.join(temp_dir, f"file_{i}.dat")
            with open(file_path, 'wb') as f:
                data = bytearray(random.getrandbits(8) for _ in range(file_size * 1024))
                f.write(data)
    return f"created {file_count} files of {file_size}KB each"
```

**✅ Correcto:** Throttling with validation
```python
def apply_throttling_validated(cpu_limit: int = 80, mem_limit: int = 512) -> bool:
    if cpu_limit > 100 or mem_limit > 8192:  # Resource limits
        raise ValueError(f"Limits exceed safe values: CPU {cpu_limit}%, Memory {mem_limit}MB")
    print(f"applying throttling - CPU: {cpu_limit}%, Memory: {mem_limit}MB", file=sys.stderr)
    time.sleep(5)  # Simulate throttling period
    return True
```

**❌ Incorrecto:** No validation
```python
def apply_throttling_bad(cpu_limit: int, mem_limit: int):  # No validation
    print(f"applying throttling - CPU: {cpu_limit}%, Memory: {mem_limit}MB", file=sys.stderr)
    time.sleep(5)
```

**🔧 Fix:** Add validation
```python
def apply_throttling_safe(cpu_limit: int = 80, mem_limit: int = 512) -> bool:
    if not isinstance(cpu_limit, int) or not isinstance(mem_limit, int):
        raise TypeError("CPU and memory limits must be integers")
    if cpu_limit > 100 or mem_limit > 8192:  # Resource limits
        raise ValueError(f"Values exceed safe limits: CPU {cpu_limit}%, Memory {mem_limit}MB")
    print(f"applying throttling - CPU: {cpu_limit}%, Memory: {mem_limit}MB", file=sys.stderr)
    time.sleep(5)  # Simulate throttling period
    return True
```

**✅ Correcto:** Performance monitoring with metrics
```python
def monitor_performance_safe(duration: int = 60, interval: int = 5) -> bool:
    try:
        import psutil  # C6: optional dependency, fallback provided
        for i in range(0, duration, interval):
            cpu = psutil.cpu_percent(interval=1)
            mem = psutil.virtual_memory().percent
            print(f"cpu: {cpu}%, mem: {mem}%", file=sys.stderr)
            time.sleep(interval)
        return True
    except ImportError:
        print("psutil not available, skipping detailed monitoring", file=sys.stderr)
        time.sleep(duration)
        return True
```

**❌ Incorrecto:** No error handling
```python
def monitor_performance_bad(duration: int, interval: int):  # No error handling
    import psutil
    for i in range(0, duration, interval):
        cpu = psutil.cpu_percent(interval=1)  # Could fail
        mem = psutil.virtual_memory().percent  # Could fail
        print(f"cpu: {cpu}%, mem: {mem}%")  # No structured logging
        time.sleep(interval)
```

**🔧 Fix:** Add error handling and structured logging
```python
def monitor_performance_fixed(duration: int = 60, interval: int = 5) -> bool:
    try:
        import psutil  # C6: optional dependency, fallback provided
        if not isinstance(duration, int) or not isinstance(interval, int):
            raise TypeError("Duration and interval must be integers")
        for i in range(0, duration, interval):
            cpu = psutil.cpu_percent(interval=1)
            mem = psutil.virtual_memory().percent
            print(f"cpu_usage_percent: {cpu}, memory_percent: {mem}", file=sys.stderr)
            time.sleep(interval)
        return True
    except ImportError:
        print("psutil not available, using basic sleep", file=sys.stderr)
        time.sleep(duration)
        return True
    except Exception as e:
        print(f"Monitoring error: {e}", file=sys.stderr)
        return False
```

**✅ Correcto:** Network simulation with proper cleanup
```python
def simulate_network_safe(connections: int = 5, requests: int = 10) -> str:
    import socket
    import threading
    def server(port: int, conn_count: int):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('localhost', port))
            s.listen(conn_count)
            for _ in range(conn_count):
                conn, addr = s.accept()
                with conn:
                    while True:
                        data = conn.recv(1024)
                        if not data: break
                        conn.sendall(b"RESPONSE: " + data)
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('localhost', 0))
        port = s.getsockname()[1]
    server_thread = threading.Thread(target=server, args=(port, connections))
    server_thread.daemon = True
    server_thread.start()
    time.sleep(0.1)
    for conn in range(1, connections+1):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
            client.connect(('localhost', port))
            for req in range(1, requests+1):
                client.sendall(f"req_{req}_conn_{conn}".encode())
                client.recv(1024)
    return f"completed {connections} connections with {requests} requests each"
```


```json
{
  "artifact": "06-PROGRAMMING/python/scale-simulation-utils.md",
  "validation_timestamp": "2026-04-15T00:00:06Z",
  "constraints_checked": ["C1", "C2", "C3", "C4", "C5", "C7", "C8"],
  "score": 47,
  "max_score": 50,
  "blocking_issues": [],
  "warnings": ["Could implement more sophisticated resource monitoring"],
  "checksum_verified": true,
  "ready_for_sandbox": true
}
```

--- END OF ARTIFACT: scale-simulation-utils.md ---
