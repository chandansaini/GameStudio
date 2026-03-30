# Slot Assignment

> **Status**: Designed — Pending Review
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-25
> **Implements Pillar**: Pillar 1 (Every Placement Is a Deduction)

## Overview

The Slot Assignment system owns the player's core interaction in LEXICON:
selecting a word from the word pool and assigning it to a slot. It uses a
two-step click model — the player clicks a word to select it, then clicks a
slot to place it. On placement, it calls `gsm.place_word(word, slot_index)`
and handles the result: a correct placement clears the selection and removes
the word from the pool; a wrong placement deducts a life and returns the word
to an unselected state. It owns no visual rendering — Word Pool UI and Slot UI
handle display — but it maintains the current selection state and drives the
interaction flow between the two.

## Player Fantasy

Every click should feel considered. When the player selects a word, they've
already formed a hypothesis — the selection is a commitment to a line of
reasoning. When they click a slot, they're testing that hypothesis. The
interaction should never feel rushed or accidental; it should feel like
placing a chess piece. Correct placements feel satisfying and deliberate.
Wrong placements sting — not because the game is cruel, but because the
player knows they should have seen it. This system serves Pillar 1 (Every
Placement Is a Deduction) by making each placement a two-beat action:
*think*, then *act*.

## Detailed Design

### Core Rules

1. Slot Assignment maintains a single `selected_word` state: either `null`
   (nothing selected) or a `String` (a word from the pool).
2. **Word click**:
   - No word selected → select clicked word; emit `word_selected(word)`
   - Clicked word is already selected → deselect; emit `word_deselected()`
   - Different word clicked while one selected → swap; emit `word_selected(new_word)`
3. **Slot click** (only valid when `selected_word != null`):
   - Call `gsm.place_word(selected_word, slot_index)`
   - `CORRECT` → emit `placement_correct(word, slot_index)`; `selected_word = null`
   - `WRONG` → emit `placement_wrong(word, slot_index)`; `selected_word = null`
   - `SLOT_SOLVED` → no-op; slot is already complete
   - `ALREADY_PLACED` → no-op; log warning
   - `INVALID` → no-op; log warning
4. Slot click when `selected_word == null` is a no-op.
5. Clicking outside any word or slot deselects current selection.
6. Solved slots are not valid placement targets.
7. Already-placed words are not valid selection targets — defended here even
   though Word Pool UI should not render them.

### States and Transitions

| State | Meaning | Entry | Exit |
|-------|---------|-------|------|
| `IDLE` | Nothing selected | Startup; placement resolves; deselection | Word clicked |
| `WORD_SELECTED` | Word held, awaiting slot click | Word clicked while IDLE | Slot clicked (any result); word re-clicked; outside click |
| `LOCKED` | Puzzle terminal — no interaction | GSM `puzzle_solved` or `puzzle_failed` | Never — terminal |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| GSM | calls into | `gsm.place_word(word, slot_index)` → result enum |
| GSM | signal in | Connects to `puzzle_solved` + `puzzle_failed` → enters `LOCKED` |
| Word Pool UI | signal out | `word_selected(word)`, `word_deselected()` |
| Slot UI | signal out | `placement_correct(word, slot_index)`, `placement_wrong(word, slot_index)` |
| Audio System | signal out | Same signals — Audio plays placement SFX |

## Formulas

Slot Assignment performs no numeric calculations. The system is pure state
logic. The complete transition function is:

```
on_word_clicked(word):
  if state == LOCKED:           → no-op
  if word.is_placed:            → no-op (defended; pool should not render placed words)
  if selected_word == null:     → selected_word = word; state = WORD_SELECTED
  if selected_word == word:     → selected_word = null; state = IDLE
  if selected_word != word:     → selected_word = word; state = WORD_SELECTED (swap)

on_slot_clicked(slot_index):
  if state != WORD_SELECTED:    → no-op
  if slot.is_solved:            → no-op
  result = gsm.place_word(selected_word, slot_index)
  selected_word = null
  state = IDLE
  → emit signal per result (see Core Rules)

on_outside_clicked():
  if state == WORD_SELECTED:    → selected_word = null; state = IDLE

on_puzzle_solved() / on_puzzle_failed():
  state = LOCKED
  selected_word = null
```

No variables, no ranges — all branching is boolean.

## Edge Cases

