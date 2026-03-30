## SceneManager
## Autoload singleton. Handles scene transitions with optional loading screen.
## For MVP, transitions are instant (no loading screen needed).
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

func _ready() -> void:
	# Capture the initial scene path from the scene tree.
	var root := get_tree().root
	var current := root.get_child(root.get_child_count() - 1)
	current_scene_path = current.scene_file_path

## Transitions to a new scene by path.
## scene_path: res:// path to the .tscn file.
func go_to(scene_path: String) -> void:
	scene_unloading.emit(current_scene_path)
	current_scene_path = scene_path
	get_tree().change_scene_to_file(scene_path)
	scene_loaded.emit(current_scene_path)

## Reloads the current scene (e.g. "Play Again").
func reload_current() -> void:
	go_to(current_scene_path)
