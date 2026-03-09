extends RefCounted
class_name ContentResolver

const CHARACTER_REQUIRED_FILES: Array[String] = ["character.def", "states.json", "commands.json", "physics.json"]
const STAGE_MODEL_KEYS: Array[String] = ["model", "model_path", "scene", "stage_model"]


static func normalize_root(root: String) -> String:
	var normalized: String = root.strip_edges()
	if normalized.is_empty():
		return ""
	if not normalized.ends_with("/"):
		normalized += "/"
	return normalized


static func ensure_user_root(root: String) -> void:
	var normalized_root: String = normalize_root(root)
	if not normalized_root.begins_with("user://"):
		return
	var root_abs: String = ProjectSettings.globalize_path(normalized_root)
	if not DirAccess.dir_exists_absolute(root_abs):
		DirAccess.make_dir_recursive_absolute(root_abs)


static func scan_character_entries(mods_roots: Array[String], mode: String = "playable") -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var seen_names: Dictionary = {}
	for root in mods_roots:
		var normalized_root: String = normalize_root(root)
		if normalized_root.is_empty():
			continue
		ensure_user_root(normalized_root)
		var dir := DirAccess.open(normalized_root)
		if dir == null:
			continue
		dir.list_dir_begin()
		var item: String = dir.get_next()
		while not item.is_empty():
			if dir.current_is_dir() and item != "." and item != ".." and not seen_names.has(item):
				var mod_path: String = "%s%s/" % [normalized_root, item]
				var entry: Dictionary = build_character_entry(item, mod_path)
				if _character_entry_matches_mode(entry, mode):
					entries.append(entry)
					seen_names[item] = true
			item = dir.get_next()
		dir.list_dir_end()
	entries.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
	return entries


static func build_character_entry(name: String, mod_path: String) -> Dictionary:
	var normalized_path: String = normalize_root(mod_path)
	var def_path: String = "%scharacter.def" % normalized_path
	var def_data: Dictionary = load_character_def(def_path)
	var model_path: String = find_character_model_path(normalized_path, def_data)
	var states_path: String = "%sstates.json" % normalized_path
	var commands_path: String = "%scommands.json" % normalized_path
	var physics_path: String = "%sphysics.json" % normalized_path
	var has_states: bool = FileAccess.file_exists(states_path)
	var has_commands: bool = FileAccess.file_exists(commands_path)
	var has_physics: bool = FileAccess.file_exists(physics_path)
	var has_def: bool = FileAccess.file_exists(def_path)
	return {
		"name": name,
		"path": normalized_path,
		"mod_path": normalized_path,
		"states_path": states_path,
		"commands_path": commands_path,
		"physics_path": physics_path,
		"def_path": def_path,
		"def_data": def_data,
		"model_path": model_path,
		"has_def": has_def,
		"has_states": has_states,
		"has_commands": has_commands,
		"has_physics": has_physics,
		"has_model": not model_path.is_empty(),
		"is_playable": has_def and has_states and has_commands and has_physics and not model_path.is_empty()
	}


static func _character_entry_matches_mode(entry: Dictionary, mode: String) -> bool:
	match mode.to_lower():
		"playable":
			return bool(entry.get("is_playable", false))
		"states":
			return bool(entry.get("has_states", false))
		"model":
			return bool(entry.get("has_model", false))
		"any":
			return true
	return bool(entry.get("is_playable", false))


