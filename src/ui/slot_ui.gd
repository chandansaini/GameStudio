## SlotUI
## Displays 4 slot panels. Each panel shows:
##   - Anchor word (always visible, pre-placed hint)
##   - Category name as blank/revealed character cells
##   - List of words correctly placed so far (excluding anchor)
##
## Supports full state restore after a UI rebuild via _restore_state().
## States per panel: ACTIVE / WRONG_FLASH / SOLVED / SOLVED_SETTLED / LOCKED
class_name SlotUI
extends VBoxContainer

const STAGGER_DELAY := 0.15

# Panel background colors
const COLOR_ACTIVE      := Color(0.090, 0.090, 0.125)   # #171720
const COLOR_WRONG_FLASH := Color(0.753, 0.224, 0.169)   # #C0392B
const COLOR_SOLVED      := Color(0.153, 0.682, 0.376)   # #27AE60
const COLOR_SOLVED_DIM  := Color(0.078, 0.239, 0.145)   # #143D25

# Text colors
const COLOR_ANCHOR      := Color(0.961, 0.784, 0.259)   # #F5C842
const COLOR_PLACED_WORD := Color(0.533, 0.533, 0.627)   # #8888A0

# Character cell colors
const COLOR_CELL_HIDDEN          := Color(0.478, 0.396, 0.125)  # #7A6520
const COLOR_CELL_HIDDEN_BORDER   := Color(0.478, 0.396, 0.125)  # #7A6520
const COLOR_CELL_REVEALED        := Color(0.961, 0.784, 0.259)  # #F5C842
const COLOR_CELL_REVEALED_BORDER := Color(0.961, 0.784, 0.259)  # #F5C842
const COLOR_CELL_BG              := Color(0.118, 0.118, 0.165)  # #1E1E2A

var _slot_assignment: SlotAssignment
var _reveal_system: LetterRevealSystem

var _panels: Array[PanelContainer] = []
var _char_label_maps: Array[Dictionary] = []
var _char_panel_maps: Array[Dictionary] = []
var _placed_word_boxes: Array[HFlowContainer] = []

func _ready() -> void:
	GSM.puzzle_loaded.connect(_on_puzzle_loaded)

func setup(slot_assignment: SlotAssignment, reveal_system: LetterRevealSystem) -> void:
	_slot_assignment = slot_assignment
	_reveal_system = reveal_system
	_slot_assignment.placement_correct.connect(_on_placement_correct)
	_slot_assignment.placement_wrong.connect(_on_placement_wrong)
	_slot_assignment.slot_solved.connect(_on_slot_solved)
	_reveal_system.letters_revealed.connect(_on_letters_revealed)

func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_panels.clear()
	_char_label_maps.clear()
	_char_panel_maps.clear()
	_placed_word_boxes.clear()

	if GSM.active_puzzle == null:
		return

	for i in range(4):
		var group: GroupData = GSM.active_puzzle.groups[i]
		_build_slot_panel(i, group)

	_restore_state()

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_puzzle_loaded(_puzzle: PuzzleData) -> void:
	rebuild()

func _on_placement_correct(word: String, slot_index: int) -> void:
	var session_anchor := GSM.session_anchors[slot_index] if slot_index < GSM.session_anchors.size() else GSM.active_puzzle.groups[slot_index].anchor_word
	if word != session_anchor:
		_add_placed_word(slot_index, word)

func _on_placement_wrong(_word: String, slot_index: int) -> void:
	_flash_panel(slot_index, COLOR_WRONG_FLASH)

func _on_slot_solved(slot_index: int) -> void:
	_set_panel_color(slot_index, COLOR_SOLVED)
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(func(): _set_panel_solved_settled(slot_index))

func _on_letters_revealed(slot_index: int, revealed_indices: Array[int], _is_fully_revealed: bool) -> void:
	_stagger_reveal(slot_index, revealed_indices)

# ---------------------------------------------------------------------------
# Private — panel construction
# ---------------------------------------------------------------------------

