extends RefCounted
class_name ContentImportService

const CHARACTER_ROOT: String = "user://mods/"
const STAGE_ROOT: String = "user://stages/"
const CESIUM_BASELINE_ROOT: String = "res://mods/CesiumMan/"
const CHARACTER_SUPPORT_FILES: Dictionary = {
	"transformations.json": {"forms": {}},
	"costumes.json": {"costumes": {}},
	"hurtboxes.json": {"hurtboxes": []}
}


static func import_character_source(source_path: String) -> Dictionary:
	var report: Dictionary = _create_report("character", source_path)
	var prepared: Dictionary = _prepare_target_folder(source_path, CHARACTER_ROOT)
	if not bool(prepared.get("ok", false)):
		return _merge_report(report, prepared)
	var target_dir: String = str(prepared.get("target_dir", ""))
	var copied_files: Array = prepared.get("copied_files", [])
	var copied_model_path: String = _first_model_from_paths(copied_files)
	if copied_model_path.is_empty():
		copied_model_path = ContentResolver.find_character_model_path(target_dir, ContentResolver.load_character_def("%scharacter.def" % target_dir))
	if copied_model_path.is_empty():
		report["warnings"].append("No .glb, .gltf, or .fbx model was found after import.")
		report["ok"] = false
		report["target_path"] = ProjectSettings.globalize_path(target_dir)
		report["content_name"] = str(prepared.get("content_name", ""))
		return report
	var animation_names: Array[String] = ContentResolver.collect_animation_names(copied_model_path)
	var generated_files: Array[String] = []
	var animation_map: Dictionary = _build_character_animation_map(animation_names)
	var relative_model_path: String = copied_model_path.trim_prefix(target_dir)
	if _ensure_character_def(target_dir, relative_model_path):
		generated_files.append("character.def")
	if _ensure_character_states(target_dir, animation_map):
		generated_files.append("states.json")
	if _ensure_character_commands(target_dir):
		generated_files.append("commands.json")
	if _ensure_character_physics(target_dir):
		generated_files.append("physics.json")
	if _ensure_character_projectiles(target_dir):
		generated_files.append("projectiles.json")
	if _ensure_character_sounds(target_dir):
		generated_files.append("sounds.json")
	for file_name in CHARACTER_SUPPORT_FILES.keys():
		if _ensure_json_file("%s%s" % [target_dir, file_name], CHARACTER_SUPPORT_FILES[file_name]):
			generated_files.append(file_name)
	if animation_names.is_empty():
		report["warnings"].append("No model animations were detected. Generated states use fallback animation ids and may need manual edits.")
	if _uses_fallback_attack_animation(animation_map):
		report["warnings"].append("No dedicated attack animation was found. Attack states currently reuse the closest available animation.")
	report["ok"] = true
	report["content_name"] = str(prepared.get("content_name", ""))
	report["target_path"] = ProjectSettings.globalize_path(target_dir)
	report["target_root_path"] = target_dir
	report["generated_files"] = generated_files
	report["copied_files"] = copied_files
	report["animation_names"] = animation_names
	report["summary"] = "Imported character %s." % report["content_name"]
	return report


static func import_stage_source(source_path: String) -> Dictionary:
	var report: Dictionary = _create_report("stage", source_path)
	var prepared: Dictionary = _prepare_target_folder(source_path, STAGE_ROOT)
	if not bool(prepared.get("ok", false)):
		return _merge_report(report, prepared)
	var target_dir: String = str(prepared.get("target_dir", ""))
	var copied_files: Array = prepared.get("copied_files", [])
	var copied_model_path: String = _first_model_from_paths(copied_files)
	if copied_model_path.is_empty():
		copied_model_path = ContentResolver.find_stage_model_path(target_dir, ContentResolver.load_stage_def("%s/stage.def" % target_dir))
	if copied_model_path.is_empty():
		report["warnings"].append("No .glb, .gltf, or .fbx model was found after import.")
		report["ok"] = false
		report["target_path"] = ProjectSettings.globalize_path(target_dir)
		report["content_name"] = str(prepared.get("content_name", ""))
		return report
	var metrics: Dictionary = _collect_model_metrics(copied_model_path)
	var relative_model_path: String = copied_model_path.trim_prefix(ContentResolver.normalize_root(target_dir))
	var generated_files: Array[String] = []
	if _ensure_stage_def(ContentResolver.normalize_root(target_dir), relative_model_path, metrics):
		generated_files.append("stage.def")
	if bool(metrics.get("used_fallback_bounds", false)):
		report["warnings"].append("Stage bounds were estimated because mesh bounds could not be read cleanly.")
	report["ok"] = true
	report["content_name"] = str(prepared.get("content_name", ""))
	report["target_path"] = ProjectSettings.globalize_path(target_dir)
	report["target_root_path"] = target_dir
	report["generated_files"] = generated_files
	report["copied_files"] = copied_files
	report["summary"] = "Imported stage %s." % report["content_name"]
	return report


