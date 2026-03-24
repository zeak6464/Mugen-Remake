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
	for entry in ContentResolver.scan_character_entries(mods_roots, "playable"):
		mod_entries.append(
			{
				"name": str(entry.get("name", "")),
				"path": str(entry.get("path", "")),
				"display_name": str(entry.get("display_name", entry.get("name", "")))
			}
		)
	mods_scanned.emit(mod_entries.size())
	return mod_entries


func load_character(mod_name: String, parent_node: Node) -> FighterBase:
	var mod_path: String = _resolve_mod_path_for_load(mod_name)
	return spawn_character_from_mod_path(mod_path, parent_node, "", mod_name, true)


## Load a fighter from a resolved mods folder (e.g. roster `mod` path). initial_state overrides character.def when set.
## emit_loaded: when false, skips character_loaded (e.g. temporary tag assists).
func spawn_character_from_mod_path(
	mod_path: String, parent_node: Node, initial_state: String = "", load_label: String = "", emit_loaded: bool = false
) -> FighterBase:
	var norm: String = ContentResolver.normalize_root(mod_path)
	if norm.is_empty() or not _has_required_files(norm):
		return null
	if fighter_scene == null or parent_node == null:
		return null
	var model_path: String = _find_model_file(norm)
	var fighter := fighter_scene.instantiate() as FighterBase
	if fighter == null:
		return null
	parent_node.add_child(fighter)
	fighter.set_mod_directory(norm)

	var parts_doc: Dictionary = _load_json("%sparts.json" % norm)
	var data_bundle: Dictionary = {
		"states": _load_json("%sstates.json" % norm),
		"commands": _load_json("%scommands.json" % norm),
		"physics": _load_json("%sphysics.json" % norm),
		"sounds": _load_json("%ssounds.json" % norm),
		"projectiles": _load_json("%sprojectiles.json" % norm),
		"transformations": _load_json("%stransformations.json" % norm),
		"costumes": _load_json("%scostumes.json" % norm),
		"parts": parts_doc,
		"def": _load_character_def("%scharacter.def" % norm)
	}
	if data_bundle["def"].has("initial_state"):
		data_bundle["initial_state"] = data_bundle["def"]["initial_state"]
	var state_override: String = str(initial_state).strip_edges()
	if not state_override.is_empty():
		data_bundle["initial_state"] = state_override

	var used_parts: bool = false
	if bool(parts_doc.get("enabled", false)):
		var base_rel: String = str(parts_doc.get("base_model", "")).strip_edges()
		if not base_rel.is_empty():
			var resolved_base: String = ContentResolver.resolve_relative_or_absolute_path(norm, base_rel)
			if FileAccess.file_exists(resolved_base) or (resolved_base.begins_with("res://") and ResourceLoader.exists(resolved_base)):
				model_path = resolved_base
				used_parts = _attach_parts_model(fighter, norm, resolved_base, parts_doc, data_bundle["def"])
	if model_path.is_empty():
		fighter.queue_free()
		return null
	if not used_parts:
		_attach_runtime_model(fighter, model_path, data_bundle["def"])
	var warn_name: String = str(load_label).strip_edges()
	if warn_name.is_empty():
		warn_name = norm.trim_suffix("/").get_file()
	var load_issues: PackedStringArray = _validate_character_bundle(warn_name, norm, data_bundle)
	for line in load_issues:
		push_warning(line)
	fighter.inject_character_data(data_bundle)
	fighter.register_mod_shader_reapply(Callable(self, "apply_runtime_shader_to_fighter"))
	if emit_loaded:
		character_loaded.emit(fighter, warn_name)
	return fighter


