#!/bin/bash
# task-manager.sh — CrispWave Task Manager v3
# Single source of truth for task operations with audit trail + spec enforcement
# RULE: Only this script modifies tasks.json. All agents use this.

set -euo pipefail

WORKSPACE="/Users/openclaw/.openclaw/workspace"
TASKS_FILE="$WORKSPACE/tasks.json"
AUDIT_LOG="$WORKSPACE/task-audit.jsonl"
SPEC_DIR="$WORKSPACE/task-specs"
LOCK_FILE="/tmp/crispwave-tasks.lock"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "$SPEC_DIR"
touch "$AUDIT_LOG"
[ -f "$TASKS_FILE" ] || echo '{"tasks":[],"meta":{"version":3,"lastModified":"","lastModifiedBy":""}}' > "$TASKS_FILE"

acquire_lock() {
    local attempts=0
    while ! mkdir "$LOCK_FILE" 2>/dev/null; do
        attempts=$((attempts + 1))
        if [ $attempts -gt 20 ]; then
            echo "ERROR: Could not acquire task lock after 10s" >&2
            exit 1
        fi
        sleep 0.5
    done
    trap 'rm -rf "$LOCK_FILE"' EXIT
}

audit() {
    local action="$1" task_id="$2" actor="${3:-unknown}" details="${4:-}"
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"action\":\"$action\",\"taskId\":\"$task_id\",\"actor\":\"$actor\",\"details\":\"$details\"}" >> "$AUDIT_LOG"
}

next_id() {
    local max_id
    max_id=$(jq -r '[.tasks[].id | ltrimstr("task-") | tonumber] | max // 0' "$TASKS_FILE")
    printf "task-%03d" $((max_id + 1))
}

spec_path_for() {
    local task_id="$1"
    printf "%s/%s.md" "$SPEC_DIR" "$task_id"
}

spec_exists() {
    local path="$1"
    [ -f "$path" ] && [ -s "$path" ]
}

spec_word_count() {
    local path="$1"
    if [ -f "$path" ]; then
        wc -w < "$path" | tr -d ' '
    else
        echo 0
    fi
}

spec_ready() {
    local path="$1"
    [ -f "$path" ] || return 1
    grep -qi '^## Acceptance Criteria' "$path" || return 1
    grep -qi '^## Context / Handoff' "$path" || return 1
    local words
    words=$(spec_word_count "$path")
    [ "$words" -ge 80 ] || return 1
    grep -qi 'Legacy task migrated without a full objective yet' "$path" && return 1
    grep -qi 'Spec needs explicit completion criteria' "$path" && return 1
    grep -qi 'Legacy task with thin historical notes' "$path" && return 1
    return 0
}

normalize_repo_status() {
    local status="${1:-}"
    case "$status" in
        "" ) echo "missing" ;;
        linked|ready|active|missing|blocked|archived|planned|unknown|not-required) echo "$status" ;;
        *) echo "$status" ;;
    esac
}

bool_json() {
    local val="${1:-false}"
    case "$val" in
        true|TRUE|1|yes|YES) echo true ;;
        *) echo false ;;
    esac
}

infer_github_required_text() {
    python3 - "$@" <<'PY'
import sys
blob = ' '.join(sys.argv[1:]).lower()
keywords = [
    'software', 'codebase', 'coding', 'bug', 'refactor', 'dashboard', 'api', 'web app',
    'ios app', 'android app', 'watchos', 'macos app', 'flutter', 'next.js', 'react',
    'plugin', 'oauth', 'mvp app', 'token usage dashboard', 'model control panel', 'operator cockpit'
]
project_markers = ['crispwave dashboard', 'heartwatch', 'bookforge', 'budget app']
assignee_markers = ['claude-code', 'codex', 'agent:forge', 'agent:heartwatch']
result = any(k in blob for k in keywords) or any(p in blob for p in project_markers) or any(a in blob for a in assignee_markers)
print('true' if result else 'false')
PY
}

compute_execution_ready() {
    local spec_ready_val="$1" github_required="$2" repo_name="$3" repo_url="$4" repo_status="$5"
    if [ "$spec_ready_val" != "true" ]; then
        echo false
        return
    fi
    if [ "$github_required" = "true" ]; then
        if [ -z "$repo_name" ] && [ -z "$repo_url" ]; then
            echo false
            return
        fi
        case "$repo_status" in
            linked|ready|active) echo true ;;
            *) echo false ;;
        esac
        return
    fi
    echo true
}

