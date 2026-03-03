extends Node
class_name ModLoader

signal mods_scanned(mod_count: int)
signal character_loaded(fighter: FighterBase, mod_name: String)

const REQUIRED_FILES: Array[String] = ["states.json", "commands.json", "physics.json", "character.def"]
const DEFAULT_CHARACTER_SHADER_PATH: String = ""

@export var mods_roots: Array[String] = ["user://mods/", "res://mods/"]
@export var fighter_scene: PackedScene = preload("res://engine/FighterBase.tscn")


func scan_mods() -> Array[Dictionary]:
	var mod_entries: Array[Dictionary] = []
	var seen_names: Dictionary = {}
	for root in mods_roots:
		var normalized_root: String = _normalize_root(root)
		var root_abs: String = ProjectSettings.globalize_path(normalized_root)
		if normalized_root.begins_with("user://") and not DirAccess.dir_exists_absolute(root_abs):
			DirAccess.make_dir_recursive_absolute(root_abs)
		var dir := DirAccess.open(normalized_root)
		if dir == null:
			continue
		dir.list_dir_begin()
		var item := dir.get_next()
		while not item.is_empty():
			if dir.current_is_dir() and item != "." and item != ".." and not seen_names.has(item):
				var mod_path := "%s%s/" % [normalized_root, item]
				if _has_required_files(mod_path):
					mod_entries.append({"name": item, "path": mod_path})
					seen_names[item] = true
			item = dir.get_next()
		dir.list_dir_end()

	mods_scanned.emit(mod_entries.size())
	return mod_entries


func load_character(mod_name: String, parent_node: Node) -> FighterBase:
	var mod_path: String = _resolve_mod_path(mod_name)
	if mod_path.is_empty() or not _has_required_files(mod_path):
		return null
	var model_path: String = _find_model_file(mod_path)
	if model_path.is_empty():
		return null
	if fighter_scene == null:
		return null

	var fighter := fighter_scene.instantiate() as FighterBase
	if fighter == null:
		return null
	parent_node.add_child(fighter)
	fighter.set_mod_directory(mod_path)

	var data_bundle: Dictionary = {
		"states": _load_json("%sstates.json" % mod_path),
		"commands": _load_json("%scommands.json" % mod_path),
		"physics": _load_json("%sphysics.json" % mod_path),
		"sounds": _load_json("%ssounds.json" % mod_path),
		"projectiles": _load_json("%sprojectiles.json" % mod_path),
		"transformations": _load_json("%stransformations.json" % mod_path),
		"costumes": _load_json("%scostumes.json" % mod_path),
		"def": _load_character_def("%scharacter.def" % mod_path)
	}
	if data_bundle["def"].has("initial_state"):
		data_bundle["initial_state"] = data_bundle["def"]["initial_state"]

	_attach_runtime_model(fighter, model_path, data_bundle["def"])
	fighter.inject_character_data(data_bundle)
	character_loaded.emit(fighter, mod_name)
	return fighter


func instantiate_helper(parent_fighter: FighterBase, _pos: Vector3, state_id: String) -> FighterBase:
	if fighter_scene == null or parent_fighter == null:
		return null
	var mod_path: String = parent_fighter.get_mod_directory()
	if mod_path.is_empty():
		return null
	var model_path: String = _find_model_file(mod_path)
	if model_path.is_empty():
		return null
	var fighter := fighter_scene.instantiate() as FighterBase
	if fighter == null:
		return null
	fighter.set_mod_directory(mod_path)
	var data_bundle: Dictionary = parent_fighter.character_data.duplicate(true)
	var requested_state: String = str(state_id).strip_edges()
	if not requested_state.is_empty():
		data_bundle["initial_state"] = requested_state
	_attach_runtime_model(fighter, model_path, data_bundle.get("def", {}))
	fighter.inject_character_data(data_bundle)
	return fighter


func _has_required_files(mod_path: String) -> bool:
	for file_name in REQUIRED_FILES:
		if not FileAccess.file_exists("%s%s" % [mod_path, file_name]):
			return false
	return not _find_model_file(mod_path).is_empty()


func _find_model_file(mod_path: String) -> String:
	var def_model_path: String = _resolve_model_path_from_def(mod_path)
	if _is_candidate_model_file(def_model_path):
		return def_model_path
	var dir := DirAccess.open(mod_path)
	if dir == null:
		return ""
	var preferred: Array[String] = ["model.glb", "model.gltf"]
	for file_name in preferred:
		var preferred_path := "%s%s" % [mod_path, file_name]
		if _is_candidate_model_file(preferred_path):
			return preferred_path
	dir.list_dir_begin()
	var item := dir.get_next()
	while not item.is_empty():
		if not dir.current_is_dir():
			var lower := item.to_lower()
			var model_path := "%s%s" % [mod_path, item]
			if (lower.ends_with(".glb") or lower.ends_with(".gltf")) and _is_candidate_model_file(model_path):
				return model_path
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


