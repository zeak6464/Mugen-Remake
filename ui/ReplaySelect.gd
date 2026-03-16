extends Control

## Lists saved replays in user://replays/ and launches the arena to watch one (characters and stage from replay).

const REPLAYS_DIR: String = "user://replays/"
const REPLAY_EXT: String = ".json"

@export var arena_scene_path: String = "res://stages/TestArena.tscn"
@export var main_menu_path: String = "res://ui/MainMenu.tscn"

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var replay_list: ItemList = $MarginContainer/VBoxContainer/ReplayListPanel/ReplayList
@onready var play_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/PlayButton
@onready var delete_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/DeleteButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/BackButton
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel

func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	UISkin.apply_background(self, "options_menu_bg")
	title_label.text = "Watch Replay"
	play_button.pressed.connect(_on_play_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	back_button.pressed.connect(_on_back_pressed)
	replay_list.item_selected.connect(_on_item_selected)
	_scan_replays()
	_update_status()


func _scan_replays() -> void:
	replay_list.clear()
	var dir := DirAccess.open(REPLAYS_DIR)
	if dir == null:
		dir = DirAccess.open("user://")
		if dir != null:
			dir.make_dir_recursive("replays")
			dir = DirAccess.open(REPLAYS_DIR)
	if dir == null:
		status_label.text = "No replays folder."
		return
	var names: Array[String] = []
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(REPLAY_EXT):
			names.append("%s%s" % [REPLAYS_DIR, name])
		name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	names.reverse()
	for path in names:
		var display: String = _format_replay_name(path.get_file())
		var i: int = replay_list.item_count
		replay_list.add_item(display)
		replay_list.set_item_metadata(i, path)
	if replay_list.item_count == 0:
		status_label.text = "No saved replays. Enable \"Save Replay\" in Match Options and play a 2P round to save one."


func _format_replay_name(filename: String) -> String:
	var base := filename.get_basename()
	if base.begins_with("replay_"):
		var rest := base.substr(7)
		var parts := rest.split("_")
		if parts.size() >= 2 and parts[0].length() == 8 and parts[1].length() == 6:
			var date_part: String = parts[0]
			var time_part: String = parts[1]
			return "%s-%s-%s %s:%s:%s" % [
				date_part.substr(0, 4), date_part.substr(4, 2), date_part.substr(6, 2),
				time_part.substr(0, 2), time_part.substr(2, 2), time_part.substr(4, 2)
			]
	return base


func _on_item_selected(_index: int) -> void:
	_update_status()


func _update_status() -> void:
	var idx := replay_list.get_selected_items()
	if idx.is_empty():
		status_label.text = "Select a replay and press Play."
		return
	status_label.text = "Selected: %s" % replay_list.get_item_text(idx[0])


func _on_play_pressed() -> void:
	var idx := replay_list.get_selected_items()
	if idx.is_empty():
		status_label.text = "Select a replay first."
		return
	var path: Variant = replay_list.get_item_metadata(idx[0])
	if path == null or str(path).is_empty():
		status_label.text = "Invalid replay."
		return
	var path_str: String = str(path)
	var file := FileAccess.open(path_str, FileAccess.READ)
	if file == null:
		status_label.text = "Could not open replay file."
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null:
		status_label.text = "Invalid replay file."
		return
	var tree := get_tree()
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("meta"):
		var meta_dict: Dictionary = parsed.get("meta", {})
		for key in meta_dict.keys():
			tree.set_meta(str(key), meta_dict[key])
	tree.set_meta("replay_path", path_str)
	tree.set_meta("replay_mode", true)
	if not tree.get_meta("game_mode", ""):
		tree.set_meta("game_mode", "training")
	tree.change_scene_to_file(arena_scene_path)


func _on_delete_pressed() -> void:
	var idx := replay_list.get_selected_items()
	if idx.is_empty():
		status_label.text = "Select a replay to delete."
		return
	var path: Variant = replay_list.get_item_metadata(idx[0])
	if path == null or str(path).is_empty():
		status_label.text = "Invalid replay."
		return
	var path_str: String = str(path)
	var dir := DirAccess.open(REPLAYS_DIR)
	if dir == null:
		status_label.text = "Could not open replays folder."
		return
	var err: Error = dir.remove(path_str.get_file())
	if err != OK:
		status_label.text = "Could not delete file."
		return
	SystemSFX.play_ui_from(self, "ui_back")
	_scan_replays()
	_update_status()
	status_label.text = "Replay deleted."


func _on_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	get_tree().change_scene_to_file(main_menu_path)
