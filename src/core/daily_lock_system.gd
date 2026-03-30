## DailyLockSystem
## Autoload singleton. Manages daily puzzle delivery with UTC date-based locking.
## One puzzle per day. Prevents skip-ahead. Delegates persistence to SavePersist.
##
## Register as Autoload in Project → Project Settings → Autoload:
##   Name: DailyLock
##   Path: res://src/core/daily_lock_system.gd
extends Node

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns today's PuzzleData. Falls back to first available if today has no puzzle.
## Always returns the same puzzle for the same UTC date.
func get_today_puzzle() -> PuzzleData:
	return PuzzleLibrary.get_daily_puzzle()

## Returns the UTC date string for today (YYYY-MM-DD).
func today() -> String:
	return Time.get_date_string_from_system()

## Returns true if today's puzzle has already been completed.
func is_today_completed() -> bool:
	return SavePersist.is_puzzle_completed(today())

## Marks today's puzzle as completed and updates streak if won.
## Safe to call multiple times — SavePersist.update_streak() is idempotent for same date.
func mark_today_completed(won: bool) -> void:
	var date := today()
	SavePersist.mark_puzzle_completed(date)
	if won:
		SavePersist.update_streak(date)
