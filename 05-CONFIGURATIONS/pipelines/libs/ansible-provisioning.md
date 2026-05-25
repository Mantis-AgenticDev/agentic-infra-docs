---
artifact_id: "pipelines-ansible-provisioning"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C2"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/ansible-provisioning.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/ansible-provisioning.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:ansible-provisioning-v1.0.0"
generated_at: "2026-05-24T00:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["vps-provisioning", "ansible-integration"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🖥️ Provisionamento de VPS com Ansible

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Automatizar a configuração inicial de VPS (Docker, usuários, systemd) usando Ansible, garantindo infraestrutura como código (C1, C2).

## 📋 Especificação
- **Entradas**: IP do VPS, perfil de infra.
- **Saídas**: Playbook Ansible executável.
- **Constraints Aplicáveis**: C1 (imutabilidade), C2 (IaC).

---

## 🛡️ Playbook Base

```yaml
---
- name: Provision MANTIS VPS
  hosts: vps_targets
  become: true
  vars:
    mantis_user: deploy
    docker_version: "24.0.7"
  tasks:
    - name: Criar usuário deploy
      user:
        name: "{{ mantis_user }}"
        groups: docker
        shell: /bin/bash
    - name: Instalar Docker
      apt:
        name: docker.io
        state: present
    - name: Configurar Docker Compose
      get_url:
        url: https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64
        dest: /usr/local/bin/docker-compose
        mode: '0755'
```

### Integração com Pipeline
```yaml
- name: Executar Ansible
  run: |
    ansible-playbook -i inventory.ini playbooks/vps-provision.yml \
      --extra-vars "mantis_version=${{ github.sha }}"
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_ansible_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/playbook.yml" << 'EOF'
---
- hosts: localhost
  tasks:
    - debug: msg="test"
EOF
  ansible-playbook --syntax-check "$tmp/playbook.yml" 2>/dev/null && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { command -v ansible-playbook &>/dev/null && test_ansible_syntax && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../../terraform/modules/vps-base/main.tf]] — Complemento Terraform
- [[../../docker-compose/libs/validation-scripts.md]]
