## LifeRestoreTimer
## Node added to the game scene. Manages the 8-hour life restore mechanic.
##
## On _ready:
##   - If a restore timestamp is saved and has already elapsed → restore lives immediately.
##   - If a restore timestamp is saved and has not elapsed → start a countdown timer.
##
## On puzzle_failed:
##   - Saves restore_timestamp = now + RESTORE_DELAY_SECONDS to SavePersist.
##   - Starts internal countdown timer.
##
## On timer expired:
##   - Restores lives to MAX_LIVES, clears the saved timestamp.
##   - Emits lives_restored so the end screen can react.
class_name LifeRestoreTimer
extends Node

## Emitted when the restore timer expires and lives have been refilled.
signal lives_restored

## Emitted each second while the restore timer is counting down.
## seconds_remaining: how many whole seconds are left.
signal countdown_tick(seconds_remaining: int)

const RESTORE_DELAY_SECONDS := 2 * 3600  # 2 hours

var _timer: Timer
var _restore_at: int = 0  # Unix timestamp for restore

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = 1.0
	_timer.timeout.connect(_on_tick)
	add_child(_timer)

	GSM.puzzle_failed.connect(_on_puzzle_failed)

	# Check for a pending restore from a previous session
	var saved_ts := SavePersist.get_life_restore_timestamp()
	if saved_ts > 0:
		var now := int(Time.get_unix_time_from_system())
		if now >= saved_ts:
			_do_restore()
		else:
			_restore_at = saved_ts
			_timer.start()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns seconds remaining until lives are restored (0 if no timer active).
func get_seconds_remaining() -> int:
	if _restore_at == 0:
		return 0
	var now := int(Time.get_unix_time_from_system())
	return maxi(0, _restore_at - now)

## Returns true if a restore timer is currently running.
func is_counting_down() -> bool:
	return _restore_at > 0

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _on_puzzle_failed() -> void:
	var now := int(Time.get_unix_time_from_system())
	_restore_at = now + RESTORE_DELAY_SECONDS
	SavePersist.set_life_restore_timestamp(_restore_at)
	SavePersist.save_lives(0)
	_timer.start()

func _on_tick() -> void:
	var remaining := get_seconds_remaining()
	countdown_tick.emit(remaining)
	if remaining <= 0:
		_do_restore()

func _do_restore() -> void:
	_timer.stop()
	_restore_at = 0
	SavePersist.clear_life_restore()
	lives_restored.emit()