execution_block_reason() {
    local spec_ready_val="$1" github_required="$2" repo_name="$3" repo_url="$4" repo_status="$5"
    if [ "$spec_ready_val" != "true" ]; then
        echo "spec-incomplete"
        return
    fi
    if [ "$github_required" = "true" ]; then
        if [ -z "$repo_name" ] && [ -z "$repo_url" ]; then
            echo "github-repo-missing"
            return
        fi
        case "$repo_status" in
            linked|ready|active) echo "ready" ;;
            *) echo "repo-$repo_status" ;;
        esac
        return
    fi
    echo "ready"
}

print_spec_template() {
    local task_id="$1"
    local title="$2"
    cat <<SPEC
# $task_id — $title

## Objective
Describe what this task is and the outcome we need.

## Scope
- What must be built/changed
- What is explicitly in scope

## Acceptance Criteria
- [ ] Concrete completion condition 1
- [ ] Concrete completion condition 2
- [ ] Concrete completion condition 3

## Constraints / Requirements
- Any constraints, dependencies, tooling rules, limits, non-goals
- If this is a coding/software task, attach a GitHub repo before execution starts.

## Context / Handoff
Enough detail that a new model, agent, or employee can pick this up cold.
Include repo linkage (repo name + URL) for coding tasks.

## Verification
How to verify the work is actually complete.
SPEC
}

usage() {
    cat << 'USAGE'
CrispWave Task Manager v3

Usage: task-manager.sh <command> [options]

Commands:
  list [--status STATUS] [--assignee NAME] [--priority LEVEL]
      List tasks with optional filters and spec/execution-readiness markers.

  add --title "TITLE" [--priority PRIORITY] [--assignee NAME] [--notes "NOTES"] [--source SOURCE]
      [--description "SUMMARY"] [--spec-file PATH] [--skip-spec]
      [--github-required true|false] [--repo-name NAME] [--repo-url URL] [--repo-status STATUS]
      Add a new task. Serious tasks are expected to have a spec.
      If no spec is provided, a draft spec file is created automatically.
      Coding/software tasks should set --github-required true and attach repo linkage.

  update TASK_ID --status STATUS --actor ACTOR [--notes "NOTES"] [--reason "REASON"] [--force]
      Update task status.
      Enforcement: task cannot move to in-progress or done unless executionReady=true,
      unless --force is used by actor apex or ronald.

  show TASK_ID
      Show full task details including spec path, repo linkage, execution readiness, and audit history.

  spec TASK_ID [--edit]
      Print the task spec path and contents. --edit opens in $EDITOR if set.

  attach-spec TASK_ID --file PATH --actor ACTOR
      Attach/replace a task spec from a markdown file and recompute readiness.

  set-description TASK_ID --description "TEXT" --actor ACTOR
      Update task short description/summary field.

  set-github TASK_ID --actor ACTOR [--required true|false] [--repo-name NAME] [--repo-url URL] [--repo-status STATUS]
      Attach or update GitHub repo linkage.
      Typical coding flow: set-github TASK --required true --repo-name owner/repo --repo-url https://github.com/owner/repo --repo-status linked

  clear-github TASK_ID --actor ACTOR
      Remove repo linkage and reset repo status to missing.

  github TASK_ID
      Show GitHub linkage for one task.

  refresh-spec [TASK_ID]
      Recompute spec metadata and execution readiness for one task or all tasks.

  migrate-github
      Backfill github_required / repo_status / execution_ready for existing tasks.
      Uses lightweight heuristics for older coding/software tasks.

  audit [TASK_ID]
      Show audit trail.

  stats
      Show task statistics including spec and execution readiness.

  board
      Show formatted task board with spec status, repo linkage, and execution readiness.

Rules:
  - Only 'apex' or 'ronald' can mark tasks as 'done'
  - All status changes require --actor
  - All changes are logged to task-audit.jsonl
  - File locking prevents concurrent corruption
  - Tasks without a complete spec are NOT ready for delegation
  - Coding/software tasks without GitHub repo linkage are NOT ready for execution or delegation
USAGE
}

