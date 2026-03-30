# Letter Reveal Pacing — Paper Prototype Results

**Date**: 2026-03-25
**Tested with**: 3 category names, left_to_right order

## Recommended Default Config

`letters_per_placement = [1, 2, 2]` — works well for categories of 6-12 characters.

- Step 1 (1 letter): confirms the player is on the right track
- Step 2 (2 letters): picture starts to form, pattern recognition kicks in
- Step 3 (2 letters): "aha" moment — player completes the name in their head before it's fully shown

## Difficulty Presets

| Difficulty | Config  | Behaviour |
|-----------|---------|-----------|
| Easy      | [2,2,3] | Category guessable after 2nd placement for most names |
| Medium    | [1,2,2] | **Default** — aha moment at step 3 |
| Hard      | [1,1,2] | Sparse reveals; category readable only at final placement |

## Validation Rule (enforce in PuzzleData)

`sum(letters_per_placement) <= len(category_name) - space_count`

For "BOARD GAMES": max_revealable = 9, [1,2,2] reveals 5 — valid.
