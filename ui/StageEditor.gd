extends Control

@export var stages_roots: Array[String] = ["user://stages/", "res://stages/"]
@export var mods_root: String = "user://mods/"
@export var preview_character_mod_name: String = "sample_fighter"

@onready var margin_container: Control = $MarginContainer
@onready var vbox_container: Control = $MarginContainer/VBoxContainer
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var top_row: Control = $MarginContainer/VBoxContainer/TopRow
@onready var content_scroll: Control = $MarginContainer/VBoxContainer/ContentScroll
@onready var content_vbox: Control = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox
@onready var form_grid: Control = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid
@onready var preview_panel: Panel = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel
@onready var preview_viewport_container: SubViewportContainer = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer
@onready var preview_viewport: SubViewport = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport

@onready var stage_option: OptionButton = $MarginContainer/VBoxContainer/TopRow/StageOption
@onready var show_collision_check: CheckBox = $MarginContainer/VBoxContainer/TopRow/ShowCollisionCheck
@onready var reload_button: Button = $MarginContainer/VBoxContainer/TopRow/ReloadButton
@onready var save_button: Button = $MarginContainer/VBoxContainer/TopRow/SaveButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/TopRow/BackButton

@onready var p1_x_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/P1XSpin
@onready var p1_y_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/P1YSpin
@onready var p1_z_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/P1ZSpin
@onready var p2_x_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/P2XSpin
@onready var p2_y_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/P2YSpin
@onready var p2_z_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/P2ZSpin
@onready var stage_offset_x_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/StageOffsetXSpin
@onready var stage_offset_y_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/StageOffsetYSpin
@onready var stage_offset_z_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/StageOffsetZSpin
@onready var stage_rotation_x_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/StageRotationXSpin
@onready var stage_rotation_y_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/StageRotationYSpin
@onready var stage_rotation_z_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/StageRotationZSpin
@onready var stage_scale_x_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/StageScaleXSpin
@onready var stage_scale_y_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/StageScaleYSpin
@onready var stage_scale_z_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/StageScaleZSpin
@onready var floor_y_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/FloorYSpin
@onready var arena_left_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/ArenaLeftSpin
@onready var arena_right_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/ArenaRightSpin
@onready var smash_blast_left_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/SmashBlastLeftSpin
@onready var smash_blast_right_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/SmashBlastRightSpin
@onready var smash_blast_top_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/SmashBlastTopSpin
@onready var smash_blast_bottom_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/SmashBlastBottomSpin
@onready var cam_x_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/CamXSpin
@onready var cam_y_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/CamYSpin
@onready var cam_z_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/CamZSpin
@onready var look_x_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/LookXSpin
@onready var look_y_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/LookYSpin
@onready var look_z_spin: SpinBox = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/FormGrid/LookZSpin

@onready var preview_camera: Camera3D = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewRoot/Camera3D
@onready var preview_stage_root: Node3D = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewRoot/StageRoot
@onready var preview_character_root: Node3D = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewRoot/CharacterRoot
@onready var collision_debug_root: Node3D = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewRoot/CollisionDebugRoot
@onready var p1_marker: MeshInstance3D = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewRoot/P1Marker
@onready var p2_marker: MeshInstance3D = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewRoot/P2Marker
@onready var left_bound: MeshInstance3D = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewRoot/LeftBound
@onready var right_bound: MeshInstance3D = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewRoot/RightBound
@onready var camera_marker: MeshInstance3D = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewRoot/CameraMarker
@onready var floor_mesh: MeshInstance3D = $MarginContainer/VBoxContainer/ContentScroll/ContentVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewRoot/Floor
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel

var stage_entries: Array[Dictionary] = []
var current_stage_folder: String = ""
var current_stage_def_path: String = ""
var current_stage_def: Dictionary = {}
var preview_stage_instance: Node = null
var preview_p1_character: Node3D = null
var preview_p2_character: Node3D = null
var is_applying_stage_def: bool = false
var camera_target: Vector3 = Vector3(0.0, 1.0, 0.0)
var camera_distance: float = 10.0
var camera_yaw: float = 0.0
var camera_pitch: float = -0.2
var is_orbiting: bool = false
var is_panning: bool = false
var user_camera_dirty: bool = false


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	_connect_signals()
	_setup_preview_materials()
	_setup_preview_camera_defaults()
	_scan_stages()
	_select_first_stage()


