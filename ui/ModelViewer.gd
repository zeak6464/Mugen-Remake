extends Control

@export var mods_roots: Array[String] = ["user://mods/", "res://mods/"]
@export var default_mod_name: String = ""

@onready var mod_option: OptionButton = $Chrome/MainRow/LeftPanel/LeftVBox/ToolbarRow/ModOption
@onready var prev_button: Button = $Chrome/MainRow/LeftPanel/LeftVBox/ToolbarRow/PrevButton
@onready var next_button: Button = $Chrome/MainRow/LeftPanel/LeftVBox/ToolbarRow/NextButton
@onready var back_button: Button = $Chrome/MainRow/LeftPanel/LeftVBox/ToolbarRow/BackButton
@onready var status_label: Label = $Chrome/MainRow/RightPanel/RightVBox/StatusLabel
@onready var mod_title_label: Label = $Chrome/MainRow/LeftPanel/LeftVBox/ModTitle
@onready var form_list: ItemList = $Chrome/MainRow/LeftPanel/LeftVBox/FormListPanel/FormList
@onready var animation_option: OptionButton = $Chrome/MainRow/RightPanel/RightVBox/AnimationRow/AnimationOption
@onready var preview_container: SubViewportContainer = $Chrome/MainRow/RightPanel/RightVBox/PreviewPanel/PreviewViewportContainer
@onready var preview_viewport: SubViewport = $Chrome/MainRow/RightPanel/RightVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport
@onready var preview_world: Node3D = $Chrome/MainRow/RightPanel/RightVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewWorld
@onready var model_root: Node3D = $Chrome/MainRow/RightPanel/RightVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewWorld/ModelRoot
@onready var camera: Camera3D = $Chrome/MainRow/RightPanel/RightVBox/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewWorld/Camera3D

var mod_entries: Array[Dictionary] = []
var variant_entries: Array[Dictionary] = []
var current_model: Node3D = null
var preview_animation_player: AnimationPlayer = null
var camera_target: Vector3 = Vector3.ZERO
var camera_distance: float = 4.0
var min_camera_distance: float = 1.2
var max_camera_distance: float = 20.0
var shader_loader: ModLoader = null


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	UISkin.attach_focus_arrow(self)
	mod_option.item_selected.connect(_on_mod_selected)
	form_list.item_selected.connect(_on_variant_selected)
	animation_option.item_selected.connect(_on_animation_selected)
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)
	preview_container.gui_input.connect(_on_preview_gui_input)
	_scan_mods()
	_select_default_mod()


func _unhandled_input(event: InputEvent) -> void:
	if _pressed(event, &"ui_cancel") or _pressed(event, &"p1_k") or _pressed(event, &"p2_k"):
		_on_back_pressed()
		return
	if _pressed(event, &"p1_left") or _pressed(event, &"p2_left"):
		_on_prev_pressed()
		return
	if _pressed(event, &"p1_right") or _pressed(event, &"p2_right"):
		_on_next_pressed()
		return
	if _pressed(event, &"p1_up") or _pressed(event, &"p2_up"):
		_select_variant_relative(-1)
		return
	if _pressed(event, &"p1_down") or _pressed(event, &"p2_down"):
		_select_variant_relative(1)
		return


func _pressed(event: InputEvent, action: StringName) -> bool:
	if not InputMap.has_action(action):
		return false
	if not event.is_action_pressed(action):
		return false
	if event is InputEventKey and (event as InputEventKey).echo:
		return false
	return true


func _scan_mods() -> void:
	mod_entries.clear()
	mod_option.clear()
	for entry in ContentResolver.scan_character_entries(mods_roots, "model"):
		var mod_path: String = str(entry.get("path", ""))
		mod_entries.append(
			{
				"name": str(entry.get("name", "")),
				"path": mod_path,
				"display_name": str(entry.get("display_name", entry.get("name", ""))),
				"model_path": str(entry.get("model_path", "")),
				"def_data": entry.get("def_data", {}),
				"forms_data": _load_mod_forms_data(mod_path)
			}
		)
	mod_entries.sort_custom(func(a, b): return str(a.get("display_name", "")) < str(b.get("display_name", "")))
	for i in range(mod_entries.size()):
		mod_option.add_item(str(mod_entries[i].get("display_name", mod_entries[i].get("name", ""))), i)


func _select_default_mod() -> void:
	if mod_entries.is_empty():
		status_label.text = "No models found."
		return
	var selected_index: int = 0
	if not default_mod_name.is_empty():
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
	mod_title_label.text = str(entry.get("display_name", entry.get("name", "")))
	_rebuild_variant_entries(entry)
	_select_variant(0)


func _on_prev_pressed() -> void:
	if mod_entries.is_empty():
		return
	var current: int = mod_option.get_selected()
	var next_idx: int = wrapi(current - 1, 0, mod_entries.size())
	mod_option.select(next_idx)
	_on_mod_selected(next_idx)
	SystemSFX.play_ui_from(self, "ui_move")