static func _create_report(kind: String, source_path: String) -> Dictionary:
	return {
		"ok": false,
		"kind": kind,
		"source_path": source_path,
		"content_name": "",
		"target_path": "",
		"target_root_path": "",
		"copied_files": [],
		"generated_files": [],
		"warnings": [],
		"summary": ""
	}


static func _merge_report(base: Dictionary, extra: Dictionary) -> Dictionary:
	for key in extra.keys():
		base[key] = extra[key]
	return base


static func _prepare_target_folder(source_path: String, target_root: String) -> Dictionary:
	var normalized_source: String = source_path.strip_edges()
	if normalized_source.is_empty():
		return {"ok": false, "summary": "No source path provided.", "warnings": ["Select a file or folder to import."]}
	ContentResolver.ensure_user_root(target_root)
	var source_abs: String = ProjectSettings.globalize_path(normalized_source) if normalized_source.begins_with("user://") or normalized_source.begins_with("res://") else normalized_source
	var is_dir: bool = DirAccess.dir_exists_absolute(source_abs)
	var is_file: bool = FileAccess.file_exists(source_abs)
	if not is_dir and not is_file:
		return {"ok": false, "summary": "Source path does not exist.", "warnings": ["The selected file or folder could not be found."]}
	var content_name: String = _sanitize_content_name(_derive_content_name(source_abs, is_dir))
	var target_dir: String = _make_unique_target_dir(target_root, content_name)
	var copied_files: Array[String] = []
	if is_dir:
		_copy_directory_recursive_absolute(source_abs, ProjectSettings.globalize_path(target_dir), copied_files)
	else:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_dir))
		var dst_abs: String = "%s/%s" % [ProjectSettings.globalize_path(target_dir).trim_suffix("/"), source_abs.get_file()]
		if not _copy_file_absolute(source_abs, dst_abs):
			return {"ok": false, "summary": "Failed to copy source file.", "warnings": ["The selected file could not be copied into the game folder."]}
		copied_files.append("%s%s" % [ContentResolver.normalize_root(target_dir), source_abs.get_file()])
	return {"ok": true, "content_name": content_name, "target_dir": ContentResolver.normalize_root(target_dir), "copied_files": copied_files}


static func _derive_content_name(source_abs: String, is_dir: bool) -> String:
	if is_dir:
		return source_abs.trim_suffix("/").get_file()
	return source_abs.get_basename().get_file()


static func _sanitize_content_name(raw_name: String) -> String:
	var out: String = ""
	for idx in range(raw_name.length()):
		var ch: String = raw_name.substr(idx, 1)
		var code: int = ch.unicode_at(0)
		var is_alnum: bool = (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
		if is_alnum or ch == "_" or ch == "-":
			out += ch
		elif ch == " ":
			out += "_"
	if out.is_empty():
		return "ImportedContent"
	return out


static func _make_unique_target_dir(root: String, base_name: String) -> String:
	var normalized_root: String = ContentResolver.normalize_root(root)
	var candidate_name: String = base_name
	var index: int = 2
	var target_dir: String = "%s%s/" % [normalized_root, candidate_name]
	while DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(target_dir)):
		candidate_name = "%s_%d" % [base_name, index]
		target_dir = "%s%s/" % [normalized_root, candidate_name]
		index += 1
	return target_dir


