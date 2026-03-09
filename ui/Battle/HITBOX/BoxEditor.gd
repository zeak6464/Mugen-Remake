extends Control

signal embedded_close_requested
signal box_data_applied(states_data: Dictionary, persistent_hurtboxes: Array)

const BOX_TYPE_KEYS: Array[String] = ["hitboxes", "persistent_hurtboxes", "throwboxes", "pushboxes"]
const STATE_BOX_TYPE_KEYS: Array[String] = ["hitboxes", "throwboxes", "pushboxes"]

@export var mods_roots: Array[String] = ["user://mods/", "res://mods/"]
@export var default_mod_name: String = "sample_fighter"

@onready var margin_container: Control = $MarginContainer
@onready var content_scroll: Control = $MarginContainer/ContentScroll
@onready var content_vbox: Control = $MarginContainer/ContentScroll/ContentVBox
@onready var title_label: Label = $MarginContainer/ContentScroll/ContentVBox/TitleLabel
@onready var top_row: Control = $MarginContainer/ContentScroll/ContentVBox/TopRow
@onready var mod_option: OptionButton = $MarginContainer/ContentScroll/ContentVBox/TopRow/ModOption
@onready var state_option: OptionButton = $MarginContainer/ContentScroll/ContentVBox/TopRow/StateOption
@onready var box_type_option: OptionButton = $MarginContainer/ContentScroll/ContentVBox/TopRow/BoxTypeOption
@onready var box_index_option: OptionButton = $MarginContainer/ContentScroll/ContentVBox/TopRow/BoxIndexOption
@onready var form_grid: Control = $MarginContainer/ContentScroll/ContentVBox/FormGrid
@onready var id_edit: LineEdit = $MarginContainer/ContentScroll/ContentVBox/FormGrid/IdEdit
@onready var bone_option: OptionButton = $MarginContainer/ContentScroll/ContentVBox/FormGrid/BoneOption
@onready var start_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/FormGrid/StartSpin
@onready var end_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/FormGrid/EndSpin
@onready var offset_x_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/FormGrid/OffsetXSpin
@onready var offset_y_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/FormGrid/OffsetYSpin
@onready var offset_z_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/FormGrid/OffsetZSpin
@onready var size_x_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/FormGrid/SizeXSpin
@onready var size_y_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/FormGrid/SizeYSpin
@onready var size_z_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/FormGrid/SizeZSpin
@onready var hit_data_grid: Control = $MarginContainer/ContentScroll/ContentVBox/HitDataGrid
@onready var damage_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/HitDataGrid/DamageSpin
@onready var pushback_x_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/HitDataGrid/PushbackXSpin
@onready var pushback_y_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/HitDataGrid/PushbackYSpin
@onready var pushback_z_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/HitDataGrid/PushbackZSpin
@onready var hitstun_state_edit: LineEdit = $MarginContainer/ContentScroll/ContentVBox/HitDataGrid/HitstunStateEdit
@onready var hit_sound_edit: LineEdit = $MarginContainer/ContentScroll/ContentVBox/HitDataGrid/HitSoundEdit
@onready var preview_panel: Panel = $MarginContainer/ContentScroll/ContentVBox/PreviewPanel
@onready var preview_viewport_container: SubViewportContainer = $MarginContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer
@onready var preview_camera: Camera3D = $MarginContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewWorld/Camera3D
@onready var preview_model_root: Node3D = $MarginContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewWorld/ModelRoot
@onready var preview_box_mesh: MeshInstance3D = $MarginContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewWorld/BoxMesh
@onready var animation_controls_row: Control = $MarginContainer/ContentScroll/ContentVBox/AnimationControlsRow
@onready var play_button: Button = $MarginContainer/ContentScroll/ContentVBox/AnimationControlsRow/PlayButton
@onready var pause_button: Button = $MarginContainer/ContentScroll/ContentVBox/AnimationControlsRow/PauseButton
@onready var stop_button: Button = $MarginContainer/ContentScroll/ContentVBox/AnimationControlsRow/StopButton
@onready var prev_frame_button: Button = $MarginContainer/ContentScroll/ContentVBox/AnimationControlsRow/PrevFrameButton
@onready var next_frame_button: Button = $MarginContainer/ContentScroll/ContentVBox/AnimationControlsRow/NextFrameButton
@onready var speed_spin: SpinBox = $MarginContainer/ContentScroll/ContentVBox/AnimationControlsRow/SpeedSpin
@onready var animation_timeline_row: Control = $MarginContainer/ContentScroll/ContentVBox/AnimationTimelineRow
@onready var timeline_slider: HSlider = $MarginContainer/ContentScroll/ContentVBox/AnimationTimelineRow/TimelineSlider
@onready var frame_label: Label = $MarginContainer/ContentScroll/ContentVBox/AnimationTimelineRow/FrameLabel
@onready var time_label: Label = $MarginContainer/ContentScroll/ContentVBox/AnimationTimelineRow/TimeLabel
@onready var status_label: Label = $MarginContainer/ContentScroll/ContentVBox/StatusLabel
@onready var actions_row: Control = $MarginContainer/ContentScroll/ContentVBox/ActionsRow
@onready var add_box_button: Button = $MarginContainer/ContentScroll/ContentVBox/ActionsRow/AddBoxButton
@onready var delete_box_button: Button = $MarginContainer/ContentScroll/ContentVBox/ActionsRow/DeleteBoxButton
@onready var apply_button: Button = $MarginContainer/ContentScroll/ContentVBox/ActionsRow/ApplyButton
@onready var save_button: Button = $MarginContainer/ContentScroll/ContentVBox/ActionsRow/SaveButton
@onready var close_button: Button = $MarginContainer/ContentScroll/ContentVBox/ActionsRow/CloseButton

