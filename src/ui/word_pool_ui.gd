## WordPoolUI
## Displays shuffled word buttons in a 3-column grid.
## Shuffle order is fixed at puzzle load and preserved across UI rebuilds.
## Button states: NORMAL → SELECTED → WRONG_FLASH → REMOVED
class_name WordPoolUI
extends GridContainer

const WRONG_FLASH_DURATION := 0.4

# Design tokens
const COLOR_NORMAL_BG       := Color(0.118, 0.118, 0.165)  # #1E1E2A
const COLOR_NORMAL_BORDER   := Color(0.180, 0.180, 0.251)  # #2E2E40
const COLOR_NORMAL_TEXT     := Color(0.941, 0.937, 0.922)  # #F0EFEB
const COLOR_HOVER_BG        := Color(0.165, 0.165, 0.220)  # #2A2A38
const COLOR_SELECTED_BG     := Color(0.110, 0.239, 0.431)  # #1C3D6E
const COLOR_SELECTED_BORDER := Color(0.227, 0.482, 0.831)  # #3A7BD5
const COLOR_WRONG_BG        := Color(0.906, 0.298, 0.235)  # #E74C3C

var _slot_assignment: SlotAssignment
## word → Button node
var _buttons: Dictionary = {}
## Stable shuffled word order — only re-shuffled on puzzle_loaded, preserved on rebuild.
var _word_order: Array[String] = []

func _ready() -> void:
	GSM.word_selected.connect(_on_word_selected)
	GSM.word_deselected.connect(_on_word_deselected)
	GSM.puzzle_loaded.connect(_on_puzzle_loaded)
	GSM.puzzle_failed.connect(_on_puzzle_end)
	GSM.puzzle_solved.connect(_on_puzzle_end)

## Inject SlotAssignment dependency. Call after adding to scene tree.
func setup(slot_assignment: SlotAssignment) -> void:
	_slot_assignment = slot_assignment
	_slot_assignment.placement_correct.connect(_on_placement_correct)
	_slot_assignment.placement_wrong.connect(_on_placement_wrong)

## Rebuilds buttons from the stored word order, skipping already-placed words.
## Preserves shuffle order across UI rebuilds.
func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_buttons.clear()

	if GSM.active_puzzle == null or _word_order.is_empty():
		return

	# Restore currently selected word after rebuild
	var current_selection := GSM.selected_word

	for word in _word_order:
		if word not in GSM.pool_words:
			continue  # Already placed — skip
		var btn := _make_button(word)
		add_child(btn)
		_buttons[word] = btn

	# Restore selection state
	if current_selection != "" and _buttons.has(current_selection):
		_set_button_state(_buttons[current_selection], "selected")

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_puzzle_loaded(_puzzle: PuzzleData) -> void:
	# Shuffle once per puzzle, then preserve order across rebuilds
	_word_order = GSM.pool_words.duplicate()
	_word_order.shuffle()
	rebuild()

func _on_word_selected(word: String) -> void:
	for w in _buttons:
		if is_instance_valid(_buttons[w]):
			_set_button_state(_buttons[w], "normal")
	if _buttons.has(word) and is_instance_valid(_buttons[word]):
		_set_button_state(_buttons[word], "selected")

func _on_word_deselected(_word: String) -> void:
	for w in _buttons:
		if is_instance_valid(_buttons[w]):
			_set_button_state(_buttons[w], "normal")

func _on_placement_correct(word: String, _slot_index: int) -> void:
	if not _buttons.has(word):
		return
	var btn: Button = _buttons[word]
	btn.disabled = true
	btn.pivot_offset = btn.size / 2
	var tween := btn.create_tween()
	tween.set_parallel(true)
	tween.tween_property(btn, "scale", Vector2(0.8, 0.8), 0.3).set_ease(Tween.EASE_IN)
	tween.tween_property(btn, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		_buttons.erase(word)
		btn.queue_free()
	)

func _on_placement_wrong(word: String, _slot_index: int) -> void:
	if not _buttons.has(word):
		return
	_flash_wrong(_buttons[word])

func _on_puzzle_end() -> void:
	visible = false

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _make_button(word: String) -> Button:
	var btn := Button.new()
	btn.text = word
	btn.name = word
	# Width fills the grid column; height scales with viewport
	btn.custom_minimum_size = Vector2(0, UIScale.px(64))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", UIScale.font(18))
	btn.add_theme_color_override("font_color", COLOR_NORMAL_TEXT)
	btn.pressed.connect(_on_button_pressed.bind(word))
	_set_button_state(btn, "normal")
	return btn

func _on_button_pressed(word: String) -> void:
	if _slot_assignment == null:
		push_error("WordPoolUI: slot_assignment not set — call setup() first")
		return
	_slot_assignment.on_word_pressed(word)

func _flash_wrong(btn: Button) -> void:
	_set_button_state(btn, "wrong")
	var tween := create_tween()
	tween.tween_interval(WRONG_FLASH_DURATION)
	tween.tween_callback(func(): _set_button_state(btn, "normal"))

func _set_button_state(btn: Button, state: String) -> void:
	var normal_style := _make_style(COLOR_NORMAL_BG, COLOR_NORMAL_BORDER, 1)
	var hover_style  := _make_style(COLOR_HOVER_BG,  COLOR_NORMAL_BORDER, 1)

	match state:
		"normal":
			btn.add_theme_color_override("font_color", COLOR_NORMAL_TEXT)
			btn.add_theme_stylebox_override("normal",   normal_style)
			btn.add_theme_stylebox_override("hover",    hover_style)
			btn.add_theme_stylebox_override("pressed",  hover_style)
			btn.add_theme_stylebox_override("focus",    normal_style)
			btn.add_theme_stylebox_override("disabled", normal_style)
		"selected":
			var sel_style := _make_style(COLOR_SELECTED_BG, COLOR_SELECTED_BORDER, 2)
			btn.add_theme_color_override("font_color", Color.WHITE)
			for s in ["normal", "hover", "pressed", "focus", "disabled"]:
				btn.add_theme_stylebox_override(s, sel_style)
		"wrong":
			var wrong_style := _make_style(COLOR_WRONG_BG, Color.TRANSPARENT, 0)
			btn.add_theme_color_override("font_color", Color.WHITE)
			for s in ["normal", "hover", "pressed", "focus", "disabled"]:
				btn.add_theme_stylebox_override(s, wrong_style)

func _make_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left   = border_width
	style.border_width_right  = border_width
	style.border_width_top    = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	return style
