## UIScale
## Autoload singleton. Computes a UI scale factor from the current viewport width.
## All UI files call UIScale.font(n) / UIScale.px(n) instead of raw pixel values,
## so the interface scales down on mobile and stays at 1.0 on desktop.
##
## Scale range: 0.60 (mobile ~390px) → 1.0 (desktop 720px+)
## Base viewport width: 720px (matches design spec).
##
## Register as Autoload in Project → Project Settings → Autoload:
##   Name: UIScale
##   Path: res://src/core/ui_scale.gd
extends Node

## Emitted when the viewport is resized enough to change the scale factor.
signal scale_changed(new_scale: float)

const BASE_WIDTH  := 720.0
const SCALE_MIN   := 0.60
const SCALE_MAX   := 1.0
## Minimum change in scale before scale_changed fires (avoids noise during drag).
const SCALE_DELTA := 0.02

var _scale: float = 1.0

func _ready() -> void:
	print("[UIScale] _ready: start")
	get_tree().root.size_changed.connect(_on_viewport_resized)
	_recalculate()
	print("[UIScale] _ready: end")

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Current scale multiplier (SCALE_MIN–SCALE_MAX).
func get_scale() -> float:
	return _scale

## Return a scaled font size (int, minimum 8).
## Usage: add_theme_font_size_override("font_size", UIScale.font(18))
func font(base_px: int) -> int:
	return maxi(8, roundi(base_px * _scale))

## Return a scaled integer pixel measurement (minimum 1).
func px(base_px: int) -> int:
	return maxi(1, roundi(base_px * _scale))

## Return a scaled float pixel measurement (minimum 1.0).
func pxf(base_px: float) -> float:
	return maxf(1.0, base_px * _scale)

## Return the appropriate content column width for the current viewport.
## Respects a 32px margin on each side, capped at BASE_WIDTH.
func content_width() -> float:
	var vp_w := _viewport_width()
	return minf(vp_w - pxf(64.0), BASE_WIDTH)

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _on_viewport_resized() -> void:
	_recalculate()

func _recalculate() -> void:
	print("[UIScale] _recalculate: start")
	var new_scale := clampf(_viewport_width() / BASE_WIDTH, SCALE_MIN, SCALE_MAX)
	if absf(new_scale - _scale) >= SCALE_DELTA:
		_scale = new_scale
		print("[UIScale] _recalculate: scale changed to %f" % _scale)
		scale_changed.emit(_scale)
	print("[UIScale] _recalculate: end (current scale=%f)" % _scale)

func _viewport_width() -> float:
	print("[UIScale] _viewport_width: start")
	var vp := get_viewport()
	if vp == null:
		print("[UIScale] _viewport_width: viewport is null, returning BASE_WIDTH")
		return BASE_WIDTH
	var w := maxf(1.0, vp.get_visible_rect().size.x)
	print("[UIScale] _viewport_width: returning %f" % w)
	return w