func _on_next_pressed() -> void:
	if mod_entries.is_empty():
		return
	var current: int = mod_option.get_selected()
	var next_idx: int = wrapi(current + 1, 0, mod_entries.size())
	mod_option.select(next_idx)
	_on_mod_selected(next_idx)
	SystemSFX.play_ui_from(self, "ui_move")


func _on_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")


func _rebuild_variant_entries(mod_entry: Dictionary) -> void:
	variant_entries.clear()
	form_list.clear()
	var base_def: Dictionary = mod_entry.get("def_data", {})
	variant_entries.append({"label": "[BASE]", "form_id": "", "form_data": {}, "def_data": base_def})
	form_list.add_item("[BASE]")
	var forms_data: Dictionary = mod_entry.get("forms_data", {})
	var keys: Array[String] = []
	for k in forms_data.keys():
		keys.append(str(k))
	keys.sort()
	for key in keys:
		var fdata: Dictionary = forms_data.get(key, {})
		var merged_def: Dictionary = _effective_def_for_variant(base_def, fdata)
		variant_entries.append({"label": key, "form_id": key, "form_data": fdata, "def_data": merged_def})
		form_list.add_item(key.to_upper())
	if form_list.item_count > 0:
		form_list.select(0)


func _select_variant(index: int) -> void:
	if index < 0 or index >= variant_entries.size():
		return
	if mod_entries.is_empty():
		return
	var mod_idx: int = mod_option.get_selected()
	if mod_idx < 0 or mod_idx >= mod_entries.size():
		return
	var mod_entry: Dictionary = mod_entries[mod_idx]
	var variant: Dictionary = variant_entries[index]
	form_list.select(index)
	var model_path: String = _resolve_variant_model_path(mod_entry, variant)
	_load_preview_model(model_path, variant.get("def_data", {}), str(mod_entry.get("path", "")))
	var form_label: String = str(variant.get("label", "[BASE]"))
	status_label.text = "Viewing %s · %s" % [str(mod_entry.get("display_name", mod_entry.get("name", ""))), form_label]


func _on_variant_selected(index: int) -> void:
	_select_variant(index)
	SystemSFX.play_ui_from(self, "ui_move")


func _select_variant_relative(delta: int) -> void:
	if variant_entries.is_empty():
		return
	var current: int = 0
	var selected: PackedInt32Array = form_list.get_selected_items()
	if not selected.is_empty():
		current = selected[0]
	var next_idx: int = wrapi(current + delta, 0, variant_entries.size())
	_select_variant(next_idx)
	SystemSFX.play_ui_from(self, "ui_move")


func _resolve_variant_model_path(mod_entry: Dictionary, variant: Dictionary) -> String:
	var model_path: String = str(mod_entry.get("model_path", ""))
	var form_data: Dictionary = variant.get("form_data", {})
	var form_model_raw: String = str(form_data.get("model_path", form_data.get("model_file", ""))).strip_edges()
	if not form_model_raw.is_empty():
		model_path = _resolve_mod_relative_path(mod_entry, form_model_raw)
	return model_path


func _merge_defs(base_def: Dictionary, override_data: Dictionary) -> Dictionary:
	var out: Dictionary = base_def.duplicate(true)
	for k in override_data.keys():
		out[k] = override_data[k]
	return out


func _effective_def_for_variant(base_def: Dictionary, variant_data: Dictionary) -> Dictionary:
	if shader_loader == null:
		shader_loader = ModLoader.new()
	return shader_loader.character_def_with_costume_overrides(base_def, variant_data)


func _load_preview_model(model_path: String, def_data: Dictionary, mod_path: String = "") -> void:
	for child in model_root.get_children():
		child.queue_free()
	current_model = null
	var scene_node: Node = _load_model_scene(model_path)
	if scene_node == null or not (scene_node is Node3D):
		_rebuild_animation_selector(null)
		return
	var node3d := scene_node as Node3D
	node3d.scale = _extract_model_scale(def_data)
	node3d.position.y += float(def_data.get("model_offset_y", 0.0))
	model_root.add_child(node3d)
	_apply_preview_shader(node3d, mod_path, def_data, model_path)
	current_model = node3d
	_fit_camera_to_model(node3d)
	_rebuild_animation_selector(node3d)


func _apply_preview_shader(node3d: Node3D, mod_path: String, def_data: Dictionary, source_model_path: String) -> void:
	if node3d == null:
		return
	var mod_dir: String = mod_path.strip_edges()
	if mod_dir.is_empty():
		return
	if shader_loader == null:
		shader_loader = ModLoader.new()
	shader_loader.apply_character_def_shader_to_model(node3d, mod_dir, def_data, source_model_path)


func _load_model_scene(path: String) -> Node:
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