static func _copy_directory_recursive_absolute(src_abs_dir: String, dst_abs_dir: String, copied_files: Array[String]) -> void:
	DirAccess.make_dir_recursive_absolute(dst_abs_dir)
	var dir := DirAccess.open(src_abs_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var item: String = dir.get_next()
	while not item.is_empty():
		if item == "." or item == "..":
			item = dir.get_next()
			continue
		var src_item_abs: String = "%s/%s" % [src_abs_dir.trim_suffix("/"), item]
		var dst_item_abs: String = "%s/%s" % [dst_abs_dir.trim_suffix("/"), item]
		if dir.current_is_dir():
			_copy_directory_recursive_absolute(src_item_abs, dst_item_abs, copied_files)
		else:
			if item.to_lower().ends_with(".import"):
				item = dir.get_next()
				continue
			if _copy_file_absolute(src_item_abs, dst_item_abs):
				copied_files.append(ProjectSettings.localize_path(dst_item_abs))
		item = dir.get_next()
	dir.list_dir_end()


static func _copy_file_absolute(src_abs: String, dst_abs: String) -> bool:
	var in_file := FileAccess.open(src_abs, FileAccess.READ)
	if in_file == null:
		return false
	var bytes: PackedByteArray = in_file.get_buffer(in_file.get_length())
	var out_file := FileAccess.open(dst_abs, FileAccess.WRITE)
	if out_file == null:
		return false
	out_file.store_buffer(bytes)
	return true


static func _first_model_from_paths(paths: Array) -> String:
	for raw_path in paths:
		var candidate: String = str(raw_path)
		var lower: String = candidate.to_lower()
		if lower.ends_with(".glb") or lower.ends_with(".gltf") or lower.ends_with(".fbx"):
			return candidate
	return ""


static func _ensure_character_def(target_dir: String, model_relative_path: String) -> bool:
	var path: String = "%scharacter.def" % target_dir
	if FileAccess.file_exists(path):
		return false
	var baseline_def: Dictionary = ContentResolver.load_character_def("%scharacter.def" % CESIUM_BASELINE_ROOT)
	var mod_name: String = target_dir.trim_suffix("/").get_file()
	var lines: PackedStringArray = [
		"name = %s" % mod_name,
		"display_name = %s" % mod_name,
		"model_path = %s" % model_relative_path,
		"initial_state = %s" % str(baseline_def.get("initial_state", "idle")),
		"model_scale = %s" % str(baseline_def.get("model_scale", 1.0)),
		"collision_scale = %s" % str(baseline_def.get("collision_scale", 1.0)),
		"ground_offset_y = %s" % str(baseline_def.get("ground_offset_y", 0.0)),
		"model_offset_y = %s" % str(baseline_def.get("model_offset_y", 0.0)),
		"hurtbox_source = %s" % str(baseline_def.get("hurtbox_source", "mesh_derived")),
		"max_resource = %s" % str(baseline_def.get("max_resource", 100)),
		"starting_resource = %s" % str(baseline_def.get("starting_resource", 0)),
		"max_juggle_points = %s" % str(baseline_def.get("max_juggle_points", 6)),
		"shader_path = %s" % str(baseline_def.get("shader_path", "res://shaders/character_toon.gdshader")),
		"shader_base_tint = %s" % str(baseline_def.get("shader_base_tint", "1.0,1.0,1.0,1.0")),
		"shader_rim_color = %s" % str(baseline_def.get("shader_rim_color", "0.20,0.35,1.00,1.0")),
		"shader_rim_power = %s" % str(baseline_def.get("shader_rim_power", 2.2)),
		"shader_rim_intensity = %s" % str(baseline_def.get("shader_rim_intensity", 0.35)),
		"shader_steps = %s" % str(baseline_def.get("shader_steps", 3.0)),
		"hurtboxes_file = hurtboxes.json"
	]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string("\n".join(lines) + "\n")
	return true


static func _ensure_character_states(target_dir: String, animation_map: Dictionary) -> bool:
	var path: String = "%sstates.json" % target_dir
	if FileAccess.file_exists(path):
		return false
	var states: Dictionary = _build_import_character_states(animation_map)
	return _write_json_file(path, states)


static func _build_attack_state(animation_name: String, hit_sound: String, end_frame: int, damage: int) -> Dictionary:
	return {
		"animation": animation_name,
		"animation_loop": false,
		"allow_movement": false,
		"allow_jump": false,
		"cancel_into": [],
		"cancel_windows": [],
		"hitboxes": [
			{
				"id": "attack_box",
				"start": 2,
				"end": 5,
				"bone": "",
				"offset": [0.8, 1.0, 0.0],
				"size": [0.55, 0.55, 0.55],
				"data": {
					"damage": damage,
					"pushback": [1.4, 0.0, 0.0],
					"hitstun_state": "hitstun",
					"hit_sound": hit_sound
				}
			}
		],
		"hurtboxes": [],
		"next": {"frame": end_frame, "id": "idle"}
	}


static func _ensure_character_commands(target_dir: String) -> bool:
	var path: String = "%scommands.json" % target_dir
	if FileAccess.file_exists(path):
		return false
	var data: Dictionary = _build_import_character_commands()
	return _write_json_file(path, data)


static func _ensure_character_physics(target_dir: String) -> bool:
	var path: String = "%sphysics.json" % target_dir
	if FileAccess.file_exists(path):
		return false
	var data: Dictionary = _build_import_character_physics()
	return _write_json_file(path, data)


static func _ensure_character_projectiles(target_dir: String) -> bool:
	var path: String = "%sprojectiles.json" % target_dir
	if FileAccess.file_exists(path):
		return false
	var baseline: Variant = _load_json_file("%sprojectiles.json" % CESIUM_BASELINE_ROOT)
	if typeof(baseline) != TYPE_DICTIONARY:
		return false
	return _write_json_file(path, baseline)


static func _ensure_character_sounds(target_dir: String) -> bool:
	var path: String = "%ssounds.json" % target_dir
	if FileAccess.file_exists(path):
		return false
	var baseline: Variant = _load_json_file("%ssounds.json" % CESIUM_BASELINE_ROOT)
	if typeof(baseline) != TYPE_DICTIONARY:
		return false
	return _write_json_file(path, baseline)


static func _ensure_json_file(path: String, data: Variant) -> bool:
	if FileAccess.file_exists(path):
		return false
	return _write_json_file(path, data)


static func _write_json_file(path: String, data: Variant) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


static func _load_json_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())


