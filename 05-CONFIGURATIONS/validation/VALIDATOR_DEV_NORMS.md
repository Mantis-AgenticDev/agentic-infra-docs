---
canonical_path: "05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md"
artifact_id: "validator-dev-norms-v1.0"
constraints_mapped: "V-INT-01,V-INT-02,V-INT-03,V-INT-04,V-INT-05"
validation_command: "bash 05-CONFIGURATIONS/validation/test-validator-contract.sh --file 05-CONFIGURATIONS/validation/*.sh"
tier: 3
---

# 📐 VALIDATOR_DEV_NORMS.md – Normas Internas de Desarrollo de Validadores

## 🎯 Propósito
Establecer un contrato de ingeniería ligero y obligatorio para todas las herramientas ubicadas en `05-CONFIGURATIONS/validation/`. Estas normas aplican **exclusivamente al equipo de desarrollo de infraestructura** y no se imponen como constraints externas a los artefactos de negocio. El objetivo es garantizar:
• Ejecución predecible y paralelizable (<500ms/artifact)
• Integración directa con [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] sin parsing complejo
• Cero sobrecarga de gobernanza en rutas de producción masiva (600-1000+ artefactos)

## 🔧 Implementación

### V-INT-01: Contrato de Salida JSON Estricto
Todo validador debe generar un único objeto JSON válido por `stdout`. La generación **obligatoriamente** se realiza con `jq -n` o `jq -s`. Nunca se permite concatenación manual de strings.
**Schema mínimo requerido:**
```json
{
  "validator": "audit-secrets.sh",
  "file": "ruta/canonica.md",
  "timestamp": "2026-04-19T12:00:00Z",
  "passed": true,
  "issues": []
}
```

### V-INT-02: Semántica de Códigos de Salida (Exit Codes)
| Código | Significado | Acción del Orquestador |
|--------|-------------|------------------------|
| `0` | `passed: true` | Continúa flujo, registra score |
| `1` | `passed: false` | Registra `blocking_issues` o `warnings` |
| `2` | Error de ejecución | Aborta fallback, loguea en stderr |

### V-INT-03: Separación Estricta de Canales (I/O)
• `stdout`: **Únicamente** el JSON de resultado. Prohibido `echo` de progreso, emojis o logs aquí.
• `stderr`: Logs de debug, advertencias de rendimiento, trazas de error. Formato libre pero legible.
• Implementación técnica: Redirigir logs explícitamente `echo "..." >&2` o usar `>&2` en pipes.

### V-INT-04: Límites de Rendimiento y Recursos
• Timeout máximo por validación: `500ms` en hardware estándar (CI runner básico).
• Uso de memoria: Límite de `64MB` por proceso. Evitar carga completa de archivos grandes en RAM.
• Procesamiento: Lectura streaming (`grep`, `awk`, `sed`, `jq --stream`) o lectura línea por línea. Prohibido `cat file | tr -d '\n'` en archivos >10MB.

### V-INT-05: Declaración Explícita de Dependencias
Cada script debe iniciar con un bloque de metadatos comentados que declare:
```bash
# VALIDATOR_DEPENDENCIES: jq>=1.6, bash>=5.0, yq>=4.25
# EXECUTION_PROFILE: <500ms, <64MB RAM, streaming IO
# SCOPE: internal-validation-only
```

## 📋 Ejemplos ✅/❌/🔧

### ✅ Cumple normas
```bash
#!/usr/bin/env bash
# VALIDATOR_DEPENDENCIES: jq>=1.6, bash>=5.0
set -euo pipefail
FILE="${1:?Missing file argument}"
# Lógica de validación...
jq -n --arg v "audit-secrets.sh" --arg f "$FILE" \
    --argjson p true --argjson i '[]' \
    '{validator:$v, file:$f, timestamp:now|strftime("%Y-%m-%dT%H:%M:%SZ"), passed:$p, issues:$i}'
exit 0
```

### ❌ Violación V-INT-03 (stdout contaminado)
```bash
echo "🔍 Escaneando $FILE..."
echo "{\"passed\": true}"  # ← JSON mezclado con texto, rompe jq en orchestrator
```
**🔧 Corrección:** `echo "🔍 Escaneando $FILE..." >&2`

### ❌ Violación V-INT-01 (concatenación manual)
```bash
echo "{\"passed\": true, \"file\": \"$FILE\"}" # ← Falla si $FILE contiene comillas o \
```
**🔧 Corrección:** `jq -n --arg f "$FILE" '{passed:true, file:$f}'`

## 🧪 Validación
• Ejecutar `bash 05-CONFIGURATIONS/validation/test-validator-contract.sh --file 05-CONFIGURATIONS/validation/*.sh`
• Verificar que cada script retorne exit code válido y JSON parseable: `bash script.sh dummy.md | jq -e '.passed'`
• Confirmar ausencia de texto en stdout: `bash script.sh dummy.md | grep -v '^{'` debe retornar vacío.

## 🔗 Referencias
• [[01-RULES/harness-norms-v3.0.md]] (Gobernanza externa - NO aplica aquí)
• [[05-CONFIGURATIONS/validation/norms-matrix.json]] (Contexto de constraints por carpeta)
• [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] (Consumidor final de outputs)
• [[06-PROGRAMMING/bash/00-INDEX.md]] (Patrones canónicos de shell)

