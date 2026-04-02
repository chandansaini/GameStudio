## Fonts autoload — central font references for all UI.
## Usage: Fonts.bold, Fonts.semibold, Fonts.regular, Fonts.mono_bold
extends Node

## Space Grotesk 700 — LEXICON title, SOLVED/FAILED headings
var bold: FontFile

## Space Grotesk 600 — word cards, anchor words, buttons, category names
var semibold: FontFile

## Space Grotesk 400 — body text, labels, placed words, hearts
var regular: FontFile

## IBM Plex Mono 700 — character reveal cells (monospaced stability)
var mono_bold: FontFile

func _ready() -> void:
	bold      = load("res://assets/fonts/SpaceGrotesk-Bold.ttf")
	semibold  = load("res://assets/fonts/SpaceGrotesk-SemiBold.ttf")
	regular   = load("res://assets/fonts/SpaceGrotesk-Regular.ttf")
	mono_bold = load("res://assets/fonts/IBMPlexMono-Bold.ttf")
