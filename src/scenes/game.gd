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

var _canvas_layer: CanvasLayer = null
var _rebuild_pending := false

const COLOR_BG_BASE := Color(0.047, 0.047, 0.071)  # #0C0C12

func _ready() -> void:
	print("[Game] _ready: start")
	print("[Game] _ready: calling _build_gameplay")
	_build_gameplay()
	print("[Game] _ready: calling _build_ui")
	_build_ui()
	print("[Game] _ready: calling _wire")
	_wire()
	print("[Game] _ready: connecting GSM.puzzle_solved")
	GSM.puzzle_solved.connect(_on_puzzle_solved)
	print("[Game] _ready: connecting GSM.puzzle_failed")
	GSM.puzzle_failed.connect(_on_puzzle_failed)
	print("[Game] _ready: connecting UIScale.scale_changed")
	UIScale.scale_changed.connect(_on_scale_changed)
	print("[Game] _ready: awaiting process_frame")
	await get_tree().process_frame
	print("[Game] _ready: fetching today's puzzle via DailyLock")
	var puzzle := DailyLock.get_today_puzzle()
	if puzzle == null:
		print("[Game] _ready: DailyLock returned null, falling back to test_001")
		puzzle = PuzzleLibrary.get_puzzle("test_001")
	print("[Game] _ready: puzzle is null = %s" % str(puzzle == null))
	GSM.load_puzzle(puzzle)
	print("[Game] _ready: end")

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
	print("[Game] _build_ui: start")

	if _canvas_layer != null:
		print("[Game] _build_ui: freeing existing canvas layer")
		_canvas_layer.queue_free()

	_canvas_layer = CanvasLayer.new()
	add_child(_canvas_layer)

	# Background
	print("[Game] _build_ui: creating background ColorRect")
	var bg := ColorRect.new()
	bg.color = COLOR_BG_BASE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas_layer.add_child(bg)

	# Full-screen anchor
	print("[Game] _build_ui: creating anchor Control")
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas_layer.add_child(anchor)

	# Horizontal centering row
	print("[Game] _build_ui: creating HBoxContainer")
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.add_child(hbox)

	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_spacer)

	# Content column
	print("[Game] _build_ui: creating content VBoxContainer")
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(UIScale.content_width(), 0)
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", UIScale.px(24))
	hbox.add_child(content)

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_spacer)

	# --- Header: LEXICON + lives (56px tall) ---
	print("[Game] _build_ui: creating header")
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, UIScale.px(56))
	header.add_theme_constant_override("separation", UIScale.px(12))
	content.add_child(header)

	var title_lbl := Label.new()
	title_lbl.text = "LEXICON"
	title_lbl.add_theme_font_size_override("font_size", UIScale.font(32))
	title_lbl.add_theme_color_override("font_color", Color(0.941, 0.937, 0.922))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_lbl)

	print("[Game] _build_ui: creating LifeIndicatorUI")
	_life_indicator = LifeIndicatorUI.new()
	_life_indicator.size_flags_horizontal = Control.SIZE_SHRINK_END
	header.add_child(_life_indicator)

	# --- Slot panels ---
	print("[Game] _build_ui: creating SlotUI")
	_slot_ui = SlotUI.new()
	_slot_ui.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_slot_ui.add_theme_constant_override("separation", UIScale.px(8))
	content.add_child(_slot_ui)

	# --- Divider ---
	print("[Game] _build_ui: creating divider")
	var divider := ColorRect.new()
	divider.color = Color(0.165, 0.165, 0.227)
	divider.custom_minimum_size = Vector2(0, 1)
	content.add_child(divider)

	# --- Word pool grid ---
	print("[Game] _build_ui: creating WordPoolUI")
	_word_pool_ui = WordPoolUI.new()
	_word_pool_ui.columns = 3
	_word_pool_ui.add_theme_constant_override("h_separation", UIScale.px(8))
	_word_pool_ui.add_theme_constant_override("v_separation", UIScale.px(8))
	content.add_child(_word_pool_ui)

	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size = Vector2(0, UIScale.px(32))
	content.add_child(bottom_pad)

	print("[Game] _build_ui: end")

