// Mapeo rudimentario de Fix Hints basado en el error/categoría
const FIX_HINTS = {
  "explicit_bypass": "Eliminar 'SET rls = false'. El bypass explícito de RLS está prohibido por C4.",
  "explicit_bypass_marker": "Eliminar el comentario '-- bypass-rls'.",
  "missing_tenant_filter": "Añadir cláusula 'WHERE tenant_id = current_setting('app.current_tenant')' o el id correspondiente en el DML.",
  "missing_join_scoping": "Asegurar de cruzar en el JOIN 'ON a.tenant_id = b.tenant_id'.",
  "API_KEY": "Mover la credencial hardcodeada a una variable de entorno o config.yaml (Zero Hardcode C3).",
  "DB_PASSWORD": "Usar secrets vault o env vars en lugar de contraseña hardcodeada.",
  "AWS_CRED": "Remover credenciales de AWS del código. Usar perfiles o env vars.",
  "BROKEN_LINK": "Actualizar el enlace roto apuntando a una ruta canónica existente.",
  "FILE_NOT_FOUND": "Asegurar que el archivo exista antes de enviarlo a validación."
};

let manifestData = null;
let currentFilter = { status: null, domain: null, search: "" };

document.addEventListener("DOMContentLoaded", () => {
  fetchData();
  setupEventListeners();
});

async function fetchData() {
  try {
    const response = await fetch('../data/manifest.json');
    if (!response.ok) throw new Error('No manifest found');
    manifestData = await response.json();
    renderDashboard();
  } catch (error) {
    document.getElementById('last-updated').innerText = "Error cargando datos. (Ejecuta el orquestador primero)";
    console.error(error);
  }
}

function renderDashboard() {
  if (!manifestData) return;

  // Header
  document.getElementById('last-updated').innerText = `Actualizado: ${new Date(manifestData.timestamp).toLocaleString()}`;

  // Metrics
  const m = manifestData.metrics;
  document.getElementById('kpi-total').innerText = m.total_artifacts;
  document.getElementById('kpi-prate').innerText = `${m.pass_rate_pct}%`;
  document.getElementById('kpi-frate').innerText = `${m.fail_rate_pct}%`;
  document.getElementById('kpi-loc').innerText = m.total_loc.toLocaleString();
  document.getElementById('kpi-tokens').innerText = m.total_tokens.toLocaleString();
  document.getElementById('kpi-time').innerText = `${(m.total_time_ms / 1000).toFixed(2)}s`;

  // Alerts
  const alertsContainer = document.getElementById('alerts-container');
  alertsContainer.innerHTML = '';
  if (parseFloat(m.fail_rate_pct) > 15) {
    alertsContainer.innerHTML += `<div class="alert-banner alert-danger">⚠️ THRESHOLD BREACH: Fail rate exceeds 15%</div>`;
  }
  if ((m.total_time_ms / m.total_artifacts) > 2500) {
    alertsContainer.innerHTML += `<div class="alert-banner alert-warning">⚠️ THRESHOLD BREACH: Average time > 2500ms</div>`;
  }

  // Populate Domains in Sidebar
  const domains = [...new Set(manifestData.artifacts.map(a => a.domain))].sort();
  const tree = document.getElementById('domain-tree');
  tree.innerHTML = '';
  domains.forEach(d => {
    const div = document.createElement('div');
    div.className = 'nav-tree-item';
    div.innerText = `📁 ${d}`;
    div.onclick = () => setFilter('domain', d, div);
    tree.appendChild(div);
  });

  renderTable();
}