static func load_character_def(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
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


static func find_character_model_path(mod_path: String, def_data: Dictionary = {}) -> String:
	var normalized_path: String = normalize_root(mod_path)
	var model_hints: Array[String] = []
	var raw_path: String = str(def_data.get("model_path", def_data.get("model_file", ""))).strip_edges()
	if not raw_path.is_empty():
		model_hints.append(raw_path)
	for raw_hint in model_hints:
		var resolved: String = resolve_relative_or_absolute_path(normalized_path, raw_hint)
		if is_candidate_model_file(resolved):
			return resolved
	var preferred: Array[String] = ["model.glb", "model.gltf"]
	for file_name in preferred:
		var candidate: String = "%s%s" % [normalized_path, file_name]
		if is_candidate_model_file(candidate):
			return candidate
	var dir := DirAccess.open(normalized_path)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var item: String = dir.get_next()
	while not item.is_empty():
		if not dir.current_is_dir():
			var lower: String = item.to_lower()
			var candidate_path: String = "%s%s" % [normalized_path, item]
			if (lower.ends_with(".gltf") or lower.ends_with(".glb")) and is_candidate_model_file(candidate_path):
				dir.list_dir_end()
				return candidate_path
		item = dir.get_next()
	dir.list_dir_end()
	return ""


static func scan_stage_entries(stages_roots: Array[String]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var seen_names: Dictionary = {}
	for root in stages_roots:
		var normalized_root: String = normalize_root(root)
		if normalized_root.is_empty():
			continue
		ensure_user_root(normalized_root)
		var dir := DirAccess.open(normalized_root)
		if dir == null:
			continue
		dir.list_dir_begin()
		var item: String = dir.get_next()
		while not item.is_empty():
			if dir.current_is_dir() and item != "." and item != ".." and not seen_names.has(item):
				var folder_path: String = "%s%s" % [normalized_root, item]
				if is_stage_folder(folder_path):
					var stage_def: Dictionary = load_stage_def("%s/stage.def" % folder_path)
					entries.append(
						{
							"name": item,
							"folder": folder_path,
							"folder_path": folder_path,
							"stage_def": stage_def,
							"model_path": find_stage_model_path(folder_path, stage_def)
						}
					)
					seen_names[item] = true
			item = dir.get_next()
		dir.list_dir_end()
	entries.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
	return entries


static func is_stage_folder(folder_path: String) -> bool:
	if FileAccess.file_exists("%s/stage.def" % folder_path):
		return true
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return false
	dir.list_dir_begin()
	var item: String = dir.get_next()
	while not item.is_empty():
		if not dir.current_is_dir():
			var lower: String = item.to_lower()
			if lower.ends_with(".glb") or lower.ends_with(".gltf"):
				dir.list_dir_end()
				return true
		item = dir.get_next()
	dir.list_dir_end()
	return false


static func load_stage_def(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
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
		if split.size() != 2:
			continue
		result[split[0].strip_edges()] = _parse_stage_def_value(split[1].strip_edges())
	return result


static func _parse_stage_def_value(raw_value: String):
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


static func find_stage_model_path(folder_path: String, stage_def: Dictionary = {}) -> String:
	for key in STAGE_MODEL_KEYS:
		var value: String = str(stage_def.get(key, "")).strip_edges()
		if value.is_empty():
			continue
		var resolved: String = resolve_relative_or_absolute_path(folder_path, value)
		if can_load_model_path(resolved):
			return resolved
	var preferred: Array[String] = ["stage.glb", "stage.gltf", "model.glb", "model.gltf", "Test.glb", "Test.gltf"]
	for file_name in preferred:
		var candidate: String = "%s/%s" % [folder_path, file_name]
		if can_load_model_path(candidate):
			return candidate
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var item: String = dir.get_next()
	while not item.is_empty():
		if not dir.current_is_dir():
			var lower: String = item.to_lower()
			if lower.ends_with(".glb") or lower.ends_with(".gltf"):
				var candidate: String = "%s/%s" % [folder_path, item]
				if can_load_model_path(candidate):
					dir.list_dir_end()
					return candidate
			elif lower.ends_with(".glb.import") or lower.ends_with(".gltf.import"):
				var source_name: String = item.trim_suffix(".import")
				var import_candidate: String = "%s/%s" % [folder_path, source_name]
				if can_load_model_path(import_candidate):
					dir.list_dir_end()
					return import_candidate
		item = dir.get_next()
	dir.list_dir_end()
	return ""


static func resolve_relative_or_absolute_path(base_folder: String, raw_path: String) -> String:
	if raw_path.is_empty():
		return ""
	if raw_path.begins_with("res://") or raw_path.begins_with("user://"):
		return raw_path
	var normalized_base: String = normalize_root(base_folder)
	return "%s%s" % [normalized_base, raw_path.trim_prefix("/")]


static func can_load_model_path(path: String) -> bool:
	if path.is_empty():
		return false
	if path.begins_with("res://") and ResourceLoader.exists(path):
		return true
	return FileAccess.file_exists(ProjectSettings.globalize_path(path))


static func is_candidate_model_file(path: String) -> bool:
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
		var magic: PackedByteArray = file.get_buffer(4)
		return magic.size() == 4 and magic[0] == 0x67 and magic[1] == 0x6C and magic[2] == 0x54 and magic[3] == 0x46
	if lower.ends_with(".gltf"):
		var text: String = file.get_as_text().strip_edges()
		return text.begins_with("{")
	return false


static func load_model_scene(path: String) -> Node:
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


static func load_model_scene_any_path(path: String) -> Node:
	var scene: Node = load_model_scene(path)
	if scene != null:
		return scene
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if absolute_path.is_empty() or absolute_path == path:
		return null
	var lower: String = absolute_path.to_lower()
	if lower.ends_with(".gltf") or lower.ends_with(".glb"):
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		if gltf.append_from_file(absolute_path, state) == OK:
			return gltf.generate_scene(state)
	return null


static func collect_animation_names(model_path: String) -> Array[String]:
	var out: Array[String] = []
	var scene: Node = load_model_scene_any_path(model_path)
	if scene == null:
		return out
	var player: AnimationPlayer = _find_animation_player_recursive(scene)
	if player != null:
		for name in player.get_animation_list():
			out.append(str(name))
	scene.queue_free()
	out.sort()
	return out


static func _find_animation_player_recursive(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found: AnimationPlayer = _find_animation_player_recursive(child)
		if found != null:
			return found
	return null