var mod_entries: Array[Dictionary] = []
var loaded_states: Dictionary = {}
var current_states_path: String = ""
var current_mod_path: String = ""
var current_hurtboxes_path: String = ""
var current_model_path: String = ""
var persistent_hurtboxes: Array = []
var preview_skeleton: Skeleton3D = null
var preview_animation_player: AnimationPlayer = null
var current_preview_animation_name: String = ""
var timeline_dragging: bool = false
var preview_boxes_root: Node3D = null

var camera_target: Vector3 = Vector3(0.0, 1.0, 0.0)
var camera_distance: float = 4.2
var camera_yaw: float = 0.0
var camera_pitch: float = -0.2
var is_orbiting: bool = false
var is_panning: bool = false
var embedded_mode: bool = false


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	_connect_signals()
	_ensure_preview_boxes_root()
	_scan_mods()
	_select_default_mod()
	_setup_preview_box_material()
	_setup_preview_camera_defaults()
	_setup_animation_controls_defaults()
	_make_timing_controls_prominent()
	_update_preview_box()
	_update_hit_data_controls_state()
	_apply_embedded_mode()

func _connect_signals() -> void:
	mod_option.item_selected.connect(_on_mod_selected)
	state_option.item_selected.connect(_on_state_selected)
	box_type_option.item_selected.connect(_on_box_type_selected)
	box_index_option.item_selected.connect(_on_box_index_selected)
	add_box_button.pressed.connect(_on_add_box_pressed)
	delete_box_button.pressed.connect(_on_delete_box_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	save_button.pressed.connect(_on_save_pressed)
	close_button.pressed.connect(_on_close_pressed)
	id_edit.text_changed.connect(_on_form_changed)
	bone_option.item_selected.connect(_on_form_changed)
	start_spin.value_changed.connect(_on_form_changed)
	end_spin.value_changed.connect(_on_form_changed)
	offset_x_spin.value_changed.connect(_on_form_changed)
	offset_y_spin.value_changed.connect(_on_form_changed)
	offset_z_spin.value_changed.connect(_on_form_changed)
	size_x_spin.value_changed.connect(_on_form_changed)
	size_y_spin.value_changed.connect(_on_form_changed)
	size_z_spin.value_changed.connect(_on_form_changed)
	damage_spin.value_changed.connect(_on_form_changed)
	pushback_x_spin.value_changed.connect(_on_form_changed)
	pushback_y_spin.value_changed.connect(_on_form_changed)
	pushback_z_spin.value_changed.connect(_on_form_changed)
	hitstun_state_edit.text_changed.connect(_on_form_changed)
	hit_sound_edit.text_changed.connect(_on_form_changed)
	preview_viewport_container.gui_input.connect(_on_preview_gui_input)
	play_button.pressed.connect(_on_play_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	prev_frame_button.pressed.connect(_on_prev_frame_pressed)
	next_frame_button.pressed.connect(_on_next_frame_pressed)
	speed_spin.value_changed.connect(_on_speed_changed)
	timeline_slider.drag_started.connect(_on_timeline_drag_started)
	timeline_slider.drag_ended.connect(_on_timeline_drag_ended)
	timeline_slider.value_changed.connect(_on_timeline_value_changed)


func _process(_delta: float) -> void:
	# Keep box anchored to animated bone transforms in real time.
	_update_preview_box()
	_update_animation_ui()


func _scan_mods() -> void:
	mod_entries.clear()
	mod_option.clear()
	for entry in ContentResolver.scan_character_entries(mods_roots, "states"):
		mod_entries.append(
			{
				"name": str(entry.get("name", "")),
				"mod_path": str(entry.get("mod_path", "")),
				"states_path": str(entry.get("states_path", "")),
				"model_path": str(entry.get("model_path", ""))
			}
		)
	mod_entries.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))

	for i in range(mod_entries.size()):
		var mod_name_text: String = str(mod_entries[i].get("name", ""))
		mod_option.add_item(mod_name_text, i)

	if mod_entries.is_empty():
		status_label.text = "No mods with states.json found."


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
	var entry: Dictionary = mod_entries[index]
	current_mod_path = str(entry.get("mod_path", ""))
	current_states_path = str(entry.get("states_path", ""))
	current_model_path = str(entry.get("model_path", ""))
	current_hurtboxes_path = _resolve_hurtboxes_path(current_mod_path)
	loaded_states = _load_states(current_states_path)
	persistent_hurtboxes = _load_persistent_hurtboxes(current_hurtboxes_path)
	_rebuild_state_option()
	_refresh_preview_model()
	_update_preview_box()
	status_label.text = "Loaded %s" % str(entry.get("name", ""))


