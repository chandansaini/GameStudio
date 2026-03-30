## GameStateManager (GSM)
## Autoload singleton. Single source of truth for all mutable puzzle state.
##
## Signal flow:
##   UI clicks → GSM.select_word() / GSM.place_word()
##   GSM → word_selected, word_placed_correct, word_placed_wrong,
##          group_solved, puzzle_solved, puzzle_failed
##   LifeSystem listens to word_placed_wrong, calls deduct_life() / trigger_fail()
##   SlotAssignment re-emits placement signals for UI consumption
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## A word was selected from the pool (first click).
signal word_selected(word: String)

## The selected word was deselected (tapped again or cancelled).
signal word_deselected(word: String)

## A word was placed into a slot and the grouping was CORRECT.
signal word_placed_correct(word: String, slot_index: int)

## A word was placed into a slot and the grouping was WRONG.
signal word_placed_wrong(word: String, slot_index: int)

## All 4 words for a slot have been correctly placed — slot is solved.
signal group_solved(slot_index: int)

## All 4 slots solved — puzzle complete.
signal puzzle_solved

## Lives reached 0 — game over.
signal puzzle_failed

## Lives changed.
signal lives_changed(lives_remaining: int)

## A new puzzle was loaded and state was reset.
signal puzzle_loaded(puzzle: PuzzleData)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const MAX_LIVES := 3

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## The active puzzle resource.
var active_puzzle: PuzzleData = null

## Words still available in the pool.
## Anchor words are pre-removed — pool starts with 12 words (4 groups × 3 non-anchor).
var pool_words: Array[String] = []

## The currently selected word, or "" if none.
var selected_word: String = ""

## Current lives remaining.
var lives: int = MAX_LIVES

## Which slot indices have been fully solved (all 4 words placed).
var solved_slots: Array[bool] = [false, false, false, false]

## Words correctly placed into each slot (includes anchor word, pre-populated).
## placed_words[i] is an Array[String] for slot i.
var placed_words: Array = [[], [], [], []]

## The anchor word chosen for each slot this session (one per slot).
## Randomised on first play; restored from save on resume; refreshed after a fail.
var session_anchors: Array[String] = []

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Load a puzzle and reset all state. Call before entering the game scene.
func load_puzzle(puzzle: PuzzleData) -> void:
	active_puzzle = puzzle
	lives = MAX_LIVES
	solved_slots = [false, false, false, false]
	placed_words = [[], [], [], []]
	selected_word = ""
	pool_words.clear()

	# Resolve session anchors — restore saved ones or pick fresh random anchors
	var saved := SavePersist.get_session_anchors(puzzle.puzzle_id)
	if saved.size() == puzzle.groups.size():
		session_anchors = saved
	else:
		session_anchors = _pick_random_anchors(puzzle)
		SavePersist.set_session_anchors(puzzle.puzzle_id, session_anchors)

	# Pre-place session anchors; add remaining words to pool
	for i in range(puzzle.groups.size()):
		var group: GroupData = puzzle.groups[i]
		placed_words[i].append(session_anchors[i])
		for word in group.words:
			if word != session_anchors[i]:
				pool_words.append(word)

	puzzle_loaded.emit(puzzle)
	lives_changed.emit(lives)

## Select a word from the pool (first click of two-step model).
## Tapping the same word again deselects it.
func select_word(word: String) -> void:
	if word not in pool_words:
		return
	if selected_word == word:
		selected_word = ""
		word_deselected.emit(word)
		return
	selected_word = word
	word_selected.emit(word)

## Place the currently selected word into a slot (second click of two-step model).
## If the slot is already solved, deselects the word and returns — gives player feedback.
func place_word(slot_index: int) -> void:
	if selected_word == "":
		return
	if solved_slots[slot_index]:
		# Tapping a solved slot cancels the current selection
		var word := selected_word
		selected_word = ""
		word_deselected.emit(word)
		return

	var word := selected_word
	selected_word = ""

	if _word_belongs_to_slot(word, slot_index):
		pool_words.erase(word)
		placed_words[slot_index].append(word)
		word_placed_correct.emit(word, slot_index)
		# Slot solved when all 4 words are placed (anchor + 3 more)
		if placed_words[slot_index].size() >= 4:
			solved_slots[slot_index] = true
			group_solved.emit(slot_index)
			if solved_slots.all(func(s): return s):
				puzzle_solved.emit()
	else:
		word_placed_wrong.emit(word, slot_index)

## Deduct one life. Called by LifeSystem.
## No-op if lives already 0 to prevent repeated emissions.
func deduct_life() -> void:
	if lives == 0:
		return
	lives -= 1
	lives_changed.emit(lives)

## Explicitly end the puzzle as a failure. Called by LifeSystem when lives hit 0.
## Clears saved anchors so "Play Again" gets a fresh set of hints.
func trigger_fail() -> void:
	if lives == 0:
		if active_puzzle != null:
			SavePersist.clear_session_anchors(active_puzzle.puzzle_id)
		puzzle_failed.emit()

## Returns true if a word is currently selected.
func has_selection() -> bool:
	return selected_word != ""

## Returns the number of unsolved slots.
func unsolved_count() -> int:
	var count := 0
	for s in solved_slots:
		if not s:
			count += 1
	return count

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _word_belongs_to_slot(word: String, slot_index: int) -> bool:
	if active_puzzle == null or slot_index >= active_puzzle.groups.size():
		return false
	return word in active_puzzle.groups[slot_index].words

## Picks one random eligible anchor word per group.
## Excludes words listed in group.hard_words. Falls back to all words if
## every word is marked hard (so the puzzle is never left without a hint).
func _pick_random_anchors(puzzle: PuzzleData) -> Array[String]:
	var anchors: Array[String] = []
	for group in puzzle.groups:
		var eligible: Array[String] = []
		for word in group.words:
			if word not in group.hard_words:
				eligible.append(word)
		if eligible.is_empty():
			eligible = group.words.duplicate()
		anchors.append(eligible[randi() % eligible.size()])
	return anchors