refresh_one_task() {
    local task_id="$1"
    local now="$2"
    local spec_path
    spec_path=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .spec.path // empty' "$TASKS_FILE")
    [ -z "$spec_path" ] && spec_path=$(spec_path_for "$task_id")
    local ready=false completeness="missing" words=0
    if spec_exists "$spec_path"; then
        words=$(spec_word_count "$spec_path")
        completeness="draft"
        if spec_ready "$spec_path"; then
            ready=true
            completeness="ready"
        fi
    fi

    local title description notes assignee project github_required repo_name repo_url repo_status execution_ready block_reason
    title=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.title // "")' "$TASKS_FILE")
    description=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.description // "")' "$TASKS_FILE")
    notes=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.notes // "")' "$TASKS_FILE")
    assignee=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.assignee // "")' "$TASKS_FILE")
    project=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.project // "")' "$TASKS_FILE")
    github_required=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .github_required // empty' "$TASKS_FILE")
    if [ -z "$github_required" ] || [ "$github_required" = "null" ]; then
        github_required=$(infer_github_required_text "$title" "$description" "$notes" "$assignee" "$project")
    fi
    repo_name=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .repo_name // ""' "$TASKS_FILE")
    repo_url=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .repo_url // ""' "$TASKS_FILE")
    repo_status=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .repo_status // empty' "$TASKS_FILE")
    repo_status=$(normalize_repo_status "$repo_status")
    if [ "$github_required" = "true" ] && [ -z "$repo_name" ] && [ -z "$repo_url" ] && { [ "$repo_status" = "missing" ] || [ "$repo_status" = "not-required" ]; }; then
        repo_status="missing"
    elif [ "$github_required" != "true" ] && [ -z "$repo_name" ] && [ -z "$repo_url" ]; then
        repo_status="not-required"
    fi
    execution_ready=$(compute_execution_ready "$ready" "$github_required" "$repo_name" "$repo_url" "$repo_status")
    block_reason=$(execution_block_reason "$ready" "$github_required" "$repo_name" "$repo_url" "$repo_status")

    jq --arg id "$task_id" --arg path "$spec_path" --arg completeness "$completeness" --arg now "$now" \
       --argjson words "$words" --argjson ready "$ready" --argjson githubRequired "$github_required" \
       --arg repoName "$repo_name" --arg repoUrl "$repo_url" --arg repoStatus "$repo_status" \
       --argjson executionReady "$execution_ready" --arg blockReason "$block_reason" '
      (.tasks[] | select(.id == $id)).spec.path = $path |
      (.tasks[] | select(.id == $id)).spec.wordCount = $words |
      (.tasks[] | select(.id == $id)).spec.completeness = $completeness |
      (.tasks[] | select(.id == $id)).spec.ready = $ready |
      (.tasks[] | select(.id == $id)).github_required = $githubRequired |
      (.tasks[] | select(.id == $id)).repo_name = ($repoName | if . == "" then null else . end) |
      (.tasks[] | select(.id == $id)).repo_url = ($repoUrl | if . == "" then null else . end) |
      (.tasks[] | select(.id == $id)).repo_status = $repoStatus |
      (.tasks[] | select(.id == $id)).execution_ready = $executionReady |
      (.tasks[] | select(.id == $id)).execution_block_reason = $blockReason |
      (.tasks[] | select(.id == $id)).updatedAt = $now |
      .meta.version = 4 |
      .meta.lastModified = $now
    ' "$TASKS_FILE" > /tmp/tasks-refresh.json
    mv /tmp/tasks-refresh.json "$TASKS_FILE"
}

cmd_list() {
    local status_filter="" assignee_filter="" priority_filter=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status) status_filter="$2"; shift 2 ;;
            --assignee) assignee_filter="$2"; shift 2 ;;
            --priority) priority_filter="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local filter='.tasks'
    [ -n "$status_filter" ] && filter="$filter | map(select(.status == \"$status_filter\"))"
    [ -n "$assignee_filter" ] && filter="$filter | map(select(.assignee == \"$assignee_filter\"))"
    [ -n "$priority_filter" ] && filter="$filter | map(select(.priority == \"$priority_filter\"))"

    jq -r "$filter | .[] | [(.id),(.status),(.priority // \"-\"),(.assignee // \"-\"),((.spec.completeness // \"missing\")),((.execution_ready // false)|tostring),((.repo_name // .repo_url // \"-\")),(.title)] | @tsv" "$TASKS_FILE" | \
        column -t -s $'\t'
}

