## MainMenu scene controller.
## Entry point of the game. Shows today's puzzle availability, streak, and
## life restore countdown if lives are depleted.
## Rebuilds UI on viewport resize via UIScale.scale_changed.
extends Node

const C_BG           := Color(0.047, 0.047, 0.071)   # #0C0C12
const C_TEXT_PRIMARY := Color(0.941, 0.937, 0.922)   # #F0EFEB
const C_TEXT_MUTED   := Color(0.533, 0.533, 0.627)   # #8888A0
const C_ACCENT       := Color(0.153, 0.682, 0.376)   # #27AE60
const C_WARN         := Color(0.918, 0.682, 0.118)   # #EAAE1E

var _status_label: Label
var _play_btn: Button
var _restore_timer: LifeRestoreTimer
var _canvas_layer: CanvasLayer = null
var _rebuild_pending := false

func _ready() -> void:
	print("[MainMenu] _ready: start")
	_restore_timer = LifeRestoreTimer.new()
	add_child(_restore_timer)
	_restore_timer.lives_restored.connect(_on_lives_restored)
	_restore_timer.countdown_tick.connect(_on_countdown_tick)
	UIScale.scale_changed.connect(_on_scale_changed)
	_build_ui()
	_refresh_state()
	print("[MainMenu] _ready: end")

# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	print("[MainMenu] _build_ui: start")
	if _canvas_layer != null:
		print("[MainMenu] _build_ui: freeing existing canvas layer")
		_canvas_layer.queue_free()

	_canvas_layer = CanvasLayer.new()
	add_child(_canvas_layer)

	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas_layer.add_child(bg)

	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas_layer.add_child(anchor)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.add_child(hbox)

	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_spacer)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(UIScale.content_width(), 0)
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", UIScale.px(32))
	hbox.add_child(content)

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_spacer)

	# Title
	var title := Label.new()
	title.text = "LEXICON"
	title.add_theme_font_size_override("font_size", UIScale.font(64))
	title.add_theme_color_override("font_color", C_TEXT_PRIMARY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	# Tagline
	var tagline := Label.new()
	tagline.text = "Daily word grouping puzzle"
	tagline.add_theme_font_size_override("font_size", UIScale.font(16))
	tagline.add_theme_color_override("font_color", C_TEXT_MUTED)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(tagline)

	# Streak
	var streak := SavePersist.get_streak()
	if streak > 0:
		var streak_row := HBoxContainer.new()
		streak_row.alignment = BoxContainer.ALIGNMENT_CENTER
		streak_row.add_theme_constant_override("separation", UIScale.px(6))
		content.add_child(streak_row)

		var emoji_font := load("res://assets/fonts/NotoEmoji-Regular.ttf") as FontFile
		var fire_lbl := Label.new()
		fire_lbl.text = char(0x1F525)
		fire_lbl.add_theme_font_size_override("font_size", UIScale.font(22))
		if emoji_font != null:
			fire_lbl.add_theme_font_override("font", emoji_font)
		streak_row.add_child(fire_lbl)

		var streak_lbl := Label.new()
		streak_lbl.text = "%d day streak" % streak
		streak_lbl.add_theme_font_size_override("font_size", UIScale.font(20))
		streak_lbl.add_theme_color_override("font_color", C_WARN)
		streak_row.add_child(streak_lbl)

		# Looping pulse animation on the fire emoji (pivot set after first layout)
		fire_lbl.resized.connect(func():
			fire_lbl.pivot_offset = fire_lbl.size / 2.0
		)
		var tween := fire_lbl.create_tween().set_loops()
		tween.tween_property(fire_lbl, "scale", Vector2(1.2, 1.2), 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(fire_lbl, "scale", Vector2(1.0, 1.0), 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Play button
	_play_btn = Button.new()
	_play_btn.custom_minimum_size = Vector2(UIScale.px(280), UIScale.px(64))
	_play_btn.add_theme_font_size_override("font_size", UIScale.font(22))
	_play_btn.add_theme_color_override("font_color", C_TEXT_PRIMARY)
	_style_button(_play_btn, C_ACCENT, C_ACCENT.lightened(0.15))
	_play_btn.pressed.connect(_on_play_pressed)
	content.add_child(_play_btn)
	print("[MainMenu] _build_ui: play button created")

	# Status label
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", UIScale.font(15))
	_status_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.visible = false
	content.add_child(_status_label)
	print("[MainMenu] _build_ui: end")

# ---------------------------------------------------------------------------
# Responsive rebuild
# ---------------------------------------------------------------------------

func _on_scale_changed(_s: float) -> void:
	print("[MainMenu] _on_scale_changed: scale=%f" % _s)
	if _rebuild_pending:
		print("[MainMenu] _on_scale_changed: rebuild already pending, skipping")
		return
	_rebuild_pending = true
	get_tree().create_timer(0.15).timeout.connect(func():
		print("[MainMenu] _on_scale_changed: debounce fired, rebuilding")
		_rebuild_pending = false
		_build_ui()
		_refresh_state()
	)

# ---------------------------------------------------------------------------
# State management
# ---------------------------------------------------------------------------

func _refresh_state() -> void:
	print("[MainMenu] _refresh_state: start")
	if _play_btn == null:
		print("[MainMenu] _refresh_state: _play_btn is null, returning early")
		return

	print("[MainMenu] _refresh_state: _status_label is null = %s" % str(_status_label == null))
	print("[MainMenu] _refresh_state: _restore_timer is null = %s" % str(_restore_timer == null))

	if DailyLock.is_today_completed():
		print("[MainMenu] _refresh_state: today is completed")
		_play_btn.text = "Completed Today \u2713"
		_play_btn.disabled = true
		_status_label.text = "Come back tomorrow for a new puzzle."
		_status_label.visible = true
		print("[MainMenu] _refresh_state: end (completed)")
		return

	if _restore_timer.is_counting_down():
		print("[MainMenu] _refresh_state: restore timer is counting down")
		_play_btn.text = "No Lives Left"
		_play_btn.disabled = true
		_status_label.text = _format_countdown(_restore_timer.get_seconds_remaining())
		_status_label.visible = true
		print("[MainMenu] _refresh_state: end (counting down)")
		return

	_play_btn.text = "Play Today's Puzzle"
	_play_btn.disabled = false
	_status_label.visible = false
	print("[MainMenu] _refresh_state: end (ready to play)")

func _on_play_pressed() -> void:
	SceneManager.go_to("res://src/scenes/game.tscn")

func _on_lives_restored() -> void:
	_refresh_state()

func _on_countdown_tick(seconds_remaining: int) -> void:
	if _status_label != null and _status_label.visible:
		_status_label.text = _format_countdown(seconds_remaining)

func _format_countdown(seconds: int) -> String:
	var h := seconds / 3600
	var m := (seconds % 3600) / 60
	var s := seconds % 60
	if h > 0:
		return "Lives restore in %dh %02dm" % [h, m]
	elif m > 0:
		return "Lives restore in %dm %02ds" % [m, s]
	return "Lives restore in %ds" % s

# ---------------------------------------------------------------------------
# Button style
# ---------------------------------------------------------------------------

func _style_button(btn: Button, bg_normal: Color, bg_hover: Color) -> void:
	btn.add_theme_stylebox_override("normal",   _make_btn_style(bg_normal))
	btn.add_theme_stylebox_override("hover",    _make_btn_style(bg_hover))
	btn.add_theme_stylebox_override("pressed",  _make_btn_style(bg_hover))
	btn.add_theme_stylebox_override("focus",    _make_btn_style(bg_normal))
	btn.add_theme_stylebox_override("disabled", _make_btn_style(bg_normal.darkened(0.4)))

func _make_btn_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	return style
