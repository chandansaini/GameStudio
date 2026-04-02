## EndScreen
## Overlay shown on puzzle_solved or puzzle_failed.
## Solved variant: ✓ SOLVED, lives circles, words count, COPY RESULT, countdown.
## Failed variant: ✗ FAILED, category reveals, TRY AGAIN (with restore timer), countdown.
## All sizes go through UIScale for responsive layout.
class_name EndScreen
extends CanvasLayer

signal back_to_menu_pressed
signal play_again_pressed

# ---------------------------------------------------------------------------
# Design tokens
# ---------------------------------------------------------------------------
const C_BG_OVERLAY    := Color(0.047, 0.047, 0.071, 0.80)
const C_CARD          := Color(0.090, 0.090, 0.125)         # #171720
const C_DIVIDER       := Color(0.165, 0.165, 0.227)         # #2A2A3A
const C_TEXT_PRIMARY  := Color(0.941, 0.937, 0.922)         # #F0EFEB
const C_TEXT_MUTED    := Color(0.533, 0.533, 0.627)         # #8888A0
const C_TEXT_DISABLED := Color(0.239, 0.239, 0.314)         # #3D3D50
const C_SOLVED        := Color(0.153, 0.682, 0.376)         # #27AE60
const C_FAILED        := Color(0.753, 0.224, 0.169)         # #C0392B
const C_GOLD          := Color(0.961, 0.784, 0.259)         # #F5C842
const C_GOLD_DIM      := Color(0.478, 0.396, 0.125)         # #7A6520
const C_BTN_DISABLED  := Color(0.165, 0.165, 0.220)         # #2A2A38

var _countdown_label: Label = null
var _countdown_timer: Timer = null

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func show_result(
	won: bool,
	puzzle_title: String,
	share_text: String,
	streak: int,
	lives_remaining: int,
	words_placed: int,
	categories: Array
) -> void:
	_build_overlay()
	var card := _build_card()
	if won:
		_build_solved(card, lives_remaining, words_placed, share_text)
	else:
		_build_failed(card, categories)
	if GSM.game_mode == GSM.GameMode.DAILY:
		_build_countdown(card)
		_start_countdown()
	_animate_card_in(card)

# ---------------------------------------------------------------------------
# Layout
# ---------------------------------------------------------------------------

func _build_overlay() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG_OVERLAY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _build_card() -> VBoxContainer:
	# Full-rect anchor so CenterContainer can reference screen size
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(anchor)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.add_child(center)

	var panel := PanelContainer.new()
	# Card width: responsive — min(480, viewport - 48px margins)
	var card_w := minf(UIScale.pxf(480.0), UIScale.content_width())
	panel.custom_minimum_size = Vector2(card_w, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = C_CARD
	style.corner_radius_top_left     = UIScale.px(16)
	style.corner_radius_top_right    = UIScale.px(16)
	style.corner_radius_bottom_left  = UIScale.px(16)
	style.corner_radius_bottom_right = UIScale.px(16)
	style.content_margin_left   = UIScale.px(40)
	style.content_margin_right  = UIScale.px(40)
	style.content_margin_top    = UIScale.px(40)
	style.content_margin_bottom = UIScale.px(36)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UIScale.px(20))
	panel.add_child(vbox)
	return vbox