cmd_add() {
    local title="" priority="medium" assignee="apex" notes="" source="apex" description="" spec_file="" skip_spec=false
    local github_required="" repo_name="" repo_url="" repo_status="missing"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title) title="$2"; shift 2 ;;
            --priority) priority="$2"; shift 2 ;;
            --assignee) assignee="$2"; shift 2 ;;
            --notes) notes="$2"; shift 2 ;;
            --source) source="$2"; shift 2 ;;
            --description) description="$2"; shift 2 ;;
            --spec-file) spec_file="$2"; shift 2 ;;
            --skip-spec) skip_spec=true; shift ;;
            --github-required) github_required="$2"; shift 2 ;;
            --repo-name) repo_name="$2"; shift 2 ;;
            --repo-url) repo_url="$2"; shift 2 ;;
            --repo-status) repo_status="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [ -z "$title" ] && { echo "ERROR: --title required" >&2; exit 1; }

    acquire_lock
    local new_id now spec_path github_required_json
    new_id=$(next_id)
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    spec_path=$(spec_path_for "$new_id")

    if [ -n "$spec_file" ]; then
        cp "$spec_file" "$spec_path"
    elif [ "$skip_spec" = false ]; then
        print_spec_template "$new_id" "$title" > "$spec_path"
    fi

    if [ -z "$github_required" ]; then
        github_required=$(infer_github_required_text "$title" "$description" "$notes" "$assignee")
    fi
    github_required_json=$(bool_json "$github_required")
    repo_status=$(normalize_repo_status "$repo_status")
    if [ "$github_required_json" != "true" ] && [ -z "$repo_name" ] && [ -z "$repo_url" ]; then
        repo_status="not-required"
    fi

    jq --arg id "$new_id" \
       --arg title "$title" \
       --arg priority "$priority" \
       --arg assignee "$assignee" \
       --arg notes "$notes" \
       --arg source "$source" \
       --arg description "$description" \
       --arg specPath "$spec_path" \
       --arg now "$now" \
       --arg repoName "$repo_name" \
       --arg repoUrl "$repo_url" \
       --arg repoStatus "$repo_status" \
       --argjson githubRequired "$github_required_json" \
       '.tasks += [{
           id: $id,
           title: $title,
           description: $description,
           status: "pending",
           priority: $priority,
           assignee: $assignee,
           source: $source,
           notes: $notes,
           createdAt: $now,
           updatedAt: $now,
           github_required: $githubRequired,
           repo_name: ($repoName | if . == "" then null else . end),
           repo_url: ($repoUrl | if . == "" then null else . end),
           repo_status: $repoStatus,
           execution_ready: false,
           execution_block_reason: "spec-incomplete",
           spec: {path: $specPath, ready: false, completeness: "missing", wordCount: 0},
           statusHistory: [{"status":"pending","at":$now,"by":$source}]
       }] | .meta.lastModified = $now | .meta.lastModifiedBy = $source | .meta.version = 4' "$TASKS_FILE" > /tmp/tasks-new.json
    mv /tmp/tasks-new.json "$TASKS_FILE"

    refresh_one_task "$new_id" "$now"
    audit "created" "$new_id" "$source" "title=$title priority=$priority github_required=$github_required_json repo=${repo_name:-$repo_url}"
    echo "$new_id"
    if [ -f "$spec_path" ]; then
        echo "SPEC: $spec_path" >&2
    fi
}

enforce_execution_ready_for_status() {
    local task_id="$1" new_status="$2" actor="$3" force="$4"
    if [[ "$new_status" =~ ^(in-progress|done)$ ]]; then
        local execution_ready github_required repo_name repo_url block_reason
        execution_ready=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.execution_ready // false)' "$TASKS_FILE")
        github_required=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.github_required // false)' "$TASKS_FILE")
        repo_name=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.repo_name // "")' "$TASKS_FILE")
        repo_url=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.repo_url // "")' "$TASKS_FILE")
        block_reason=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.execution_block_reason // "execution-blocked")' "$TASKS_FILE")
        if [ "$execution_ready" != "true" ]; then
            if [ "$force" = true ] && { [ "$actor" = "apex" ] || [ "$actor" = "ronald" ]; }; then
                return 0
            fi
            if [ "$github_required" = "true" ] && [ -z "$repo_name" ] && [ -z "$repo_url" ]; then
                echo "ERROR: Task $task_id is blocked for execution. Coding/software tasks require GitHub repo linkage before moving to $new_status. Use: task-manager.sh set-github $task_id --actor $actor --required true --repo-name owner/repo --repo-url https://github.com/owner/repo --repo-status linked" >&2
            else
                echo "ERROR: Task $task_id is not execution-ready ($block_reason). Add/update spec and GitHub linkage before moving to $new_status." >&2
            fi
            exit 1
        fi
    fi
}