func _rebuild_state_option() -> void:
	state_option.clear()
	var keys: Array = loaded_states.keys()
	keys.sort()
	for i in range(keys.size()):
		state_option.add_item(str(keys[i]), i)
	if keys.is_empty():
		_clear_form()
		return
	state_option.select(0)
	_on_state_selected(0)


func _on_state_selected(_index: int) -> void:
	_rebuild_box_index_option()
	_play_preview_state_animation()


func _on_box_type_selected(_index: int) -> void:
	_rebuild_box_index_option()
	_update_preview_box()
	_update_hit_data_controls_state()


func _rebuild_box_index_option() -> void:
	box_index_option.clear()
	var boxes: Array = _get_current_box_array()
	for i in range(boxes.size()):
		var box_id: String = str((boxes[i] as Dictionary).get("id", "box_%d" % i))
		box_index_option.add_item("%d: %s" % [i, box_id], i)
	if boxes.is_empty():
		_clear_form()
		return
	box_index_option.select(0)
	_on_box_index_selected(0)


func _on_box_index_selected(index: int) -> void:
	var boxes: Array = _get_current_box_array()
	if index < 0 or index >= boxes.size():
		_clear_form()
		return
	_apply_box_to_form(boxes[index])
	_update_preview_box()


func _on_add_box_pressed() -> void:
	var boxes: Array = _get_current_box_array()
	var new_entry: Dictionary = {
		"id": "%s_%d" % [_get_current_box_key().trim_suffix("es"), boxes.size() + 1],
		"start": 0,
		"end": 0,
		"bone": "",
		"offset": [0.0, 1.0, 0.0],
		"size": [0.5, 0.5, 0.5]
	}
	if _get_current_box_key() == "hitboxes":
		new_entry["data"] = {"damage": 10, "pushback": [0.5, 0.0, 0.0], "hitstun_state": "hitstun"}
	boxes.append(new_entry)
	_set_current_box_array(boxes)
	_rebuild_box_index_option()
	box_index_option.select(boxes.size() - 1)
	_on_box_index_selected(boxes.size() - 1)
	status_label.text = "Added box entry."
	_update_preview_box()


func _on_delete_box_pressed() -> void:
	var boxes: Array = _get_current_box_array()
	var index: int = box_index_option.get_selected_id()
	if index < 0 or index >= boxes.size():
		return
	boxes.remove_at(index)
	_set_current_box_array(boxes)
	_rebuild_box_index_option()
	status_label.text = "Deleted box entry."
	_update_preview_box()


func _on_apply_pressed() -> void:
	var boxes: Array = _get_current_box_array()
	var index: int = box_index_option.get_selected()
	if index < 0 or index >= boxes.size():
		return
	var entry: Dictionary = boxes[index]
	entry["id"] = id_edit.text.strip_edges()
	entry["bone"] = _get_selected_bone_name()
	entry["start"] = int(start_spin.value)
	entry["end"] = int(end_spin.value)
	entry["offset"] = [offset_x_spin.value, offset_y_spin.value, offset_z_spin.value]
	entry["size"] = [maxf(0.05, size_x_spin.value), maxf(0.05, size_y_spin.value), maxf(0.05, size_z_spin.value)]
	if _is_hitbox_mode():
		var data_dict: Dictionary = {}
		if typeof(entry.get("data", {})) == TYPE_DICTIONARY:
			data_dict = (entry.get("data", {}) as Dictionary).duplicate(true)
		data_dict["damage"] = int(damage_spin.value)
		data_dict["pushback"] = [pushback_x_spin.value, pushback_y_spin.value, pushback_z_spin.value]
		data_dict["hitstun_state"] = hitstun_state_edit.text.strip_edges()
		data_dict["hit_sound"] = hit_sound_edit.text.strip_edges()
		entry["data"] = data_dict
	boxes[index] = entry
	_set_current_box_array(boxes)
	_rebuild_box_index_option()
	box_index_option.select(index)
	status_label.text = "Applied current values."
	_update_preview_box()
	box_data_applied.emit(loaded_states.duplicate(true), persistent_hurtboxes.duplicate(true))


func _on_save_pressed() -> void:
	if current_states_path.is_empty():
		return
	# Always fold current form values into loaded_states before saving.
	_on_apply_pressed()
	if not _write_states_file(current_states_path, loaded_states):
		status_label.text = "Failed to save states.json."
		return
	if not current_hurtboxes_path.is_empty():
		if not _write_hurtboxes_file(current_hurtboxes_path, persistent_hurtboxes):
			status_label.text = "Saved states.json but failed to save hurtboxes file."
			return
		_ensure_character_def_hurtboxes_file(current_mod_path, current_hurtboxes_path)
	var mirrored_res_path: String = _get_res_mirror_path(current_states_path)
	if not mirrored_res_path.is_empty():
		_write_states_file(mirrored_res_path, loaded_states)
		status_label.text = "Saved states + hurtboxes (mirrored states to %s)" % mirrored_res_path
	else:
		status_label.text = "Saved states + hurtboxes."


func _write_states_file(path: String, states: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(states, "\t"))
	return true


func _get_res_mirror_path(source_path: String) -> String:
	if not source_path.begins_with("user://mods/"):
		return ""
	var relative: String = source_path.trim_prefix("user://")
	var candidate: String = "res://%s" % relative
	if FileAccess.file_exists(candidate):
		return candidate
	return ""


