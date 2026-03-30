# Letter Reveal System

> **Status**: Designed — Pending Review
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-24
> **Implements Pillar**: Pillar 2 (The Aha Is Earned), Pillar 1 (Every Placement Is a Deduction)

## Overview

The Letter Reveal System is the mechanic that makes LEXICON unique. When a
player correctly places a word into a slot, this system reads the slot's
`reveal_config` from the Puzzle Data resource, determines which letters of
the hidden category name to reveal next, and instructs the Game State Manager
to mark those positions as visible. It connects to the GSM's
`word_placed_correct` signal, calculates the placement index (which reveal
step this is), selects the correct number of letters in the configured order
(left-to-right, right-to-left, common-first, or rare-first using an English
frequency table), and calls `gsm.reveal_letter()` for each. It is the bridge
between a correct word placement and the satisfying emergence of the hidden
category name — the system that makes every deduction feel rewarded.

## Player Fantasy

Each correct placement should feel like peeling back a layer. The first
revealed letter is a tease — a single clue that confirms you're on the right
track. The second builds the picture. By the third, the category name is
almost readable, and the player is mentally completing it before the last
letter appears. The "aha" is not the final reveal — it's the moment the
player *sees* the answer two letters before it's fully shown. The Letter
Reveal System's job is to engineer that moment: reveal enough to guide,
withhold enough to challenge, and sequence letters so each reveal feels
meaningful rather than random. It serves Pillar 2 (The Aha Is Earned) — the
satisfaction comes from the player's own pattern recognition, not from being
handed the answer.

## Detailed Design

### Core Rules

1. The Letter Reveal System connects to `gsm.word_placed_correct(word,
   slot_index)` on initialisation.
2. On receiving the signal, it executes the **reveal algorithm** for the
   given `slot_index`.

3. **Reveal Algorithm**:
   - **Step 1**: Read placement index:
     `placement_index = gsm.slot_states[slot_index].placed_words.size() - 2`
     *(minus 1 for anchor word, minus 1 for 0-based index of this placement)*
   - **Step 2**: Read reveal count:
     `N = puzzle.groups[slot_index].reveal_config.letters_per_placement[placement_index]`
   - **Step 3**: Read reveal order:
     `reveal_order = puzzle.groups[slot_index].reveal_config.reveal_order`
   - **Step 4**: Build candidates — all character indices in `category_name`
     where `gsm.slot_states[slot_index].revealed_letters[i] == false`
     AND `category_name[i] != " "`
   - **Step 5**: Sort candidates by `reveal_order` (see sorting rules below)
   - **Step 6**: Take first `min(N, candidates.size())` positions
   - **Step 7**: Call `gsm.reveal_letter(slot_index, char_index)` for each

4. **Sorting Rules by `reveal_order`**:

   | Enum Value | Sort Rule |
   |------------|-----------|
   | `left_to_right` | Sort positions ascending — leftmost unrevealed first |
   | `right_to_left` | Sort positions descending — rightmost unrevealed first |
   | `common_letters_first` | Sort by frequency rank ascending — most common (E) first |
   | `rare_letters_first` | Sort by frequency rank descending — rarest (Z) first |

5. **English Frequency Table** (hardcoded constant, uppercase):
   ```
   FREQUENCY_RANK = {
     "E":0,  "T":1,  "A":2,  "O":3,  "I":4,  "N":5,
     "S":6,  "H":7,  "R":8,  "D":9,  "L":10, "C":11,
     "U":12, "M":13, "W":14, "F":15, "G":16, "Y":17,
     "P":18, "B":19, "V":20, "K":21, "J":22, "X":23,
     "Q":24, "Z":25
   }
   ```
   Category names are compared uppercase. Non-alphabetic characters
   (digits, punctuation) are assigned rank 13 (middle) for sorting.

6. The system is **stateless** — all data is read from GSM and Puzzle Data
   on each signal invocation. No internal state is maintained between
   placements.

7. If `candidates.size() < N` (fewer unrevealed letters than requested):
   reveal all remaining candidates and log a warning. This indicates a
   puzzle authoring error — the Puzzle Data validation rule should have
   caught it at load time.

### States and Transitions

The Letter Reveal System is event-driven and stateless. It activates on
`word_placed_correct` signal and completes synchronously within the same
frame. No internal states or transitions exist.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| GSM | signal in | Connects to `word_placed_correct(word, slot_index)` |
| GSM | calls into | `gsm.reveal_letter(slot_index, char_index)` per letter; reads `slot_states[slot_index].placed_words.size()` and `revealed_letters` |
| Puzzle Data System | reads from | `reveal_config` (letters_per_placement, reveal_order) and `category_name` per group |
| Slot UI | indirect | GSM emits `letter_revealed(slot_index, char_index)` after each `reveal_letter()` — Slot UI connects to this signal |
| Audio System | indirect | Audio System connects to `word_placed_correct` independently — not called directly by this system |

## Formulas

