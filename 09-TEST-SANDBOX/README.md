# 🧪 Sandbox de Pruebas — Generación Multi-IA

> **Propósito**: Espacio aislado para comparar outputs de Qwen, MiniMax y DeepSeek antes de promoción a producción.

## 📂 Estructura

09-TEST-SANDBOX/
├── qwen/          # Outputs de Qwen2.5-72B
├── minimax/       # Outputs de MiniMax 2.7
├── deepseek/      # Outputs de DeepSeek Web
├── comparison/    # Análisis comparativo y decisiones
└── README.md      # Este archivo


## 🔄 Flujo de Trabajo
1. Cada IA genera en su carpeta asignada
2. Archivos NO se mergean a main sin validación
3. Revisión comparativa en `comparison/`
4. Promoción manual a producción tras certificación

## ⚠️ Reglas
- ❌ Nunca ejecutar deploy desde esta carpeta
- ❌ Nunca referenciar archivos de test en producción
- ✅ Siempre incluir `test-source: [ia-name]` en frontmatter
- ✅ Borrar archivos tras promoción exitosa

## 🤝 Revisión con Asistente
Para revisión, compartir:
1. Ruta relativa del archivo (ej: `09-TEST-SANDBOX/qwen/variables.tf`)
2. Tier objetivo (1/2/3)
3. Validadores ejecutados y resultados


## 🆕 IAs Adicionales Incorporadas
- `claude/`: Outputs de Claude (disponible desde jueves)
- `gemini/`: Outputs de Gemini (Google AI)

## 📋 Estado Actual de Generación
| IA | Carpeta | Estado | Archivos Generados |
|----|---------|--------|-------------------|
| Qwen2.5-72B | `qwen/` | ✅ Activa | GOVERNANCE-ORCHESTRATOR.md, orchestrator-engine.sh |
| MiniMax 2.7 | `minimax/` | ✅ Activa | GOVERNANCE-ORCHESTRATOR.md, orchestrator-engine.sh |
| DeepSeek | `deepseek/` | ✅ Activa | GOVERNANCE-ORCHESTRATOR.md, orchestrator-engine.sh |
| Claude | `claude/` | ⏳ Pendiente (desde jueves) | - |
| Gemini | `gemini/` | 🔄 En progreso | Informe pendiente |
