# ---
# title: "Validator Documentation - Agentic Infra Docs"
# category: "Configuraciones"
# priority: "Media"
# version: "1.0.0"
# last_updated: "2026-04-XX"
# language: "es"
# repository: "agentic-infra-docs"
# owner: "Mantis-AgenticDev"
# type: "config"
# ia_parser_version: "2.0"
# auto_validate: true
# compliance_check: "on-demand"
# validation_script: "scripts/validate-against-specs.sh"
# auto_fixable: false
# severity_scope: "medium"
# tags:
#   - validator
#   - ci-cd
#   - sdd-compliance
#   - bash
# related_files:
#   - "05-CONFIGURATIONS/scripts/validate-against-specs.sh"
#   - "01-RULES/00-INDEX.md"
# ---

================================================================
VALIDATOR AGAINST SPECS - DOCUMENTACIÓN TÉCNICA (v1.0)
Proyecto: MANTIS AGENTIC | Metodología: SDD
================================================================

1. OBJETIVO
Validar automáticamente que los archivos del repositorio cumplan 
con los constraints absolutos (C1-C6), estructura SDD, tenant-
awareness y límites de recursos antes de commit o despliegue.

2. ARQUITECTURA MODULAR
El script no es un monolito. Cada función valida un dominio 
específico. Esto permite mantenimiento escalonado y evita 
falsos positivos cuando nuevas specs se agregan.

Módulos activos:
- validate_markdown_structure  : Frontmatter, code fences, tablas, secrets
- validate_tenant_awareness    : Constraint C4 (tenant_id en queries/specs)
- validate_resource_limits     : Constraints C1/C2 (RAM/CPU en Docker)
- validate_security            : Constraints C3/C6 (puertos BD, modelos locales)
- validate_n8n_patterns        : Timeouts HTTP, estructura JSON, tenant_id
- validate_sql_patterns        : WHERE tenant_id, prepared statements

3. USO EN TERMINAL
Uso básico:
  ./validate-against-specs.sh [ruta] [reporte.json] [verbose:0/1] [strict:0/1]

Ejemplos:
  ./validate-against-specs.sh ./01-RULES/ report.json 0 0
  ./validate-against-specs.sh README.md - 1 0          # Verbose, stdout
  ./validate-against-specs.sh ./ sdd-audit.json 0 1    # Strict mode

Parámetros:
  [ruta]          : Archivo o directorio a validar.
  [reporte.json]  : Ruta de salida del reporte JSON. Usa "-" para stdout.
  [verbose]       : 0=normal, 1=mostrar checks aprobados.
  [strict]        : 0=warnings no fallan, 1=warnings cuentan como error.

4. INTEGRACIÓN SDD
- El validador NO genera código. Solo audita contra reglas existentes.
- Si falla, retorna exit code 1. Ideal para hooks de git o CI/CD.
- El reporte JSON incluye: timestamp, sha256 del objetivo, conteos y lista de errores/warnings.
- Principio: Spec > Código. Si el validador falla, el commit se rechaza.

5. NAVEGACIÓN PARA IA (FRONTMATTER)
El bloque YAML está comentado con # para no romper la ejecución de bash.
Parsers de IA deben:
  1. Ignorar líneas que inician con # al ejecutar.
  2. Extraer metadata leyendo entre los delimitadores # ---
  3. Usar campos como: ai_parser_compatible, purpose, validation_scope, dependencies.

6. MANTENIMIENTO Y EXTENSIÓN
Para agregar nuevas reglas:
  a. Crear función validate_<dominio>() siguiendo el patrón:
     - Retornar 0 si pasa, 1 si falla.
     - Usar log_pass(), log_warn(), log_error() para registro estandarizado.
  b. Llamarla en run_validations() sin modificar la lógica central.
  c. No modificar generate_report() salvo agregar campos al JSON de salida.
  d. Actualizar este documento y el frontmatter YAML.

7. DEPENDENCIAS MÍNIMAS
- bash 4.0+
- utilidades POSIX: grep, awk, sed, sha256sum, find, date
- jq (opcional, solo para formatear arrays en el reporte JSON)
Compatible con Ubuntu 20.04+ sin instalación extra.

8. NOTAS OPERATIVAS
- El script ignora .git/ automáticamente.
- En modo strict, cualquier warning detiene la validación.
- Para CI/CD: ./validate-against-specs.sh ./ report.json 0 1 || echo "Fallo SDD"
- No usar sudo. Ejecutar como usuario estándar o en pipeline CI.

================================================================
Última revisión: 2026-04 | Autor: Equipo Mantis Agentic
Licencia: Uso interno, proyecto de ciencia abierta
================================================================

## 🔗 Conexiones Estructurales
[[01-RULES/00-INDEX.md]]
[[01-RULES/05-CODE-PATTERNS-RULES.md]]

## 🔗 Conexiones Estructurales (Auto-generado)
[[00-CONTEXT/documentation-validation-cheklist.md]]
[[PROJECT_TREE.md]]
