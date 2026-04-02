## ResultsBuilder
## Tracks group solve order and wrong attempts, builds a shareable emoji results string.
## Format: one row per group (in solve order), showing 3 emoji for that group's colour.
## Unsolved groups appear at the end as ⬛⬛⬛.
##
## Example share text (solved, 2 wrong):
##   LEXICON — Daily Mix
##   ✅ Solved  ❌×2
##
##   🟩🟩🟩
##   🟦🟦🟦
##   🟨🟨🟨
##   🟪🟪🟪
class_name ResultsBuilder
extends Node

const GROUP_EMOJI := ["🟩", "🟦", "🟨", "🟪"]
const WRONG_EMOJI := "⬛"

## Slot indices in the order they were solved, e.g. [2, 0, 3, 1]
var _solve_order: Array[int] = []
var _total_wrong: int = 0

func _ready() -> void:
	GSM.puzzle_loaded.connect(_on_puzzle_loaded)
	GSM.group_solved.connect(_on_group_solved)
	GSM.word_placed_wrong.connect(_on_word_placed_wrong)

## Returns the full share text for the end screen.
func build_share_text(won: bool) -> String:
	if GSM.active_puzzle == null:
		return ""

	var result_line := "✅ Solved" if won else "❌ Failed"
	if _total_wrong > 0:
		result_line += "  ❌×%d" % _total_wrong

	var lines: Array[String] = []
	lines.append("LEXICON — %s" % GSM.active_puzzle.title)
	lines.append(result_line)
	lines.append("")

	# Solved groups in solve order
	for slot_index in _solve_order:
		lines.append(GROUP_EMOJI[slot_index].repeat(3))

	# Unsolved groups (failed game) shown as black
	for i in range(4):
		if not GSM.solved_slots[i]:
			lines.append(WRONG_EMOJI.repeat(3))

	return "\n".join(lines)

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _on_puzzle_loaded(_puzzle: PuzzleData) -> void:
	_solve_order.clear()
	_total_wrong = 0

func _on_group_solved(slot_index: int) -> void:
	_solve_order.append(slot_index)

func _on_word_placed_wrong(_word: String, _slot_index: int) -> void:
	_total_wrong += 1
