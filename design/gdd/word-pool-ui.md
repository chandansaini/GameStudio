# Word Pool UI

> **Status**: Designed — Pending Review
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-25
> **Implements Pillar**: Pillar 1 (Every Placement Is a Deduction)

## Overview

Word Pool UI displays the full set of unplaced words for the current puzzle,
handles word button clicks by forwarding them to Slot Assignment, and keeps
its display in sync with selection and placement state. It renders each word
as a tappable button, highlights the currently selected word, removes correctly
placed words from view, and briefly marks wrong placements before the word
returns to its normal state. It reads the initial word list from GSM at scene
load and connects to Slot Assignment's signals for all subsequent updates. It
owns no interaction logic — Slot Assignment decides what a click means; Word
Pool UI only shows the result.

## Player Fantasy

The word pool is the player's hand of cards. At a glance, they should be
able to scan all available words and feel the puzzle taking shape. The
selected word should feel "held" — visually distinct, ready to be placed.
Words that disappear on correct placement confirm progress and quietly
reduce the cognitive load: fewer words, clearer picture. A wrong placement
should produce a brief, honest flash of feedback — not punishing, just
acknowledgement — before the word settles back into the pool. The pool
should never feel cluttered or confusing; it should feel like a clean
workspace that gets tidier as the player reasons their way through.

## Detailed Design

### Core Rules

1. On scene load, read `gsm.session_state` to build the initial word list:
   - Include all words from the puzzle not yet placed (`word not in any slot_state.placed_words`)
   - Render one button per word; order is fixed (alphabetical — see Open Questions)
2. Each word button, when clicked, calls `slot_assignment.on_word_clicked(word)`.
3. Connect to Slot Assignment signals on initialisation:
   - `word_selected(word)` → apply **selected** visual state to that button
   - `word_deselected()` → remove selected state from all buttons
   - `placement_correct(word, slot_index)` → remove that word's button from the pool
   - `placement_wrong(word, slot_index)` → apply **wrong** visual state briefly, then return to normal
4. Connect to GSM signals:
   - `puzzle_solved` or `puzzle_failed` → disable all word buttons (LOCKED state)
5. **Wrong flash duration**: ~0.4s visual feedback then auto-resets to normal. No
   interaction is blocked during the flash.
6. Placed words do not appear in the pool after a correct placement — buttons are
   freed, not hidden.

### States and Transitions

Per-button state machine:

| State | Visual | Entry | Exit |
|-------|--------|-------|------|
| `NORMAL` | Default style | Scene load; wrong flash ends; deselection | Clicked; wrong placement |
| `SELECTED` | Highlighted (elevated, coloured border) | `word_selected` signal | `word_deselected` signal; placement result |
| `WRONG_FLASH` | Error colour (brief ~0.4s) | `placement_wrong` signal | After ~0.4s → NORMAL |
| `REMOVED` | Freed from scene | `placement_correct` signal | Never — terminal |

All buttons enter `DISABLED` (no interaction, no visual change) on `puzzle_solved`
or `puzzle_failed`. DISABLED is an overlay condition, not a state in the per-button
machine.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Slot Assignment | calls into | `slot_assignment.on_word_clicked(word)` on button press |
| Slot Assignment | signal in | `word_selected(word)`, `word_deselected()`, `placement_correct(word, slot_index)`, `placement_wrong(word, slot_index)` |
| GSM | reads from | `session_state` at scene load for initial word list |
| GSM | signal in | `puzzle_solved`, `puzzle_failed` → disable all buttons |

## Formulas

One timed calculation — the wrong flash reset:

```
wrong_flash_duration = 0.4s  (tuning knob)

On placement_wrong signal:
  apply WRONG_FLASH visual
  start Tween: wait wrong_flash_duration → reset to NORMAL
```

No other math. Button layout and sizing is handled by Godot container nodes —
no manual calculation required.

## Edge Cases

