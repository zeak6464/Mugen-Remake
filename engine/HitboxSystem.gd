extends Node
class_name HitboxSystem

signal hit_confirmed(attacker: Node, defender: Node, hit_data: Dictionary)

var fighter: Node = null
var skeleton: Skeleton3D = null
var hitboxes_root: Node3D = null
var hurtboxes_root: Node3D = null
var active_hitboxes: Dictionary = {}
var active_hurtboxes: Dictionary = {}
var active_throwboxes: Dictionary = {}
var persistent_hurtbox_entries: Dictionary = {}
var persistent_hurtboxes: Dictionary = {}
var debug_visuals_enabled: bool = false

const DEBUG_HITBOX_ACTIVE_COLOR := Color(1.0, 0.05, 0.05, 1.0)
const DEBUG_HITBOX_INACTIVE_COLOR := Color(0.55, 0.08, 0.08, 0.95)
const DEBUG_HURTBOX_COLOR := Color(0.0, 1.0, 1.0, 1.0)
const DEBUG_THROWBOX_ACTIVE_COLOR := Color(1.0, 0.25, 0.95, 1.0)
const DEBUG_THROWBOX_INACTIVE_COLOR := Color(0.45, 0.12, 0.42, 0.95)


func setup(p_fighter: Node, p_skeleton: Skeleton3D, p_hitboxes_root: Node3D, p_hurtboxes_root: Node3D) -> void:
	fighter = p_fighter
	skeleton = p_skeleton
	hitboxes_root = p_hitboxes_root
	hurtboxes_root = p_hurtboxes_root


func set_debug_visuals_enabled(enabled: bool) -> void:
	debug_visuals_enabled = enabled
	for area in active_hitboxes.values():
		if area is Area3D:
			var hit_area := area as Area3D
			_set_area_debug_mesh_visible(hit_area, debug_visuals_enabled)
			_set_area_debug_mesh_color(hit_area, DEBUG_HITBOX_ACTIVE_COLOR if hit_area.monitoring else DEBUG_HITBOX_INACTIVE_COLOR)
	for area in active_hurtboxes.values():
		if area is Area3D:
			var runtime_hurt := area as Area3D
			_set_area_debug_mesh_visible(runtime_hurt, debug_visuals_enabled)
			_set_area_debug_mesh_color(runtime_hurt, DEBUG_HURTBOX_COLOR)
	for area in persistent_hurtboxes.values():
		if area is Area3D:
			var persistent_hurt := area as Area3D
			_set_area_debug_mesh_visible(persistent_hurt, debug_visuals_enabled)
			_set_area_debug_mesh_color(persistent_hurt, DEBUG_HURTBOX_COLOR)
	for area in active_throwboxes.values():
		if area is Area3D:
			var throw_area := area as Area3D
			_set_area_debug_mesh_visible(throw_area, debug_visuals_enabled)
			_set_area_debug_mesh_color(throw_area, DEBUG_THROWBOX_ACTIVE_COLOR if throw_area.monitoring else DEBUG_THROWBOX_INACTIVE_COLOR)
	if hurtboxes_root != null:
		for child in hurtboxes_root.get_children():
			if child is Area3D:
				var hurt_area := child as Area3D
				_ensure_area_debug_mesh(hurt_area, DEBUG_HURTBOX_COLOR)
				_set_area_debug_mesh_visible(hurt_area, debug_visuals_enabled)


func get_debug_info() -> Dictionary:
	var hurtbox_count: int = 0
	if hurtboxes_root != null:
		for child in hurtboxes_root.get_children():
			if child is Area3D:
				hurtbox_count += 1

	var active_count: int = 0
	for area in active_hitboxes.values():
		if area is Area3D and (area as Area3D).monitoring:
			active_count += 1
	var active_hurt_count: int = 0
	for area in active_hurtboxes.values():
		if area is Area3D and (area as Area3D).monitoring:
			active_hurt_count += 1
	var persistent_hurt_count: int = 0
	for area in persistent_hurtboxes.values():
		if area is Area3D and (area as Area3D).monitoring:
			persistent_hurt_count += 1
	var active_throw_count: int = 0
	for area in active_throwboxes.values():
		if area is Area3D and (area as Area3D).monitoring:
			active_throw_count += 1

	return {
		"enabled": debug_visuals_enabled,
		"hurtboxes": hurtbox_count,
		"active_hitboxes": active_count,
		"active_hurtboxes": active_hurt_count,
		"persistent_hurtboxes": persistent_hurt_count,
		"active_throwboxes": active_throw_count
	}