func _build_solved(card: VBoxContainer, lives_remaining: int, words_placed: int, share_text: String) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", UIScale.px(16))
	card.add_child(title_row)

	var check_lbl := Label.new()
	check_lbl.text = "\u2713"
	check_lbl.add_theme_font_override("font", Fonts.bold)
	check_lbl.add_theme_font_size_override("font_size", UIScale.font(40))
	check_lbl.add_theme_color_override("font_color", C_SOLVED)
	title_row.add_child(check_lbl)

	var solved_lbl := Label.new()
	solved_lbl.text = "SOLVED"
	solved_lbl.add_theme_font_override("font", Fonts.bold)
	solved_lbl.add_theme_font_size_override("font_size", UIScale.font(48))
	solved_lbl.add_theme_color_override("font_color", C_SOLVED)
	title_row.add_child(solved_lbl)

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", UIScale.px(8))
	card.add_child(stats)

	var lives_row := HBoxContainer.new()
	lives_row.add_theme_constant_override("separation", UIScale.px(12))
	stats.add_child(lives_row)

	var lives_lbl := Label.new()
	lives_lbl.text = "Lives remaining:"
	lives_lbl.add_theme_font_override("font", Fonts.regular)
	lives_lbl.add_theme_font_size_override("font_size", UIScale.font(15))
	lives_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	lives_row.add_child(lives_lbl)

	_add_life_circles(lives_row, lives_remaining)

	var words_lbl := Label.new()
	words_lbl.text = "Words placed:  %d / 12" % words_placed
	words_lbl.add_theme_font_override("font", Fonts.regular)
	words_lbl.add_theme_font_size_override("font_size", UIScale.font(15))
	words_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	stats.add_child(words_lbl)

	_add_divider(card)

	if share_text != "":
		var copy_btn := Button.new()
		copy_btn.text = "COPY RESULT"
		copy_btn.custom_minimum_size = Vector2(0, UIScale.px(72))
		copy_btn.add_theme_font_override("font", Fonts.semibold)
		copy_btn.add_theme_font_size_override("font_size", UIScale.font(15))
		copy_btn.add_theme_color_override("font_color", Color.WHITE)
		_style_pill_button(copy_btn, C_SOLVED, C_SOLVED.lightened(0.12))
		copy_btn.pressed.connect(func():
			DisplayServer.clipboard_set(share_text)
			copy_btn.text = "\u2713  COPIED!"
		)
		card.add_child(copy_btn)

	if GSM.game_mode == GSM.GameMode.UNLIMITED:
		var next_btn := Button.new()
		next_btn.text = "Next Puzzle"
		next_btn.custom_minimum_size = Vector2(0, UIScale.px(72))
		next_btn.add_theme_font_override("font", Fonts.semibold)
		next_btn.add_theme_font_size_override("font_size", UIScale.font(15))
		next_btn.add_theme_color_override("font_color", Color.WHITE)
		_style_pill_button(next_btn, C_SOLVED, C_SOLVED.lightened(0.12))
		next_btn.pressed.connect(func(): play_again_pressed.emit())
		card.add_child(next_btn)

	_add_menu_button(card)

func _build_failed(card: VBoxContainer, categories: Array) -> void:
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", UIScale.px(16))
	card.add_child(title_row)

	var x_lbl := Label.new()
	x_lbl.text = "\u2717"
	x_lbl.add_theme_font_override("font", Fonts.bold)
	x_lbl.add_theme_font_size_override("font_size", UIScale.font(40))
	x_lbl.add_theme_color_override("font_color", C_FAILED)
	title_row.add_child(x_lbl)

	var failed_lbl := Label.new()
	failed_lbl.text = "FAILED"
	failed_lbl.add_theme_font_override("font", Fonts.bold)
	failed_lbl.add_theme_font_size_override("font_size", UIScale.font(48))
	failed_lbl.add_theme_color_override("font_color", C_FAILED)
	title_row.add_child(failed_lbl)

	var cat_block := VBoxContainer.new()
	cat_block.add_theme_constant_override("separation", UIScale.px(6))
	card.add_child(cat_block)

	var intro_lbl := Label.new()
	intro_lbl.text = "The categories were:"
	intro_lbl.add_theme_font_override("font", Fonts.regular)
	intro_lbl.add_theme_font_size_override("font_size", UIScale.font(15))
	intro_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	cat_block.add_child(intro_lbl)

	for cat in categories:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UIScale.px(8))
		cat_block.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = cat.get("name", "")
		name_lbl.add_theme_font_override("font", Fonts.semibold)
		name_lbl.add_theme_font_size_override("font_size", UIScale.font(15))
		name_lbl.add_theme_color_override("font_color", C_GOLD)
		row.add_child(name_lbl)

		var anchor_lbl := Label.new()
		anchor_lbl.text = "(%s)" % cat.get("anchor", "")
		anchor_lbl.add_theme_font_override("font", Fonts.regular)
		anchor_lbl.add_theme_font_size_override("font_size", UIScale.font(12))
		anchor_lbl.add_theme_color_override("font_color", C_TEXT_DISABLED)
		row.add_child(anchor_lbl)

	_add_divider(card)

	var try_btn := Button.new()
	try_btn.disabled = true
	try_btn.custom_minimum_size = Vector2(0, UIScale.px(72))
	try_btn.add_theme_font_override("font", Fonts.semibold)
	try_btn.add_theme_font_size_override("font_size", UIScale.font(15))
	try_btn.add_theme_color_override("font_color", C_TEXT_DISABLED)
	_style_pill_button_disabled(try_btn)
	var restore_secs := maxi(0, SavePersist.get_life_restore_timestamp() - int(Time.get_unix_time_from_system()))
	var h := restore_secs / 3600
	var m := (restore_secs % 3600) / 60
	try_btn.text = "TRY AGAIN  %dh %02dm" % [h, m] if h > 0 else "TRY AGAIN  %02d:%02d" % [m, restore_secs % 60]
	card.add_child(try_btn)

	_add_menu_button(card)

