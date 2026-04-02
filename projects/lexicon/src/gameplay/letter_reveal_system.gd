## LetterRevealSystem
## Manages the progressive letter reveal for each slot's category name.
## After a correct placement, the player confirms reveals one step at a time.
## Each call to advance_reveal() uncovers the next batch of letters per RevealConfig.
##
## Add as a child node in the game scene.
class_name LetterRevealSystem
extends Node

## Emitted when letters are revealed for a slot.
## slot_index: which slot (0-3)
## revealed_indices: which character positions in the category name are now visible
## is_fully_revealed: true if all letters are now shown
signal letters_revealed(slot_index: int, revealed_indices: Array[int], is_fully_revealed: bool)

## Emitted when a slot becomes fully revealed (all letters shown).
signal slot_fully_revealed(slot_index: int)

## Per-slot state: how many characters have been revealed so far.
var _revealed_count: Array[int] = [0, 0, 0, 0]

## Per-slot state: which reveal step we're on (index into RevealConfig.reveal_steps).
var _current_step: Array[int] = [0, 0, 0, 0]

## Per-slot: whether the slot has been fully revealed.
var _fully_revealed: Array[bool] = [false, false, false, false]

func _ready() -> void:
	GSM.puzzle_loaded.connect(_on_puzzle_loaded)
	GSM.word_placed_correct.connect(_on_word_placed_correct)
	GSM.group_solved.connect(_on_group_solved)

## Reveals all remaining hidden letters for a slot immediately (no stagger).
## Called automatically when the slot is fully solved.
func reveal_all(slot_index: int) -> void:
	if GSM.active_puzzle == null or _fully_revealed[slot_index]:
		return
	var category: String = GSM.active_puzzle.groups[slot_index].category_name
	var total_chars := category.length()
	if _revealed_count[slot_index] >= total_chars:
		return

	var remaining: Array[int] = []
	for i in range(_revealed_count[slot_index], total_chars):
		remaining.append(i)

	_revealed_count[slot_index] = total_chars
	_fully_revealed[slot_index] = true

	letters_revealed.emit(slot_index, remaining, true)
	slot_fully_revealed.emit(slot_index)

## Called by SlotUI's confirm button (or automatically on correct placement for MVP).
## Advances the reveal by one step for the given slot.
## Does nothing if the slot is already fully revealed or no puzzle is loaded.
func advance_reveal(slot_index: int) -> void:
	if GSM.active_puzzle == null:
		return
	if _fully_revealed[slot_index]:
		return

	var config := GSM.active_puzzle.get_reveal_config_for_group(slot_index)
	var category: String = GSM.active_puzzle.groups[slot_index].category_name
	var total_chars := category.length()

	var step := _current_step[slot_index]
	if step >= config.reveal_steps.size():
		return

	var chars_this_step: int = config.reveal_steps[step]
	var start := _revealed_count[slot_index]
	var end: int = mini(start + chars_this_step, total_chars)

	# Build the list of newly revealed indices (left_to_right)
	var new_indices: Array[int] = []
	for i in range(start, end):
		new_indices.append(i)

	_revealed_count[slot_index] = end
	_current_step[slot_index] = step + 1

	var fully_done: bool = end >= total_chars
	_fully_revealed[slot_index] = fully_done

	letters_revealed.emit(slot_index, new_indices, fully_done)
	if fully_done:
		slot_fully_revealed.emit(slot_index)

## Returns which character indices are currently visible for a slot (0-based).
func get_revealed_indices(slot_index: int) -> Array[int]:
	var result: Array[int] = []
	for i in range(_revealed_count[slot_index]):
		result.append(i)
	return result

## Returns true if all letters for this slot are visible.
func is_fully_revealed(slot_index: int) -> bool:
	return _fully_revealed[slot_index]

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _on_puzzle_loaded(_puzzle: PuzzleData) -> void:
	_revealed_count = [0, 0, 0, 0]
	_current_step = [0, 0, 0, 0]
	_fully_revealed = [false, false, false, false]

func _on_word_placed_correct(_word: String, slot_index: int) -> void:
	# Advance one reveal step per correct placement.
	# reveal_all() is triggered separately via group_solved when slot is complete.
	advance_reveal(slot_index)

func _on_group_solved(slot_index: int) -> void:
	# Slot fully solved — snap-reveal any remaining hidden letters.
	reveal_all(slot_index)