| # | Situation | Resolution |
|---|-----------|------------|
| 1 | `word_selected` fires for a word not in the pool (already removed) | No-op — button no longer exists; signal ignored |
| 2 | `placement_wrong` fires during WRONG_FLASH (rapid double wrong) | Not reachable — Slot Assignment clears selection after any placement result; second wrong can't fire until player re-selects |
| 3 | `puzzle_solved` or `puzzle_failed` fires while a word is in WRONG_FLASH | Flash Tween completes normally; buttons disabled regardless — no visual conflict |
| 4 | Scene loads mid-puzzle (resume) with some words already placed | GSM `session_state` filters placed words at load time — only unplaced words rendered |
| 5 | All words placed before `puzzle_solved` signal fires | All buttons already REMOVED; signal disables empty pool — no-op, no crash |
| 6 | Word pool contains only one word | Renders as single button; no layout issues with Godot containers |
| 7 | `word_deselected` fires with no word currently selected | No-op — no button in SELECTED state; nothing to reset |

## Dependencies

### Upstream Dependencies

| System | Interface | Type |
|--------|-----------|------|
| Slot Assignment | Calls `on_word_clicked(word)`; connects to `word_selected`, `word_deselected`, `placement_correct`, `placement_wrong` | Hard — no other source of selection or placement events |
| Game State Manager | Reads `session_state` at scene load for initial word list; connects to `puzzle_solved`, `puzzle_failed` | Hard — cannot build pool without word list |

### Downstream Dependents

None. Word Pool UI is a leaf node — no other system depends on it.

## Tuning Knobs

| Knob | Default | Safe Range | Too Low | Too High |
|------|---------|------------|---------|----------|
| `wrong_flash_duration` | 0.4s | 0.2–0.8s | Flash too brief to register — player misses feedback | Flash too long — word feels locked out; breaks flow |

Layout, font size, and button dimensions are UI polish concerns — not gameplay
tuning knobs.

## Visual / Audio Requirements

- Word buttons require two distinct visual states beyond NORMAL: SELECTED
  (player is holding this word) and WRONG_FLASH (wrong placement feedback).
- SELECTED: suggest elevation, colour border, or fill change — must be
  immediately readable at a glance.
- WRONG_FLASH: error colour (red or equivalent); brief enough to not feel
  punishing. Exact colours and animation owned by art direction pass.
- No audio produced directly — Audio System reacts to Slot Assignment signals
  independently.

## UI Requirements

- Word buttons must be large enough for comfortable tap targets on mobile
  (minimum 44×44pt per platform guidelines).
- Pool layout uses a Godot `FlowContainer` or `GridContainer` — words wrap
  automatically; no manual positioning.
- Word text must be legible at smallest expected screen size; font size
  and truncation handled in UI polish pass.

## Acceptance Criteria

1. Scene load renders exactly the unplaced words from the current puzzle — no placed words visible.
2. Clicking a word button calls `slot_assignment.on_word_clicked(word)` exactly once.
3. `word_selected(word)` signal → that word's button enters SELECTED visual state; all others remain NORMAL.
4. `word_deselected()` signal → all buttons return to NORMAL state.
5. `placement_correct(word, slot_index)` → that word's button is removed from the pool; no longer visible or interactive.
6. `placement_wrong(word, slot_index)` → that word's button flashes WRONG_FLASH for `wrong_flash_duration`, then returns to NORMAL.
7. `puzzle_solved` or `puzzle_failed` → all remaining word buttons are disabled; no clicks processed.
8. Scene loaded mid-puzzle with words already placed → only unplaced words rendered; no crash.
9. `word_selected` signal for a word already removed → no crash; no-op.
10. `word_deselected` with no button in SELECTED state → no crash; no-op.

## Open Questions

- Should words be ordered alphabetically or in puzzle-authored order? Alphabetical
  reduces the risk of order giving away groupings; authored order allows intentional
  misdirection. **Recommendation: alphabetical for MVP** — revisit if puzzle authors
  want control over order.
