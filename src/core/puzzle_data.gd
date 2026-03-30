## PuzzleData
## Root data resource for a single LEXICON puzzle.
## Contains exactly 4 GroupData entries (16 total words, all unique).
## Serialized as a .tres file under data/puzzles/.
class_name PuzzleData
extends Resource

## Unique identifier for this puzzle. Used by PuzzleLibrary for lookups.
## Convention: "YYYY-MM-DD" for daily puzzles, "test_NNN" for dev puzzles.
@export var puzzle_id: String = ""

## Human-readable title displayed on the end screen.
@export var title: String = ""

## The four word groups. Must contain exactly 4 GroupData entries.
@export var groups: Array[GroupData] = []

## Default reveal config applied to any group that has reveal_config == null.
## Defaults to Medium pacing [1, 2, 2] per design/notes/letter-reveal-pacing.md.
@export var default_reveal_config: RevealConfig = null

## Validates structural integrity of this puzzle.
## Returns an array of error strings; empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []

	if puzzle_id.strip_edges().is_empty():
		errors.append("puzzle_id is empty")

	if groups.size() != 4:
		errors.append("Expected 4 groups, got %d" % groups.size())
		return errors  # Can't check further without 4 groups

	# Validate each group
	for i in range(groups.size()):
		var group: GroupData = groups[i]
		if group == null:
			errors.append("Group %d is null" % i)
			continue
		if not group.is_valid():
			errors.append("Group %d ('%s') failed is_valid()" % [i, group.category_name])

	# Check all 16 words are unique (case-insensitive)
	var seen: Dictionary = {}
	for group in groups:
		if group == null:
			continue
		for word in group.words:
			var key := word.to_upper().strip_edges()
			if seen.has(key):
				errors.append("Duplicate word: '%s'" % word)
			else:
				seen[key] = true

	return errors

## Returns the effective RevealConfig for a given group index.
## Falls back to default_reveal_config, then to a hardcoded Medium default.
func get_reveal_config_for_group(group_index: int) -> RevealConfig:
	if group_index >= 0 and group_index < groups.size():
		var group: GroupData = groups[group_index]
		if group != null and group.reveal_config != null:
			return group.reveal_config

	if default_reveal_config != null:
		return default_reveal_config

	# Hardcoded fallback — Medium [1, 2, 2]
	var fallback := RevealConfig.new()
	fallback.reveal_steps = [1, 2, 2]
	return fallback
