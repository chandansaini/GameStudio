# Puzzle Library

> **Status**: Designed — Pending Review
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-24
> **Implements Pillar**: Pillar 3 (One Perfect Puzzle)

## Overview

The Puzzle Library is a registry of all authored LEXICON puzzles. At game
startup it loads every puzzle resource file from a designated directory,
validates each one against the Puzzle Data System rules, rejects malformed
puzzles (hard block in debug, silent skip in production), and indexes valid
puzzles by both `id` and `publish_date`. It exposes two lookup methods:
`get_puzzle_by_date(date: String)` and `get_puzzle_by_id(id: int)`. It holds
no runtime game state — it is a read-only catalogue that other systems query.
The Daily Lock System is its only consumer at launch.

## Player Fantasy

The Puzzle Library is invisible to the player. Its fantasy belongs to the
puzzle author: every puzzle they craft is reliably stored, discoverable, and
served on the right day without manual intervention. For the player, it
manifests as quiet confidence — today's puzzle is always there, always valid,
never missing.

## Detailed Design

### Core Rules

1. The Puzzle Library is a Godot **Autoload singleton**, initialised once at
   startup.
2. On startup, it scans `res://data/puzzles/` and loads all `.tres` files
   found there.
3. Each loaded file is validated against Puzzle Data System rules. Invalid
   puzzles are rejected per the two-tier rule (hard block in debug / silent
   skip in production).
4. Valid puzzles are stored in two dictionaries:
   - `_by_date: Dictionary` — key: `publish_date` (String "YYYY-MM-DD"),
     value: `PuzzleData`
   - `_by_id: Dictionary` — key: `id` (int), value: `PuzzleData`
5. If two puzzles share a `publish_date`, the one with the lower `id` is kept;
   the other is logged as a warning and discarded.
6. After startup the library is read-only — no puzzles are added or removed
   at runtime.
7. `get_puzzle_by_date(date: String) -> PuzzleData` — returns the puzzle for
   that date, or `null` if none exists.
8. `get_puzzle_by_id(id: int) -> PuzzleData` — returns the puzzle with that
   id, or `null` if none exists.

### States and Transitions

| State | Meaning | Entry | Exit |
|-------|---------|-------|------|
| `LOADING` | Scanning and validating puzzle files | App startup | All files processed |
| `READY` | Library indexed, available for queries | Loading complete | Never — stays READY |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Puzzle Data System | reads from | Uses validation rules at load time; stores `PuzzleData` resources |
| Daily Lock System | called by | Calls `get_puzzle_by_date(today)` to retrieve today's puzzle |

## Formulas

None. The Puzzle Library indexes and retrieves puzzle resources — no
calculations are performed.

## Edge Cases

| # | Situation | Resolution |
|---|-----------|------------|
| 1 | `res://data/puzzles/` directory is empty | Library initialises with empty index; Daily Lock System receives `null` and handles it |
| 2 | `get_puzzle_by_date()` called before `READY` | Return `null` and log a warning |
| 3 | Date string in wrong format (not "YYYY-MM-DD") | Return `null`; do not crash |
| 4 | Two puzzles share `publish_date` | Keep lower `id`; log warning; discard other |
| 5 | Non-`.tres` files in puzzle directory | Silently skipped — only `.tres` files loaded |
| 6 | `.tres` file exists but is not a `PuzzleData` resource | Rejected at validation; two-tier rejection applies |
| 7 | `get_puzzle_by_id()` called with unknown id | Return `null` |

## Dependencies

### Upstream Dependencies

| System | Interface | Type |
|--------|-----------|------|
| Puzzle Data System | Loads and validates `PuzzleData` resources at startup | Hard — library cannot function without puzzle data structure |

### Downstream Dependents

| System | Interface | Type |
|--------|-----------|------|
| Daily Lock System | `get_puzzle_by_date(date: String)` | Hard — Daily Lock cannot serve today's puzzle without the library |

## Tuning Knobs

| Knob | Default | Safe Range | Notes |
|------|---------|------------|-------|
| `puzzle_directory` | `res://data/puzzles/` | Any valid Godot resource path | Change only if puzzle files are reorganised; must contain `.tres` files |

## Visual / Audio Requirements

None. The Puzzle Library is a data registry with no visual or audio output.

## UI Requirements

None. The Puzzle Library is not player-facing.

## Acceptance Criteria

1. All valid `.tres` files in `res://data/puzzles/` are loaded and indexed
   on startup.
2. `get_puzzle_by_date("YYYY-MM-DD")` returns the correct `PuzzleData` or
   `null` if no puzzle exists for that date.
3. `get_puzzle_by_id(n)` returns the correct `PuzzleData` or `null` if no
   puzzle exists with that id.
4. Two puzzles sharing a `publish_date` — lower `id` is kept, warning logged,
   higher `id` discarded.
5. Invalid puzzle files rejected per two-tier rule: hard block in debug,
   silent skip in production.
6. Non-`.tres` files in the puzzle directory are silently ignored.
7. Empty puzzle directory initialises cleanly with no crash.
8. Library remains read-only after startup — no runtime modifications.

## Open Questions

- Should the library support hot-reloading puzzles at runtime (e.g., for
  editor tooling)? Not needed for launch — note for future tooling work.
