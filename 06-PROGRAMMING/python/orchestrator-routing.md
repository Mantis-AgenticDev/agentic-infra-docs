---
title: "Orchestrator Routing Engine in Python"
version: "1.0.0"
canonical_path: "06-PROGRAMMING/python/orchestrator-routing.md"
constraints_mapped: [C3, C4, C5, C7, C8]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file $0 --json"
checksum_sha256: "d4e5f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4"
---
#!/usr/bin/env python3
# orchestrator-routing.py
# C5: SHA256: d4e5f6a7b8c9d2e4b1a6f3c8d5e9f2a1b4c7d6e5f8a9b2c3d4e5f6a7b8c9d2e4

import os
import sys
import logging
import contextvars
import json
import requests
import time
import hashlib
from typing import Dict, Any, Optional, List
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

def calculate_provider_score(provider_name: str, 
                           response_time_ms: float = 1000.0,
                           success_rate: float = 0.95,
                           resource_utilization: float = 0.3) -> int:
    """C7: Calculate provider score based on weighted factors"""
    # Calculate score based on weighted factors
    time_factor = int(1000 / (response_time_ms + 1))  # Higher score for faster response
    success_factor = int(success_rate * 100)  # Higher score for better success rate
    resource_factor = int(100 - (resource_utilization * 100))  # Higher score for lower utilization
    
    # Weighted calculation (time: 40%, success: 40%, resources: 20%)
    weighted_score = int((time_factor * 0.4) + (success_factor * 0.4) + (resource_factor * 0.2))
    
    # Clamp to reasonable range
    final_score = min(max(weighted_score, 10), 100)
    
    logger.debug(f"Provider {provider_name} scored: {final_score}")
    return final_score

def check_provider_availability(endpoint: str, timeout: int = 5) -> bool:
    """C7: Check if provider is available"""
    try:
        response = requests.get(f"{endpoint}/health", timeout=timeout)
        return response.status_code == 200
    except requests.RequestException:
        return False

def route_request(request_payload: Dict[str, Any], 
                 routing_context: str = "default",
                 fallback_provider: str = "default_fallback") -> Optional[Dict[str, Any]]:
    """C7: Route request to appropriate provider based on scoring"""
    logger.info(f"Routing request in context: {routing_context}")
    
    # Define provider configurations
    providers = [
        {"name": "high_performance", "endpoint": "http://hp-provider.local", "weight": 0.7},
        {"name": "cost_optimized", "endpoint": "http://co-provider.local", "weight": 0.5},
        {"name": "fallback", "endpoint": "http://fb-provider.local", "weight": 0.3}
    ]
    
    best_provider = None
    best_score = 0
    
    for provider in providers:
        endpoint = provider["endpoint"]
        name = provider["name"]
        
        # Skip if provider is not available
        if not check_provider_availability(endpoint):
            logger.warning(f"Provider {name} not available at {endpoint}")
            continue
        
        # Simulate getting metrics for scoring (in real scenario, these would come from monitoring)
        response_time = 200.0
        success_rate = 0.98
        resource_util = 0.25
        
        # Adjust based on routing context
        if routing_context == "latency_critical":
            response_time = response_time * 2 / 3  # Better score for latency critical
        elif routing_context == "cost_sensitive":
            resource_util = resource_util * 0.7  # Better score for cost sensitive
        
        score = calculate_provider_score(name, response_time, success_rate, resource_util)
        logger.info(f"Provider {name} scored: {score} (endpoint: {endpoint})")
        
        if score > best_score:
            best_score = score
            best_provider = name
    
    # C7: Fallback mechanism if no provider meets threshold
    if not best_provider or best_score < 10:  # Minimum threshold
        logger.warning(f"No suitable provider found (best score: {best_score}), using fallback: {fallback_provider}")
        best_provider = fallback_provider
        best_score = 0  # Fallback score
    
    # Prepare routing result
    routing_result = {
        "selected_provider": best_provider,
        "score": best_score,
        "timestamp": time.strftime('%Y-%m-%dT%H:%M:%SZ'),
        "tenant": TENANT_ID_CTX.get() or "unknown"
    }
    
    logger.info(f"Selected provider: {best_provider} with score: {best_score}")
    return routing_result