func update_hitboxes_for_frame(hitbox_timeline: Array, frame_in_state: int) -> void:
	if hitboxes_root == null:
		return

	var active_ids: Dictionary = {}
	for entry in hitbox_timeline:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var start_frame: int = int(entry.get("start", 0))
		var end_frame: int = int(entry.get("end", -1))
		# Backward-compat: editor often writes start=0,end=0 for "always active" boxes.
		if start_frame == 0 and end_frame == 0:
			end_frame = -1
		if frame_in_state < start_frame:
			continue
		if end_frame >= 0 and frame_in_state > end_frame:
			continue

		var hitbox_id: String = str(entry.get("id", "hitbox_%d" % frame_in_state))
		active_ids[hitbox_id] = true
		_ensure_hitbox_node(hitbox_id, entry)
		_update_hitbox_transform(hitbox_id, entry)
		_set_hitbox_enabled(hitbox_id, true)

	for hitbox_id in active_hitboxes.keys():
		if not active_ids.has(hitbox_id):
			_set_hitbox_enabled(hitbox_id, false)

	_ensure_hurtboxes_active()


func update_hurtboxes_for_frame(hurtbox_timeline: Array, frame_in_state: int) -> void:
	if hurtboxes_root == null:
		return
	if hurtbox_timeline.is_empty():
		for hurtbox_id in active_hurtboxes.keys():
			_set_hurtbox_enabled(hurtbox_id, false)
		return

	var active_ids: Dictionary = {}
	for entry in hurtbox_timeline:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var start_frame: int = int(entry.get("start", 0))
		var end_frame: int = int(entry.get("end", -1))
		# Backward-compat: editor often writes start=0,end=0 for "always active" boxes.
		if start_frame == 0 and end_frame == 0:
			end_frame = -1
		if frame_in_state < start_frame:
			continue
		if end_frame >= 0 and frame_in_state > end_frame:
			continue
		var hurtbox_id: String = str(entry.get("id", "hurtbox_%d" % frame_in_state))
		active_ids[hurtbox_id] = true
		_ensure_hurtbox_node(hurtbox_id, entry)
		_update_hurtbox_transform(hurtbox_id, entry)
		_set_hurtbox_enabled(hurtbox_id, true)

	for hurtbox_id in active_hurtboxes.keys():
		if not active_ids.has(hurtbox_id):
			_set_hurtbox_enabled(hurtbox_id, false)


func update_throwboxes_for_frame(throwbox_timeline: Array, frame_in_state: int) -> void:
	if hitboxes_root == null:
		return
	var active_ids: Dictionary = {}
	for entry in throwbox_timeline:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var start_frame: int = int(entry.get("start", 0))
		var end_frame: int = int(entry.get("end", -1))
		if start_frame == 0 and end_frame == 0:
			end_frame = -1
		if frame_in_state < start_frame:
			continue
		if end_frame >= 0 and frame_in_state > end_frame:
			continue
		var throwbox_id: String = str(entry.get("id", "throwbox_%d" % frame_in_state))
		active_ids[throwbox_id] = true
		_ensure_throwbox_node(throwbox_id, entry)
		_update_throwbox_transform(throwbox_id, entry)
		_set_throwbox_enabled(throwbox_id, true)
	for throwbox_id in active_throwboxes.keys():
		if not active_ids.has(throwbox_id):
			_set_throwbox_enabled(throwbox_id, false)


