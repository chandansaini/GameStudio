# Puzzle Data System

> **Status**: Designed — Pending Review
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-24
> **Implements Pillar**: Pillar 4 (Always Fair, Never Easy), Pillar 2 (The Aha Is Earned)

## Overview

The Puzzle Data System defines the complete data model for a LEXICON puzzle. It
is a pure data layer — no game logic, no UI, no interaction — responsible only
for storing and providing structured puzzle information that all other systems
read. A puzzle consists of a numeric ID, a publish date, an optional difficulty
rating (reserved for future display), and exactly four groups. Each group
contains a variable number of words, one designated anchor word (pre-placed for
the player), a category name (the hidden label the player deduces), and a
per-group reveal configuration controlling how many letters reveal per correct
placement and in what order. All other systems — Game State Manager, Puzzle
Library, Slot Assignment, Letter Reveal System, Daily Lock System — treat this
as their single source of truth for puzzle content.

## Player Fantasy

This system is not player-facing. Its fantasy is the designer's: the ability to
craft a puzzle that feels surprising yet inevitable — where the category names,
word choices, anchor selections, and reveal pacing all combine into a single
coherent experience. The data structure must give puzzle authors enough control
to make each puzzle feel distinct, and enough constraints to prevent ambiguity.
When a player has their "aha" moment, the Puzzle Data System is what made it
possible to engineer that moment precisely.

## Detailed Design

### Core Rules

1. A puzzle contains exactly 4 groups — no more, no fewer.
2. All 4 groups in a puzzle must have the same word count (uniform per puzzle).
3. Word count per group: minimum 3, maximum 6. Standard is 4.
4. Each group has exactly one anchor word. The anchor word must appear in that
   group's `words` array.
5. No word may appear in more than one group within the same puzzle.
6. Category names must be unique within a puzzle — no two groups share the same label.
7. `letters_per_placement` must have exactly `group_size - 1` entries (one per
   non-anchor word placement).
8. The sum of `letters_per_placement` should not exceed the character count of
   `category_name` (excluding spaces). Spaces are always revealed automatically
   when adjacent revealed letters expose them.
9. `difficulty_rating` is stored but not displayed at launch. Valid range: 1–5.
   Default: 3.
10. `publish_date` must be unique across all puzzles in the library — no two
    puzzles share a date.
11. `id` must be a positive integer, unique across all puzzles, assigned
    sequentially.

### States and Transitions

The Puzzle Data System is a static data layer — it has no runtime states. A
puzzle resource is loaded once by the Puzzle Library and read-only thereafter.
It is never mutated during gameplay.

### Interactions with Other Systems

| System | Direction | What flows |
|--------|-----------|------------|
| Puzzle Library | reads from | Loads puzzle resources by ID or date key |
| Game State Manager | reads from | Reads group count, word lists, anchor words, category names on puzzle init |
| Slot Assignment | reads from | Reads word lists and anchor assignments to populate slots |
| Letter Reveal System | reads from | Reads `reveal_config` per group to execute reveals |
| Daily Lock System | reads from | Reads `publish_date` to match today's puzzle |

No system writes to the Puzzle Data System at runtime.

## Formulas

### Formula 1: Valid Reveal Budget

Prevents puzzle authors from accidentally creating an unrevealable puzzle where
the sum of letter reveals exceeds the available letters in the category name.

```
max_revealable_letters = len(category_name) - space_count(category_name)
sum(letters_per_placement) ≤ max_revealable_letters
```

**Example**: `"Shades of Blue"` → 14 chars, 2 spaces → 12 revealable letters.
`letters_per_placement = [1, 2, 2]` → sum = 5 ✓ (5 ≤ 12)

### Formula 2: Minimum Reveal Guarantee

Ensures the player always receives at least one letter reveal per group,
guaranteeing a progress signal exists.

```
sum(letters_per_placement) ≥ 1
```

Both formulas are validation rules enforced at puzzle load time. If either
fails, the puzzle is rejected as malformed.

## Edge Cases

### Rejection Behaviour (Two-Tier)

When a puzzle fails validation:

- **Debug builds**: Hard block. Game halts at startup with a detailed error message
  identifying the puzzle ID, the rule violated, and the bad value. The author must
  fix the puzzle before the game will run.
- **Production builds**: Puzzle is silently skipped. Puzzle Library serves the next
  valid puzzle by publish date. The rejection is written to the error log for the
  developer to investigate. Players never see a broken state.

### Validation Edge Cases