func _build_slot_panel(slot_index: int, group: GroupData) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, UIScale.px(96))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.name = "Slot%d" % slot_index
	_apply_panel_style(panel, COLOR_ACTIVE)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UIScale.px(4))
	panel.add_child(vbox)

	# Anchor word — left-aligned, gold (uses session anchor, not fixed puzzle data)
	var anchor_lbl := Label.new()
	anchor_lbl.text = GSM.session_anchors[slot_index] if slot_index < GSM.session_anchors.size() else group.anchor_word
	anchor_lbl.add_theme_font_override("font", Fonts.semibold)
	anchor_lbl.add_theme_font_size_override("font_size", UIScale.font(22))
	anchor_lbl.add_theme_color_override("font_color", COLOR_ANCHOR)
	anchor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(anchor_lbl)

	# Category name character cells.
	# Wrapped in a plain Control so its minimum width doesn't propagate upward
	# and force the content column wider than the viewport allows.
	var char_wrapper := Control.new()
	char_wrapper.custom_minimum_size = Vector2(0, UIScale.px(36))
	char_wrapper.clip_contents = true
	char_wrapper.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(char_wrapper)

	var char_row := HBoxContainer.new()
	char_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	char_row.add_theme_constant_override("separation", UIScale.px(4))
	char_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	char_wrapper.add_child(char_row)

	# Calculate cell width that fits all characters within the panel width.
	# Panel internal width = content_width - 24px (12px content_margin each side).
	var cell_w := _calc_cell_width(group.category_name)
	var cell_font_size := UIScale.font(20) if group.category_name.length() > 12 else UIScale.font(26)

	var label_map: Dictionary = {}
	var panel_map: Dictionary = {}
	var char_idx := 0
	for ch in group.category_name:
		if ch == " ":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(UIScale.px(12), UIScale.px(36))
			char_row.add_child(spacer)
		else:
			var cell := PanelContainer.new()
			cell.custom_minimum_size = Vector2(cell_w, UIScale.px(36))
			_apply_cell_style(cell, false)

			var lbl := Label.new()
			lbl.text = "_"
			lbl.add_theme_font_override("font", Fonts.mono_bold)
			lbl.add_theme_font_size_override("font_size", cell_font_size)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_color_override("font_color", COLOR_CELL_HIDDEN)
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cell.add_child(lbl)
			char_row.add_child(cell)

			label_map[char_idx] = lbl
			panel_map[char_idx] = cell
		char_idx += 1

	_char_label_maps.append(label_map)
	_char_panel_maps.append(panel_map)

	# Placed words — horizontal wrap
	var placed_box := HFlowContainer.new()
	placed_box.add_theme_constant_override("h_separation", UIScale.px(20))
	placed_box.add_theme_constant_override("v_separation", UIScale.px(2))
	vbox.add_child(placed_box)
	_placed_word_boxes.append(placed_box)

	# Invisible click overlay
	var btn := Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(_on_slot_pressed.bind(slot_index))
	var transparent := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state, transparent)
	panel.add_child(btn)

	add_child(panel)
	_panels.append(panel)

# ---------------------------------------------------------------------------
# State restore after rebuild
# ---------------------------------------------------------------------------

func _restore_state() -> void:
	if GSM.active_puzzle == null:
		return

	# Restore placed words (non-anchor words from GSM)
	for i in range(4):
		var session_anchor := GSM.session_anchors[i] if i < GSM.session_anchors.size() else GSM.active_puzzle.groups[i].anchor_word
		for word in GSM.placed_words[i]:
			if word != session_anchor:
				_add_placed_word(i, word)

	# Restore revealed letters instantly (no animation)
	if _reveal_system != null:
		for i in range(4):
			var revealed := _reveal_system.get_revealed_indices(i)
			_reveal_cells_instant(i, revealed)

	# Restore solved visual states
	for i in range(4):
		if GSM.solved_slots[i]:
			_set_panel_solved_settled(i)

func _reveal_cells_instant(slot_index: int, indices: Array[int]) -> void:
	if slot_index >= _char_label_maps.size():
		return
	var label_map: Dictionary = _char_label_maps[slot_index]
	var panel_map: Dictionary = _char_panel_maps[slot_index]
	var category: String = GSM.active_puzzle.groups[slot_index].category_name
	for idx in indices:
		if label_map.has(idx):
			var lbl: Label = label_map[idx]
			lbl.text = category[idx]
			lbl.add_theme_color_override("font_color", COLOR_CELL_REVEALED)
			_apply_cell_style(panel_map[idx], true)

