## AudioSystem
## Autoload singleton. Plays procedurally-generated tones for game events.
## No external audio files required — all sounds are synthesised from PCM data.
##
## Register as Autoload in Project → Project Settings → Autoload:
##   Name: AudioSys
##   Path: res://src/core/audio_system.gd
extends Node

const SAMPLE_RATE := 22050

# Pre-built streams, created once in _ready()
var _sfx_click: AudioStreamWAV
var _sfx_correct: AudioStreamWAV
var _sfx_wrong: AudioStreamWAV
var _sfx_group_solved: AudioStreamWAV
var _sfx_puzzle_solved: AudioStreamWAV
var _sfx_puzzle_failed: AudioStreamWAV
var _sfx_reveal: AudioStreamWAV

# Pooled players — avoids allocation on hot paths
var _players: Array[AudioStreamPlayer] = []
const PLAYER_POOL_SIZE := 6

func _ready() -> void:
	_build_streams()
	_build_player_pool()
	_connect_to_gsm()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Play a word-selected click sound.
func play_click() -> void:
	_play(_sfx_click)

## Play a correct-placement confirmation tone.
func play_correct() -> void:
	_play(_sfx_correct)

## Play a wrong-placement buzz.
func play_wrong() -> void:
	_play(_sfx_wrong)

## Play a group-solved chime.
func play_group_solved() -> void:
	_play(_sfx_group_solved)

## Play the puzzle-solved fanfare.
func play_puzzle_solved() -> void:
	_play(_sfx_puzzle_solved)

## Play the puzzle-failed tone.
func play_puzzle_failed() -> void:
	_play(_sfx_puzzle_failed)

## Play a letter-reveal tick.
func play_reveal() -> void:
	_play(_sfx_reveal)

# ---------------------------------------------------------------------------
# GSM signal connections
# ---------------------------------------------------------------------------

func _connect_to_gsm() -> void:
	GSM.word_selected.connect(func(_w): play_click())
	GSM.word_placed_correct.connect(func(_w, _s): play_correct())
	GSM.word_placed_wrong.connect(func(_w, _s): play_wrong())
	GSM.group_solved.connect(func(_s): play_group_solved())
	GSM.puzzle_solved.connect(play_puzzle_solved)
	GSM.puzzle_failed.connect(play_puzzle_failed)

# ---------------------------------------------------------------------------
# Playback
# ---------------------------------------------------------------------------

func _play(stream: AudioStreamWAV) -> void:
	var player := _get_free_player()
	if player == null:
		return
	player.stream = stream
	player.play()

func _get_free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return null  # All players busy — drop the sound

# ---------------------------------------------------------------------------
# Stream construction
# ---------------------------------------------------------------------------

func _build_streams() -> void:
	# Short click: 880 Hz, 60 ms, soft
	_sfx_click = _make_tone(880.0, 0.06, 0.3)
	# Correct placement: 660 Hz, 120 ms, medium
	_sfx_correct = _make_tone(660.0, 0.12, 0.45)
	# Wrong placement: 200 Hz, 200 ms, descending envelope
	_sfx_wrong = _make_descending_tone(200.0, 0.20, 0.5)
	# Group solved: two-tone chime (523 + 784 Hz)
	_sfx_group_solved = _make_chord([523.25, 783.99], 0.30, 0.4)
	# Puzzle solved: ascending three-tone fanfare
	_sfx_puzzle_solved = _make_chord([523.25, 659.25, 783.99], 0.50, 0.45)
	# Puzzle failed: low descending tone
	_sfx_puzzle_failed = _make_descending_tone(150.0, 0.40, 0.5)
	# Letter reveal tick: very short high tick
	_sfx_reveal = _make_tone(1200.0, 0.03, 0.2)

func _build_player_pool() -> void:
	for i in range(PLAYER_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)

# ---------------------------------------------------------------------------
# PCM tone generators
# ---------------------------------------------------------------------------

## Generates a sine wave tone with a linear fade-out envelope.
## frequency: Hz | duration: seconds | volume: 0.0–1.0
func _make_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit mono

	var fade_start := int(sample_count * 0.75)
	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var envelope := 1.0
		if i >= fade_start:
			envelope = 1.0 - float(i - fade_start) / float(sample_count - fade_start)
		var sample := int(sin(TAU * frequency * t) * 32767.0 * volume * envelope)
		data.encode_s16(i * 2, clampi(sample, -32768, 32767))

	return _build_wav(data)

## Generates a descending-pitch tone (frequency drops to half over duration).
func _make_descending_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0

	for i in range(sample_count):
		var progress := float(i) / float(sample_count)
		var freq := frequency * (1.0 - progress * 0.5)  # Drops to 50% over duration
		var envelope := 1.0 - progress * 0.8
		phase += TAU * freq / SAMPLE_RATE
		var sample := int(sin(phase) * 32767.0 * volume * envelope)
		data.encode_s16(i * 2, clampi(sample, -32768, 32767))

	return _build_wav(data)

## Generates a chord by summing multiple sine waves.
func _make_chord(frequencies: Array, duration: float, volume: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var per_voice := volume / frequencies.size()
	var fade_start := int(sample_count * 0.7)

	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var envelope := 1.0
		if i >= fade_start:
			envelope = 1.0 - float(i - fade_start) / float(sample_count - fade_start)
		var sum := 0.0
		for freq in frequencies:
			sum += sin(TAU * float(freq) * t)
		var sample := int(sum * 32767.0 * per_voice * envelope)
		data.encode_s16(i * 2, clampi(sample, -32768, 32767))

	return _build_wav(data)

func _build_wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream
