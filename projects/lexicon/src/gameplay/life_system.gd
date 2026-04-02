## LifeSystem
## Stateless event-driven node. Sits in the game scene tree.
## Listens to GSM signals → calls GSM.deduct_life() → emits own signals
## for LifeIndicatorUI to consume.
##
## Add as a child node in the game scene. No configuration needed.
class_name LifeSystem
extends Node

## Emitted after GSM.deduct_life() is called, with the new remaining count.
signal life_lost(lives_remaining: int)

## Emitted when lives drop to 1 — UI may show a restore prompt (future feature).
signal lives_restore_eligible

func _ready() -> void:
	GSM.word_placed_wrong.connect(_on_word_placed_wrong)

func _on_word_placed_wrong(_word: String, _slot_index: int) -> void:
	GSM.deduct_life()
	life_lost.emit(GSM.lives)
	if GSM.lives == 1:
		lives_restore_eligible.emit()
	elif GSM.lives == 0:
		GSM.trigger_fail()
