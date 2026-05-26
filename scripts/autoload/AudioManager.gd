extends Node
## Autoload de audio: SFX con variación de pitch y música con crossfade.

const SFX_PATH := "res://sfx/"
const MUSIC_PATH := "res://music/"

const SFX_POOL_SIZE := 8

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_active: AudioStreamPlayer
var _music_fade_tween: Tween = null
var _current_music_name: String = ""

var _stream_cache: Dictionary = {}
var _fallback_music_tones: Dictionary = {
	"room_explore": {"freq": 98.0, "dur": 3.5},
	"room_battle": {"freq": 140.0, "dur": 3.5},
}

var _fallback_tones: Dictionary = {
	"hit": {"freq": 320.0, "dur": 0.08},
	"land": {"freq": 120.0, "dur": 0.06},
	"hurt": {"freq": 180.0, "dur": 0.12},
	"jump": {"freq": 440.0, "dur": 0.07},
	"heal": {"freq": 520.0, "dur": 0.14},
	"collect": {"freq": 660.0, "dur": 0.1},
	"death": {"freq": 90.0, "dur": 0.2},
	"ui": {"freq": 400.0, "dur": 0.05},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)

	_music_a = _make_music_player()
	_music_b = _make_music_player()
	_music_active = _music_a


func reproduce_sfx(nombre: String, pitch_variation: float = 0.1) -> void:
	var stream := _load_stream(SFX_PATH, nombre, true)
	if stream == null:
		return

	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


func reproduce_musica(nombre: String, crossfade: float = 1.0) -> void:
	if nombre == _current_music_name and _music_active.playing:
		return

	var stream := _load_stream(MUSIC_PATH, nombre, false)
	if stream == null:
		return

	_current_music_name = nombre
	var incoming := _music_b if _music_active == _music_a else _music_a
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	if _music_fade_tween != null and _music_fade_tween.is_valid():
		_music_fade_tween.kill()

	_music_fade_tween = create_tween().set_parallel(true)
	_music_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if crossfade > 0.0 and _music_active.playing:
		_music_fade_tween.tween_property(_music_active, "volume_db", -80.0, crossfade)
		_music_fade_tween.tween_property(incoming, "volume_db", 0.0, crossfade)
	else:
		_music_active.volume_db = -80.0
		_music_active.stop()
		incoming.volume_db = 0.0

	_music_fade_tween.finished.connect(func() -> void:
		if _music_active != incoming and _music_active.playing:
			_music_active.stop()
		_music_active = incoming,
		CONNECT_ONE_SHOT,
	)


func stop_music(fade: float = 0.5) -> void:
	_current_music_name = ""
	if _music_fade_tween != null and _music_fade_tween.is_valid():
		_music_fade_tween.kill()
	if fade <= 0.0:
		_music_a.stop()
		_music_b.stop()
		return
	_music_fade_tween = create_tween().set_parallel(true)
	_music_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_fade_tween.tween_property(_music_a, "volume_db", -80.0, fade)
	_music_fade_tween.tween_property(_music_b, "volume_db", -80.0, fade)
	_music_fade_tween.finished.connect(func() -> void:
		_music_a.stop()
		_music_b.stop(),
		CONNECT_ONE_SHOT,
	)


func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index(&"Music") == -1:
		AudioServer.add_bus()
		var music_idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_idx, &"Music")
		AudioServer.set_bus_send(music_idx, &"Master")
	if AudioServer.get_bus_index(&"SFX") == -1:
		AudioServer.add_bus()
		var sfx_idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_idx, &"SFX")
		AudioServer.set_bus_send(sfx_idx, &"Master")


func _make_music_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = &"Music"
	player.volume_db = 0.0
	add_child(player)
	return player


func _load_stream(base_path: String, nombre: String, is_sfx: bool) -> AudioStream:
	var cache_key := "%s:%s" % [base_path, nombre]
	if _stream_cache.has(cache_key):
		return _stream_cache[cache_key] as AudioStream

	for extension: String in [".ogg", ".wav", ".mp3"]:
		var resource_path: String = base_path + nombre + extension
		if ResourceLoader.exists(resource_path):
			var loaded: AudioStream = load(resource_path) as AudioStream
			_stream_cache[cache_key] = loaded
			return loaded

	if is_sfx and _fallback_tones.has(nombre):
		var tone: Dictionary = _fallback_tones[nombre]
		var generated := _generate_tone(tone["freq"], tone["dur"])
		_stream_cache[cache_key] = generated
		return generated

	if not is_sfx and _fallback_music_tones.has(nombre):
		var music_tone: Dictionary = _fallback_music_tones[nombre]
		var music_stream := _generate_tone(music_tone["freq"], music_tone["dur"])
		music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_stream_cache[cache_key] = music_stream
		return music_stream

	push_warning("AudioManager: no se encontró '%s' en %s" % [nombre, base_path])
	return null


func _generate_tone(freq: float, duration: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t := float(i) / mix_rate
		var envelope := 1.0 - (t / duration)
		var sample := int(clamp(sin(t * freq * TAU) * 2800.0 * envelope, -32768.0, 32767.0))
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = mix_rate
	stream.data = data
	return stream