func instantiate_helper(parent_fighter: FighterBase, _pos: Vector3, state_id: String) -> FighterBase:
	if fighter_scene == null or parent_fighter == null:
		return null
	var mod_path: String = parent_fighter.get_mod_directory()
	if mod_path.is_empty():
		return null
	var model_path: String = _find_model_file(mod_path)
	var data_bundle: Dictionary = parent_fighter.character_data.duplicate(true)
	var helper_parts: Dictionary = data_bundle.get("parts", {})
	if bool(helper_parts.get("enabled", false)):
		var h_base: String = str(helper_parts.get("base_model", "")).strip_edges()
		if not h_base.is_empty():
			var h_resolved: String = ContentResolver.resolve_relative_or_absolute_path(mod_path, h_base)
			if FileAccess.file_exists(h_resolved) or (h_resolved.begins_with("res://") and ResourceLoader.exists(h_resolved)):
				model_path = h_resolved
	if model_path.is_empty():
		return null
	var fighter := fighter_scene.instantiate() as FighterBase
	if fighter == null:
		return null
	fighter.set_mod_directory(mod_path)
	var requested_state: String = str(state_id).strip_edges()
	if not requested_state.is_empty():
		data_bundle["initial_state"] = requested_state
	var used_helper_parts: bool = bool(helper_parts.get("enabled", false)) and not str(helper_parts.get("base_model", "")).strip_edges().is_empty() and _attach_parts_model(fighter, mod_path, model_path, helper_parts, data_bundle.get("def", {}))
	if not used_helper_parts:
		_attach_runtime_model(fighter, model_path, data_bundle.get("def", {}))
	fighter.inject_character_data(data_bundle)
	fighter.register_mod_shader_reapply(Callable(self, "apply_runtime_shader_to_fighter"))
	return fighter


func _has_required_files(mod_path: String) -> bool:
	return bool(ContentResolver.build_character_entry(mod_path.trim_suffix("/").get_file(), mod_path).get("is_playable", false))


func _find_model_file(mod_path: String) -> String:
	return ContentResolver.find_character_model_path(mod_path, _load_character_def("%scharacter.def" % mod_path))


func _resolve_model_path_from_def(mod_path: String) -> String:
	var def_data: Dictionary = _load_character_def("%scharacter.def" % mod_path)
	var raw_path: String = str(def_data.get("model_path", def_data.get("model_file", ""))).strip_edges()
	return ContentResolver.resolve_relative_or_absolute_path(mod_path, raw_path)