func _add_placed_word(slot_index: int, word: String) -> void:
	if slot_index >= _placed_word_boxes.size():
		return
	var lbl := Label.new()
	lbl.text = word
	lbl.add_theme_font_override("font", Fonts.regular)
	lbl.add_theme_font_size_override("font_size", UIScale.font(15))
	lbl.add_theme_color_override("font_color", COLOR_PLACED_WORD)
	_placed_word_boxes[slot_index].add_child(lbl)

# ---------------------------------------------------------------------------
# Private — visual state
# ---------------------------------------------------------------------------

func _on_slot_pressed(slot_index: int) -> void:
	if _slot_assignment == null:
		return
	_slot_assignment.on_slot_pressed(slot_index)

func _stagger_reveal(slot_index: int, indices: Array[int]) -> void:
	if slot_index >= _char_label_maps.size():
		return
	var label_map: Dictionary = _char_label_maps[slot_index]
	var panel_map: Dictionary = _char_panel_maps[slot_index]
	var category: String = GSM.active_puzzle.groups[slot_index].category_name
	var delay := 0.0

	for idx in indices:
		if not label_map.has(idx):
			continue
		var lbl: Label = label_map[idx]
		var cell: PanelContainer = panel_map[idx]

		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func():
			lbl.text = category[idx]
			lbl.add_theme_color_override("font_color", COLOR_CELL_REVEALED)
			_apply_cell_style(cell, true)
			lbl.pivot_offset = lbl.size / 2
			lbl.scale = Vector2(0.7, 0.7)
			var stween := lbl.create_tween()
			stween.tween_property(lbl, "scale", Vector2.ONE, 0.2) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		delay += STAGGER_DELAY

func _flash_panel(slot_index: int, flash_color: Color) -> void:
	if slot_index >= _panels.size():
		return
	_set_panel_color(slot_index, flash_color)
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(func(): _set_panel_color(slot_index, COLOR_ACTIVE))

func _set_panel_color(slot_index: int, color: Color) -> void:
	if slot_index >= _panels.size():
		return
	_apply_panel_style(_panels[slot_index], color)

func _set_panel_solved_settled(slot_index: int) -> void:
	if slot_index >= _panels.size():
		return
	var panel := _panels[slot_index]
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SOLVED_DIM
	style.border_width_left = 3
	style.border_color = COLOR_SOLVED
	style.corner_radius_top_left     = 12
	style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left   = 13
	style.content_margin_right  = 12
	style.content_margin_top    = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

## Returns the cell width (px) that fits all chars of [category_name]
## within the available panel width, capped at the design-spec max of 28px.
func _calc_cell_width(category_name: String) -> int:
	var non_space := 0
	var spaces := 0
	for ch in category_name:
		if ch == " ":
			spaces += 1
		else:
			non_space += 1
	if non_space == 0:
		return UIScale.px(28)
	var avail := UIScale.content_width() - UIScale.pxf(24.0)  # 12px content_margin each side
	var space_total := UIScale.px(12) * spaces
	var sep_total := UIScale.px(4) * (non_space + spaces - 1)
	var cell_w := int((avail - space_total - sep_total) / non_space)
	return clampi(cell_w, UIScale.px(14), UIScale.px(28))

func _apply_panel_style(panel: PanelContainer, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left     = 12
	style.corner_radius_top_right    = 12
	style.corner_radius_bottom_left  = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left   = 12
	style.content_margin_right  = 12
	style.content_margin_top    = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

func _apply_cell_style(cell: PanelContainer, revealed: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.961, 0.784, 0.259, 0.12) if revealed else COLOR_CELL_BG
	style.border_width_bottom = 2
	style.border_color = COLOR_CELL_REVEALED_BORDER if revealed else COLOR_CELL_HIDDEN_BORDER
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	cell.add_theme_stylebox_override("panel", style)
