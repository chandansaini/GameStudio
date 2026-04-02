# Game State Manager

> **Status**: Designed — Pending Review
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-24
> **Implements Pillar**: Pillar 1 (Every Placement Is a Deduction)

## Overview

The Game State Manager tracks all mutable state for an active puzzle session.
It initialises from a Puzzle Data resource at session start and maintains the
complete runtime picture: which words have been placed in which slots, which
groups are solved, the current letter reveal state per group, remaining lives,
and the overall puzzle outcome (in progress / solved / failed). It also records
the placement history used by the Share Result System to generate post-game
summaries. All gameplay systems — Slot Assignment, Life System, Letter Reveal
System, and all UI systems — read from and write to the GSM as their single
source of runtime truth. The GSM owns no display logic and contains no puzzle
authoring data; it is a pure state container with a well-defined interface.

## Player Fantasy

The Game State Manager is never seen by the player. Its fantasy is invisible
correctness — the player should never experience a stale UI, a life that didn't
deduct, a letter that didn't reveal, or a solved group that forgot it was solved.
When it works perfectly, it is unnoticeable. When it fails, everything the player
trusted breaks at once. The GSM serves Pillar 1 (Every Placement Is a Deduction)
by ensuring that every piece of information the player uses to reason — partial
letter reveals, remaining lives, placed words — is always accurate and instantly
reflected across all systems.

## Detailed Design

### Core Rules

1. The GSM is initialised once per puzzle session by passing a `PuzzleData`
   resource. It reads groups, words, anchor words, and category names to build
   a `SlotState` for each of the 4 groups.
2. `revealed_letters` is initialised as an array of bools matching
   `category_name` length. Spaces are set to `true` immediately (always
   visible). All other positions start `false`.
3. Anchor words are pre-registered in `placed_words` for their slot at
   initialisation — they count as already placed and do not appear in the
   word pool.
4. All state changes go through GSM methods — no system mutates GSM fields
   directly.
5. Core method: `place_word(word: String, slot_index: int)` — validates
   placement, updates state, emits signals. Returns a result enum:
   `CORRECT | WRONG | ALREADY_PLACED | SLOT_SOLVED | INVALID`.
6. On `CORRECT`: word is added to `slot_states[slot_index].placed_words`;
   `word_placed_correct` signal is emitted; if all non-anchor words in the
   slot are placed, `is_solved` is set to `true`, `group_solved` is emitted,
   and `puzzle_solved_check()` runs.
7. On `WRONG`: `lives_remaining` decremented by 1; `word_placed_wrong` signal
   emitted; if `lives_remaining == 0`, `outcome` set to `FAILED` and
   `puzzle_failed` signal emitted.
8. `puzzle_solved_check()`: if all 4 `SlotState.is_solved == true`, `outcome`
   is set to `SOLVED` and `puzzle_solved` signal emitted.
9. Every call to `place_word()` appends a `PlacementRecord` to
   `placement_history` regardless of outcome (correct or wrong).
10. Once `outcome` is `SOLVED` or `FAILED`, `place_word()` is a no-op and
    returns `INVALID`.

### Data Structures

```
SessionState
├── puzzle_id          : int               — which puzzle is active
├── outcome            : Enum              — IN_PROGRESS | SOLVED | FAILED
├── lives_remaining    : int               — 0–3
├── placement_history  : Array[PlacementRecord]
└── slot_states        : Array[SlotState]  — always 4 entries

SlotState
├── group_index        : int               — index into puzzle's groups array
├── placed_words       : Array[String]     — correctly placed words (includes anchor)
├── is_solved          : bool              — true when all words placed
└── revealed_letters   : Array[bool]       — one bool per char in category_name;
                                             spaces always true, others start false

PlacementRecord
├── word               : String            — word that was placed
├── target_slot        : int               — slot it was assigned to
├── was_correct        : bool              — correct or wrong
└── lives_after        : int               — lives remaining after this placement
```

### States and Transitions

| State | Meaning | Entry Condition | Valid Transitions |
|-------|---------|-----------------|-------------------|
| `IN_PROGRESS` | Session active | GSM initialised with valid puzzle | → `SOLVED`, → `FAILED` |
| `SOLVED` | All 4 groups placed correctly | All 4 `SlotState.is_solved == true` | None — terminal |
| `FAILED` | Lives exhausted | `lives_remaining == 0` | None — terminal |

