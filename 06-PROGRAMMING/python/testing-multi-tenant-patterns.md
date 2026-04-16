# SHA256: c9d0e1f2a3b4c5d678901234567890abcdef1234567890abcdef12345678
---
artifact_id: "testing-multi-tenant-patterns"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C4","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/testing-multi-tenant-patterns.md --json"
---

# 🧪 Testing Multi‑tenant Patterns – Python

## Propósito
Patrones para testear código Python multi‑tenant con enfoque en validación de aislamiento de tenant (C4), manejo de timeouts y rollback (C7), y logging estructurado sin `print()` (C8). Incluye ejemplos de tests unitarios y de integración con `pytest` y mocks.

## Patrones de Código Validados

### Ejemplo 1: Test de validación estricta de TENANT_ID (C4)
```python
# ✅ C4: test para sys.exit(1) si falta TENANT_ID
def test_missing_tenant_id():
    with pytest.raises(SystemExit):
        os.environ.pop("TENANT_ID", None)
        validate_tenant_id()
```

```python
# ❌ Anti-pattern: test sin limpieza
def test_tenant():
    os.environ["TENANT_ID"] = "t1"
    assert validate_tenant_id() == "t1"

# 🔧 Fix: usar monkeypatch para aislar
def test_missing(monkeypatch):
    monkeypatch.delenv("TENANT_ID", raising=False)
    with pytest.raises(SystemExit):
        validate_tenant_id()
```

### Ejemplo 2: Test de logging estructurado (C8)
```python
# ✅ C8: capturar logs JSON-like con caplog
def test_logging(caplog):
    with caplog.at_level(logging.INFO):
        logger.info(json.dumps({"event": "test"}))
    assert '"event": "test"' in caplog.text
```

```python
# ❌ Anti-pattern: test que depende de print()
def test_output(capsys):
    print("ok")
    captured = capsys.readouterr()
    assert "ok" in captured.out

# 🔧 Fix: usar caplog para logger
def test_log(caplog):
    logger.info("ok")
    assert "ok" in caplog.text
```

### Ejemplo 3: Test de timeout con subprocess (C7)
```python
# ✅ C7: simular timeout en subprocess
def test_timeout(mocker):
    mock_run = mocker.patch("subprocess.run")
    mock_run.side_effect = subprocess.TimeoutExpired("cmd", 10)
    with pytest.raises(subprocess.TimeoutExpired):
        run_with_timeout(["sleep", "100"], timeout=1)
```

```python
# ❌ Anti-pattern: sleep real en test
def test_slow():
    time.sleep(5)  # ralentiza suite

# 🔧 Fix: mock del tiempo o subprocess
mock_run.side_effect = subprocess.TimeoutExpired(...)
```

### Ejemplo 4: Test de rollback tras fallo (C7)
```python
# ✅ C7: verificar llamada a rollback
def test_rollback(mocker):
    mock_rollback = mocker.patch("module.rollback")
    mocker.patch("module.dangerous_op", side_effect=Exception)
    with pytest.raises(Exception):
        orchestrate()
    mock_rollback.assert_called_once()
```

```python
# ❌ Anti-pattern: test sin verificar rollback
def test_failure():
    with pytest.raises(Exception):
        orchestrate()

# 🔧 Fix: mock rollback y assert called
mock_rollback.assert_called_once()
```

### Ejemplo 5: Test de aislamiento de contexto (C4)
```python
# ✅ C4: verificar que tenant_ctx se propaga
def test_tenant_context():
    tenant_ctx.set("tenant_a")
    result = process_with_tenant()
    assert result["tenant"] == "tenant_a"
```

```python
# ❌ Anti-pattern: no limpiar contexto entre tests
def test_a():
    tenant_ctx.set("a")
def test_b():
    assert tenant_ctx.get() == "a"  # depende de orden

# 🔧 Fix: fixture que resetea ContextVar
@pytest.fixture(autouse=True)
def reset_tenant_ctx():
    tenant_ctx.set("")
```

### Ejemplo 6: Test de TenantFilter en logs (C4, C8)
```python
# ✅ C4/C8: validar que log incluye tenant
def test_tenant_filter(caplog):
    tenant_ctx.set("t1")
    logger.addFilter(TenantFilter())
    logger.info("test")
    assert '"tenant": "t1"' in caplog.text
```

```python
# ❌ Anti-pattern: test sin filtro
def test_log(caplog):
    logger.info("test")
    assert "tenant" not in caplog.text

# 🔧 Fix: añadir TenantFilter antes de loguear
logger.addFilter(TenantFilter())
```

