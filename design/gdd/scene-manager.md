# Scene Manager

> **Status**: Designed — Pending Review
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-24
> **Implements Pillar**: Infrastructure — enables all UI flow

## Overview

The Scene Manager controls navigation between LEXICON's three screens: Main
Menu, Puzzle, and Results. It is the single point of authority for all scene
transitions — no scene loads itself or another scene directly. It accepts
transition requests from other systems (e.g., "go to puzzle", "go to results"),
handles the Godot scene change, passes required data to the incoming scene, and
optionally plays a transition animation between screens. It holds no game state
and has no knowledge of puzzle content — it only knows which screen is active
and how to get to the next one.

## Player Fantasy

The Scene Manager is invisible to the player. Its fantasy is seamless flow —
the player should never feel a jarring jump between screens, a freeze during
load, or a moment of confusion about where they are. Transitions should feel
intentional: entering a puzzle feels like opening something, leaving to results
feels like a reveal. When it works, the player experiences LEXICON as one
continuous space, not a collection of disconnected screens.

## Detailed Design

### Core Rules

1. The Scene Manager is a Godot **Autoload singleton** — accessible from any
   scene via `SceneManager.method()` without a node reference.
2. Three scenes exist at launch: `MainMenu`, `Puzzle`, `Results`. No other
   scenes are loaded directly.
3. All transitions go through one of three methods:
   - `go_to_puzzle(puzzle_id: int)` — called by Main Menu; passes `puzzle_id`
     to the Puzzle scene on load
   - `go_to_results()` — called when GSM emits `puzzle_solved` or `puzzle_failed`
   - `go_to_main_menu()` — called by the Results screen "Back" button
4. Transition sequence: fade to black (0.2s) → change scene → fade in (0.2s).
5. While a transition is `IN_PROGRESS`, all subsequent transition calls are
   ignored — no double-transitions possible.
6. `puzzle_id` is passed to the Puzzle scene via a direct method call on the
   incoming scene's root node immediately after load.

### States and Transitions

| State | Meaning | Entry | Exit |
|-------|---------|-------|------|
| `IDLE` | No transition in progress | App start; transition complete | Any `go_to_*()` call |
| `TRANSITIONING` | Fade + scene change in progress | Any `go_to_*()` call while IDLE | Fade-in complete |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Main Menu | called by | Calls `go_to_puzzle(puzzle_id)` on "Play" button press |
| GSM | signal | Connects to `puzzle_solved` and `puzzle_failed` → calls `go_to_results()` |
| Results Screen | called by | Calls `go_to_main_menu()` on "Back" button press |
| Daily Lock System | reads from | Main Menu reads `puzzle_id` from Daily Lock before calling `go_to_puzzle()` |

## Formulas

```
total_transition_duration = fade_out_duration + fade_in_duration
                          = 0.2s + 0.2s
                          = 0.4s per transition
```

No other calculations. All timing values are tuning knobs (see below).

## Edge Cases

| # | Situation | Resolution |
|---|-----------|------------|
| 1 | `go_to_*()` called while already `TRANSITIONING` | Ignored — no-op; current transition completes uninterrupted |
| 2 | `go_to_puzzle()` called with an invalid `puzzle_id` | Puzzle scene receives the ID; Puzzle Library handles the invalid ID — not Scene Manager's responsibility |
| 3 | `go_to_results()` called before GSM is initialised | Results scene reads from GSM on load; if GSM has no state, Results screen shows a fallback empty state |
| 4 | Player presses Back/Escape during a transition | Input ignored while `TRANSITIONING`; processed after transition completes |
| 5 | Scene file missing or corrupt on disk | Godot's `change_scene_to_file()` throws an error; log and return to Main Menu as fallback |
| 6 | App launched for the first time (no saved state) | Scene Manager always opens to `MainMenu` on launch — no conditional logic needed |
| 7 | `go_to_results()` triggered twice rapidly | Second call ignored while `TRANSITIONING` — state guard handles this |

## Dependencies

### Upstream Dependencies

None. The Scene Manager is a Foundation layer system with no dependencies on
other game systems.

### Downstream Dependents

| System | Interface |
|--------|-----------|
| Main Menu | Calls `go_to_puzzle(puzzle_id)` on "Play" button press |
| GSM | Scene Manager connects to `puzzle_solved` and `puzzle_failed` signals |
| Results Screen | Calls `go_to_main_menu()` on "Back" button press |

## Tuning Knobs

| Knob | Default | Safe Range | Too Low | Too High |
|------|---------|------------|---------|----------|
| `fade_out_duration` | 0.2s | 0.1–0.5s | Jarring instant cut | Player waits noticeably before scene changes |
| `fade_in_duration` | 0.2s | 0.1–0.5s | New scene pops in abruptly | Slow reveal feels like a loading problem |

Keep `fade_out_duration` and `fade_in_duration` symmetric for a polished feel.
Total transition overhead: 0.4s at defaults.

## Visual / Audio Requirements

- Fade overlay: full-screen black `ColorRect` node animated via `Tween`.
  No art assets required — pure code.
- No audio tied to transitions at launch. Optional whoosh SFX can be added
  in the polish phase.

## UI Requirements

None. The Scene Manager is not a UI system. It owns the transition overlay
only; all screen content is owned by individual scene roots.

## Acceptance Criteria

1. `go_to_puzzle(id)` transitions from Main Menu to Puzzle scene; Puzzle scene
   receives the correct `puzzle_id` on load.
2. GSM `puzzle_solved` signal triggers transition to Results scene.
3. GSM `puzzle_failed` signal triggers transition to Results scene.
4. Results "Back" button triggers transition to Main Menu.
5. Calling any `go_to_*()` during an active transition is a no-op — no
   double scene load occurs.
6. Fade out and fade in play on every transition — no instant cuts in
   production builds.
7. App always opens to Main Menu on launch regardless of save state.
8. Scene Manager is accessible as an Autoload from any scene without a node
   reference.

## Open Questions

- Should fade colour be configurable (black vs. white vs. brand colour)?
  Black is the safest default — revisit in polish phase if needed.
