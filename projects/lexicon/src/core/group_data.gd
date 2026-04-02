## GroupData
## Data resource representing one word group (category) within a puzzle.
## Contains the category name, the member words, and reveal configuration.
## Stored as a sub-resource inside PuzzleData.
class_name GroupData
extends Resource

## Display name of the category shown in the slot panel header (all-caps recommended).
## Example: "SNAKES", "BOARD GAMES", "TYPES OF CLOUD"
@export var category_name: String = ""

## The four words belonging to this category.
## Must contain exactly 4 entries — validated by PuzzleData.validate().
@export var words: Array[String] = []

## One word from this group that is pre-revealed in the slot as a hint.
## Must be present in words[]. Used as the fallback anchor when no session
## anchor has been chosen yet (first play). Excluded from the word pool.
@export var anchor_word: String = ""

## Words in this group that should never be chosen as the session anchor hint.
## Mark the hardest/most distinctive words here so the reveal is always helpful.
## If all words are marked hard, the restriction is ignored and any word may be chosen.
@export var hard_words: Array[String] = []

## Reveal pacing config for this group's category name letters.
## If null, PuzzleLibrary will assign the puzzle-level default_reveal_config.
@export var reveal_config: RevealConfig = null

## Returns true if this group's data is structurally valid.
## Does not check word uniqueness across groups — that is PuzzleData's job.
func is_valid() -> bool:
	if category_name.strip_edges().is_empty():
		return false
	if words.size() != 4:
		return false
	for word in words:
		if word.strip_edges().is_empty():
			return false
	if anchor_word.strip_edges().is_empty():
		return false
	if anchor_word not in words:
		return false
	return true