| # | Situation | Resolution |
|---|-----------|------------|
| 1 | Word clicked while already selected | Deselects — `selected_word = null`; `state = IDLE`; emit `word_deselected()` |
| 2 | Different word clicked while one is selected | Swaps selection — `selected_word = new_word`; emit `word_selected(new_word)`; no deselect event fired |
| 3 | Slot clicked with no word selected | No-op; no feedback — slot does not animate or respond |
| 4 | Already-solved slot clicked while a word is selected | No-op; selection is preserved — player can still click another slot |
| 5 | `place_word()` returns `ALREADY_PLACED` | No-op; log warning; selection cleared — programming error upstream |
| 6 | `place_word()` returns `INVALID` | No-op; log warning; selection cleared — bad slot index; not reachable in normal play |
| 7 | `puzzle_solved` or `puzzle_failed` fires while a word is selected | Clears selection; enters `LOCKED` — in-flight selection is silently dropped |
| 8 | Player clicks outside any word or slot | Deselects if `WORD_SELECTED`; no-op if `IDLE` or `LOCKED` |
| 9 | Already-placed word is clicked (pool bug) | No-op; log warning — pool UI should not render placed words, but defended here regardless |
| 10 | Two clicks arrive in the same frame (double-tap) | Godot processes input sequentially; each click handled in order — no race condition |

## Dependencies

### Upstream Dependencies

| System | Interface | Type |
|--------|-----------|------|
| Game State Manager | Calls `gsm.place_word(word, slot_index)` → result enum; reads `slot_states[slot_index].is_solved`; connects to `puzzle_solved` + `puzzle_failed` signals | Hard — cannot resolve placements without GSM |
| Puzzle Data System | Indirect — GSM owns puzzle data; no direct interface | Soft — no direct coupling |

### Downstream Dependents

| System | Interface | Type |
|--------|-----------|------|
| Word Pool UI | Connects to `word_selected(word)` and `word_deselected()` to highlight/unhighlight selection | Hard — no other source of selection state |
| Slot UI | Connects to `placement_correct(word, slot_index)` and `placement_wrong(word, slot_index)` to trigger animations | Hard — no other source of placement events |
| Audio System | Connects to `placement_correct` and `placement_wrong` to play SFX | Soft — game functions without audio |
| Letter Reveal System | Indirect — connects to GSM's `word_placed_correct` signal, which GSM emits after `place_word()` succeeds | Soft — no direct interface |

## Tuning Knobs

None. Slot Assignment is pure interaction logic with no designer-adjustable
values. Interaction timing and animations are owned by Word Pool UI and Slot UI.
Game rules (lives, placement validity) are owned by Game State Manager.

## Visual / Audio Requirements

This system produces no visuals or audio directly.
- Visual feedback (word highlight, slot animation) is owned by Word Pool UI and
  Slot UI reacting to the signals this system emits.
- Audio feedback (placement SFX) is owned by Audio System reacting to the same signals.

## UI Requirements

None. This system contains no display logic.

## Acceptance Criteria

1. Clicking a word with nothing selected → word becomes selected; `word_selected(word)` emitted.
2. Clicking the currently selected word → word deselects; `word_deselected()` emitted.
3. Clicking a different word while one is selected → selection swaps; `word_selected(new_word)` emitted; no deselect event fired.
4. Clicking a slot with a word selected → `gsm.place_word()` is called exactly once with the correct word and slot index.
5. Correct placement → `placement_correct(word, slot_index)` emitted; `selected_word` clears; state returns to `IDLE`.
6. Wrong placement → `placement_wrong(word, slot_index)` emitted; `selected_word` clears; state returns to `IDLE`.
7. Slot click with no word selected → no-op; no signal emitted; no GSM call made.
8. Solved slot click while a word is selected → no-op; selection preserved; player can click another slot.
9. Outside click while a word is selected → deselects; `word_deselected()` emitted.
10. `puzzle_solved` or `puzzle_failed` signal received → state enters `LOCKED`; all subsequent clicks are no-ops.
11. Already-placed word clicked → no-op; warning logged.
12. `place_word()` returns `ALREADY_PLACED` or `INVALID` → no-op; warning logged; selection cleared.

## Open Questions

- Should a wrong placement lock out re-placement briefly, or make the word
  available immediately? **Decision: available immediately.** Revisit if
  playtesting shows players spam-clicking after wrong placements.