func set_persistent_hurtboxes(entries: Array) -> void:
	persistent_hurtbox_entries.clear()
	for key in persistent_hurtboxes.keys():
		var existing: Area3D = persistent_hurtboxes[key]
		if existing != null and is_instance_valid(existing):
			existing.queue_free()
	persistent_hurtboxes.clear()
	for i in range(entries.size()):
		var entry = entries[i]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var dict_entry: Dictionary = (entry as Dictionary).duplicate(true)
		var hurtbox_id: String = str(dict_entry.get("id", "persistent_%d" % i))
		persistent_hurtbox_entries[hurtbox_id] = dict_entry
		_ensure_persistent_hurtbox_node(hurtbox_id, dict_entry)
	if hurtboxes_root != null and not persistent_hurtbox_entries.is_empty():
		for child in hurtboxes_root.get_children():
			if child is Area3D:
				var area := child as Area3D
				if bool(area.get_meta("runtime_hurtbox", false)):
					continue
				area.monitoring = false
				area.visible = false
	update_persistent_hurtboxes()


func update_persistent_hurtboxes() -> void:
	for hurtbox_id in persistent_hurtbox_entries.keys():
		var entry: Dictionary = persistent_hurtbox_entries[hurtbox_id]
		_ensure_persistent_hurtbox_node(hurtbox_id, entry)
		_update_persistent_hurtbox_transform(hurtbox_id, entry)
		_set_persistent_hurtbox_enabled(hurtbox_id, true)


func _ensure_hitbox_node(hitbox_id: String, entry: Dictionary) -> void:
	if active_hitboxes.has(hitbox_id):
		return

	var area := Area3D.new()
	area.name = hitbox_id
	area.monitoring = true
	area.monitorable = true
	area.set_meta("is_hitbox", true)
	area.set_meta("owner_fighter", fighter)
	area.set_meta("hit_data", entry.get("data", {}))
	area.area_entered.connect(_on_hitbox_area_entered.bind(area))

	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	var size: Vector3 = _to_vector3(entry.get("size", Vector3.ONE))
	shape.size = size
	shape_node.shape = shape
	area.add_child(shape_node)
	_ensure_area_debug_mesh(area, DEBUG_HITBOX_INACTIVE_COLOR)
	_set_area_debug_mesh_visible(area, debug_visuals_enabled)

	hitboxes_root.add_child(area)
	active_hitboxes[hitbox_id] = area


func _update_hitbox_transform(hitbox_id: String, entry: Dictionary) -> void:
	var area: Area3D = active_hitboxes.get(hitbox_id, null)
	if area == null:
		return

	var local_offset: Vector3 = _resolve_offset_with_facing(_to_vector3(entry.get("offset", Vector3.ZERO)))
	var bone_name: String = str(entry.get("bone", ""))
	if skeleton != null and not bone_name.is_empty():
		var bone_idx: int = skeleton.find_bone(bone_name)
		if bone_idx != -1:
			var bone_transform: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx)
			var world_pos: Vector3 = bone_transform.origin + local_offset
			area.global_transform = Transform3D(Basis.IDENTITY, world_pos)
			area.set_meta("hit_data", entry.get("data", {}))
			return

	area.global_transform = Transform3D(Basis.IDENTITY, _get_fighter_origin() + local_offset)
	area.set_meta("hit_data", entry.get("data", {}))


func _set_hitbox_enabled(hitbox_id: String, enabled: bool) -> void:
	var area: Area3D = active_hitboxes.get(hitbox_id, null)
	if area == null:
		return
	area.monitoring = enabled
	_set_area_debug_mesh_visible(area, debug_visuals_enabled)
	_set_area_debug_mesh_color(area, DEBUG_HITBOX_ACTIVE_COLOR if enabled else DEBUG_HITBOX_INACTIVE_COLOR)


func _ensure_hurtboxes_active() -> void:
	if hurtboxes_root == null:
		return
	if not persistent_hurtbox_entries.is_empty():
		_set_unmanaged_hurtboxes_enabled(false)
		return
	_set_unmanaged_hurtboxes_enabled(true)


