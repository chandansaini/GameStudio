# Life Indicator UI

> **Status**: Designed — Pending Review
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-25
> **Implements Pillar**: Pillar 1 (Every Placement Is a Deduction)

## Overview

Life Indicator UI displays the player's current life count as a row of 3 icons.
It reads the initial count from GSM at scene load, connects to Life System's
`life_lost(lives_remaining)` signal to animate a life loss, and connects to
GSM's `puzzle_failed` to show the zero-lives terminal state. It owns no logic —
it is a pure visual display of `lives_remaining`.

## Player Fantasy

The life icons are a constant peripheral presence — the player glances at them
to know how much margin they have left. Losing a life should feel visceral: an
icon dims or shatters, the remaining ones feel more precious. At zero, the empty
row is a quiet verdict. The indicator should never feel noisy or distracting when
lives are full — it only demands attention when something goes wrong.

## Detailed Design

### Core Rules

1. On scene load, read `gsm.session_state.lives_remaining` and render that many
   active icons (out of `max_lives`).
2. Connect to `life_system.life_lost(lives_remaining)` → play loss animation on
   the icon being lost; update display to show `lives_remaining` active icons.
3. Connect to `gsm.puzzle_solved` → no change (lives remaining shown as-is).
4. Connect to `gsm.puzzle_failed` → ensure all icons show LOST state.
5. Icons are display-only — not interactive.

### States and Transitions

Per-icon state machine:

| State | Visual | Entry | Exit |
|-------|--------|-------|------|
| `FULL` | Active icon (filled heart / symbol) | Scene load if within `lives_remaining` | `life_lost` reduces count below this icon's position |
| `LOST` | Dimmed / empty icon | `life_lost` animation completes | Never — terminal per session |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Life System | signal in | `life_lost(lives_remaining)` → animate loss, update display |
| GSM | reads from | `session_state.lives_remaining` at scene load |
| GSM | signal in | `puzzle_failed` → ensure all icons in LOST state |

## Formulas

```
active_icons = lives_remaining
lost_icons   = max_lives - lives_remaining
```

No other math. `max_lives` is read from GSM.

## Edge Cases

| # | Situation | Resolution |
|---|-----------|------------|
| 1 | `life_lost(0)` fires | All icons enter LOST state; `puzzle_failed` follows — both handled gracefully |
| 2 | Scene loads with `lives_remaining < max_lives` (resume) | Icons initialised from GSM — correct LOST/FULL split at load |
| 3 | `puzzle_solved` with lives remaining | Icons stay in current state — results screen shows lives separately |

## Dependencies

### Upstream Dependencies

| System | Interface | Type |
|--------|-----------|------|
| Life System | Connects to `life_lost(lives_remaining)` | Hard — no other source of life change events |
| Game State Manager | Reads `lives_remaining` at scene load; connects to `puzzle_failed` | Hard — needs initial state |

### Downstream Dependents

None. Life Indicator UI is a leaf node — no other system depends on it.

## Tuning Knobs

None. `max_lives` is owned and defined in the Game State Manager GDD.

## Visual / Audio Requirements

- Icons require two distinct visual states: FULL (active) and LOST (dimmed/empty).
- Loss animation (shake, shatter, or dim transition) owned by art direction pass.
- No audio produced directly — Audio System reacts to `life_lost` independently.

## UI Requirements

- 3 icons in a horizontal row; fixed position at top of puzzle screen.
- Icons must be legible at smallest expected screen size.
- Row width fixed to `max_lives` slots — lost icons remain as empty placeholders,
  not removed, so the row width never changes.

## Acceptance Criteria

1. Scene load renders `lives_remaining` active icons and `max_lives - lives_remaining` lost icons.
2. `life_lost(lives_remaining)` → one icon transitions from FULL to LOST with animation; display matches new count.
3. `life_lost(0)` → all icons in LOST state; no crash.
4. `puzzle_failed` → all icons in LOST state regardless of current display.
5. Icons are not interactive — clicks do nothing.
6. Scene loaded mid-puzzle with 1 or 2 lives remaining → correct FULL/LOST split shown.

## Open Questions

None.
