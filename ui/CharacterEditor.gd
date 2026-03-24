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
@onready var shader_host: Control = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/ShaderHost
@onready var shader_preview_option: OptionButton = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/ShaderHost/VBoxContainer/ShaderRow/ShaderPreviewOption
@onready var shader_preview_path_edit: LineEdit = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/ShaderHost/VBoxContainer/ShaderRow/ShaderPreviewPathEdit
@onready var shader_preview_rescan_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/ShaderHost/VBoxContainer/ShaderRow/ShaderPreviewRescanButton
@onready var shader_preview_save_def_button: Button = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/ShaderHost/VBoxContainer/ShaderRow/ShaderPreviewSaveDefButton
@onready var shader_preview_viewport_container: SubViewportContainer = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/ShaderHost/VBoxContainer/ShaderPreviewViewportContainer
@onready var shader_preview_viewport: SubViewport = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/ShaderHost/VBoxContainer/ShaderPreviewViewportContainer/ShaderPreviewViewport
@onready var shader_preview_camera: Camera3D = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/ShaderHost/VBoxContainer/ShaderPreviewViewportContainer/ShaderPreviewViewport/ShaderPreviewWorld/ShaderPreviewCamera
@onready var shader_preview_model_root: Node3D = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/ShaderHost/VBoxContainer/ShaderPreviewViewportContainer/ShaderPreviewViewport/ShaderPreviewWorld/ShaderPreviewModelRoot
@onready var shader_dynamic_params_vbox: VBoxContainer = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/ShaderHost/VBoxContainer/ShaderDynamicScroll/ShaderDynamicParamsVBox
@onready var shader_live_feedback_label: Label = $MarginContainer/VBoxContainer/ContentPanel/EditorsRoot/ShaderHost/VBoxContainer/ShaderLiveFeedbackLabel
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
var shader_preview_current_model: Node3D = null
var shader_preview_anim_player: AnimationPlayer = null
var shader_preview_camera_target: Vector3 = Vector3(0.0, 1.0, 0.0)
var shader_preview_camera_distance: float = 3.6
var shader_preview_cam_yaw: float = 0.0
var shader_preview_cam_pitch: float = 0.0
const SHADER_PREVIEW_PITCH_LIMIT: float = 1.53
var shader_preview_min_zoom: float = 1.2
var shader_preview_max_zoom: float = 16.0
var shader_preview_def_cache: Dictionary = {}
var shader_preview_suppress_option_signal: bool = false
var shader_preview_active_path: String = ""
var shader_preview_suppress_ui_sync: bool = false
var shader_dynamic_uniform_editors: Dictionary = {}
var shader_preview_uniform_ui_build_id: int = 0
var shader_preview_sampler_defaults: Dictionary = {}

const SHADER_DEF_KEYS: Array[String] = [
	"shader_path",
	"shader_user_uniforms",
	"shader_base_tint",
	"shader_rim_color",
	"shader_rim_power",
	"shader_rim_intensity",
	"shader_steps"
]


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	UISkin.attach_focus_arrow(self)
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
	section_option.add_item("Shader Preview")
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
	shader_preview_option.item_selected.connect(_on_shader_preview_option_selected)
	shader_preview_path_edit.text_submitted.connect(_on_shader_preview_path_submitted)
	shader_preview_rescan_button.pressed.connect(_on_shader_preview_rescan_pressed)
	shader_preview_save_def_button.pressed.connect(_save_shader_path_to_character_def)
	shader_preview_viewport_container.gui_input.connect(_on_shader_preview_viewport_gui_input)
	reload_button.pressed.connect(_on_reload_pressed)
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


func _select_default_mod() -> void:
	if mod_entries.is_empty():
		status_label.text = "No mods found."
		return
	var selected_index: int = 0
	var preferred_mod_name: String = str(get_tree().get_meta("character_editor_mod_name", default_mod_name))
	for i in range(mod_entries.size()):
		if str(mod_entries[i].get("name", "")) == preferred_mod_name:
			selected_index = i
			break
	mod_option.select(selected_index)
	_on_mod_selected(selected_index)


func _on_mod_selected(index: int) -> void:
	if index < 0 or index >= mod_entries.size():
		return
	var mod_name: String = str(mod_entries[index].get("name", ""))
	var mod_path_sel: String = str(mod_entries[index].get("path", "")).strip_edges()
	var sync_key: String = mod_path_sel if not mod_path_sel.is_empty() else mod_name
	if box_editor_instance != null and box_editor_instance.has_method("select_mod_by_name"):
		box_editor_instance.call("select_mod_by_name", sync_key)
	if json_editor_instance != null and json_editor_instance.has_method("select_mod_by_name"):
		json_editor_instance.call("select_mod_by_name", sync_key)
	_reload_state_maker_for_mod(index)
	_reload_commands_for_mod(index)
	_reload_preview_tools_for_mod(index)
	_reload_frame_data_for_mod(index)
	_reload_shader_preview_for_mod(index)
	_sync_box_editor_to_selected_state()
	status_label.text = "Loaded mod: %s" % str(mod_entries[index].get("display_name", mod_name))


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
		shader_host.visible = false
		status_label.text = "Raw Files section active."
	elif section_id == 2:
		box_host.visible = false
		file_host.visible = false
		states_host.visible = true
		commands_host.visible = false
		preview_host.visible = false
		frame_host.visible = false
		shader_host.visible = false
		status_label.text = "States section active."
	elif section_id == 3:
		box_host.visible = false
		file_host.visible = false
		states_host.visible = false
		commands_host.visible = true
		preview_host.visible = false
		frame_host.visible = false
		shader_host.visible = false
		status_label.text = "Commands section active."
	elif section_id == 4:
		box_host.visible = false
		file_host.visible = false
		states_host.visible = false
		commands_host.visible = false
		preview_host.visible = true
		frame_host.visible = false
		shader_host.visible = false
		status_label.text = "Preview section active (Command Tester + In-Editor Playtest)."
	elif section_id == 5:
		box_host.visible = false
		file_host.visible = false
		states_host.visible = false
		commands_host.visible = false
		preview_host.visible = false
		frame_host.visible = true
		shader_host.visible = false
		status_label.text = "Frame Data section active."
	elif section_id == 6:
		box_host.visible = false
		file_host.visible = false
		states_host.visible = false
		commands_host.visible = false
		preview_host.visible = false
		frame_host.visible = false
		shader_host.visible = true
		status_label.text = "Shader Preview: live 3D preview."
		_refresh_shader_preview_model_if_needed()
	else:
		box_host.visible = true
		file_host.visible = false
		states_host.visible = false
		commands_host.visible = false
		preview_host.visible = false
		frame_host.visible = false
		shader_host.visible = false
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
	elif section_id == 6:
		var idx_sh: int = mod_option.get_selected()
		if idx_sh >= 0:
			_reload_shader_preview_for_mod(idx_sh)
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
	elif section_id == 6:
		_save_shader_path_to_character_def()
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
	_sync_box_editor_to_selected_state()


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
	var cancel_into: Array = _parse_state_maker_cancel_into(state_maker_cancel_into_edit.text)
	var cancel_windows_parse: Dictionary = _parse_state_maker_json_array_field(state_maker_cancel_windows_edit.text, "cancel_windows")
	if not bool(cancel_windows_parse.get("ok", false)):
		return
	var state_data: Dictionary = state_maker_data.get(old_id, {}).duplicate(true)
	state_data["animation"] = state_maker_animation_edit.text.strip_edges()
	state_data["allow_movement"] = state_maker_allow_movement_check.button_pressed
	state_data["cancel_into"] = cancel_into
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
	_sync_box_editor_to_selected_state()
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
	var cancel_windows_raw: Variant = state_data.get("cancel_windows", [])
	var cancel_windows_arr: Array = cancel_windows_raw if cancel_windows_raw is Array else []
	state_maker_cancel_windows_edit.text = JSON.stringify(cancel_windows_arr)
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


