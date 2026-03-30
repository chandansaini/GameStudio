# Life System

> **Status**: Designed — Pending Review
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-25
> **Implements Pillar**: Pillar 1 (Every Placement Is a Deduction)

## Overview

The Life System enforces the cost of wrong placements in LEXICON. It connects
to the GSM's `word_placed_wrong` signal, calls `gsm.deduct_life()` on each
wrong placement, and monitors `lives_remaining`. When lives reach zero, it
calls `gsm.trigger_fail()` to end the puzzle. It also emits a
`lives_restore_eligible` signal when the puzzle has failed and the restore
cooldown window has been met — consumed by the Life Restore Timer at launch.
It owns no display logic; Life Indicator UI handles visuals.

## Player Fantasy

Lives are the stakes that make every placement matter. A wrong placement
should sting — not because the game is cruel, but because the player
recognises they could have reasoned it out. Three lives is enough to
survive early mistakes but not enough to be careless. Losing the last
life should feel like a genuine failure — earned, not arbitrary. The
Life System serves Pillar 1 (Every Placement Is a Deduction) by ensuring
there is always a cost to guessing.

## Detailed Design

### Core Rules

1. Life System connects to GSM's `word_placed_wrong(word, slot_index)` on initialisation.
2. On receiving the signal: call `gsm.deduct_life()`.
3. After deduction, read `gsm.session_state.lives_remaining`:
   - `> 0` → emit `life_lost(lives_remaining)`
   - `== 0` → emit `life_lost(0)`; call `gsm.trigger_fail()`
4. Life System connects to GSM's `puzzle_failed` signal. On receipt, emit
   `lives_restore_eligible()` — the signal that tells the Life Restore Timer
   to start its countdown.
5. Life System is **stateless** — all life data lives in GSM. It only reacts
   to signals and calls GSM methods.
6. Life System does nothing on correct placements.
7. Once `puzzle_failed` fires, GSM enters its terminal state — no further
   `word_placed_wrong` signals are possible.

### States and Transitions

The Life System is stateless and event-driven. No internal states exist — it
activates on signals and completes synchronously within the same frame.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| GSM | signal in | Connects to `word_placed_wrong(word, slot_index)` |
| GSM | signal in | Connects to `puzzle_failed` → emits `lives_restore_eligible()` |
| GSM | calls into | `gsm.deduct_life()`, `gsm.trigger_fail()` |
| Life Indicator UI | signal out | `life_lost(lives_remaining)` → UI updates display |
| Audio System | signal out | `life_lost(lives_remaining)` → plays life-lost SFX |
| Life Restore Timer | signal out | `lives_restore_eligible()` → starts restore countdown |
| Results Screen | indirect | Reads `lives_remaining` from GSM directly on load |

## Formulas

Life System performs no numeric calculations. The deduction math lives in
GSM's `deduct_life()`:

```
lives_remaining = max(0, lives_remaining - 1)
puzzle_fails    = (lives_remaining == 0)
```

Life System reads `lives_remaining` after the call to determine which signal
to emit — it does not compute the value itself.

## Edge Cases

| # | Situation | Resolution |
|---|-----------|------------|
| 1 | `word_placed_wrong` fires when `lives_remaining` is already 0 | Not reachable — GSM enters terminal state after `trigger_fail()`; no further wrong-placement signals possible |
| 2 | `gsm.deduct_life()` called but GSM returns lives > 0, then `puzzle_failed` fires immediately | `puzzle_failed` is authoritative — Life System emits `lives_restore_eligible()` on the signal regardless of its own read of `lives_remaining` |
| 3 | `lives_restore_eligible()` emitted but Life Restore Timer is not yet connected (MVP build) | Signal fires into nothing — no crash; timer is a launch system, safe to wire up later |
| 4 | Two wrong placements in rapid succession | Godot processes signals sequentially; each deduction handled in order — second fires only after first completes |
| 5 | Puzzle solved with 0 lives remaining | Not reachable — `lives_remaining == 0` triggers fail before a final correct placement could resolve the puzzle |

## Dependencies

### Upstream Dependencies

| System | Interface | Type |
|--------|-----------|------|
| Game State Manager | Connects to `word_placed_wrong` and `puzzle_failed` signals; calls `gsm.deduct_life()` and `gsm.trigger_fail()`; reads `gsm.session_state.lives_remaining` | Hard — all life data and fail logic lives in GSM |

### Downstream Dependents

| System | Interface | Type |
|--------|-----------|------|
| Life Indicator UI | Connects to `life_lost(lives_remaining)` | Hard — no other source of life count changes |
| Audio System | Connects to `life_lost(lives_remaining)` for SFX | Soft — game functions without audio |
| Life Restore Timer | Connects to `lives_restore_eligible()` | Soft — launch system; MVP builds run without it |
| Results Screen | Indirect — reads `lives_remaining` from GSM directly | Soft — no direct interface with Life System |

## Tuning Knobs

| Knob | Default | Safe Range | Too Low | Too High |
|------|---------|------------|---------|----------|
| `max_lives` | 3 | 1–5 | 1 life = brutally unforgiving; one mistake ends the puzzle | 5+ lives = placements feel consequence-free; kills tension |

`max_lives` is owned and defined in the Game State Manager GDD. Listed here
for reference only — do not redefine it.

## Visual / Audio Requirements

This system produces no visuals or audio directly.
- Visual feedback (life icon dimming/loss animation) is owned by Life Indicator UI
  reacting to `life_lost(lives_remaining)`.
- Audio feedback (life-lost SFX) is owned by Audio System reacting to the same signal.

## UI Requirements

None. This system contains no display logic.

## Acceptance Criteria

1. Wrong placement → `gsm.deduct_life()` called exactly once; `life_lost(lives_remaining)` emitted with the updated count.
2. Wrong placement with `lives_remaining > 0` after deduction → `life_lost` emitted; `gsm.trigger_fail()` NOT called.
3. Wrong placement that reduces `lives_remaining` to 0 → `life_lost(0)` emitted; `gsm.trigger_fail()` called exactly once.
4. `puzzle_failed` signal received → `lives_restore_eligible()` emitted.
5. Correct placement → no deduction; no signal emitted by Life System.
6. `lives_restore_eligible()` emitted with no listener connected → no crash.
7. Two wrong placements in sequence → two separate `life_lost` events emitted in order; lives decremented correctly each time.

## Open Questions

- Should lives restore fully (back to 3) or partially (back to 1) after the
  cooldown? **Decision deferred to Life Restore Timer GDD** — Life System only
  signals eligibility, not the restore amount.
- Post-launch: should players be able to watch an ad or pay to restore lives
  immediately? Note for monetisation phase — not in scope for launch.