# ---------------------------------------------------------------------------

func _wire() -> void:
	print("[Game] _wire: start")
	print("[Game] _wire: _life_indicator is null = %s" % str(_life_indicator == null))
	print("[Game] _wire: _life_system is null = %s" % str(_life_system == null))
	_life_indicator.setup(_life_system)
	print("[Game] _wire: _slot_ui is null = %s" % str(_slot_ui == null))
	print("[Game] _wire: _slot_assignment is null = %s" % str(_slot_assignment == null))
	print("[Game] _wire: _reveal_system is null = %s" % str(_reveal_system == null))
	_slot_ui.setup(_slot_assignment, _reveal_system)
	print("[Game] _wire: _word_pool_ui is null = %s" % str(_word_pool_ui == null))
	_word_pool_ui.setup(_slot_assignment)
	print("[Game] _wire: end")

# ---------------------------------------------------------------------------
# Responsive rebuild
# ---------------------------------------------------------------------------

func _on_scale_changed(_new_scale: float) -> void:
	if _rebuild_pending:
		return
	_rebuild_pending = true
	get_tree().create_timer(0.15).timeout.connect(_do_rebuild)

func _do_rebuild() -> void:
	print("[Game] _do_rebuild: start")
	_rebuild_pending = false
	_build_ui()
	print("[Game] _do_rebuild: _life_indicator is null = %s" % str(_life_indicator == null))
	_life_indicator.setup(_life_system)
	print("[Game] _do_rebuild: _slot_ui is null = %s" % str(_slot_ui == null))
	_slot_ui.setup(_slot_assignment, _reveal_system)
	print("[Game] _do_rebuild: _word_pool_ui is null = %s" % str(_word_pool_ui == null))
	_word_pool_ui.setup(_slot_assignment)
	print("[Game] _do_rebuild: GSM.active_puzzle is null = %s" % str(GSM.active_puzzle == null))
	if GSM.active_puzzle:
		_slot_ui.rebuild()
		_word_pool_ui.rebuild()
		_life_indicator.refresh()
	print("[Game] _do_rebuild: end")

# ---------------------------------------------------------------------------
# Puzzle events
# ---------------------------------------------------------------------------

func _on_puzzle_solved() -> void:
	print("[Game] _on_puzzle_solved: start")
	DailyLock.mark_today_completed(true)
	_show_end_screen(true)
	print("[Game] _on_puzzle_solved: end")

func _on_puzzle_failed() -> void:
	print("[Game] _on_puzzle_failed: start")
	DailyLock.mark_today_completed(false)
	_show_end_screen(false)
	print("[Game] _on_puzzle_failed: end")

func _show_end_screen(won: bool) -> void:
	print("[Game] _show_end_screen: start (won=%s)" % str(won))
	var screen := EndScreen.new()
	add_child(screen)

	print("[Game] _show_end_screen: GSM.active_puzzle is null = %s" % str(GSM.active_puzzle == null))
	var title := GSM.active_puzzle.title if GSM.active_puzzle else ""
	print("[Game] _show_end_screen: _results_builder is null = %s" % str(_results_builder == null))
	var share_text := _results_builder.build_share_text(won)
	var streak := SavePersist.get_streak() if won else 0
	var lives_remaining := GSM.lives
	var words_placed := 12 - GSM.pool_words.size()

	var categories: Array = []
	if not won and GSM.active_puzzle:
		for group in GSM.active_puzzle.groups:
			categories.append({"name": group.category_name, "anchor": group.anchor_word})

	print("[Game] _show_end_screen: calling screen.show_result")
	screen.show_result(won, title, share_text, streak, lives_remaining, words_placed, categories)
	screen.back_to_menu_pressed.connect(_on_back_to_menu)
	screen.play_again_pressed.connect(_on_play_again)
	print("[Game] _show_end_screen: end")

func _on_back_to_menu() -> void:
	SceneManager.go_to("res://src/scenes/main_menu.tscn")

func _on_play_again() -> void:
	SceneManager.reload_current()