func _on_close_pressed() -> void:
	if embedded_mode:
		embedded_close_requested.emit()
		return
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")


func set_embedded_mode(enabled: bool) -> void:
	embedded_mode = enabled
	_apply_embedded_mode()


func _apply_embedded_mode() -> void:
	if close_button != null:
		close_button.visible = true
		close_button.text = "Back" if embedded_mode else "Close"


func select_mod_by_name(mod_name: String) -> bool:
	if mod_name.is_empty():
		return false
	for i in range(mod_entries.size()):
		if str(mod_entries[i].get("name", "")) == mod_name:
			mod_option.select(i)
			_on_mod_selected(i)
			return true
	return false


func select_state_by_name(state_id: String, preferred_box_key: String = "hitboxes") -> bool:
	if state_id.is_empty():
		return false
	if not preferred_box_key.is_empty():
		select_box_type_by_key(preferred_box_key)
	for i in range(state_option.item_count):
		if state_option.get_item_text(i) == state_id:
			state_option.select(i)
			_on_state_selected(i)
			return true
	return false


func select_box_type_by_key(box_key: String) -> bool:
	var idx: int = BOX_TYPE_KEYS.find(box_key)
	if idx < 0:
		return false
	box_type_option.select(idx)
	_on_box_type_selected(idx)
	return true


func reload_current() -> void:
	var idx: int = mod_option.get_selected()
	if idx >= 0:
		_on_mod_selected(idx)


func save_current() -> void:
	_on_save_pressed()


func _get_selected_state_id() -> String:
	var idx: int = state_option.get_selected_id()
	if idx < 0:
		return ""
	return state_option.get_item_text(state_option.get_selected())


func _get_current_box_key() -> String:
	var selected: int = box_type_option.get_selected()
	if selected < 0:
		return "hitboxes"
	return BOX_TYPE_KEYS[selected]


func _is_hitbox_mode() -> bool:
	return _get_current_box_key() == "hitboxes"


func _get_current_box_array() -> Array:
	if _is_persistent_hurtbox_mode():
		return persistent_hurtboxes.duplicate(true)
	var state_id: String = _get_selected_state_id()
	if state_id.is_empty() or not loaded_states.has(state_id):
		return []
	var state_data: Dictionary = loaded_states[state_id]
	var key: String = _get_current_box_key()
	var boxes: Array = state_data.get(key, [])
	return boxes.duplicate(true)


func _set_current_box_array(boxes: Array) -> void:
	if _is_persistent_hurtbox_mode():
		persistent_hurtboxes = boxes.duplicate(true)
		return
	var state_id: String = _get_selected_state_id()
	if state_id.is_empty() or not loaded_states.has(state_id):
		return
	var state_data: Dictionary = loaded_states[state_id]
	var key: String = _get_current_box_key()
	state_data[key] = boxes
	loaded_states[state_id] = state_data


func _apply_box_to_form(entry: Dictionary) -> void:
	id_edit.text = str(entry.get("id", ""))
	_set_bone_option_by_name(str(entry.get("bone", "")))
	start_spin.value = float(entry.get("start", 0))
	end_spin.value = float(entry.get("end", 0))
	var offset: Vector3 = _to_vector3(entry.get("offset", Vector3.ZERO))
	var box_size: Vector3 = _to_vector3(entry.get("size", Vector3.ONE))
	offset_x_spin.value = offset.x
	offset_y_spin.value = offset.y
	offset_z_spin.value = offset.z
	size_x_spin.value = box_size.x
	size_y_spin.value = box_size.y
	size_z_spin.value = box_size.z
	if _is_hitbox_mode():
		_apply_hit_data_to_form(entry.get("data", {}))
	else:
		_clear_hit_data_form()
	_update_hit_data_controls_state()


func _clear_form() -> void:
	id_edit.text = ""
	_set_bone_option_by_name("")
	start_spin.value = 0
	end_spin.value = 0
	offset_x_spin.value = 0
	offset_y_spin.value = 0
	offset_z_spin.value = 0
	size_x_spin.value = 0.5
	size_y_spin.value = 0.5
	size_z_spin.value = 0.5
	_clear_hit_data_form()
	_update_hit_data_controls_state()
	_update_preview_box()


func _load_states(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var normalized: Dictionary = (parsed as Dictionary).duplicate(true)
	for state_id in normalized.keys():
		var state_data = normalized[state_id]
		if typeof(state_data) != TYPE_DICTIONARY:
			continue
		var state_dict: Dictionary = state_data
		for key in STATE_BOX_TYPE_KEYS:
			if not state_dict.has(key) or typeof(state_dict[key]) != TYPE_ARRAY:
				state_dict[key] = []
		normalized[state_id] = state_dict
	return normalized


func _is_persistent_hurtbox_mode() -> bool:
	return _get_current_box_key() == "persistent_hurtboxes"


func _resolve_hurtboxes_path(mod_path: String) -> String:
	var def_data: Dictionary = _load_character_def("%scharacter.def" % mod_path)
	var configured: String = str(def_data.get("hurtboxes_file", "")).strip_edges()
	if configured.is_empty():
		configured = str(def_data.get("hurtboxes_path", "")).strip_edges()
	if configured.is_empty():
		return "%shurtboxes.json" % mod_path
	if configured.begins_with("res://") or configured.begins_with("user://"):
		return configured
	return "%s%s" % [mod_path, configured]


func _load_persistent_hurtboxes(path: String) -> Array:
	if path.is_empty() or not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		return (parsed as Array).duplicate(true)
	if typeof(parsed) == TYPE_DICTIONARY:
		var dict: Dictionary = parsed
		var hurtboxes = dict.get("hurtboxes", [])
		if typeof(hurtboxes) == TYPE_ARRAY:
			return (hurtboxes as Array).duplicate(true)
	return []


func _write_hurtboxes_file(path: String, hurtboxes: Array) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"hurtboxes": hurtboxes}, "\t"))
	return true