func _set_unmanaged_hurtboxes_enabled(enabled: bool) -> void:
	if hurtboxes_root == null:
		return
	for child in hurtboxes_root.get_children():
		if child is Area3D:
			var hurt_area := child as Area3D
			if bool(hurt_area.get_meta("runtime_hurtbox", false)):
				continue
			hurt_area.visible = enabled
			hurt_area.monitoring = enabled
			hurt_area.monitorable = true
			hurt_area.set_meta("is_hurtbox", true)
			hurt_area.set_meta("owner_fighter", fighter)
			_ensure_area_debug_mesh(hurt_area, DEBUG_HURTBOX_COLOR)
			_set_area_debug_mesh_visible(hurt_area, debug_visuals_enabled and enabled)


func _ensure_hurtbox_node(hurtbox_id: String, entry: Dictionary) -> void:
	if active_hurtboxes.has(hurtbox_id):
		return
	var area := Area3D.new()
	area.name = hurtbox_id
	area.monitoring = true
	area.monitorable = true
	area.set_meta("is_hurtbox", true)
	area.set_meta("owner_fighter", fighter)
	area.set_meta("runtime_hurtbox", true)
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = _to_vector3(entry.get("size", Vector3.ONE))
	shape_node.shape = shape
	area.add_child(shape_node)
	_ensure_area_debug_mesh(area, DEBUG_HURTBOX_COLOR)
	_set_area_debug_mesh_visible(area, debug_visuals_enabled)
	hurtboxes_root.add_child(area)
	active_hurtboxes[hurtbox_id] = area


func _update_hurtbox_transform(hurtbox_id: String, entry: Dictionary) -> void:
	var area: Area3D = active_hurtboxes.get(hurtbox_id, null)
	if area == null:
		return
	var shape_node := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null and shape_node.shape is BoxShape3D:
		(shape_node.shape as BoxShape3D).size = _to_vector3(entry.get("size", Vector3.ONE))
		_ensure_area_debug_mesh(area, DEBUG_HURTBOX_COLOR)
	var local_offset: Vector3 = _resolve_offset_with_facing(_to_vector3(entry.get("offset", Vector3.ZERO)))
	var bone_name: String = str(entry.get("bone", ""))
	if skeleton != null and not bone_name.is_empty():
		var bone_idx: int = skeleton.find_bone(bone_name)
		if bone_idx != -1:
			var bone_transform: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx)
			var world_pos: Vector3 = bone_transform.origin + local_offset
			area.global_transform = Transform3D(Basis.IDENTITY, world_pos)
			return
	area.global_transform = Transform3D(Basis.IDENTITY, _get_fighter_origin() + local_offset)


func _set_hurtbox_enabled(hurtbox_id: String, enabled: bool) -> void:
	var area: Area3D = active_hurtboxes.get(hurtbox_id, null)
	if area == null:
		return
	area.monitoring = enabled
	area.monitorable = true
	_set_area_debug_mesh_visible(area, debug_visuals_enabled and enabled)
	_set_area_debug_mesh_color(area, DEBUG_HURTBOX_COLOR)


func _ensure_throwbox_node(throwbox_id: String, entry: Dictionary) -> void:
	if active_throwboxes.has(throwbox_id):
		return
	var area := Area3D.new()
	area.name = throwbox_id
	area.monitoring = true
	area.monitorable = true
	area.set_meta("is_hitbox", true)
	area.set_meta("is_throwbox", true)
	area.set_meta("owner_fighter", fighter)
	area.set_meta("hit_data", _build_throw_hit_data(entry))
	area.area_entered.connect(_on_throwbox_area_entered.bind(area))
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = _scale_size_for_collision(_to_vector3(entry.get("size", Vector3.ONE)))
	shape_node.shape = shape
	area.add_child(shape_node)
	_ensure_area_debug_mesh(area, DEBUG_THROWBOX_INACTIVE_COLOR)
	_set_area_debug_mesh_visible(area, debug_visuals_enabled)
	hitboxes_root.add_child(area)
	active_throwboxes[throwbox_id] = area


