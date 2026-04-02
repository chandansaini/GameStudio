## SavePersistSystem
## Autoload singleton. Handles all game state persistence via ConfigFile.
## Stores: puzzle completion history, streak, lives count, life restore timestamp.
##
## Register as Autoload in Project → Project Settings → Autoload:
##   Name: SavePersist
##   Path: res://src/core/save_persist_system.gd
extends Node

const SAVE_PATH := "user://lexicon_save.cfg"

var _config: ConfigFile

func _ready() -> void:
	_config = ConfigFile.new()
	_config.load(SAVE_PATH)  # no-op if file doesn't exist yet

# ---------------------------------------------------------------------------
# Puzzle Completion
# ---------------------------------------------------------------------------

## Returns true if the puzzle with the given ID has been completed.
func is_puzzle_completed(puzzle_id: String) -> bool:
	return _config.get_value("completed", puzzle_id, false)

## Marks a puzzle as completed and persists immediately.
func mark_puzzle_completed(puzzle_id: String) -> void:
	_config.set_value("completed", puzzle_id, true)
	_save()

# ---------------------------------------------------------------------------
# Lives
# ---------------------------------------------------------------------------

## Returns the saved lives count. Defaults to MAX_LIVES if never set.
func get_lives() -> int:
	return _config.get_value("lives", "count", 3)

## Persists the current lives count.
func save_lives(count: int) -> void:
	_config.set_value("lives", "count", count)
	_save()

# ---------------------------------------------------------------------------
# Life Restore Timer
# ---------------------------------------------------------------------------

## Returns the Unix timestamp when lives should be restored (0 = no pending restore).
func get_life_restore_timestamp() -> int:
	return _config.get_value("lives", "restore_timestamp", 0)

## Sets the Unix timestamp for life restoration (current_time + restore_delay).
func set_life_restore_timestamp(unix_time: int) -> void:
	_config.set_value("lives", "restore_timestamp", unix_time)
	_save()

## Clears the restore timer and resets lives to full.
func clear_life_restore() -> void:
	_config.set_value("lives", "restore_timestamp", 0)
	_config.set_value("lives", "count", 3)
	_save()

# ---------------------------------------------------------------------------
# Streak
# ---------------------------------------------------------------------------

## Returns the current consecutive-days streak.
func get_streak() -> int:
	return _config.get_value("streak", "count", 0)

## Returns the YYYY-MM-DD date of the last streak increment.
func get_streak_last_date() -> String:
	return _config.get_value("streak", "last_date", "")

## Updates the streak based on solved_date (YYYY-MM-DD).
## Increments if solved_date is the day after last_date.
## Resets to 1 if a day was missed. No-op if already updated today.
func update_streak(solved_date: String) -> void:
	var last_date := get_streak_last_date()
	if last_date == solved_date:
		return  # Already updated today

	var current_streak := get_streak()
	var yesterday := _date_offset(solved_date, -1)

	if last_date == yesterday:
		current_streak += 1
	else:
		current_streak = 1

	_config.set_value("streak", "count", current_streak)
	_config.set_value("streak", "last_date", solved_date)
	_save()

# ---------------------------------------------------------------------------
# Session Anchors
# ---------------------------------------------------------------------------

## Returns the saved session anchor words for a puzzle (one per slot).
## Returns an empty array if no anchors have been saved yet.
func get_session_anchors(puzzle_id: String) -> Array[String]:
	var raw = _config.get_value("session_anchors", puzzle_id, [])
	var result: Array[String] = []
	for v in raw:
		result.append(str(v))
	return result

## Saves the chosen anchor words for a puzzle session.
func set_session_anchors(puzzle_id: String, anchors: Array[String]) -> void:
	_config.set_value("session_anchors", puzzle_id, anchors)
	_save()

# ---------------------------------------------------------------------------
# Unlimited Mode Progress
# ---------------------------------------------------------------------------

## Returns the index of the next unlimited puzzle to play.
func get_unlimited_index() -> int:
	return _config.get_value("unlimited", "index", 0)

## Advances to the next unlimited puzzle. Called after a puzzle is solved.
func advance_unlimited_index() -> void:
	_config.set_value("unlimited", "index", get_unlimited_index() + 1)
	_save()

## Clears the saved anchors for a puzzle so the next load picks fresh ones.
## Called after a puzzle failure so "Play Again" gets a new set of hints.
func clear_session_anchors(puzzle_id: String) -> void:
	if _config.has_section_key("session_anchors", puzzle_id):
		_config.erase_section_key("session_anchors", puzzle_id)
		_save()

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _save() -> void:
	var err := _config.save(SAVE_PATH)
	if err != OK:
		push_error("SavePersistSystem: Failed to save to %s (error %d)" % [SAVE_PATH, err])

## Returns the YYYY-MM-DD string for the date offset by `days` from `date_str`.
func _date_offset(date_str: String, days: int) -> String:
	var parts := date_str.split("-")
	if parts.size() != 3:
		return ""
	var unix := Time.get_unix_time_from_datetime_dict({
		"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
		"hour": 12, "minute": 0, "second": 0
	})
	var offset_unix := unix + (days * 86400)
	var d := Time.get_datetime_dict_from_unix_time(offset_unix)
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]