### Signals

| Signal | Arguments | Listeners |
|--------|-----------|-----------|
| `word_placed_correct(word, slot_index)` | String, int | Letter Reveal System, Word Pool UI, Slot UI, Audio System |
| `word_placed_wrong(word, slot_index)` | String, int | Life System, Life Indicator UI, Audio System |
| `group_solved(slot_index)` | int | Slot UI, Audio System |
| `puzzle_solved()` | — | Scene Manager, Results Screen, Streak Tracker, Audio System |
| `puzzle_failed()` | — | Scene Manager, Results Screen, Life Restore Timer, Audio System |
| `letter_revealed(slot_index, char_index)` | int, int | Slot UI |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Puzzle Data System | reads from | Initialisation only — reads groups, words, anchor words, category names |
| Slot Assignment | calls into | `place_word(word, slot_index)` → result enum |
| Letter Reveal System | signal + calls into | Connects to `word_placed_correct`; calls `gsm.reveal_letter(slot_index, char_index)` to update `revealed_letters` |
| Life System | signal | Connects to `word_placed_wrong`; reads `lives_remaining` |
| Save/Persist System | reads from | Reads full session state for serialisation on app close |
| All UI systems | signal + reads | Connect to relevant signals; read state for initial render on scene load |
| Share Result System | reads from | Reads `placement_history` to build post-game result summary |

## Formulas

### Formula 1: Lives After Wrong Placement
```
lives_remaining = lives_remaining - 1
```
Range: 3 → 2 → 1 → 0. Reaching 0 triggers `FAILED` state.

### Formula 2: Puzzle Solved Condition
```
solved_group_count = count(slot_states where is_solved == true)
puzzle_solved      = (solved_group_count == 4)
```
Evaluated after every correct placement that sets a group's `is_solved = true`.

### Formula 3: Share Result Derivations
```
total_placements = len(placement_history)
wrong_placements = count(placement_history where was_correct == false)
lives_used       = 3 - lives_remaining   (read at terminal state only)
```
These are read-only derivations used by Share Result System. The GSM does not
compute them proactively — they are calculated on demand from `placement_history`.

## Edge Cases

| # | Situation | Resolution |
|---|-----------|------------|
| 1 | `place_word()` called with a word not in the puzzle's word pool | Return `INVALID`; no state change; no life deducted |
| 2 | `place_word()` called on a slot that is already solved | Return `SLOT_SOLVED`; no state change; no life deducted |
| 3 | `place_word()` called after `outcome` is `SOLVED` or `FAILED` | Return `INVALID`; no-op |
| 4 | `place_word()` called with a word already placed in any slot | Return `ALREADY_PLACED`; no state change; no life deducted |
| 5 | `reveal_letter()` called with a `char_index` that is a space | Space is always `true`; no-op, no signal emitted |
| 6 | `reveal_letter()` called with an already-revealed `char_index` | No-op; no duplicate signal emitted |
| 7 | `reveal_letter()` called with `char_index` out of bounds | Log error and no-op; never crash |
| 8 | GSM initialised with a puzzle that has fewer or more than 4 groups | Reject initialisation; log error; do not enter `IN_PROGRESS` |
| 9 | App closed mid-session (`IN_PROGRESS`) | Save/Persist System serialises full state; GSM restores on next launch |
| 10 | App closed after terminal state (`SOLVED` or `FAILED`) | Save/Persist records outcome; GSM on next launch starts in terminal state — no replay without life restore |
| 11 | `lives_remaining` goes below 0 | Clamp to 0; log warning; trigger `FAILED` if not already triggered |
| 12 | Final group solved (all 4 groups now solved) | `puzzle_solved_check()` runs after each `group_solved`; fires `puzzle_solved` signal exactly once on first check that returns true |

## Dependencies

### Upstream (what GSM needs)

| System | What it reads | Type |
|--------|--------------|------|
| Puzzle Data System | `groups`, `words`, `anchor_word`, `category_name`, `group_size` at initialisation | Hard — cannot initialise without puzzle data |

### Downstream (what reads from GSM)