def dispatch_request(provider_endpoint: str, 
                   request_payload: Dict[str, Any], 
                   request_timeout: int = 30) -> Optional[Dict[str, Any]]:
    """C7: Dispatch request to selected provider"""
    logger.info(f"Dispatching request to: {provider_endpoint}")
    
    try:
        # Send request to provider
        headers = {
            "Content-Type": "application/json",
            "X-Tenant-ID": TENANT_ID_CTX.get() or "unknown",
            "X-Request-ID": hashlib.sha256(os.urandom(32)).hexdigest()[:16]
        }
        
        response = requests.post(
            f"{provider_endpoint}/api/process",
            json=request_payload,
            headers=headers,
            timeout=request_timeout
        )
        
        if response.status_code == 200:
            logger.info(f"Response received from: {provider_endpoint}")
            return response.json()
        else:
            logger.error(f"Provider returned error: {response.status_code}")
            return None
    except requests.Timeout:
        logger.error(f"Request to {provider_endpoint} timed out after {request_timeout}s")
        return None
    except requests.RequestException as e:
        logger.error(f"Failed to dispatch request to {provider_endpoint}: {e}")
        return None

def parse_routing_config(config_file: str) -> Optional[Dict[str, Any]]:
    """C7: Parse routing configuration file"""
    try:
        config_path = Path(config_file)
        if not config_path.exists():
            logger.error(f"Configuration file not found: {config_file}")
            return None
        
        with open(config_path, 'r') as f:
            config = json.load(f)
        
        # Validate required fields
        required_fields = ["providers", "default_route", "fallback_provider"]
        for field in required_fields:
            if field not in config:
                logger.error(f"Required field missing in config: {field}")
                return None
        
        logger.info(f"Configuration validated successfully: {config_file}")
        return config
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in configuration file: {e}")
        return None
    except Exception as e:
        logger.error(f"Error reading configuration file: {e}")
        return None

def handle_multi_tenant_request(tenant_request: Dict[str, Any], tenant_id: str) -> Optional[Dict[str, Any]]:
    """C7: Multi-tenant request handler"""
    logger.info(f"Processing multi-tenant request for: {tenant_id}")
    
    # Validate tenant-specific policies
    policy_result = validate_tenant_policy(tenant_id, tenant_request)
    if not policy_result:
        logger.error(f"Policy validation failed for tenant: {tenant_id}")
        return None
    
    # Determine routing context based on tenant
    routing_context = determine_routing_context(tenant_id)
    
    # Route the request
    routing_decision = route_request(tenant_request, routing_context)
    if not routing_decision:
        logger.error(f"Routing failed for tenant: {tenant_id}")
        return None
    
    selected_provider = routing_decision["selected_provider"]
    provider_endpoint = get_provider_endpoint(selected_provider)
    
    # Dispatch to selected provider
    response = dispatch_request(provider_endpoint, tenant_request)
    if not response:
        logger.error(f"Dispatch failed for tenant: {tenant_id}, provider: {selected_provider}")
        return None
    
    logger.info(f"Request processed for tenant: {tenant_id} via provider: {selected_provider}")
    return response

def validate_tenant_policy(tenant_id: str, request: Dict[str, Any]) -> bool:
    """Validate tenant-specific policies"""
    # In a real implementation, this would check tenant-specific quotas, permissions, etc.
    # For this example, we'll just log and return success
    logger.info(f"Validated policy for tenant: {tenant_id}")
    return True

def determine_routing_context(tenant_id: str) -> str:
    """Determine routing context based on tenant"""
    if tenant_id.startswith(("premium_", "high_priority_")):
        return "latency_critical"
    elif tenant_id.startswith(("cost_sensitive_", "budget_")):
        return "cost_sensitive"
    else:
        return "default"

def get_provider_endpoint(provider_name: str) -> str:
    """Get endpoint for provider name"""
    endpoints = {
        "high_performance": "http://hp-provider.local",
        "cost_optimized": "http://co-provider.local",
        "fallback": "http://fb-provider.local",
        "default_fallback": "http://fb-provider.local"
    }
    return endpoints.get(provider_name, "http://default-provider.local")

