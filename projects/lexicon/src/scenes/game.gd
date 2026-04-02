## Game scene controller — builds the full UI tree in code.
## Content is centered in a UIScale.content_width() column.
## Rebuilds UI on viewport resize (debounced 150ms) while preserving game state.
extends Node

var _life_system: LifeSystem
var _slot_assignment: SlotAssignment
var _reveal_system: LetterRevealSystem
var _results_builder: ResultsBuilder
var _life_restore_timer: LifeRestoreTimer

var _life_indicator: LifeIndicatorUI
var _slot_ui: SlotUI
var _word_pool_ui: WordPoolUI
var _divider: ColorRect

var _canvas_layer: CanvasLayer = null
var _rebuild_pending := false

const COLOR_BG_BASE := Color(0.047, 0.047, 0.071)  # #0C0C12

func _ready() -> void:
	_build_gameplay()
	_build_ui()
	_wire()
	GSM.puzzle_solved.connect(_on_puzzle_solved)
	GSM.puzzle_failed.connect(_on_puzzle_failed)
	UIScale.scale_changed.connect(_on_scale_changed)
	await get_tree().process_frame
	var puzzle: PuzzleData
	if GSM.game_mode == GSM.GameMode.UNLIMITED:
		puzzle = PuzzleLibrary.get_unlimited_puzzle(SavePersist.get_unlimited_index())
	else:
		puzzle = DailyLock.get_today_puzzle()
		if puzzle == null:
			puzzle = PuzzleLibrary.get_puzzle("test_001")
	GSM.load_puzzle(puzzle)

# ---------------------------------------------------------------------------
# Gameplay nodes
# ---------------------------------------------------------------------------

func _build_gameplay() -> void:
	_life_system = LifeSystem.new()
	_slot_assignment = SlotAssignment.new()
	_reveal_system = LetterRevealSystem.new()
	_results_builder = ResultsBuilder.new()
	_life_restore_timer = LifeRestoreTimer.new()
	add_child(_life_system)
	add_child(_slot_assignment)
	add_child(_reveal_system)
	add_child(_results_builder)
	add_child(_life_restore_timer)

# ---------------------------------------------------------------------------
# UI tree — centered column, width from UIScale
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	if _canvas_layer != null:
		_canvas_layer.queue_free()

	_canvas_layer = CanvasLayer.new()
	add_child(_canvas_layer)

	# Background
	var bg := ColorRect.new()
	bg.color = COLOR_BG_BASE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas_layer.add_child(bg)

	# 20px side margins only (top/bottom unrestricted for scroll)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   UIScale.px(20))
	margin.add_theme_constant_override("margin_right",  UIScale.px(20))
	margin.add_theme_constant_override("margin_top",    0)
	margin.add_theme_constant_override("margin_bottom", 0)
	_canvas_layer.add_child(margin)

	# Horizontal centering row
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)

	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_spacer)

	# Content column
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(UIScale.content_width(), 0)
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", UIScale.px(16))
	hbox.add_child(content)

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_spacer)

	# --- Header: back button + LEXICON + lives ---
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, UIScale.px(72))
	header.add_theme_constant_override("separation", UIScale.px(12))
	content.add_child(header)

	var back_btn := Button.new()
	back_btn.text = "\u2190"
	back_btn.custom_minimum_size = Vector2(UIScale.px(72), UIScale.px(72))
	back_btn.add_theme_font_override("font", Fonts.bold)
	back_btn.add_theme_font_size_override("font_size", UIScale.font(22))
	back_btn.add_theme_color_override("font_color", Color(0.533, 0.533, 0.627))
	back_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var back_style := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus"]:
		back_btn.add_theme_stylebox_override(s, back_style)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	var title_lbl := Label.new()
	title_lbl.text = "LEXICON"
	title_lbl.add_theme_font_override("font", Fonts.bold)
	title_lbl.add_theme_font_size_override("font_size", UIScale.font(32))
	title_lbl.add_theme_color_override("font_color", Color(0.941, 0.937, 0.922))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_lbl)

	_life_indicator = LifeIndicatorUI.new()
	_life_indicator.size_flags_horizontal = Control.SIZE_SHRINK_END
	header.add_child(_life_indicator)

	# --- Slot panels ---
	_slot_ui = SlotUI.new()
	_slot_ui.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_slot_ui.add_theme_constant_override("separation", UIScale.px(8))
	content.add_child(_slot_ui)

	# --- Divider ---
	_divider = ColorRect.new()
	_divider.color = Color(0.165, 0.165, 0.227)
	_divider.custom_minimum_size = Vector2(0, 1)
	content.add_child(_divider)

	# --- Word pool grid ---
	_word_pool_ui = WordPoolUI.new()
	_word_pool_ui.columns = 3
	_word_pool_ui.add_theme_constant_override("h_separation", UIScale.px(8))
	_word_pool_ui.add_theme_constant_override("v_separation", UIScale.px(8))
	content.add_child(_word_pool_ui)

	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size = Vector2(0, UIScale.px(32))
	content.add_child(bottom_pad)

