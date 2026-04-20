<!-- EXPECT: passed | DETECT: false | PERF: <500ms -->
# Documentación Limpia




# Ejemplo seguro: usar variables de entorno
API_KEY="${API_KEY:?Missing API_KEY env var}"
DB_PASSWORD="${DB_PASSWORD}"


Referencias:
- [[01-RULES/harness-norms-v3.0.md]]
- [[05-CONFIGURATIONS/.env.example]]

