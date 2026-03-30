## Integration test scene — runs a full automated puzzle flow and logs every event.
## Swap this back as main.gd content to run headless verification.
## Set project.godot main scene to game.tscn for normal play.
extends Node

var _life_system: LifeSystem
var _slot_assignment: SlotAssignment
var _reveal_system: LetterRevealSystem
var _results_builder: ResultsBuilder

func _ready() -> void:
	print("=== LEXICON Full Integration Test ===")
	await get_tree().process_frame

	_life_system = LifeSystem.new()
	_slot_assignment = SlotAssignment.new()
	_reveal_system = LetterRevealSystem.new()
	_results_builder = ResultsBuilder.new()
	add_child(_life_system)
	add_child(_slot_assignment)
	add_child(_reveal_system)
	add_child(_results_builder)

	# --- Wire all signal logging ---
	GSM.puzzle_loaded.connect(func(p): print("[GSM] puzzle_loaded: id=%s title='%s'" % [p.puzzle_id, p.title]))
	GSM.word_selected.connect(func(w): print("[GSM] word_selected: '%s'" % w))
	GSM.word_deselected.connect(func(w): print("[GSM] word_deselected: '%s'" % w))
	GSM.word_placed_correct.connect(func(w,s): print("[GSM] word_placed_correct: '%s' → slot %d | placed=%s" % [w, s, GSM.placed_words[s]]))
	GSM.word_placed_wrong.connect(func(w,s): print("[GSM] word_placed_wrong: '%s' → slot %d | lives=%d" % [w, s, GSM.lives]))
	GSM.group_solved.connect(func(s): print("[GSM] group_solved: slot %d | category='%s'" % [s, GSM.active_puzzle.groups[s].category_name]))
	GSM.lives_changed.connect(func(l): print("[GSM] lives_changed: %d" % l))
	GSM.puzzle_solved.connect(func(): print("[GSM] puzzle_solved!"))
	GSM.puzzle_failed.connect(func(): print("[GSM] puzzle_failed!"))

	_slot_assignment.state_changed.connect(func(s): print("[SlotAssignment] state → %s" % SlotAssignment.State.keys()[s]))
	_slot_assignment.placement_correct.connect(func(w,s): print("[SlotAssignment] placement_correct: '%s' → slot %d" % [w, s]))
	_slot_assignment.placement_wrong.connect(func(w,s): print("[SlotAssignment] placement_wrong: '%s' → slot %d" % [w, s]))
	_slot_assignment.slot_solved.connect(func(s): print("[SlotAssignment] slot_solved: slot %d" % s))

	_life_system.life_lost.connect(func(l): print("[LifeSystem] life_lost: %d remaining" % l))
	_life_system.lives_restore_eligible.connect(func(): print("[LifeSystem] lives_restore_eligible"))

	_reveal_system.letters_revealed.connect(func(s,i,d):
		var cat: String = GSM.active_puzzle.groups[s].category_name
		var visible := ""
		for c in range(cat.length()):
			visible += cat[c] if c in _reveal_system.get_revealed_indices(s) else "_"
		print("[RevealSystem] slot %d revealed %s → '%s' done=%s" % [s, i, visible, d])
	)
	_reveal_system.slot_fully_revealed.connect(func(s): print("[RevealSystem] slot %d FULLY REVEALED: '%s'" % [s, GSM.active_puzzle.groups[s].category_name]))

	# --- Load puzzle ---
	print("\n--- Loading test_001 ---")
	GSM.load_puzzle(PuzzleLibrary.get_puzzle("test_001"))
	print("Pool (%d words): %s" % [GSM.pool_words.size(), GSM.pool_words])
	print("Placed at load: slot0=%s slot1=%s slot2=%s slot3=%s" % [
		GSM.placed_words[0], GSM.placed_words[1], GSM.placed_words[2], GSM.placed_words[3]])

	# --- Test 1: correct placement (slot 0 = SNAKES) ---
	print("\n--- Test 1: Place MAMBA into SNAKES slot (correct) ---")
	_slot_assignment.on_word_pressed("MAMBA")
	_slot_assignment.on_slot_pressed(0)

	# --- Test 2: wrong placement ---
	print("\n--- Test 2: Place BEAR into SNAKES slot (wrong) ---")
	_slot_assignment.on_word_pressed("BEAR")
	_slot_assignment.on_slot_pressed(0)

	# --- Test 3: deselect ---
	print("\n--- Test 3: Select then deselect VIPER ---")
	_slot_assignment.on_word_pressed("VIPER")
	_slot_assignment.on_word_pressed("VIPER")

	# --- Test 4: solve all of slot 0 (SNAKES) ---
	print("\n--- Test 4: Solve slot 0 (SNAKES) — place VIPER + PYTHON ---")
	_slot_assignment.on_word_pressed("VIPER")
	_slot_assignment.on_slot_pressed(0)
	_slot_assignment.on_word_pressed("PYTHON")
	_slot_assignment.on_slot_pressed(0)
	print("solved_slots=%s placed_words[0]=%s" % [GSM.solved_slots, GSM.placed_words[0]])

	# --- Test 5: exhaust lives ---
	# BEAR belongs to MAMMALS (slot 1), so placing into BIRDS (slot 2) is wrong
	print("\n--- Test 5: Exhaust lives (3 wrong placements into slot 2/BIRDS) ---")
	for _i in range(3):
		_slot_assignment.on_word_pressed("BEAR")
		_slot_assignment.on_slot_pressed(2)
	print("lives=%d solved=%s" % [GSM.lives, GSM.solved_slots])

	# --- Test 6: attempt play after puzzle_failed (should be no-op) ---
	print("\n--- Test 6: Attempt play after game over (expect no-op) ---")
	_slot_assignment.on_word_pressed("BEAR")
	print("selected after fail: '%s' (expect empty)" % GSM.selected_word)

	print("\n--- Results card ---")
	print(_results_builder.build_share_text(false))
	print("\n=== Integration Test Done ===")