func _fit_camera_to_model(root: Node3D) -> void:
	var aabb: AABB = _collect_model_aabb(root)
	if aabb.size.length() <= 0.001:
		camera_target = Vector3(0.0, 1.0, 0.0)
		camera_distance = 3.0
		min_camera_distance = 1.2
		max_camera_distance = 12.0
		_update_camera_position()
		return
	var center: Vector3 = aabb.get_center()
	var extent: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	camera_target = center
	camera_target.y += extent * 0.08
	camera_distance = clampf(extent * 1.9, 2.2, 14.0)
	min_camera_distance = maxf(0.8, extent * 0.45)
	max_camera_distance = maxf(camera_distance + 4.0, extent * 5.0)
	_update_camera_position()


func _collect_model_aabb(root: Node3D) -> AABB:
	var stack: Array[Node] = [root]
	var has_bounds: bool = false
	var merged: AABB = AABB()
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh != null:
				var local_box: AABB = mi.mesh.get_aabb()
				var world_box: AABB = mi.global_transform * local_box
				if not has_bounds:
					merged = world_box
					has_bounds = true
				else:
					merged = merged.merge(world_box)
		for child in n.get_children():
			stack.append(child)
	if not has_bounds:
		return AABB(Vector3.ZERO, Vector3.ZERO)
	return merged


func _rebuild_animation_selector(root: Node) -> void:
	preview_animation_player = _find_animation_player_recursive(root)
	animation_option.clear()
	if preview_animation_player == null:
		animation_option.disabled = true
		animation_option.add_item("No animations", 0)
		animation_option.select(0)
		return
	var names: PackedStringArray = preview_animation_player.get_animation_list()
	if names.is_empty():
		animation_option.disabled = true
		animation_option.add_item("No animations", 0)
		animation_option.select(0)
		return
	animation_option.disabled = false
	for i in range(names.size()):
		animation_option.add_item(names[i], i)
	animation_option.select(0)
	_on_animation_selected(0)


func _on_animation_selected(index: int) -> void:
	if preview_animation_player == null:
		return
	if index < 0 or index >= animation_option.item_count:
		return
	var animation_name: String = animation_option.get_item_text(index)
	if animation_name.is_empty():
		return
	if preview_animation_player.has_animation(animation_name):
		preview_animation_player.play(animation_name)


func _find_model_file(mod_path: String) -> String:
	return ContentResolver.find_character_model_path(mod_path, _load_character_def("%scharacter.def" % mod_path))


func _resolve_model_path_from_def(mod_path: String) -> String:
	var def_data: Dictionary = _load_character_def("%scharacter.def" % mod_path)
	var raw_path: String = str(def_data.get("model_path", def_data.get("model_file", ""))).strip_edges()
	return ContentResolver.resolve_relative_or_absolute_path(mod_path, raw_path)


func _load_character_def(path: String) -> Dictionary:
	return ContentResolver.load_character_def(path)


func _extract_model_scale(def_data: Dictionary) -> Vector3:
	var uniform_scale: float = float(def_data.get("model_scale", 1.0))
	var x: float = float(def_data.get("model_scale_x", uniform_scale))
	var y: float = float(def_data.get("model_scale_y", uniform_scale))
	var z: float = float(def_data.get("model_scale_z", uniform_scale))
	return Vector3(x, y, z)


func _is_candidate_model_file(path: String) -> bool:
	return ContentResolver.is_candidate_model_file(path)


func _normalize_root(root: String) -> String:
	var normalized: String = root.strip_edges()
	if normalized.is_empty():
		return ""
	if not normalized.ends_with("/"):
		normalized += "/"
	return normalized


func _load_mod_forms_data(mod_path: String) -> Dictionary:
	var path: String = "%stransformations.json" % mod_path
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var forms_dict: Dictionary = (parsed as Dictionary).get("forms", {})
	return forms_dict if typeof(forms_dict) == TYPE_DICTIONARY else {}


func _resolve_mod_relative_path(mod_entry: Dictionary, raw_path: String) -> String:
	if raw_path.is_empty():
		return ""
	if raw_path.begins_with("res://") or raw_path.begins_with("user://"):
		return raw_path
	var mod_path: String = str(mod_entry.get("path", ""))
	return "%s%s" % [mod_path, raw_path]


func _find_animation_player_recursive(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found: AnimationPlayer = _find_animation_player_recursive(child)
		if found != null:
			return found
	return null


func _on_preview_gui_input(event: InputEvent) -> void:
	if current_model == null:
		return
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event as InputEventMouseButton
		if button_event.pressed and button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(-0.45)
			return
		if button_event.pressed and button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(0.45)
			return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		current_model.rotate_y(-motion.relative.x * 0.01)


func _adjust_zoom(delta: float) -> void:
	camera_distance = clampf(camera_distance + delta, min_camera_distance, max_camera_distance)
	_update_camera_position()


func _update_camera_position() -> void:
	if camera == null:
		return
	camera.global_position = camera_target + Vector3(0.0, 0.0, camera_distance)
	camera.look_at(camera_target, Vector3.UP)
