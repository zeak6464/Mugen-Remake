extends Node
class_name SystemSFX

const ROOT_NODE_NAME: String = "SystemSFX"
const SAMPLE_RATE: int = 44100

const UI_TONES: Dictionary = {
	"ui_move": {"freq": 540.0, "duration": 0.035, "volume_db": -22.0},
	"ui_confirm": {"freq": 780.0, "duration": 0.070, "volume_db": -16.0},
	"ui_back": {"freq": 420.0, "duration": 0.065, "volume_db": -18.0}
}

const BATTLE_TONES: Dictionary = {
	"battle_hit": {"freq": 230.0, "duration": 0.055, "volume_db": -11.0},
	"battle_block": {"freq": 170.0, "duration": 0.080, "volume_db": -10.0},
	"battle_parry": {"freq": 980.0, "duration": 0.090, "volume_db": -9.0},
	"battle_throw": {"freq": 150.0, "duration": 0.120, "volume_db": -9.0},
	"battle_ko": {"freq": 110.0, "duration": 0.240, "volume_db": -6.0},
	"round_ready": {"freq": 620.0, "duration": 0.070, "volume_db": -14.0},
	"round_fight": {"freq": 840.0, "duration": 0.100, "volume_db": -12.0},
	"round_win": {"freq": 700.0, "duration": 0.140, "volume_db": -12.0},
	"round_match": {"freq": 520.0, "duration": 0.220, "volume_db": -10.0},
	"time_up": {"freq": 300.0, "duration": 0.180, "volume_db": -11.0}
}

const EVENT_SOUND_PATHS: Dictionary = {
	"ui_move": [
		"res://sounds/System/select.wav"
	],
	"ui_confirm": [
		"res://sounds/System/select.wav"
	],
	"ui_back": [
		"res://sounds/System/close.wav",
		"res://sounds/System/closescreen.wav"
	],
	"round_ready": [
		"res://sounds/Announcer/Ready.wav"
	],
	"round_fight": [
		"res://sounds/Announcer/Fight.wav"
	],
	"round_win": [
		"res://sounds/Announcer/Winner.wav"
	],
	"round_match": [
		"res://sounds/Announcer/End.wav"
	],
	"time_up": [
		"res://sounds/Announcer/Draw.wav"
	]
}

const MENU_MUSIC_PATHS: Dictionary = {
	"titlescreen": ["res://sounds/Menu/titlescreen.mp3"],
	"mainmenu": ["res://sounds/Menu/mainmenu.mp3"],
	"charactersel": ["res://sounds/Menu/charactersel.mp3"],
	"mapsel": ["res://sounds/Menu/mapsel.mp3"]
}

var ui_player: AudioStreamPlayer = null
var battle_player: AudioStreamPlayer = null
var music_player: AudioStreamPlayer = null
var stream_cache: Dictionary = {}


static func _get_instance(context: Node) -> SystemSFX:
	if context == null:
		return null
	var tree := context.get_tree()
	if tree == null:
		return null
	var root := tree.root
	if root == null:
		return null
	var existing := root.get_node_or_null(ROOT_NODE_NAME)
	if existing != null and existing is SystemSFX:
		return existing as SystemSFX
	var created := SystemSFX.new()
	created.name = ROOT_NODE_NAME
	root.call_deferred("add_child", created)
	return created


static func play_ui_from(context: Node, event_id: String) -> void:
	var instance := _get_instance(context)
	if instance == null:
		return
	if not instance.is_inside_tree():
		instance.call_deferred("_play_ui", event_id)
		return
	instance._play_ui(event_id)


static func play_battle_from(context: Node, event_id: String) -> void:
	var instance := _get_instance(context)
	if instance == null:
		return
	if not instance.is_inside_tree():
		instance.call_deferred("_play_battle", event_id)
		return
	instance._play_battle(event_id)


static func play_menu_music_from(context: Node, track_id: String, loop: bool = true, volume_db: float = -8.0) -> void:
	var instance := _get_instance(context)
	if instance == null:
		return
	if not instance.is_inside_tree():
		instance.call_deferred("_play_menu_music", track_id, loop, volume_db)
		return
	instance._play_menu_music(track_id, loop, volume_db)


static func stop_menu_music_from(context: Node) -> void:
	var instance := _get_instance(context)
	if instance == null:
		return
	if not instance.is_inside_tree():
		instance.call_deferred("_stop_menu_music")
		return
	instance._stop_menu_music()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UISkin.ensure_skin_dirs()
	_ensure_players()


func _ensure_players() -> void:
	if ui_player == null:
		ui_player = AudioStreamPlayer.new()
		ui_player.name = "UIPlayer"
		ui_player.bus = "Master"
		add_child(ui_player)
	if battle_player == null:
		battle_player = AudioStreamPlayer.new()
		battle_player.name = "BattlePlayer"
		battle_player.bus = "Master"
		add_child(battle_player)
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		music_player.name = "MusicPlayer"
		music_player.bus = "Master"
		add_child(music_player)