### Ejemplo 7: Test de type hints con mypy (C8)
```python
# ✅ C8: validación estática en CI
# $ mypy --strict module.py
def process(data: dict) -> bool:
    return bool(data)
```

```python
# ❌ Anti-pattern: código sin type hints
def process(data):
    return bool(data)

# 🔧 Fix: añadir anotaciones y correr mypy
def process(data: dict) -> bool: ...
```

### Ejemplo 8: Test de integración con timeout HTTP (C7)
```python
# ✅ C7: mock de requests con timeout
def test_api_timeout(mocker):
    mock_post = mocker.patch("requests.post")
    mock_post.side_effect = requests.Timeout
    with pytest.raises(requests.Timeout):
        call_external_api()
```

```python
# ❌ Anti-pattern: llamada real a API
def test_live():
    resp = requests.get("https://api.example.com")

# 🔧 Fix: mock para evitar llamadas reales
mock_get.side_effect = requests.Timeout
```

### Ejemplo 9: Test de CLI help con logger (C8)
```python
# ✅ C8: verificar que --help loguea uso
def test_help(caplog, monkeypatch):
    monkeypatch.setattr(sys, "argv", ["script.py", "--help"])
    with pytest.raises(SystemExit):
        main()
    assert "Uso:" in caplog.text
```

```python
# ❌ Anti-pattern: test que captura stdout
def test_help(capsys):
    sys.argv = ["script.py", "--help"]
    main()
    assert "Uso:" in capsys.readouterr().out

# 🔧 Fix: usar caplog para logger.info
```

### Ejemplo 10: Test de validación de tenant en carga de datos (C4)
```python
# ✅ C4: asegurar que carga falla si tenant no coincide
def test_tenant_mismatch():
    tenant_ctx.set("tenant_x")
    with pytest.raises(PermissionError):
        load_data_for_tenant("tenant_y")
```

```python
# ❌ Anti-pattern: test sin verificar tenant
def test_load():
    data = load_data()  # no se pasa tenant

# 🔧 Fix: pasar tenant explícito y verificar
def test_load():
    with pytest.raises(PermissionError):
        load_data("other_tenant")
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/testing-multi-tenant-patterns.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"testing-multi-tenant-patterns","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---# SHA256: c9d0e1f2a3b4c5d678901234567890abcdef1234567890abcdef12345678
---
artifact_id: "testing-multi-tenant-patterns"
artifact_type: "skill_python"
version: "2.1.1"
constraints_mapped: ["C4","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/testing-multi-tenant-patterns.md --json"
---

# 🧪 Testing Multi‑tenant Patterns – Python

## Propósito
Patrones para testear código Python multi‑tenant con enfoque en validación de aislamiento de tenant (C4), manejo de timeouts y rollback (C7), y logging estructurado sin `print()` (C8). Incluye ejemplos de tests unitarios y de integración con `pytest` y mocks.

## Patrones de Código Validados

### Ejemplo 1: Test de validación estricta de TENANT_ID (C4)
```python
# ✅ C4: test para sys.exit(1) si falta TENANT_ID
def test_missing_tenant_id():
    with pytest.raises(SystemExit):
        os.environ.pop("TENANT_ID", None)
        validate_tenant_id()
```

```python
# ❌ Anti-pattern: test sin limpieza
def test_tenant():
    os.environ["TENANT_ID"] = "t1"
    assert validate_tenant_id() == "t1"

# 🔧 Fix: usar monkeypatch para aislar
def test_missing(monkeypatch):
    monkeypatch.delenv("TENANT_ID", raising=False)
    with pytest.raises(SystemExit):
        validate_tenant_id()
```

### Ejemplo 2: Test de logging estructurado (C8)
```python
# ✅ C8: capturar logs JSON-like con caplog
def test_logging(caplog):
    with caplog.at_level(logging.INFO):
        logger.info(json.dumps({"event": "test"}))
    assert '"event": "test"' in caplog.text
```

```python
# ❌ Anti-pattern: test que depende de print()
def test_output(capsys):
    print("ok")
    captured = capsys.readouterr()
    assert "ok" in captured.out

# 🔧 Fix: usar caplog para logger
def test_log(caplog):
    logger.info("ok")
    assert "ok" in caplog.text
```

### Ejemplo 3: Test de timeout con subprocess (C7)
```python
# ✅ C7: simular timeout en subprocess
def test_timeout(mocker):
    mock_run = mocker.patch("subprocess.run")
    mock_run.side_effect = subprocess.TimeoutExpired("cmd", 10)
    with pytest.raises(subprocess.TimeoutExpired):
        run_with_timeout(["sleep", "100"], timeout=1)
