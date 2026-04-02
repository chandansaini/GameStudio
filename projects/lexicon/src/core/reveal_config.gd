## RevealConfig
## Data resource that defines letter reveal pacing for a puzzle group.
## Configures how many category letters are revealed at each confirmation step.
##
## Default [1, 2, 2] = reveal 1 letter on first confirm, then 2, then 2 (Medium).
## Easy   [2, 2, 3] — more letters visible per step
## Hard   [1, 1, 2] — fewer letters visible per step
## See: design/notes/letter-reveal-pacing.md
class_name RevealConfig
extends Resource

## Number of letters to reveal at each confirmation step.
## Array length determines how many confirmations before full reveal.
## Example: [1, 2, 2] → reveal 1, then 2, then 2 (total 5 of N letters).
@export var reveal_steps: Array[int] = [1, 2, 2]

## Order in which letters are revealed within each step.
## "left_to_right" is the only supported value for MVP.
@export_enum("left_to_right") var reveal_order: String = "left_to_right"

## Delay in seconds between each letter reveal within a single step.
## Matches letter_reveal_stagger_delay tuning knob in slot-ui GDD.
@export var stagger_delay: float = 0.15

## Returns total letters revealed after all steps complete.
func total_revealed() -> int:
	var total := 0
	for step in reveal_steps:
		total += step
	return total

## Returns cumulative revealed count after a given step index (0-based).
func revealed_after_step(step_index: int) -> int:
	var total := 0
	for i in range(min(step_index + 1, reveal_steps.size())):
		total += reveal_steps[i]
	return total
