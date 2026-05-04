package dashboard

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"

	"github.com/mantis-agentic/orchestrator-engine/types"
)

// GenerateDashboardHTML generates a standalone HTML dashboard
func GenerateDashboardHTML(manifest *types.Manifest) (string, error) {
	// Calculate pass rate
	passRate := 0.0
	if manifest.Metrics.TotalArtifacts > 0 {
		passRate = float64(manifest.Metrics.Passed) / float64(manifest.Metrics.TotalArtifacts) * 100
	}

	// Marshal manifest to JSON
	manifestJSON, err := json.Marshal(manifest)
	if err != nil {
		manifestJSON = []byte("{}")
	}

	data := struct {
		Timestamp       string
		Version         string
		TotalArtifacts  int
		Passed          int
		Failed          int
		PassRate        float64
		FailRate        float64
		TotalLOC        int
		TotalTokens     int
		TotalTime       string
		ManifestJSON    template.JS
	}{
		Timestamp:       manifest.Timestamp.Format("02 Jan 2006, 15:04"),
		Version:         "4.0.0",
		TotalArtifacts:  manifest.Metrics.TotalArtifacts,
		Passed:          manifest.Metrics.Passed,
		Failed:          manifest.Metrics.Failed,
		PassRate:        passRate,
		FailRate:        100 - passRate,
		TotalLOC:        manifest.Metrics.TotalLOC,
		TotalTokens:     manifest.Metrics.TotalTokens,
		TotalTime:       formatDuration(manifest.Metrics.TotalTimeMs),
		ManifestJSON:    template.JS(manifestJSON),
	}

	var buf bytes.Buffer
	if err := dashboardTemplate.Execute(&buf, data); err != nil {
		return "", err
	}

	return buf.String(), nil
}

func formatDuration(ms int64) string {
	if ms < 1000 {
		return fmt.Sprintf("%dms", ms)
	}
	seconds := float64(ms) / 1000
	if seconds < 60 {
		return fmt.Sprintf("%.2fs", seconds)
	}
	minutes := int(seconds) / 60
	remainingSeconds := int(seconds) % 60
	return fmt.Sprintf("%dm %ds", minutes, remainingSeconds)
}

