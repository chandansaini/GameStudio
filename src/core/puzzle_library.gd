## PuzzleLibrary
## Autoload singleton. Loads and indexes all PuzzleData .tres files from
## data/puzzles/. Provides puzzle lookup by ID and daily puzzle resolution.
##
## Register as Autoload in Project → Project Settings → Autoload:
##   Name: PuzzleLibrary
##   Path: res://src/core/puzzle_library.gd
extends Node

## Emitted when all puzzles have been loaded and indexed.
signal library_loaded(puzzle_count: int)

## Emitted when a puzzle fails validation on load.
signal puzzle_load_error(puzzle_id: String, errors: Array)

const PUZZLE_DIR := "res://data/puzzles/"
const MANIFEST := preload("res://data/puzzle_manifest.gd")

## Internal index: puzzle_id → PuzzleData
var _puzzles: Dictionary = {}

var _is_loaded: bool = false

func _ready() -> void:
	_load_all_puzzles()

## Returns true once _load_all_puzzles() has completed.
func is_loaded() -> bool:
	return _is_loaded

## Returns a PuzzleData by puzzle_id, or null if not found.
func get_puzzle(puzzle_id: String) -> PuzzleData:
	return _puzzles.get(puzzle_id, null)

## Returns the puzzle for today's date (expects puzzle_id == "YYYY-MM-DD").
## Falls back to the first available puzzle if today's is missing.
func get_daily_puzzle() -> PuzzleData:
	var today := Time.get_date_string_from_system()
	if _puzzles.has(today):
		return _puzzles[today]
	# Fallback: return first puzzle in sorted ID order (deterministic)
	if not _puzzles.is_empty():
		var first_key: String = get_all_puzzle_ids()[0]
		push_warning("PuzzleLibrary: No puzzle for %s, falling back to '%s'" % [today, first_key])
		return _puzzles[first_key]
	push_error("PuzzleLibrary: No puzzles loaded!")
	return null

## Returns the puzzle at position [index] in sorted ID order (wraps on overflow).
## Used by unlimited mode to advance sequentially through all puzzles.
func get_unlimited_puzzle(index: int) -> PuzzleData:
	var ids := get_all_puzzle_ids()
	if ids.is_empty():
		return null
	return _puzzles[ids[index % ids.size()]]

## Total number of loaded puzzles.
func get_unlimited_count() -> int:
	return _puzzles.size()

## Returns all loaded puzzle IDs, sorted.
func get_all_puzzle_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _puzzles.keys():
		ids.append(key)
	ids.sort()
	return ids

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _load_all_puzzles() -> void:
	for puzzle_id in MANIFEST.PUZZLE_IDS:
		_load_puzzle_file(PUZZLE_DIR + puzzle_id + ".tres")

	_is_loaded = true
	library_loaded.emit(_puzzles.size())

func _load_puzzle_file(path: String) -> void:
	var resource := load(path)
	if not resource is PuzzleData:
		push_warning("PuzzleLibrary: Skipping non-PuzzleData resource at %s" % path)
		return

	var puzzle: PuzzleData = resource
	var errors := puzzle.validate()
	if errors.size() > 0:
		push_error("PuzzleLibrary: Puzzle at '%s' failed validation: %s" % [path, errors])
		puzzle_load_error.emit(puzzle.puzzle_id, errors)
		return

	if _puzzles.has(puzzle.puzzle_id):
		push_warning("PuzzleLibrary: Duplicate puzzle_id '%s', skipping %s" % [puzzle.puzzle_id, path])
		return

	_puzzles[puzzle.puzzle_id] = puzzle
