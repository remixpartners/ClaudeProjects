#!/bin/bash
# Generates an HTML dashboard and opens it in the browser

WORKSPACE="$HOME/claude-workspace"
CLAUDE_CONFIG="$HOME/.claude"
OUTPUT="$HOME/claude-workspace/.claude/dashboard.html"
META_FILE="$HOME/claude-workspace/.claude/dashboard-meta.json"

# Initialize meta file if missing
if [ ! -f "$META_FILE" ]; then
    echo '{"favorites":[],"titles":{},"projectNotes":{},"archived":[]}' > "$META_FILE"
fi

# Read metadata
META_CONTENT=$(cat "$META_FILE")

# Start HTML
cat > "$OUTPUT" << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Claude Code</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>🦀</text></svg>">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', sans-serif;
            background: #fafafa;
            color: #1a1a1a;
            line-height: 1.5;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            padding: 40px 24px;
        }
        header {
            margin-bottom: 32px;
        }
        h1 {
            font-size: 28px;
            font-weight: 600;
            letter-spacing: -0.5px;
            margin-bottom: 16px;
        }

        /* Search */
        .search-container {
            position: relative;
            margin-bottom: 24px;
        }
        .search-input {
            width: 100%;
            padding: 14px 20px 14px 44px;
            border: 1px solid #e0e0e0;
            border-radius: 10px;
            font-size: 15px;
            background: white;
            transition: all 0.2s;
        }
        .search-input:focus {
            outline: none;
            border-color: #999;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }
        .search-icon {
            position: absolute;
            left: 16px;
            top: 50%;
            transform: translateY(-50%);
            color: #999;
        }
        .search-hint {
            position: absolute;
            right: 16px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 12px;
            color: #999;
        }

        /* Quick Skills */
        .skills-bar {
            display: flex;
            gap: 8px;
            margin-bottom: 24px;
            flex-wrap: wrap;
        }
        .skill-btn {
            padding: 8px 14px;
            border: 1px solid #e0e0e0;
            border-radius: 20px;
            background: white;
            font-size: 13px;
            cursor: pointer;
            transition: all 0.15s;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .skill-btn:hover {
            border-color: #1a1a1a;
            background: #1a1a1a;
            color: white;
        }

        /* Section */
        .section {
            margin-bottom: 32px;
        }
        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
            padding-bottom: 8px;
            border-bottom: 1px solid #e5e5e5;
        }
        .section-title {
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #888;
        }
        .section-actions {
            display: flex;
            gap: 8px;
        }

        /* Buttons */
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 7px 12px;
            border: none;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.15s;
        }
        .btn-primary {
            background: #1a1a1a;
            color: white;
        }
        .btn-primary:hover { background: #333; }
        .btn-ghost {
            background: transparent;
            color: #666;
            border: 1px solid #e0e0e0;
        }
        .btn-ghost:hover {
            background: #f5f5f5;
            border-color: #ccc;
        }

        /* Project Card */
        .project {
            background: white;
            border: 1px solid #e5e5e5;
            border-radius: 10px;
            margin-bottom: 12px;
            overflow: hidden;
        }
        .project.last-used {
            border-color: #1a1a1a;
            border-width: 2px;
        }
        .project-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 14px 16px;
            cursor: pointer;
        }
        .project-header:hover { background: #fafafa; }
        .project-info { flex: 1; }
        .project-name {
            font-size: 15px;
            font-weight: 600;
            margin-bottom: 2px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .project-desc {
            font-size: 13px;
            color: #666;
        }
        .project-actions {
            display: flex;
            gap: 8px;
            align-items: center;
        }
        .tag {
            font-size: 10px;
            padding: 2px 7px;
            border-radius: 4px;
            background: #f0f0f0;
            color: #666;
        }
        .tag.root { background: #1a1a1a; color: white; }
        .tag.home { background: #3b82f6; color: white; }
        .tag.last { background: #22c55e; color: white; }
        .tag.other { background: #8b5cf6; color: white; }
        .tag.count { background: #f3f4f6; color: #666; font-weight: normal; }
        .chevron {
            color: #ccc;
            transition: transform 0.2s;
            font-size: 18px;
        }
        .project.expanded .chevron { transform: rotate(90deg); }

        /* Sessions */
        .sessions {
            border-top: 1px solid #f0f0f0;
            background: #fafafa;
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.3s ease;
        }
        .project.expanded .sessions {
            max-height: 600px;
            overflow-y: auto;
        }

        /* Project Notes */
        .project-notes {
            padding: 12px 16px;
            border-bottom: 1px solid #f0f0f0;
            background: #fffbeb;
        }
        .project-notes textarea {
            width: 100%;
            border: none;
            background: transparent;
            font-size: 13px;
            resize: none;
            outline: none;
            font-family: inherit;
            color: #666;
        }
        .project-notes-label {
            font-size: 11px;
            color: #999;
            margin-bottom: 4px;
        }

        /* Session Item */
        .session {
            display: flex;
            align-items: center;
            padding: 10px 16px;
            border-bottom: 1px solid #f0f0f0;
            gap: 12px;
        }
        .session:last-child { border-bottom: none; }
        .session:hover { background: #f5f5f5; }
        .session.archived { opacity: 0.5; }
        .session.hidden { display: none; }
        .session-star {
            cursor: pointer;
            font-size: 16px;
            color: #ddd;
            transition: color 0.1s;
        }
        .session-star:hover { color: #fbbf24; }
        .session-star.favorited { color: #fbbf24; }
        .session-date {
            font-size: 12px;
            color: #888;
            min-width: 50px;
        }
        .session-title {
            flex: 1;
            font-size: 13px;
            color: #333;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            cursor: text;
        }
        .session-title:hover { text-decoration: underline dotted; }
        .session-buttons {
            display: flex;
            gap: 6px;
            opacity: 0;
            transition: opacity 0.1s;
        }
        .session:hover .session-buttons { opacity: 1; }
        .copy-btn {
            padding: 4px 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            background: white;
            font-size: 11px;
            cursor: pointer;
            transition: all 0.1s;
        }
        .copy-btn:hover {
            background: #f5f5f5;
            border-color: #ccc;
        }
        .copy-btn.danger {
            border-color: #ffcccc;
            color: #cc0000;
        }
        .copy-btn.danger:hover {
            background: #fff5f5;
        }
        .archive-btn {
            padding: 4px 8px;
            border: none;
            background: transparent;
            font-size: 12px;
            cursor: pointer;
            color: #999;
        }
        .archive-btn:hover { color: #666; }

        .no-sessions {
            padding: 16px;
            text-align: center;
            color: #999;
            font-size: 13px;
        }

        /* Favorites Section */
        .favorites-section {
            margin-bottom: 24px;
        }
        .favorites-section:empty { display: none; }
        .favorites-list {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .favorite-item {
            display: flex;
            align-items: center;
            padding: 10px 14px;
            background: white;
            border: 1px solid #fbbf24;
            border-radius: 8px;
            gap: 12px;
        }
        .favorite-item .session-buttons { opacity: 1; }

        /* Archive Toggle */
        .archive-toggle {
            text-align: center;
            padding: 12px;
        }
        .archive-toggle button {
            background: none;
            border: none;
            color: #888;
            font-size: 12px;
            cursor: pointer;
        }
        .archive-toggle button:hover { color: #333; }

        /* Toast */
        .toast {
            position: fixed;
            bottom: 24px;
            left: 50%;
            transform: translateX(-50%) translateY(100px);
            background: #1a1a1a;
            color: white;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            opacity: 0;
            transition: all 0.3s ease;
            z-index: 100;
        }
        .toast.show {
            opacity: 1;
            transform: translateX(-50%) translateY(0);
        }

        /* No Results */
        .no-results {
            text-align: center;
            padding: 40px;
            color: #999;
            display: none;
        }
        .no-results.show { display: block; }

        /* Tabs */
        .tabs {
            display: flex;
            gap: 4px;
            margin-bottom: 24px;
            border-bottom: 1px solid #e5e5e5;
        }
        .tab {
            padding: 12px 20px;
            border: none;
            background: none;
            font-size: 14px;
            font-weight: 500;
            color: #888;
            cursor: pointer;
            border-bottom: 2px solid transparent;
            margin-bottom: -1px;
            transition: all 0.15s;
        }
        .tab:hover { color: #333; }
        .tab.active {
            color: #1a1a1a;
            border-bottom-color: #1a1a1a;
        }
        .tab-content { display: none; }
        .tab-content.active { display: block; }

        /* Config Grid */
        .config-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 16px;
        }
        .config-card {
            background: white;
            border: 1px solid #e5e5e5;
            border-radius: 10px;
            padding: 16px;
        }
        .config-card-header {
            font-weight: 600;
            font-size: 15px;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .config-section {
            margin-bottom: 12px;
        }
        .config-section:last-child { margin-bottom: 0; }
        .config-section-title {
            font-size: 11px;
            text-transform: uppercase;
            color: #888;
            margin-bottom: 6px;
            font-weight: 600;
        }
        .config-item {
            display: inline-block;
            padding: 4px 10px;
            background: #f5f5f5;
            border-radius: 4px;
            font-size: 12px;
            margin: 2px 4px 2px 0;
        }
        .config-item.plugin { background: #e0f2fe; color: #0369a1; }
        .config-item.skill { background: #fef3c7; color: #92400e; }
        .config-none {
            color: #999;
            font-size: 12px;
            font-style: italic;
        }

        /* Modes List */
        .modes-list {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        .mode-item {
            background: white;
            border: 1px solid #e5e5e5;
            border-radius: 10px;
            padding: 16px;
        }
        .mode-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
        }
        .mode-name {
            font-weight: 600;
            font-size: 15px;
        }
        .mode-desc {
            color: #444;
            font-size: 14px;
            line-height: 1.5;
            margin-bottom: 8px;
        }
        .mode-when {
            color: #888;
            font-size: 13px;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Claude Code</h1>
        </header>

        <!-- Tabs -->
        <div class="tabs">
            <button class="tab active" onclick="showTab('sessions')">Sessions</button>
            <button class="tab" onclick="showTab('modes')">Modes</button>
            <button class="tab" onclick="showTab('commands')">Commands</button>
            <button class="tab" onclick="showTab('config')">Plugins & Skills</button>
        </div>

        <!-- Sessions Tab -->
        <div class="tab-content active" id="tab-sessions">

        <!-- Search -->
        <div class="search-container">
            <span class="search-icon">🔍</span>
            <input type="text" class="search-input" id="search" placeholder="Search all sessions..." oninput="filterSessions(this.value)">
            <span class="search-hint">across all projects</span>
        </div>

        <!-- Favorites -->
        <div class="favorites-section" id="favorites">
            <div class="section-header">
                <span class="section-title">⭐ Favorites</span>
            </div>
            <div class="favorites-list" id="favorites-list"></div>
        </div>

        <div class="section">
            <div class="section-header">
                <span class="section-title">Projects</span>
                <div class="section-actions">
                    <button class="btn btn-primary" onclick="copyCmd('~/claude-workspace/.claude/scripts/new-project.sh')">+ New Project</button>
                    <button class="btn btn-ghost" onclick="refreshDashboard()">Refresh</button>
                </div>
            </div>

            <div class="no-results" id="no-results">No sessions match your search.</div>
HTMLHEAD

# Get most recently modified project (scan ALL project directories)
LAST_USED=""
LAST_TIME=0
for sessions_dir in "$CLAUDE_CONFIG/projects"/-*/; do
    [ -d "$sessions_dir" ] || continue
    latest=$(ls -t "$sessions_dir"/*.jsonl 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        mod_time=$(stat -f "%m" "$latest" 2>/dev/null)
        if [ "$mod_time" -gt "$LAST_TIME" ] 2>/dev/null; then
            LAST_TIME=$mod_time
            # Decode path
            encoded_name=$(basename "$sessions_dir")
            LAST_USED=$(echo "$encoded_name" | sed 's/^-/\//' | sed 's/-/\//g')
        fi
    fi
done

# Function to extract session info
get_session_info() {
    local file="$1"
    local project_path="$2"
    local mod_date=$(stat -f "%Sm" -t "%b %d" "$file" 2>/dev/null)
    local size=$(stat -f "%z" "$file" 2>/dev/null)

    [ "$size" = "0" ] || [ -z "$size" ] && return

    local summary=$(head -100 "$file" 2>/dev/null | grep -o '"content":"[^"]*"' | head -1 | sed 's/"content":"//;s/"$//' | cut -c1-100)

    [ -z "$summary" ] || [ "$summary" = "Warmup" ] && return

    summary=$(echo "$summary" | sed 's/"/\&quot;/g' | sed "s/'/\&#39;/g" | tr '\n' ' ')

    local session_id=$(basename "$file" .jsonl)
    local escaped_path=$(echo "$project_path" | sed 's/\/$//')

    cat << SESSIONHTML
                <div class="session" data-search="$summary" data-session="$session_id" data-path="$escaped_path">
                    <span class="session-star" onclick="toggleFavorite('$session_id', '$escaped_path', this)" title="Add to favorites">☆</span>
                    <span class="session-date">$mod_date</span>
                    <span class="session-title" onclick="renameSession('$session_id', this)" title="Click to rename">$summary</span>
                    <span class="session-buttons">
                        <button class="copy-btn" onclick="copyCmd('cd $escaped_path && claude --resume $session_id')">Copy</button>
                        <button class="copy-btn danger" onclick="copyCmd('cd $escaped_path && claude --dangerously-skip-permissions --resume $session_id')">⚠️ Copy</button>
                        <button class="archive-btn" onclick="toggleArchive('$session_id', this.closest('.session'))" title="Archive">🗄️</button>
                    </span>
                </div>
SESSIONHTML
}

# Generate project
generate_project() {
    local path="$1"
    local name="$2"
    local tag="$3"
    local desc="$4"

    local escaped_path=$(echo "$path" | sed 's/\/$//' | sed 's/ /\\ /g')
    local project_id=$(echo "$path" | md5 | cut -c1-8)

    local last_tag=""
    if [ "$path" = "$LAST_USED" ] || [ "${path%/}" = "${LAST_USED%/}" ]; then
        last_tag="last-used"
    fi

    # Count sessions first
    local encoded_path=$(echo "$path" | sed 's/\/$//' | sed 's/\//-/g')
    local sessions_dir="$CLAUDE_CONFIG/projects/$encoded_path"
    local total_sessions=0
    if [ -d "$sessions_dir" ]; then
        total_sessions=$(ls "$sessions_dir"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
    fi

    cat >> "$OUTPUT" << PROJ
            <div class="project $last_tag" id="proj-$project_id" data-project="$name">
                <div class="project-header" onclick="toggle('proj-$project_id')">
                    <div class="project-info">
                        <div class="project-name">
                            $name
                            <span class="tag $tag">$tag</span>
                            <span class="tag count">$total_sessions sessions</span>
PROJ

    if [ -n "$last_tag" ]; then
        echo '                            <span class="tag last">latest</span>' >> "$OUTPUT"
    fi

    cat >> "$OUTPUT" << PROJ2
                        </div>
                        <div class="project-desc">$desc</div>
                    </div>
                    <div class="project-actions">
                        <button class="btn btn-primary" onclick="event.stopPropagation(); copyCmd('cd $escaped_path && claude')">New</button>
                        <span class="chevron">›</span>
                    </div>
                </div>
                <div class="sessions">
PROJ2

    local session_count=0
    if [ -d "$sessions_dir" ]; then
        for session_file in $(ls -t "$sessions_dir"/*.jsonl 2>/dev/null | head -15); do
            if [ -f "$session_file" ]; then
                local size=$(stat -f "%z" "$session_file" 2>/dev/null)
                if [ "$size" != "0" ] && [ -n "$size" ]; then
                    get_session_info "$session_file" "$path" >> "$OUTPUT"
                    session_count=$((session_count + 1))
                fi
            fi
        done
    fi

    [ $session_count -eq 0 ] && echo '<div class="no-sessions">No sessions yet</div>' >> "$OUTPUT"

    cat >> "$OUTPUT" << 'PROJEND'
                </div>
            </div>
PROJEND
}

# Generate all projects
# 1. Home first (most common starting point)
generate_project "$HOME" "Home (~)" "home" "Sessions started from home directory"

# 2. claudeprojects workspace root
generate_project "$WORKSPACE" "claudeprojects" "root" "Command center — sees all projects"

# 3. Work projects
for dir in "$WORKSPACE/work"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    desc=$(head -5 "$dir/CLAUDE.md" 2>/dev/null | grep -v "^#" | grep -v "^$" | grep -v "^---" | head -1 | cut -c1-80)
    [ -z "$desc" ] && desc="Work project"
    generate_project "$dir" "$name" "work" "$desc"
done

# 4. Personal projects
for dir in "$WORKSPACE/personal"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    desc=$(head -5 "$dir/CLAUDE.md" 2>/dev/null | grep -v "^#" | grep -v "^$" | grep -v "^---" | head -1 | cut -c1-80)
    [ -z "$desc" ] && desc="Personal project"
    generate_project "$dir" "$name" "personal" "$desc"
done

# 5. Other directories (outside claude-workspace, excluding Home which is already shown)
for encoded_dir in "$CLAUDE_CONFIG/projects"/-*/; do
    [ -d "$encoded_dir" ] || continue

    # Decode the path: -Users-justinmassa-foo -> /Users/justinmassa/foo
    encoded_name=$(basename "$encoded_dir")
    decoded_path=$(echo "$encoded_name" | sed 's/^-/\//' | sed 's/-/\//g')

    # Skip Home (already shown above) and workspace projects
    case "$decoded_path" in
        "$HOME") continue ;;
        "$WORKSPACE"|"$WORKSPACE/"*) continue ;;
    esac

    # Skip if directory doesn't exist anymore
    [ -d "$decoded_path" ] || continue

    # Get a friendly name for display
    display_name=$(basename "$decoded_path")

    # Get description from CLAUDE.md or use path
    desc=$(head -5 "$decoded_path/CLAUDE.md" 2>/dev/null | grep -v "^#" | grep -v "^$" | grep -v "^---" | head -1 | cut -c1-60)
    [ -z "$desc" ] && desc="$decoded_path"

    generate_project "$decoded_path" "$display_name" "other" "$desc"
done

# Close sessions tab, add modes tab, then config tab
cat >> "$OUTPUT" << 'TABSWITCH'
        </div>
        </div>

        <!-- Modes Tab -->
        <div class="tab-content" id="tab-modes">
            <div class="section">
                <div class="section-header">
                    <span class="section-title">Claude Code Modes Cheat Sheet</span>
                </div>
                <p style="color: #666; margin-bottom: 20px; font-size: 14px;">Type these commands in any Claude Code session to activate a mode.</p>

                <h3 style="font-size: 14px; color: #1a1a1a; margin: 0 0 12px; display: flex; align-items: center; gap: 8px;">
                    <span style="background: #22c55e; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px;">FOR YOU</span>
                    Essential Modes
                </h3>
                <div class="modes-list" style="margin-bottom: 32px;">
                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">💡 Brainstorming</span>
                            <button class="copy-btn" onclick="copyCmd('/brainstorming')">Copy</button>
                        </div>
                        <div class="mode-desc">Explores your idea before jumping to solutions. Asks clarifying questions, considers alternatives, helps you think through what you actually want.</div>
                        <div class="mode-when">Use when: Starting something new and you're not 100% sure what you want yet</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">🔍 Systematic Debugging</span>
                            <button class="copy-btn" onclick="copyCmd('/systematic-debugging')">Copy</button>
                        </div>
                        <div class="mode-desc">Methodically investigates problems instead of guessing. Forms hypotheses, tests them one by one, finds the root cause.</div>
                        <div class="mode-when">Use when: Something isn't working and you don't know why</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">📋 Writing Plans</span>
                            <button class="copy-btn" onclick="copyCmd('/writing-plans')">Copy</button>
                        </div>
                        <div class="mode-desc">Creates a detailed step-by-step plan before doing any work. Identifies what needs to change, in what order, and potential risks.</div>
                        <div class="mode-when">Use when: Tackling something complex or multi-step</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">🚀 Executing Plans</span>
                            <button class="copy-btn" onclick="copyCmd('/executing-plans')">Copy</button>
                        </div>
                        <div class="mode-desc">Takes a written plan and executes it step by step, checking in with you at key milestones.</div>
                        <div class="mode-when">Use when: You have a plan and want Claude to carry it out</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">✅ Verification Before Completion</span>
                            <button class="copy-btn" onclick="copyCmd('/verification-before-completion')">Copy</button>
                        </div>
                        <div class="mode-desc">Forces Claude to actually verify that something works before claiming it's done. Runs tests, checks output, confirms success.</div>
                        <div class="mode-when">Use when: You want proof that something actually works, not just "I think it's done"</div>
                    </div>
                </div>

                <h3 style="font-size: 14px; color: #888; margin: 0 0 12px; display: flex; align-items: center; gap: 8px;">
                    <span style="background: #e5e5e5; color: #666; padding: 2px 8px; border-radius: 4px; font-size: 11px;">DEVELOPER</span>
                    For Coding Projects
                </h3>
                <div class="modes-list">
                    <div class="mode-item" style="opacity: 0.7;">
                        <div class="mode-header">
                            <span class="mode-name">🧪 Test-Driven Development</span>
                            <button class="copy-btn" onclick="copyCmd('/test-driven-development')">Copy</button>
                        </div>
                        <div class="mode-desc">Writes tests first, then writes code to pass those tests. A developer discipline for building reliable software.</div>
                        <div class="mode-when">Use when: Writing code and you want it thoroughly tested</div>
                    </div>

                    <div class="mode-item" style="opacity: 0.7;">
                        <div class="mode-header">
                            <span class="mode-name">👀 Requesting Code Review</span>
                            <button class="copy-btn" onclick="copyCmd('/requesting-code-review')">Copy</button>
                        </div>
                        <div class="mode-desc">Has Claude review code for bugs, security issues, and best practices before you ship it.</div>
                        <div class="mode-when">Use when: You want a second pair of eyes on code</div>
                    </div>

                    <div class="mode-item" style="opacity: 0.7;">
                        <div class="mode-header">
                            <span class="mode-name">🌿 Git Worktrees</span>
                            <button class="copy-btn" onclick="copyCmd('/using-git-worktrees')">Copy</button>
                        </div>
                        <div class="mode-desc">Creates isolated workspaces for features so you can work on multiple things without them interfering.</div>
                        <div class="mode-when">Use when: Starting feature work that needs isolation</div>
                    </div>

                    <div class="mode-item" style="opacity: 0.7;">
                        <div class="mode-header">
                            <span class="mode-name">🏁 Finishing a Branch</span>
                            <button class="copy-btn" onclick="copyCmd('/finishing-a-development-branch')">Copy</button>
                        </div>
                        <div class="mode-desc">Guides you through completing development work—merge, PR, or cleanup.</div>
                        <div class="mode-when">Use when: Implementation is done and you need to wrap up</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Commands Tab -->
        <div class="tab-content" id="tab-commands">
            <div class="section">
                <div class="section-header">
                    <span class="section-title">Claude Code Commands Cheat Sheet</span>
                </div>
                <p style="color: #666; margin-bottom: 20px; font-size: 14px;">Type these in any Claude Code session. All verified to work.</p>

                <h3 style="font-size: 14px; color: #888; margin: 24px 0 12px; text-transform: uppercase;">Memory</h3>
                <div class="modes-list">
                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/memory</span>
                            <button class="copy-btn" onclick="copyCmd('/memory')">Copy</button>
                        </div>
                        <div class="mode-desc">View and edit your CLAUDE.md file — what Claude remembers about you and this project across sessions.</div>
                        <div class="mode-when">Use when: You want to add or change saved preferences</div>
                    </div>
                </div>

                <h3 style="font-size: 14px; color: #888; margin: 24px 0 12px; text-transform: uppercase;">Session Management</h3>
                <div class="modes-list">
                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/clear</span>
                            <button class="copy-btn" onclick="copyCmd('/clear')">Copy</button>
                        </div>
                        <div class="mode-desc">Clears the conversation history. Fresh start without closing Claude.</div>
                        <div class="mode-when">Use when: You want to switch topics or start over</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/compact</span>
                            <button class="copy-btn" onclick="copyCmd('/compact')">Copy</button>
                        </div>
                        <div class="mode-desc">Summarizes the conversation to free up space while keeping key points. You can add instructions like "/compact focus on the dashboard work".</div>
                        <div class="mode-when">Use when: Running low on context space</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/resume</span>
                            <button class="copy-btn" onclick="copyCmd('/resume')">Copy</button>
                        </div>
                        <div class="mode-desc">Opens a picker to resume a previous session, or type /resume [session-id] to resume a specific one.</div>
                        <div class="mode-when">Use when: You want to continue an old conversation</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/rename</span>
                            <button class="copy-btn" onclick="copyCmd('/rename ')">Copy</button>
                        </div>
                        <div class="mode-desc">Rename the current session to something memorable. Example: /rename dashboard-project</div>
                        <div class="mode-when">Use when: You want to find this session easily later</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/export</span>
                            <button class="copy-btn" onclick="copyCmd('/export')">Copy</button>
                        </div>
                        <div class="mode-desc">Export the conversation to a file or clipboard. Great for saving important work.</div>
                        <div class="mode-when">Use when: You want to save or share the conversation</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">Escape key</span>
                        </div>
                        <div class="mode-desc">Press <strong>Escape</strong> to stop Claude mid-response.</div>
                        <div class="mode-when">Use when: Claude is going in the wrong direction</div>
                    </div>
                </div>

                <h3 style="font-size: 14px; color: #888; margin: 24px 0 12px; text-transform: uppercase;">Info & Status</h3>
                <div class="modes-list">
                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/help</span>
                            <button class="copy-btn" onclick="copyCmd('/help')">Copy</button>
                        </div>
                        <div class="mode-desc">Shows all available commands.</div>
                        <div class="mode-when">Use when: You want to see what's available</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/status</span>
                            <button class="copy-btn" onclick="copyCmd('/status')">Copy</button>
                        </div>
                        <div class="mode-desc">Opens settings showing version, model, account info, and connection status.</div>
                        <div class="mode-when">Use when: You want to check what model you're using or your account</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/context</span>
                            <button class="copy-btn" onclick="copyCmd('/context')">Copy</button>
                        </div>
                        <div class="mode-desc">Shows a visual breakdown of context usage — how much of Claude's "memory" is used by system, messages, skills, etc.</div>
                        <div class="mode-when">Use when: You want to see how much conversation space is left</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/doctor</span>
                            <button class="copy-btn" onclick="copyCmd('/doctor')">Copy</button>
                        </div>
                        <div class="mode-desc">Checks the health of your Claude Code installation. Diagnoses problems.</div>
                        <div class="mode-when">Use when: Something seems broken</div>
                    </div>
                </div>

                <h3 style="font-size: 14px; color: #888; margin: 24px 0 12px; text-transform: uppercase;">Permissions & Safety</h3>
                <div class="modes-list">
                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/permissions</span>
                            <button class="copy-btn" onclick="copyCmd('/permissions')">Copy</button>
                        </div>
                        <div class="mode-desc">View and manage what Claude is allowed to do in this project.</div>
                        <div class="mode-when">Use when: You want to see or change access permissions</div>
                    </div>

                    <div class="mode-item" style="border-color: #ffcccc;">
                        <div class="mode-header">
                            <span class="mode-name">⚠️ --dangerously-skip-permissions</span>
                            <button class="copy-btn danger" onclick="copyCmd('--dangerously-skip-permissions')">Copy</button>
                        </div>
                        <div class="mode-desc">Add this flag when starting Claude to skip all permission prompts. Claude won't ask before running commands or editing files.</div>
                        <div class="mode-when">Use when: You trust the session completely. Be careful!</div>
                    </div>
                </div>

                <h3 style="font-size: 14px; color: #888; margin: 24px 0 12px; text-transform: uppercase;">Configuration</h3>
                <div class="modes-list">
                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/model</span>
                            <button class="copy-btn" onclick="copyCmd('/model')">Copy</button>
                        </div>
                        <div class="mode-desc">Select or change the AI model (Opus, Sonnet, etc.).</div>
                        <div class="mode-when">Use when: You want to switch between models</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/theme</span>
                            <button class="copy-btn" onclick="copyCmd('/theme')">Copy</button>
                        </div>
                        <div class="mode-desc">Change the color theme of the interface.</div>
                        <div class="mode-when">Use when: You want dark mode or different colors</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">/config</span>
                            <button class="copy-btn" onclick="copyCmd('/config')">Copy</button>
                        </div>
                        <div class="mode-desc">Opens the settings configuration interface.</div>
                        <div class="mode-when">Use when: You want to change Claude Code settings</div>
                    </div>
                </div>

                <h3 style="font-size: 14px; color: #888; margin: 24px 0 12px; text-transform: uppercase;">Terminal Startup Flags</h3>
                <p style="color: #666; margin-bottom: 12px; font-size: 13px;">Add these when starting Claude in Warp:</p>
                <div class="modes-list">
                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">claude --resume</span>
                            <button class="copy-btn" onclick="copyCmd('claude --resume')">Copy</button>
                        </div>
                        <div class="mode-desc">Starts Claude and immediately resumes your most recent session.</div>
                        <div class="mode-when">Shortcut to pick up where you left off</div>
                    </div>

                    <div class="mode-item">
                        <div class="mode-header">
                            <span class="mode-name">claude --continue</span>
                            <button class="copy-btn" onclick="copyCmd('claude --continue')">Copy</button>
                        </div>
                        <div class="mode-desc">Same as --resume. Continues your last conversation.</div>
                        <div class="mode-when">Alternative syntax if you prefer "continue"</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Config Tab -->
        <div class="tab-content" id="tab-config">
            <div class="section">
                <div class="section-header">
                    <span class="section-title">Plugins & Skills by Project</span>
                    <div class="section-actions">
                        <button class="btn btn-ghost" onclick="refreshDashboard()">Refresh</button>
                    </div>
                </div>
                <div class="config-grid">
TABSWITCH

# Generate config cards for each project
generate_config_card() {
    local path="$1"
    local name="$2"
    local tag="$3"

    # Get plugins from settings.json
    local plugins=""
    if [ -f "$path/.claude/settings.json" ]; then
        plugins=$(grep -oE '"[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+"' "$path/.claude/settings.json" 2>/dev/null | tr -d '"' | sed 's/@.*//' | sort -u | tr '\n' ' ')
    fi

    # Get skills from .claude/skills/
    local skills=""
    if [ -d "$path/.claude/skills" ]; then
        skills=$(ls "$path/.claude/skills/" 2>/dev/null | sed 's/\.skill$//' | tr '\n' ' ')
    fi

    cat >> "$OUTPUT" << CONFIGCARD
                    <div class="config-card">
                        <div class="config-card-header">
                            $name
                            <span class="tag $tag">$tag</span>
                        </div>
                        <div class="config-section">
                            <div class="config-section-title">Plugins</div>
CONFIGCARD

    if [ -n "$plugins" ]; then
        for p in $plugins; do
            echo "                            <span class=\"config-item plugin\">$p</span>" >> "$OUTPUT"
        done
    else
        echo "                            <span class=\"config-none\">None</span>" >> "$OUTPUT"
    fi

    cat >> "$OUTPUT" << 'CONFIGMID'
                        </div>
                        <div class="config-section">
                            <div class="config-section-title">Skills</div>
CONFIGMID

    if [ -n "$skills" ]; then
        for s in $skills; do
            echo "                            <span class=\"config-item skill\">$s</span>" >> "$OUTPUT"
        done
    else
        echo "                            <span class=\"config-none\">None</span>" >> "$OUTPUT"
    fi

    echo "                        </div>" >> "$OUTPUT"
    echo "                    </div>" >> "$OUTPUT"
}

# Generate config cards

# First, add Global plugins card (from ~/.claude/settings.json)
GLOBAL_PLUGINS=""
if [ -f "$HOME/.claude/settings.json" ]; then
    GLOBAL_PLUGINS=$(grep -oE '"[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+"' "$HOME/.claude/settings.json" 2>/dev/null | tr -d '"' | sed 's/@.*//' | sort -u | tr '\n' ' ')
fi

if [ -n "$GLOBAL_PLUGINS" ]; then
    cat >> "$OUTPUT" << 'GLOBALSTART'
                    <div class="config-card" style="border-color: #22c55e; background: #f0fdf4;">
                        <div class="config-card-header">
                            Global
                            <span class="tag" style="background: #22c55e; color: white;">all projects</span>
                        </div>
                        <div class="config-section">
                            <div class="config-section-title">Plugins (available everywhere)</div>
GLOBALSTART
    for p in $GLOBAL_PLUGINS; do
        echo "                            <span class=\"config-item plugin\">$p</span>" >> "$OUTPUT"
    done
    cat >> "$OUTPUT" << 'GLOBALEND'
                        </div>
                    </div>
GLOBALEND
fi

generate_config_card "$HOME" "Home (~)" "home"
generate_config_card "$WORKSPACE" "claudeprojects" "root"

for dir in "$WORKSPACE/work"/*/; do
    [ -d "$dir" ] || continue
    generate_config_card "$dir" "$(basename "$dir")" "work"
done

for dir in "$WORKSPACE/personal"/*/; do
    [ -d "$dir" ] || continue
    generate_config_card "$dir" "$(basename "$dir")" "personal"
done

# Other directories (outside workspace)
for encoded_dir in "$CLAUDE_CONFIG/projects"/-*/; do
    [ -d "$encoded_dir" ] || continue
    encoded_name=$(basename "$encoded_dir")
    decoded_path=$(echo "$encoded_name" | sed 's/^-/\//' | sed 's/-/\//g')
    case "$decoded_path" in
        "$HOME") continue ;;
        "$WORKSPACE"|"$WORKSPACE/"*) continue ;;
    esac
    [ -d "$decoded_path" ] || continue
    display_name=$(basename "$decoded_path")
    generate_config_card "$decoded_path" "$display_name" "other"
done

# Close config tab
cat >> "$OUTPUT" << 'CONFIGEND'
                </div>
            </div>
        </div>
CONFIGEND

# Finish HTML with JavaScript
cat >> "$OUTPUT" << 'HTMLFOOT'
    </div>

    <!-- Footer -->
    <div style="max-width: 1000px; margin: 40px auto; padding: 20px 24px; border-top: 1px solid #e5e5e5; text-align: center;">
        <button onclick="copyEditPrompt()" style="background: none; border: 1px solid #ddd; padding: 8px 16px; border-radius: 6px; font-size: 13px; color: #666; cursor: pointer;">
            Edit this app with Claude
        </button>
        <p style="margin-top: 8px; font-size: 11px; color: #999;">
            ClaudeProjects v1.0 &bull; <a href="https://github.com/justinmassa/ClaudeProjects" style="color: #999;">GitHub</a>
        </p>
    </div>

    <div class="toast" id="toast">Copied to clipboard</div>

    <script>
        // Metadata storage
        let meta = JSON.parse(localStorage.getItem('claudeDashboardMeta') || '{"favorites":[],"titles":{},"notes":{},"archived":[]}');

        function saveMeta() {
            localStorage.setItem('claudeDashboardMeta', JSON.stringify(meta));
        }

        function showTab(tabName) {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            document.querySelector('.tab[onclick*="' + tabName + '"]').classList.add('active');
            document.getElementById('tab-' + tabName).classList.add('active');
        }

        // Initialize on load
        document.addEventListener('DOMContentLoaded', () => {
            // Apply saved titles
            document.querySelectorAll('.session').forEach(s => {
                const id = s.dataset.session;
                if (meta.titles[id]) {
                    s.querySelector('.session-title').textContent = meta.titles[id];
                }
                if (meta.favorites.includes(id)) {
                    s.querySelector('.session-star').textContent = '★';
                    s.querySelector('.session-star').classList.add('favorited');
                    addToFavoritesPanel(s);
                }
                if (meta.archived.includes(id)) {
                    s.classList.add('archived');
                }
            });

            // Apply saved notes
            document.querySelectorAll('.project').forEach(p => {
                const id = p.id.replace('proj-', '');
                if (meta.notes[id]) {
                    const textarea = p.querySelector('.project-notes textarea');
                    if (textarea) textarea.value = meta.notes[id];
                }
            });

            // Hide favorites section if empty
            updateFavoritesVisibility();
        });

        function toggle(id) {
            document.getElementById(id).classList.toggle('expanded');
        }

        function copyCmd(cmd) {
            navigator.clipboard.writeText(cmd).then(() => showToast('Copied to clipboard'));
        }

        function copySkill(skill) {
            copyCmd('cd ~/claude-workspace && claude\n\nThen type: /' + skill);
            showToast('Copied! Paste in Warp, then type /' + skill);
        }

        function showToast(msg, duration = 2500) {
            const toast = document.getElementById('toast');
            toast.textContent = msg;
            toast.classList.add('show');
            setTimeout(() => toast.classList.remove('show'), duration);
        }

        function refreshDashboard() {
            location.reload();
        }

        function filterSessions(query) {
            const q = query.toLowerCase();
            let anyVisible = false;

            document.querySelectorAll('.session').forEach(s => {
                const text = (s.dataset.search + ' ' + s.querySelector('.session-title').textContent).toLowerCase();
                const match = !q || text.includes(q);
                s.classList.toggle('hidden', !match);
                if (match) anyVisible = true;
            });

            document.querySelectorAll('.project').forEach(p => {
                const hasSessions = p.querySelectorAll('.session:not(.hidden)').length > 0;
                const nameMatch = p.dataset.project.toLowerCase().includes(q);
                p.style.display = (hasSessions || nameMatch || !q) ? '' : 'none';
                if (q && hasSessions) p.classList.add('expanded');
            });

            document.getElementById('no-results').classList.toggle('show', q && !anyVisible);
        }

        function toggleFavorite(sessionId, path, star) {
            const idx = meta.favorites.indexOf(sessionId);
            const session = star.closest('.session, .favorite-item');

            if (idx > -1) {
                meta.favorites.splice(idx, 1);
                // Update star in both places (original and favorites panel)
                document.querySelectorAll('[data-session="' + sessionId + '"] .session-star').forEach(s => {
                    s.textContent = '☆';
                    s.classList.remove('favorited');
                });
                removeFavorite(sessionId);
            } else {
                meta.favorites.push(sessionId);
                star.textContent = '★';
                star.classList.add('favorited');
                addToFavoritesPanel(session);
            }
            saveMeta();
            updateFavoritesVisibility();
        }

        function addToFavoritesPanel(session) {
            const list = document.getElementById('favorites-list');
            const clone = session.cloneNode(true);
            clone.classList.add('favorite-item');
            clone.classList.remove('session');
            clone.id = 'fav-' + session.dataset.session;
            list.appendChild(clone);
        }

        function removeFavorite(sessionId) {
            const fav = document.getElementById('fav-' + sessionId);
            if (fav) fav.remove();
        }

        function updateFavoritesVisibility() {
            const section = document.getElementById('favorites');
            const list = document.getElementById('favorites-list');
            section.style.display = list.children.length ? '' : 'none';
        }

        function renameSession(sessionId, el) {
            const current = el.textContent;
            const newName = prompt('Rename this session:', current);
            if (newName && newName !== current) {
                el.textContent = newName;
                meta.titles[sessionId] = newName;
                saveMeta();

                // Update in favorites if exists
                const fav = document.getElementById('fav-' + sessionId);
                if (fav) {
                    fav.querySelector('.session-title').textContent = newName;
                }
            }
        }

        function toggleArchive(sessionId, el) {
            const idx = meta.archived.indexOf(sessionId);
            if (idx > -1) {
                meta.archived.splice(idx, 1);
                el.classList.remove('archived');
            } else {
                meta.archived.push(sessionId);
                el.classList.add('archived');
            }
            saveMeta();
        }

        function saveNote(projectId, note) {
            meta.notes[projectId] = note;
            saveMeta();
        }

        function copyEditPrompt() {
            const prompt = `I want to continue working on ClaudeProjects, my session tracker dashboard app. The code lives at:

- Main script: ~/claude-workspace/.claude/scripts/generate-dashboard.sh
- Generated HTML: ~/claude-workspace/.claude/dashboard.html
- App launcher: /Applications/ClaudeProjects.app

Read the generate-dashboard.sh script to understand the current state, then help me with my changes.`;
            navigator.clipboard.writeText(prompt).then(() => {
                showToast('Prompt copied! Paste into a new Claude session', 3500);
            });
        }
    </script>
</body>
</html>
HTMLFOOT

open "$OUTPUT"
