extends Control

@export var mods_roots: Array[String] = ["user://mods/", "res://mods/"]
@export var default_mod_name: String = ""

@onready var mod_option: OptionButton = $MarginContainer/VBoxContainer/TopRow/ModOption
@onready var prev_button: Button = $MarginContainer/VBoxContainer/TopRow/PrevButton
@onready var next_button: Button = $MarginContainer/VBoxContainer/TopRow/NextButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/TopRow/BackButton
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var animation_option: OptionButton = $MarginContainer/VBoxContainer/AnimationRow/AnimationOption
@onready var preview_container: SubViewportContainer = $MarginContainer/VBoxContainer/PreviewPanel/PreviewViewportContainer
@onready var preview_viewport: SubViewport = $MarginContainer/VBoxContainer/PreviewPanel/PreviewViewportContainer/PreviewViewport
@onready var preview_world: Node3D = $MarginContainer/VBoxContainer/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewWorld
@onready var model_root: Node3D = $MarginContainer/VBoxContainer/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewWorld/ModelRoot
@onready var camera: Camera3D = $MarginContainer/VBoxContainer/PreviewPanel/PreviewViewportContainer/PreviewViewport/PreviewWorld/Camera3D

var mod_entries: Array[Dictionary] = []
var current_model: Node3D = null
var preview_animation_player: AnimationPlayer = null
var camera_target: Vector3 = Vector3.ZERO
var camera_distance: float = 4.0
var min_camera_distance: float = 1.2
var max_camera_distance: float = 20.0


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	mod_option.item_selected.connect(_on_mod_selected)
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
		_adjust_zoom(-0.6)
		return
	if _pressed(event, &"p1_down") or _pressed(event, &"p2_down"):
		_adjust_zoom(0.6)
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
				var mod_path := "%s%s/" % [normalized_root, item]
				var model_path: String = _find_model_file(mod_path)
				if not model_path.is_empty():
					mod_entries.append({"name": item, "path": mod_path, "model_path": model_path, "def_data": _load_character_def("%scharacter.def" % mod_path)})
					seen_names[item] = true
			item = dir.get_next()
		dir.list_dir_end()
	mod_entries.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
	for i in range(mod_entries.size()):
		mod_option.add_item(str(mod_entries[i].get("name", "")), i)


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
	var model_path: String = str(entry.get("model_path", ""))
	_load_preview_model(model_path, entry.get("def_data", {}))
	status_label.text = "Viewing: %s" % str(entry.get("name", ""))


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


func _load_preview_model(model_path: String, def_data: Dictionary) -> void:
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
	current_model = node3d
	_fit_camera_to_model(node3d)
	_rebuild_animation_selector(node3d)


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
	var def_model_path: String = _resolve_model_path_from_def(mod_path)
	if _is_candidate_model_file(def_model_path):
		return def_model_path
	var preferred: Array[String] = ["model.glb", "model.gltf"]
	for file_name in preferred:
		var candidate: String = "%s%s" % [mod_path, file_name]
		if _is_candidate_model_file(candidate):
			return candidate
	var dir := DirAccess.open(mod_path)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var item := dir.get_next()
	while not item.is_empty():
		if not dir.current_is_dir():
			var lower := item.to_lower()
			var candidate_path := "%s%s" % [mod_path, item]
			if (lower.ends_with(".gltf") or lower.ends_with(".glb")) and _is_candidate_model_file(candidate_path):
				dir.list_dir_end()
				return candidate_path
		item = dir.get_next()
	dir.list_dir_end()
	return ""


func _resolve_model_path_from_def(mod_path: String) -> String:
	var def_data: Dictionary = _load_character_def("%scharacter.def" % mod_path)
	var raw_path: String = str(def_data.get("model_path", "")).strip_edges()
	if raw_path.is_empty():
		raw_path = str(def_data.get("model_file", "")).strip_edges()
	if raw_path.is_empty():
		return ""
	if raw_path.begins_with("res://") or raw_path.begins_with("user://"):
		return raw_path
	return "%s%s" % [mod_path, raw_path]


func _load_character_def(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var result: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with(";") or line.begins_with("#"):
			continue
		var split := line.split("=", false, 1)
		if split.size() == 2:
			result[split[0].strip_edges()] = split[1].strip_edges()
	return result


func _extract_model_scale(def_data: Dictionary) -> Vector3:
	var uniform_scale: float = float(def_data.get("model_scale", 1.0))
	var x: float = float(def_data.get("model_scale_x", uniform_scale))
	var y: float = float(def_data.get("model_scale_y", uniform_scale))
	var z: float = float(def_data.get("model_scale_z", uniform_scale))
	return Vector3(x, y, z)


func _is_candidate_model_file(path: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
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
		var text := file.get_as_text().strip_edges()
		return text.begins_with("{")
	return false


func _normalize_root(root: String) -> String:
	var normalized: String = root.strip_edges()
	if normalized.is_empty():
		return ""
	if not normalized.ends_with("/"):
		normalized += "/"
	return normalized


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
