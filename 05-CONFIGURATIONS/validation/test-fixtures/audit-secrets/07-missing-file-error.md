<!-- EXPECT: error | DETECT: N/A | PERF: N/A -->
# Este archivo NO existe – se usa para probar manejo de errores
# Ejecutar con: bash audit-secrets.sh --file /ruta/que/no/existe.md
# Debe retornar exit code 2 y JSON con passed:false + error en stderr

