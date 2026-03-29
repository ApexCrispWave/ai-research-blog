const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const TASKS_PATH = path.join('/Users/openclaw/.openclaw/workspace', 'tasks.json');

function loadTasks() {
  try {
    return JSON.parse(fs.readFileSync(TASKS_PATH, 'utf8'));
  } catch (e) {
    return { tasks: [] };
  }
}

function statusEmoji(status) {
  const map = {
    done: '✅', 'in-progress': '🔄', pending: '⏳',
    blocked: '🚫', failed: '❌'
  };
  return map[status] || '❓';
}

function priorityBadge(p) {
  const map = {
    critical: '<span class="badge critical">CRITICAL</span>',
    high: '<span class="badge high">HIGH</span>',
    medium: '<span class="badge medium">MEDIUM</span>',
    low: '<span class="badge low">LOW</span>'
  };
  return map[p] || p;
}

function escapeHtml(s) {
  return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

function buildPage() {
  const data = loadTasks();
  const tasks = data.tasks || [];
  const done = tasks.filter(t => t.status === 'done').length;
  const active = tasks.filter(t => t.status === 'in-progress').length;
  const pending = tasks.filter(t => t.status === 'pending').length;
  const blocked = tasks.filter(t => t.status === 'blocked').length;
  const execReady = tasks.filter(t => t.execution_ready === true).length;
  const githubMissing = tasks.filter(t => t.github_required === true && !(t.repo_name || t.repo_url)).length;

  const order = ['in-progress', 'blocked', 'pending', 'done', 'failed'];
  const sorted = [...tasks].sort((a, b) => order.indexOf(a.status) - order.indexOf(b.status));

  const rows = sorted.map(t => `
    <tr class="status-${t.status}">
      <td>${statusEmoji(t.status)} ${escapeHtml(t.status)}</td>
      <td><strong>${escapeHtml(t.id)}</strong></td>
      <td>${escapeHtml(t.title)}</td>
      <td>${priorityBadge(t.priority)}</td>
      <td>${escapeHtml(t.assignee)}</td>
      <td>${t.execution_ready === true ? '<span class="ok">ready</span>' : '<span class="bad">blocked</span>'}</td>
      <td>${escapeHtml(t.repo_name || t.repo_url || '-')}<div class="repo-status">${escapeHtml(t.repo_status || (t.github_required ? 'missing' : 'not-required'))}</div></td>
      <td class="notes">${escapeHtml(t.notes || '').substring(0, 120)}${(t.notes||'').length > 120 ? '…' : ''}</td>
    </tr>`).join('\n');

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CrispWave Dashboard</title>
<meta http-equiv="refresh" content="30">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0d1117; color: #c9d1d9; padding: 24px; }
  h1 { color: #58a6ff; margin-bottom: 4px; font-size: 1.8em; }
  .subtitle { color: #8b949e; margin-bottom: 24px; }
  .stats { display: flex; gap: 16px; margin-bottom: 24px; flex-wrap: wrap; }
  .stat { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 16px 24px; min-width: 120px; }
  .stat .num { font-size: 2em; font-weight: bold; }
  .stat .label { color: #8b949e; font-size: 0.85em; }
  .stat.done .num { color: #3fb950; }
  .stat.active .num { color: #d29922; }
  .stat.pending .num { color: #58a6ff; }
  .stat.blocked .num { color: #f85149; }
  .stat.exec .num { color: #3fb950; }
  .stat.repo .num { color: #ff7b72; }
  table { width: 100%; border-collapse: collapse; background: #161b22; border-radius: 8px; overflow: hidden; }
  th { background: #21262d; color: #8b949e; text-align: left; padding: 12px 16px; font-size: 0.85em; text-transform: uppercase; letter-spacing: 0.5px; }
  td { padding: 10px 16px; border-top: 1px solid #21262d; font-size: 0.9em; }
  tr:hover { background: #1c2128; }
  .badge { padding: 2px 8px; border-radius: 10px; font-size: 0.75em; font-weight: 600; }
  .badge.critical { background: #f8514920; color: #f85149; }
  .badge.high { background: #d2992220; color: #d29922; }
  .badge.medium { background: #58a6ff20; color: #58a6ff; }
  .badge.low { background: #3fb95020; color: #3fb950; }
  .notes { color: #8b949e; max-width: 300px; }
  .ok { color: #3fb950; font-weight: 600; }
  .bad { color: #f85149; font-weight: 600; }
  .repo-status { color: #8b949e; font-size: 0.8em; margin-top: 2px; }
  .status-done { opacity: 0.6; }
  .footer { margin-top: 24px; color: #484f58; font-size: 0.8em; }
</style>
</head>
<body>
<h1>🚀 CrispWave Dashboard</h1>
<p class="subtitle">Internal Task Tracker — Auto-refreshes every 30s &nbsp;|&nbsp; <a href="/tokens" style="color:#58a6ff;text-decoration:none;font-size:0.85em;">💸 Token Usage →</a></p>
<div class="stats">
  <div class="stat done"><div class="num">${done}</div><div class="label">Done</div></div>
  <div class="stat active"><div class="num">${active}</div><div class="label">In Progress</div></div>
  <div class="stat pending"><div class="num">${pending}</div><div class="label">Pending</div></div>
  <div class="stat blocked"><div class="num">${blocked}</div><div class="label">Blocked</div></div>
  <div class="stat exec"><div class="num">${execReady}</div><div class="label">Execution Ready</div></div>
  <div class="stat repo"><div class="num">${githubMissing}</div><div class="label">GitHub Missing</div></div>
</div>
<table>
<thead><tr><th>Status</th><th>ID</th><th>Title</th><th>Priority</th><th>Assignee</th><th>Exec</th><th>GitHub Repo</th><th>Notes</th></tr></thead>
<tbody>${rows}</tbody>
</table>
<div class="footer">Last updated: ${new Date().toISOString()} | Total tasks: ${tasks.length}</div>
</body>
</html>`;
}

// ─── Token Dashboard ──────────────────────────────────────────────────────────

const TOKEN_DATA_PATH = path.join('/Users/openclaw/.openclaw/workspace', 'token-usage.json');

/** Load token usage data from disk */
function loadTokenData() {
  try {
    return JSON.parse(fs.readFileSync(TOKEN_DATA_PATH, 'utf8'));
  } catch (e) {
    return null;
  }
}

/** Format a cost number as a dollar string */
function formatCost(n) {
  if (typeof n !== 'number') return '$0.0000';
  return '$' + n.toFixed(4);
}

/** Format a large token count with commas */
function formatTokens(n) {
  if (typeof n !== 'number') return '0';
  return n.toLocaleString();
}

/** Get today's date as YYYY-MM-DD in local time */
function todayStr() {
  const d = new Date();
  return d.toISOString().substring(0, 10);
}

/** Get the Monday of the current week as YYYY-MM-DD */
function weekStartStr() {
  const d = new Date();
  const day = d.getDay(); // 0=Sun
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(d.setDate(diff));
  return monday.toISOString().substring(0, 10);
}

/** Get the first day of the current month as YYYY-MM-DD */
function monthStartStr() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-01`;
}

/** Build the /tokens HTML page */
function buildTokenPage() {
  const data = loadTokenData();

  const today   = todayStr();
  const weekStart  = weekStartStr();
  const monthStart = monthStartStr();

  // Compute summary metrics from byDate entries
  let todayCost = 0, weekCost = 0, monthCost = 0, todayTokens = 0;
  if (data && data.byDate) {
    for (const entry of data.byDate) {
      if (entry.date === today) {
        todayCost   += entry.cost || 0;
        todayTokens += (entry.inputTokens || 0) + (entry.outputTokens || 0);
      }
      if (entry.date >= weekStart)  weekCost  += entry.cost || 0;
      if (entry.date >= monthStart) monthCost += entry.cost || 0;
    }
  }

  // Model breakdown table rows
  let modelRows = '';
  const totalCost = data?.summary?.totalCost || 0;
  if (data && data.byModel && data.byModel.length) {
    for (const m of data.byModel) {
      const pct = totalCost > 0 ? ((m.cost / totalCost) * 100).toFixed(1) : '0.0';
      modelRows += `
        <tr>
          <td><code>${escapeHtml(m.model)}</code></td>
          <td>${formatTokens(m.inputTokens)}</td>
          <td>${formatTokens(m.outputTokens)}</td>
          <td>${formatCost(m.cost)}</td>
          <td>
            <div class="pct-bar-wrap">
              <div class="pct-bar" style="width:${Math.min(parseFloat(pct), 100)}%"></div>
              <span>${pct}%</span>
            </div>
          </td>
        </tr>`;
    }
  } else {
    modelRows = '<tr><td colspan="5" class="empty-msg">No model data available</td></tr>';
  }

  // Session type table rows
  let sessionRows = '';
  if (data && data.bySessionType && data.bySessionType.length) {
    for (const s of data.bySessionType) {
      const total = (s.inputTokens || 0) + (s.outputTokens || 0);
      sessionRows += `
        <tr>
          <td><span class="type-badge type-${escapeHtml(s.type)}">${escapeHtml(s.type)}</span></td>
          <td>${formatTokens(s.inputTokens)}</td>
          <td>${formatTokens(s.outputTokens)}</td>
          <td>${formatTokens(total)}</td>
          <td>${formatCost(s.cost)}</td>
        </tr>`;
    }
  } else {
    sessionRows = '<tr><td colspan="5" class="empty-msg">No session data available</td></tr>';
  }

  const noDataBanner = !data
    ? `<div class="no-data-banner">⚠️ No data yet — run <code>node scripts/token-tracker.js</code> to generate usage data</div>`
    : '';

  const lastUpdated = data?.generatedAt
    ? `Data as of: ${new Date(data.generatedAt).toLocaleString()}`
    : 'No data generated yet';

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CrispWave Token Dashboard</title>
<meta http-equiv="refresh" content="60">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0d1117; color: #c9d1d9; padding: 24px; }
  h1 { color: #58a6ff; margin-bottom: 4px; font-size: 1.8em; }
  .subtitle { color: #8b949e; margin-bottom: 16px; }
  .nav { margin-bottom: 24px; }
  .nav a { color: #58a6ff; text-decoration: none; font-size: 0.9em; margin-right: 16px; }
  .nav a:hover { text-decoration: underline; }
  .no-data-banner { background: #2d1a00; border: 1px solid #d29922; border-radius: 8px; padding: 16px; margin-bottom: 24px; color: #d29922; font-size: 0.95em; }
  .no-data-banner code { background: #1c1f26; padding: 2px 6px; border-radius: 4px; font-size: 0.9em; }
  .stats { display: flex; gap: 16px; margin-bottom: 28px; flex-wrap: wrap; }
  .stat { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 16px 24px; min-width: 140px; }
  .stat .num { font-size: 1.8em; font-weight: bold; color: #58a6ff; }
  .stat .label { color: #8b949e; font-size: 0.82em; margin-top: 4px; text-transform: uppercase; letter-spacing: 0.5px; }
  h2 { color: #e6edf3; margin: 24px 0 12px; font-size: 1.1em; border-bottom: 1px solid #21262d; padding-bottom: 8px; }
  table { width: 100%; border-collapse: collapse; background: #161b22; border-radius: 8px; overflow: hidden; margin-bottom: 28px; }
  th { background: #21262d; color: #8b949e; text-align: left; padding: 10px 16px; font-size: 0.82em; text-transform: uppercase; letter-spacing: 0.5px; }
  td { padding: 10px 16px; border-top: 1px solid #21262d; font-size: 0.9em; }
  tr:hover td { background: #1c2128; }
  code { background: #21262d; padding: 2px 6px; border-radius: 4px; font-size: 0.85em; color: #79c0ff; }
  .empty-msg { color: #484f58; text-align: center; padding: 24px; }
  /* Percentage bar */
  .pct-bar-wrap { display: flex; align-items: center; gap: 8px; }
  .pct-bar-wrap span { font-size: 0.85em; color: #8b949e; min-width: 40px; }
  .pct-bar { height: 8px; background: #58a6ff; border-radius: 4px; min-width: 2px; transition: width 0.3s; }
  /* Session type badges */
  .type-badge { display: inline-block; padding: 2px 10px; border-radius: 10px; font-size: 0.8em; font-weight: 600; text-transform: uppercase; }
  .type-heartbeat { background: #3fb95020; color: #3fb950; }
  .type-cron      { background: #d2992220; color: #d29922; }
  .type-main      { background: #58a6ff20; color: #58a6ff; }
  .type-subagent  { background: #bc8cff20; color: #bc8cff; }
  .type-discord   { background: #5865f220; color: #8891f2; }
  .footer { margin-top: 16px; color: #484f58; font-size: 0.8em; }
</style>
</head>
<body>
<h1>💸 Token Usage Dashboard</h1>
<p class="subtitle">CrispWave API cost tracker — Auto-refreshes every 60s</p>
<div class="nav">
  <a href="/">← Task Dashboard</a>
  <a href="/api/tokens">Raw JSON ↗</a>
</div>

${noDataBanner}

<div class="stats">
  <div class="stat"><div class="num">${formatCost(todayCost)}</div><div class="label">Today's Cost</div></div>
  <div class="stat"><div class="num">${formatCost(weekCost)}</div><div class="label">This Week</div></div>
  <div class="stat"><div class="num">${formatCost(monthCost)}</div><div class="label">This Month</div></div>
  <div class="stat"><div class="num">${formatTokens(todayTokens)}</div><div class="label">Tokens Today</div></div>
</div>

<h2>📊 Model Breakdown</h2>
<table>
<thead><tr><th>Model</th><th>Input Tokens</th><th>Output Tokens</th><th>Cost</th><th>% of Total</th></tr></thead>
<tbody>${modelRows}</tbody>
</table>

<h2>🗂️ Session Types</h2>
<table>
<thead><tr><th>Type</th><th>Input Tokens</th><th>Output Tokens</th><th>Total Tokens</th><th>Cost</th></tr></thead>
<tbody>${sessionRows}</tbody>
</table>

<div class="footer">${lastUpdated} | <a href="/tokens" style="color:#484f58">Refresh</a></div>
</body>
</html>`;
}

// ─── HTTP Server ───────────────────────────────────────────────────────────────

const server = http.createServer((req, res) => {
  // Strip query strings for routing
  const url = req.url.split('?')[0];

  if (url === '/api/tasks') {
    // Existing: task list API
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(loadTasks()));
  } else if (url === '/api/tokens') {
    // NEW: raw token usage JSON
    const data = loadTokenData();
    if (!data) {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'No token data found. Run: node scripts/token-tracker.js' }));
    } else {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(data));
    }
  } else if (url === '/tokens') {
    // NEW: token usage HTML dashboard
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(buildTokenPage());
  } else if (url === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('ok');
  } else {
    // Default: task dashboard (with nav link to /tokens)
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(buildPage());
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`CrispWave Dashboard running on http://0.0.0.0:${PORT}`);
});
