# Claude Code Game Studios -- Game Studio Agent Architecture

Indie and free-to-play game development managed through 60 coordinated Claude Code subagents.
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

## Future: Game Factory Pipeline

**Not yet implemented. Design is complete — build when ready.**

The goal: input a game idea, receive a signed APK.

### What the factory is

A `/factory` skill that drives the `producer` agent through the full
development lifecycle autonomously, with 3 human approval gates.

### Architecture

```
Input: game idea + business requirements (product-manager)
          ↓
producer orchestrates all 56 agents through lifecycle phases
          ↓
Gate 1: creative-director + product-manager approve concept
Gate 2: technical-director + product-manager approve architecture
Gate 3: game-designer + product-manager validate first build
          ↓
Output: complete project (code + docs + asset specs + strategy)
```

### The remaining gaps to close (in priority order)

1. `/factory` skill — drives producer through the pipeline; uses
   `AskUserQuestion` for the 3 gates; writes state to
   `production/session-state/active.md` between phases
2. **Asset library bridge** — Bash scripts to fetch and wire up free
   asset packs (Kenney.nl, OpenGameArt) as placeholder art; fastest
   path to a visually complete prototype
3. **Build automation** — per-engine build scripts runnable via Bash;
   engine-specific commands for Godot, Unity, Flutter, Cocos, Web
4. **AI image API integration** — Stability AI / DALL-E prompts written
   by `art-director`, executed via Bash API calls; replaces placeholder
   art with generated art for casual game quality
5. **AI audio API integration** — Suno (music) + ElevenLabs (SFX)
   called via Bash; `audio-director` writes prompts and briefs
6. **Code signing** — one-time keystore setup per studio; automates
   APK signing so output is store-ready

### Role clarity in the factory

- `producer` — orchestrates the pipeline (the factory controller)
- `product-manager` — provides business requirements as input; validates
  at each gate that output serves market and KPI goals
- `game-designer` — defines what the game is; active throughout
- These three roles do not conflict: producer runs the machine,
  PM owns the business layer, game-designer owns the player experience