func _add_life_circles(parent: Node, lives_remaining: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIScale.px(6))
	parent.add_child(row)
	for i in range(3):
		var heart := Label.new()
		heart.text = "\u2665" if i < lives_remaining else "\u2661"
		heart.add_theme_font_override("font", Fonts.regular)
		heart.add_theme_font_size_override("font_size", UIScale.font(22))
		heart.add_theme_color_override("font_color",
			Color(0.824, 0.102, 0.110) if i < lives_remaining else Color(0.400, 0.102, 0.110))
		row.add_child(heart)

func _add_divider(parent: VBoxContainer) -> void:
	var div := ColorRect.new()
	div.color = C_DIVIDER
	div.custom_minimum_size = Vector2(0, 1)
	parent.add_child(div)

func _add_menu_button(card: VBoxContainer) -> void:
	var btn := Button.new()
	btn.text = "Back to Menu"
	btn.custom_minimum_size = Vector2(0, UIScale.px(72))
	btn.add_theme_font_override("font", Fonts.semibold)
	btn.add_theme_font_size_override("font_size", UIScale.font(15))
	btn.add_theme_color_override("font_color", C_TEXT_PRIMARY)
	_style_pill_button_outlined(btn)
	btn.pressed.connect(func(): back_to_menu_pressed.emit())
	card.add_child(btn)

func _build_countdown(card: VBoxContainer) -> void:
	_countdown_label = Label.new()
	_countdown_label.add_theme_font_override("font", Fonts.regular)
	_countdown_label.add_theme_font_size_override("font_size", UIScale.font(11))
	_countdown_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_countdown_label)
	_update_countdown_text()

func _start_countdown() -> void:
	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.one_shot = false
	_countdown_timer.timeout.connect(_update_countdown_text)
	add_child(_countdown_timer)
	_countdown_timer.start()

func _update_countdown_text() -> void:
	if _countdown_label == null:
		return
	var secs := _secs_until_midnight()
	_countdown_label.text = "Next puzzle in %d:%02d:%02d" % [secs / 3600, (secs % 3600) / 60, secs % 60]

func _secs_until_midnight() -> int:
	var now := int(Time.get_unix_time_from_system())
	var utc := Time.get_datetime_dict_from_unix_time(now)
	var midnight := Time.get_unix_time_from_datetime_dict({
		"year": utc["year"], "month": utc["month"], "day": utc["day"],
		"hour": 23, "minute": 59, "second": 59
	})
	return maxi(0, int(midnight) - now + 1)

# ---------------------------------------------------------------------------
# Button styles
# ---------------------------------------------------------------------------

func _style_pill_button(btn: Button, bg_normal: Color, bg_hover: Color) -> void:
	btn.add_theme_stylebox_override("normal",   _make_pill_style(bg_normal))
	btn.add_theme_stylebox_override("hover",    _make_pill_style(bg_hover))
	btn.add_theme_stylebox_override("pressed",  _make_pill_style(bg_hover))
	btn.add_theme_stylebox_override("focus",    _make_pill_style(bg_normal))
	btn.add_theme_stylebox_override("disabled", _make_pill_style(bg_normal))

func _style_pill_button_outlined(btn: Button) -> void:
	var normal_style := _make_pill_style(Color.TRANSPARENT)
	normal_style.border_width_left   = 1
	normal_style.border_width_right  = 1
	normal_style.border_width_top    = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(0.350, 0.350, 0.470)
	var hover_style := _make_pill_style(Color(0.165, 0.165, 0.220))
	hover_style.border_width_left   = 1
	hover_style.border_width_right  = 1
	hover_style.border_width_top    = 1
	hover_style.border_width_bottom = 1
	hover_style.border_color = Color(0.533, 0.533, 0.627)
	btn.add_theme_stylebox_override("normal",   normal_style)
	btn.add_theme_stylebox_override("hover",    hover_style)
	btn.add_theme_stylebox_override("pressed",  hover_style)
	btn.add_theme_stylebox_override("focus",    normal_style)
	btn.add_theme_stylebox_override("disabled", normal_style)

func _style_pill_button_disabled(btn: Button) -> void:
	var style := _make_pill_style(C_BTN_DISABLED)
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.180, 0.180, 0.251)
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(s, style)

func _make_pill_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left     = 9999
	style.corner_radius_top_right    = 9999
	style.corner_radius_bottom_left  = 9999
	style.corner_radius_bottom_right = 9999
	return style

func _animate_card_in(card: VBoxContainer) -> void:
	var panel := card.get_parent()
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)