| System | What it reads / calls | Type |
|--------|----------------------|------|
| Slot Assignment | `place_word(word, slot_index)` | Hard — core interaction method |
| Letter Reveal System | `reveal_letter(slot_index, char_index)`; connects to `word_placed_correct` signal | Hard — reveal cannot execute without GSM state |
| Life System | `lives_remaining`; connects to `word_placed_wrong` signal | Hard — life tracking lives here |
| Save/Persist System | Full session state serialisation | Hard — must persist GSM to survive app close |
| Word Pool UI | `slot_states[].placed_words` for initial render | Hard — UI has nothing to display without state |
| Slot UI | `slot_states[].revealed_letters`, `is_solved`; connects to all slot signals | Hard |
| Life Indicator UI | `lives_remaining`; connects to `word_placed_wrong` signal | Hard |
| Life Restore Timer | Connects to `puzzle_failed` signal | Hard — timer starts on failure |
| Streak Tracker | Connects to `puzzle_solved` signal | Soft — streak works without it, but cannot count wins |
| Results Screen | `outcome`, `placement_history`, `slot_states` at terminal state | Hard — nothing to display without terminal state |
| Audio System | Connects to all signals | Soft — game functions without audio |
| Share Result System | `placement_history`, `lives_remaining` at terminal state | Soft — share feature depends on it, core game does not |

### Consistency Check

The Puzzle Data System GDD lists GSM as a downstream dependent reading
`groups`, `words`, `anchor_word`, `category_name` on puzzle init — consistent
with upstream dependency listed above. ✓

## Tuning Knobs

| Knob | Location | Default | Safe Range | Too Low | Too High |
|------|----------|---------|------------|---------|----------|
| `max_lives` | GSM constant | 3 | 2–5 | 2 lives — very punishing, low tolerance for exploratory guesses | 5+ lives — reduces stakes; Pillar 1 weakens as random guessing becomes viable |

**Why 3:** Mirrors established puzzle conventions while keeping stakes meaningful.
3 lives allows one exploratory guess early without making the puzzle trivially
safe. Changing this value affects every puzzle simultaneously — it is a global
setting, not per-puzzle.

**Note:** `max_lives` is the only tuning knob. All other GSM behaviour is
deterministic logic with no designer-adjustable parameters.

## Visual / Audio Requirements

None. The GSM is a pure state container with no visual or audio output. All
presentation is handled by UI systems and the Audio System reacting to its
signals.

## UI Requirements

None. The GSM is not player-facing. UI systems read from it and connect to its
signals — it does not depend on any UI system.

## Acceptance Criteria

1. GSM initialises correctly from a valid `PuzzleData` resource — all 4
   `SlotState` entries created, anchor words pre-placed, `revealed_letters`
   initialised with spaces as `true` and all other positions as `false`.
2. `place_word()` with a correct word returns `CORRECT`, updates `placed_words`,
   emits `word_placed_correct` signal.
3. `place_word()` with a wrong word returns `WRONG`, decrements `lives_remaining`
   by 1, emits `word_placed_wrong` signal.
4. `place_word()` on an already-solved slot returns `SLOT_SOLVED` with no state
   change and no life deducted.
5. `place_word()` with an already-placed word returns `ALREADY_PLACED` with no
   state change and no life deducted.
6. `place_word()` with an unknown word returns `INVALID` with no state change
   and no life deducted.
7. `lives_remaining` reaching 0 sets `outcome` to `FAILED` and emits
   `puzzle_failed` signal exactly once.
8. All 4 groups solved sets `outcome` to `SOLVED` and emits `puzzle_solved`
   signal exactly once.
9. All `place_word()` calls append a `PlacementRecord` to `placement_history`
   — correct and wrong placements alike.
10. `place_word()` called after terminal state returns `INVALID` with no state
    change.
11. `reveal_letter()` on a space or already-revealed index is a no-op — no
    signal emitted, no error thrown.
12. `reveal_letter()` with an out-of-bounds index logs an error and does not
    crash.
13. Full session state serialises and deserialises without data loss — restored
    GSM behaves identically to pre-close GSM.
14. GSM initialised with a puzzle lacking exactly 4 groups rejects initialisation
    and logs an error.

## Open Questions

- Should `placement_history` record the *intended* slot or the *correct* slot
  for wrong placements? Currently records `target_slot` (intended). Share Result
  System should clarify what it needs before this is finalised.
- Should GSM expose a `get_word_pool()` method returning unplaced words, or
  should Word Pool UI derive this itself from puzzle data minus placed words?
  Centralising in GSM is cleaner but adds surface area to the interface.