# ---------------------------------------------------------------------------

func _wire() -> void:
	_life_indicator.setup(_life_system)
	_slot_ui.setup(_slot_assignment, _reveal_system)
	_word_pool_ui.setup(_slot_assignment)

# ---------------------------------------------------------------------------
# Responsive rebuild
# ---------------------------------------------------------------------------

func _on_scale_changed(_new_scale: float) -> void:
	if _rebuild_pending:
		return
	_rebuild_pending = true
	get_tree().create_timer(0.15).timeout.connect(_do_rebuild)

func _do_rebuild() -> void:
	_rebuild_pending = false
	_build_ui()
	_life_indicator.setup(_life_system)
	_slot_ui.setup(_slot_assignment, _reveal_system)
	_word_pool_ui.setup(_slot_assignment)
	if GSM.active_puzzle:
		_slot_ui.rebuild()
		_word_pool_ui.rebuild()
		_life_indicator.refresh()

# ---------------------------------------------------------------------------
# Puzzle events
# ---------------------------------------------------------------------------

func _on_puzzle_solved() -> void:
	if GSM.game_mode == GSM.GameMode.DAILY:
		DailyLock.mark_today_completed(true)
	else:
		SavePersist.advance_unlimited_index()
	if _divider:
		_divider.visible = false
	_show_end_screen(true)

func _on_puzzle_failed() -> void:
	if GSM.game_mode == GSM.GameMode.DAILY:
		DailyLock.mark_today_completed(false)
	if _divider:
		_divider.visible = false
	_show_end_screen(false)

func _show_end_screen(won: bool) -> void:
	var screen := EndScreen.new()
	add_child(screen)

	var title := GSM.active_puzzle.title if GSM.active_puzzle else ""
	var share_text := _results_builder.build_share_text(won)
	var streak := SavePersist.get_streak() if won else 0
	var lives_remaining := GSM.lives
	var words_placed := 12 - GSM.pool_words.size()

	var categories: Array = []
	if not won and GSM.active_puzzle:
		for group in GSM.active_puzzle.groups:
			categories.append({"name": group.category_name, "anchor": group.anchor_word})

	screen.show_result(won, title, share_text, streak, lives_remaining, words_placed, categories)
	screen.back_to_menu_pressed.connect(_on_back_to_menu)
	screen.play_again_pressed.connect(_on_play_again)

func _on_back_pressed() -> void:
	# If puzzle is already over, go straight back
	if GSM.active_puzzle == null or GSM.solved_slots.all(func(s): return s) or GSM.lives == 0:
		SceneManager.go_to("res://src/scenes/main_menu.tscn")
		return
	# Mid-puzzle — show a confirm dialog
	var dialog := ConfirmationDialog.new()
	dialog.title = "Leave Puzzle?"
	dialog.dialog_text = "Your progress will be lost."
	dialog.ok_button_text = "Leave"
	dialog.cancel_button_text = "Keep Playing"
	dialog.confirmed.connect(func(): SceneManager.go_to("res://src/scenes/main_menu.tscn"))
	add_child(dialog)
	dialog.popup_centered()

func _on_back_to_menu() -> void:
	SceneManager.go_to("res://src/scenes/main_menu.tscn")

func _on_play_again() -> void:
	SceneManager.reload_current()
