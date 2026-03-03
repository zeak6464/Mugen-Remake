extends Control

@export var mods_roots: Array[String] = ["user://mods/", "res://mods/"]
@export var default_mod_name: String = "sample_fighter"
@export var box_editor_scene_path: String = "res://ui/Battle/HITBOX/BoxEditor.tscn"
@export var json_editor_scene_path: String = "res://ui/JsonEditor.tscn"
@export var playtest_scene_path: String = "res://stages/TestArena.tscn"

@onready var margin_container: Control = $MarginContainer
@onready var vbox_container: Control = $MarginContainer/VBoxContainer
@onready var top_row: Control = $MarginContainer/VBoxContainer/TopRow
@onready var mod_option: OptionButton = $MarginContainer/VBoxContainer/TopRow/ModOption
@onready var section_option: OptionButton = $MarginContainer/VBoxContainer/TopRow/SectionOption
@onready var reload_button: Button = $MarginContainer/VBoxContainer/TopRow/ReloadButton
@onready var save_button: Button = $MarginContainer/VBoxContainer/TopRow/SaveButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/TopRow/BackButton
@onready var content_panel: Panel = $MarginContainer/VBoxContainer/ContentPanel
@onready var editors_root: Control = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot
@onready var box_host: Control = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/BoxHost
@onready var file_host: Control = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/FileHost
@onready var states_host: Control = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost
@onready var state_maker_option: OptionButton = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/TopRow/StateOption
@onready var state_maker_add_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/TopRow/AddStateButton
@onready var state_maker_delete_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/TopRow/DeleteStateButton
@onready var state_maker_id_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/FormGrid/StateIdEdit
@onready var state_maker_animation_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/FormGrid/AnimationEdit
@onready var state_maker_animation_option: OptionButton = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/AnimationRow/AnimationOption
@onready var state_maker_refresh_animations_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/AnimationRow/RefreshAnimationsButton
@onready var state_maker_use_animation_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/AnimationRow/UseAnimationButton
@onready var state_maker_allow_movement_check: CheckBox = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/FormGrid/AllowMovementCheck
@onready var state_maker_cancel_into_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/FormGrid/CancelIntoEdit
@onready var state_maker_cancel_windows_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/FormGrid/CancelWindowsEdit
@onready var state_maker_next_frame_spin: SpinBox = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/FormGrid/NextFrameSpin
@onready var state_maker_next_id_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/FormGrid/NextIdEdit
@onready var state_maker_preset_option: OptionButton = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/PresetRow/PresetOption
@onready var state_maker_add_preset_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/PresetRow/AddPresetButton
@onready var state_maker_controllers_lane_list: ItemList = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ControllersPanel/ControllersVBox/ControllersLaneList
@onready var state_maker_controller_type_option: OptionButton = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ControllersPanel/ControllersVBox/ControllersEditRow/ControllerTypeOption
@onready var state_maker_controller_trigger_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ControllersPanel/ControllersVBox/ControllersEditRow/ControllerTriggerEdit
@onready var state_maker_controller_params_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ControllersPanel/ControllersVBox/ControllersEditRow/ControllerParamsEdit
@onready var state_maker_add_update_controller_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ControllersPanel/ControllersVBox/ControllersEditRow/AddUpdateControllerButton
@onready var state_maker_delete_controller_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ControllersPanel/ControllersVBox/ControllersEditRow/DeleteControllerButton
@onready var state_maker_controllers_text: TextEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ControllersPanel/ControllersVBox/ControllersText
@onready var state_maker_sounds_lane_list: ItemList = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/SoundsPanel/SoundsVBox/SoundsLaneList
@onready var state_maker_sound_frame_spin: SpinBox = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/SoundsPanel/SoundsVBox/SoundsEditRow/SoundFrameSpin
@onready var state_maker_sound_id_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/SoundsPanel/SoundsVBox/SoundsEditRow/SoundIdEdit
@onready var state_maker_sound_channel_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/SoundsPanel/SoundsVBox/SoundsEditRow/SoundChannelEdit
@onready var state_maker_add_update_sound_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/SoundsPanel/SoundsVBox/SoundsEditRow/AddUpdateSoundButton
@onready var state_maker_delete_sound_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/SoundsPanel/SoundsVBox/SoundsEditRow/DeleteSoundButton
@onready var state_maker_sounds_text: TextEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/SoundsPanel/SoundsVBox/SoundsText
@onready var state_maker_projectiles_lane_list: ItemList = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ProjectilesPanel/ProjectilesVBox/ProjectilesLaneList
@onready var state_maker_projectile_frame_spin: SpinBox = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ProjectilesPanel/ProjectilesVBox/ProjectilesEditRow/ProjectileFrameSpin
@onready var state_maker_projectile_id_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ProjectilesPanel/ProjectilesVBox/ProjectilesEditRow/ProjectileIdEdit
@onready var state_maker_add_update_projectile_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ProjectilesPanel/ProjectilesVBox/ProjectilesEditRow/AddUpdateProjectileButton
@onready var state_maker_delete_projectile_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ProjectilesPanel/ProjectilesVBox/ProjectilesEditRow/DeleteProjectileButton
@onready var state_maker_projectiles_text: TextEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ArraysRow/ProjectilesPanel/ProjectilesVBox/ProjectilesText
@onready var state_maker_timeline_text: RichTextLabel = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/TimelineText
@onready var state_maker_apply_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/StatesHost/VBoxContainer/ActionsRow/ApplyStateButton
@onready var commands_host: Control = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost
@onready var command_option: OptionButton = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/TopRow/CommandOption
@onready var add_command_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/TopRow/AddCommandButton
@onready var delete_command_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/TopRow/DeleteCommandButton
@onready var command_id_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/FormGrid/CommandIdEdit
@onready var command_pattern_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/FormGrid/PatternEdit
@onready var command_target_state_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/FormGrid/TargetStateEdit
@onready var command_max_window_spin: SpinBox = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/FormGrid/MaxWindowSpin
@onready var command_min_repeat_spin: SpinBox = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/FormGrid/MinRepeatSpin
@onready var command_transform_to_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/FormGrid/TransformToEdit
@onready var command_transform_state_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/FormGrid/TransformStateEdit
@onready var command_revert_transform_check: CheckBox = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/FormGrid/RevertTransformCheck
@onready var command_apply_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/CommandsHost/VBoxContainer/ActionsRow/ApplyCommandButton
@onready var preview_host: Control = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/PreviewHost
@onready var preview_command_option: OptionButton = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/PreviewHost/VBoxContainer/CommandRow/CommandOption
@onready var preview_match_label: Label = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/PreviewHost/VBoxContainer/CommandRow/MatchLabel
@onready var preview_input_label: Label = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/PreviewHost/VBoxContainer/InputRow/InputLabel
@onready var preview_buffer_text: RichTextLabel = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/PreviewHost/VBoxContainer/BufferText
@onready var preview_playtest_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/PreviewHost/VBoxContainer/ActionRow/PlaytestButton
@onready var frame_host: Control = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/FrameHost
@onready var frame_vbox: Control = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/FrameHost/VBoxContainer
@onready var frame_top_row: Control = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/FrameHost/VBoxContainer/TopRow
@onready var frame_state_option: OptionButton = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/FrameHost/VBoxContainer/TopRow/StateOption
@onready var frame_hint_label: Label = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/FrameHost/VBoxContainer/TopRow/HintLabel
@onready var frame_data_text: RichTextLabel = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/FrameHost/VBoxContainer/FrameDataText
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel

var mod_entries: Array[Dictionary] = []
var box_editor_instance: Control = null
var json_editor_instance: Control = null
var state_maker_data: Dictionary = {}
var current_state_maker_path: String = ""
var selected_state_maker_key: String = ""
var state_maker_animation_names: Array[String] = []
var state_maker_mod_path: String = ""
var state_maker_controllers_lane: Array = []
var state_maker_sounds_lane: Array = []
var state_maker_projectiles_lane: Array = []
var frame_states_data: Dictionary = {}
var commands_data: Dictionary = {"commands": []}
var current_commands_path: String = ""
var preview_commands_data: Dictionary = {}
var preview_command_interpreter: CommandInterpreter = null
var preview_last_buffer_hash: int = 0


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	_build_section_options()
	_instantiate_embedded_editors()
	_setup_preview_tools()
	_build_state_maker_controller_type_options()
	_connect_signals()
	_scan_mods()
	_select_default_mod()
	_apply_initial_section_from_meta()
	_apply_section_visibility()

func _build_section_options() -> void:
	section_option.clear()
	section_option.add_item("Box Tools")
	section_option.add_item("Raw Files")
	section_option.add_item("States")
	section_option.add_item("Commands")
	section_option.add_item("Preview")
	section_option.add_item("Frame Data")
	section_option.select(0)


func _instantiate_embedded_editors() -> void:
	var box_scene := load(box_editor_scene_path)
	if box_scene is PackedScene:
		box_editor_instance = (box_scene as PackedScene).instantiate() as Control
		if box_editor_instance != null:
			box_host.add_child(box_editor_instance)
			_fit_embedded_editor_to_host(box_editor_instance)
			if box_editor_instance.has_method("set_embedded_mode"):
				box_editor_instance.call("set_embedded_mode", true)

	var json_scene := load(json_editor_scene_path)
	if json_scene is PackedScene:
		json_editor_instance = (json_scene as PackedScene).instantiate() as Control
		if json_editor_instance != null:
			file_host.add_child(json_editor_instance)
			_fit_embedded_editor_to_host(json_editor_instance)
			if json_editor_instance.has_method("set_embedded_mode"):
				json_editor_instance.call("set_embedded_mode", true)