func _connect_signals() -> void:
	stage_option.item_selected.connect(_on_stage_selected)
	show_collision_check.toggled.connect(_on_show_collision_toggled)
	reload_button.pressed.connect(_on_reload_pressed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)
	preview_viewport_container.gui_input.connect(_on_preview_gui_input)
	var all_spins: Array[SpinBox] = [
		p1_x_spin, p1_y_spin, p1_z_spin,
		p2_x_spin, p2_y_spin, p2_z_spin,
		stage_offset_x_spin, stage_offset_y_spin, stage_offset_z_spin,
		stage_rotation_x_spin, stage_rotation_y_spin, stage_rotation_z_spin,
		stage_scale_x_spin, stage_scale_y_spin, stage_scale_z_spin,
		floor_y_spin, arena_left_spin, arena_right_spin,
		smash_blast_left_spin, smash_blast_right_spin, smash_blast_top_spin, smash_blast_bottom_spin
	]
	for spin in all_spins:
		spin.value_changed.connect(_on_values_changed)
	var camera_spins: Array[SpinBox] = [
		cam_x_spin, cam_y_spin, cam_z_spin,
		look_x_spin, look_y_spin, look_z_spin
	]
	for spin in camera_spins:
		spin.value_changed.connect(_on_camera_values_changed)


func _scan_stages() -> void:
	stage_entries.clear()
	stage_option.clear()
	for entry in ContentResolver.scan_stage_entries(stages_roots):
		stage_entries.append({"name": str(entry.get("name", "")), "folder": str(entry.get("folder_path", ""))})
	stage_entries.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
	for i in range(stage_entries.size()):
		stage_option.add_item(str(stage_entries[i].get("name", "")), i)
	if stage_entries.is_empty():
		status_label.text = "No stage folders found in user://stages or res://stages."


func _is_stage_folder(folder: String) -> bool:
	return ContentResolver.is_stage_folder(folder)


func _select_first_stage() -> void:
	if stage_entries.is_empty():
		status_label.text = "No stage folders found."
		return
	var selected_index: int = 0
	var preferred_stage_name: String = str(get_tree().get_meta("stage_editor_stage_name", ""))
	if not preferred_stage_name.is_empty():
		for i in range(stage_entries.size()):
			if str(stage_entries[i].get("name", "")) == preferred_stage_name:
				selected_index = i
				break
	stage_option.select(selected_index)
	_on_stage_selected(selected_index)


func _on_stage_selected(index: int) -> void:
	if index < 0 or index >= stage_entries.size():
		return
	current_stage_folder = str(stage_entries[index].get("folder", ""))
	current_stage_def_path = "%s/stage.def" % current_stage_folder
	current_stage_def = _load_stage_def(current_stage_def_path)
	_apply_def_to_form()
	_reload_preview_stage()
	_reload_preview_characters()
	user_camera_dirty = false
	_update_preview()
	status_label.text = "Loaded stage: %s" % str(stage_entries[index].get("name", ""))


func _on_reload_pressed() -> void:
	if current_stage_folder.is_empty():
		return
	current_stage_def = _load_stage_def(current_stage_def_path)
	_apply_def_to_form()
	_reload_preview_stage()
	_reload_preview_characters()
	user_camera_dirty = false
	_update_preview()