func _is_candidate_model_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	if file.get_length() <= 0:
		return false
	var lower := path.to_lower()
	if lower.ends_with(".glb"):
		if file.get_length() < 4:
			return false
		var magic := file.get_buffer(4)
		return (
			magic.size() == 4
			and magic[0] == 0x67
			and magic[1] == 0x6C
			and magic[2] == 0x54
			and magic[3] == 0x46
		)
	if lower.ends_with(".gltf"):
		var text := file.get_as_text().strip_edges()
		return text.begins_with("{")
	return false


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}


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


func _attach_runtime_model(fighter: FighterBase, model_path: String, character_def: Dictionary = {}) -> void:
	var lower_path := model_path.to_lower()
	var model_offset_y: float = float(character_def.get("model_offset_y", 0.0))
	var model_scale: Vector3 = _extract_model_scale(character_def)
	var shader_path_raw: String = str(character_def.get("shader_path", DEFAULT_CHARACTER_SHADER_PATH)).strip_edges()
	if shader_path_raw.is_empty():
		shader_path_raw = DEFAULT_CHARACTER_SHADER_PATH
	var shader: Shader = _load_shader_from_path(shader_path_raw, "res://mods/")
	var shader_params: Dictionary = _extract_character_shader_params(character_def)
	# user:// model files are not imported resources, so parse glTF directly.
	if model_path.begins_with("user://") and (lower_path.ends_with(".gltf") or lower_path.ends_with(".glb")):
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		var err := gltf.append_from_file(model_path, state)
		if err != OK:
			return
		var model_scene := gltf.generate_scene(state)
		if model_scene != null and fighter.skeleton != null:
			if model_scene is Node3D:
				var model_node := model_scene as Node3D
				model_node.position.y += model_offset_y
				model_node.scale = model_scale
				fighter.set_runtime_model_root(model_node, model_path)
				_apply_shader_to_model_tree(model_node, shader, shader_params)
			fighter.skeleton.add_child(model_scene)
		return

	var model_res := ResourceLoader.load(model_path)
	if model_res is PackedScene:
		var model_instance := (model_res as PackedScene).instantiate()
		if fighter.skeleton != null:
			if model_instance is Node3D:
				var model_node := model_instance as Node3D
				model_node.position.y += model_offset_y
				model_node.scale = model_scale
				fighter.set_runtime_model_root(model_node, model_path)
				_apply_shader_to_model_tree(model_node, shader, shader_params)
			fighter.skeleton.add_child(model_instance)
		return
	if lower_path.ends_with(".gltf") or lower_path.ends_with(".glb"):
		var gltf2 := GLTFDocument.new()
		var state2 := GLTFState.new()
		var err2 := gltf2.append_from_file(model_path, state2)
		if err2 != OK:
			return
		var model_scene2 := gltf2.generate_scene(state2)
		if model_scene2 != null and fighter.skeleton != null:
			if model_scene2 is Node3D:
				var model_node := model_scene2 as Node3D
				model_node.position.y += model_offset_y
				model_node.scale = model_scale
				fighter.set_runtime_model_root(model_node, model_path)
				_apply_shader_to_model_tree(model_node, shader, shader_params)
			fighter.skeleton.add_child(model_scene2)


func _extract_model_scale(character_def: Dictionary) -> Vector3:
	var uniform_scale: float = float(character_def.get("model_scale", 1.0))
	var x: float = float(character_def.get("model_scale_x", uniform_scale))
	var y: float = float(character_def.get("model_scale_y", uniform_scale))
	var z: float = float(character_def.get("model_scale_z", uniform_scale))
	return Vector3(x, y, z)


func _extract_character_shader_params(character_def: Dictionary) -> Dictionary:
	var params: Dictionary = {}
	if character_def.has("shader_base_tint"):
		params["base_tint"] = _parse_color_from_value(character_def.get("shader_base_tint", "1,1,1,1"), Color.WHITE)
	if character_def.has("shader_rim_color"):
		params["rim_color"] = _parse_color_from_value(character_def.get("shader_rim_color", "0.2,0.35,1.0,1.0"), Color(0.2, 0.35, 1.0, 1.0))
	if character_def.has("shader_rim_power"):
		params["rim_power"] = float(character_def.get("shader_rim_power", 2.2))
	if character_def.has("shader_rim_intensity"):
		params["rim_intensity"] = float(character_def.get("shader_rim_intensity", 0.35))
	if character_def.has("shader_steps"):
		params["shade_steps"] = float(character_def.get("shader_steps", 3.0))
	return params