cmd_update() {
    local task_id="$1"; shift
    local new_status="" actor="" notes="" reason="" force=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status) new_status="$2"; shift 2 ;;
            --actor) actor="$2"; shift 2 ;;
            --notes) notes="$2"; shift 2 ;;
            --reason) reason="$2"; shift 2 ;;
            --force) force=true; shift ;;
            *) shift ;;
        esac
    done

    [ -z "$new_status" ] && { echo "ERROR: --status required" >&2; exit 1; }
    [ -z "$actor" ] && { echo "ERROR: --actor required" >&2; exit 1; }

    local current_status now valid=false
    current_status=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .status' "$TASKS_FILE")
    [ -z "$current_status" ] && { echo "ERROR: Task $task_id not found" >&2; exit 1; }

    if [ "$new_status" = "done" ] && [ "$actor" != "apex" ] && [ "$actor" != "ronald" ]; then
        echo "ERROR: Only 'apex' or 'ronald' can mark tasks as done." >&2
        audit "denied" "$task_id" "$actor" "attempted done, denied"
        exit 1
    fi
    if [ "$current_status" = "done" ] && [ "$force" = false ]; then
        echo "ERROR: Task $task_id is done. Use --force to reopen." >&2
        exit 1
    fi

    case "$current_status" in
        pending) [[ "$new_status" =~ ^(in-progress|blocked|cancelled)$ ]] && valid=true ;;
        in-progress) [[ "$new_status" =~ ^(done|blocked|on-hold|pending)$ ]] && valid=true ;;
        blocked) [[ "$new_status" =~ ^(pending|in-progress|cancelled)$ ]] && valid=true ;;
        on-hold) [[ "$new_status" =~ ^(pending|in-progress|cancelled)$ ]] && valid=true ;;
        done) [ "$force" = true ] && valid=true ;;
        cancelled) [ "$force" = true ] && valid=true ;;
    esac
    [ "$valid" = false ] && { echo "ERROR: Invalid transition: $current_status → $new_status" >&2; exit 1; }

    local refresh_now
    refresh_now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    refresh_one_task "$task_id" "$refresh_now"
    enforce_execution_ready_for_status "$task_id" "$new_status" "$actor" "$force"

    acquire_lock
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    jq --arg id "$task_id" --arg status "$new_status" --arg actor "$actor" --arg reason "$reason" --arg now "$now" '
        (.tasks[] | select(.id == $id)).status = $status |
        (.tasks[] | select(.id == $id)).updatedAt = $now |
        (.tasks[] | select(.id == $id)).statusHistory += [{"status":$status,"at":$now,"by":$actor,"reason":$reason}] |
        .meta.lastModified = $now |
        .meta.lastModifiedBy = $actor
    ' "$TASKS_FILE" > /tmp/tasks-updated.json
    mv /tmp/tasks-updated.json "$TASKS_FILE"

    if [ "$new_status" = "done" ]; then
        jq --arg id "$task_id" --arg now "$now" '(.tasks[] | select(.id == $id)).completedAt = $now' "$TASKS_FILE" > /tmp/tasks-done.json
        mv /tmp/tasks-done.json "$TASKS_FILE"
    fi
    if [ -n "$notes" ]; then
        jq --arg id "$task_id" --arg notes "$notes" '(.tasks[] | select(.id == $id)).notes = $notes' "$TASKS_FILE" > /tmp/tasks-notes.json
        mv /tmp/tasks-notes.json "$TASKS_FILE"
    fi

    audit "status_change" "$task_id" "$actor" "$current_status→$new_status reason=$reason"
    echo "✅ $task_id: $current_status → $new_status (by $actor)"
}

cmd_show() {
    local task_id="$1"
    echo -e "${BLUE}═══ Task Details ═══${NC}"
    jq -r --arg id "$task_id" '.tasks[] | select(.id == $id)' "$TASKS_FILE"
    echo ""
    echo -e "${BLUE}═══ Execution Gate ═══${NC}"
    jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | "github_required=\(.github_required // false)\nrepo_name=\(.repo_name // "-")\nrepo_url=\(.repo_url // "-")\nrepo_status=\(.repo_status // "missing")\nexecution_ready=\(.execution_ready // false)\nexecution_block_reason=\(.execution_block_reason // "unknown")"' "$TASKS_FILE"
    echo ""
    local spec_path
    spec_path=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .spec.path // empty' "$TASKS_FILE")
    if [ -n "$spec_path" ] && [ -f "$spec_path" ]; then
        echo -e "${BLUE}═══ Spec Preview ═══${NC}"
        sed -n '1,80p' "$spec_path"
        echo ""
    fi
    echo -e "${BLUE}═══ Audit Trail ═══${NC}"
    grep "\"$task_id\"" "$AUDIT_LOG" 2>/dev/null | jq -r '"\(.ts) [\(.actor)] \(.action): \(.details)"' || echo "No audit entries"
}