```
placement_index = placed_words.size() - 2
  — placed_words includes the anchor word and the just-placed word;
    subtract 1 for anchor, subtract 1 for 0-based index

N = letters_per_placement[placement_index]
  — number of letters to reveal for this specific placement step

letters_to_reveal = min(N, unrevealed_non_space_count)
  — defensive cap; should always equal N for valid authored puzzles

unrevealed_non_space_count = count(i where revealed_letters[i] == false
                                        AND category_name[i] != " ")
```

**Cumulative reveal validation (for puzzle authors):**
```
total_revealed  = sum(letters_per_placement[0 .. group_size - 2])
max_revealable  = len(category_name) - space_count(category_name)
valid_puzzle    = total_revealed ≤ max_revealable
```
This constraint is enforced by the Puzzle Data System at load time.
The Letter Reveal System treats a violation as a bug, not a design choice.

## Edge Cases

| # | Situation | Resolution |
|---|-----------|------------|
| 1 | `unrevealed_non_space_count < N` | Reveal all remaining candidates; log warning — puzzle authoring error |
| 2 | `unrevealed_non_space_count == 0` when signal fires | No-op; log warning — all letters already revealed before group was solved |
| 3 | `placement_index` out of bounds for `letters_per_placement` | Log error; reveal 0 letters; do not crash — puzzle validation should have caught this |
| 4 | Category name contains numbers or punctuation | Assigned frequency rank 13 (middle); sorted and revealed as any other character |
| 5 | Category name is all spaces (invalid puzzle) | No candidates exist; no-op; puzzle should have been rejected at load time |
| 6 | `reveal_order` value not in the 4 known enums | Default to `left_to_right`; log warning |
| 7 | `word_placed_correct` fires for an already-solved slot | GSM prevents this — `place_word()` returns `SLOT_SOLVED` before the signal fires; not reachable |
| 8 | Two `word_placed_correct` signals fire in the same frame | Each processed sequentially in signal order; both reveals execute correctly |
| 9 | All candidates share the same frequency rank (e.g., "AAA") | Tie broken by position ascending — leftmost unrevealed first |

## Dependencies

### Upstream Dependencies

| System | Interface | Type |
|--------|-----------|------|
| Puzzle Data System | Reads `reveal_config` (letters_per_placement, reveal_order) and `category_name` per group | Hard — cannot execute reveals without config |
| Game State Manager | Connects to `word_placed_correct` signal; reads `slot_states[slot_index].placed_words.size()` and `revealed_letters`; calls `reveal_letter(slot_index, char_index)` | Hard — all runtime data lives in GSM |
| Slot Assignment | Indirect — Slot Assignment triggers GSM which fires the signal this system listens to | Soft — no direct interface |

### Downstream Dependents

| System | Interface | Type |
|--------|-----------|------|
| Slot UI | Indirect — GSM emits `letter_revealed(slot_index, char_index)` after each `reveal_letter()` call | Hard — Slot UI has no other way to know which letters to show |
| Audio System | Indirect — Audio System connects to GSM `word_placed_correct` independently | Soft — game functions without audio |

## Tuning Knobs

No direct tuning knobs. All tuning lives in `reveal_config` within each
puzzle's Puzzle Data resource:

- `letters_per_placement` (Array[int]) — how many letters reveal per correct
  placement. See Puzzle Data System GDD for safe ranges.
- `reveal_order` (String enum) — which letters reveal first. See Puzzle Data
  System GDD for valid values.

The English frequency table (`FREQUENCY_RANK`) is a hardcoded constant and
is not designer-adjustable. It reflects standard English letter frequency and
should not change between puzzles.

## Visual / Audio Requirements

- The Letter Reveal System produces no visuals or audio directly.
- Visual feedback (letter appearing in the slot) is owned by Slot UI reacting
  to GSM's `letter_revealed` signal.
- Audio feedback (reveal chime) is owned by Audio System reacting to GSM's
  `word_placed_correct` signal.

## UI Requirements

None. This system contains no display logic.

## Acceptance Criteria

1. Correct word placement triggers reveal of exactly
   `letters_per_placement[placement_index]` letters for that slot.
2. `left_to_right` reveals leftmost unrevealed non-space characters first.
3. `right_to_left` reveals rightmost unrevealed non-space characters first.
4. `common_letters_first` reveals in English frequency order — E before T
   before A… before Z.
5. `rare_letters_first` reveals in reverse frequency order — Z before Q
   before X… before E.
6. Spaces are never selected as reveal candidates — they are always visible.
7. Already-revealed letters are never selected as candidates — no duplicates.
8. If fewer unrevealed letters than N exist, all remaining are revealed and
   a warning is logged — no crash.
9. Unknown `reveal_order` value defaults to `left_to_right` with a warning.
10. System is stateless — two consecutive puzzles in the same session produce
    correct independent reveals for each.
11. `placement_index` correctly identifies the 1st, 2nd, and 3rd placements
    excluding the anchor word.
12. Frequency rank ties (identical letters) are broken by position ascending.

## Open Questions

- Should the reveal animation stagger individual letters (letter 1 appears,
  then letter 2, then letter 3) or reveal all N simultaneously? Stagger feels
  better but adds animation complexity — decide during Slot UI design.
- Post-launch: should `FREQUENCY_RANK` support locale-specific tables for
  non-English category names? Note for localisation phase.