var dashboardTemplate = template.Must(template.New("dashboard").Parse(`<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mantis Agentic Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --bg-primary: #111111;
            --bg-surface: #1a1a1a;
            --border-color: #333333;
            --gold: #E0AF68;
            --green: #2e8b57;
            --red: #c0392b;
            --text-primary: #cccccc;
            --text-secondary: #888888;
        }

        body {
            background-color: var(--bg-primary);
            color: var(--text-primary);
            font-family: system-ui, -apple-system, sans-serif;
            line-height: 1.6;
        }

        /* Sidebar */
        .sidebar {
            position: fixed;
            left: 0;
            top: 0;
            width: 260px;
            height: 100vh;
            background-color: var(--bg-surface);
            border-right: 1px solid var(--border-color);
            display: flex;
            flex-direction: column;
            padding: 24px 0;
        }

        .sidebar-header {
            padding: 0 24px 32px;
        }

        .sidebar-logo {
            font-size: 18px;
            font-weight: 900;
            color: var(--gold);
            letter-spacing: -0.02em;
        }

        .sidebar-version {
            font-size: 10px;
            color: var(--text-secondary);
            letter-spacing: 0.1em;
            margin-top: 4px;
        }

        .version-badge {
            background: #1E3A1E;
            color: var(--green);
            font-size: 10px;
            font-weight: bold;
            padding: 2px 8px;
            border-radius: 4px;
            border: 1px solid rgba(111, 207, 151, 0.2);
        }

        .nav-section {
            padding: 0 12px;
            flex: 1;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 16px;
            border-radius: 8px;
            color: var(--text-secondary);
            cursor: pointer;
            transition: all 0.2s;
            border-left: 4px solid transparent;
        }

        .nav-item:hover {
            color: var(--text-primary);
            background: rgba(255, 255, 255, 0.05);
        }

        .nav-item.active {
            color: var(--gold);
            background: rgba(224, 175, 104, 0.05);
            border-left-color: var(--gold);
        }

        .nav-icon {
            font-size: 20px;
        }

        .nav-label {
            font-size: 14px;
        }

        /* Main Content */
        .main-content {
            margin-left: 260px;
            min-height: 100vh;
        }

        /* Header */
        .header {
            position: sticky;
            top: 0;
            z-index: 10;
            background: rgba(17, 17, 17, 0.8);
            backdrop-filter: blur(8px);
            border-bottom: 1px solid var(--border-color);
            padding: 16px 32px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .search-box {
            display: flex;
            align-items: center;
            background: var(--bg-surface);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 8px 16px;
            width: 384px;
            transition: border-color 0.2s;
        }

        .search-box:focus-within {
            border-color: rgba(224, 175, 104, 0.5);
        }

        .search-box input {
            background: transparent;
            border: none;
            color: var(--text-primary);
            font-size: 14px;
            width: 100%;
            outline: none;
        }

        .search-box input::placeholder {
            color: #555;
        }

        .search-icon {
            color: #555;
            margin-right: 12px;
        }

        .header-info {
            display: flex;
            align-items: center;
            gap: 24px;
        }

        .last-updated {
            font-size: 12px;
            color: var(--text-secondary);
        }

        /* Dashboard Content */
        .dashboard-content {
            padding: 32px;
        }

        /* KPI Grid */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            margin-bottom: 32px;
        }

        .kpi-card {
            background: var(--bg-surface);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 20px;
            transition: all 0.2s;
        }

        .kpi-card:hover {
            border-color: rgba(224, 175, 104, 0.3);
        }

        .kpi-label {
            font-size: 11px;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.05em;
            font-weight: 700;
            margin-bottom: 8px;
        }

        .kpi-value {
            font-size: 24px;
            font-weight: 600;
            color: var(--text-primary);
        }

        .kpi-value.pass {
            color: var(--green);
        }

        .kpi-value.fail {
            color: var(--red);
        }

        .kpi-value.highlight {
            color: var(--gold);
        }

        /* Table */
        .table-container {
            background: var(--bg-surface);
            border: 1px solid var(--border-color);
            border-radius: 16px;
            overflow: hidden;
            margin-bottom: 32px;
        }

        .table-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 24px;
            border-bottom: 1px solid var(--border-color);
        }

        .table-title {
            font-size: 20px;
            font-weight: 600;
        }

        .table-actions {
            display: flex;
            gap: 8px;
        }

        .btn-icon {
            background: var(--bg-primary);
            border: 1px solid var(--border-color);
            color: var(--text-secondary);
            padding: 8px;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-icon:hover {
            color: var(--text-primary);
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th {
            text-align: left;
            padding: 16px 24px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--text-secondary);
            background: rgba(17, 17, 17, 0.5);
        }

        td {
            padding: 16px 24px;
            border-top: 1px solid rgba(255, 255, 255, 0.05);
        }

        tr:hover {
            background: rgba(255, 255, 255, 0.03);
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 12px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 700;
        }

        .status-badge.pass {
            background: rgba(46, 139, 87, 0.15);
            color: var(--green);
        }

        .status-badge.fail {
            background: rgba(192, 57, 43, 0.15);
            color: var(--red);
        }

        .file-path {
            font-family: 'JetBrains Mono', monospace;
            font-size: 12px;
            color: #a8a29e;
            max-width: 400px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .domain-tag {
            font-family: monospace;
            font-size: 11px;
            color: var(--gold);
            opacity: 0.7;
        }

        .numeric-cell {
            font-family: monospace;
            font-size: 12px;
            color: var(--text-secondary);
            text-align: right;
        }

        .action-btn {
            background: rgba(192, 57, 43, 0.1);
            color: var(--red);
            border: none;
            padding: 4px 12px;
            border-radius: 4px;
            font-size: 10px;
            font-weight: 700;
            cursor: pointer;
            text-transform: uppercase;
            letter-spacing: 0.02em;
            transition: all 0.2s;
        }

        .action-btn:hover {
            background: rgba(192, 57, 43, 0.2);
        }

        /* Domain Tree */
        .domain-tree {
            padding: 16px;
            border-top: 1px solid var(--border-color);
        }

        .domain-node {
            padding: 8px 16px;
            font-size: 11px;
            color: var(--text-secondary);
            cursor: pointer;
        }

        .domain-node:hover {
            color: var(--gold);
        }

        .domain-node.active {
            color: var(--gold);
            font-weight: 600;
        }

        /* Footer */
        .footer-actions {
            padding: 16px 24px;
            border-top: 1px solid var(--border-color);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .pagination-info {
            font-size: 11px;
            color: var(--text-secondary);
        }

        .pagination-btns {
            display: flex;
            gap: 8px;
        }

        .btn-pagination {
            background: transparent;
            border: none;
            color: var(--text-secondary);
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 4px;
            font-size: 11px;
        }

        .btn-pagination:hover {
            color: var(--text-primary);
        }

        /* Modal */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.7);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 100;
        }

        .modal-overlay.active {
            display: flex;
        }

        .modal {
            background: var(--bg-surface);
            border: 1px solid var(--border-color);
            border-radius: 16px;
            width: 600px;
            max-height: 80vh;
            overflow: hidden;
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px 24px;
            border-bottom: 1px solid var(--border-color);
        }

        .modal-title {
            font-size: 16px;
            font-weight: 600;
        }

        .modal-close {
            background: transparent;
            border: none;
            color: var(--text-secondary);
            cursor: pointer;
            font-size: 20px;
        }

        .modal-body {
            padding: 24px;
            max-height: 60vh;
            overflow-y: auto;
        }

        .issue-card {
            padding: 16px;
            background: rgba(0, 0, 0, 0.2);
            border-left: 4px solid var(--red);
            border-radius: 0 8px 8px 0;
            margin-bottom: 16px;
        }

        .issue-card.warning {
            border-left-color: #f59e0b;
        }

        .issue-header {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 8px;
        }

        .issue-severity {
            font-size: 11px;
            font-weight: 700;
        }

        .issue-severity.critical {
            color: var(--red);
        }

        .issue-severity.warning {
            color: #f59e0b;
        }

        .issue-category {
            font-size: 11px;
            color: var(--text-secondary);
        }

        .issue-description {
            font-size: 14px;
            margin-bottom: 12px;
        }

        .issue-snippet {
            background: #000;
            padding: 12px;
            border-radius: 8px;
            font-family: monospace;
            font-size: 12px;
            color: #f87171;
            overflow-x: auto;
            margin-bottom: 12px;
        }

        .issue-hint {
            font-size: 12px;
            font-style: italic;
            color: var(--green);
        }

        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 48px 24px;
            color: var(--text-secondary);
        }

        /* Animations */
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        .fade-in {
            animation: fadeIn 0.3s ease;
        }

        /* Scrollbar */
        ::-webkit-scrollbar {
            width: 4px;
        }

        ::-webkit-scrollbar-track {
            background: #1E1E1E;
        }

        ::-webkit-scrollbar-thumb {
            background: var(--border-color);
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <!-- Sidebar -->
    <aside class="sidebar">
        <div class="sidebar-header">
            <div class="sidebar-logo">MANTIS AGENTIC</div>
            <div class="sidebar-version">v2.4.1-stable</div>
            <span class="version-badge">{{.Version}}</span>
        </div>

        <nav class="nav-section">
            <div class="nav-item active" id="nav-global">
                <span class="nav-icon">📊</span>
                <span class="nav-label">Global Metrics</span>
            </div>

            <div class="nav-item" id="nav-domain-tree" onclick="toggleDomainTree()">
                <span class="nav-icon">📁</span>
                <span class="nav-label">Domain Tree</span>
                <span class="nav-icon" style="margin-left: auto;">▾</span>
            </div>
            <div class="domain-tree" id="domain-tree" style="display: none;"></div>

            <div class="nav-item" id="nav-passed">
                <span class="nav-icon">✓</span>
                <span class="nav-label">Passed Artifacts</span>
            </div>

            <div class="nav-item" id="nav-failed">
                <span class="nav-icon">✗</span>
                <span class="nav-label">Failed Artifacts</span>
            </div>
        </nav>

        <div style="padding: 16px;">
            <button style="width: 100%; padding: 12px; background: var(--gold); color: #1a1a1a; font-weight: bold; border: none; border-radius: 8px; cursor: pointer;">
                Run New Analysis
            </button>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="main-content">
        <!-- Header -->
        <header class="header">
            <div class="search-box">
                <span class="search-icon">🔍</span>
                <input type="text" id="search-input" placeholder="Search files...">
            </div>
            <div class="header-info">
                <span class="last-updated" id="last-updated">Last Updated: {{.Timestamp}}</span>
            </div>
        </header>

        <!-- Dashboard Content -->
        <div class="dashboard-content">
            <!-- KPI Cards -->
            <div class="kpi-grid">
                <div class="kpi-card">
                    <div class="kpi-label">Total Artifacts</div>
                    <div class="kpi-value">{{.TotalArtifacts}}</div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-label">Pass Rate</div>
                    <div class="kpi-value pass">{{printf "%.1f" .PassRate}}%</div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-label">Fail Rate</div>
                    <div class="kpi-value fail">{{printf "%.1f" .FailRate}}%</div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-label">Total LOC</div>
                    <div class="kpi-value">{{.TotalLOC}}</div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-label">Total Tokens</div>
                    <div class="kpi-value highlight">{{.TotalTokens}}</div>
                </div>
                <div class="kpi-card">
                    <div class="kpi-label">Total Time</div>
                    <div class="kpi-value">{{.TotalTime}}</div>
                </div>
            </div>

            <!-- Table -->
            <div class="table-container">
                <div class="table-header">
                    <h2 class="table-title">Analysis Artifacts</h2>
                    <div class="table-actions">
                        <button class="btn-icon">⚙</button>
                        <button class="btn-icon">↓</button>
                    </div>
                </div>

                <table>
                    <thead>
                        <tr>
                            <th>Status</th>
                            <th>Domain</th>
                            <th>File Path</th>
                            <th style="text-align: right;">Time (ms)</th>
                            <th style="text-align: right;">LOC</th>
                            <th style="text-align: center;">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="table-body">
                    </tbody>
                </table>

                <div class="footer-actions">
                    <span class="pagination-info" id="pagination-info">Showing 0 results</span>
                    <div class="pagination-btns">
                        <button class="btn-pagination" id="prev-btn">← Previous</button>
                        <button class="btn-pagination" id="next-btn">Next →</button>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <!-- Issue Modal -->
    <div class="modal-overlay" id="issue-modal">
        <div class="modal">
            <div class="modal-header">
                <h3 class="modal-title" id="modal-title">Issues</h3>
                <button class="modal-close" id="modal-close">×</button>
            </div>
            <div class="modal-body" id="modal-body">
            </div>
        </div>
    </div>

    <!-- Manifest Data (embedded) -->
    <script id="manifest-data" type="application/json">{{.ManifestJSON}}</script>

    <script>
        // Constants
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

        // State
        let manifestData = null;
        let currentFilter = { status: null, domain: null, search: "" };
        let currentPage = 1;
        const pageSize = 50;

        // Initialize
        document.addEventListener('DOMContentLoaded', () => {
            initDashboard();
        });

        function initDashboard() {
            const manifestEl = document.getElementById('manifest-data');
            if (manifestEl) {
                try {
                    manifestData = JSON.parse(manifestEl.textContent);
                    renderDashboard();
                } catch (e) {
                    console.error('Failed to parse manifest:', e);
                }
            }
            setupEventListeners();
        }

        function renderDashboard() {
            if (!manifestData || !manifestData.artifacts) return;

            renderDomainTree();
            renderTable();
        }

        function renderDomainTree() {
            const tree = document.getElementById('domain-tree');
            if (!tree) return;

            const domains = [...new Set(manifestData.artifacts.map(a => a.domain))].sort();

            tree.innerHTML = domains.map(d =>
                '<div class="domain-node ' + (currentFilter.domain === d ? 'active' : '') + '" onclick="filterByDomain(\'' + d + '\')">' + d + '</div>'
            ).join('');
        }

        function renderTable() {
            const tbody = document.getElementById('table-body');
            if (!tbody) return;

            let filtered = manifestData.artifacts;

            // Apply filters
            if (currentFilter.status !== null) {
                filtered = filtered.filter(a => a.passed === currentFilter.status);
            }
            if (currentFilter.domain !== null) {
                filtered = filtered.filter(a => a.domain === currentFilter.domain);
            }
            if (currentFilter.search) {
                const search = currentFilter.search.toLowerCase();
                filtered = filtered.filter(a => a.file.toLowerCase().includes(search));
            }

            // Pagination
            const start = (currentPage - 1) * pageSize;
            const end = start + pageSize;
            const pageData = filtered.slice(start, end);

            if (pageData.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" class="empty-state">No artifacts found</td></tr>';
            } else {
                tbody.innerHTML = pageData.map((a, idx) => {
                    const globalIndex = manifestData.artifacts.indexOf(a);
                    return '<tr class="fade-in" style="animation-delay: ' + (idx * 20) + 'ms">' +
                        '<td><span class="status-badge ' + (a.passed ? 'pass' : 'fail') + '">' +
                        (a.passed ? '✓ PASS' : '✗ FAIL') + '</span></td>' +
                        '<td class="domain-tag">' + a.domain + '</td>' +
                        '<td class="file-path" title="' + a.file + '">' + a.file + '</td>' +
                        '<td class="numeric-cell">' + a.time_ms + '</td>' +
                        '<td class="numeric-cell">' + a.loc + '</td>' +
                        '<td style="text-align: center;">' +
                        (!a.passed && a.issues && a.issues.length > 0 ?
                            '<button class="action-btn" onclick="openModal(' + globalIndex + ')">VIEW ISSUES</button>' :
                            '<span style="color: var(--green); opacity: 0.5;">OK</span>') +
                        '</td></tr>';
                }).join('');
            }

            // Update pagination info
            const paginationInfo = document.getElementById('pagination-info');
            if (paginationInfo) {
                paginationInfo.textContent = 'Showing ' + (start + 1) + '-' + Math.min(end, filtered.length) + ' of ' + filtered.length + ' results';
            }
        }

        function setupEventListeners() {
            // Navigation
            document.getElementById('nav-global')?.addEventListener('click', () => {
                currentFilter = { status: null, domain: null, search: "" };
                currentPage = 1;
                updateNavActive('nav-global');
                renderTable();
            });

            document.getElementById('nav-passed')?.addEventListener('click', () => {
                currentFilter.status = true;
                currentFilter.domain = null;
                currentPage = 1;
                updateNavActive('nav-passed');
                renderTable();
            });

            document.getElementById('nav-failed')?.addEventListener('click', () => {
                currentFilter.status = false;
                currentFilter.domain = null;
                currentPage = 1;
                updateNavActive('nav-failed');
                renderTable();
            });

            // Search
            document.getElementById('search-input')?.addEventListener('input', (e) => {
                currentFilter.search = e.target.value;
                currentPage = 1;
                renderTable();
            });

            // Modal close
            document.getElementById('modal-close')?.addEventListener('click', () => {
                document.getElementById('issue-modal')?.classList.remove('active');
            });

            // Click outside modal to close
            document.getElementById('issue-modal')?.addEventListener('click', (e) => {
                if (e.target.id === 'issue-modal') {
                    e.target.classList.remove('active');
                }
            });

            // Pagination
            document.getElementById('prev-btn')?.addEventListener('click', () => {
                if (currentPage > 1) {
                    currentPage--;
                    renderTable();
                }
            });

            document.getElementById('next-btn')?.addEventListener('click', () => {
                let filtered = manifestData.artifacts;
                if (currentFilter.status !== null) {
                    filtered = filtered.filter(a => a.passed === currentFilter.status);
                }
                if (currentFilter.domain !== null) {
                    filtered = filtered.filter(a => a.domain === currentFilter.domain);
                }
                if (Math.ceil(filtered.length / pageSize) > currentPage) {
                    currentPage++;
                    renderTable();
                }
            });
        }

        function updateNavActive(activeId) {
            ['nav-global', 'nav-domain-tree', 'nav-passed', 'nav-failed'].forEach(id => {
                const el = document.getElementById(id);
                if (el) {
                    el.classList.toggle('active', id === activeId);
                }
            });
        }

        function toggleDomainTree() {
            const tree = document.getElementById('domain-tree');
            if (tree) {
                tree.style.display = tree.style.display === 'none' ? 'block' : 'none';
            }
        }

        function filterByDomain(domain) {
            currentFilter.domain = domain;
            currentFilter.status = null;
            currentPage = 1;
            updateNavActive('nav-domain-tree');
            renderTable();
        }

        function openModal(index) {
            const artifact = manifestData.artifacts[index];
            const modalTitle = document.getElementById('modal-title');
            const modalBody = document.getElementById('modal-body');
            const modal = document.getElementById('issue-modal');

            if (!artifact || !artifact.issues) return;

            modalTitle.textContent = 'Issues in: ' + artifact.file.split('/').pop();
            modalBody.innerHTML = artifact.issues.map(issue => {
       let hint = "Revisar logs y normativas MANTIS C1-C8/V1-V3.";
                Object.keys(FIX_HINTS).forEach(key => {
                    if ((issue.category && issue.category.includes(key)) ||
                        (issue.description && issue.description.includes(key))) {
                        hint = FIX_HINTS[key];
                    }
                });

                const isWarning = issue.severity === 'WARNING' || issue.severity === 'HIGH';
                const severityClass = isWarning ? 'warning' : 'critical';

                return '<div class="issue-card ' + (isWarning ? 'warning' : '') + '">' +
                    '<div class="issue-header">' +
                    '<span class="issue-severity ' + severityClass + '">[' + issue.severity + ']</span>' +
                    '<span class="issue-category">' + (issue.category || issue.constraint) + '</span>' +
                    '</div>' +
                    '<div class="issue-description">' + issue.description + '</div>' +
                    (issue.snippet ? '<pre class="issue-snippet"><code>' + escapeHtml(issue.snippet) + '</code></pre>' : '') +
                    '<div class="issue-hint">💡 Hint: ' + hint + '</div>' +
                    '</div>';
            }).join('');

            modal?.classList.add('active');
        }

        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
    </script>
</body>
</html>
`))
