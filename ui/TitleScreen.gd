extends Control

@export var main_menu_scene_path: String = "res://ui/MainMenu.tscn"
@export var prompt_flash_min_alpha: float = 0.35
@export var prompt_flash_duration: float = 0.6
@export var background_video_paths: Array[String] = [
	"user://ui-skin/videos/titlescreen.ogv",
	"user://videos/titlescreen.ogv",
	"res://videos/titlescreen.ogv"
]

@onready var prompt_label: Label = $CenterContainer/VBoxContainer/PromptLabel

var transitioned: bool = false
var background_video_player: VideoStreamPlayer = null


func _ready() -> void:
	_ensure_ui_fits_screen()
	var has_video: bool = _setup_looping_background_video(background_video_paths)
	if not has_video:
		_apply_title_background_fallback()
	_start_prompt_flash()
	SystemSFX.play_menu_music_from(self, "titlescreen", true, -8.0)


func _start_prompt_flash() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(prompt_label, "modulate:a", prompt_flash_min_alpha, prompt_flash_duration)
	tween.tween_property(prompt_label, "modulate:a", 1.0, prompt_flash_duration)


func _unhandled_input(event: InputEvent) -> void:
	if transitioned:
		return
	if _is_start_input(event):
		transitioned = true
		SystemSFX.play_ui_from(self, "ui_confirm")
		get_tree().change_scene_to_file(main_menu_scene_path)


func _is_start_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if event.is_action_pressed("ui_accept"):
		return true
	if InputMap.has_action(&"p1_p") and event.is_action_pressed(&"p1_p"):
		return true
	if InputMap.has_action(&"p2_p") and event.is_action_pressed(&"p2_p"):
		return true
	return false


func _setup_looping_background_video(paths: Array[String]) -> bool:
	var stream: VideoStream = _load_first_video_stream(paths)
	if stream == null:
		return false
	background_video_player = VideoStreamPlayer.new()
	background_video_player.name = "BackgroundVideo"
	background_video_player.anchor_left = 0.0
	background_video_player.anchor_top = 0.0
	background_video_player.anchor_right = 1.0
	background_video_player.anchor_bottom = 1.0
	background_video_player.offset_left = 0.0
	background_video_player.offset_top = 0.0
	background_video_player.offset_right = 0.0
	background_video_player.offset_bottom = 0.0
	background_video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_video_player.expand = true
	background_video_player.stream = stream
	background_video_player.autoplay = true
	add_child(background_video_player)
	move_child(background_video_player, 0)
	if stream is VideoStreamTheora:
		(stream as VideoStreamTheora).loop = true
	background_video_player.play()
	return true


func _load_first_video_stream(paths: Array[String]) -> VideoStream:
	for path_value in paths:
		var path: String = str(path_value).strip_edges()
		if path.is_empty():
			continue
		var stream: VideoStream = _load_video_stream(path)
		if stream != null:
			return stream
	return null


func _load_video_stream(path: String) -> VideoStream:
	var resolved_path: String = path
	if not ResourceLoader.exists(resolved_path):
		var remap_path: String = _resolve_imported_resource_path(path)
		if remap_path.is_empty():
			return null
		resolved_path = remap_path
	if not ResourceLoader.exists(resolved_path):
		return null
	var loaded = ResourceLoader.load(resolved_path)
	if loaded is VideoStream:
		return loaded as VideoStream
	return null


func _resolve_imported_resource_path(source_path: String) -> String:
	var import_path: String = "%s.import" % source_path
	if not FileAccess.file_exists(import_path):
		return ""
	var cfg := ConfigFile.new()
	if cfg.load(import_path) != OK:
		return ""
	return str(cfg.get_value("remap", "path", "")).strip_edges()


func _ensure_ui_fits_screen() -> void:
	var width: int = int(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
	var height: int = int(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
	var window := get_window()
	if window != null:
		window.min_size = Vector2i(maxi(1, width), maxi(1, height))


func _apply_title_background_fallback() -> void:
	var bg := get_node_or_null("BackgroundColor") as ColorRect
	if bg != null:
		bg.visible = true