cmd_spec() {
    local task_id="$1"; shift || true
    local edit=false
    [ "${1:-}" = "--edit" ] && edit=true
    local spec_path
    spec_path=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .spec.path // empty' "$TASKS_FILE")
    [ -z "$spec_path" ] && spec_path=$(spec_path_for "$task_id")
    echo "$spec_path"
    [ -f "$spec_path" ] || { echo "No spec file"; exit 1; }
    if [ "$edit" = true ]; then
        : "${EDITOR:=vi}"
        "$EDITOR" "$spec_path"
        cmd_refresh_spec "$task_id"
    else
        sed -n '1,220p' "$spec_path"
    fi
}

cmd_attach_spec() {
    local task_id="$1"; shift
    local file="" actor=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file) file="$2"; shift 2 ;;
            --actor) actor="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [ -z "$file" ] && { echo "ERROR: --file required" >&2; exit 1; }
    [ -z "$actor" ] && { echo "ERROR: --actor required" >&2; exit 1; }
    local spec_path now
    spec_path=$(spec_path_for "$task_id")
    cp "$file" "$spec_path"
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    acquire_lock
    refresh_one_task "$task_id" "$now"
    jq --arg id "$task_id" --arg actor "$actor" --arg now "$now" '(.tasks[] | select(.id == $id)).updatedAt = $now | .meta.lastModified = $now | .meta.lastModifiedBy = $actor' "$TASKS_FILE" > /tmp/tasks-attach.json
    mv /tmp/tasks-attach.json "$TASKS_FILE"
    audit "spec_attached" "$task_id" "$actor" "path=$spec_path"
    echo "✅ Attached spec: $spec_path"
}

cmd_set_description() {
    local task_id="$1"; shift
    local description="" actor=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --description) description="$2"; shift 2 ;;
            --actor) actor="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [ -z "$description" ] && { echo "ERROR: --description required" >&2; exit 1; }
    [ -z "$actor" ] && { echo "ERROR: --actor required" >&2; exit 1; }
    acquire_lock
    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    jq --arg id "$task_id" --arg description "$description" --arg actor "$actor" --arg now "$now" '
      (.tasks[] | select(.id == $id)).description = $description |
      (.tasks[] | select(.id == $id)).updatedAt = $now |
      .meta.lastModified = $now |
      .meta.lastModifiedBy = $actor
    ' "$TASKS_FILE" > /tmp/tasks-desc.json
    mv /tmp/tasks-desc.json "$TASKS_FILE"
    refresh_one_task "$task_id" "$now"
    audit "description_set" "$task_id" "$actor" "description updated"
    echo "✅ Updated description for $task_id"
}

cmd_set_github() {
    local task_id="$1"; shift
    local actor="" required="" repo_name="" repo_url="" repo_status=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --actor) actor="$2"; shift 2 ;;
            --required) required="$2"; shift 2 ;;
            --repo-name) repo_name="$2"; shift 2 ;;
            --repo-url) repo_url="$2"; shift 2 ;;
            --repo-status) repo_status="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [ -z "$actor" ] && { echo "ERROR: --actor required" >&2; exit 1; }
    [ -z "$required" ] && required=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.github_required // false)' "$TASKS_FILE")
    required=$(bool_json "$required")
    if [ -z "$repo_name" ]; then
        repo_name=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.repo_name // "")' "$TASKS_FILE")
    fi
    if [ -z "$repo_url" ]; then
        repo_url=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.repo_url // "")' "$TASKS_FILE")
    fi
    if [ -z "$repo_status" ]; then
        repo_status=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | (.repo_status // "missing")' "$TASKS_FILE")
    fi
    repo_status=$(normalize_repo_status "$repo_status")
    acquire_lock
    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    jq --arg id "$task_id" --arg actor "$actor" --arg now "$now" --arg repoName "$repo_name" --arg repoUrl "$repo_url" --arg repoStatus "$repo_status" --argjson required "$required" '
      (.tasks[] | select(.id == $id)).github_required = $required |
      (.tasks[] | select(.id == $id)).repo_name = ($repoName | if . == "" then null else . end) |
      (.tasks[] | select(.id == $id)).repo_url = ($repoUrl | if . == "" then null else . end) |
      (.tasks[] | select(.id == $id)).repo_status = $repoStatus |
      (.tasks[] | select(.id == $id)).updatedAt = $now |
      .meta.lastModified = $now |
      .meta.lastModifiedBy = $actor
    ' "$TASKS_FILE" > /tmp/tasks-github.json
    mv /tmp/tasks-github.json "$TASKS_FILE"
    refresh_one_task "$task_id" "$now"
    audit "github_set" "$task_id" "$actor" "required=$required repo=${repo_name:-$repo_url} status=$repo_status"
    echo "✅ Updated GitHub linkage for $task_id"
}

