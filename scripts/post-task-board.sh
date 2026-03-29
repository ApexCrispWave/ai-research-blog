#!/bin/bash
# post-task-board.sh — Posts task board + hardware stats + activity delta to Discord #task-board

CONFIG_FILE="/Users/openclaw/.openclaw/openclaw.json"
TASKS_FILE="/Users/openclaw/.openclaw/workspace/tasks.json"
STATE_FILE="/Users/openclaw/.openclaw/workspace/memory/task-board-state.json"
CHANNEL_ID="1484408539974860871"

# Get Discord bot token
TOKEN=$(python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(c['channels']['discord']['accounts']['default']['token'])")

# Build full message
MESSAGE=$(python3 << 'PYEOF'
import json, subprocess, os, re
from datetime import datetime, timezone

TASKS_FILE = '/Users/openclaw/.openclaw/workspace/tasks.json'
STATE_FILE = '/Users/openclaw/.openclaw/workspace/memory/task-board-state.json'

now = datetime.now()
now_str = now.strftime('%Y-%m-%d %I:%M %p PT')

with open(TASKS_FILE) as f:
    data = json.load(f)
tasks = data.get('tasks', [])

# Load previous state
prev_state = {}
if os.path.exists(STATE_FILE):
    try:
        with open(STATE_FILE) as f:
            prev_state = json.load(f)
    except:
        prev_state = {}

prev_statuses = prev_state.get('statuses', {})
prev_in_progress = set(prev_state.get('in_progress', []))

# Current status map
curr_statuses = {t['id']: t['status'] for t in tasks}
curr_in_progress = set(t['id'] for t in tasks if t['status'] == 'in-progress')

# Detect activity since last run
newly_started = []   # was pending/blocked, now in-progress
stalled = []         # was in-progress, now blocked/failed
restarted = []       # was blocked/failed, now in-progress again
just_done = []       # was in-progress, now done

task_map = {t['id']: t for t in tasks}

for tid, curr_s in curr_statuses.items():
    prev_s = prev_statuses.get(tid)
    if prev_s is None:
        continue
    t = task_map[tid]
    label = f"**{tid}** — {t['title'][:60]}"
    if prev_s in ('pending', 'blocked', 'deferred') and curr_s == 'in-progress':
        if prev_s == 'blocked':
            restarted.append(label)
        else:
            newly_started.append(label)
    elif prev_s == 'in-progress' and curr_s in ('blocked', 'failed'):
        stalled.append(label)
    elif prev_s == 'in-progress' and curr_s == 'done':
        just_done.append(label)

# Save current state
os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
with open(STATE_FILE, 'w') as f:
    json.dump({
        'statuses': curr_statuses,
        'in_progress': list(curr_in_progress),
        'lastRun': now.isoformat()
    }, f, indent=2)

# Build message
lines = [f"🚀 **CrispWave Task Board** — {now_str}", ""]

in_progress = [t for t in tasks if t['status'] == 'in-progress']
pending = [t for t in tasks if t['status'] == 'pending']
blocked = [t for t in tasks if t['status'] == 'blocked']
done = [t for t in tasks if t['status'] == 'done']

if in_progress:
    lines.append("**🔄 IN PROGRESS**")
    for t in in_progress:
        repo = t.get('repo_name') or t.get('repo_url') or '-'
        repo_status = t.get('repo_status') or ('missing' if t.get('github_required') else 'not-required')
        exec_state = 'ready' if t.get('execution_ready') else 'blocked'
        lines.append(f"🔄 **{t['id']}** — {t['title']} · exec:{exec_state} · repo:{repo} [{repo_status}]")
    lines.append("")

if pending:
    lines.append("**⏳ PENDING**")
    for t in pending:
        pri = t.get('priority', '')
        pri_tag = f" *({pri})*" if pri in ['critical', 'high'] else ""
        repo = t.get('repo_name') or t.get('repo_url') or '-'
        repo_status = t.get('repo_status') or ('missing' if t.get('github_required') else 'not-required')
        exec_state = 'ready' if t.get('execution_ready') else 'blocked'
        lines.append(f"⏳ **{t['id']}** — {t['title']}{pri_tag} · exec:{exec_state} · repo:{repo} [{repo_status}]")
    lines.append("")

if blocked:
    lines.append("**🚫 BLOCKED**")
    for t in blocked:
        repo = t.get('repo_name') or t.get('repo_url') or '-'
        repo_status = t.get('repo_status') or ('missing' if t.get('github_required') else 'not-required')
        exec_state = 'ready' if t.get('execution_ready') else 'blocked'
        lines.append(f"🚫 **{t['id']}** — {t['title']} · exec:{exec_state} · repo:{repo} [{repo_status}]")
    lines.append("")

github_missing = sum(1 for t in tasks if t.get('github_required') and not (t.get('repo_name') or t.get('repo_url')))
exec_ready = sum(1 for t in tasks if t.get('execution_ready'))
lines.append(f"**Summary: {len(done)} done | {len(in_progress)} in-progress | {len(pending)} pending | {len(blocked)} blocked | {exec_ready} exec-ready | {github_missing} missing GitHub**")

# Activity delta section
has_activity = any([newly_started, restarted, stalled, just_done])
if has_activity:
    lines.append("")
    lines.append("─────────────────────────")
    lines.append("⚡ **Heartbeat Activity**")
    if just_done:
        lines.append("✅ Completed:")
        for item in just_done:
            lines.append(f"  • {item}")
    if newly_started:
        lines.append("▶️ Newly started:")
        for item in newly_started:
            lines.append(f"  • {item}")
    if restarted:
        lines.append("🔁 Restarted (was blocked):")
        for item in restarted:
            lines.append(f"  • {item}")
    if stalled:
        lines.append("⚠️ Stalled/blocked:")
        for item in stalled:
            lines.append(f"  • {item}")
else:
    lines.append("")
    lines.append("─────────────────────────")
    lines.append("⚡ **Heartbeat Activity:** No changes since last run")

# Hardware stats
lines.append("")
lines.append("─────────────────────────")
lines.append("🖥️ **Hardware** (Mac Mini M4 Pro)")

try:
    cpu_out = subprocess.check_output(
        "top -l 1 -n 0 | grep 'CPU usage' | awk '{print $3}' | tr -d '%'",
        shell=True, text=True).strip()
    cpu_user = float(cpu_out) if cpu_out else 0
    cpu_sys_out = subprocess.check_output(
        "top -l 1 -n 0 | grep 'CPU usage' | awk '{print $5}' | tr -d '%'",
        shell=True, text=True).strip()
    cpu_sys = float(cpu_sys_out) if cpu_sys_out else 0
    lines.append(f"🔲 CPU: {cpu_user + cpu_sys:.1f}% used")
except:
    lines.append("🔲 CPU: unavailable")

try:
    vm = subprocess.check_output("vm_stat", shell=True, text=True)
    page_size = 16384
    pages = {}
    for line in vm.split('\n'):
        m = re.match(r'^(.+?):\s+(\d+)', line)
        if m:
            pages[m.group(1).strip()] = int(m.group(2))
    used_gb = (pages.get('Pages active',0) + pages.get('Pages wired down',0) + pages.get('Pages occupied by compressor',0)) * page_size / (1024**3)
    pct = (used_gb / 24.0) * 100
    lines.append(f"🧠 RAM: {used_gb:.1f} / 24 GB ({pct:.0f}%)")
except:
    lines.append("🧠 RAM: unavailable")

try:
    df_out = subprocess.check_output("df -h / | tail -1", shell=True, text=True).strip().split()
    lines.append(f"💾 Storage: {df_out[2]} used / {df_out[1]} total ({df_out[3]} free)")
except:
    lines.append("💾 Storage: unavailable")

try:
    models_out = subprocess.check_output("ollama ps 2>/dev/null", shell=True, text=True).strip()
    model_lines = [l for l in models_out.split('\n') if l and 'NAME' not in l]
    if model_lines:
        lines.append(f"🤖 Models: {', '.join(l.split()[0] for l in model_lines)}")
    else:
        lines.append("🤖 Models: none loaded (idle)")
except:
    lines.append("🤖 Models: unavailable")

print('\n'.join(lines))
PYEOF
)

# Escape and post
ESCAPED=$(python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$MESSAGE")

curl -s -X POST "https://discord.com/api/v10/channels/${CHANNEL_ID}/messages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bot ${TOKEN}" \
  -d "{\"content\": ${ESCAPED}}" > /dev/null

echo "Task board posted at $(date)"
