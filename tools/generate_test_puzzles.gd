## GenerateTestPuzzles
## EditorScript — run from Godot editor: right-click → Run.
## Creates 3 test .tres puzzles under data/puzzles/.
##
## Usage:
##   1. Open this file in the Godot script editor.
##   2. Right-click the script tab → "Run".
##   3. Check the FileSystem dock — data/puzzles/ will contain the .tres files.
@tool
extends EditorScript

func _run() -> void:
	print("GenerateTestPuzzles: Creating test puzzles...")

	_make_puzzle(
		"test_001",
		"Animals by Category",
		[
			["SNAKES",      ["COBRA", "MAMBA", "VIPER", "PYTHON"]],
			["MAMMALS",     ["WOLF", "BEAR", "DEER", "OTTER"]],
			["BIRDS",       ["ROBIN", "CRANE", "SWIFT", "FINCH"]],
			["FISH",        ["TROUT", "PERCH", "BREAM", "ROACH"]],
		]
	)

	_make_puzzle(
		"test_002",
		"Games Night",
		[
			["BOARD GAMES",   ["CHESS", "GO", "RISK", "CLUE"]],
			["CARD GAMES",    ["POKER", "SNAP", "RUMMY", "WAR"]],
			["DICE GAMES",    ["YAHTZEE", "CRAPS", "FARKLE", "BUNCO"]],
			["PARTY GAMES",   ["CHARADES", "TABOO", "CODENAMES", "PICTIONARY"]],
		]
	)

	_make_puzzle(
		"test_003",
		"Sky High",
		[
			["CLOUD TYPES",  ["CIRRUS", "NIMBUS", "STRATUS", "CUMULUS"]],
			["PLANETS",      ["MARS", "VENUS", "SATURN", "URANUS"]],
			["STARS",        ["SIRIUS", "VEGA", "RIGEL", "SPICA"]],
			["CONSTELLATIONS", ["ORION", "LYRA", "DRACO", "VELA"]],
		]
	)

	print("GenerateTestPuzzles: Done. Check data/puzzles/ in the FileSystem dock.")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Creates and saves one PuzzleData .tres file.
## groups_data: Array of [category_name: String, words: Array[String]]
func _make_puzzle(
	puzzle_id: String,
	title: String,
	groups_data: Array
) -> void:
	var puzzle := PuzzleData.new()
	puzzle.puzzle_id = puzzle_id
	puzzle.title = title

	# Default Medium reveal config shared by all groups in this puzzle
	var default_config := RevealConfig.new()
	default_config.reveal_steps = [1, 2, 2]
	default_config.reveal_order = "left_to_right"
	default_config.stagger_delay = 0.15
	puzzle.default_reveal_config = default_config

	for entry in groups_data:
		var group := GroupData.new()
		group.category_name = entry[0]
		group.words.assign(entry[1])
		# group.reveal_config left null → uses puzzle default
		puzzle.groups.append(group)

	var errors := puzzle.validate()
	if errors.size() > 0:
		push_error("GenerateTestPuzzles: Puzzle '%s' failed validation: %s" % [puzzle_id, errors])
		return

	var path := "res://data/puzzles/%s.tres" % puzzle_id
	var err := ResourceSaver.save(puzzle, path)
	if err != OK:
		push_error("GenerateTestPuzzles: Failed to save '%s' (error %d)" % [path, err])
	else:
		print("  Saved: %s" % path)