static func _build_import_character_states(animation_map: Dictionary) -> Dictionary:
	var states: Dictionary = _build_generic_character_states(animation_map)
	var baseline: Variant = _load_json_file("%sstates.json" % CESIUM_BASELINE_ROOT)
	if typeof(baseline) != TYPE_DICTIONARY:
		return states
	for state_id in (baseline as Dictionary).keys():
		var state_name: String = str(state_id)
		if state_name == "controller_demo" or state_name == "transform_start" or state_name == "transform_end":
			continue
		var state_value = (baseline as Dictionary).get(state_id, {})
		if typeof(state_value) != TYPE_DICTIONARY:
			continue
		states[state_name] = (state_value as Dictionary).duplicate(true)
	_apply_import_animation_map_to_states(states, animation_map)
	return states


static func _apply_import_animation_map_to_states(states: Dictionary, animation_map: Dictionary) -> void:
	for state_id in states.keys():
		var state_name: String = str(state_id)
		var state_value = states.get(state_id, {})
		if typeof(state_value) != TYPE_DICTIONARY:
			continue
		var state_dict: Dictionary = state_value
		if not state_dict.has("animation"):
			continue
		state_dict["animation"] = _animation_for_import_state(state_name, animation_map)
		states[state_id] = state_dict


static func _animation_for_import_state(state_name: String, animation_map: Dictionary) -> String:
	var idle_anim: String = str(animation_map.get("idle", "bn01"))
	var walk_anim: String = str(animation_map.get("walk", idle_anim))
	var run_anim: String = str(animation_map.get("run", walk_anim))
	var crouch_anim: String = str(animation_map.get("crouch", idle_anim))
	var jump_anim: String = str(animation_map.get("jump", idle_anim))
	var fall_anim: String = str(animation_map.get("fall", jump_anim))
	var attack_anim: String = str(animation_map.get("attack", idle_anim))
	var hit_anim: String = str(animation_map.get("hit", idle_anim))
	var ko_anim: String = str(animation_map.get("ko", hit_anim))
	var victory_anim: String = str(animation_map.get("victory", idle_anim))
	match state_name:
		"idle", "guard", "parry", "wakeup":
			return idle_anim
		"walk":
			return walk_anim
		"run":
			return run_anim
		"crouch":
			return crouch_anim
		"jump":
			return jump_anim
		"fall":
			return fall_anim
		"p_light", "qcf_p", "throw", "attack_p", "attack_k", "attack_h":
			return attack_anim
		"grabbed", "hitstun", "knockdown":
			return hit_anim
		"ko":
			return ko_anim
		"victory":
			return victory_anim
		_:
			return idle_anim