func _connect_signals() -> void:
	mod_option.item_selected.connect(_on_mod_selected)
	section_option.item_selected.connect(_on_section_selected)
	state_maker_option.item_selected.connect(_on_state_maker_selected)
	state_maker_add_button.pressed.connect(_on_state_maker_add_pressed)
	state_maker_delete_button.pressed.connect(_on_state_maker_delete_pressed)
	state_maker_apply_button.pressed.connect(_on_state_maker_apply_pressed)
	state_maker_refresh_animations_button.pressed.connect(_on_state_maker_refresh_animations_pressed)
	state_maker_use_animation_button.pressed.connect(_on_state_maker_use_animation_pressed)
	state_maker_add_preset_button.pressed.connect(_on_state_maker_add_preset_pressed)
	state_maker_controllers_lane_list.item_selected.connect(_on_state_maker_controller_lane_selected)
	state_maker_add_update_controller_button.pressed.connect(_on_state_maker_add_update_controller_pressed)
	state_maker_delete_controller_button.pressed.connect(_on_state_maker_delete_controller_pressed)
	state_maker_sounds_lane_list.item_selected.connect(_on_state_maker_sound_lane_selected)
	state_maker_add_update_sound_button.pressed.connect(_on_state_maker_add_update_sound_pressed)
	state_maker_delete_sound_button.pressed.connect(_on_state_maker_delete_sound_pressed)
	state_maker_projectiles_lane_list.item_selected.connect(_on_state_maker_projectile_lane_selected)
	state_maker_add_update_projectile_button.pressed.connect(_on_state_maker_add_update_projectile_pressed)
	state_maker_delete_projectile_button.pressed.connect(_on_state_maker_delete_projectile_pressed)
	command_option.item_selected.connect(_on_command_selected)
	add_command_button.pressed.connect(_on_add_command_pressed)
	delete_command_button.pressed.connect(_on_delete_command_pressed)
	command_apply_button.pressed.connect(_on_apply_command_pressed)
	preview_command_option.item_selected.connect(_on_preview_command_selected)
	preview_playtest_button.pressed.connect(_on_preview_playtest_pressed)
	frame_state_option.item_selected.connect(_on_frame_state_selected)
	reload_button.pressed.connect(_on_reload_pressed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _scan_mods() -> void:
	mod_entries.clear()
	mod_option.clear()
	var seen_names: Dictionary = {}
	for root in mods_roots:
		var normalized_root: String = _normalize_root(root)
		if normalized_root.is_empty():
			continue
		if normalized_root.begins_with("user://"):
			var root_abs: String = ProjectSettings.globalize_path(normalized_root)
			if not DirAccess.dir_exists_absolute(root_abs):
				DirAccess.make_dir_recursive_absolute(root_abs)
		var dir := DirAccess.open(normalized_root)
		if dir == null:
			continue
		dir.list_dir_begin()
		var item := dir.get_next()
		while not item.is_empty():
			if dir.current_is_dir() and item != "." and item != ".." and not seen_names.has(item):
				mod_entries.append({"name": item, "path": "%s%s/" % [normalized_root, item]})
				seen_names[item] = true
			item = dir.get_next()
		dir.list_dir_end()
	mod_entries.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
	for i in range(mod_entries.size()):
		mod_option.add_item(str(mod_entries[i].get("name", "")), i)


func _select_default_mod() -> void:
	if mod_entries.is_empty():
		status_label.text = "No mods found."
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
	var mod_name: String = str(mod_entries[index].get("name", ""))
	if box_editor_instance != null and box_editor_instance.has_method("select_mod_by_name"):
		box_editor_instance.call("select_mod_by_name", mod_name)
	if json_editor_instance != null and json_editor_instance.has_method("select_mod_by_name"):
		json_editor_instance.call("select_mod_by_name", mod_name)
	_reload_state_maker_for_mod(index)
	_reload_commands_for_mod(index)
	_reload_preview_tools_for_mod(index)
	_reload_frame_data_for_mod(index)
	status_label.text = "Loaded mod: %s" % mod_name


func _on_section_selected(_index: int) -> void:
	_apply_section_visibility()


func _apply_section_visibility() -> void:
	var section_id: int = section_option.get_selected()
	if section_id == 1:
		box_host.visible = false
		file_host.visible = true
		states_host.visible = false
		commands_host.visible = false
		preview_host.visible = false
		frame_host.visible = false
		status_label.text = "Raw Files section active."
	elif section_id == 2:
		box_host.visible = false
		file_host.visible = false
		states_host.visible = true
		commands_host.visible = false
		preview_host.visible = false
		frame_host.visible = false
		status_label.text = "States section active."
	elif section_id == 3:
		box_host.visible = false
		file_host.visible = false
		states_host.visible = false
		commands_host.visible = true
		preview_host.visible = false
		frame_host.visible = false
		status_label.text = "Commands section active."
	elif section_id == 4:
		box_host.visible = false
		file_host.visible = false
		states_host.visible = false
		commands_host.visible = false
		preview_host.visible = true
		frame_host.visible = false
		status_label.text = "Preview section active (Command Tester + In-Editor Playtest)."
	elif section_id == 5:
		box_host.visible = false
		file_host.visible = false
		states_host.visible = false
		commands_host.visible = false
		preview_host.visible = false
		frame_host.visible = true
		status_label.text = "Frame Data section active."
	else:
		box_host.visible = true
		file_host.visible = false
		states_host.visible = false
		commands_host.visible = false
		preview_host.visible = false
		frame_host.visible = false
		status_label.text = "Box Tools section active."


func _on_reload_pressed() -> void:
	var section_id: int = section_option.get_selected()
	if section_id == 1:
		if json_editor_instance != null and json_editor_instance.has_method("reload_current"):
			json_editor_instance.call("reload_current")
	elif section_id == 2:
		var idx_state: int = mod_option.get_selected()
		if idx_state >= 0:
			_reload_state_maker_for_mod(idx_state)
	elif section_id == 3:
		var idx_cmd: int = mod_option.get_selected()
		if idx_cmd >= 0:
			_reload_commands_for_mod(idx_cmd)
	elif section_id == 4:
		var idx_preview: int = mod_option.get_selected()
		if idx_preview >= 0:
			_reload_preview_tools_for_mod(idx_preview)
	elif section_id == 5:
		var idx: int = mod_option.get_selected()
		if idx >= 0:
			_reload_frame_data_for_mod(idx)
	else:
		if box_editor_instance != null and box_editor_instance.has_method("reload_current"):
			box_editor_instance.call("reload_current")


func _on_save_pressed() -> void:
	var section_id: int = section_option.get_selected()
	if section_id == 1:
		if json_editor_instance != null and json_editor_instance.has_method("save_current"):
			json_editor_instance.call("save_current")
	elif section_id == 2:
		_on_state_maker_apply_pressed()
		_save_state_maker_file()
	elif section_id == 3:
		_on_apply_command_pressed()
		_save_commands_file()
	elif section_id == 4:
		status_label.text = "Command Tester is runtime-only. Use Playtest to validate in battle."
	elif section_id == 5:
		status_label.text = "Frame Data is derived from states.json."
	else:
		if box_editor_instance != null and box_editor_instance.has_method("save_current"):
			box_editor_instance.call("save_current")


func _on_back_pressed() -> void:
	get_tree().set_meta("character_editor_section", "boxes")
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")


func _normalize_root(root: String) -> String:
	var normalized: String = root.strip_edges()
	if normalized.is_empty():
		return ""
	if not normalized.ends_with("/"):
		normalized += "/"
	return normalized


func _fit_embedded_editor_to_host(editor_control: Control) -> void:
	if editor_control == null:
		return
	editor_control.layout_mode = 1
	editor_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_control.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _reload_state_maker_for_mod(index: int) -> void:
	state_maker_data = {}
	current_state_maker_path = ""
	selected_state_maker_key = ""
	state_maker_mod_path = ""
	state_maker_option.clear()
	_clear_state_maker_form()
	if index < 0 or index >= mod_entries.size():
		return
	var mod_path: String = str(mod_entries[index].get("path", ""))
	if mod_path.is_empty():
		return
	state_maker_mod_path = mod_path
	current_state_maker_path = "%sstates.json" % mod_path
	if FileAccess.file_exists(current_state_maker_path):
		var file := FileAccess.open(current_state_maker_path, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				state_maker_data = (parsed as Dictionary).duplicate(true)
	_reload_state_maker_animation_options()
	_build_state_maker_preset_options()
	_rebuild_state_maker_option()


func _rebuild_state_maker_option() -> void:
	state_maker_option.clear()
	var keys: Array = state_maker_data.keys()
	keys.sort()
	for i in range(keys.size()):
		state_maker_option.add_item(str(keys[i]), i)
	if state_maker_option.item_count <= 0:
		state_maker_option.disabled = true
		selected_state_maker_key = ""
		_clear_state_maker_form()
		return
	state_maker_option.disabled = false
	state_maker_option.select(0)
	_on_state_maker_selected(0)


func _on_state_maker_selected(_index: int) -> void:
	if state_maker_option.item_count <= 0:
		selected_state_maker_key = ""
		_clear_state_maker_form()
		return
	var state_id: String = state_maker_option.get_item_text(state_maker_option.get_selected())
	if state_id.is_empty() or not state_maker_data.has(state_id):
		selected_state_maker_key = ""
		_clear_state_maker_form()
		return
	selected_state_maker_key = state_id
	var state_data: Dictionary = state_maker_data.get(state_id, {})
	_apply_state_maker_to_form(state_id, state_data)


func _on_state_maker_add_pressed() -> void:
	var base_id: String = "new_state"
	var candidate: String = base_id
	var idx: int = 1
	while state_maker_data.has(candidate):
		idx += 1
		candidate = "%s_%d" % [base_id, idx]
	state_maker_data[candidate] = {
		"animation": "",
		"allow_movement": false,
		"cancel_into": [],
		"hitboxes": [],
		"throwboxes": [],
		"pushboxes": [],
		"next": {}
	}
	_rebuild_state_maker_option()
	for i in range(state_maker_option.item_count):
		if state_maker_option.get_item_text(i) == candidate:
			state_maker_option.select(i)
			_on_state_maker_selected(i)
			break
	status_label.text = "Added state %s." % candidate


func _on_state_maker_delete_pressed() -> void:
	if selected_state_maker_key.is_empty() or not state_maker_data.has(selected_state_maker_key):
		return
	state_maker_data.erase(selected_state_maker_key)
	selected_state_maker_key = ""
	_rebuild_state_maker_option()
	status_label.text = "Deleted state."


func _on_state_maker_apply_pressed() -> void:
	if selected_state_maker_key.is_empty() or not state_maker_data.has(selected_state_maker_key):
		return
	var old_id: String = selected_state_maker_key
	var new_id: String = state_maker_id_edit.text.strip_edges()
	if new_id.is_empty():
		status_label.text = "State id cannot be empty."
		return
	var state_data: Dictionary = state_maker_data.get(old_id, {})
	state_data["animation"] = state_maker_animation_edit.text.strip_edges()
	state_data["allow_movement"] = state_maker_allow_movement_check.button_pressed
	state_data["cancel_into"] = _parse_state_maker_cancel_into(state_maker_cancel_into_edit.text)
	var cancel_windows_parse: Dictionary = _parse_state_maker_json_array_field(state_maker_cancel_windows_edit.text, "cancel_windows")
	if not bool(cancel_windows_parse.get("ok", false)):
		return
	state_data["cancel_windows"] = cancel_windows_parse.get("value", [])
	state_data["controllers"] = state_maker_controllers_lane.duplicate(true)
	state_data["sounds"] = state_maker_sounds_lane.duplicate(true)
	state_data["projectiles"] = state_maker_projectiles_lane.duplicate(true)
	var next_id: String = state_maker_next_id_edit.text.strip_edges()
	if next_id.is_empty():
		state_data["next"] = {}
	else:
		state_data["next"] = {"frame": int(state_maker_next_frame_spin.value), "id": next_id}
	if new_id != old_id:
		state_maker_data.erase(old_id)
	state_maker_data[new_id] = state_data
	selected_state_maker_key = new_id
	_rebuild_state_maker_option()
	for i in range(state_maker_option.item_count):
		if state_maker_option.get_item_text(i) == new_id:
			state_maker_option.select(i)
			_on_state_maker_selected(i)
			break
	status_label.text = "Applied state values."


func _apply_state_maker_to_form(state_id: String, state_data: Dictionary) -> void:
	state_maker_id_edit.text = state_id
	state_maker_animation_edit.text = str(state_data.get("animation", ""))
	state_maker_allow_movement_check.button_pressed = bool(state_data.get("allow_movement", false))
	var cancel_into: Array = state_data.get("cancel_into", [])
	var cancel_text: PackedStringArray = []
	for entry in cancel_into:
		cancel_text.append(str(entry))
	state_maker_cancel_into_edit.text = ",".join(cancel_text)
	state_maker_cancel_windows_edit.text = str(state_data.get("cancel_windows", []))
	var next_data: Dictionary = state_data.get("next", {})
	state_maker_next_frame_spin.value = float(next_data.get("frame", 0))
	state_maker_next_id_edit.text = str(next_data.get("id", ""))
	state_maker_controllers_lane = (state_data.get("controllers", []) as Array).duplicate(true)
	state_maker_sounds_lane = (state_data.get("sounds", []) as Array).duplicate(true)
	state_maker_projectiles_lane = (state_data.get("projectiles", []) as Array).duplicate(true)
	_refresh_state_maker_controllers_lane_list()
	_refresh_state_maker_sounds_lane_list()
	_refresh_state_maker_projectiles_lane_list()
	_sync_state_maker_lane_text_fields()
	_select_state_maker_animation(state_maker_animation_edit.text)
	_update_state_maker_timeline_text(state_data)


func _clear_state_maker_form() -> void:
	state_maker_id_edit.text = ""
	state_maker_animation_edit.text = ""
	state_maker_allow_movement_check.button_pressed = false
	state_maker_cancel_into_edit.text = ""
	state_maker_cancel_windows_edit.text = ""
	state_maker_next_frame_spin.value = 0
	state_maker_next_id_edit.text = ""
	state_maker_controllers_lane = []
	state_maker_sounds_lane = []
	state_maker_projectiles_lane = []
	_refresh_state_maker_controllers_lane_list()
	_refresh_state_maker_sounds_lane_list()
	_refresh_state_maker_projectiles_lane_list()
	_sync_state_maker_lane_text_fields()
	state_maker_timeline_text.text = "No state selected."


func _parse_state_maker_cancel_into(text: String) -> Array:
	var raw: String = text.strip_edges()
	if raw.is_empty():
		return []
	var parsed = JSON.parse_string(raw)
	if parsed is Array:
		return parsed as Array
	var out: Array = []
	var parts: PackedStringArray = raw.split(",", false)
	for part in parts:
		var value: String = str(part).strip_edges()
		if not value.is_empty():
			out.append(value)
	return out


func _parse_state_maker_json_array_field(text: String, field_name: String) -> Dictionary:
	var raw: String = text.strip_edges()
	if raw.is_empty():
		return {"ok": true, "value": []}
	var parsed = JSON.parse_string(raw)
	if parsed is Array:
		return {"ok": true, "value": parsed as Array}
	status_label.text = "Invalid JSON array for %s." % field_name
	return {"ok": false, "value": []}


func _save_state_maker_file() -> void:
	if current_state_maker_path.is_empty():
		status_label.text = "No states.json path for selected mod."
		return
	var file := FileAccess.open(current_state_maker_path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Failed to save states.json."
		return
	file.store_string(JSON.stringify(state_maker_data, "\t"))
	var idx: int = mod_option.get_selected()
	if idx >= 0:
		_reload_frame_data_for_mod(idx)
	status_label.text = "Saved %s" % current_state_maker_path


func _on_state_maker_refresh_animations_pressed() -> void:
	_reload_state_maker_animation_options()
	status_label.text = "Animation list refreshed."


func _on_state_maker_use_animation_pressed() -> void:
	if state_maker_animation_option.item_count <= 0:
		return
	var idx: int = state_maker_animation_option.get_selected()
	if idx < 0 or idx >= state_maker_animation_option.item_count:
		return
	state_maker_animation_edit.text = state_maker_animation_option.get_item_text(idx)


func _on_state_maker_add_preset_pressed() -> void:
	if selected_state_maker_key.is_empty() or not state_maker_data.has(selected_state_maker_key):
		status_label.text = "Select a state first."
		return
	if state_maker_preset_option.item_count <= 0:
		return
	var preset_id: String = state_maker_preset_option.get_item_text(state_maker_preset_option.get_selected())
	var state_data: Dictionary = state_maker_data.get(selected_state_maker_key, {})
	var controllers: Array = state_data.get("controllers", [])
	match preset_id:
		"CtrlSet On":
			controllers.append({"type": "CtrlSet", "value": 1, "trigger1": "time = 0", "persistent": 0})
		"ChangeState -> idle":
			controllers.append({"type": "ChangeState", "value": "idle", "trigger1": "time >= 20"})
		"VelSet Forward":
			controllers.append({"type": "VelSet", "x": 2.0, "y": 0.0, "z": 0.0, "trigger1": "time = 0", "persistent": 0})
		"PlaySnd Swing":
			controllers.append({"type": "PlaySnd", "id": "swing_light", "channel": "sfx", "trigger1": "time = 1", "persistent": 0})
		"Pause On Hit":
			controllers.append({"type": "Pause", "time": 6, "trigger1": "movehit = 1", "persistent": 0})
	state_data["controllers"] = controllers
	state_maker_data[selected_state_maker_key] = state_data
	_apply_state_maker_to_form(selected_state_maker_key, state_data)
	status_label.text = "Added controller preset."


func _build_state_maker_preset_options() -> void:
	state_maker_preset_option.clear()
	state_maker_preset_option.add_item("CtrlSet On")
	state_maker_preset_option.add_item("ChangeState -> idle")
	state_maker_preset_option.add_item("VelSet Forward")
	state_maker_preset_option.add_item("PlaySnd Swing")
	state_maker_preset_option.add_item("Pause On Hit")
	state_maker_preset_option.select(0)


func _build_state_maker_controller_type_options() -> void:
	state_maker_controller_type_option.clear()
	for type_name in [
		"ChangeState",
		"CtrlSet",
		"VelSet",
		"PlaySnd",
		"Pause",
		"Explod",
		"HitDef",
		"AssertSpecial",
		"VarSet",
		"PowerAdd",
		"StateTypeSet"
	]:
		state_maker_controller_type_option.add_item(type_name)
	if state_maker_controller_type_option.item_count > 0:
		state_maker_controller_type_option.select(0)


func _refresh_state_maker_sounds_lane_list() -> void:
	state_maker_sounds_lane_list.clear()
	for i in range(state_maker_sounds_lane.size()):
		var entry: Dictionary = state_maker_sounds_lane[i] if typeof(state_maker_sounds_lane[i]) == TYPE_DICTIONARY else {}
		var frame: int = int(entry.get("frame", 0))
		var sound_id: String = str(entry.get("id", ""))
		var channel: String = str(entry.get("channel", "sfx"))
		state_maker_sounds_lane_list.add_item("%03d  %s  [%s]" % [frame, sound_id, channel])


func _refresh_state_maker_projectiles_lane_list() -> void:
	state_maker_projectiles_lane_list.clear()
	for i in range(state_maker_projectiles_lane.size()):
		var entry: Dictionary = state_maker_projectiles_lane[i] if typeof(state_maker_projectiles_lane[i]) == TYPE_DICTIONARY else {}
		var frame: int = int(entry.get("frame", 0))
		var projectile_id: String = str(entry.get("id", ""))
		state_maker_projectiles_lane_list.add_item("%03d  %s" % [frame, projectile_id])


func _refresh_state_maker_controllers_lane_list() -> void:
	state_maker_controllers_lane_list.clear()
	for i in range(state_maker_controllers_lane.size()):
		var entry: Dictionary = state_maker_controllers_lane[i] if typeof(state_maker_controllers_lane[i]) == TYPE_DICTIONARY else {}
		var controller_type: String = str(entry.get("type", "Controller"))
		var trigger1: String = str(entry.get("trigger1", ""))
		if trigger1.is_empty():
			state_maker_controllers_lane_list.add_item("%s" % controller_type)
		else:
			state_maker_controllers_lane_list.add_item("%s  when %s" % [controller_type, trigger1])


func _sync_state_maker_lane_text_fields() -> void:
	state_maker_controllers_text.text = JSON.stringify(state_maker_controllers_lane, "\t")
	state_maker_sounds_text.text = JSON.stringify(state_maker_sounds_lane, "\t")
	state_maker_projectiles_text.text = JSON.stringify(state_maker_projectiles_lane, "\t")


func _on_state_maker_sound_lane_selected(index: int) -> void:
	if index < 0 or index >= state_maker_sounds_lane.size():
		return
	var entry: Dictionary = state_maker_sounds_lane[index] if typeof(state_maker_sounds_lane[index]) == TYPE_DICTIONARY else {}
	state_maker_sound_frame_spin.value = float(entry.get("frame", 0))
	state_maker_sound_id_edit.text = str(entry.get("id", ""))
	state_maker_sound_channel_edit.text = str(entry.get("channel", "sfx"))


func _on_state_maker_add_update_sound_pressed() -> void:
	var sound_id: String = state_maker_sound_id_edit.text.strip_edges()
	if sound_id.is_empty():
		status_label.text = "Sound id is required."
		return
	var entry: Dictionary = {
		"frame": int(state_maker_sound_frame_spin.value),
		"id": sound_id,
		"channel": state_maker_sound_channel_edit.text.strip_edges() if not state_maker_sound_channel_edit.text.strip_edges().is_empty() else "sfx"
	}
	var selected: int = state_maker_sounds_lane_list.get_selected_items()[0] if state_maker_sounds_lane_list.get_selected_items().size() > 0 else -1
	if selected >= 0 and selected < state_maker_sounds_lane.size():
		state_maker_sounds_lane[selected] = entry
	else:
		state_maker_sounds_lane.append(entry)
	_refresh_state_maker_sounds_lane_list()
	_sync_state_maker_lane_text_fields()
	status_label.text = "Sound lane updated."


func _on_state_maker_delete_sound_pressed() -> void:
	var selected: int = state_maker_sounds_lane_list.get_selected_items()[0] if state_maker_sounds_lane_list.get_selected_items().size() > 0 else -1
	if selected < 0 or selected >= state_maker_sounds_lane.size():
		return
	state_maker_sounds_lane.remove_at(selected)
	_refresh_state_maker_sounds_lane_list()
	_sync_state_maker_lane_text_fields()
	status_label.text = "Sound lane row removed."


func _on_state_maker_projectile_lane_selected(index: int) -> void:
	if index < 0 or index >= state_maker_projectiles_lane.size():
		return
	var entry: Dictionary = state_maker_projectiles_lane[index] if typeof(state_maker_projectiles_lane[index]) == TYPE_DICTIONARY else {}
	state_maker_projectile_frame_spin.value = float(entry.get("frame", 0))
	state_maker_projectile_id_edit.text = str(entry.get("id", ""))


func _on_state_maker_add_update_projectile_pressed() -> void:
	var projectile_id: String = state_maker_projectile_id_edit.text.strip_edges()
	if projectile_id.is_empty():
		status_label.text = "Projectile id is required."
		return
	var entry: Dictionary = {
		"frame": int(state_maker_projectile_frame_spin.value),
		"id": projectile_id
	}
	var selected: int = state_maker_projectiles_lane_list.get_selected_items()[0] if state_maker_projectiles_lane_list.get_selected_items().size() > 0 else -1
	if selected >= 0 and selected < state_maker_projectiles_lane.size():
		state_maker_projectiles_lane[selected] = entry
	else:
		state_maker_projectiles_lane.append(entry)
	_refresh_state_maker_projectiles_lane_list()
	_sync_state_maker_lane_text_fields()
	status_label.text = "Projectile lane updated."


func _on_state_maker_delete_projectile_pressed() -> void:
	var selected: int = state_maker_projectiles_lane_list.get_selected_items()[0] if state_maker_projectiles_lane_list.get_selected_items().size() > 0 else -1
	if selected < 0 or selected >= state_maker_projectiles_lane.size():
		return
	state_maker_projectiles_lane.remove_at(selected)
	_refresh_state_maker_projectiles_lane_list()
	_sync_state_maker_lane_text_fields()
	status_label.text = "Projectile lane row removed."


func _on_state_maker_controller_lane_selected(index: int) -> void:
	if index < 0 or index >= state_maker_controllers_lane.size():
		return
	var entry: Dictionary = state_maker_controllers_lane[index] if typeof(state_maker_controllers_lane[index]) == TYPE_DICTIONARY else {}
	var controller_type: String = str(entry.get("type", "ChangeState"))
	for i in range(state_maker_controller_type_option.item_count):
		if state_maker_controller_type_option.get_item_text(i) == controller_type:
			state_maker_controller_type_option.select(i)
			break
	state_maker_controller_trigger_edit.text = str(entry.get("trigger1", ""))
	var params: Dictionary = entry.duplicate(true)
	params.erase("type")
	params.erase("trigger1")
	state_maker_controller_params_edit.text = JSON.stringify(params)


func _on_state_maker_add_update_controller_pressed() -> void:
	var controller_type: String = state_maker_controller_type_option.get_item_text(state_maker_controller_type_option.get_selected())
	if controller_type.is_empty():
		status_label.text = "Controller type is required."
		return
	var entry: Dictionary = {"type": controller_type}
	var trigger1: String = state_maker_controller_trigger_edit.text.strip_edges()
	if not trigger1.is_empty():
		entry["trigger1"] = trigger1
	var params_text: String = state_maker_controller_params_edit.text.strip_edges()
	if not params_text.is_empty():
		var parsed = JSON.parse_string(params_text)
		if typeof(parsed) != TYPE_DICTIONARY:
			status_label.text = "Controller params must be a JSON object."
			return
		for key in (parsed as Dictionary).keys():
			entry[str(key)] = (parsed as Dictionary)[key]
	var selected: int = state_maker_controllers_lane_list.get_selected_items()[0] if state_maker_controllers_lane_list.get_selected_items().size() > 0 else -1
	if selected >= 0 and selected < state_maker_controllers_lane.size():
		state_maker_controllers_lane[selected] = entry
	else:
		state_maker_controllers_lane.append(entry)
	_refresh_state_maker_controllers_lane_list()
	_sync_state_maker_lane_text_fields()
	status_label.text = "Controller lane updated."


func _on_state_maker_delete_controller_pressed() -> void:
	var selected: int = state_maker_controllers_lane_list.get_selected_items()[0] if state_maker_controllers_lane_list.get_selected_items().size() > 0 else -1
	if selected < 0 or selected >= state_maker_controllers_lane.size():
		return
	state_maker_controllers_lane.remove_at(selected)
	_refresh_state_maker_controllers_lane_list()
	_sync_state_maker_lane_text_fields()
	status_label.text = "Controller lane row removed."


func _reload_state_maker_animation_options() -> void:
	state_maker_animation_option.clear()
	state_maker_animation_names.clear()
	var from_states: Dictionary = {}
	for key in state_maker_data.keys():
		var st = state_maker_data.get(key, {})
		if typeof(st) != TYPE_DICTIONARY:
			continue
		var anim_name: String = str((st as Dictionary).get("animation", "")).strip_edges()
		if not anim_name.is_empty():
			from_states[anim_name] = true
	for anim_key in from_states.keys():
		state_maker_animation_names.append(str(anim_key))
	var model_anims: Array[String] = _collect_model_animation_names_for_state_maker(state_maker_mod_path)
	for anim_name in model_anims:
		if not state_maker_animation_names.has(anim_name):
			state_maker_animation_names.append(anim_name)
	state_maker_animation_names.sort()
	for i in range(state_maker_animation_names.size()):
		state_maker_animation_option.add_item(state_maker_animation_names[i], i)
	if state_maker_animation_option.item_count <= 0:
		state_maker_animation_option.add_item("<no animations found>")
		state_maker_animation_option.disabled = true
	else:
		state_maker_animation_option.disabled = false
		state_maker_animation_option.select(0)


func _select_state_maker_animation(animation_name: String) -> void:
	if animation_name.is_empty():
		return
	for i in range(state_maker_animation_option.item_count):
		if state_maker_animation_option.get_item_text(i) == animation_name:
			state_maker_animation_option.select(i)
			return


func _collect_model_animation_names_for_state_maker(mod_path: String) -> Array[String]:
	var out: Array[String] = []
	if mod_path.is_empty():
		return out
	var model_path: String = _find_model_path_for_state_maker(mod_path)
	if model_path.is_empty():
		return out
	var scene: Node = _load_model_scene_for_state_maker(model_path)
	if scene == null:
		return out
	var anim_player: AnimationPlayer = _find_animation_player_recursive_for_state_maker(scene)
	if anim_player != null:
		for name in anim_player.get_animation_list():
			out.append(str(name))
	scene.queue_free()
	return out


func _find_model_path_for_state_maker(mod_path: String) -> String:
	var def_data: Dictionary = _load_def_for_state_maker("%scharacter.def" % mod_path)
	var raw_path: String = str(def_data.get("model_path", def_data.get("model_file", ""))).strip_edges()
	if not raw_path.is_empty():
		if raw_path.begins_with("res://") or raw_path.begins_with("user://"):
			return raw_path
		return "%s%s" % [mod_path, raw_path]
	for file_name in ["model.glb", "model.gltf"]:
		var candidate: String = "%s%s" % [mod_path, file_name]
		if FileAccess.file_exists(candidate):
			return candidate
	return ""


func _load_def_for_state_maker(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var out: Dictionary = {}
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with(";") or line.begins_with("#"):
			continue
		var split: PackedStringArray = line.split("=", false, 1)
		if split.size() == 2:
			out[split[0].strip_edges()] = split[1].strip_edges()
	return out


func _load_model_scene_for_state_maker(path: String) -> Node:
	var lower: String = path.to_lower()
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


func _find_animation_player_recursive_for_state_maker(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found: AnimationPlayer = _find_animation_player_recursive_for_state_maker(child)
		if found != null:
			return found
	return null


func _update_state_maker_timeline_text(state_data: Dictionary) -> void:
	var lines: PackedStringArray = []
	lines.append("[b]Timeline Overview[/b]")
	var animation_name: String = str(state_data.get("animation", ""))
	lines.append("Animation: %s" % animation_name)
	var hitboxes: Array = state_data.get("hitboxes", [])
	var throwboxes: Array = state_data.get("throwboxes", [])
	var sounds: Array = state_data.get("sounds", [])
	var projectiles: Array = state_data.get("projectiles", [])
	var controllers: Array = state_data.get("controllers", [])
	lines.append("Hitboxes: %d | Throwboxes: %d" % [hitboxes.size(), throwboxes.size()])
	lines.append("Sounds: %d | Projectiles: %d | Controllers: %d" % [sounds.size(), projectiles.size(), controllers.size()])
	var next_data: Dictionary = state_data.get("next", {})
	if not next_data.is_empty():
		lines.append("Next: frame %s -> %s" % [str(next_data.get("frame", "-")), str(next_data.get("id", "-"))])
	var cancel_windows = state_data.get("cancel_windows", [])
	lines.append("Cancel Windows: %s" % str(cancel_windows))
	state_maker_timeline_text.text = "\n".join(lines)


func _reload_commands_for_mod(index: int) -> void:
	command_option.clear()
	commands_data = {"commands": []}
	current_commands_path = ""
	_clear_command_form()
	if index < 0 or index >= mod_entries.size():
		return
	var mod_path: String = str(mod_entries[index].get("path", ""))
	if mod_path.is_empty():
		return
	current_commands_path = "%scommands.json" % mod_path
	if FileAccess.file_exists(current_commands_path):
		var file := FileAccess.open(current_commands_path, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				commands_data = parsed as Dictionary
	if not commands_data.has("commands") or typeof(commands_data.get("commands", [])) != TYPE_ARRAY:
		commands_data["commands"] = []
	_rebuild_command_option()


func _rebuild_command_option() -> void:
	command_option.clear()
	var entries: Array = commands_data.get("commands", [])
	for i in range(entries.size()):
		if typeof(entries[i]) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entries[i]
		var command_id: String = str(entry.get("id", "command_%d" % i))
		var pattern: Array = entry.get("pattern", [])
		command_option.add_item("%s  %s" % [command_id, str(pattern)], i)
	if command_option.item_count > 0:
		command_option.disabled = false
		command_option.select(0)
		_on_command_selected(0)
	else:
		command_option.disabled = true
		_clear_command_form()


func _on_command_selected(_index: int) -> void:
	var selected: int = command_option.get_selected()
	var entries: Array = commands_data.get("commands", [])
	if selected < 0 or selected >= entries.size() or typeof(entries[selected]) != TYPE_DICTIONARY:
		_clear_command_form()
		return
	_apply_command_to_form(entries[selected] as Dictionary)


func _on_add_command_pressed() -> void:
	var entries: Array = commands_data.get("commands", [])
	var new_entry: Dictionary = {
		"id": "new_command_%d" % (entries.size() + 1),
		"pattern": ["P"],
		"max_window": 8,
		"min_repeat_frames": 8,
		"target_state": ""
	}
	entries.append(new_entry)
	commands_data["commands"] = entries
	_rebuild_command_option()
	command_option.select(entries.size() - 1)
	_on_command_selected(entries.size() - 1)
	status_label.text = "Added command entry."


func _on_delete_command_pressed() -> void:
	var selected: int = command_option.get_selected()
	var entries: Array = commands_data.get("commands", [])
	if selected < 0 or selected >= entries.size():
		return
	entries.remove_at(selected)
	commands_data["commands"] = entries
	_rebuild_command_option()
	status_label.text = "Deleted command entry."


func _on_apply_command_pressed() -> void:
	var selected: int = command_option.get_selected()
	var entries: Array = commands_data.get("commands", [])
	if selected < 0 or selected >= entries.size() or typeof(entries[selected]) != TYPE_DICTIONARY:
		return
	var entry: Dictionary = entries[selected]
	entry["id"] = command_id_edit.text.strip_edges()
	entry["pattern"] = _parse_pattern_text(command_pattern_edit.text)
	entry["max_window"] = int(command_max_window_spin.value)
	entry["min_repeat_frames"] = int(command_min_repeat_spin.value)
	var target_state: String = command_target_state_edit.text.strip_edges()
	if target_state.is_empty():
		entry.erase("target_state")
	else:
		entry["target_state"] = target_state
	var transform_to: String = command_transform_to_edit.text.strip_edges()
	if transform_to.is_empty():
		entry.erase("transform_to")
	else:
		entry["transform_to"] = transform_to
	var transform_state: String = command_transform_state_edit.text.strip_edges()
	if transform_state.is_empty():
		entry.erase("transform_state")
	else:
		entry["transform_state"] = transform_state
	if command_revert_transform_check.button_pressed:
		entry["revert_transform"] = true
	else:
		entry.erase("revert_transform")
	entries[selected] = entry
	commands_data["commands"] = entries
	_rebuild_command_option()
	command_option.select(selected)
	status_label.text = "Applied command values."


func _apply_command_to_form(entry: Dictionary) -> void:
	command_id_edit.text = str(entry.get("id", ""))
	command_pattern_edit.text = str(entry.get("pattern", ["P"]))
	command_max_window_spin.value = float(entry.get("max_window", 8))
	command_min_repeat_spin.value = float(entry.get("min_repeat_frames", 8))
	command_target_state_edit.text = str(entry.get("target_state", ""))
	command_transform_to_edit.text = str(entry.get("transform_to", ""))
	command_transform_state_edit.text = str(entry.get("transform_state", ""))
	command_revert_transform_check.button_pressed = bool(entry.get("revert_transform", false))


func _clear_command_form() -> void:
	command_id_edit.text = ""
	command_pattern_edit.text = ""
	command_max_window_spin.value = 8
	command_min_repeat_spin.value = 8
	command_target_state_edit.text = ""
	command_transform_to_edit.text = ""
	command_transform_state_edit.text = ""
	command_revert_transform_check.button_pressed = false


func _parse_pattern_text(text: String) -> Array:
	var raw: String = text.strip_edges()
	if raw.is_empty():
		return ["P"]
	var parsed = JSON.parse_string(raw)
	if parsed is Array:
		return parsed as Array
	var compact: String = raw
	if compact.begins_with("[") and compact.ends_with("]") and compact.length() >= 2:
		compact = compact.substr(1, compact.length() - 2)
	var out: Array = []
	var parts: PackedStringArray = compact.split(",", false)
	for part in parts:
		var token: String = str(part).strip_edges()
		if token.is_empty():
			continue
		if (token.begins_with("\"") and token.ends_with("\"")) or (token.begins_with("'") and token.ends_with("'")):
			token = token.substr(1, token.length() - 2)
		if token.is_valid_int():
			out.append(int(token))
		else:
			out.append(token)
	if out.is_empty():
		out.append("P")
	return out


func _save_commands_file() -> void:
	if current_commands_path.is_empty():
		status_label.text = "No commands.json path for selected mod."
		return
	var file := FileAccess.open(current_commands_path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Failed to save commands.json."
		return
	file.store_string(JSON.stringify(commands_data, "\t"))
	status_label.text = "Saved %s" % current_commands_path


func _process(_delta: float) -> void:
	if preview_host == null or not preview_host.visible:
		return
	if preview_command_interpreter == null:
		return
	var latest_dir: Vector2 = preview_command_interpreter.get_latest_raw_direction()
	var facing_label: String = "Facing: Right" if preview_command_interpreter.get_facing_right() else "Facing: Left"
	preview_input_label.text = "Dir: (%.2f, %.2f) | %s" % [latest_dir.x, latest_dir.y, facing_label]
	var buffer_snapshot: Array[Dictionary] = preview_command_interpreter.get_buffer_snapshot()
	var buffer_hash: int = buffer_snapshot.hash()
	if buffer_hash == preview_last_buffer_hash:
		return
	preview_last_buffer_hash = buffer_hash
	_refresh_preview_buffer_text(buffer_snapshot)


func _apply_initial_section_from_meta() -> void:
	var section: String = str(get_tree().get_meta("character_editor_section", "boxes")).to_lower()
	if section == "files":
		section_option.select(1)
	elif section == "states":
		section_option.select(2)
	elif section == "commands":
		section_option.select(3)
	elif section == "preview":
		section_option.select(4)
	elif section == "framedata":
		section_option.select(5)
	else:
		section_option.select(0)


func _setup_preview_tools() -> void:
	preview_command_interpreter = CommandInterpreter.new()
	preview_command_interpreter.name = "EditorCommandInterpreter"
	preview_command_interpreter.read_local_input = true
	preview_command_interpreter.command_matched.connect(_on_preview_command_matched)
	add_child(preview_command_interpreter)
	preview_match_label.text = "Last Match: -"
	preview_input_label.text = "Dir: (0.00, 0.00) | Facing: Right"
	preview_buffer_text.text = "Input buffer is empty."


func _reload_preview_tools_for_mod(index: int) -> void:
	preview_command_option.clear()
	preview_commands_data = {}
	if index < 0 or index >= mod_entries.size():
		preview_match_label.text = "Last Match: -"
		return
	var mod_path: String = str(mod_entries[index].get("path", ""))
	if mod_path.is_empty():
		preview_match_label.text = "Last Match: -"
		return
	var commands_path: String = "%scommands.json" % mod_path
	if FileAccess.file_exists(commands_path):
		var file := FileAccess.open(commands_path, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				preview_commands_data = parsed as Dictionary
	if preview_command_interpreter != null:
		preview_command_interpreter.set_command_data(preview_commands_data)
	preview_match_label.text = "Last Match: -"
	var entries: Array = []
	if preview_commands_data.has("commands") and preview_commands_data.get("commands", []) is Array:
		entries = preview_commands_data.get("commands", [])
	for i in range(entries.size()):
		if typeof(entries[i]) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entries[i]
		var command_id: String = str(entry.get("id", "command_%d" % i))
		var pattern: Array = entry.get("pattern", [])
		preview_command_option.add_item("%s  %s" % [command_id, str(pattern)], i)
	if preview_command_option.item_count == 0:
		preview_command_option.add_item("No commands found", -1)
		preview_command_option.disabled = true
	else:
		preview_command_option.disabled = false
		preview_command_option.select(0)


func _refresh_preview_buffer_text(buffer_snapshot: Array[Dictionary]) -> void:
	if buffer_snapshot.is_empty():
		preview_buffer_text.text = "Input buffer is empty."
		return
	var lines: PackedStringArray = []
	var start_idx: int = maxi(0, buffer_snapshot.size() - 12)
	for i in range(start_idx, buffer_snapshot.size()):
		var frame_data: Dictionary = buffer_snapshot[i]
		var dir_num: int = int(frame_data.get("direction", 5))
		var pressed: Array = frame_data.get("pressed", [])
		var held: Array = frame_data.get("held", [])
		var released: Array = frame_data.get("released", [])
		lines.append(
			"#%d  d:%d  p:%s  h:%s  r:%s"
			% [int(frame_data.get("frame_index", i)), dir_num, str(pressed), str(held), str(released)]
		)
	preview_buffer_text.text = "\n".join(lines)


func _on_preview_command_selected(_index: int) -> void:
	preview_match_label.text = "Last Match: -"


func _on_preview_command_matched(command_id: String, _entry: Dictionary) -> void:
	preview_match_label.text = "Last Match: %s @ frame %d" % [command_id, preview_command_interpreter.get_last_matched_command_frame()]


func _on_preview_playtest_pressed() -> void:
	var idx: int = mod_option.get_selected()
	if idx < 0 or idx >= mod_entries.size():
		status_label.text = "Select a mod first."
		return
	var p1_mod: String = str(mod_entries[idx].get("name", ""))
	if p1_mod.is_empty():
		status_label.text = "Selected mod is invalid."
		return
	var p2_mod: String = "sample_fighter"
	if p2_mod == p1_mod:
		p2_mod = _first_other_mod_name(p1_mod)
	get_tree().set_meta("game_mode", "training")
	get_tree().set_meta("training_p1_mod", p1_mod)
	get_tree().set_meta("training_p2_mod", p2_mod)
	get_tree().set_meta("training_p1_form", "")
	get_tree().set_meta("training_p2_form", "")
	get_tree().set_meta("training_p1_costume", "")
	get_tree().set_meta("training_p2_costume", "")
	get_tree().change_scene_to_file(playtest_scene_path)


func _first_other_mod_name(exclude_name: String) -> String:
	for entry in mod_entries:
		var name_value: String = str((entry as Dictionary).get("name", ""))
		if not name_value.is_empty() and name_value != exclude_name:
			return name_value
	return exclude_name


func _reload_frame_data_for_mod(index: int) -> void:
	frame_states_data = {}
	frame_state_option.clear()
	if index < 0 or index >= mod_entries.size():
		frame_data_text.text = "No mod selected."
		return
	var mod_path: String = str(mod_entries[index].get("path", ""))
	if mod_path.is_empty():
		frame_data_text.text = "Invalid mod path."
		return
	var states_path: String = "%sstates.json" % mod_path
	if not FileAccess.file_exists(states_path):
		frame_data_text.text = "No states.json found."
		return
	var file := FileAccess.open(states_path, FileAccess.READ)
	if file == null:
		frame_data_text.text = "Could not open states.json."
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		frame_data_text.text = "states.json is invalid."
		return
	frame_states_data = parsed as Dictionary
	var state_ids: Array = frame_states_data.keys()
	state_ids.sort()
	for i in range(state_ids.size()):
		frame_state_option.add_item(str(state_ids[i]), i)
	if frame_state_option.get_item_count() == 0:
		frame_data_text.text = "No states found."
		return
	frame_state_option.select(0)
	_on_frame_state_selected(0)


func _on_frame_state_selected(_index: int) -> void:
	if frame_state_option.get_item_count() == 0:
		frame_data_text.text = "No state selected."
		return
	var state_id: String = frame_state_option.get_item_text(frame_state_option.get_selected())
	if state_id.is_empty() or not frame_states_data.has(state_id):
		frame_data_text.text = "State data missing."
		return
	var state_data: Dictionary = frame_states_data.get(state_id, {})
	var hitboxes: Array = state_data.get("hitboxes", [])
	var next_info: Dictionary = state_data.get("next", {})
	var total_frames: int = int(next_info.get("frame", -1))

	var startup: int = -1
	var active_start: int = -1
	var active_end: int = -1
	for entry in hitboxes:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var s: int = int((entry as Dictionary).get("start", -1))
		var e: int = int((entry as Dictionary).get("end", -1))
		if s >= 0 and (active_start < 0 or s < active_start):
			active_start = s
		if e >= 0 and e > active_end:
			active_end = e
	startup = active_start
	var recovery: int = -1
	if total_frames >= 0 and active_end >= 0:
		recovery = maxi(0, total_frames - active_end - 1)

	var lines: PackedStringArray = []
	lines.append("[b]%s[/b]" % state_id)
	lines.append("Animation: %s" % str(state_data.get("animation", "")))
	lines.append("Startup: %s" % ("-" if startup < 0 else str(startup)))
	lines.append("Active: %s" % ("-" if active_start < 0 else ("%d-%d" % [active_start, maxi(active_start, active_end)])))
	lines.append("Recovery: %s" % ("-" if recovery < 0 else str(recovery)))
	lines.append("Total: %s" % ("-" if total_frames < 0 else str(total_frames)))
	lines.append("Hitboxes: %d | Persistent hurtboxes are edited in Box Tools." % hitboxes.size())
	if state_data.has("cancel_into"):
		lines.append("Cancel Into: %s" % str(state_data.get("cancel_into", [])))
	for i in range(hitboxes.size()):
		if typeof(hitboxes[i]) != TYPE_DICTIONARY:
			continue
		var hb: Dictionary = hitboxes[i]
		var hb_id: String = str(hb.get("id", "hitbox_%d" % i))
		var hb_start: int = int(hb.get("start", -1))
		var hb_end: int = int(hb.get("end", -1))
		var hb_size = hb.get("size", [])
		var hb_data: Dictionary = hb.get("data", {})
		var on_hit_adv: String = "-"
		var on_block_adv: String = "-"
		if hb_data.has("on_hit_adv"):
			on_hit_adv = str(int(hb_data.get("on_hit_adv", 0)))
		if hb_data.has("on_block_adv"):
			on_block_adv = str(int(hb_data.get("on_block_adv", 0)))
		var damage: int = int(hb_data.get("damage", 0))
		lines.append("- %s: frames %s-%s size %s dmg %d" % [hb_id, str(hb_start), str(hb_end), str(hb_size), damage])
		lines.append("    on hit: %s | on block: %s" % [on_hit_adv, on_block_adv])
	frame_data_text.text = "\n".join(lines)