func _sanitize_for_json_export(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			var f: float = value
			if is_nan(f) or is_inf(f):
				return null
			return f
		TYPE_DICTIONARY:
			var src: Dictionary = value
			var out: Dictionary = {}
			for k in src.keys():
				out[str(k)] = _sanitize_for_json_export(src[k])
			return out
		TYPE_ARRAY:
			var src_a: Array = value
			var out_a: Array = []
			for item in src_a:
				out_a.append(_sanitize_for_json_export(item))
			return out_a
		_:
			return value


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
	var safe_root: Variant = _sanitize_for_json_export(state_maker_data)
	if typeof(safe_root) != TYPE_DICTIONARY:
		status_label.text = "Save failed: could not prepare states.json data."
		return
	var text: String = JSON.stringify(safe_root, "\t")
	var round_trip: Variant = JSON.parse_string(text)
	if typeof(round_trip) != TYPE_DICTIONARY:
		status_label.text = "Save failed: states.json would not parse (check for bad float values)."
		push_error("states.json round-trip validation failed after stringify.")
		return
	var file := FileAccess.open(current_state_maker_path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Failed to save states.json."
		return
	file.store_string(text)
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
	var hitbox_windows: PackedStringArray = []
	for hitbox in hitboxes:
		if typeof(hitbox) != TYPE_DICTIONARY:
			continue
		var hitbox_data: Dictionary = hitbox as Dictionary
		hitbox_windows.append(
			"%s [%s-%s]" % [
				str(hitbox_data.get("id", "hitbox")),
				str(hitbox_data.get("start", 0)),
				str(hitbox_data.get("end", -1))
			]
		)
	if not hitbox_windows.is_empty():
		lines.append("Hitbox Windows: %s" % " | ".join(hitbox_windows))
	var throwbox_windows: PackedStringArray = []
	for throwbox in throwboxes:
		if typeof(throwbox) != TYPE_DICTIONARY:
			continue
		var throwbox_data: Dictionary = throwbox as Dictionary
		throwbox_windows.append(
			"%s [%s-%s]" % [
				str(throwbox_data.get("id", "throwbox")),
				str(throwbox_data.get("start", 0)),
				str(throwbox_data.get("end", -1))
			]
		)
	if not throwbox_windows.is_empty():
		lines.append("Throw Windows: %s" % " | ".join(throwbox_windows))
	var next_data: Dictionary = state_data.get("next", {})
	if not next_data.is_empty():
		lines.append("Next: frame %s -> %s" % [str(next_data.get("frame", "-")), str(next_data.get("id", "-"))])
	var cancel_windows = state_data.get("cancel_windows", [])
	lines.append("Cancel Windows: %s" % str(cancel_windows))
	lines.append("Tip: open `Box Tools`, scrub the timeline, and the selected state's hitbox will only show during its active frames.")
	state_maker_timeline_text.text = "\n".join(lines)


func _sync_box_editor_to_selected_state() -> void:
	if box_editor_instance == null:
		return
	if selected_state_maker_key.is_empty():
		return
	if not box_editor_instance.has_method("select_state_by_name"):
		return
	box_editor_instance.call("select_state_by_name", selected_state_maker_key, "hitboxes")


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
	elif section == "shader" or section == "shaders":
		section_option.select(6)
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
	var p1_mod: String = str(mod_entries[idx].get("path", "")).strip_edges()
	if p1_mod.is_empty():
		p1_mod = str(mod_entries[idx].get("name", ""))
	if p1_mod.is_empty():
		status_label.text = "Selected mod is invalid."
		return
	var p2_mod: String = _first_other_mod_path(p1_mod)
	get_tree().set_meta("game_mode", "training")
	get_tree().set_meta("training_p1_mod", p1_mod)
	get_tree().set_meta("training_p2_mod", p2_mod)
	get_tree().set_meta("training_p1_form", "")
	get_tree().set_meta("training_p2_form", "")
	get_tree().set_meta("training_p1_costume", "")
	get_tree().set_meta("training_p2_costume", "")
	get_tree().change_scene_to_file(playtest_scene_path)


func _first_other_mod_path(exclude_path: String) -> String:
	for entry in mod_entries:
		var e: Dictionary = entry as Dictionary
		var p: String = str(e.get("path", "")).strip_edges()
		var key: String = p if not p.is_empty() else str(e.get("name", "")).strip_edges()
		if key.is_empty() or key == exclude_path:
			continue
		return key
	return exclude_path


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
	var active_count: int = -1
	if active_start >= 0 and active_end >= 0:
		active_count = maxi(0, active_end - active_start + 1)

	var lines: PackedStringArray = []
	lines.append("[b]%s[/b]" % state_id)
	lines.append("Animation: %s" % str(state_data.get("animation", "")))
	lines.append("")
	lines.append("[b]Frame data[/b]")
	lines.append("%s Frame Startup" % ("-" if startup < 0 else str(startup)))
	lines.append("%s Active Frames" % ("-" if active_count < 0 else str(active_count)))
	if active_start >= 0 and active_end >= 0:
		lines.append("  (frames %d–%d)" % [active_start, active_end])
	lines.append("%s Recovery Frames" % ("-" if recovery < 0 else str(recovery)))
	if total_frames >= 0:
		lines.append("Total: %d frames" % total_frames)
	lines.append("")
	var first_hb_data: Dictionary = {}
	var first_hb_result: String = ""
	for i in range(hitboxes.size()):
		if typeof(hitboxes[i]) != TYPE_DICTIONARY:
			continue
		var hb: Dictionary = hitboxes[i]
		first_hb_data = hb.get("data", {})
		first_hb_result = str(first_hb_data.get("on_hit_result", "")).strip_edges()
		if first_hb_result.is_empty() and bool(first_hb_data.get("knockdown", false)):
			first_hb_result = "Knockdown"
		if first_hb_result.is_empty():
			first_hb_result = "Hit"
		break
	if not first_hb_data.is_empty():
		lines.append("[b]Properties on Hit / Block[/b]")
		var hit_adv: Variant = first_hb_data.get("on_hit_adv", null)
		var block_adv: Variant = first_hb_data.get("on_block_adv", null)
		var hit_str: String = first_hb_result
		if hit_adv != null:
			var v: int = int(hit_adv)
			hit_str += " %+d On Hit" % v
		else:
			hit_str += " On Hit"
		var block_str: String = "- On Block" if block_adv == null else ("%+d On Block" % int(block_adv))
		lines.append(hit_str)
		lines.append(block_str)
		var smash_pct_first: Variant = first_hb_data.get("smash_percent", first_hb_data.get("smash_damage", null))
		if smash_pct_first != null:
			lines.append("Smash: %s%% damage" % str(int(smash_pct_first)))
		else:
			var dmg_first: int = int(first_hb_data.get("damage", 0))
			lines.append("Smash: %d%% damage (from dmg)" % dmg_first)
	lines.append("")
	lines.append("Hitboxes: %d | Persistent hurtboxes in Box Tools." % hitboxes.size())
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
		var smash_pct: Variant = hb_data.get("smash_percent", hb_data.get("smash_damage", null))
		var dmg_str: String = "dmg %d" % damage
		if smash_pct != null:
			dmg_str += " | Smash: %s%%" % str(int(smash_pct))
		else:
			dmg_str += " (%d%% in Smash)" % damage
		lines.append("- %s: frames %s-%s size %s | %s | hit %s block %s" % [hb_id, str(hb_start), str(hb_end), str(hb_size), dmg_str, on_hit_adv, on_block_adv])
	frame_data_text.text = "\n".join(lines)


func _reload_shader_preview_for_mod(index: int) -> void:
	shader_preview_def_cache = {}
	shader_preview_active_path = ""
	if index < 0 or index >= mod_entries.size():
		_clear_shader_preview_model()
		return
	var mod_path: String = str(mod_entries[index].get("path", ""))
	if mod_path.is_empty():
		_clear_shader_preview_model()
		return
	var def_file: String = "%scharacter.def" % mod_path
	shader_preview_def_cache = ContentResolver.load_character_def(def_file)
	var model_path: String = _resolve_shader_preview_model_path(mod_path)
	if model_path.is_empty():
		status_label.text = "Shader Preview: no model found for this mod."
		_clear_shader_preview_model()
		return
	var cur_shader: String = str(shader_preview_def_cache.get("shader_path", "")).strip_edges()
	_clear_shader_dynamic_uniform_ui()
	_populate_shader_preview_dropdown(mod_path, cur_shader)
	_apply_shader_preview_with_path(cur_shader)


func _resolve_shader_preview_model_path(mod_path: String) -> String:
	var normalized: String = mod_path
	if not normalized.ends_with("/"):
		normalized += "/"
	var parts_path: String = "%sparts.json" % normalized
	var parts: Dictionary = {}
	if FileAccess.file_exists(parts_path):
		var pf := FileAccess.open(parts_path, FileAccess.READ)
		if pf != null:
			var parsed = JSON.parse_string(pf.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				parts = parsed as Dictionary
	if bool(parts.get("enabled", false)):
		var bm: String = str(parts.get("base_model", "")).strip_edges()
		if not bm.is_empty():
			var rp: String = ContentResolver.resolve_relative_or_absolute_path(normalized, bm)
			if FileAccess.file_exists(rp) or (rp.begins_with("res://") and ResourceLoader.exists(rp)):
				return rp
	return ContentResolver.find_character_model_path(normalized, ContentResolver.load_character_def("%scharacter.def" % normalized))


func _clear_shader_preview_model() -> void:
	for c in shader_preview_model_root.get_children():
		c.queue_free()
	shader_preview_current_model = null
	shader_preview_anim_player = null


func _populate_shader_preview_dropdown(mod_path: String, current_shader: String) -> void:
	shader_preview_suppress_option_signal = true
	shader_preview_option.clear()
	shader_preview_option.add_item("(Default — GLTF materials)")
	shader_preview_option.set_item_metadata(0, "")
	var discovered: Array[String] = _collect_gdshader_paths_for_editor(mod_path)
	for p in discovered:
		var label: String = p.substr(6) if p.begins_with("res://") else p
		shader_preview_option.add_item(label)
		shader_preview_option.set_item_metadata(shader_preview_option.item_count - 1, p)
	shader_preview_option.add_item("— Custom (path field) —")
	shader_preview_option.set_item_metadata(shader_preview_option.item_count - 1, "__custom__")
	shader_preview_path_edit.text = current_shader
	var sel: int = 0
	if not current_shader.is_empty():
		var found_idx: bool = false
		for j in range(shader_preview_option.item_count):
			var m = shader_preview_option.get_item_metadata(j)
			if str(m) == current_shader:
				sel = j
				found_idx = true
				break
		if not found_idx:
			sel = shader_preview_option.item_count - 1
	shader_preview_option.select(sel)
	shader_preview_suppress_option_signal = false


func _collect_gdshader_paths_for_editor(mod_path: String) -> Array[String]:
	var out: Array[String] = []
	var seen: Dictionary = {}
	_shader_dir_collect_gdshaders("res://shaders", out, seen, 4)
	_shader_dir_collect_gdshaders("res://ui/Battle", out, seen, 2)
	if not mod_path.is_empty():
		_shader_dir_collect_gdshaders(mod_path.trim_suffix("/"), out, seen, 4)
	var md := DirAccess.open("res://mods")
	if md != null:
		md.list_dir_begin()
		var it: String = md.get_next()
		while not it.is_empty():
			if md.current_is_dir() and it != "." and it != "..":
				_shader_dir_collect_gdshaders("res://mods/%s" % it, out, seen, 2)
			it = md.get_next()
		md.list_dir_end()
	out.sort()
	return out


func _shader_dir_collect_gdshaders(dir_path: String, out: Array[String], seen: Dictionary, depth: int) -> void:
	if depth < 0 or dir_path.is_empty():
		return
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var fn: String = d.get_next()
	while not fn.is_empty():
		if d.current_is_dir():
			if fn != "." and fn != "..":
				_shader_dir_collect_gdshaders("%s/%s" % [dir_path, fn], out, seen, depth - 1)
		elif fn.to_lower().ends_with(".gdshader"):
			var full: String = "%s/%s" % [dir_path, fn]
			if not seen.has(full):
				seen[full] = true
				out.append(full)
		fn = d.get_next()
	d.list_dir_end()


func _resolve_shader_path_from_editor_field(text: String) -> String:
	var t: String = text.strip_edges()
	if t.is_empty():
		return ""
	if t.begins_with("res://") or t.begins_with("user://"):
		return t
	var idx: int = mod_option.get_selected()
	if idx >= 0:
		var mp: String = str(mod_entries[idx].get("path", ""))
		return ContentResolver.resolve_relative_or_absolute_path(mp, t)
	return t


func _editor_load_shader(path_raw: String) -> Shader:
	if path_raw.is_empty():
		return null
	if path_raw.begins_with("res://"):
		if not ResourceLoader.exists(path_raw):
			return null
		var r = ResourceLoader.load(path_raw)
		return r as Shader
	if not FileAccess.file_exists(path_raw):
		return null
	var f := FileAccess.open(path_raw, FileAccess.READ)
	if f == null:
		return null
	var sh := Shader.new()
	sh.code = f.get_as_text()
	return sh


func _editor_shader_params_from_def(def_data: Dictionary) -> Dictionary:
	var params: Dictionary = {}
	if def_data.has("shader_base_tint"):
		params["base_tint"] = _editor_parse_color(def_data.get("shader_base_tint", "1,1,1,1"), Color.WHITE)
	if def_data.has("shader_rim_color"):
		params["rim_color"] = _editor_parse_color(def_data.get("shader_rim_color", "0.2,0.35,1.0,1.0"), Color(0.2, 0.35, 1.0, 1.0))
	if def_data.has("shader_rim_power"):
		params["rim_power"] = float(def_data.get("shader_rim_power", 2.2))
	if def_data.has("shader_rim_intensity"):
		params["rim_intensity"] = float(def_data.get("shader_rim_intensity", 0.35))
	if def_data.has("shader_steps"):
		params["shade_steps"] = float(def_data.get("shader_steps", 3.0))
	return params


func _editor_parse_color(value, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var parts: PackedStringArray = value.split(",", false)
		if parts.size() >= 3:
			var a: float = 1.0
			if parts.size() >= 4:
				a = float(parts[3])
			return Color(float(parts[0]), float(parts[1]), float(parts[2]), a)
	return fallback


## Preview-only: when true, applies shader to every surface so live param edits always have materials to update.
func _editor_apply_character_shader(root: Node3D, shader: Shader, params: Dictionary, preview_force_all_surfaces: bool = false) -> int:
	var surface_count: int = 0
	if root == null or shader == null:
		return 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh != null:
				for i in range(mesh_node.mesh.get_surface_count()):
					var source_mat: Material = _editor_resolve_surface_material(mesh_node, i)
					var albedo_tex: Texture2D = _editor_albedo_tex(source_mat)
					var albedo_color: Color = _editor_albedo_color(source_mat)
					var useful: bool = albedo_tex != null or not _editor_color_near_white(albedo_color)
					if not useful and preview_force_all_surfaces:
						albedo_tex = null
						albedo_color = Color.WHITE
						useful = true
					if not useful:
						continue
					var mat := ShaderMaterial.new()
					mat.shader = shader
					if albedo_tex != null:
						mat.set_shader_parameter("albedo_texture", albedo_tex)
						mat.set_shader_parameter("use_albedo_texture", true)
					else:
						mat.set_shader_parameter("use_albedo_texture", false)
					mat.set_shader_parameter("material_color", albedo_color)
					for k in params.keys():
						mat.set_shader_parameter(str(k), params[k])
					mesh_node.set_surface_override_material(i, mat)
					surface_count += 1
		for ch in node.get_children():
			stack.append(ch)
	return surface_count


func _editor_resolve_surface_material(mesh_node: MeshInstance3D, surface_index: int) -> Material:
	var source_mat: Material = mesh_node.get_active_material(surface_index)
	if source_mat == null and mesh_node.material_override != null:
		source_mat = mesh_node.material_override
	if source_mat == null and mesh_node.mesh != null:
		source_mat = mesh_node.mesh.surface_get_material(surface_index)
	return source_mat


func _editor_albedo_tex(material: Material) -> Texture2D:
	if material is BaseMaterial3D:
		return (material as BaseMaterial3D).albedo_texture
	if material is ShaderMaterial:
		var sm := material as ShaderMaterial
		var t = sm.get_shader_parameter("albedo_texture")
		if t is Texture2D:
			return t as Texture2D
		t = sm.get_shader_parameter("texture_albedo")
		if t is Texture2D:
			return t as Texture2D
	return null


func _editor_albedo_color(material: Material) -> Color:
	if material is BaseMaterial3D:
		return (material as BaseMaterial3D).albedo_color
	if material is ShaderMaterial:
		var v = (material as ShaderMaterial).get_shader_parameter("albedo")
		if v is Color:
			return v as Color
	return Color.WHITE


func _editor_color_near_white(color: Color) -> bool:
	return color.r > 0.98 and color.g > 0.98 and color.b > 0.98 and color.a > 0.98


func _load_shader_preview_model_node(model_path: String, def_data: Dictionary) -> void:
	_clear_shader_preview_model()
	var scene_node: Node = _load_editor_model_scene(model_path)
	if scene_node == null or not (scene_node is Node3D):
		return
	var node3d := scene_node as Node3D
	node3d.scale = _shader_preview_model_scale(def_data)
	node3d.position.y += float(def_data.get("model_offset_y", 0.0))
	shader_preview_model_root.add_child(node3d)
	shader_preview_current_model = node3d
	shader_preview_anim_player = _shader_find_animation_player(node3d)
	if shader_preview_anim_player != null:
		var anim_list: PackedStringArray = shader_preview_anim_player.get_animation_list()
		if anim_list.size() > 0:
			var play_name: String = str(anim_list[0])
			for cand in ["idle", "Idle", "TPOSE", "tp", "bn01"]:
				if shader_preview_anim_player.has_animation(cand):
					play_name = cand
					break
			shader_preview_anim_player.play(play_name)
	_shader_preview_fit_camera(node3d)


func _load_editor_model_scene(path: String) -> Node:
	var lower: String = path.to_lower()
	if path.begins_with("user://") and (lower.ends_with(".gltf") or lower.ends_with(".glb")):
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		if gltf.append_from_file(path, state) != OK:
			return null
		return gltf.generate_scene(state)
	if not path.begins_with("user://"):
		var loaded = ResourceLoader.load(path)
		if loaded is PackedScene:
			return (loaded as PackedScene).instantiate()
	if lower.ends_with(".gltf") or lower.ends_with(".glb"):
		var gltf2 := GLTFDocument.new()
		var state2 := GLTFState.new()
		if gltf2.append_from_file(path, state2) != OK:
			return null
		return gltf2.generate_scene(state2)
	return null


func _shader_preview_model_scale(def_data: Dictionary) -> Vector3:
	var u: float = float(def_data.get("model_scale", 1.0))
	return Vector3(
		float(def_data.get("model_scale_x", u)),
		float(def_data.get("model_scale_y", u)),
		float(def_data.get("model_scale_z", u))
	)


func _shader_find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for ch in root.get_children():
		var a: AnimationPlayer = _shader_find_animation_player(ch)
		if a != null:
			return a
	return null


func _shader_preview_collect_aabb(root: Node3D) -> AABB:
	var stack: Array[Node] = [root]
	var has_b: bool = false
	var merged: AABB = AABB()
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh != null:
				var wb: AABB = mi.global_transform * mi.mesh.get_aabb()
				if not has_b:
					merged = wb
					has_b = true
				else:
					merged = merged.merge(wb)
		for ch in n.get_children():
			stack.append(ch)
	return merged if has_b else AABB()


func _shader_preview_fit_camera(root: Node3D) -> void:
	shader_preview_cam_yaw = 0.0
	shader_preview_cam_pitch = 0.0
	var aabb: AABB = _shader_preview_collect_aabb(root)
	if aabb.size.length() <= 0.001:
		shader_preview_camera_target = Vector3(0.0, 1.0, 0.0)
		shader_preview_camera_distance = 3.6
	else:
		var center: Vector3 = aabb.get_center()
		var extent: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		shader_preview_camera_target = center + Vector3(0.0, extent * 0.06, 0.0)
		shader_preview_camera_distance = clampf(extent * 1.85, 2.0, 14.0)
		shader_preview_min_zoom = maxf(0.35, extent * 0.25)
		shader_preview_max_zoom = maxf(shader_preview_camera_distance + 8.0, extent * 12.0)
	_shader_preview_update_camera()


func _shader_preview_update_camera() -> void:
	if shader_preview_camera == null:
		return
	var d: float = shader_preview_camera_distance
	var cp: float = cos(shader_preview_cam_pitch)
	var offset: Vector3 = Vector3(
		sin(shader_preview_cam_yaw) * cp,
		sin(shader_preview_cam_pitch),
		cos(shader_preview_cam_yaw) * cp
	) * d
	shader_preview_camera.global_position = shader_preview_camera_target + offset
	shader_preview_camera.look_at(shader_preview_camera_target, Vector3.UP)


func _shader_preview_pan_camera(rel: Vector2) -> void:
	if shader_preview_camera == null:
		return
	var k: float = 0.0022 * maxf(0.5, shader_preview_camera_distance)
	var right: Vector3 = shader_preview_camera.global_transform.basis.x
	var up: Vector3 = shader_preview_camera.global_transform.basis.y
	shader_preview_camera_target += (-right * rel.x + up * rel.y) * k
	_shader_preview_update_camera()


func _apply_shader_preview_with_path(shader_resolved_path: String) -> void:
	var idx: int = mod_option.get_selected()
	if idx < 0:
		return
	var mod_path: String = str(mod_entries[idx].get("path", ""))
	var mp: String = _resolve_shader_preview_model_path(mod_path)
	if mp.is_empty():
		return
	var def: Dictionary = shader_preview_def_cache
	var p: String = shader_resolved_path.strip_edges()
	shader_preview_active_path = p
	_load_shader_preview_model_node(mp, def)
	if p.is_empty():
		status_label.text = "Shader Preview: default materials."
		_clear_shader_dynamic_uniform_ui()
		_set_shader_live_feedback("No shader selected — model uses GLTF materials. Pick a shader to list uniforms.", false)
		return
	var sh: Shader = _editor_load_shader(p)
	if sh == null:
		status_label.text = "Shader Preview: could not load %s" % p
		_clear_shader_dynamic_uniform_ui()
		_set_shader_live_feedback("Could not load shader file.", false)
		return
	var n_surfaces: int = _editor_apply_character_shader(shader_preview_current_model, sh, _shader_merged_uniform_dict_for_apply(), true)
	status_label.text = "Shader Preview: %s" % p.get_file()
	_set_shader_live_feedback(
		"✓ %d surface(s). Building uniform list…" % n_surfaces,
		true
	)
	_shader_preview_refresh_viewport()
	shader_preview_uniform_ui_build_id += 1
	var build_id: int = shader_preview_uniform_ui_build_id
	call_deferred("_shader_deferred_build_uniform_ui", sh, build_id)


func _refresh_shader_preview_model_if_needed() -> void:
	var idx: int = mod_option.get_selected()
	if idx < 0:
		return
	_reload_shader_preview_for_mod(idx)


func _on_shader_preview_option_selected(_i: int) -> void:
	if shader_preview_suppress_option_signal:
		return
	var sel: int = shader_preview_option.get_selected()
	var meta = shader_preview_option.get_item_metadata(sel)
	var p: String = ""
	if meta == null or str(meta) == "":
		p = ""
	elif str(meta) == "__custom__":
		p = _resolve_shader_path_from_editor_field(shader_preview_path_edit.text)
	else:
		p = str(meta)
	_apply_shader_preview_with_path(p)


func _on_shader_preview_path_submitted(new_text: String) -> void:
	shader_preview_path_edit.text = new_text
	shader_preview_suppress_option_signal = true
	shader_preview_option.select(shader_preview_option.item_count - 1)
	shader_preview_suppress_option_signal = false
	_apply_shader_preview_with_path(_resolve_shader_path_from_editor_field(new_text))


func _on_shader_preview_rescan_pressed() -> void:
	var idx: int = mod_option.get_selected()
	if idx < 0:
		return
	var mod_path: String = str(mod_entries[idx].get("path", ""))
	_populate_shader_preview_dropdown(mod_path, shader_preview_active_path)
	_apply_shader_preview_with_path(shader_preview_active_path)


func _save_shader_path_to_character_def() -> void:
	var idx: int = mod_option.get_selected()
	if idx < 0:
		status_label.text = "No mod selected."
		return
	var mod_path: String = str(mod_entries[idx].get("path", ""))
	var def_file: String = "%scharacter.def" % mod_path
	if not FileAccess.file_exists(def_file):
		status_label.text = "character.def not found."
		return
	var f_read := FileAccess.open(def_file, FileAccess.READ)
	if f_read == null:
		status_label.text = "Could not read character.def."
		return
	var new_lines: PackedStringArray = []
	while not f_read.eof_reached():
		new_lines.append(f_read.get_line())
	f_read.close()
	var skip_keys: Dictionary = {}
	for k in SHADER_DEF_KEYS:
		skip_keys[k] = true
	var out_lines: PackedStringArray = []
	for line in new_lines:
		var lk: String = _character_def_line_key(line)
		if skip_keys.has(lk):
			continue
		out_lines.append(line)
	var spath: String = shader_preview_active_path.strip_edges()
	if not spath.is_empty():
		out_lines.append("shader_path = %s" % spath)
		var uj: String = JSON.stringify(_collect_shader_uniforms_for_json_save())
		out_lines.append("shader_user_uniforms = %s" % uj)
	var f_write := FileAccess.open(def_file, FileAccess.WRITE)
	if f_write == null:
		status_label.text = "Could not write character.def."
		return
	for L in out_lines:
		f_write.store_string(L)
		f_write.store_string("\n")
	f_write.close()
	shader_preview_def_cache = ContentResolver.load_character_def(def_file)
	status_label.text = "Saved shader_path + shader_user_uniforms to character.def"


func _character_def_line_key(line: String) -> String:
	var st: String = line.strip_edges()
	if st.is_empty() or st.begins_with(";") or st.begins_with("#"):
		return ""
	var eq: int = st.find("=")
	if eq < 0:
		return ""
	return st.substr(0, eq).strip_edges()


func _shader_merged_uniform_dict_for_apply() -> Dictionary:
	var params: Dictionary = {}
	var raw_u: String = str(shader_preview_def_cache.get("shader_user_uniforms", "")).strip_edges()
	if not raw_u.is_empty():
		var parsed_u = JSON.parse_string(raw_u)
		if typeof(parsed_u) == TYPE_DICTIONARY:
			for k in (parsed_u as Dictionary).keys():
				var pv: Variant = _editor_json_to_shader_variant((parsed_u as Dictionary)[k])
				if pv != null:
					params[str(k)] = pv
	if not params.has("base_tint") and shader_preview_def_cache.has("shader_base_tint"):
		params["base_tint"] = _editor_parse_color(shader_preview_def_cache.get("shader_base_tint"), Color.WHITE)
	if not params.has("rim_color") and shader_preview_def_cache.has("shader_rim_color"):
		params["rim_color"] = _editor_parse_color(shader_preview_def_cache.get("shader_rim_color"), Color(0.2, 0.35, 1.0, 1.0))
	if not params.has("rim_power") and shader_preview_def_cache.has("shader_rim_power"):
		params["rim_power"] = float(shader_preview_def_cache.get("shader_rim_power", 2.2))
	if not params.has("rim_intensity") and shader_preview_def_cache.has("shader_rim_intensity"):
		params["rim_intensity"] = float(shader_preview_def_cache.get("shader_rim_intensity", 0.35))
	if not params.has("shade_steps") and shader_preview_def_cache.has("shader_steps"):
		params["shade_steps"] = float(shader_preview_def_cache.get("shader_steps", 3.0))
	return params


const SHADER_JSON_TEX_UV_GRADIENT := "__uv_gradient__"


func _editor_make_uv_gradient_texture() -> Texture2D:
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.add_point(0.0, Color.BLACK)
	gr.add_point(1.0, Color.WHITE)
	gt.gradient = gr
	gt.width = 256
	gt.height = 256
	return gt


func _editor_load_texture2d_from_path(path: String) -> Texture2D:
	var p: String = path.strip_edges()
	if p.is_empty():
		return null
	if ResourceLoader.exists(p):
		var r = ResourceLoader.load(p)
		if r is Texture2D:
			return r as Texture2D
	if not FileAccess.file_exists(p):
		return null
	var img := Image.new()
	if img.load(p) != OK:
		return null
	return ImageTexture.create_from_image(img)


func _editor_json_to_shader_variant(v) -> Variant:
	if v is String:
		var sv: String = str(v).strip_edges()
		if sv == SHADER_JSON_TEX_UV_GRADIENT:
			return _editor_make_uv_gradient_texture()
		if sv.begins_with("res://") or sv.begins_with("user://"):
			var tr2 := _editor_load_texture2d_from_path(sv)
			if tr2 != null:
				return tr2
		var midx: int = mod_option.get_selected()
		if midx >= 0:
			var root: String = str(mod_entries[midx].get("path", "")).trim_suffix("/")
			if not root.is_empty():
				var fp: String = root.path_join(sv)
				var t2 := _editor_load_texture2d_from_path(fp)
				if t2 != null:
					return t2
		return null
	if v is float or v is int or v is bool:
		return v
	if v is Array:
		var a: Array = v
		if a.size() >= 4:
			return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
		if a.size() == 3:
			return Vector3(float(a[0]), float(a[1]), float(a[2]))
		if a.size() == 2:
			return Vector2(float(a[0]), float(a[1]))
	return v


func _shader_saved_uniform_string_tokens() -> Dictionary:
	var out: Dictionary = {}
	var raw_u: String = str(shader_preview_def_cache.get("shader_user_uniforms", "")).strip_edges()
	if raw_u.is_empty():
		return out
	var parsed_u = JSON.parse_string(raw_u)
	if typeof(parsed_u) != TYPE_DICTIONARY:
		return out
	for k in (parsed_u as Dictionary).keys():
		var vv = (parsed_u as Dictionary)[k]
		if vv is String:
			out[str(k)] = str(vv).strip_edges()
	return out


func _shader_line_parse_hint_range(line: String) -> Dictionary:
	var out: Dictionary = {"has": false, "mn": 0.0, "mx": 1.0, "step": 0.01}
	var hi: int = line.find("hint_range")
	if hi < 0:
		return out
	var op: int = line.find("(", hi)
	var cl: int = line.find(")", op)
	if op < 0 or cl < 0:
		return out
	var ins: String = line.substr(op + 1, cl - op - 1)
	var parts: PackedStringArray = ins.split(",")
	if parts.size() < 2:
		return out
	out["has"] = true
	out["mn"] = float(str(parts[0]).strip_edges())
	out["mx"] = float(str(parts[1]).strip_edges())
	out["step"] = 0.01
	if parts.size() >= 3:
		out["step"] = float(str(parts[2]).strip_edges())
	return out


func _parse_shader_uniform_specs(code: String) -> Array:
	var specs: Array = []
	var group: String = "General"
	for raw_line in code.split("\n"):
		var line: String = raw_line.strip_edges()
		var cmt: int = line.find("//")
		if cmt >= 0:
			line = line.substr(0, cmt).strip_edges()
		if line.is_empty():
			continue
		if line.begins_with("group_uniforms"):
			var grest: String = line.substr(14).strip_edges().trim_suffix(";").strip_edges()
			group = grest if not grest.is_empty() else "General"
			continue
		if not line.begins_with("uniform"):
			continue
		var sc: int = line.find(";")
		if sc > 0:
			line = line.substr(0, sc).strip_edges()
		var hr: Dictionary = _shader_line_parse_hint_range(line)
		var end_idx: int = line.length()
		var ci: int = line.find(":")
		var ei: int = line.find("=")
		if ci >= 0:
			end_idx = mini(end_idx, ci)
		if ei >= 0:
			end_idx = mini(end_idx, ei)
		var decl_prefix: String = line.substr(0, end_idx).strip_edges()
		var u0: int = decl_prefix.find("uniform")
		if u0 < 0:
			continue
		var after: String = decl_prefix.substr(u0 + 7).strip_edges()
		var toks: PackedStringArray = after.split(" ", false)
		var ti: int = 0
		while ti < toks.size() and str(toks[ti]) in ["const", "highp", "mediump", "lowp", "instance"]:
			ti += 1
		if ti + 1 >= toks.size():
			continue
		var typ: String = str(toks[ti])
		var blob: String = ""
		var tj: int = ti + 1
		while tj < toks.size():
			blob += ("" if blob.is_empty() else " ") + str(toks[tj])
			tj += 1
		for raw_n in blob.split(","):
			var nm: String = raw_n.strip_edges().split(" ", false)[0]
			if not nm.is_valid_identifier():
				continue
			specs.append({
				"group": group,
				"name": nm,
				"type": typ,
				"hr": hr,
			})
	return specs


func _shader_ordered_uniform_entries(sh: Shader) -> Array:
	var specs: Array = _parse_shader_uniform_specs(sh.code)
	var by_name: Dictionary = {}
	for s in specs:
		by_name[s["name"]] = true
	var ordered: Array = []
	for s in specs:
		ordered.append(s)
	for nm in _shader_list_uniform_names(sh):
		if by_name.has(nm):
			continue
		ordered.append({
			"group": "General",
			"name": nm,
			"type": _gdshader_type_for_uniform(sh.code, nm),
			"hr": {"has": false, "mn": 0.0, "mx": 1.0, "step": 0.01},
		})
	return ordered


func _shader_preview_collect_mod_texture_paths(mod_root: String, max_files: int = 64) -> PackedStringArray:
	var out: PackedStringArray = []
	if mod_root.is_empty():
		return out
	var base: String = mod_root.trim_suffix("/")
	_shader_preview_dir_images_recursive(base, out, max_files, 0, 4)
	return out


func _shader_preview_dir_images_recursive(dir_path: String, out: PackedStringArray, max_f: int, depth: int, max_depth: int) -> void:
	if out.size() >= max_f or depth > max_depth:
		return
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var fn: String = d.get_next()
	while fn != "":
		if fn == "." or fn == "..":
			fn = d.get_next()
			continue
		var full: String = dir_path.path_join(fn)
		if d.current_is_dir():
			_shader_preview_dir_images_recursive(full, out, max_f, depth + 1, max_depth)
		else:
			var low: String = fn.to_lower()
			if low.ends_with(".png") or low.ends_with(".jpg") or low.ends_with(".jpeg") or low.ends_with(".webp") or low.ends_with(".tga"):
				if FileAccess.file_exists(full) or (full.begins_with("res://") and ResourceLoader.exists(full)):
					out.append(full)
		fn = d.get_next()


func _clear_shader_dynamic_uniform_ui() -> void:
	shader_dynamic_uniform_editors.clear()
	shader_preview_sampler_defaults.clear()
	if shader_dynamic_params_vbox == null:
		return
	for c in shader_dynamic_params_vbox.get_children():
		c.queue_free()


func _shader_list_uniform_names(sh: Shader) -> Array[String]:
	var out: Array[String] = []
	var seen: Dictionary = {}
	if sh == null:
		return out
	for nm in _parse_uniform_names_from_gdshader(sh.code):
		seen[nm] = true
		out.append(nm)
	if sh.has_method("get_shader_uniform_list"):
		for item in sh.get_shader_uniform_list():
			if typeof(item) == TYPE_DICTIONARY:
				var nm2: String = str(item.get("name", "")).strip_edges()
				if not nm2.is_empty() and not seen.has(nm2):
					seen[nm2] = true
					out.append(nm2)
	return out


func _parse_uniform_names_from_gdshader(code: String) -> Array[String]:
	var seen: Dictionary = {}
	var names: Array[String] = []
	for raw_line in code.split("\n"):
		var line: String = raw_line.strip_edges()
		var cmt: int = line.find("//")
		if cmt >= 0:
			line = line.substr(0, cmt).strip_edges()
		if not line.begins_with("uniform"):
			continue
		var sc: int = line.find(";")
		if sc > 0:
			line = line.substr(0, sc).strip_edges()
		var end_idx: int = line.length()
		var ci: int = line.find(":")
		var ei: int = line.find("=")
		if ci >= 0:
			end_idx = mini(end_idx, ci)
		if ei >= 0:
			end_idx = mini(end_idx, ei)
		var decl_prefix: String = line.substr(0, end_idx).strip_edges()
		var u0: int = decl_prefix.find("uniform")
		if u0 < 0:
			continue
		var after: String = decl_prefix.substr(u0 + 7).strip_edges()
		var toks: PackedStringArray = after.split(" ", false)
		var i: int = 0
		while i < toks.size() and str(toks[i]) in ["const", "highp", "mediump", "lowp", "instance"]:
			i += 1
		if i >= toks.size() or i + 1 >= toks.size():
			continue
		var names_blob: String = ""
		var j: int = i + 1
		while j < toks.size():
			names_blob += ("" if names_blob.is_empty() else " ") + str(toks[j])
			j += 1
		for raw_n in names_blob.split(","):
			var nm: String = raw_n.strip_edges()
			if nm.is_empty():
				continue
			nm = nm.split(" ", false)[0]
			if nm.is_valid_identifier() and not seen.has(nm):
				seen[nm] = true
				names.append(nm)
	return names


func _gdshader_type_for_uniform(code: String, uname: String) -> String:
	if uname.is_empty():
		return ""
	for raw_line in code.split("\n"):
		var line: String = raw_line.strip_edges()
		var cmt2: int = line.find("//")
		if cmt2 >= 0:
			line = line.substr(0, cmt2).strip_edges()
		if not line.begins_with("uniform"):
			continue
		var sc2: int = line.find(";")
		if sc2 > 0:
			line = line.substr(0, sc2).strip_edges()
		var end2: int = line.length()
		var c2: int = line.find(":")
		var e2: int = line.find("=")
		if c2 >= 0:
			end2 = mini(end2, c2)
		if e2 >= 0:
			end2 = mini(end2, e2)
		var decl_p: String = line.substr(0, end2).strip_edges()
		var u1: int = decl_p.find("uniform")
		if u1 < 0:
			continue
		var after2: String = decl_p.substr(u1 + 7).strip_edges()
		var tok2: PackedStringArray = after2.split(" ", false)
		var ti: int = 0
		while ti < tok2.size() and str(tok2[ti]) in ["const", "highp", "mediump", "lowp", "instance"]:
			ti += 1
		if ti >= tok2.size() or ti + 1 >= tok2.size():
			continue
		var typ: String = str(tok2[ti])
		var blob: String = ""
		var tj: int = ti + 1
		while tj < tok2.size():
			blob += ("" if blob.is_empty() else " ") + str(tok2[tj])
			tj += 1
		for raw_n2 in blob.split(","):
			var nmx: String = raw_n2.strip_edges().split(" ", false)[0]
			if nmx == uname:
				if typ.begins_with("sampler"):
					return "sampler"
				return typ
	return ""


func _shader_default_variant_for_gdshader_type(typ: String) -> Variant:
	if typ.is_empty() or typ == "sampler":
		return null
	match typ:
		"float":
			return 0.0
		"int", "uint":
			return 0
		"bool":
			return false
		"vec2", "ivec2", "uvec2", "bvec2":
			return Vector2.ZERO
		"vec3", "ivec3", "uvec3", "bvec3":
			return Vector3.ZERO
		"vec4", "ivec4", "uvec4", "bvec4":
			return Vector4.ZERO
		"mat2", "mat3", "mat4":
			return null
		_:
			return 0.0


func _shader_saved_uniform_map_for_ui() -> Dictionary:
	var d: Dictionary = {}
	var raw_u: String = str(shader_preview_def_cache.get("shader_user_uniforms", "")).strip_edges()
	if not raw_u.is_empty():
		var parsed_u = JSON.parse_string(raw_u)
		if typeof(parsed_u) == TYPE_DICTIONARY:
			d = (parsed_u as Dictionary).duplicate(true)
	if not d.has("base_tint") and shader_preview_def_cache.has("shader_base_tint"):
		var c: Color = _editor_parse_color(shader_preview_def_cache.get("shader_base_tint"), Color.WHITE)
		d["base_tint"] = [c.r, c.g, c.b, c.a]
	if not d.has("rim_color") and shader_preview_def_cache.has("shader_rim_color"):
		var c2: Color = _editor_parse_color(shader_preview_def_cache.get("shader_rim_color"), Color(0.2, 0.35, 1.0, 1.0))
		d["rim_color"] = [c2.r, c2.g, c2.b, c2.a]
	if not d.has("rim_power") and shader_preview_def_cache.has("shader_rim_power"):
		d["rim_power"] = float(shader_preview_def_cache.get("shader_rim_power", 2.2))
	if not d.has("rim_intensity") and shader_preview_def_cache.has("shader_rim_intensity"):
		d["rim_intensity"] = float(shader_preview_def_cache.get("shader_rim_intensity", 0.35))
	if not d.has("shade_steps") and shader_preview_def_cache.has("shader_steps"):
		d["shade_steps"] = float(shader_preview_def_cache.get("shader_steps", 3.0))
	return d


func _shader_deferred_build_uniform_ui(shader_res: Shader, build_id: int) -> void:
	if shader_res == null or not is_instance_valid(self):
		return
	await get_tree().process_frame
	if not is_instance_valid(self) or build_id != shader_preview_uniform_ui_build_id:
		return
	await get_tree().process_frame
	if not is_instance_valid(self) or build_id != shader_preview_uniform_ui_build_id:
		return
	if shader_preview_active_path.is_empty():
		return
	_rebuild_shader_dynamic_uniform_ui(shader_res)
	_set_shader_live_feedback(
		"✓ %d uniform(s) — edits apply live. Save stores them in shader_user_uniforms (JSON)." % shader_dynamic_uniform_editors.size(),
		true
	)


func _rebuild_shader_dynamic_uniform_ui(sh: Shader) -> void:
	_clear_shader_dynamic_uniform_ui()
	if shader_dynamic_params_vbox == null or sh == null:
		return
	var sm_probe := ShaderMaterial.new()
	sm_probe.shader = sh
	var saved: Dictionary = _shader_saved_uniform_map_for_ui()
	var str_tok: Dictionary = _shader_saved_uniform_string_tokens()
	var entries: Array = _shader_ordered_uniform_entries(sh)
	if entries.is_empty():
		var empty_lab := Label.new()
		empty_lab.text = "No uniforms found. Use group_uniforms Name; and uniform lines in your .gdshader."
		empty_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		shader_dynamic_params_vbox.add_child(empty_lab)
		return
	var mod_root: String = ""
	var mid: int = mod_option.get_selected()
	if mid >= 0:
		mod_root = str(mod_entries[mid].get("path", "")).trim_suffix("/")
	var last_group: String = "\n"
	for spec in entries:
		var uname: String = str(spec["name"])
		var gname: String = str(spec["group"])
		if gname != last_group:
			var gh := Label.new()
			gh.text = gname.to_upper()
			gh.add_theme_font_size_override("font_size", 13)
			shader_dynamic_params_vbox.add_child(gh)
			last_group = gname
		var typ: String = str(spec["type"])
		var hr: Dictionary = spec["hr"]
		var v: Variant = null
		if saved.has(uname):
			v = _editor_json_to_shader_variant(saved[uname])
		if v == null:
			v = sm_probe.get_shader_parameter(uname)
		var ed: Control = null
		if typ.begins_with("sampler2D") or typ == "sampler2D":
			shader_preview_sampler_defaults[uname] = sm_probe.get_shader_parameter(uname)
			var cur_tex: Texture2D = null
			if v is Texture2D:
				cur_tex = v as Texture2D
			ed = _make_shader_sampler_dropdown(uname, cur_tex, str_tok.get(uname, ""), mod_root)
		elif typ in ["mat2", "mat3", "mat4"]:
			continue
		elif typ.begins_with("sampler"):
			continue
		elif v is Texture2D or v is Texture3D:
			continue
		else:
			if v == null:
				v = _shader_default_variant_for_gdshader_type(typ)
			if v == null:
				continue
			var use_slider: bool = bool(hr.get("has", false)) and typ in ["float", "int", "uint"]
			ed = _make_shader_uniform_editor_typed(uname, v, typ, hr, use_slider)
		if ed == null:
			continue
		var row := HBoxContainer.new()
		var lab := Label.new()
		lab.text = uname
		lab.custom_minimum_size.x = 160
		row.add_child(lab)
		ed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(ed)
		shader_dynamic_params_vbox.add_child(row)
		shader_dynamic_uniform_editors[uname] = ed
		_connect_shader_uniform_editor(ed)


func _make_shader_sampler_dropdown(_uname: String, cur_tex: Texture2D, saved_token: String, mod_root: String) -> OptionButton:
	var ob := OptionButton.new()
	ob.add_item("(Default)", 0)
	ob.set_item_metadata(0, "")
	var ix: int = 1
	ob.add_item("UV gradient", ix)
	ob.set_item_metadata(ix, SHADER_JSON_TEX_UV_GRADIENT)
	ix += 1
	for tp in _shader_preview_collect_mod_texture_paths(mod_root):
		ob.add_item(tp.get_file())
		ob.set_item_metadata(ix, tp)
		ix += 1
	var pick: int = 0
	if not saved_token.is_empty():
		for j in range(ob.item_count):
			var md: Variant = ob.get_item_metadata(j)
			if str(md) == saved_token:
				pick = j
				break
		if pick == 0 and saved_token == SHADER_JSON_TEX_UV_GRADIENT:
			pick = 1
	elif cur_tex != null:
		var rp: String = cur_tex.resource_path
		if not rp.is_empty():
			for j2 in range(ob.item_count):
				if str(ob.get_item_metadata(j2)) == rp:
					pick = j2
					break
		elif cur_tex is GradientTexture2D:
			pick = 1
	ob.select(pick)
	ob.set_meta("u_kind", "sampler")
	ob.set_meta("sampler_uname", _uname)
	return ob


func _make_shader_hslider_spin(mn: float, mx: float, st: float, val: float, as_int: bool) -> HBoxContainer:
	var hb := HBoxContainer.new()
	var sl := HSlider.new()
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.min_value = mn
	sl.max_value = mx
	sl.step = maxf(st, 0.0001) if not as_int else 1.0
	var cv: float = clampf(val, mn, mx)
	if as_int:
		cv = roundi(cv)
	sl.value = cv
	var sp := SpinBox.new()
	sp.custom_minimum_size.x = 76
	sp.min_value = mn
	sp.max_value = mx
	sp.step = maxf(st, 0.0001) if not as_int else 1.0
	sp.rounded = as_int
	sp.value = sl.value
	sl.value_changed.connect(func(x):
		var nx: float = roundf(x) if as_int else x
		sp.set_block_signals(true)
		sp.value = nx
		sp.set_block_signals(false)
		_on_dynamic_shader_uniform_changed())
	sp.value_changed.connect(func(x):
		sl.set_block_signals(true)
		sl.value = x
		sl.set_block_signals(false)
		_on_dynamic_shader_uniform_changed())
	hb.add_child(sl)
	hb.add_child(sp)
	hb.set_meta("u_kind", "slider_spin")
	hb.set_meta("as_int", as_int)
	return hb


func _make_shader_uniform_editor_typed(_uname: String, v: Variant, typ: String, hr: Dictionary, use_slider: bool) -> Control:
	var t: int = typeof(v)
	if typ in ["int", "uint"] and use_slider:
		var mn2: int = int(hr.get("mn", 0.0))
		var mx2: int = int(hr.get("mx", 10.0))
		var st2: int = maxi(1, int(hr.get("step", 1.0)))
		if mn2 >= mx2:
			mx2 = mn2 + 10
		return _make_shader_hslider_spin(float(mn2), float(mx2), float(st2), float(int(v)), true)
	if typ == "float" and use_slider:
		var mn: float = float(hr.get("mn", 0.0))
		var mx: float = float(hr.get("mx", 1.0))
		var st: float = float(hr.get("step", 0.01))
		if mn >= mx:
			mx = mn + 1.0
		return _make_shader_hslider_spin(mn, mx, st, float(v), false)
	if typ in ["int", "uint"]:
		var sbint := SpinBox.new()
		sbint.min_value = -2147483648
		sbint.max_value = 2147483647
		sbint.step = 1
		sbint.rounded = true
		sbint.value = int(float(v))
		sbint.set_meta("u_kind", "int")
		return sbint
	if typ == "float" or t == TYPE_FLOAT:
		var sb := SpinBox.new()
		sb.min_value = -999999.0
		sb.max_value = 999999.0
		sb.step = 0.01
		sb.value = float(v)
		sb.set_meta("u_kind", "float")
		return sb
	if t == TYPE_BOOL:
		var cb := CheckBox.new()
		cb.button_pressed = bool(v)
		cb.set_meta("u_kind", "bool")
		return cb
	if t == TYPE_COLOR:
		var le_c := LineEdit.new()
		var c: Color = v as Color
		le_c.text = "%s,%s,%s,%s" % [str(c.r), str(c.g), str(c.b), str(c.a)]
		le_c.set_meta("u_kind", "color")
		return le_c
	if t == TYPE_VECTOR2:
		var vb := VBoxContainer.new()
		var v2: Vector2 = v as Vector2
		var sx := SpinBox.new()
		sx.min_value = -999999.0
		sx.max_value = 999999.0
		sx.step = 0.01
		sx.value = v2.x
		var sy := SpinBox.new()
		sy.min_value = -999999.0
		sy.max_value = 999999.0
		sy.step = 0.01
		sy.value = v2.y
		var lx := Label.new()
		lx.text = "x"
		var ly := Label.new()
		ly.text = "y"
		var rx := HBoxContainer.new()
		rx.add_child(lx)
		rx.add_child(sx)
		var ry := HBoxContainer.new()
		ry.add_child(ly)
		ry.add_child(sy)
		sx.value_changed.connect(_on_dynamic_shader_uniform_changed)
		sy.value_changed.connect(_on_dynamic_shader_uniform_changed)
		vb.add_child(rx)
		vb.add_child(ry)
		vb.set_meta("u_kind", "vec2_xy")
		return vb
	if t == TYPE_VECTOR3:
		var le3 := LineEdit.new()
		var v3: Vector3 = v as Vector3
		le3.text = "%s,%s,%s" % [str(v3.x), str(v3.y), str(v3.z)]
		le3.set_meta("u_kind", "vec3")
		return le3
	if t == TYPE_VECTOR4:
		var le4 := LineEdit.new()
		var v4: Vector4 = v as Vector4
		le4.text = "%s,%s,%s,%s" % [str(v4.x), str(v4.y), str(v4.z), str(v4.w)]
		le4.set_meta("u_kind", "vec4")
		return le4
	return null


func _connect_shader_uniform_editor(ed: Control) -> void:
	if ed is SpinBox:
		(ed as SpinBox).value_changed.connect(_on_dynamic_shader_uniform_changed)
	elif ed is CheckBox:
		(ed as CheckBox).toggled.connect(_on_dynamic_shader_uniform_changed)
	elif ed is LineEdit:
		(ed as LineEdit).text_changed.connect(_on_dynamic_shader_uniform_changed)
	elif ed is OptionButton:
		(ed as OptionButton).item_selected.connect(_on_dynamic_shader_uniform_changed)
	elif ed is HBoxContainer and str(ed.get_meta("u_kind", "")) == "slider_spin":
		pass


func _read_shader_uniform_editor(ed: Control) -> Variant:
	var kind: String = str(ed.get_meta("u_kind", ""))
	if ed is OptionButton and kind == "sampler":
		var md: Variant = (ed as OptionButton).get_item_metadata((ed as OptionButton).selected)
		if md == null or str(md).is_empty():
			var sun: String = str(ed.get_meta("sampler_uname", ""))
			return shader_preview_sampler_defaults.get(sun)
		var tok: String = str(md)
		if tok == SHADER_JSON_TEX_UV_GRADIENT:
			return _editor_make_uv_gradient_texture()
		var ltex := _editor_load_texture2d_from_path(tok)
		if ltex != null:
			return ltex
		return shader_preview_sampler_defaults.get(str(ed.get_meta("sampler_uname", "")))
	if kind == "slider_spin":
		var spn: SpinBox = null
		for c in ed.get_children():
			if c is SpinBox:
				spn = c as SpinBox
				break
		if spn == null:
			return null
		if ed.get_meta("as_int", false):
			return int(spn.value)
		return float(spn.value)
	if kind == "vec2_xy":
		var spins: Array[SpinBox] = []
		for c2 in ed.get_children():
			if c2 is HBoxContainer:
				for c3 in c2.get_children():
					if c3 is SpinBox:
						spins.append(c3 as SpinBox)
		if spins.size() < 2:
			return Vector2.ZERO
		return Vector2(float(spins[0].value), float(spins[1].value))
	if ed is SpinBox:
		var sb: SpinBox = ed as SpinBox
		if kind == "int":
			return int(sb.value)
		return float(sb.value)
	if ed is CheckBox:
		return (ed as CheckBox).button_pressed
	if ed is LineEdit:
		var txt: String = (ed as LineEdit).text.strip_edges()
		match kind:
			"color":
				return _editor_parse_color(txt if not txt.is_empty() else "1,1,1,1", Color.WHITE)
			"vec2":
				var p2: PackedStringArray = txt.split(",", false)
				if p2.size() >= 2:
					return Vector2(float(p2[0]), float(p2[1]))
				return Vector2.ZERO
			"vec3":
				var p3: PackedStringArray = txt.split(",", false)
				if p3.size() >= 3:
					return Vector3(float(p3[0]), float(p3[1]), float(p3[2]))
				return Vector3.ZERO
			"vec4":
				var p4: PackedStringArray = txt.split(",", false)
				if p4.size() >= 4:
					return Vector4(float(p4[0]), float(p4[1]), float(p4[2]), float(p4[3]))
				return Vector4.ZERO
	return null


func _shader_strip_invalid_preview_uniforms(d: Dictionary) -> void:
	var ks: Array = d.keys()
	for k in ks:
		var v: Variant = d[k]
		if v == null or v is String:
			if v is String:
				var s: String = str(v)
				if s == SHADER_JSON_TEX_UV_GRADIENT:
					d[k] = _editor_make_uv_gradient_texture()
				else:
					var tx := _editor_load_texture2d_from_path(s)
					if tx != null:
						d[k] = tx
					else:
						d.erase(k)
			else:
				d.erase(k)


func _collect_dynamic_shader_uniforms_dict() -> Dictionary:
	var out: Dictionary = _shader_merged_uniform_dict_for_apply().duplicate()
	if shader_dynamic_uniform_editors.is_empty():
		_shader_strip_invalid_preview_uniforms(out)
		return out
	for uname in shader_dynamic_uniform_editors.keys():
		var val: Variant = _read_shader_uniform_editor(shader_dynamic_uniform_editors[uname])
		if val != null:
			out[str(uname)] = val
		elif shader_dynamic_uniform_editors[uname] is OptionButton:
			var def_t: Variant = shader_preview_sampler_defaults.get(uname)
			if def_t != null:
				out[str(uname)] = def_t
			else:
				out.erase(str(uname))
	_shader_strip_invalid_preview_uniforms(out)
	return out


func _collect_shader_uniforms_for_json_save() -> Dictionary:
	var serial: Dictionary = {}
	if shader_dynamic_uniform_editors.is_empty():
		var merged_fallback: Dictionary = _shader_merged_uniform_dict_for_apply()
		for k in merged_fallback.keys():
			serial[str(k)] = _shader_variant_to_json_value(merged_fallback[k])
		return serial
	for uname in shader_dynamic_uniform_editors.keys():
		var edc: Control = shader_dynamic_uniform_editors[uname]
		if edc is OptionButton and str(edc.get_meta("u_kind", "")) == "sampler":
			var md2: Variant = (edc as OptionButton).get_item_metadata((edc as OptionButton).selected)
			if md2 == null or str(md2).is_empty():
				continue
			serial[str(uname)] = str(md2)
			continue
		var val2: Variant = _read_shader_uniform_editor(edc)
		if val2 != null:
			serial[str(uname)] = _shader_variant_to_json_value(val2)
	return serial


func _shader_variant_to_json_value(v: Variant):
	if v is Texture2D:
		var tt: Texture2D = v as Texture2D
		var rpp: String = tt.resource_path
		if not rpp.is_empty():
			return rpp
		return SHADER_JSON_TEX_UV_GRADIENT
	if v is Color:
		var c: Color = v as Color
		return [c.r, c.g, c.b, c.a]
	if v is Vector2:
		var v2: Vector2 = v as Vector2
		return [v2.x, v2.y]
	if v is Vector3:
		var v3: Vector3 = v as Vector3
		return [v3.x, v3.y, v3.z]
	if v is Vector4:
		var v4: Vector4 = v as Vector4
		return [v4.x, v4.y, v4.z, v4.w]
	return v


func _shader_preview_push_uniforms_to_materials(params: Dictionary) -> int:
	var updated: int = 0
	if shader_preview_current_model == null or params.is_empty():
		return 0
	var stack: Array[Node] = [shader_preview_current_model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n as MeshInstance3D
			if mi.mesh == null:
				continue
			for surf_idx in range(mi.mesh.get_surface_count()):
				var smat: ShaderMaterial = null
				var ovr: Material = mi.get_surface_override_material(surf_idx)
				if ovr is ShaderMaterial:
					smat = ovr as ShaderMaterial
				else:
					var act: Material = mi.get_active_material(surf_idx)
					if act is ShaderMaterial:
						smat = act as ShaderMaterial
				if smat == null:
					continue
				for uk in params.keys():
					var pvv: Variant = params[uk]
					if pvv is String:
						continue
					if pvv == null:
						continue
					smat.set_shader_parameter(str(uk), pvv)
				updated += 1
		for ch in n.get_children():
			stack.append(ch)
	return updated


func _shader_preview_refresh_viewport() -> void:
	if shader_preview_viewport != null:
		shader_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if shader_preview_viewport_container != null:
		shader_preview_viewport_container.queue_redraw()


func _set_shader_live_feedback(message: String, ok: bool) -> void:
	if shader_live_feedback_label == null:
		return
	shader_live_feedback_label.text = message
	if ok:
		shader_live_feedback_label.add_theme_color_override("font_color", Color(0.4, 0.88, 0.55, 1.0))
	else:
		shader_live_feedback_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35, 1.0))


func _on_dynamic_shader_uniform_changed(_arg = null) -> void:
	if shader_preview_active_path.is_empty():
		_set_shader_live_feedback(
			"⚠ Select a shader first.",
			false
		)
		return
	var cnt: int = _shader_preview_push_uniforms_to_materials(_collect_dynamic_shader_uniforms_dict())
	_shader_preview_refresh_viewport()
	if cnt <= 0:
		_set_shader_live_feedback(
			"⚠ No shader materials on the model — pick a shader again or reload the mod.",
			false
		)
	else:
		_set_shader_live_feedback(
			"✓ Live preview updated · %d surface(s) · t=%d ms (change base_tint or rim to see it)" % [cnt, Time.get_ticks_msec()],
			true
		)


func _on_shader_preview_viewport_gui_input(event: InputEvent) -> void:
	if shader_preview_current_model == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			shader_preview_camera_distance = clampf(shader_preview_camera_distance - 0.45, shader_preview_min_zoom, shader_preview_max_zoom)
			_shader_preview_update_camera()
			accept_event()
			return
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			shader_preview_camera_distance = clampf(shader_preview_camera_distance + 0.45, shader_preview_min_zoom, shader_preview_max_zoom)
			_shader_preview_update_camera()
			accept_event()
			return
	if event is InputEventMouseMotion:
		var motion2 := event as InputEventMouseMotion
		var panning: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or (
			Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.is_key_pressed(KEY_SHIFT)
		)
		var orbiting: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_key_pressed(KEY_SHIFT)
		if panning:
			_shader_preview_pan_camera(motion2.relative)
			accept_event()
			return
		if orbiting:
			shader_preview_cam_yaw -= motion2.relative.x * 0.0055
			shader_preview_cam_pitch -= motion2.relative.y * 0.0055
			shader_preview_cam_pitch = clampf(shader_preview_cam_pitch, -SHADER_PREVIEW_PITCH_LIMIT, SHADER_PREVIEW_PITCH_LIMIT)
			_shader_preview_update_camera()
			accept_event()


func _input(event: InputEvent) -> void:
	if shader_preview_viewport_container == null or shader_preview_current_model == null:
		return
	if section_option.get_selected() != 6:
		return
	var vr: Rect2 = shader_preview_viewport_container.get_rect()
	if not vr.has_point(shader_preview_viewport_container.get_local_mouse_position()):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_HOME:
			_shader_preview_fit_camera(shader_preview_current_model)
			accept_event()