function renderTable() {
  const tbody = document.getElementById('table-body');
  tbody.innerHTML = '';

  let filtered = manifestData.artifacts.filter(a => {
    if (currentFilter.status !== null && a.passed !== currentFilter.status) return false;
    if (currentFilter.domain !== null && a.domain !== currentFilter.domain) return false;
    if (currentFilter.search) {
      return a.file.toLowerCase().includes(currentFilter.search.toLowerCase());
    }
    return true;
  });

  // Limitar a 100 en UI para performance virtual
  filtered.slice(0, 100).forEach((a, i) => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>
        <span class="status-icon" ${!a.passed ? `onclick="openModal(${manifestData.artifacts.indexOf(a)})"` : ''}>
          ${a.passed ? '✅' : '❌'}
        </span>
      </td>
      <td><span class="badge">${a.domain}</span></td>
      <td style="font-family: monospace; font-size: 0.9em">${a.file}</td>
      <td>${a.time_ms}</td>
      <td>${a.loc}</td>
      <td>${a.tokens}</td>
      <td>
        ${!a.passed ? `<button onclick="openModal(${manifestData.artifacts.indexOf(a)})" style="background:var(--text-red); border:none; color:#fff; padding:4px 8px; border-radius:4px; cursor:pointer;">Issues</button>` : ''}
      </td>
    `;
    tbody.appendChild(tr);
  });
}

function setFilter(type, value, element) {
  // Reset active classes
  document.querySelectorAll('.nav-item, .nav-tree-item').forEach(el => el.classList.remove('active'));
  if (element) element.classList.add('active');

  if (type === 'global') {
    currentFilter = { status: null, domain: null, search: document.getElementById('search-input').value };
  } else if (type === 'domain') {
    currentFilter.domain = value;
    currentFilter.status = null;
  } else if (type === 'status') {
    currentFilter.status = value;
    currentFilter.domain = null;
  }
  renderTable();
}

function setupEventListeners() {
  document.getElementById('nav-global').onclick = (e) => setFilter('global', null, e.target);
  document.getElementById('nav-passed').onclick = (e) => setFilter('status', true, e.target);
  document.getElementById('nav-failed').onclick = (e) => setFilter('status', false, e.target);
  
  document.getElementById('search-input').addEventListener('input', (e) => {
    currentFilter.search = e.target.value;
    renderTable();
  });

  document.getElementById('modal-close').onclick = () => {
    document.getElementById('issue-modal').style.display = "none";
  };
  
  window.onclick = (e) => {
    const modal = document.getElementById('issue-modal');
    if (e.target == modal) modal.style.display = "none";
  };
}

window.openModal = function(index) {
  const artifact = manifestData.artifacts[index];
  document.getElementById('modal-title').innerText = `Issues in: ${artifact.file.split('/').pop()}`;
  
  const body = document.getElementById('modal-body');
  body.innerHTML = '';

  if (artifact.issues && artifact.issues.length > 0) {
    artifact.issues.forEach(issue => {
      // Intentar encontrar un hint
      let hint = "Revisar logs y normativas MANTIS C1-C8/V1-V3.";
      Object.keys(FIX_HINTS).forEach(key => {
        if ((issue.category && issue.category.includes(key)) || (issue.description && issue.description.includes(key)) || (issue === key)) {
          hint = FIX_HINTS[key];
        }
      });

      const cat = issue.category || issue.constraint || issue;
      const desc = issue.description || issue;
      const sev = issue.severity || 'ERROR';
      const snip = issue.snippet ? `<div class="issue-snippet">${issue.snippet.replace(/</g, "&lt;")}</div>` : '';
      const line = issue.line ? ` (Línea ${issue.line})` : '';

      body.innerHTML += `
        <div class="issue-block ${sev === 'WARNING' ? 'warning' : ''}">
          <div class="issue-title">[${sev}] ${cat} - Valiator: ${issue.validator || 'unknown'}</div>
          <div>${desc}${line}</div>
          ${snip}
          <div class="fix-hint">💡 Hint: ${hint}</div>
        </div>
      `;
    });
  } else {
    body.innerHTML = '<p>No se reportaron issues estructurados. Revisa stderr logs.</p>';
  }

  document.getElementById('issue-modal').style.display = "block";
};