func _is_candidate_model_file(path: String) -> bool:
	return ContentResolver.is_candidate_model_file(path)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("ModLoader: could not open JSON: %s" % path)
		return {}
	var raw: String = file.get_as_text()
	if raw.strip_edges().is_empty():
		push_warning("ModLoader: empty JSON file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null:
		push_warning("ModLoader: JSON parse error (check syntax): %s" % path)
		return {}
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("ModLoader: JSON root must be an object: %s" % path)
		return {}
	return parsed


func _validate_character_bundle(mod_name: String, mod_path: String, bundle: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var prefix: String = "ModLoader [%s]" % mod_name
	var states: Dictionary = bundle.get("states", {})
	var commands: Dictionary = bundle.get("commands", {})
	var physics: Dictionary = bundle.get("physics", {})
	if states.is_empty():
		out.append("%s: states.json is missing, empty, or invalid — fighter will have no states." % prefix)
	if commands.is_empty():
		out.append("%s: commands.json is missing, empty, or invalid — inputs may not work." % prefix)
	if physics.is_empty():
		out.append("%s: physics.json is missing, empty, or invalid — movement may be wrong." % prefix)
	var def: Dictionary = bundle.get("def", {})
	if def.is_empty():
		out.append("%s: character.def could not be read — using defaults where possible." % prefix)
	else:
		var ichk: String = str(bundle.get("initial_state", def.get("initial_state", ""))).strip_edges()
		if not ichk.is_empty() and not states.is_empty() and not states.has(ichk):
			out.append('%s: initial_state "%s" not found in states.json — first state will be used.' % [prefix, ichk])
	if not mod_path.is_empty():
		var sp: String = "%sstates.json" % mod_path
		var cp: String = "%scommands.json" % mod_path
		var pp: String = "%sphysics.json" % mod_path
		if FileAccess.file_exists(sp) and states.is_empty():
			out.append("%s: file exists but failed to load: %s" % [prefix, sp])
		if FileAccess.file_exists(cp) and commands.is_empty():
			out.append("%s: file exists but failed to load: %s" % [prefix, cp])
		if FileAccess.file_exists(pp) and physics.is_empty():
			out.append("%s: file exists but failed to load: %s" % [prefix, pp])
	return out


func _load_character_def(path: String) -> Dictionary:
	return ContentResolver.load_character_def(path)


func apply_runtime_shader_to_fighter(fighter: FighterBase) -> void:
	if fighter == null or fighter.runtime_model_root == null:
		return
	var def_eff: Dictionary = _effective_def_for_costume_shader(fighter)
	var mod_dir: String = fighter.get_mod_directory().trim_suffix("/")
	if mod_dir.is_empty():
		return
	var model_path_f: String = fighter.current_model_path
	var tex_root: String = model_path_f.get_base_dir() if not model_path_f.is_empty() else mod_dir
	apply_character_def_shader_to_model(fighter.runtime_model_root, mod_dir, def_eff, model_path_f, tex_root)


## Applies character.def (+ optional costume overrides) shading to any model root (e.g. CSS preview).
func apply_character_def_shader_to_model(
	model_node: Node3D,
	mod_path: String,
	character_def: Dictionary,
	source_model_path: String = "",
	texture_root_override: String = ""
) -> void:
	if model_node == null:
		return
	var mod_slash: String = mod_path.trim_suffix("/") + "/"
	var shader_path_raw: String = str(character_def.get("shader_path", DEFAULT_CHARACTER_SHADER_PATH)).strip_edges()
	if shader_path_raw.is_empty():
		shader_path_raw = DEFAULT_CHARACTER_SHADER_PATH
	var shader: Shader = _load_shader_from_path(shader_path_raw, mod_slash)
	if shader == null:
		return
	var tex_root: String = texture_root_override.strip_edges()
	if tex_root.is_empty() and not source_model_path.is_empty():
		tex_root = source_model_path.get_base_dir()
	if tex_root.is_empty():
		tex_root = mod_slash.trim_suffix("/")
	var shader_params: Dictionary = _extract_character_shader_params(character_def, tex_root)
	_apply_shader_to_model_tree(model_node, shader, shader_params)


func character_def_with_costume_overrides(base_def: Dictionary, costume: Dictionary) -> Dictionary:
	var d: Dictionary = base_def.duplicate(true) if typeof(base_def) == TYPE_DICTIONARY else {}
	if typeof(costume) != TYPE_DICTIONARY or costume.is_empty():
		return d
	var csp: String = str(costume.get("shader_path", "")).strip_edges()
	if not csp.is_empty():
		d["shader_path"] = csp
	if not costume.has("shader_user_uniforms"):
		return d
	var merged_u: Dictionary = {}
	var rb: String = str(d.get("shader_user_uniforms", "")).strip_edges()
	if not rb.is_empty():
		var pb = JSON.parse_string(rb)
		if typeof(pb) == TYPE_DICTIONARY:
			merged_u = (pb as Dictionary).duplicate(true)
	var cu = costume.get("shader_user_uniforms", null)
	if cu is Dictionary:
		for uk in (cu as Dictionary).keys():
			merged_u[str(uk)] = (cu as Dictionary)[uk]
	elif cu is String:
		var cs: String = str(cu).strip_edges()
		if not cs.is_empty():
			var pc = JSON.parse_string(cs)
			if typeof(pc) == TYPE_DICTIONARY:
				for uk in (pc as Dictionary).keys():
					merged_u[str(uk)] = (pc as Dictionary)[uk]
	d["shader_user_uniforms"] = JSON.stringify(merged_u)
	return d


func _effective_def_for_costume_shader(fighter: FighterBase) -> Dictionary:
	var base: Dictionary = fighter.character_data.get("def", {})
	if typeof(base) != TYPE_DICTIONARY:
		base = {}
	var eff: Dictionary = base.duplicate(true)
	if fighter.current_form_id != "base" and not fighter.active_form_data.is_empty():
		eff = character_def_with_costume_overrides(eff, fighter.active_form_data)
	if fighter.current_costume_id != "base" and not fighter.active_costume_data.is_empty():
		eff = character_def_with_costume_overrides(eff, fighter.active_costume_data)
	return eff


func _attach_runtime_model(fighter: FighterBase, model_path: String, character_def: Dictionary = {}) -> void:
	var lower_path := model_path.to_lower()
	var model_offset_y: float = float(character_def.get("model_offset_y", 0.0))
	var model_scale: Vector3 = _extract_model_scale(character_def)
	var shader_path_raw: String = str(character_def.get("shader_path", DEFAULT_CHARACTER_SHADER_PATH)).strip_edges()
	if shader_path_raw.is_empty():
		shader_path_raw = DEFAULT_CHARACTER_SHADER_PATH
	var shader: Shader = _load_shader_from_path(shader_path_raw, "res://mods/")
	var shader_params: Dictionary = _extract_character_shader_params(character_def, model_path.get_base_dir())
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


func _attach_parts_model(fighter: FighterBase, mod_path: String, base_path: String, parts_doc: Dictionary, character_def: Dictionary) -> bool:
	var model_node := _load_model_root_node(base_path)
	if model_node == null or fighter.skeleton == null:
		if model_node != null:
			model_node.queue_free()
		return false
	var skel: Skeleton3D = _find_skeleton_recursive_in_node(model_node)
	if skel == null:
		model_node.queue_free()
		return false
	var model_offset_y: float = float(character_def.get("model_offset_y", 0.0))
	var model_scale: Vector3 = _extract_model_scale(character_def)
	model_node.position.y += model_offset_y
	model_node.scale = model_scale
	var slots: Dictionary = parts_doc.get("slots", {})
	if typeof(slots) != TYPE_DICTIONARY:
		slots = {}
	for slot_id in _parts_slot_keys_in_order(parts_doc, slots):
		var raw_slot: String = str(slots.get(slot_id, "")).strip_edges()
		if raw_slot.is_empty():
			continue
		var part_path: String = ContentResolver.resolve_relative_or_absolute_path(mod_path, raw_slot)
		if not FileAccess.file_exists(part_path) and not (part_path.begins_with("res://") and ResourceLoader.exists(part_path)):
			push_warning("ModLoader: parts slot '%s' file not found: %s" % [str(slot_id), part_path])
			continue
		var part_root := _load_model_root_node(part_path)
		if part_root == null:
			push_warning("ModLoader: parts slot '%s' failed to load: %s" % [str(slot_id), part_path])
			continue
		_merge_part_meshes_into_skeleton(part_root, skel, str(slot_id))
	var shader_path_raw: String = str(character_def.get("shader_path", DEFAULT_CHARACTER_SHADER_PATH)).strip_edges()
	if shader_path_raw.is_empty():
		shader_path_raw = DEFAULT_CHARACTER_SHADER_PATH
	var shader: Shader = _load_shader_from_path(shader_path_raw, "res://mods/")
	var shader_params: Dictionary = _extract_character_shader_params(character_def, mod_path)
	_apply_shader_to_model_tree(model_node, shader, shader_params)
	fighter.set_runtime_model_root(model_node, base_path)
	fighter.skeleton.add_child(model_node)
	return true


func _load_model_root_node(path: String) -> Node3D:
	if path.is_empty():
		return null
	var lower_path := path.to_lower()
	if path.begins_with("user://") and (lower_path.ends_with(".gltf") or lower_path.ends_with(".glb")):
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		if gltf.append_from_file(path, state) != OK:
			return null
		var scene := gltf.generate_scene(state)
		return scene as Node3D if scene is Node3D else null
	var model_res := ResourceLoader.load(path)
	if model_res is PackedScene:
		var inst := (model_res as PackedScene).instantiate()
		return inst as Node3D if inst is Node3D else null
	if lower_path.ends_with(".gltf") or lower_path.ends_with(".glb"):
		var gltf2 := GLTFDocument.new()
		var state2 := GLTFState.new()
		if gltf2.append_from_file(path, state2) != OK:
			return null
		var scene2 := gltf2.generate_scene(state2)
		return scene2 as Node3D if scene2 is Node3D else null
	return null


func _find_skeleton_recursive_in_node(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found: Skeleton3D = _find_skeleton_recursive_in_node(child)
		if found != null:
			return found
	return null


func _parts_slot_keys_in_order(parts_doc: Dictionary, slots: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var order = parts_doc.get("slot_order", [])
	if typeof(order) == TYPE_ARRAY:
		for item in order:
			var k: String = str(item).strip_edges()
			if slots.has(k):
				out.append(k)
	for key in slots.keys():
		var ks: String = str(key)
		if not out.has(ks):
			out.append(ks)
	return out


func _merge_part_meshes_into_skeleton(part_root: Node3D, skel: Skeleton3D, slot_id: String) -> void:
	var mesh_nodes: Array[Node] = part_root.find_children("*", "MeshInstance3D", true, false)
	for n in mesh_nodes:
		if not n is MeshInstance3D:
			continue
		var mi: MeshInstance3D = n as MeshInstance3D
		if mi.mesh == null:
			continue
		var dup: MeshInstance3D = mi.duplicate(Node.DUPLICATE_USE_INSTANTIATION) as MeshInstance3D
		var safe_slot: String = str(slot_id).replace("/", "_").replace(":", "_")
		dup.name = "part_%s_%s" % [safe_slot, mi.name]
		skel.add_child(dup)
		dup.skeleton = dup.get_path_to(skel)
		dup.transform = Transform3D.IDENTITY
	part_root.queue_free()


func _extract_model_scale(character_def: Dictionary) -> Vector3:
	var uniform_scale: float = float(character_def.get("model_scale", 1.0))
	var x: float = float(character_def.get("model_scale_x", uniform_scale))
	var y: float = float(character_def.get("model_scale_y", uniform_scale))
	var z: float = float(character_def.get("model_scale_z", uniform_scale))
	return Vector3(x, y, z)


func _extract_character_shader_params(character_def: Dictionary, texture_resolve_root: String = "") -> Dictionary:
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
	_merge_shader_user_uniforms_json(character_def, params, texture_resolve_root)
	return params


func _merge_shader_user_uniforms_json(character_def: Dictionary, params: Dictionary, texture_resolve_root: String = "") -> void:
	var raw: String = str(character_def.get("shader_user_uniforms", "")).strip_edges()
	if raw.is_empty():
		return
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for k in (parsed as Dictionary).keys():
		var pv: Variant = _shader_uniform_value_from_json((parsed as Dictionary)[k], texture_resolve_root)
		if pv != null:
			params[str(k)] = pv


func _make_uv_gradient_texture() -> Texture2D:
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.add_point(0.0, Color.BLACK)
	gr.add_point(1.0, Color.WHITE)
	gt.gradient = gr
	gt.width = 256
	gt.height = 256
	return gt


func _load_texture2d_from_path(path: String) -> Texture2D:
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


func _shader_uniform_value_from_json(v, texture_resolve_root: String = "") -> Variant:
	if v is float or v is int or v is bool:
		return v
	if v is String:
		var sv: String = str(v).strip_edges()
		if sv == "__uv_gradient__":
			return _make_uv_gradient_texture()
		if sv.begins_with("res://") or sv.begins_with("user://"):
			var tr := _load_texture2d_from_path(sv)
			if tr != null:
				return tr
			return null
		if not texture_resolve_root.is_empty():
			var root: String = texture_resolve_root.trim_suffix("/")
			var full: String = root.path_join(sv)
			var t2 := _load_texture2d_from_path(full)
			if t2 != null:
				return t2
			return null
		return null
	if v is Array:
		var a: Array = v
		if a.size() >= 4:
			return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
		if a.size() == 3:
			return Vector3(float(a[0]), float(a[1]), float(a[2]))
		if a.size() == 2:
			return Vector2(float(a[0]), float(a[1]))
	return v


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
						var pm: Variant = params[key]
						if pm == null or pm is String:
							continue
						mat.set_shader_parameter(str(key), pm)
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


## Accepts a bundled folder name (first playable match in mods_roots) or a full mod directory (res:// or user://).
func _resolve_mod_path_for_load(mod_key: String) -> String:
	var key: String = mod_key.strip_edges()
	if key.is_empty():
		return ""
	if key.begins_with("res://") or key.begins_with("user://"):
		var normalized: String = ContentResolver.normalize_root(key)
		if _has_required_files(normalized):
			return normalized
		return ""
	return _resolve_mod_path(key)


func _normalize_root(root: String) -> String:
	var normalized: String = root.strip_edges()
	if normalized.is_empty():
		return ""
	if not normalized.ends_with("/"):
		normalized += "/"
	return normalized