func _update_throwbox_transform(throwbox_id: String, entry: Dictionary) -> void:
	var area: Area3D = active_throwboxes.get(throwbox_id, null)
	if area == null:
		return
	var shape_node := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null and shape_node.shape is BoxShape3D:
		(shape_node.shape as BoxShape3D).size = _scale_size_for_collision(_to_vector3(entry.get("size", Vector3.ONE)))
		_ensure_area_debug_mesh(area, DEBUG_THROWBOX_INACTIVE_COLOR)
	var local_offset: Vector3 = _resolve_offset_with_facing(_to_vector3(entry.get("offset", Vector3.ZERO)))
	var bone_name: String = str(entry.get("bone", ""))
	if skeleton != null and not bone_name.is_empty():
		var bone_idx: int = skeleton.find_bone(bone_name)
		if bone_idx != -1:
			var bone_transform: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx)
			var world_pos: Vector3 = bone_transform.origin + local_offset
			area.global_transform = Transform3D(Basis.IDENTITY, world_pos)
			area.set_meta("hit_data", _build_throw_hit_data(entry))
			return
	area.global_transform = Transform3D(Basis.IDENTITY, _get_fighter_origin() + local_offset)
	area.set_meta("hit_data", _build_throw_hit_data(entry))


func _set_throwbox_enabled(throwbox_id: String, enabled: bool) -> void:
	var area: Area3D = active_throwboxes.get(throwbox_id, null)
	if area == null:
		return
	area.monitoring = enabled
	area.monitorable = true
	_set_area_debug_mesh_visible(area, debug_visuals_enabled and enabled)
	_set_area_debug_mesh_color(area, DEBUG_THROWBOX_ACTIVE_COLOR if enabled else DEBUG_THROWBOX_INACTIVE_COLOR)


func _ensure_persistent_hurtbox_node(hurtbox_id: String, entry: Dictionary) -> void:
	if persistent_hurtboxes.has(hurtbox_id):
		return
	if hurtboxes_root == null:
		return
	var area := Area3D.new()
	area.name = "Persistent_%s" % hurtbox_id
	area.monitoring = true
	area.monitorable = true
	area.set_meta("is_hurtbox", true)
	area.set_meta("owner_fighter", fighter)
	area.set_meta("runtime_hurtbox", true)
	area.set_meta("persistent_hurtbox", true)
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = _scale_size_for_collision(_to_vector3(entry.get("size", Vector3.ONE)))
	shape_node.shape = shape
	area.add_child(shape_node)
	_ensure_area_debug_mesh(area, DEBUG_HURTBOX_COLOR)
	_set_area_debug_mesh_visible(area, debug_visuals_enabled)
	hurtboxes_root.add_child(area)
	persistent_hurtboxes[hurtbox_id] = area


func _update_persistent_hurtbox_transform(hurtbox_id: String, entry: Dictionary) -> void:
	var area: Area3D = persistent_hurtboxes.get(hurtbox_id, null)
	if area == null:
		return
	var shape_node := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null and shape_node.shape is BoxShape3D:
		(shape_node.shape as BoxShape3D).size = _scale_size_for_collision(_to_vector3(entry.get("size", Vector3.ONE)))
		_ensure_area_debug_mesh(area, DEBUG_HURTBOX_COLOR)
	var local_offset: Vector3 = _resolve_offset_with_facing(_to_vector3(entry.get("offset", Vector3.ZERO)))
	var bone_name: String = str(entry.get("bone", ""))
	if skeleton != null and not bone_name.is_empty():
		var bone_idx: int = skeleton.find_bone(bone_name)
		if bone_idx != -1:
			var bone_transform: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx)
			var world_pos: Vector3 = bone_transform.origin + local_offset
			area.global_transform = Transform3D(Basis.IDENTITY, world_pos)
			return
	area.global_transform = Transform3D(Basis.IDENTITY, _get_fighter_origin() + local_offset)


func _set_persistent_hurtbox_enabled(hurtbox_id: String, enabled: bool) -> void:
	var area: Area3D = persistent_hurtboxes.get(hurtbox_id, null)
	if area == null:
		return
	area.monitoring = enabled
	area.monitorable = true
	_set_area_debug_mesh_visible(area, debug_visuals_enabled and enabled)
	_set_area_debug_mesh_color(area, DEBUG_HURTBOX_COLOR)