cmd_clear_github() {
    local task_id="$1"; shift
    local actor=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --actor) actor="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [ -z "$actor" ] && { echo "ERROR: --actor required" >&2; exit 1; }
    acquire_lock
    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    jq --arg id "$task_id" --arg actor "$actor" --arg now "$now" '
      (.tasks[] | select(.id == $id)).repo_name = null |
      (.tasks[] | select(.id == $id)).repo_url = null |
      (.tasks[] | select(.id == $id)).repo_status = "missing" |
      (.tasks[] | select(.id == $id)).updatedAt = $now |
      .meta.lastModified = $now |
      .meta.lastModifiedBy = $actor
    ' "$TASKS_FILE" > /tmp/tasks-github-clear.json
    mv /tmp/tasks-github-clear.json "$TASKS_FILE"
    refresh_one_task "$task_id" "$now"
    audit "github_cleared" "$task_id" "$actor" "repo linkage cleared"
    echo "✅ Cleared GitHub linkage for $task_id"
}

cmd_github() {
    local task_id="$1"
    jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | "Task: \(.id) — \(.title)\ngithub_required: \(.github_required // false)\nrepo_name: \(.repo_name // "-")\nrepo_url: \(.repo_url // "-")\nrepo_status: \(.repo_status // "missing")\nexecution_ready: \(.execution_ready // false)\nexecution_block_reason: \(.execution_block_reason // "unknown")"' "$TASKS_FILE"
}