func _play_ui(event_id: String) -> void:
	_play_event(ui_player, UI_TONES, "ui", event_id)


func _play_battle(event_id: String) -> void:
	_play_event(battle_player, BATTLE_TONES, "battle", event_id)


func _play_event(player: AudioStreamPlayer, tone_map: Dictionary, category: String, event_id: String) -> void:
	if player == null or event_id.is_empty():
		return
	var tone_data: Dictionary = tone_map.get(event_id, {})
	var volume_db: float = float(tone_data.get("volume_db", -14.0))
	var custom_stream = UISkin.get_audio_stream(category, event_id)
	if custom_stream != null and custom_stream is AudioStream:
		player.stream = custom_stream
		player.volume_db = volume_db
		player.pitch_scale = 1.0
		player.play()
		return
	var explicit_stream: AudioStream = _load_event_stream(event_id)
	if explicit_stream != null:
		player.stream = explicit_stream
		player.volume_db = volume_db
		player.pitch_scale = 1.0
		player.play()
		return
	_play_tone_from_map(player, tone_map, event_id)


func _play_tone_from_map(player: AudioStreamPlayer, tone_map: Dictionary, event_id: String) -> void:
	if player == null or event_id.is_empty():
		return
	var tone_data: Dictionary = tone_map.get(event_id, {})
	if tone_data.is_empty():
		return
	var freq: float = float(tone_data.get("freq", 440.0))
	var duration: float = float(tone_data.get("duration", 0.06))
	var volume_db: float = float(tone_data.get("volume_db", -14.0))
	var cache_key: String = "%s_%s" % [str(freq), str(duration)]
	var stream: AudioStreamWAV = stream_cache.get(cache_key, null)
	if stream == null:
		stream = _build_tone_stream(freq, duration)
		if stream == null:
			return
		stream_cache[cache_key] = stream
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0
	player.play()


func _build_tone_stream(freq: float, duration: float) -> AudioStreamWAV:
	var sample_count: int = maxi(1, int(SAMPLE_RATE * maxf(0.01, duration)))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0 - (float(i) / float(sample_count))
		var sample_f: float = sin(2.0 * PI * freq * t) * env
		var sample_i: int = int(clampi(int(sample_f * 30000.0), -32768, 32767))
		var packed: int = sample_i & 0xFFFF
		data[i * 2] = packed & 0xFF
		data[i * 2 + 1] = (packed >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream


func _load_event_stream(event_id: String) -> AudioStream:
	if event_id.is_empty():
		return null
	var candidates: Array = EVENT_SOUND_PATHS.get(event_id, [])
	for candidate in candidates:
		var path: String = str(candidate)
		if path.is_empty():
			continue
		var stream: AudioStream = _load_stream(path)
		if stream != null:
			return stream
	return null


func _play_menu_music(track_id: String, loop: bool, volume_db: float) -> void:
	if music_player == null or track_id.is_empty():
		return
	var stream: AudioStream = _load_menu_music_stream(track_id)
	if stream == null:
		return
	_apply_stream_loop(stream, loop)
	music_player.stream = stream
	music_player.volume_db = volume_db
	if not music_player.playing:
		music_player.play()
	else:
		# Restart from beginning when switching tracks.
		music_player.play(0.0)


func _stop_menu_music() -> void:
	if music_player == null:
		return
	music_player.stop()
	music_player.stream = null


func _load_menu_music_stream(track_id: String) -> AudioStream:
	var candidates: Array = MENU_MUSIC_PATHS.get(track_id, [])
	for candidate in candidates:
		var path: String = str(candidate)
		if path.is_empty():
			continue
		var stream: AudioStream = _load_stream(path)
		if stream != null:
			return stream
	return null


func _load_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	var resolved_path: String = path
	if not ResourceLoader.exists(resolved_path):
		var imported_path: String = _resolve_imported_resource_path(path)
		if imported_path.is_empty():
			return null
		resolved_path = imported_path
	if not ResourceLoader.exists(resolved_path):
		return null
	var loaded = ResourceLoader.load(resolved_path)
	if loaded is AudioStream:
		return loaded as AudioStream
	return null


func _apply_stream_loop(stream: AudioStream, loop_enabled: bool) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop_enabled
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop_enabled
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if loop_enabled else AudioStreamWAV.LOOP_DISABLED


func _resolve_imported_resource_path(source_path: String) -> String:
	if source_path.is_empty():
		return ""
	var import_path: String = "%s.import" % source_path
	if not FileAccess.file_exists(import_path):
		return ""
	var cfg := ConfigFile.new()
	if cfg.load(import_path) != OK:
		return ""
	return str(cfg.get_value("remap", "path", "")).strip_edges()
