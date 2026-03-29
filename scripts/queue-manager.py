#!/usr/bin/env python3
"""
CrispWave Queue Manager
Reads tasks.json + queue.json, reports status, and manages agent slot discipline.

Usage:
  python3 queue-manager.py status        — show full queue status
  python3 queue-manager.py next          — return next task to start (respects slots)
  python3 queue-manager.py slots         — show agent slot utilization
  python3 queue-manager.py check-stalls  — flag tasks in-progress > 30 min with no update
  python3 queue-manager.py add-slot <model> <task_id> <session_id>
  python3 queue-manager.py free-slot <model> <task_id>
"""

import json, sys
from datetime import datetime, timezone
from pathlib import Path

WORKSPACE = Path("/Users/openclaw/.openclaw/workspace")
TASKS_FILE = WORKSPACE / "tasks.json"
QUEUE_FILE = WORKSPACE / "queue.json"


def load():
    with open(TASKS_FILE) as f:
        tasks_data = json.load(f)
    with open(QUEUE_FILE) as f:
        queue_data = json.load(f)
    return tasks_data, queue_data


def save_queue(queue_data):
    with open(QUEUE_FILE, 'w') as f:
        json.dump(queue_data, f, indent=2)


def get_slot_usage(queue_data):
    usage = {}
    for model, cfg in queue_data['agentSlots']['models'].items():
        active = [a for a in cfg.get('active', []) if a]
        usage[model] = (len(active), cfg['limit'])
    return usage


def can_start_agent(model, queue_data):
    models = queue_data['agentSlots']['models']
    if model not in models:
        model = "anthropic/claude-sonnet-4-5"
    cfg = models[model]
    active = [a for a in cfg.get('active', []) if a]
    return len(active) < cfg['limit']


def total_active(queue_data):
    return sum(len([a for a in cfg.get('active', []) if a]) for cfg in queue_data['agentSlots']['models'].values())


def spec_state(task):
    spec = task.get('spec') or {}
    if spec.get('ready') is True:
        return 'ready'
    return spec.get('completeness', 'missing')


def repo_summary(task):
    repo_name = task.get('repo_name') or '-'
    repo_status = task.get('repo_status') or ('required-missing' if task.get('github_required') else 'not-required')
    return f'{repo_name} ({repo_status})'


def ready_for_delegation(task):
    if 'execution_ready' in task:
        return task.get('execution_ready') is True
    spec = task.get('spec') or {}
    if spec.get('ready') is not True:
        return False
    if task.get('github_required'):
        return bool(task.get('repo_name') or task.get('repo_url')) and (task.get('repo_status') in {'linked', 'ready', 'active'})
    return True


def execution_block_reason(task):
    spec = task.get('spec') or {}
    if spec.get('ready') is not True:
        return f'spec:{spec_state(task)}'
    if task.get('github_required'):
        if not (task.get('repo_name') or task.get('repo_url')):
            return 'github:missing-repo'
        if task.get('repo_status') not in {'linked', 'ready', 'active'}:
            return f'github:{task.get("repo_status") or "missing-status"}'
    return 'ready'


def get_next_task(tasks_data, queue_data):
    tasks = tasks_data.get('tasks', [])
    priority_order = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3}

    pending = [t for t in tasks if t.get('status') == 'pending' and ready_for_delegation(t)]
    pending.sort(key=lambda t: (priority_order.get(t.get('priority', 'low'), 9), t.get('createdAt', '')))

    for task in pending:
        model = task.get('model', 'anthropic/claude-sonnet-4-5')
        if can_start_agent(model, queue_data):
            return task
    return None


def status(tasks_data, queue_data):
    tasks = tasks_data.get('tasks', [])
    statuses = {}
    for t in tasks:
        s = t.get('status', '?')
        statuses[s] = statuses.get(s, 0) + 1

    execution_ready = len([t for t in tasks if ready_for_delegation(t)])
    execution_blocked = len([t for t in tasks if not ready_for_delegation(t)])
    pending_unready = [t for t in tasks if t.get('status') == 'pending' and not ready_for_delegation(t)]

    print("=" * 60)
    print("CRISPWAVE TASK QUEUE STATUS")
    print("=" * 60)
    print(f"Total tasks: {len(tasks)}")
    for s, count in sorted(statuses.items()):
        print(f"  {s:15} {count}")
    print(f"  {'exec-ready':15} {execution_ready}")
    print(f"  {'exec-blocked':15} {execution_blocked}")
    print()

    print("AGENT SLOTS")
    print("-" * 40)
    usage = get_slot_usage(queue_data)
    for model, (used, limit) in usage.items():
        bar = "█" * used + "░" * (limit - used)
        short = model.split('/')[-1]
        print(f"  {short:30} {bar} {used}/{limit}")
    print(f"  Total active: {total_active(queue_data)}")
    print()

    active = [t for t in tasks if t.get('status') == 'in-progress']
    if active:
        print("IN PROGRESS")
        print("-" * 40)
        for t in active:
            print(f"  [{t.get('priority','?'):8}] {t['id']} — {t['title'][:45]} · {execution_block_reason(t)} · repo:{repo_summary(t)}")
    print()

    pending = [t for t in tasks if t.get('status') == 'pending' and ready_for_delegation(t)]
    priority_order = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3}
    pending.sort(key=lambda t: (priority_order.get(t.get('priority','low'), 9), t.get('createdAt','')))
    if pending:
        print("READY PENDING QUEUE")
        print("-" * 40)
        for i, t in enumerate(pending):
            print(f"  {i+1}. [{t.get('priority','?'):8}] {t['id']} — {t['title'][:46]} · repo:{repo_summary(t)}")
    print()

    if pending_unready:
        print("EXECUTION-BLOCKED TASKS (not ready for delegation)")
        print("-" * 40)
        for t in pending_unready:
            print(f"  {t['id']} — {t['title'][:44]} · {execution_block_reason(t)} · repo:{repo_summary(t)}")
        print()

    blocked = [t for t in tasks if t.get('status') == 'blocked']
    if blocked:
        print(f"BLOCKED ({len(blocked)} tasks — need Ronald)")
        print("-" * 40)
        for t in blocked:
            print(f"  {t['id']} — {t['title'][:60]} · repo:{repo_summary(t)}")
    print()

    next_task = get_next_task(tasks_data, queue_data)
    if next_task:
        print(f"NEXT TO START: {next_task['id']} — {next_task['title'][:55]} · repo:{repo_summary(next_task)}")
    else:
        if pending:
            print("NEXT TO START: None — all model slots full")
        elif pending_unready:
            print("NEXT TO START: None — pending tasks exist but are execution-blocked (spec and/or GitHub repo missing)")
        else:
            print("NEXT TO START: None — queue empty")
    print("=" * 60)


def add_slot(model, task_id, session_id, queue_data):
    if model not in queue_data['agentSlots']['models']:
        print(f"Unknown model: {model}")
        return
    entry = {"task_id": task_id, "session_id": session_id, "startedAt": datetime.now(timezone.utc).isoformat()}
    queue_data['agentSlots']['models'][model]['active'].append(entry)
    queue_data['_updated'] = datetime.now(timezone.utc).isoformat()
    save_queue(queue_data)
    print(f"Slot added: {model} / {task_id}")


def free_slot(model, task_id, queue_data):
    if model not in queue_data['agentSlots']['models']:
        print(f"Unknown model: {model}")
        return
    before = len(queue_data['agentSlots']['models'][model]['active'])
    queue_data['agentSlots']['models'][model]['active'] = [
        a for a in queue_data['agentSlots']['models'][model]['active']
        if a.get('task_id') != task_id
    ]
    after = len(queue_data['agentSlots']['models'][model]['active'])
    queue_data['_updated'] = datetime.now(timezone.utc).isoformat()
    save_queue(queue_data)
    print(f"Freed {before-after} slot(s) for {task_id} on {model}")


def check_stalls(tasks_data, queue_data):
    tasks = tasks_data.get('tasks', [])
    now = datetime.now(timezone.utc)
    stalls = []
    for t in tasks:
        if t.get('status') == 'in-progress':
            started = t.get('startedAt') or t.get('updatedAt') or t.get('createdAt')
            if started:
                try:
                    dt = datetime.fromisoformat(started.replace('Z','+00:00'))
                    age_min = (now - dt).total_seconds() / 60
                    if age_min > 30:
                        stalls.append((t, age_min))
                except Exception:
                    pass
    if stalls:
        print(f"STALLED TASKS ({len(stalls)}):")
        for t, age in stalls:
            print(f"  {t['id']} — {t['title'][:48]} ({age:.0f} min) · {execution_block_reason(t)} · repo:{repo_summary(t)}")
    else:
        print("No stalled tasks detected.")
    return stalls


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'status'
    tasks_data, queue_data = load()

    if cmd == 'status':
        status(tasks_data, queue_data)
    elif cmd == 'next':
        t = get_next_task(tasks_data, queue_data)
        print(json.dumps(t) if t else 'null')
    elif cmd == 'slots':
        usage = get_slot_usage(queue_data)
        for model, (used, limit) in usage.items():
            print(f"{model}: {used}/{limit}")
        print(f"total: {total_active(queue_data)}")
    elif cmd == 'add-slot':
        if len(sys.argv) < 5:
            print('Usage: add-slot <model> <task_id> <session_id>')
        else:
            add_slot(sys.argv[2], sys.argv[3], sys.argv[4], queue_data)
    elif cmd == 'free-slot':
        if len(sys.argv) < 4:
            print('Usage: free-slot <model> <task_id>')
        else:
            free_slot(sys.argv[2], sys.argv[3], queue_data)
    elif cmd == 'check-stalls':
        check_stalls(tasks_data, queue_data)
    else:
        print(f"Unknown command: {cmd}")
        print(__doc__)