cmd_refresh_spec() {
    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    acquire_lock
    if [ $# -gt 0 ]; then
        refresh_one_task "$1" "$now"
        echo "✅ Refreshed $1"
    else
        local ids
        ids=$(jq -r '.tasks[].id' "$TASKS_FILE")
        for id in $ids; do
            refresh_one_task "$id" "$now"
        done
        echo "✅ Refreshed all task spec metadata"
    fi
}

cmd_migrate_github() {
    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    acquire_lock
    python3 - "$TASKS_FILE" <<'PY'
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
data = json.loads(p.read_text())
keywords = [
    'software', 'codebase', 'coding', 'bug', 'refactor', 'dashboard', 'api', 'web app',
    'ios app', 'android app', 'watchos', 'macos app', 'flutter', 'next.js', 'react',
    'plugin', 'oauth', 'mvp app', 'token usage dashboard', 'model control panel', 'operator cockpit'
]
project_markers = ['crispwave dashboard', 'heartwatch', 'bookforge', 'budget app']
assignee_markers = ['claude-code', 'codex', 'agent:forge', 'agent:heartwatch']
def infer(task):
    blob = ' '.join(str(task.get(k,'')) for k in ('title','description','notes','assignee','project')).lower()
    return any(k in blob for k in keywords) or any(p1 in blob for p1 in project_markers) or any(a in blob for a in assignee_markers)
for task in data.get('tasks', []):
    if not (task.get('repo_name') or task.get('repo_url')):
        task['github_required'] = infer(task)
        task['repo_status'] = 'missing' if task['github_required'] else 'not-required'
p.write_text(json.dumps(data, indent=2))
PY
    local ids
    ids=$(jq -r '.tasks[].id' "$TASKS_FILE")
    for id in $ids; do
        refresh_one_task "$id" "$now"
    done
    jq --arg now "$now" '.meta.version = 4 | .meta.lastModified = $now | .meta.lastModifiedBy = "apex"' "$TASKS_FILE" > /tmp/tasks-migrate.json
    mv /tmp/tasks-migrate.json "$TASKS_FILE"
    audit "github_migrated" "all" "apex" "backfilled github_required/repo_status/execution_ready"
    echo "✅ Migrated GitHub execution metadata across all tasks"
}

cmd_audit() {
    local task_id="${1:-}"
    if [ -n "$task_id" ]; then
        grep "\"$task_id\"" "$AUDIT_LOG" 2>/dev/null | jq -r '"\(.ts) [\(.actor)] \(.action) \(.taskId): \(.details)"' || echo "No entries"
    else
        tail -20 "$AUDIT_LOG" | jq -r '"\(.ts) [\(.actor)] \(.action) \(.taskId): \(.details)"'
    fi
}

cmd_stats() {
    echo -e "${BLUE}═══ Task Statistics ═══${NC}"
    python3 - <<'PY2'
import json
with open('/Users/openclaw/.openclaw/workspace/tasks.json') as f:
    tasks = json.load(f)['tasks']
print(f'Total: {len(tasks)}')
for label, status in [('Done','done'), ('In Progress','in-progress'), ('Pending','pending'), ('Blocked','blocked'), ('On Hold','on-hold'), ('Cancelled','cancelled')]:
    print(f'{label}: {sum(1 for t in tasks if t.get("status") == status)}')
print(f'Spec Ready: {sum(1 for t in tasks if (t.get("spec") or {}).get("ready") is True)}')
print(f'Execution Ready: {sum(1 for t in tasks if t.get("execution_ready") is True)}')
print(f'GitHub Required: {sum(1 for t in tasks if t.get("github_required") is True)}')
print(f'GitHub Missing: {sum(1 for t in tasks if t.get("github_required") is True and not (t.get("repo_name") or t.get("repo_url")))}')
PY2
}

cmd_board() {
    local now_str
    now_str=$(date '+%Y-%m-%d %I:%M %p PT')
    echo "📋 **CrispWave Task Board** — $now_str"
    echo ""

    local ip
    ip=$(jq -r '.tasks[] | select(.status == "in-progress") | "🔄 \(.id) — \(.title) [\(.assignee // "unassigned")] · exec: \((.execution_ready // false)) · repo: \((.repo_name // .repo_url // "-")) [\(.repo_status // "missing")]"' "$TASKS_FILE")
    if [ -n "$ip" ]; then
        echo "**🔄 In Progress:**"
        echo "$ip"
        echo ""
    fi

    local pend
    pend=$(jq -r '.tasks[] | select(.status == "pending") | "⏳ \(.id) — \(.title) · exec: \((.execution_ready // false)) · repo: \((.repo_name // .repo_url // "-")) [\(.repo_status // "missing")]"' "$TASKS_FILE")
    if [ -n "$pend" ]; then
        echo "**⏳ Pending:**"
        echo "$pend"
        echo ""
    fi

    local blocked
    blocked=$(jq -r '.tasks[] | select(.status == "blocked") | "🚫 \(.id) — \(.title) · exec: \((.execution_ready // false)) · repo: \((.repo_name // .repo_url // "-")) [\(.repo_status // "missing")]"' "$TASKS_FILE")
    if [ -n "$blocked" ]; then
        echo "**🚫 Blocked:**"
        echo "$blocked"
        echo ""
    fi

    local ready total repo_missing
    ready=$(jq '[.tasks[] | select(.execution_ready == true)] | length' "$TASKS_FILE")
    total=$(jq '.tasks | length' "$TASKS_FILE")
    repo_missing=$(jq '[.tasks[] | select(.github_required == true and ((.repo_name // .repo_url // "") == ""))] | length' "$TASKS_FILE")
    echo "**Execution Readiness:** $ready/$total ready for clean handoff"
    echo "**GitHub Missing on Required Tasks:** $repo_missing"
}

case "${1:-help}" in
    list) shift; cmd_list "$@" ;;
    add) shift; cmd_add "$@" ;;
    update) shift; cmd_update "$@" ;;
    show) shift; cmd_show "$1" ;;
    spec) shift; cmd_spec "$@" ;;
    attach-spec) shift; cmd_attach_spec "$@" ;;
    set-description) shift; cmd_set_description "$@" ;;
    set-github) shift; cmd_set_github "$@" ;;
    clear-github) shift; cmd_clear_github "$@" ;;
    github) shift; cmd_github "$1" ;;
    refresh-spec) shift; cmd_refresh_spec "$@" ;;
    migrate-github) shift; cmd_migrate_github ;;
    audit) shift; cmd_audit "${1:-}" ;;
    stats) shift; cmd_stats ;;
    board) shift; cmd_board ;;
    help|--help|-h) usage ;;
    *) echo "Unknown command: $1"; usage; exit 1 ;;
esac
