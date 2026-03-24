extends Control

@export var mods_roots: Array[String] = ["user://mods/", "res://mods/"]
@export var default_mod_name: String = "sample_fighter"

@onready var mod_option: OptionButton = $MarginContainer/VBoxContainer/TopRow/ModOption
@onready var file_option: OptionButton = $MarginContainer/VBoxContainer/TopRow/FileOption
@onready var reload_button: Button = $MarginContainer/VBoxContainer/TopRow/ReloadButton
@onready var format_json_button: Button = $MarginContainer/VBoxContainer/TopRow/FormatJsonButton
@onready var editor: TextEdit = $MarginContainer/VBoxContainer/EditorPanel/Editor
@onready var save_button: Button = $MarginContainer/VBoxContainer/BottomRow/SaveButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/BottomRow/BackButton
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel

var mod_entries: Array[Dictionary] = []
var current_mod_path: String = ""
var current_file_path: String = ""
var embedded_mode: bool = false


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	UISkin.attach_focus_arrow(self)
	_connect_signals()
	_scan_mods()
	_select_default_mod()
	_apply_embedded_mode()


func _connect_signals() -> void:
	mod_option.item_selected.connect(_on_mod_selected)
	file_option.item_selected.connect(_on_file_selected)
	reload_button.pressed.connect(_on_reload_pressed)
	format_json_button.pressed.connect(_on_format_json_pressed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _scan_mods() -> void:
	mod_entries.clear()
	mod_option.clear()
	for entry in ContentResolver.scan_character_entries(mods_roots, "any"):
		mod_entries.append(
			{
				"name": str(entry.get("name", "")),
				"path": str(entry.get("path", "")),
				"display_name": str(entry.get("display_name", entry.get("name", "")))
			}
		)
	mod_entries.sort_custom(func(a, b): return str(a.get("display_name", "")) < str(b.get("display_name", "")))

	for i in range(mod_entries.size()):
		mod_option.add_item(str(mod_entries[i].get("display_name", mod_entries[i].get("name", ""))), i)

	if mod_entries.is_empty():
		status_label.text = "No mods found."


func _normalize_root(root: String) -> String:
	var normalized: String = root.strip_edges()
	if normalized.is_empty():
		return ""
	if not normalized.ends_with("/"):
		normalized += "/"
	return normalized


func _select_default_mod() -> void:
	if mod_entries.is_empty():
		return
	var selected_index: int = 0
	for i in range(mod_entries.size()):
		if str(mod_entries[i].get("name", "")) == default_mod_name:
			selected_index = i
			break
	mod_option.select(selected_index)
	_on_mod_selected(selected_index)


func _on_mod_selected(index: int) -> void:
	if index < 0 or index >= mod_entries.size():
		return
	current_mod_path = str(mod_entries[index].get("path", ""))
	_rebuild_file_option()
	status_label.text = "Loaded mod: %s" % str(mod_entries[index].get("name", ""))


func _rebuild_file_option() -> void:
	file_option.clear()
	current_file_path = ""
	editor.text = ""
	if current_mod_path.is_empty():
		return

	var dir := DirAccess.open(current_mod_path)
	if dir == null:
		status_label.text = "Could not open mod directory."
		return

	var candidate_files: Array[String] = []
	dir.list_dir_begin()
	var item: String = dir.get_next()
	while not item.is_empty():
		if not dir.current_is_dir():
			var lower: String = item.to_lower()
			if lower.ends_with(".json") or lower.ends_with(".def"):
				candidate_files.append(item)
		item = dir.get_next()
	dir.list_dir_end()
	candidate_files.sort()

	for i in range(candidate_files.size()):
		var file_name: String = candidate_files[i]
		file_option.add_item(file_name, i)

	if candidate_files.is_empty():
		status_label.text = "No .json or .def files in this mod."
		return
	file_option.select(0)
	_on_file_selected(0)


func _on_file_selected(_index: int) -> void:
	if current_mod_path.is_empty() or file_option.get_selected() < 0:
		return
	var selected_name: String = file_option.get_item_text(file_option.get_selected())
	current_file_path = "%s%s" % [current_mod_path, selected_name]
	_load_current_file()


func _load_current_file() -> void:
	if current_file_path.is_empty():
		return
	if not FileAccess.file_exists(current_file_path):
		editor.text = ""
		status_label.text = "File missing: %s" % current_file_path
		return
	var file := FileAccess.open(current_file_path, FileAccess.READ)
	if file == null:
		editor.text = ""
		status_label.text = "Failed to open file."
		return
	editor.text = file.get_as_text()
	editor.set_caret_line(0)
	editor.set_caret_column(0)
	status_label.text = "Opened %s" % current_file_path


func _on_reload_pressed() -> void:
	_load_current_file()


func _on_format_json_pressed() -> void:
	if current_file_path.is_empty():
		return
	if not current_file_path.to_lower().ends_with(".json"):
		status_label.text = "Format JSON is only for .json files."
		return
	var parsed = JSON.parse_string(editor.text)
	if parsed == null:
		status_label.text = "JSON parse failed. Fix syntax first."
		return
	editor.text = JSON.stringify(parsed, "\t")
	status_label.text = "JSON formatted."


func _on_save_pressed() -> void:
	if current_file_path.is_empty():
		return
	var lower: String = current_file_path.to_lower()
	if lower.ends_with(".json"):
		var parsed = JSON.parse_string(editor.text)
		if parsed == null:
			status_label.text = "Save blocked: invalid JSON."
			return
		editor.text = JSON.stringify(parsed, "\t")
	var file := FileAccess.open(current_file_path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Save failed: cannot open file for write."
		return
	file.store_string(editor.text)
	status_label.text = "Saved %s" % current_file_path


func _on_back_pressed() -> void:
	if embedded_mode:
		return
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")


func set_embedded_mode(enabled: bool) -> void:
	embedded_mode = enabled
	_apply_embedded_mode()


func _apply_embedded_mode() -> void:
	if back_button != null:
		back_button.visible = not embedded_mode


func select_mod_by_name(mod_key: String) -> bool:
	if mod_key.is_empty():
		return false
	var key: String = mod_key.strip_edges()
	for i in range(mod_entries.size()):
		var e: Dictionary = mod_entries[i]
		if str(e.get("path", "")).strip_edges() == key:
			mod_option.select(i)
			_on_mod_selected(i)
			return true
	for i in range(mod_entries.size()):
		var e2: Dictionary = mod_entries[i]
		if str(e2.get("name", "")) == key or str(e2.get("display_name", "")) == key:
			mod_option.select(i)
			_on_mod_selected(i)
			return true
	return false


func reload_current() -> void:
	_on_reload_pressed()


func save_current() -> void:
	_on_save_pressed()