func _on_save_pressed() -> void:
	if current_stage_folder.is_empty():
		return
	_collect_form_to_def()
	var out_lines: PackedStringArray = []
	_write_ordered_key(out_lines, "name", current_stage_def.get("name", current_stage_folder.get_file()))
	_write_ordered_key(out_lines, "music", current_stage_def.get("music", ""))
	_write_ordered_key(out_lines, "music_loop", current_stage_def.get("music_loop", true))
	_write_ordered_key(out_lines, "music_volume_db", current_stage_def.get("music_volume_db", -6.0))
	_write_ordered_key(out_lines, "spawn_p1", current_stage_def.get("spawn_p1", Vector3(-1.25, 0.0, 0.0)))
	_write_ordered_key(out_lines, "spawn_p2", current_stage_def.get("spawn_p2", Vector3(1.25, 0.0, 0.0)))
	_write_ordered_key(out_lines, "stage_offset", current_stage_def.get("stage_offset", Vector3.ZERO))
	_write_ordered_key(out_lines, "stage_rotation", current_stage_def.get("stage_rotation", Vector3.ZERO))
	_write_ordered_key(out_lines, "stage_scale", current_stage_def.get("stage_scale", Vector3.ONE))
	_write_ordered_key(out_lines, "floor_y", current_stage_def.get("floor_y", 0.0))
	_write_ordered_key(out_lines, "arena_left", current_stage_def.get("arena_left", -30.0))
	_write_ordered_key(out_lines, "arena_right", current_stage_def.get("arena_right", 30.0))
	_write_ordered_key(out_lines, "smash_blast_left", current_stage_def.get("smash_blast_left", -32.0))
	_write_ordered_key(out_lines, "smash_blast_right", current_stage_def.get("smash_blast_right", 32.0))
	_write_ordered_key(out_lines, "smash_blast_top", current_stage_def.get("smash_blast_top", 22.0))
	_write_ordered_key(out_lines, "smash_blast_bottom", current_stage_def.get("smash_blast_bottom", -9.0))
	_write_ordered_key(out_lines, "fall_reset_y", current_stage_def.get("fall_reset_y", -8.0))
	_write_ordered_key(out_lines, "camera_position", current_stage_def.get("camera_position", Vector3(0.0, 4.1319685, 12.0)))
	_write_ordered_key(out_lines, "camera_look_target", current_stage_def.get("camera_look_target", Vector3(0.0, 1.0, 0.0)))
	var file := FileAccess.open(current_stage_def_path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Failed to save stage.def"
		return
	file.store_string("\n".join(out_lines) + "\n")
	status_label.text = "Saved %s" % current_stage_def_path


func _write_ordered_key(out_lines: PackedStringArray, key: String, value) -> void:
	out_lines.append("%s = %s" % [key, _def_value_to_string(value)])


func _def_value_to_string(value) -> String:
	if value is Vector3:
		var v: Vector3 = value
		return "%.3f, %.3f, %.3f" % [v.x, v.y, v.z]
	if value is bool:
		return "true" if bool(value) else "false"
	return str(value)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")


func _on_values_changed(_value: float) -> void:
	if is_applying_stage_def:
		return
	_collect_form_to_def()
	_update_preview()


func _on_camera_values_changed(_value: float) -> void:
	if is_applying_stage_def:
		return
	# Camera fields are explicit camera edits; sync preview camera from form.
	user_camera_dirty = false
	_collect_form_to_def()
	_update_preview()


func _apply_def_to_form() -> void:
	is_applying_stage_def = true
	var p1: Vector3 = _to_vector3(current_stage_def.get("spawn_p1", Vector3(-1.25, 0.0, 0.0)))
	var p2: Vector3 = _to_vector3(current_stage_def.get("spawn_p2", Vector3(1.25, 0.0, 0.0)))
	var stage_offset: Vector3 = _to_vector3(current_stage_def.get("stage_offset", Vector3.ZERO))
	var stage_rotation: Vector3 = _to_vector3(current_stage_def.get("stage_rotation", Vector3.ZERO))
	var stage_scale: Vector3 = _to_vector3(current_stage_def.get("stage_scale", Vector3.ONE))
	var cam_pos: Vector3 = _to_vector3(current_stage_def.get("camera_position", Vector3(0.0, 4.1319685, 12.0)))
	var look_target: Vector3 = _to_vector3(current_stage_def.get("camera_look_target", Vector3(0.0, 1.0, 0.0)))
	p1_x_spin.value = p1.x
	p1_y_spin.value = p1.y
	p1_z_spin.value = p1.z
	p2_x_spin.value = p2.x
	p2_y_spin.value = p2.y
	p2_z_spin.value = p2.z
	stage_offset_x_spin.value = stage_offset.x
	stage_offset_y_spin.value = stage_offset.y
	stage_offset_z_spin.value = stage_offset.z
	stage_rotation_x_spin.value = stage_rotation.x
	stage_rotation_y_spin.value = stage_rotation.y
	stage_rotation_z_spin.value = stage_rotation.z
	stage_scale_x_spin.value = stage_scale.x
	stage_scale_y_spin.value = stage_scale.y
	stage_scale_z_spin.value = stage_scale.z
	floor_y_spin.value = float(current_stage_def.get("floor_y", 0.0))
	arena_left_spin.value = float(current_stage_def.get("arena_left", -30.0))
	arena_right_spin.value = float(current_stage_def.get("arena_right", 30.0))
	smash_blast_left_spin.value = float(current_stage_def.get("smash_blast_left", current_stage_def.get("blast_left", -32.0)))
	smash_blast_right_spin.value = float(current_stage_def.get("smash_blast_right", current_stage_def.get("blast_right", 32.0)))
	smash_blast_top_spin.value = float(current_stage_def.get("smash_blast_top", current_stage_def.get("blast_top", 22.0)))
	smash_blast_bottom_spin.value = float(current_stage_def.get("smash_blast_bottom", current_stage_def.get("blast_bottom", -9.0)))
	cam_x_spin.value = cam_pos.x
	cam_y_spin.value = cam_pos.y
	cam_z_spin.value = cam_pos.z
	look_x_spin.value = look_target.x
	look_y_spin.value = look_target.y
	look_z_spin.value = look_target.z
	is_applying_stage_def = false


func _collect_form_to_def() -> void:
	current_stage_def["spawn_p1"] = Vector3(p1_x_spin.value, p1_y_spin.value, p1_z_spin.value)
	current_stage_def["spawn_p2"] = Vector3(p2_x_spin.value, p2_y_spin.value, p2_z_spin.value)
	current_stage_def["stage_offset"] = Vector3(stage_offset_x_spin.value, stage_offset_y_spin.value, stage_offset_z_spin.value)
	current_stage_def["stage_rotation"] = Vector3(
		stage_rotation_x_spin.value,
		stage_rotation_y_spin.value,
		stage_rotation_z_spin.value
	)
	current_stage_def["stage_scale"] = Vector3(
		stage_scale_x_spin.value,
		stage_scale_y_spin.value,
		stage_scale_z_spin.value
	)
	current_stage_def["floor_y"] = floor_y_spin.value
	current_stage_def["arena_left"] = arena_left_spin.value
	current_stage_def["arena_right"] = arena_right_spin.value
	current_stage_def["smash_blast_left"] = smash_blast_left_spin.value
	current_stage_def["smash_blast_right"] = smash_blast_right_spin.value
	current_stage_def["smash_blast_top"] = smash_blast_top_spin.value
	current_stage_def["smash_blast_bottom"] = smash_blast_bottom_spin.value
	# Keep legacy aliases for compatibility with older stage defs.
	current_stage_def["blast_left"] = smash_blast_left_spin.value
	current_stage_def["blast_right"] = smash_blast_right_spin.value
	current_stage_def["blast_top"] = smash_blast_top_spin.value
	current_stage_def["blast_bottom"] = smash_blast_bottom_spin.value
	current_stage_def["camera_position"] = Vector3(cam_x_spin.value, cam_y_spin.value, cam_z_spin.value)
	current_stage_def["camera_look_target"] = Vector3(look_x_spin.value, look_y_spin.value, look_z_spin.value)


func _reload_preview_stage() -> void:
	for child in preview_stage_root.get_children():
		child.queue_free()
	preview_stage_instance = null
	var model_path: String = _find_stage_model_path(current_stage_folder)
	if model_path.is_empty():
		return
	var stage_node: Node = _load_stage_node(model_path)
	if stage_node == null:
		return
	preview_stage_instance = stage_node
	preview_stage_root.add_child(stage_node)
	_rebuild_collision_debug()


func _update_preview() -> void:
	var p1: Vector3 = _to_vector3(current_stage_def.get("spawn_p1", Vector3(-1.25, 0.0, 0.0)))
	var p2: Vector3 = _to_vector3(current_stage_def.get("spawn_p2", Vector3(1.25, 0.0, 0.0)))
	var stage_offset: Vector3 = _to_vector3(current_stage_def.get("stage_offset", Vector3.ZERO))
	var stage_rotation: Vector3 = _to_vector3(current_stage_def.get("stage_rotation", Vector3.ZERO))
	var stage_scale: Vector3 = _to_vector3(current_stage_def.get("stage_scale", Vector3.ONE))
	var floor_y: float = float(current_stage_def.get("floor_y", 0.0))
	var arena_left: float = float(current_stage_def.get("arena_left", -30.0))
	var arena_right: float = float(current_stage_def.get("arena_right", 30.0))
	var cam_pos: Vector3 = _to_vector3(current_stage_def.get("camera_position", Vector3(0.0, 4.1319685, 12.0)))
	var look_target: Vector3 = _to_vector3(current_stage_def.get("camera_look_target", Vector3(0.0, 1.0, 0.0)))

	p1_marker.position = p1
	p2_marker.position = p2
	if preview_p1_character != null:
		preview_p1_character.position = p1
		var look_tgt_p1: Vector3 = Vector3(p2.x, p1.y, p2.z)
		if not p1.is_equal_approx(look_tgt_p1):
			preview_p1_character.look_at(look_tgt_p1, Vector3.UP)
	if preview_p2_character != null:
		preview_p2_character.position = p2
		var look_tgt_p2: Vector3 = Vector3(p1.x, p2.y, p1.z)
		if not p2.is_equal_approx(look_tgt_p2):
			preview_p2_character.look_at(look_tgt_p2, Vector3.UP)
	left_bound.position = Vector3(arena_left, floor_y + 1.0, 0.0)
	right_bound.position = Vector3(arena_right, floor_y + 1.0, 0.0)
	camera_marker.position = cam_pos
	floor_mesh.position.y = floor_y
	if preview_stage_instance is Node3D:
		var preview_stage_node := preview_stage_instance as Node3D
		preview_stage_node.position = stage_offset
		preview_stage_node.rotation_degrees = stage_rotation
		preview_stage_node.scale = stage_scale
	_rebuild_collision_debug()
	if not user_camera_dirty:
		camera_target = look_target
		var to_camera: Vector3 = cam_pos - camera_target
		camera_distance = maxf(1.2, to_camera.length())
		camera_yaw = atan2(to_camera.x, to_camera.z)
		camera_pitch = asin(clampf(to_camera.y / camera_distance, -1.0, 1.0))
		_update_preview_camera_transform()


func _setup_preview_materials() -> void:
	_apply_marker_material(p1_marker, Color(0.2, 0.9, 1.0, 1.0))
	_apply_marker_material(p2_marker, Color(1.0, 0.4, 0.2, 1.0))
	_apply_marker_material(left_bound, Color(1.0, 0.2, 0.2, 0.85))
	_apply_marker_material(right_bound, Color(1.0, 0.2, 0.2, 0.85))
	_apply_marker_material(camera_marker, Color(0.2, 1.0, 0.35, 1.0))
	var floor_mat := StandardMaterial3D.new()
	floor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_mat.albedo_color = Color(0.55, 0.58, 0.65, 1.0)
	floor_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	floor_mesh.material_override = floor_mat


func _apply_marker_material(mesh_node: MeshInstance3D, color: Color) -> void:
	if mesh_node == null:
		return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mesh_node.material_override = mat


func _on_show_collision_toggled(enabled: bool) -> void:
	collision_debug_root.visible = enabled
	if enabled:
		_rebuild_collision_debug()


func _find_stage_model_path(folder: String) -> String:
	return ContentResolver.find_stage_model_path(folder, _load_stage_def("%s/stage.def" % folder))


func _normalize_root(root: String) -> String:
	var normalized: String = root.strip_edges()
	if normalized.is_empty():
		return ""
	if not normalized.ends_with("/"):
		normalized += "/"
	return normalized


func _load_stage_node(path: String) -> Node:
	var loaded = ResourceLoader.load(path)
	if loaded is PackedScene:
		return (loaded as PackedScene).instantiate()
	var lower: String = path.to_lower()
	if lower.ends_with(".gltf") or lower.ends_with(".glb"):
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		if gltf.append_from_file(path, state) == OK:
			return gltf.generate_scene(state)
	return null


func _reload_preview_characters() -> void:
	for child in preview_character_root.get_children():
		child.queue_free()
	preview_p1_character = null
	preview_p2_character = null
	var model_path: String = _find_character_model_path(preview_character_mod_name)
	if model_path.is_empty():
		return
	var def_path: String = _find_character_def_path(preview_character_mod_name)
	var def_data: Dictionary = _load_character_def(def_path)
	var p1_model_node := _load_character_model_node(model_path)
	if p1_model_node == null:
		return
	var p2_model_node := _load_character_model_node(model_path)
	if p2_model_node == null:
		return
	_apply_character_visual_settings(p1_model_node, def_data)
	_apply_character_visual_settings(p2_model_node, def_data)
	preview_character_root.add_child(p1_model_node)
	preview_character_root.add_child(p2_model_node)
	preview_p1_character = p1_model_node
	preview_p2_character = p2_model_node


func _find_character_model_path(mod_name: String) -> String:
	var candidates: Array[String] = []
	var user_mod_root: String = "%s%s/" % [mods_root, mod_name]
	var res_mod_root: String = "res://mods/%s/" % mod_name
	candidates.append("%smodel.glb" % user_mod_root)
	candidates.append("%smodel.gltf" % user_mod_root)
	candidates.append("%smodel.glb" % res_mod_root)
	candidates.append("%smodel.gltf" % res_mod_root)
	for candidate in candidates:
		if _is_model_path_valid(candidate):
			return candidate
	var user_found: String = _find_first_model_in_folder(user_mod_root)
	if not user_found.is_empty():
		return user_found
	return _find_first_model_in_folder(res_mod_root)


func _find_character_def_path(mod_name: String) -> String:
	var user_path: String = "%s%s/character.def" % [mods_root, mod_name]
	if FileAccess.file_exists(user_path):
		return user_path
	var res_path: String = "res://mods/%s/character.def" % mod_name
	if FileAccess.file_exists(res_path):
		return res_path
	return ""


func _find_first_model_in_folder(folder: String) -> String:
	var dir := DirAccess.open(folder)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var item: String = dir.get_next()
	while not item.is_empty():
		if not dir.current_is_dir():
			var lower: String = item.to_lower()
			if lower.ends_with(".glb") or lower.ends_with(".gltf"):
				var candidate: String = "%s%s" % [folder, item]
				if _is_model_path_valid(candidate):
					dir.list_dir_end()
					return candidate
		item = dir.get_next()
	dir.list_dir_end()
	return ""


func _is_model_path_valid(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	if file.get_length() <= 0:
		return false
	var lower: String = path.to_lower()
	if lower.ends_with(".glb"):
		if file.get_length() < 4:
			return false
		var magic := file.get_buffer(4)
		return magic.size() == 4 and magic[0] == 0x67 and magic[1] == 0x6C and magic[2] == 0x54 and magic[3] == 0x46
	if lower.ends_with(".gltf"):
		var text: String = file.get_as_text().strip_edges()
		return text.begins_with("{")
	return false


func _load_character_model_node(path: String) -> Node3D:
	if not path.begins_with("user://"):
		var loaded = ResourceLoader.load(path)
		if loaded is PackedScene:
			var inst := (loaded as PackedScene).instantiate()
			if inst is Node3D:
				return inst as Node3D
	var lower: String = path.to_lower()
	if lower.ends_with(".gltf") or lower.ends_with(".glb"):
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		if gltf.append_from_file(path, state) == OK:
			var scene: Node = gltf.generate_scene(state)
			if scene is Node3D:
				return scene as Node3D
	return null


func _load_character_def(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var result: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with(";") or line.begins_with("#"):
			continue
		var split: PackedStringArray = line.split("=", false, 1)
		if split.size() == 2:
			result[split[0].strip_edges()] = split[1].strip_edges()
	return result


func _apply_character_visual_settings(model_node: Node3D, def_data: Dictionary) -> void:
	var uniform_scale: float = float(def_data.get("model_scale", 1.0))
	var sx: float = float(def_data.get("model_scale_x", uniform_scale))
	var sy: float = float(def_data.get("model_scale_y", uniform_scale))
	var sz: float = float(def_data.get("model_scale_z", uniform_scale))
	model_node.scale = Vector3(sx, sy, sz)
	model_node.position.y += float(def_data.get("model_offset_y", 0.0))


func _load_stage_def(path: String) -> Dictionary:
	return ContentResolver.load_stage_def(path)


func _parse_stage_def_value(raw_value: String):
	var lower: String = raw_value.to_lower()
	if lower == "true":
		return true
	if lower == "false":
		return false
	if raw_value.is_valid_float():
		return raw_value.to_float()
	if raw_value.contains(","):
		var parts: PackedStringArray = raw_value.split(",", false)
		if parts.size() >= 3:
			return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
	return raw_value


func _to_vector3(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO


func _rebuild_collision_debug() -> void:
	for child in collision_debug_root.get_children():
		child.queue_free()
	if not show_collision_check.button_pressed:
		return
	if preview_stage_instance == null:
		return
	var collision_nodes: Array[Node] = preview_stage_instance.find_children("*", "CollisionShape3D", true, false)
	for node in collision_nodes:
		if not (node is CollisionShape3D):
			continue
		var shape_node: CollisionShape3D = node as CollisionShape3D
		if shape_node.shape == null:
			continue
		var debug_mesh := MeshInstance3D.new()
		var mesh := _shape_to_debug_mesh(shape_node.shape)
		if mesh == null:
			continue
		debug_mesh.mesh = mesh
		debug_mesh.global_transform = shape_node.global_transform
		debug_mesh.material_override = _make_collision_debug_material()
		collision_debug_root.add_child(debug_mesh)


func _shape_to_debug_mesh(shape: Shape3D) -> Mesh:
	if shape is BoxShape3D:
		var box_shape := shape as BoxShape3D
		var box_mesh := BoxMesh.new()
		box_mesh.size = box_shape.size
		return box_mesh
	if shape is SphereShape3D:
		var sphere_shape := shape as SphereShape3D
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = sphere_shape.radius
		sphere_mesh.height = sphere_shape.radius * 2.0
		return sphere_mesh
	if shape is CapsuleShape3D:
		var capsule_shape := shape as CapsuleShape3D
		var capsule_mesh := CapsuleMesh.new()
		capsule_mesh.radius = capsule_shape.radius
		capsule_mesh.height = capsule_shape.height + capsule_shape.radius * 2.0
		return capsule_mesh
	if shape is CylinderShape3D:
		var cylinder_shape := shape as CylinderShape3D
		var cylinder_mesh := CylinderMesh.new()
		cylinder_mesh.top_radius = cylinder_shape.radius
		cylinder_mesh.bottom_radius = cylinder_shape.radius
		cylinder_mesh.height = cylinder_shape.height
		return cylinder_mesh
	return null


func _make_collision_debug_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.15, 0.15, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.2, 0.45)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	return mat


func _setup_preview_camera_defaults() -> void:
	var camera_pos: Vector3 = preview_camera.global_position
	camera_target = Vector3(0.0, 1.0, 0.0)
	var to_camera: Vector3 = camera_pos - camera_target
	camera_distance = maxf(1.2, to_camera.length())
	camera_yaw = atan2(to_camera.x, to_camera.z)
	camera_pitch = asin(clampf(to_camera.y / camera_distance, -1.0, 1.0))
	_update_preview_camera_transform()


func _update_preview_camera_transform() -> void:
	camera_pitch = clampf(camera_pitch, -1.2, 1.2)
	camera_distance = clampf(camera_distance, 1.2, 80.0)
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
			user_camera_dirty = true
			camera_yaw -= motion.relative.x * 0.008
			camera_pitch -= motion.relative.y * 0.008
			_update_preview_camera_transform()
		elif is_panning:
			user_camera_dirty = true
			var right: Vector3 = preview_camera.global_transform.basis.x
			var up: Vector3 = preview_camera.global_transform.basis.y
			var pan_scale: float = 0.0035 * camera_distance
			camera_target += (-right * motion.relative.x + up * motion.relative.y) * pan_scale
			_update_preview_camera_transform()