static func _build_import_character_commands() -> Dictionary:
	var baseline: Variant = _load_json_file("%scommands.json" % CESIUM_BASELINE_ROOT)
	if typeof(baseline) != TYPE_DICTIONARY:
		return _build_generic_character_commands()
	var output_commands: Array = []
	for entry in (baseline as Dictionary).get("commands", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var command: Dictionary = (entry as Dictionary).duplicate(true)
		if command.has("transform_to") or command.has("revert_transform") or command.has("transform_state"):
			continue
		output_commands.append(command)
	if output_commands.is_empty():
		return _build_generic_character_commands()
	return {"commands": output_commands}


static func _build_import_character_physics() -> Dictionary:
	var baseline: Variant = _load_json_file("%sphysics.json" % CESIUM_BASELINE_ROOT)
	if typeof(baseline) != TYPE_DICTIONARY:
		return _build_generic_character_physics()
	var physics: Dictionary = (baseline as Dictionary).duplicate(true)
	var generic: Dictionary = _build_generic_character_physics()
	for key in generic:
		if not physics.has(key):
			physics[key] = generic[key]
	return physics


static func _build_generic_character_states(animation_map: Dictionary) -> Dictionary:
	var idle_anim: String = str(animation_map.get("idle", "bn01"))
	var walk_anim: String = str(animation_map.get("walk", idle_anim))
	var run_anim: String = str(animation_map.get("run", walk_anim))
	var crouch_anim: String = str(animation_map.get("crouch", idle_anim))
	var jump_anim: String = str(animation_map.get("jump", idle_anim))
	var fall_anim: String = str(animation_map.get("fall", jump_anim))
	var attack_anim: String = str(animation_map.get("attack", idle_anim))
	var hit_anim: String = str(animation_map.get("hit", idle_anim))
	var ko_anim: String = str(animation_map.get("ko", hit_anim))
	var victory_anim: String = str(animation_map.get("victory", idle_anim))
	return {
		"idle": {
			"animation": idle_anim,
			"animation_loop": true,
			"allow_movement": true,
			"allow_jump": true,
			"cancel_into": ["attack_p", "attack_k", "attack_h"],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"walk": {
			"animation": walk_anim,
			"animation_loop": true,
			"allow_movement": true,
			"allow_jump": true,
			"cancel_into": ["attack_p", "attack_k", "attack_h"],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"run": {
			"animation": run_anim,
			"animation_loop": true,
			"allow_movement": true,
			"allow_jump": true,
			"cancel_into": ["attack_p", "attack_k", "attack_h"],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"crouch": {
			"animation": crouch_anim,
			"animation_loop": true,
			"allow_movement": false,
			"allow_jump": false,
			"cancel_into": ["attack_p", "attack_k"],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"jump": {
			"animation": jump_anim,
			"animation_loop": false,
			"allow_movement": true,
			"allow_jump": false,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"fall": {
			"animation": fall_anim,
			"animation_loop": true,
			"allow_movement": true,
			"allow_jump": false,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"attack_p": _build_attack_state(attack_anim, "light_hit", 18, 32),
		"attack_k": _build_attack_state(attack_anim, "medium_hit", 20, 44),
		"attack_h": _build_attack_state(attack_anim, "heavy_hit", 24, 60),
		"guard": {
			"animation": idle_anim,
			"animation_loop": false,
			"allow_movement": false,
			"guard_active": true,
			"guard_stance": "stand",
			"can_guard": true,
			"auto_guard": true,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {"frame": 8, "id": "idle"}
		},
		"grabbed": {
			"animation": hit_anim,
			"velocity": [0.0, 0.0, 0.0],
			"allow_movement": false,
			"throw_invuln": true,
			"can_guard": false,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"hitstun": {
			"animation": hit_anim,
			"velocity": [0.0, 0.0, 0.0],
			"allow_movement": false,
			"can_guard": false,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {"frame": 14, "id": "idle"}
		},
		"knockdown": {
			"animation": hit_anim,
			"velocity": [0.0, 0.0, 0.0],
			"allow_movement": false,
			"can_guard": false,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"wakeup": {
			"animation": idle_anim,
			"velocity": [0.0, 0.0, 0.0],
			"allow_movement": false,
			"can_guard": true,
			"guard_stance": "stand",
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {"frame": 10, "id": "idle"}
		},
		"ko": {
			"animation": ko_anim,
			"velocity": [0.0, 0.0, 0.0],
			"allow_movement": false,
			"can_guard": false,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"victory": {
			"animation": victory_anim,
			"velocity": [0.0, 0.0, 0.0],
			"allow_movement": false,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		}
	}


static func _build_generic_character_commands() -> Dictionary:
	return {
		"commands": [
			{"id": "p_attack", "pattern": ["P"], "target_state": "attack_p", "max_window": 8, "min_repeat": 1},
			{"id": "k_attack", "pattern": ["K"], "target_state": "attack_k", "max_window": 8, "min_repeat": 1},
			{"id": "s_attack", "pattern": ["S"], "target_state": "attack_h", "max_window": 8, "min_repeat": 1},
			{"id": "h_attack", "pattern": ["H"], "target_state": "attack_h", "max_window": 8, "min_repeat": 1}
		]
	}


static func _build_generic_character_physics() -> Dictionary:
	return {
		"weight": 100,
		"walk_speed": 3.2,
		"run_speed": 5.8,
		"initial_dash": 6.2,
		"jump_speed": 7.5,
		"gravity": 18.0,
		"max_fall_speed": 25.0,
		"fast_fall_speed": 32.0,
		"air_speed": 2.72,
		"air_accel": 0.45,
		"max_jumps": 1
	}


static func _build_character_animation_map(animation_names: Array[String]) -> Dictionary:
	var map: Dictionary = {}
	var fallback: String = animation_names[0] if not animation_names.is_empty() else "bn01"
	map["idle"] = _pick_animation(animation_names, ["idle", "stand", "bn01", "base_idle"], fallback)
	map["walk"] = _pick_animation(animation_names, ["walk", "locomotion", "move", "forward"], str(map["idle"]))
	map["run"] = _pick_animation(animation_names, ["run", "dash", "sprint"], str(map["walk"]))
	map["crouch"] = _pick_animation(animation_names, ["crouch", "duck"], str(map["idle"]))
	map["jump"] = _pick_animation(animation_names, ["jump", "jump_start", "takeoff"], str(map["idle"]))
	map["fall"] = _pick_animation(animation_names, ["fall", "jump_loop", "air"], str(map["jump"]))
	map["attack"] = _pick_animation(animation_names, ["attack", "punch", "kick", "jab", "strike", "atk"], str(map["idle"]))
	map["hit"] = _pick_animation(animation_names, ["hit", "hurt", "damage", "stagger"], str(map["idle"]))
	map["ko"] = _pick_animation(animation_names, ["ko", "death", "down", "knockout"], str(map["hit"]))
	map["victory"] = _pick_animation(animation_names, ["victory", "win", "taunt", "pose"], str(map["idle"]))
	return map


static func _pick_animation(animation_names: Array[String], keywords: Array[String], fallback: String) -> String:
	for keyword in keywords:
		for animation_name in animation_names:
			if animation_name.to_lower().find(keyword) >= 0:
				return animation_name
	return fallback


static func _uses_fallback_attack_animation(animation_map: Dictionary) -> bool:
	return str(animation_map.get("attack", "")) == str(animation_map.get("idle", ""))


static func _ensure_stage_def(target_dir: String, model_relative_path: String, metrics: Dictionary) -> bool:
	var path: String = "%sstage.def" % target_dir
	if FileAccess.file_exists(path):
		return false
	var arena_half_width: float = float(metrics.get("arena_half_width", 10.0))
	var camera_y: float = float(metrics.get("camera_y", 6.0))
	var camera_z: float = float(metrics.get("camera_z", 12.0))
	var look_y: float = float(metrics.get("look_y", 1.5))
	var stage_offset: Vector3 = metrics.get("stage_offset", Vector3.ZERO)
	var lines: PackedStringArray = [
		"name = %s" % target_dir.trim_suffix("/").get_file(),
		"model_path = %s" % model_relative_path,
		"music = ",
		"music_loop = true",
		"music_volume_db = -6.0",
		"spawn_p1 = -1.25, 0.0, 0.0",
		"spawn_p2 = 1.25, 0.0, 0.0",
		"stage_offset = %.3f, %.3f, %.3f" % [stage_offset.x, stage_offset.y, stage_offset.z],
		"floor_y = 0.0",
		"arena_left = %.3f" % (-arena_half_width),
		"arena_right = %.3f" % arena_half_width,
		"smash_blast_left = %.3f" % (-(arena_half_width + 8.0)),
		"smash_blast_right = %.3f" % (arena_half_width + 8.0),
		"smash_blast_top = %.3f" % (look_y + 18.0),
		"smash_blast_bottom = -9.0",
		"fall_reset_y = -8.0",
		"camera_position = 0.0, %.3f, %.3f" % [camera_y, camera_z],
		"camera_look_target = 0.0, %.3f, 0.0" % look_y
	]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string("\n".join(lines) + "\n")
	return true


static func _collect_model_metrics(model_path: String) -> Dictionary:
	var fallback: Dictionary = {
		"arena_half_width": 10.0,
		"camera_y": 6.0,
		"camera_z": 12.0,
		"look_y": 1.5,
		"stage_offset": Vector3.ZERO,
		"used_fallback_bounds": true
	}
	var scene: Node = ContentResolver.load_model_scene_any_path(model_path)
	if scene == null or not (scene is Node3D):
		return fallback
	var bounds: AABB = _collect_model_aabb(scene as Node3D)
	scene.queue_free()
	if bounds.size.length() <= 0.001:
		return fallback
	var center: Vector3 = bounds.get_center()
	var stage_offset: Vector3 = Vector3(-center.x, -bounds.position.y, -center.z)
	var half_width: float = maxf(8.0, bounds.size.x * 0.6)
	var max_dim: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	return {
		"arena_half_width": half_width,
		"camera_y": maxf(5.0, bounds.size.y * 0.8 + 3.0),
		"camera_z": maxf(10.0, max_dim * 1.35 + 4.0),
		"look_y": maxf(1.25, bounds.size.y * 0.35),
		"stage_offset": stage_offset,
		"used_fallback_bounds": false
	}


static func _collect_model_aabb(root: Node3D) -> AABB:
	var stack: Array[Node] = [root]
	var has_bounds: bool = false
	var merged: AABB = AABB()
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh != null:
				var local_box: AABB = mesh_node.mesh.get_aabb()
				var world_box: AABB = mesh_node.global_transform * local_box
				if not has_bounds:
					merged = world_box
					has_bounds = true
				else:
					merged = merged.merge(world_box)
		for child in node.get_children():
			stack.append(child)
	if not has_bounds:
		return AABB(Vector3.ZERO, Vector3.ZERO)
	return merged