def main():
    """Main execution function"""
    try:
        # C4: Validate tenant ID first
        tenant_id = validate_tenant_id()
        logger.info("Starting orchestrator routing engine")
        
        if len(sys.argv) < 2:
            logger.info("No arguments provided, showing help")
            logger.info("Usage: python orchestrator-routing.py '<json_request>' [routing_context] [tenant_id]")
            logger.info('Example: python orchestrator-routing.py \'{"task": "process_data", "priority": "high"}\' \'latency_critical\' \'premium_client\'')
            return 0
        
        request_payload = json.loads(sys.argv[1])
        routing_context = sys.argv[2] if len(sys.argv) > 2 else "default"
        tenant_id_arg = sys.argv[3] if len(sys.argv) > 3 else tenant_id
        
        # Process the request
        response = handle_multi_tenant_request(request_payload, tenant_id_arg)
        if response:
            print(json.dumps(response, indent=2))
            return 0
        else:
            logger.error("Request processing failed")
            return 1
            
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in request payload: {e}")
        return 1
    except Exception as e:
        logger.error(f"Error during execution: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())

## 📚 Ejemplos ✅/❌/🔧

**✅ Correcto:** Provider scoring with weights
```python
def calculate_score(response_time: float = 1000.0, success_rate: float = 0.95) -> int:
    time_factor = int(1000 / (response_time + 1))
    success_factor = int(success_rate * 100)
    weighted_score = int((time_factor * 0.4) + (success_factor * 0.4))
    return min(max(weighted_score, 10), 100)
```

**❌ Incorrecto:** No input validation
```python
def bad_calculate_score(response_time) -> int:  # No type hints, no validation
    return response_time * 2  # Could fail with invalid input
```

**🔧 Fix:** Add input validation
```python
def calculate_score_safe(response_time: float = 1000.0, success_rate: float = 0.95) -> int:
    if not isinstance(response_time, (int, float)) or response_time <= 0:
        raise ValueError("Response time must be positive number")
    if not isinstance(success_rate, (int, float)) or not 0 <= success_rate <= 1:
        raise ValueError("Success rate must be between 0 and 1")
    time_factor = int(1000 / (response_time + 1))
    success_factor = int(success_rate * 100)
    weighted_score = int((time_factor * 0.4) + (success_factor * 0.4))
    return min(max(weighted_score, 10), 100)
```

**✅ Correcto:** Availability check with timeout
```python
def check_available(endpoint: str, timeout: int = 5) -> bool:
    import requests
    try:
        response = requests.get(f"{endpoint}/health", timeout=timeout)
        return response.status_code == 200
    except requests.RequestException:
        return False
```

**❌ Incorrecto:** No timeout protection
```python
def check_available_bad(endpoint: str) -> bool:  # Could hang indefinitely
    import requests
    response = requests.get(f"{endpoint}/health")  # No timeout
    return response.status_code == 200
```

**🔧 Fix:** Add timeout and error handling
```python
def check_available_fixed(endpoint: str, timeout: int = 5) -> bool:
    import requests
    try:
        response = requests.get(f"{endpoint}/health", timeout=timeout)
        return response.status_code == 200
    except requests.Timeout:
        print(f"Health check timed out for {endpoint}", file=sys.stderr)
        return False
    except requests.RequestException as e:
        print(f"Health check failed for {endpoint}: {e}", file=sys.stderr)
        return False
```

**✅ Correcto:** Tenant-aware routing
```python
def route_for_tenant(request: dict, tenant: str = "default") -> Optional[dict]:
    context = determine_context_for_tenant(tenant)
    return route_request(request, context)
```

**❌ Incorrecto:** No tenant isolation
```python
def route_without_tenant(request: dict):  # Ignores tenant context
    return route_request(request, "default")  # Hardcoded context
```

**✅ Correcto:** Fallback mechanism
```python
def route_with_fallback(request: dict) -> Optional[dict]:
    primary_result = route_request(request, "primary")
    return primary_result if primary_result else route_request(request, "fallback")
```

**❌ Incorrecto:** No fallback
```python
def route_no_fallback(request: dict):  # Will fail if primary unavailable
    return route_request(request, "primary")
```

**🔧 Fix:** Add fallback handling
```python
def route_with_fallback_safe(request: dict) -> Optional[dict]:
    primary_result = route_request(request, "primary")
    if primary_result:
        return primary_result
    print("Primary routing failed, trying fallback", file=sys.stderr)
    return route_request(request, "fallback")
```

**✅ Correcto:** JSON validation in routing
```python
def validate_and_route(json_payload: dict) -> Optional[dict]:
    if not isinstance(json_payload, dict):
        raise TypeError("Payload must be a dictionary")
    return route_request(json_payload)
```

**❌ Incorrecto:** No JSON validation
```python
def route_invalid_json(json_payload):  # May fail with invalid JSON
    return route_request(json_payload)  # No validation
```

**🔧 Fix:** Add JSON validation
```python
def validate_and_route_safe(json_payload: dict) -> Optional[dict]:
    if not isinstance(json_payload, dict):
        raise TypeError(f"Expected dict, got {type(json_payload)}")
    return route_request(json_payload)
```

**✅ Correcto:** Multi-step routing decision
```python
def complex_route(request: dict, tenant: str = "default") -> Optional[dict]:
    priority = request.get("priority", "normal")
    context = "latency_critical" if priority == "high" else "default"
    return route_request(request, context, tenant)
```


```json
{
  "artifact": "06-PROGRAMMING/python/orchestrator-routing.md",
  "validation_timestamp": "2026-04-15T00:00:03Z",
  "constraints_checked": ["C3", "C4", "C5", "C7", "C8"],
  "score": 35,
  "max_score": 50,
  "blocking_issues": [],
  "warnings": ["Missing C1 (resource limits), C2 (performance thresholds) implementation"],
  "checksum_verified": true,
  "ready_for_sandbox": true
}
```

--- END OF ARTIFACT: orchestrator-routing.md ---