func _ensure_character_def_hurtboxes_file(mod_path: String, hurtboxes_path: String) -> void:
	var character_def_path: String = "%scharacter.def" % mod_path
	if not FileAccess.file_exists(character_def_path):
		return
	var file := FileAccess.open(character_def_path, FileAccess.READ)
	if file == null:
		return
	var raw_text: String = file.get_as_text()
	var rel_path: String = hurtboxes_path
	if rel_path.begins_with(mod_path):
		rel_path = rel_path.trim_prefix(mod_path)
	var lines: PackedStringArray = raw_text.split("\n")
	var replaced: bool = false
	for i in range(lines.size()):
		var line: String = lines[i].strip_edges()
		if line.begins_with("hurtboxes_file") or line.begins_with("hurtboxes_path"):
			lines[i] = "hurtboxes_file = %s" % rel_path
			replaced = true
			break
	if not replaced:
		lines.append("hurtboxes_file = %s" % rel_path)
	var out := FileAccess.open(character_def_path, FileAccess.WRITE)
	if out != null:
		out.store_string("\n".join(lines))


func _to_vector3(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO


func _on_form_changed(_value = null) -> void:
	_update_preview_box()


func _apply_hit_data_to_form(raw_data) -> void:
	var data: Dictionary = {}
	if typeof(raw_data) == TYPE_DICTIONARY:
		data = raw_data as Dictionary
	damage_spin.value = float(data.get("damage", 10))
	var pushback: Vector3 = _to_vector3(data.get("pushback", Vector3(0.5, 0.0, 0.0)))
	pushback_x_spin.value = pushback.x
	pushback_y_spin.value = pushback.y
	pushback_z_spin.value = pushback.z
	hitstun_state_edit.text = str(data.get("hitstun_state", "hitstun"))
	hit_sound_edit.text = str(data.get("hit_sound", ""))


func _clear_hit_data_form() -> void:
	damage_spin.value = 10
	pushback_x_spin.value = 0.5
	pushback_y_spin.value = 0.0
	pushback_z_spin.value = 0.0
	hitstun_state_edit.text = "hitstun"
	hit_sound_edit.text = ""


func _update_hit_data_controls_state() -> void:
	var enabled: bool = _is_hitbox_mode() and _has_selected_box_entry()
	hit_data_grid.visible = _is_hitbox_mode()
	damage_spin.editable = enabled
	pushback_x_spin.editable = enabled
	pushback_y_spin.editable = enabled
	pushback_z_spin.editable = enabled
	hitstun_state_edit.editable = enabled
	hit_sound_edit.editable = enabled


func _find_model_path(mod_path: String) -> String:
	return ContentResolver.find_character_model_path(mod_path, _load_character_def("%scharacter.def" % mod_path))


func _refresh_preview_model() -> void:
	for child in preview_model_root.get_children():
		child.queue_free()
	preview_skeleton = null
	preview_animation_player = null
	if current_model_path.is_empty():
		_rebuild_bone_option()
		return
	var model_scene: Node = _load_model_scene(current_model_path)
	if model_scene == null:
		_rebuild_bone_option()
		return
	if model_scene is Node3D:
		var model_node := model_scene as Node3D
		var def_data: Dictionary = _load_character_def("%scharacter.def" % current_mod_path)
		model_node.scale = _extract_model_scale(def_data)
		model_node.position.y += float(def_data.get("model_offset_y", 0.0))
	preview_model_root.add_child(model_scene)
	preview_skeleton = _find_skeleton_recursive(model_scene)
	preview_animation_player = _find_animation_player_recursive(model_scene)
	_rebuild_bone_option()
	_reset_camera_target_from_model()
	_update_preview_camera_transform()
	_apply_speed_to_preview_animation()
	_play_preview_state_animation()


func _load_model_scene(path: String) -> Node:
	var lower := path.to_lower()
	if not path.begins_with("user://"):
		var loaded = ResourceLoader.load(path)
		if loaded is PackedScene:
			return (loaded as PackedScene).instantiate()
	if lower.ends_with(".gltf") or lower.ends_with(".glb"):
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		if gltf.append_from_file(path, state) == OK:
			return gltf.generate_scene(state)
	return null


func _setup_preview_box_material() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = _get_preview_box_color()
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	preview_box_mesh.material_override = mat


func _setup_preview_camera_defaults() -> void:
	var camera_pos: Vector3 = preview_camera.global_position
	camera_target = Vector3(0.0, 1.0, 0.0)
	var to_camera: Vector3 = camera_pos - camera_target
	camera_distance = maxf(1.0, to_camera.length())
	camera_yaw = atan2(to_camera.x, to_camera.z)
	camera_pitch = asin(clampf(to_camera.y / camera_distance, -1.0, 1.0))
	_update_preview_camera_transform()


func _update_preview_box() -> void:
	if preview_box_mesh == null:
		return
	var box_size := Vector3(maxf(0.05, float(size_x_spin.value)), maxf(0.05, float(size_y_spin.value)), maxf(0.05, float(size_z_spin.value)))
	var offset := Vector3(float(offset_x_spin.value), float(offset_y_spin.value), float(offset_z_spin.value))
	preview_box_mesh.scale = box_size
	preview_box_mesh.position = _resolve_box_preview_position(offset, _get_selected_bone_name())
	preview_box_mesh.visible = _has_selected_box_entry()
	var mat := preview_box_mesh.material_override as StandardMaterial3D
	if mat != null:
		var color := _get_preview_box_color()
		mat.albedo_color = color
		mat.emission = color
	_update_preview_overlay_boxes()


func _has_selected_box_entry() -> bool:
	var boxes: Array = _get_current_box_array()
	if boxes.is_empty():
		return false
	var selected_index: int = box_index_option.get_selected()
	return selected_index >= 0 and selected_index < boxes.size()


func _get_selected_box_entry() -> Dictionary:
	var boxes: Array = _get_current_box_array()
	if boxes.is_empty():
		return {}
	var selected_index: int = box_index_option.get_selected()
	if selected_index < 0 or selected_index >= boxes.size():
		return {}
	if typeof(boxes[selected_index]) != TYPE_DICTIONARY:
		return {}
	return boxes[selected_index] as Dictionary


func _get_preview_box_color() -> Color:
	match _get_current_box_key():
		"hitboxes":
			return Color(1.0, 0.1, 0.1, 0.45)
		"persistent_hurtboxes":
			return Color(0.1, 0.9, 1.0, 0.45)
		"throwboxes":
			return Color(1.0, 0.85, 0.1, 0.45)
		"pushboxes":
			return Color(0.2, 1.0, 0.25, 0.45)
	return Color(1.0, 1.0, 1.0, 0.45)


func _resolve_box_preview_position(offset: Vector3, bone_name: String) -> Vector3:
	if preview_skeleton == null or bone_name.is_empty():
		return offset
	var bone_idx: int = preview_skeleton.find_bone(bone_name)
	if bone_idx == -1:
		return offset
	var bone_world: Transform3D = preview_skeleton.global_transform * preview_skeleton.get_bone_global_pose(bone_idx)
	return bone_world.origin + (bone_world.basis * offset)


func _ensure_preview_boxes_root() -> void:
	if preview_box_mesh == null:
		return
	var parent_node := preview_box_mesh.get_parent()
	if parent_node == null:
		return
	var existing := parent_node.get_node_or_null("BoxesRoot")
	if existing != null and existing is Node3D:
		preview_boxes_root = existing as Node3D
		return
	preview_boxes_root = Node3D.new()
	preview_boxes_root.name = "BoxesRoot"
	parent_node.add_child(preview_boxes_root)


func _update_preview_overlay_boxes() -> void:
	if preview_boxes_root == null:
		return
	for child in preview_boxes_root.get_children():
		child.queue_free()
	var boxes: Array = _get_current_box_array()
	if boxes.is_empty():
		return
	var selected_index: int = box_index_option.get_selected()
	var frame_now: int = _get_preview_state_frame()
	for i in range(boxes.size()):
		if i == selected_index:
			continue
		if not (boxes[i] is Dictionary):
			continue
		var entry: Dictionary = boxes[i]
		if not _is_box_active_on_frame(entry, frame_now):
			continue
		var size_vec: Vector3 = _to_vector3(entry.get("size", Vector3.ONE))
		var offset_vec: Vector3 = _to_vector3(entry.get("offset", Vector3.ZERO))
		var bone_name: String = str(entry.get("bone", ""))
		var mesh_instance := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3.ONE
		mesh_instance.mesh = box_mesh
		mesh_instance.scale = Vector3(
			maxf(0.05, size_vec.x),
			maxf(0.05, size_vec.y),
			maxf(0.05, size_vec.z)
		)
		mesh_instance.position = _resolve_box_preview_position(offset_vec, bone_name)
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.no_depth_test = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var color := _get_preview_box_color()
		color.a = 0.22
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mesh_instance.material_override = mat
		preview_boxes_root.add_child(mesh_instance)


func _is_box_active_on_frame(entry: Dictionary, frame_now: int) -> bool:
	var start_frame: int = int(entry.get("start", 0))
	var end_frame: int = int(entry.get("end", -1))
	if frame_now < start_frame:
		return false
	if end_frame >= 0 and frame_now > end_frame:
		return false
	return true


func _get_preview_state_frame() -> int:
	if preview_animation_player == null:
		return 0
	if current_preview_animation_name.is_empty():
		return 0
	if not preview_animation_player.has_animation(current_preview_animation_name):
		return 0
	var anim: Animation = preview_animation_player.get_animation(current_preview_animation_name)
	if anim == null:
		return 0
	var fps: float = _get_preview_fps(anim)
	var current_time: float = maxf(0.0, preview_animation_player.current_animation_position)
	return int(round(current_time * fps))


func _load_character_def(path: String) -> Dictionary:
	return ContentResolver.load_character_def(path)


func _is_candidate_model_file(path: String) -> bool:
	return ContentResolver.is_candidate_model_file(path)


func _find_skeleton_recursive(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found: Skeleton3D = _find_skeleton_recursive(child)
		if found != null:
			return found
	return null


func _find_animation_player_recursive(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found: AnimationPlayer = _find_animation_player_recursive(child)
		if found != null:
			return found
	return null


func _play_preview_state_animation() -> void:
	if preview_animation_player == null:
		current_preview_animation_name = ""
		_update_animation_ui()
		return
	var state_id: String = _get_selected_state_id()
	if state_id.is_empty() or not loaded_states.has(state_id):
		current_preview_animation_name = ""
		_update_animation_ui()
		return
	var state_data: Dictionary = loaded_states[state_id]
	var animation_name: String = str(state_data.get("animation", ""))
	if animation_name.is_empty():
		current_preview_animation_name = ""
		_update_animation_ui()
		return
	current_preview_animation_name = animation_name
	if preview_animation_player.has_animation(animation_name):
		preview_animation_player.play(animation_name)
	_update_animation_ui()


func _rebuild_bone_option() -> void:
	var previous: String = _get_selected_bone_name()
	bone_option.clear()
	bone_option.add_item("<none>", 0)
	if preview_skeleton != null:
		for i in range(preview_skeleton.get_bone_count()):
			var bone_name: String = preview_skeleton.get_bone_name(i)
			bone_option.add_item(bone_name, i + 1)
	_set_bone_option_by_name(previous)


func _get_selected_bone_name() -> String:
	if bone_option.get_item_count() == 0:
		return ""
	var selected: int = bone_option.get_selected()
	if selected <= 0:
		return ""
	return bone_option.get_item_text(selected)


func _set_bone_option_by_name(bone_name: String) -> void:
	if bone_option.get_item_count() == 0:
		return
	if bone_name.is_empty():
		bone_option.select(0)
		return
	for i in range(bone_option.get_item_count()):
		if bone_option.get_item_text(i) == bone_name:
			bone_option.select(i)
			return
	bone_option.select(0)


func _extract_model_scale(character_def: Dictionary) -> Vector3:
	var uniform_scale: float = float(character_def.get("model_scale", 1.0))
	var x: float = float(character_def.get("model_scale_x", uniform_scale))
	var y: float = float(character_def.get("model_scale_y", uniform_scale))
	var z: float = float(character_def.get("model_scale_z", uniform_scale))
	return Vector3(x, y, z)


func _reset_camera_target_from_model() -> void:
	if preview_model_root.get_child_count() == 0:
		camera_target = Vector3(0.0, 1.0, 0.0)
		return
	var aabb: AABB
	var has_aabb: bool = false
	var stack: Array[Node] = [preview_model_root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is VisualInstance3D:
			var visual: VisualInstance3D = node as VisualInstance3D
			var node_aabb: AABB = visual.get_aabb()
			if not node_aabb.size.is_zero_approx():
				var world_origin: Vector3 = visual.global_transform * node_aabb.position
				var world_end: Vector3 = visual.global_transform * (node_aabb.position + node_aabb.size)
				var world_aabb: AABB = AABB(world_origin, Vector3.ZERO).expand(world_end)
				if has_aabb:
					aabb = aabb.merge(world_aabb)
				else:
					aabb = world_aabb
					has_aabb = true
		for child in node.get_children():
			stack.append(child)
	if has_aabb:
		camera_target = aabb.get_center()
		camera_target.y = maxf(0.5, camera_target.y)
		camera_distance = clampf(maxf(aabb.size.length() * 0.85, 2.0), 2.0, 16.0)


func _update_preview_camera_transform() -> void:
	camera_pitch = clampf(camera_pitch, -1.2, 1.2)
	camera_distance = clampf(camera_distance, 1.2, 20.0)
	var offset: Vector3 = Vector3(
		sin(camera_yaw) * cos(camera_pitch),
		sin(camera_pitch),
		cos(camera_yaw) * cos(camera_pitch)
	) * camera_distance
	preview_camera.global_position = camera_target + offset
	preview_camera.look_at(camera_target, Vector3.UP)


func _on_preview_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event as InputEventMouseButton
		match button_event.button_index:
			MOUSE_BUTTON_LEFT:
				is_orbiting = button_event.pressed
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				is_panning = button_event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if button_event.pressed:
					camera_distance *= 0.9
					_update_preview_camera_transform()
			MOUSE_BUTTON_WHEEL_DOWN:
				if button_event.pressed:
					camera_distance *= 1.1
					_update_preview_camera_transform()
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if is_orbiting:
			camera_yaw -= motion.relative.x * 0.008
			camera_pitch -= motion.relative.y * 0.008
			_update_preview_camera_transform()
		elif is_panning:
			var right: Vector3 = preview_camera.global_transform.basis.x
			var up: Vector3 = preview_camera.global_transform.basis.y
			var pan_scale: float = 0.0035 * camera_distance
			camera_target += (-right * motion.relative.x + up * motion.relative.y) * pan_scale
			_update_preview_camera_transform()


func _setup_animation_controls_defaults() -> void:
	speed_spin.min_value = 0.1
	speed_spin.max_value = 3.0
	speed_spin.step = 0.1
	speed_spin.value = 1.0
	timeline_slider.min_value = 0.0
	timeline_slider.max_value = 1.0
	timeline_slider.step = 0.0001
	timeline_slider.value = 0.0
	_update_animation_ui()


func _make_timing_controls_prominent() -> void:
	if content_vbox == null:
		return
	if animation_controls_row != null and animation_controls_row.get_parent() == content_vbox:
		content_vbox.move_child(animation_controls_row, preview_panel.get_index())
	if animation_timeline_row != null and animation_timeline_row.get_parent() == content_vbox:
		content_vbox.move_child(animation_timeline_row, preview_panel.get_index())
	if preview_panel != null:
		preview_panel.custom_minimum_size.y = 240.0 if embedded_mode else 280.0


func _on_play_pressed() -> void:
	if preview_animation_player == null:
		return
	if current_preview_animation_name.is_empty():
		_play_preview_state_animation()
		return
	if preview_animation_player.has_animation(current_preview_animation_name):
		preview_animation_player.play(current_preview_animation_name)


func _on_pause_pressed() -> void:
	if preview_animation_player == null:
		return
	preview_animation_player.pause()


func _on_stop_pressed() -> void:
	if preview_animation_player == null:
		return
	preview_animation_player.stop()
	preview_animation_player.seek(0.0, true)
	_update_animation_ui()


func _on_prev_frame_pressed() -> void:
	_step_preview_frame(-1)


func _on_next_frame_pressed() -> void:
	_step_preview_frame(1)


func _step_preview_frame(direction: int) -> void:
	if preview_animation_player == null:
		return
	if current_preview_animation_name.is_empty():
		return
	if not preview_animation_player.has_animation(current_preview_animation_name):
		return
	var anim: Animation = preview_animation_player.get_animation(current_preview_animation_name)
	if anim == null:
		return
	preview_animation_player.pause()
	var fps: float = _get_preview_fps(anim)
	var frame_step: float = 1.0 / fps
	var length: float = anim.length
	var next_time: float = clampf(preview_animation_player.current_animation_position + (frame_step * float(direction)), 0.0, length)
	preview_animation_player.seek(next_time, true)
	_update_animation_ui()


func _on_speed_changed(value: float) -> void:
	_apply_speed_to_preview_animation()
	status_label.text = "Animation speed: %.1fx" % value


func _apply_speed_to_preview_animation() -> void:
	if preview_animation_player == null:
		return
	preview_animation_player.speed_scale = float(speed_spin.value)


func _on_timeline_drag_started() -> void:
	timeline_dragging = true


func _on_timeline_drag_ended(_value_changed: bool) -> void:
	timeline_dragging = false


func _on_timeline_value_changed(value: float) -> void:
	if not timeline_dragging:
		return
	_seek_preview_normalized(float(value))


func _seek_preview_normalized(normalized: float) -> void:
	if preview_animation_player == null:
		return
	if current_preview_animation_name.is_empty():
		return
	if not preview_animation_player.has_animation(current_preview_animation_name):
		return
	var anim: Animation = preview_animation_player.get_animation(current_preview_animation_name)
	if anim == null:
		return
	var length: float = maxf(anim.length, 0.001)
	preview_animation_player.seek(clampf(normalized, 0.0, 1.0) * length, true)
	_update_animation_ui()


func _update_animation_ui() -> void:
	if preview_animation_player == null or current_preview_animation_name.is_empty():
		frame_label.text = "Frame: -"
		time_label.text = "Time: -"
		if not timeline_dragging:
			timeline_slider.value = 0.0
		return
	if not preview_animation_player.has_animation(current_preview_animation_name):
		frame_label.text = "Frame: -"
		time_label.text = "Time: -"
		if not timeline_dragging:
			timeline_slider.value = 0.0
		return
	var anim: Animation = preview_animation_player.get_animation(current_preview_animation_name)
	if anim == null:
		return
	var length: float = maxf(anim.length, 0.001)
	var current_time: float = clampf(preview_animation_player.current_animation_position, 0.0, length)
	var fps: float = _get_preview_fps(anim)
	var frame: int = int(round(current_time * fps))
	var total_frames: int = int(ceil(length * fps))
	frame_label.text = "Frame: %d / %d | %s" % [frame, total_frames, _describe_selected_box_activity(frame)]
	time_label.text = "Time: %.2f / %.2f" % [current_time, length]
	if not timeline_dragging:
		timeline_slider.value = current_time / length


func _get_preview_fps(anim: Animation) -> float:
	var fps: float = (1.0 / float(anim.step)) if anim.step > 0.0001 else 60.0
	return maxf(1.0, fps)


func _describe_selected_box_activity(frame_now: int) -> String:
	var entry: Dictionary = _get_selected_box_entry()
	if entry.is_empty():
		return "No box selected"
	var start_frame: int = int(entry.get("start", 0))
	var end_frame: int = int(entry.get("end", -1))
	if _is_box_active_on_frame(entry, frame_now):
		if end_frame >= 0:
			return "ACTIVE [%d-%d]" % [start_frame, end_frame]
		return "ACTIVE [%d-...]" % start_frame
	if frame_now < start_frame:
		return "Starts at %d" % start_frame
	if end_frame >= 0:
		return "Ended at %d" % end_frame
	return "Inactive"
