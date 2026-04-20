# Claude Code Game Studios -- Game Studio Agent Architecture

Indie and free-to-play game development managed through 56 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Studio Structure

This is a **multi-game, multi-engine studio**. Each game lives under `projects/<game-name>/`
with its own `CLAUDE.md` that defines the engine, language, and project-specific settings.

**At the start of every project session**, check the project's own `CLAUDE.md` for:
- Engine and version
- Language and build system
- Project-specific technical preferences
- `studio_mode` — either `indie` or `f2p`. Eight agents change behaviour based
  on this value. If absent, assume `indie`.

> **Starting a new project?** Run `/setup-engine` inside the project folder to pin
> the engine and populate reference docs.

## Technology Stack

- **Engine**: Per-project (see `projects/<game-name>/CLAUDE.md`)
- **Version Control**: Git with trunk-based development
- **Supported Engines**: Godot, Unity, Unreal, Cocos Creator, Flutter/Flame, Web/HTML5 (specialist agents exist for all)

## Active Projects

| Project | Engine | Status |
|---------|--------|--------|
| FLASHPOINT | Unity 6 LTS | Active |
| LEXICON | Godot 4.3 | Archived → `projects/lexicon/` |

## Project Structure

@.claude/docs/directory-structure.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
