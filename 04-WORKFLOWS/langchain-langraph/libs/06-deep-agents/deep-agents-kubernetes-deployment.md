---
artifact_id: "deep-agents-kubernetes-deployment"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-kubernetes-deployment.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-kubernetes-deployment.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-kubernetes-v1.0.0"
generated_at: "2026-05-26T01:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-deployment-production"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# ☸️ Deep Agents – Deploy em Kubernetes

> **Contrato modular**: Artefato filho do Master Agent. Guia completo para implantar Deep Agents em clusters Kubernetes, incluindo Helm charts, configuração de ingress, secrets, escalabilidade e monitoramento.

---

## 🎯 Propósito
Permitir que agentes MANTIS sejam implantados em infraestrutura Kubernetes de forma escalável, segura e gerenciável.

## 📋 Especificação (SDD)
- **Entradas**: Dockerfile, Helm chart, configurações de secrets.
- **Saídas**: Agente rodando em cluster Kubernetes.
- **Side Effects**: Recursos alocados no cluster.
- **Constraints Aplicáveis**: C1 (recursos definidos), C2 (versionamento de imagem), C3 (secrets), C4 (namespaces), C5 (health checks), C7 (probes), C8 (logs), C9 (tracing).
- **Dependências**: `docker`, `kubectl`, `helm`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Dockerfile Otimizado

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -f http://localhost:8000/health || exit 1
CMD ["python", "-m", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. Helm Chart – `values.yaml`

```yaml
replicaCount: 2
image:
  repository: registry.example.com/mantis-agent
  tag: "1.0.0"
  pullPolicy: Always
service:
  type: ClusterIP
  port: 8000
ingress:
  enabled: true
  hosts:
    - host: agent.mantis.internal
      paths: ["/"]
resources:
  limits:
    cpu: "2"
    memory: "4Gi"
  requests:
    cpu: "1"
    memory: "2Gi"
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
env:
  - name: LANGSMITH_API_KEY
    valueFrom:
      secretKeyRef:
        name: mantis-secrets
        key: langsmith-api-key
  - name: OPENAI_API_KEY
    valueFrom:
      secretKeyRef:
        name: mantis-secrets
        key: openai-api-key
```

### 3. Deployment com Probes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mantis-agent
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: mantis-agent
  template:
    metadata:
      labels:
        app: mantis-agent
    spec:
      containers:
      - name: agent
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: 8000
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        env:
          {{- toYaml .Values.env | nindent 10 }}
```

### 4. Health e Readiness Endpoints

```python
from fastapi import FastAPI
app = FastAPI()

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.get("/ready")
async def ready():
    # Verificar dependências: Redis, DB, APIs
    checks = {
        "redis": await check_redis(),
        "database": await check_db(),
        "langsmith": await check_langsmith(),
    }
    if all(checks.values()):
        return {"status": "ready"}
    raise HTTPException(status_code=503, detail=checks)
```

### 5. Secrets Management

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mantis-secrets
type: Opaque
data:
  langsmith-api-key: <base64>
  openai-api-key: <base64>
  anthropic-api-key: <base64>
```

### 6. Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: mantis-agent-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: mantis-agent
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
```

### 7. ServiceMonitor para Prometheus

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: mantis-agent-monitor
spec:
  selector:
    matchLabels:
      app: mantis-agent
  endpoints:
  - port: http
    path: /metrics
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-kubernetes-deployment.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-deployment-production.md]]
