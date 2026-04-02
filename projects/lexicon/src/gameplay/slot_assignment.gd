## SlotAssignment
## Stateless two-step click model controller.
## Manages IDLE → WORD_SELECTED → (correct → IDLE|LOCKED | wrong → IDLE) transitions.
## Re-emits placement results as named signals so UI layers don't couple to GSM directly.
##
## Add as a child node in the game scene.
class_name SlotAssignment
extends Node

enum State { IDLE, WORD_SELECTED, LOCKED }

## Emitted when state changes.
signal state_changed(new_state: State)

## Emitted when a word is correctly placed into a slot.
signal placement_correct(word: String, slot_index: int)

## Emitted when a word is incorrectly placed into a slot.
signal placement_wrong(word: String, slot_index: int)

## Emitted when a slot is fully solved (all 4 words placed).
signal slot_solved(slot_index: int)

var _state: State = State.IDLE

func _ready() -> void:
	GSM.word_selected.connect(_on_word_selected)
	GSM.word_deselected.connect(_on_word_deselected)
	GSM.word_placed_correct.connect(_on_word_placed_correct)
	GSM.word_placed_wrong.connect(_on_word_placed_wrong)
	GSM.group_solved.connect(func(i): slot_solved.emit(i))
	GSM.puzzle_solved.connect(func(): _set_state(State.LOCKED))
	GSM.puzzle_failed.connect(func(): _set_state(State.LOCKED))

## Called by WordPoolUI when a word button is pressed.
func on_word_pressed(word: String) -> void:
	if _state == State.LOCKED:
		return
	GSM.select_word(word)

## Called by SlotUI when a slot panel is pressed.
func on_slot_pressed(slot_index: int) -> void:
	if _state != State.WORD_SELECTED:
		return
	GSM.place_word(slot_index)

func get_state() -> State:
	return _state

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	state_changed.emit(new_state)

func _on_word_selected(_word: String) -> void:
	_set_state(State.WORD_SELECTED)

func _on_word_deselected(_word: String) -> void:
	_set_state(State.IDLE)

func _on_word_placed_correct(word: String, slot_index: int) -> void:
	placement_correct.emit(word, slot_index)
	if GSM.unsolved_count() == 0:
		_set_state(State.LOCKED)
	else:
		_set_state(State.IDLE)

func _on_word_placed_wrong(word: String, slot_index: int) -> void:
	placement_wrong.emit(word, slot_index)
	if _state == State.LOCKED:
		return
	_set_state(State.IDLE)
