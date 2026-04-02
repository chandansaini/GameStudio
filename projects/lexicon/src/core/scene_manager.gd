## SceneManager
## Autoload singleton. Handles scene transitions with a fade-to-black overlay.
## The overlay lives on CanvasLayer 100 (always on top of all game UI).
##
## Register as Autoload in Project → Project Settings → Autoload:
##   Name: SceneManager
##   Path: res://src/core/scene_manager.gd
extends Node

## Emitted just before the current scene is freed.
signal scene_unloading(scene_path: String)

## Emitted after the new scene becomes active.
signal scene_loaded(scene_path: String)

## Path of the currently loaded scene.
var current_scene_path: String = ""

const FADE_DURATION := 0.25

var _overlay: ColorRect

func _ready() -> void:
	var root := get_tree().root
	var current := root.get_child(root.get_child_count() - 1)
	current_scene_path = current.scene_file_path
	_build_overlay()

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	layer.add_child(_overlay)

## Transitions to a new scene with a fade-to-black.
## scene_path: res:// path to the .tscn file.
func go_to(scene_path: String) -> void:
	await _fade_out()
	scene_unloading.emit(current_scene_path)
	current_scene_path = scene_path
	get_tree().change_scene_to_file(scene_path)
	scene_loaded.emit(current_scene_path)
	await get_tree().process_frame
	await _fade_in()

## Reloads the current scene (e.g. "Play Again").
func reload_current() -> void:
	await go_to(current_scene_path)

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, FADE_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished

func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, FADE_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