| # | Situation | Resolution |
|---|-----------|------------|
| 1 | `anchor_word` not in group's `words` array | Reject puzzle as malformed |
| 2 | Same word appears in two different groups | Reject puzzle as malformed |
| 3 | Two groups share the same `category_name` | Reject puzzle as malformed |
| 4 | `letters_per_placement` length ≠ `group_size − 1` | Reject puzzle as malformed |
| 5 | `sum(letters_per_placement)` exceeds revealable letter count | Reject puzzle — not auto-corrected, author must fix |
| 6 | `sum(letters_per_placement)` = 0 | Reject puzzle — minimum 1 letter reveal required |
| 7 | `category_name` is empty string or all spaces | Reject puzzle — no revealable letters exist |
| 8 | `words` array contains duplicates within the same group | Reject puzzle as malformed |
| 9 | Group sizes vary within the same puzzle | Reject puzzle — uniform size is required |
| 10 | Two puzzles share the same `publish_date` | Puzzle Library uses the lower `id`; logs a warning |
| 11 | `difficulty_rating` outside 1–5 | Clamp to nearest valid value; log warning (not a rejection) |
| 12 | Puzzle has fewer or more than 4 groups | Reject puzzle as malformed |
| 13 | `group_size` below 3 or above 6 | Reject puzzle as malformed |

All rejections are evaluated at Puzzle Library load time — never silently during
an active gameplay session.

## Dependencies

### Upstream Dependencies

None. The Puzzle Data System is the foundation layer — it has no runtime
dependencies on other systems.

### Downstream Dependents

| System | What it reads | Dependency type |
|--------|--------------|-----------------|
| Puzzle Library | Full puzzle resource by ID or date | Hard — library cannot function without puzzle data |
| Game State Manager | `groups`, `words`, `anchor_word`, `category_name` per group | Hard — cannot initialise game state without puzzle |
| Slot Assignment | `words`, `anchor_word` per group | Hard — cannot populate slots without word lists |
| Letter Reveal System | `reveal_config` per group | Hard — cannot execute reveals without config |
| Daily Lock System | `publish_date` | Hard — cannot match today's puzzle without date |

### Data Format

Puzzles are authored as Godot `Resource` files (`.tres` or `.res`). This makes
them natively loadable, inspector-editable in the Godot editor, and type-safe
in GDScript. The Puzzle Library loads them via `load()` or `preload()`.

## Tuning Knobs

| Knob | Location | Default | Safe Range | Too Low | Too High |
|------|----------|---------|------------|---------|----------|
| `group_size` (per puzzle) | Puzzle resource | 4 | 3–6 | Too few decisions per group; feels trivial | Too many words; cognitive overload, session runs long |
| `letters_per_placement[i]` (per group) | RevealConfig | [1,1,1] for 4-word group | 0–4 per entry (sum ≥ 1) | No progress signal; reveal feels meaningless | Category name fully revealed before group is solved; grouping becomes trivial |
| `reveal_order` (per group) | RevealConfig | `"left_to_right"` | Any valid enum value | N/A — all modes are valid | `"rare_letters_first"` + low `letters_per_placement` on a long name creates near-impossible groups |
| `difficulty_rating` (per puzzle) | Puzzle resource | 3 | 1–5 | Reserved for future display — no gameplay effect at launch | Same |

### Key Interaction Warning

`letters_per_placement` and `reveal_order` interact strongly.
`"rare_letters_first"` + `[1,1,1]` on a category name of 10+ characters will
reveal almost nothing useful until the final placement — intentionally brutal
for hard puzzles, unintentionally brutal if used on a normal puzzle by mistake.
Authors should always verify the effective reveal sequence when combining low
placement counts with non-standard reveal orders.

## Visual / Audio Requirements

None. The Puzzle Data System is a pure data layer with no visual or audio output.

## UI Requirements

None. The Puzzle Data System is not player-facing. UI systems read from it
indirectly via Game State Manager and Slot Assignment.

## Acceptance Criteria

1. A valid puzzle resource loads without errors and all fields are accessible
   to dependent systems.
2. A puzzle with `anchor_word` not in its group's `words` array is rejected at
   load time with a descriptive error in debug builds.
3. A puzzle with duplicate words across groups is rejected at load time.
4. A puzzle with non-uniform group sizes is rejected at load time.
5. A puzzle with `sum(letters_per_placement)` exceeding revealable letter count
   is rejected at load time.
6. A puzzle with `sum(letters_per_placement)` = 0 is rejected at load time.
7. In production builds, a rejected puzzle is skipped and the next valid puzzle
   by date is served — no crash, no error screen.
8. Two puzzles sharing a `publish_date` resolve to the lower `id` without
   crashing.
9. `difficulty_rating` outside 1–5 is clamped silently without rejection.
10. A puzzle resource is never mutated after load — all reads return the same
    values throughout a session.
11. All 4 groups in a puzzle have identical `words` array lengths (uniform group
    size enforced).
12. Puzzle loads correctly in both debug and production export builds.

## Open Questions

- Should `reveal_order` support a custom `Array[int]` of character indices for
  maximum authoring control post-launch? (Low priority — enum modes cover all
  launch needs)
- Should `difficulty_rating` drive any automatic UI badge at launch, or remain
  fully reserved until post-launch? (Confirm before Launch Build phase)