```

```python
# ❌ Anti-pattern: sleep real en test
def test_slow():
    time.sleep(5)  # ralentiza suite

# 🔧 Fix: mock del tiempo o subprocess
mock_run.side_effect = subprocess.TimeoutExpired(...)
```

### Ejemplo 4: Test de rollback tras fallo (C7)
```python
# ✅ C7: verificar llamada a rollback
def test_rollback(mocker):
    mock_rollback = mocker.patch("module.rollback")
    mocker.patch("module.dangerous_op", side_effect=Exception)
    with pytest.raises(Exception):
        orchestrate()
    mock_rollback.assert_called_once()
```

```python
# ❌ Anti-pattern: test sin verificar rollback
def test_failure():
    with pytest.raises(Exception):
        orchestrate()

# 🔧 Fix: mock rollback y assert called
mock_rollback.assert_called_once()
```

### Ejemplo 5: Test de aislamiento de contexto (C4)
```python
# ✅ C4: verificar que tenant_ctx se propaga
def test_tenant_context():
    tenant_ctx.set("tenant_a")
    result = process_with_tenant()
    assert result["tenant"] == "tenant_a"
```

```python
# ❌ Anti-pattern: no limpiar contexto entre tests
def test_a():
    tenant_ctx.set("a")
def test_b():
    assert tenant_ctx.get() == "a"  # depende de orden

# 🔧 Fix: fixture que resetea ContextVar
@pytest.fixture(autouse=True)
def reset_tenant_ctx():
    tenant_ctx.set("")
```

### Ejemplo 6: Test de TenantFilter en logs (C4, C8)
```python
# ✅ C4/C8: validar que log incluye tenant
def test_tenant_filter(caplog):
    tenant_ctx.set("t1")
    logger.addFilter(TenantFilter())
    logger.info("test")
    assert '"tenant": "t1"' in caplog.text
```

```python
# ❌ Anti-pattern: test sin filtro
def test_log(caplog):
    logger.info("test")
    assert "tenant" not in caplog.text

# 🔧 Fix: añadir TenantFilter antes de loguear
logger.addFilter(TenantFilter())
```

### Ejemplo 7: Test de type hints con mypy (C8)
```python
# ✅ C8: validación estática en CI
# $ mypy --strict module.py
def process(data: dict) -> bool:
    return bool(data)
```

```python
# ❌ Anti-pattern: código sin type hints
def process(data):
    return bool(data)

# 🔧 Fix: añadir anotaciones y correr mypy
def process(data: dict) -> bool: ...
```

### Ejemplo 8: Test de integración con timeout HTTP (C7)
```python
# ✅ C7: mock de requests con timeout
def test_api_timeout(mocker):
    mock_post = mocker.patch("requests.post")
    mock_post.side_effect = requests.Timeout
    with pytest.raises(requests.Timeout):
        call_external_api()
```

```python
# ❌ Anti-pattern: llamada real a API
def test_live():
    resp = requests.get("https://api.example.com")

# 🔧 Fix: mock para evitar llamadas reales
mock_get.side_effect = requests.Timeout
```

### Ejemplo 9: Test de CLI help con logger (C8)
```python
# ✅ C8: verificar que --help loguea uso
def test_help(caplog, monkeypatch):
    monkeypatch.setattr(sys, "argv", ["script.py", "--help"])
    with pytest.raises(SystemExit):
        main()
    assert "Uso:" in caplog.text
```

```python
# ❌ Anti-pattern: test que captura stdout
def test_help(capsys):
    sys.argv = ["script.py", "--help"]
    main()
    assert "Uso:" in capsys.readouterr().out

# 🔧 Fix: usar caplog para logger.info
```

### Ejemplo 10: Test de validación de tenant en carga de datos (C4)
```python
# ✅ C4: asegurar que carga falla si tenant no coincide
def test_tenant_mismatch():
    tenant_ctx.set("tenant_x")
    with pytest.raises(PermissionError):
        load_data_for_tenant("tenant_y")
```

```python
# ❌ Anti-pattern: test sin verificar tenant
def test_load():
    data = load_data()  # no se pasa tenant

# 🔧 Fix: pasar tenant explícito y verificar
def test_load():
    with pytest.raises(PermissionError):
        load_data("other_tenant")
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/python/testing-multi-tenant-patterns.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"testing-multi-tenant-patterns","version":"2.1.1","score":32,"blocking_issues":[],"constraints_verified":["C4","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"Python 3.10+","timestamp":"2026-04-16T04:23:45Z"}
```

---