func _build_throw_hit_data(entry: Dictionary) -> Dictionary:
	var data = entry.get("data", {})
	var result: Dictionary = data.duplicate(true) if typeof(data) == TYPE_DICTIONARY else {}
	if not result.has("attack_type"):
		result["attack_type"] = "grapple"
	if not result.has("grapple"):
		result["grapple"] = true
	if not result.has("grapple_hold"):
		result["grapple_hold"] = true
	return result


func _resolve_offset_with_facing(offset: Vector3) -> Vector3:
	var resolved: Vector3 = offset
	if fighter != null and fighter.has_method("get") and fighter.get("command_interpreter") != null:
		var ci = fighter.get("command_interpreter")
		if ci != null and ci.has_method("get_facing_right"):
			var facing_right: bool = bool(ci.call("get_facing_right"))
			if not facing_right:
				resolved.x = -resolved.x
	return resolved


func _get_fighter_origin() -> Vector3:
	if fighter != null and fighter is Node3D:
		return (fighter as Node3D).global_position
	return Vector3.ZERO


func _on_hitbox_area_entered(other_area: Area3D, hitbox_area: Area3D) -> void:
	if other_area == null or not other_area.has_meta("is_hurtbox"):
		return
	var attacker: Node = hitbox_area.get_meta("owner_fighter", null)
	var defender: Node = other_area.get_meta("owner_fighter", null)
	if attacker == null or defender == null or attacker == defender:
		return
	var hit_data: Dictionary = hitbox_area.get_meta("hit_data", {})
	hit_confirmed.emit(attacker, defender, hit_data)


func _on_throwbox_area_entered(other_area: Area3D, throwbox_area: Area3D) -> void:
	if other_area == null or not other_area.has_meta("is_hurtbox"):
		return
	var attacker: Node = throwbox_area.get_meta("owner_fighter", null)
	var defender: Node = other_area.get_meta("owner_fighter", null)
	if attacker == null or defender == null or attacker == defender:
		return
	var hit_data: Dictionary = throwbox_area.get_meta("hit_data", {})
	hit_confirmed.emit(attacker, defender, hit_data)


func _to_vector3(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(
			float(value.get("x", 0.0)),
			float(value.get("y", 0.0)),
			float(value.get("z", 0.0))
		)
	return Vector3.ZERO


func _scale_size_for_collision(size: Vector3) -> Vector3:
	var collision_scale: float = 1.0
	if fighter != null and fighter.has_method("get"):
		collision_scale = maxf(0.1, float(fighter.get("collision_scale")))
	return Vector3(
		maxf(0.05, size.x * collision_scale),
		maxf(0.05, size.y * collision_scale),
		maxf(0.05, size.z * collision_scale)
	)


func _ensure_area_debug_mesh(area: Area3D, color: Color) -> void:
	var debug_mesh := area.get_node_or_null("DebugMesh") as MeshInstance3D
	var collision_shape := area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		return
	if debug_mesh == null:
		debug_mesh = MeshInstance3D.new()
		debug_mesh.name = "DebugMesh"
		area.add_child(debug_mesh)

	var box_mesh := BoxMesh.new()
	box_mesh.size = _collision_shape_to_box_size(collision_shape.shape) * 1.45
	debug_mesh.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	debug_mesh.material_override = mat
	debug_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _set_area_debug_mesh_visible(area: Area3D, visible_value: bool) -> void:
	var debug_mesh := area.get_node_or_null("DebugMesh") as MeshInstance3D
	if debug_mesh != null:
		debug_mesh.visible = visible_value


func _set_area_debug_mesh_color(area: Area3D, color: Color) -> void:
	var debug_mesh := area.get_node_or_null("DebugMesh") as MeshInstance3D
	if debug_mesh == null:
		return
	var mat := debug_mesh.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = color
	mat.emission = color


func _collision_shape_to_box_size(shape: Shape3D) -> Vector3:
	if shape is BoxShape3D:
		return (shape as BoxShape3D).size
	if shape is CapsuleShape3D:
		var cap := shape as CapsuleShape3D
		var diameter := cap.radius * 2.0
		return Vector3(diameter, cap.height + diameter, diameter)
	if shape is SphereShape3D:
		var sph := shape as SphereShape3D
		var d := sph.radius * 2.0
		return Vector3(d, d, d)
	return Vector3.ONE