func _load_shader_from_path(path_raw: String, relative_root: String) -> Shader:
	if path_raw.is_empty():
		return null
	var resolved: String = path_raw
	if not resolved.begins_with("res://") and not resolved.begins_with("user://"):
		resolved = "%s%s" % [relative_root, path_raw]
	if resolved.begins_with("res://"):
		if not FileAccess.file_exists(resolved):
			return null
		var loaded = ResourceLoader.load(resolved)
		if loaded is Shader:
			return loaded as Shader
	if not FileAccess.file_exists(resolved):
		return null
	var file := FileAccess.open(resolved, FileAccess.READ)
	if file == null:
		return null
	var shader := Shader.new()
	shader.code = file.get_as_text()
	return shader


func _apply_shader_to_model_tree(root: Node3D, shader: Shader, params: Dictionary) -> void:
	if root == null or shader == null:
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh != null:
				var surfaces: int = mesh_node.mesh.get_surface_count()
				for i in range(surfaces):
					var mat := ShaderMaterial.new()
					mat.shader = shader
					var source_mat: Material = _resolve_surface_source_material(mesh_node, i)
					var albedo_tex: Texture2D = _extract_albedo_texture_from_material(source_mat)
					var albedo_color: Color = _extract_albedo_color_from_material(source_mat)
					var has_useful_base: bool = albedo_tex != null or not _is_near_white(albedo_color)
					if not has_useful_base:
						# Keep original material if source has no meaningful base data.
						continue
					if albedo_tex != null:
						mat.set_shader_parameter("albedo_texture", albedo_tex)
						mat.set_shader_parameter("use_albedo_texture", true)
					else:
						mat.set_shader_parameter("use_albedo_texture", false)
					mat.set_shader_parameter("material_color", albedo_color)
					for key in params.keys():
						mat.set_shader_parameter(str(key), params[key])
					mesh_node.set_surface_override_material(i, mat)
		for child in node.get_children():
			stack.append(child)


func _resolve_surface_source_material(mesh_node: MeshInstance3D, surface_index: int) -> Material:
	if mesh_node == null or mesh_node.mesh == null:
		return null
	var source_mat: Material = mesh_node.get_active_material(surface_index)
	if source_mat == null and mesh_node.material_override != null:
		source_mat = mesh_node.material_override
	if source_mat == null and mesh_node.mesh != null:
		source_mat = mesh_node.mesh.surface_get_material(surface_index)
	return source_mat


func _extract_albedo_texture_from_material(material: Material) -> Texture2D:
	if material == null:
		return null
	if material is BaseMaterial3D:
		var base_mat := material as BaseMaterial3D
		return base_mat.albedo_texture
	if material is ShaderMaterial:
		var shader_mat := material as ShaderMaterial
		var tex = shader_mat.get_shader_parameter("albedo_texture")
		if tex is Texture2D:
			return tex as Texture2D
		tex = shader_mat.get_shader_parameter("texture_albedo")
		if tex is Texture2D:
			return tex as Texture2D
	return null


func _extract_albedo_color_from_material(material: Material) -> Color:
	if material == null:
		return Color.WHITE
	if material is BaseMaterial3D:
		var base_mat := material as BaseMaterial3D
		return base_mat.albedo_color
	if material is ShaderMaterial:
		var shader_mat := material as ShaderMaterial
		var value = shader_mat.get_shader_parameter("albedo")
		if value is Color:
			return value as Color
	return Color.WHITE


func _is_near_white(color: Color) -> bool:
	return color.r > 0.98 and color.g > 0.98 and color.b > 0.98 and color.a > 0.98


func _parse_color_from_value(value, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var parts: PackedStringArray = (value as String).split(",", false)
		if parts.size() >= 3:
			var r: float = float(parts[0])
			var g: float = float(parts[1])
			var b: float = float(parts[2])
			var a: float = 1.0
			if parts.size() >= 4:
				a = float(parts[3])
			return Color(r, g, b, a)
	return fallback


func _resolve_mod_path(mod_name: String) -> String:
	for root in mods_roots:
		var normalized_root: String = _normalize_root(root)
		var candidate: String = "%s%s/" % [normalized_root, mod_name]
		if _has_required_files(candidate):
			return candidate
	return ""


func _normalize_root(root: String) -> String:
	var normalized: String = root.strip_edges()
	if normalized.is_empty():
		return ""
	if not normalized.ends_with("/"):
		normalized += "/"
	return normalized
