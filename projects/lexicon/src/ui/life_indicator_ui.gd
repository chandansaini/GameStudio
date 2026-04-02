## LifeIndicatorUI
## Displays remaining lives as red heart glyphs.
## Full life: red ♥. Lost life: dim red ♡.
class_name LifeIndicatorUI
extends HBoxContainer

const GLYPH_FULL := "\u2665"  # ♥
const GLYPH_LOST := "\u2661"  # ♡

const COLOR_FULL := Color(0.824, 0.102, 0.110)  # #D21A1C — red
const COLOR_LOST := Color(0.400, 0.102, 0.110)  # #661A1C — dim red
const HEART_GAP  := 8
const HEART_SIZE := 22  # base px — scaled via UIScale.font()

var _life_system: LifeSystem
var _icons: Array[Label] = []

func _ready() -> void:
	add_theme_constant_override("separation", HEART_GAP)
	GSM.puzzle_loaded.connect(_on_puzzle_loaded)

## Inject LifeSystem dependency. Call after adding to scene tree.
func setup(life_system: LifeSystem) -> void:
	_life_system = life_system
	_life_system.life_lost.connect(_on_life_lost)

func refresh() -> void:
	_build_icons()
	_sync_to_lives(GSM.lives)

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_puzzle_loaded(_puzzle: PuzzleData) -> void:
	refresh()

func _on_life_lost(lives_remaining: int) -> void:
	var lost_index := lives_remaining
	if lost_index < _icons.size():
		var icon := _icons[lost_index]
		icon.pivot_offset = icon.size / 2
		var tween := icon.create_tween()
		tween.tween_property(icon, "scale", Vector2(0.0, 0.0), 0.3).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			_sync_icon(icon, false)
			icon.scale = Vector2.ONE
		)
	else:
		_sync_to_lives(lives_remaining)

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _build_icons() -> void:
	for child in get_children():
		child.queue_free()
	_icons.clear()

	for i in range(GSM.MAX_LIVES):
		var lbl := Label.new()
		lbl.name = "Heart%d" % i
		lbl.add_theme_font_override("font", Fonts.regular)
		lbl.add_theme_font_size_override("font_size", UIScale.font(HEART_SIZE))
		add_child(lbl)
		_icons.append(lbl)

func _sync_to_lives(lives_remaining: int) -> void:
	for i in range(_icons.size()):
		_sync_icon(_icons[i], i < lives_remaining)

func _sync_icon(icon: Label, is_full: bool) -> void:
	icon.text = GLYPH_FULL if is_full else GLYPH_LOST
	icon.add_theme_color_override("font_color", COLOR_FULL if is_full else COLOR_LOST)
