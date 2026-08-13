extends Node
## Autoload de audio do EcoCat. Todos os sons sao gerados por codigo
## (AudioStreamWAV), sem depender de arquivos externos — mantem o projeto
## autossuficiente e leve para a Web.

const MIX_RATE := 22050

var muted := false

var _sfx: Dictionary = {}
var _sfx_players: Array = []
var _sfx_index := 0
var _music_player: AudioStreamPlayer


func _ready() -> void:
	_sfx["pickup"] = _tone([660.0, 880.0], 0.10, 0.35)
	_sfx["correct"] = _tone([523.0, 784.0, 1046.0], 0.16, 0.4)
	_sfx["wrong"] = _tone([220.0, 175.0], 0.18, 0.35)
	_sfx["coin"] = _tone([988.0, 1319.0], 0.09, 0.3)
	_sfx["buy"] = _tone([440.0, 660.0, 880.0], 0.14, 0.35)
	_sfx["phase"] = _tone([523.0, 659.0, 784.0, 1046.0], 0.5, 0.4)

	for i in 6:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -16.0
	_music_player.stream = _build_music()
	add_child(_music_player)


func play(sfx_name: String) -> void:
	if muted or not _sfx.has(sfx_name):
		return
	var player: AudioStreamPlayer = _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stream = _sfx[sfx_name]
	player.play()


func start_music() -> void:
	if not muted and not _music_player.playing:
		_music_player.play()


func toggle_mute() -> bool:
	muted = not muted
	if muted:
		_music_player.stop()
		for p in _sfx_players:
			p.stop()
	else:
		_music_player.play()
	return muted


# --------------------------------------------------------------------------- #
# Geracao dos sons
# --------------------------------------------------------------------------- #

func _tone(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	# Uma sequencia curta de notas (arpejo) com envelope suave.
	var note_len := duration / float(freqs.size())
	var total := int(duration * MIX_RATE)
	var samples_per_note := int(note_len * MIX_RATE)
	var data := PackedByteArray()
	data.resize(total * 2)

	for i in total:
		var note := mini(i / maxi(1, samples_per_note), freqs.size() - 1)
		var freq: float = freqs[note]
		var local := float(i - note * samples_per_note) / float(maxi(1, samples_per_note))
		var env := sin(PI * clampf(local, 0.0, 1.0))  # ataque/decay suave
		var s := sin(TAU * freq * (float(i) / MIX_RATE)) * env * volume
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))

	return _make_wav(data, false, 0, total)


func _build_music() -> AudioStreamWAV:
	# Pad calmo em loop: progressao lenta de acordes com ondas suaves.
	var chords := [
		[261.63, 329.63, 392.0],   # C
		[293.66, 349.23, 440.0],   # Dm
		[349.23, 440.0, 523.25],   # F
		[392.0, 493.88, 587.33],   # G
	]
	var chord_dur := 2.0
	var chord_samples := int(chord_dur * MIX_RATE)
	var total := chord_samples * chords.size()
	var data := PackedByteArray()
	data.resize(total * 2)

	for i in total:
		var ci := (i / chord_samples) % chords.size()
		var chord: Array = chords[ci]
		var local := float(i % chord_samples) / float(chord_samples)
		var env := 0.5 - 0.5 * cos(TAU * local)  # fade in/out por acorde
		var t := float(i) / MIX_RATE
		var s := 0.0
		for f in chord:
			s += sin(TAU * float(f) * t)
		s = (s / float(chord.size())) * env * 0.5
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))

	return _make_wav(data, true, 0, total)


func _make_wav(data: PackedByteArray, loop: bool, loop_begin: int, loop_end: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = loop_begin
		stream.loop_end = loop_end
	stream.data = data
	return stream
