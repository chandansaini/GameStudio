# Slot UI

> **Status**: Designed — Pending Review
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-25
> **Implements Pillar**: Pillar 2 (The Aha Is Earned), Pillar 1 (Every Placement Is a Deduction)

## Overview

Slot UI renders the four slot panels that are the centrepiece of the LEXICON
puzzle screen. Each panel displays the slot's anchor word, a category name
with unrevealed letters shown as blanks, and the list of words the player has
placed so far. It handles slot click events by forwarding them to Slot
Assignment, and keeps its display in sync with three signal sources: Slot
Assignment (placement results), GSM (letter reveals, puzzle terminal states),
and its own initial load from GSM session state. It owns all visual feedback
for the slot — correct placement animation, wrong placement flash, staggered
letter reveal animations, and the solved state. It produces no game logic —
it is a pure display layer that reacts to events from the systems beneath it.

## Player Fantasy

The slot is where deduction becomes visible. The blank category name is a
mystery the player is actively solving — each correct placement peels back
a letter, and the emerging name should feel like a reward for reasoning, not
a gift. The stagger matters: letter 1 appears, then letter 2, then letter 3 —
each pop building anticipation. The "aha" hits before the name is fully
revealed; the player completes it in their head two letters early and feels
clever. A solved slot should feel conclusive — the full category name visible,
the placed words confirmed, a moment of quiet satisfaction before moving to
the next group. Wrong placements sting at the slot level too — a brief flash
that says "not here" without belaboring the point.

## Detailed Design

### Core Rules

1. On scene load, read `gsm.session_state` to initialise each of the 4 slot panels:
   - Anchor word: `puzzle.groups[slot_index].anchor_word`
   - Category name: render each character — spaces always visible, letters as
     `_` if `revealed_letters[i] == false`, letter if `true`
   - Placed words: render `slot_states[slot_index].placed_words` (excluding anchor word)
2. Each slot panel, when clicked, calls `slot_assignment.on_slot_clicked(slot_index)`.
3. Connect to **Slot Assignment** signals:
   - `placement_correct(word, slot_index)` → add word to that slot's placed words
     list; play correct placement animation
   - `placement_wrong(word, slot_index)` → flash that slot's panel WRONG (~0.4s);
     word does not appear in slot
4. Connect to **GSM** signals:
   - `letter_revealed(slot_index, char_index)` → reveal that character in the
     category name with a staggered pop animation (`letter_reveal_stagger_delay`
     between each letter)
   - `puzzle_solved` → show full solved state for all slots
   - `puzzle_failed` → lock all slots; no change to category names
5. **Letter reveal stagger**: when multiple `letter_revealed` signals fire in
   sequence, each letter animates with a `letter_reveal_stagger_delay` offset.
   Signals fire sequentially from GSM — each triggers its own animation independently.
6. **Solved slot detection**: when `placement_correct` fires and
   `gsm.slot_states[slot_index].is_solved == true`, play the slot solved animation
   (category name glows, placed words lock in, solved indicator appears).
7. Solved slots do not forward clicks to Slot Assignment — clicking a solved slot
   is a no-op at the UI level.

### States and Transitions

Per-slot panel state machine:

| State | Visual | Entry | Exit |
|-------|--------|-------|------|
| `ACTIVE` | Normal; clickable | Scene load | Solved; puzzle terminal |
| `WRONG_FLASH` | Error flash (~0.4s) | `placement_wrong` signal | After ~0.4s → ACTIVE |
| `SOLVED` | Full category name shown; placed words locked; solved indicator | `is_solved == true` after correct placement | Never — terminal |
| `LOCKED` | No interaction; display unchanged | `puzzle_failed` | Never — terminal |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Slot Assignment | calls into | `slot_assignment.on_slot_clicked(slot_index)` on panel click |
| Slot Assignment | signal in | `placement_correct(word, slot_index)`, `placement_wrong(word, slot_index)` |
| GSM | reads from | `session_state` at scene load for initial render |
| GSM | signal in | `letter_revealed(slot_index, char_index)`, `puzzle_solved`, `puzzle_failed` |
| Puzzle Data System | reads from | `puzzle.groups[slot_index].anchor_word`, `category_name` at scene load |

## Formulas

```
wrong_flash_duration        = 0.4s   (tuning knob)
letter_reveal_stagger_delay = 0.15s  (tuning knob)

Letter reveal animation timing per slot:
  letter N appears at: N * letter_reveal_stagger_delay after the first
  letter_revealed signal for that placement batch

  Example (3 letters revealed):
    letter 0 → appears at 0.0s
    letter 1 → appears at 0.15s
    letter 2 → appears at 0.30s
    total reveal duration = (N - 1) * letter_reveal_stagger_delay = 0.30s
```

No other math — layout handled by Godot container nodes.

## Edge Cases

| # | Situation | Resolution |
|---|-----------|------------|
| 1 | `letter_revealed` fires for an already-visible character | No-op — character cell already showing the letter; animation plays harmlessly |
| 2 | `placement_correct` fires and `is_solved == true` simultaneously | Read `is_solved` after adding the word — if true, trigger solved animation in the same frame |
| 3 | `placement_wrong` fires on a slot currently in WRONG_FLASH | Reset the flash timer — slot flashes again from start; not reachable in normal play |
| 4 | `puzzle_failed` fires while a letter reveal animation is in progress | Animation completes; slot enters LOCKED after — no visual conflict |
| 5 | `puzzle_solved` fires before all slots individually reach SOLVED | Forces full reveal on all slots — any not yet visually solved are brought to solved state immediately |
| 6 | Scene loads mid-puzzle with partially revealed letters | `revealed_letters[]` from GSM initialises each character cell correctly at load time |
| 7 | Category name is a single character | Renders as one character cell; no layout issues |
| 8 | Solved slot clicked | No-op at UI level — click not forwarded to Slot Assignment |
| 9 | `letter_revealed` fires for a slot_index out of range (0–3) | Log error; no-op — should not occur with valid puzzle data |

## Dependencies

### Upstream Dependencies

| System | Interface | Type |
|--------|-----------|------|
| Slot Assignment | Calls `on_slot_clicked(slot_index)`; connects to `placement_correct`, `placement_wrong` | Hard — no other source of placement events |
| Game State Manager | Reads `session_state` at load; connects to `letter_revealed`, `puzzle_solved`, `puzzle_failed` | Hard — all runtime slot data lives in GSM |
| Puzzle Data System | Reads `anchor_word` and `category_name` per group at load | Hard — cannot render slots without puzzle data |

### Downstream Dependents

None. Slot UI is a leaf node — no other system depends on it.

## Tuning Knobs

| Knob | Default | Safe Range | Too Low | Too High |
|------|---------|------------|---------|----------|
| `wrong_flash_duration` | 0.4s | 0.2–0.8s | Flash too brief to register | Flash too long — slot feels locked out |
| `letter_reveal_stagger_delay` | 0.15s | 0.05–0.3s | Letters pop simultaneously — loses the drama | Letters stagger so slowly the reveal feels broken |

## Visual / Audio Requirements

- **Category name cells**: each character rendered as a distinct cell — blank
  (`_`) or revealed letter. Spaces rendered as visible gaps (not cells).
- **WRONG_FLASH**: error colour flash on the full slot panel (~0.4s via Tween).
- **Letter reveal pop**: each letter cell animates in (scale pop or fade-in)
  with `letter_reveal_stagger_delay` between letters. Exact animation style
  owned by art direction pass.
- **SOLVED state**: full category name revealed; visual treatment (glow, colour
  change, checkmark) owned by art direction pass.
- No audio produced directly — Audio System reacts to GSM signals independently.

## UI Requirements

- 4 slot panels arranged vertically; each panel contains:
  - Anchor word label (top)
  - Category name display (row of character cells)
  - Placed words list (grows downward as words are added)
- Slot panels must be large enough to be comfortable tap targets on mobile.
- Category name cell row must accommodate the longest expected category name
  without truncation — wrap to two lines if needed.
- Placed words list must not overflow the slot panel; scroll or truncate
  gracefully if word count exceeds visual space (unlikely with max group
  size of 6).

## Acceptance Criteria

1. Scene load renders all 4 slots with correct anchor words, category names (blanks for unrevealed, letters for revealed), and any already-placed words.
2. Clicking an ACTIVE slot calls `slot_assignment.on_slot_clicked(slot_index)` exactly once.
3. `placement_correct(word, slot_index)` → word appears in that slot's placed words list.
4. `placement_correct` with `is_solved == true` → slot transitions to SOLVED state; full category name visible; solved indicator shown.
5. `placement_wrong(word, slot_index)` → that slot flashes WRONG_FLASH for `wrong_flash_duration`; word does not appear in slot.
6. `letter_revealed(slot_index, char_index)` → that character cell transitions from blank to letter with pop animation; stagger delay applied between consecutive reveals.
7. `puzzle_solved` → all slots show full category names and solved state.
8. `puzzle_failed` → all slots enter LOCKED; no clicks forwarded; display unchanged.
9. Solved slot clicked → no call to Slot Assignment; no-op.
10. Scene loaded mid-puzzle → revealed letters and placed words correctly restored from GSM state.
11. Multiple `letter_revealed` signals for the same slot fire in order with `letter_reveal_stagger_delay` between each animation.

## Open Questions

- Should the wrong flash apply to the whole slot panel or just the border/outline?
  Full panel flash is more visible; border flash is more subtle. **Recommendation:
  full panel flash for MVP** — refine in art direction pass if too heavy.
