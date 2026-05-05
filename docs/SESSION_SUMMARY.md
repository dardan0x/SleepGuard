# Session Summary — Vibe Coding System for iOS Apps

## What Was Built

A complete AI-assisted iOS app development system, anchored to IceCubesApp (SwiftUI Mastodon client) architecture patterns. Works with both **Claude Code** and **Kimi Code CLI** — you can switch between them anytime.

## Files Created

```
project-root/
├── CLAUDE.md                      ← Claude Code auto-reads this
├── AGENTS.md                      ← Kimi Code CLI auto-reads this
│
docs/
├── architecture/                  # IceCubes patterns (11 files, read-only reference)
│   ├── INDEX.md (28 lines)        # Quick lookup table
│   ├── overview.md (47)           # App structure, packages, dependency graph
│   ├── navigation.md (137)        # Router, sheets, deep links
│   ├── state.md (116)             # ViewState enums, @Observable singletons, optimistic updates
│   ├── concurrency.md (95)        # .task, cancellation, debouncing
│   ├── dependencies.md (114)      # @Environment DI, withAppDependencyGraph()
│   ├── views.md (121)             # Composition, naming, placeholders, platform branching
│   ├── modules.md (60)            # Package isolation, inter-feature communication
│   ├── networking.md (154)        # MastodonClient, Endpoint protocol, pagination
│   ├── feature-template.md (242)  # 5-step copy-paste template
│   ├── rules.md (52)              # 20 Do's, 8 Don'ts, anti-patterns
│   └── PROMPTS.md (429)           # IceCubes prompt cookbook (kept as reference, not used in workflow)
│
├── templates/                     # Tracker templates (AI copies from here in Phase 0)
│   ├── FeatureTracker.md          # Dashboard/index template with auto-update rules
│   └── feature-tracker-detail.md  # Per-feature file template with auto-update rules
│
├── VIBE_CODING_WORKFLOW.md        # The manufacturing process (unified for both tools)
├── SIMULATION_SNORING_ANALYZER.md # 30-prompt simulation of full app build
├── CLAUDE_TEMPLATE.md             # → copy as CLAUDE.md in new projects
├── AGENTS_TEMPLATE.md             # → copy as AGENTS.md in new projects
├── KICKOFF_PROMPT.md (79)         # One prompt to start any new project (tool-agnostic)
├── SETUP_GUIDE.md                 # Manual setup for both Claude Code and Kimi Code CLI
│
└── simulation/                    # Example FeatureTracker (split format)
    ├── FeatureTracker.md (54)     # Index: summary + feature status + links
    └── trackers/                  # One file per feature with task details
        ├── f1-live-session.md (95)
        ├── f2-session-history.md (44)
        ├── f3-session-detail.md (42)
        ├── f4-trends.md (31)
        └── f5-settings.md (42)
```

## Key Design Decisions

1. **Unified workflow for both tools** — One `docs/` folder, one `VIBE_CODING_WORKFLOW.md`, one set of trackers. Both Claude and Kimi read the same state and follow the same process.

2. **Tool-specific rule files in project root** — `CLAUDE.md` for Claude Code, `AGENTS.md` for Kimi Code CLI. Each tool auto-reads its own. Everything else is shared.

3. **Architecture split into 11 files** — The AI reads only what's needed per task (e.g., navigation.md = 137 lines, not 500+). Saves tokens.

4. **No ViewModels** — modern pattern uses `@State` with `ViewState` enums directly in views. `@Environment` for shared state. No Combine.

5. **Split FeatureTracker** — index file (summary table + links) + one file per feature (task details, acceptance criteria, prompts used). AI reads only the feature being worked on.

6. **Sync embedded in every task prompt** — three sections: `BEFORE CODING` (set In Progress) → `IMPLEMENTATION` (code + build) → `AFTER VERIFIED` (set Done, update trackers). No separate sync prompts needed.

7. **Notion MCP as primary task system** — Notion is the external source of truth, local tracker is the mirror. Both stay in sync after every task. Works identically in Claude and Kimi.

8. **MCP servers shared** — XcodeBuildMCP, Notion MCP, and iOS MCP servers work the same in both tools. Config files differ (`~/.claude/settings.json` vs `~/.kimi/mcp.json`) but the servers are the same.

## Workflow Summary (14-step loop)

```
SESSION START: Read Notion MCP → Read FeatureTracker → Pick task
PER TASK:      One prompt (Before → Code → After) → Review → Fix → Repeat
FEATURE DONE:  Feature doc → Update ProjectArchitecture → Notion sync
SESSION END:   Sprint Log → Verify tracker matches Notion
```

## How to Start a New Project

1. Manual setup: folder, git, install AI tool, configure MCP servers, copy docs/ (see SETUP_GUIDE.md)
2. Copy both `CLAUDE.md` and `AGENTS.md` to project root
3. Fill in `KICKOFF_PROMPT.md` with app details
4. Send to Claude or Kimi
5. The AI runs Phase 0-4 of `VIBE_CODING_WORKFLOW.md`

## Tool Switching

You can switch between Claude Code and Kimi Code CLI at any time:
- Both read the same `docs/FeatureTracker.md` and `docs/trackers/*.md`
- Both sync to the same Notion databases
- Both use the same MCP servers
- Both follow the same `VIBE_CODING_WORKFLOW.md`

Just open the project with the other tool and send the session start prompt. The AI will pick up exactly where the previous one left off.

## Where to Edit What

| Want to change... | Edit this file |
|---|---|
| Coding principles (Claude) | `CLAUDE_TEMPLATE.md` → project's `CLAUDE.md` |
| Coding principles (Kimi) | `AGENTS_TEMPLATE.md` → project's `AGENTS.md` |
| Workflow phases, task structure, sync points | `VIBE_CODING_WORKFLOW.md` |
| Architecture patterns (navigation, state, DI, etc.) | `docs/architecture/[topic].md` |
| What the AI reads on first prompt | `KICKOFF_PROMPT.md` |
| Pre-flight setup instructions | `SETUP_GUIDE.md` |
| Feature tracker format | `VIBE_CODING_WORKFLOW.md` Phase 0 Step 3 |
| Notion database schemas | `VIBE_CODING_WORKFLOW.md` Phase 0 Step 4 |
| Task prompt structure (BEFORE/IMPLEMENTATION/AFTER) | `VIBE_CODING_WORKFLOW.md` Phase 3 Step 2 |
| Example of complete project simulation | `SIMULATION_SNORING_ANALYZER.md` |
| Example of split tracker in action | `docs/simulation/` |

## Tool Comparison

| Aspect | Claude Code | Kimi Code CLI |
|--------|-------------|---------------|
| Project memory file | `CLAUDE.md` | `AGENTS.md` |
| Plan mode | `/plan` slash command | `EnterPlanMode` tool |
| Build tool | `XcodeBuildMCP` (MCP server) | `XcodeBuildMCP` (MCP server) |
| Notion integration | Notion MCP (native) | Notion MCP (native) |
| GitHub integration | `gh` CLI via Shell | `gh` CLI via Shell |
| Primary source of truth | Notion (via MCP) | Notion (via MCP) |
| MCP config file | `~/.claude/settings.json` | `~/.kimi/mcp.json` |
| Install method | `npm install -g @anthropic-ai/claude-code` | `uv tool install kimi-cli` or `pip install kimi-cli` |
| Shared state | `docs/FeatureTracker.md`, `docs/trackers/*.md`, Notion | Same |
| Workflow file | `docs/VIBE_CODING_WORKFLOW.md` | Same |
| Architecture docs | `docs/architecture/*.md` | Same |
