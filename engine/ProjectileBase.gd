extends Area3D
class_name ProjectileBase

signal projectile_hit(attacker: Node, defender: Node, hit_data: Dictionary)
signal projectile_expired(projectile: ProjectileBase)

var owner_fighter: Node = null
var velocity: Vector3 = Vector3.ZERO
var lifetime_frames: int = 60
var frame_count: int = 0
var despawn_on_hit: bool = true
var hit_data: Dictionary = {}
var hit_target_ids: Dictionary = {}
var projectile_def: Dictionary = {}
var visual_root: Node3D = null
var trail_root: GPUParticles3D = null

## Downward acceleration (world units / sec²). 0 = legacy linear motion only.
## (Named fall_gravity — Area3D reserves "gravity".)
var fall_gravity: float = 0.0
## 0 = slide / rest on floor; >0 reflects off static geometry (layer mask below).
var bounce_restitution: float = 0.0
var bounce_horizontal_mult: float = 1.0
## Stop bouncing when vertical speed after bounce is below this (prevents jitter).
var bounce_min_vertical_speed: float = 0.35
## -1 = unlimited bounces; 0 = never bounce (same as restitution 0 for count).
var max_floor_bounces: int = -1
## True = apply frame-step equations (vy -= g, pos += v) without delta scaling.
var use_discrete_step: bool = false
## Optional lifecycle behavior: despawn once bounce count reaches max_floor_bounces.
var despawn_on_max_bounces: bool = false
## Optional lifecycle behavior: despawn when bounce speed falls below threshold.
var despawn_on_settle: bool = true
## Optional lifecycle behavior: despawn after traveling this distance (<= 0 disables).
var max_range: float = 0.0
## Bitmask for floor raycasts (default: layer 1 = static stage meshes / legacy floor).
var floor_collision_mask: int = 1
var _half_y: float = 0.25
var _floor_bounces_done: int = 0
var _start_position: Vector3 = Vector3.ZERO


func setup(owner_node: Node, spawn_position: Vector3, projectile_velocity: Vector3, frames_to_live: int, data: Dictionary, size: Vector3, should_despawn_on_hit: bool, def: Dictionary = {}) -> void:
	owner_fighter = owner_node
	global_position = spawn_position
	velocity = projectile_velocity
	lifetime_frames = maxi(1, frames_to_live)
	hit_data = data.duplicate(true)
	despawn_on_hit = should_despawn_on_hit
	projectile_def = def.duplicate(true)
	fall_gravity = maxf(0.0, float(projectile_def.get("gravity", 0.0)))
	var restitution_input: Variant = projectile_def.get("bounce_restitution", projectile_def.get("bounce_damping", 0.0))
	bounce_restitution = clampf(float(restitution_input), 0.0, 2.0)
	bounce_horizontal_mult = clampf(float(projectile_def.get("bounce_horizontal_mult", 1.0)), 0.0, 2.0)
	bounce_min_vertical_speed = maxf(0.0, float(projectile_def.get("bounce_min_vertical_speed", 0.35)))
	max_floor_bounces = int(projectile_def.get("max_floor_bounces", projectile_def.get("max_bounces", -1)))
	use_discrete_step = bool(projectile_def.get("use_discrete_step", false))
	despawn_on_max_bounces = bool(projectile_def.get("despawn_on_max_bounces", projectile_def.has("max_bounces")))
	despawn_on_settle = bool(projectile_def.get("despawn_on_settle", true))
	max_range = maxf(0.0, float(projectile_def.get("max_range", 0.0)))
	floor_collision_mask = maxi(1, int(projectile_def.get("floor_collision_mask", 1)))
	_half_y = maxf(0.025, size.y * 0.5)
	_floor_bounces_done = 0
	_start_position = global_position
	monitoring = true
	monitorable = true
	# Match HitboxSystem hurtboxes (layer 1). Default Area3D mask can miss overlaps.
	collision_layer = 1
	collision_mask = 1
	set_meta("owner_fighter", owner_fighter)
	_ensure_collision_shape(size)
	_ensure_visual(size)
	_ensure_trail()


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if fall_gravity > 0.0:
		velocity.y -= fall_gravity if use_discrete_step else (fall_gravity * delta)
	global_position += velocity if use_discrete_step else (velocity * delta)
	if fall_gravity > 0.0 or bounce_restitution > 0.0:
		_resolve_floor_collision()
	if max_range > 0.0 and _start_position.distance_to(global_position) > max_range:
		projectile_expired.emit(self)
		queue_free()
		return
	_update_visual_facing()
	_update_trail_direction()
	frame_count += 1
	if frame_count >= lifetime_frames:
		projectile_expired.emit(self)
		queue_free()


func _on_area_entered(other_area: Area3D) -> void:
	if other_area == null or is_queued_for_deletion():
		return
	if other_area is ProjectileBase:
		_cancel_against_projectile(other_area as ProjectileBase)
		return
	if not other_area.has_meta("is_hurtbox"):
		return
	var defender: Node = other_area.get_meta("owner_fighter", null)
	if defender == null or defender == owner_fighter:
		return
	if owner_fighter != null and owner_fighter.has_method("get") and defender.has_method("get"):
		var owner_team: int = int(owner_fighter.get("team_id"))
		var defender_team: int = int(defender.get("team_id"))
		# Teammates should be transparent to allied projectiles.
		if owner_team > 0 and owner_team == defender_team:
			return
	if defender.has_method("try_reflect_projectile"):
		var reflected: bool = bool(defender.call("try_reflect_projectile", self, owner_fighter, hit_data))
		if reflected:
			return
	var defender_id: int = defender.get_instance_id()
	if hit_target_ids.has(defender_id):
		return
	hit_target_ids[defender_id] = true
	var emit_data: Dictionary = hit_data.duplicate(true)
	emit_data["is_projectile"] = true
	projectile_hit.emit(owner_fighter, defender, emit_data)
	if despawn_on_hit:
		projectile_expired.emit(self)
		queue_free()


func _cancel_against_projectile(other_projectile: ProjectileBase) -> void:
	if other_projectile == null or other_projectile == self:
		return
	if other_projectile.is_queued_for_deletion():
		return
	if owner_fighter == other_projectile.owner_fighter:
		return
	if _shares_owner_team(other_projectile.owner_fighter):
		return
	projectile_expired.emit(self)
	queue_free()
	other_projectile.projectile_expired.emit(other_projectile)
	other_projectile.queue_free()


func _shares_owner_team(other_owner: Node) -> bool:
	if owner_fighter == null or other_owner == null:
		return false
	if not owner_fighter.has_method("get") or not other_owner.has_method("get"):
		return false
	var owner_team: int = int(owner_fighter.get("team_id"))
	var other_team: int = int(other_owner.get("team_id"))
	return owner_team > 0 and owner_team == other_team


func reflect_to(new_owner: Node) -> void:
	if new_owner == null:
		return
	owner_fighter = new_owner
	set_meta("owner_fighter", owner_fighter)
	velocity.x *= -1.0
	hit_target_ids.clear()


func _resolve_floor_collision() -> void:
	var world := get_world_3d()
	if world == null:
		return
	var space := world.direct_space_state
	var from := global_position + Vector3(0.0, _half_y + 0.04, 0.0)
	var to := global_position + Vector3(0.0, -80.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = floor_collision_mask
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return
	var n: Vector3 = hit.get("normal", Vector3.UP)
	if n.y < 0.45:
		return
	var floor_y: float = hit.position.y
	var bottom_y: float = global_position.y - _half_y
	if bottom_y > floor_y + 0.08:
		return
	var penetrated_floor: bool = bottom_y < floor_y
	if penetrated_floor:
		global_position = hit.position + n * (_half_y + 0.02)
	var vn: float = velocity.dot(n)
	if vn >= -0.02:
		return
	if bounce_restitution > 0.0:
		if max_floor_bounces >= 0 and _floor_bounces_done >= max_floor_bounces:
			if despawn_on_max_bounces:
				projectile_expired.emit(self)
				queue_free()
				return
			velocity -= vn * n
			return
		if use_discrete_step and n.y > 0.85:
			# Mario-style discrete bounce: vy = -vy * e
			velocity.y = absf(velocity.y) * bounce_restitution
		else:
			velocity = velocity - (1.0 + bounce_restitution) * vn * n
		velocity.x *= bounce_horizontal_mult
		velocity.z *= bounce_horizontal_mult
		_floor_bounces_done += 1
		if despawn_on_max_bounces and max_floor_bounces >= 0 and _floor_bounces_done >= max_floor_bounces:
			projectile_expired.emit(self)
			queue_free()
			return
		if n.y > 0.85 and absf(velocity.y) < bounce_min_vertical_speed:
			if despawn_on_settle:
				projectile_expired.emit(self)
				queue_free()
				return
			velocity.y = 0.0
	else:
		velocity -= vn * n


func _ensure_collision_shape(size: Vector3) -> void:
	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		shape_node = CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		add_child(shape_node)
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(0.05, size.x), maxf(0.05, size.y), maxf(0.05, size.z))
	shape_node.shape = box


func _ensure_visual(size: Vector3) -> void:
	var existing_visual := get_node_or_null("VisualRoot") as Node3D
	if existing_visual != null:
		existing_visual.queue_free()
	var custom_visual: Node3D = _build_custom_visual()
	if custom_visual != null:
		custom_visual.name = "VisualRoot"
		add_child(custom_visual)
		visual_root = custom_visual
		_apply_visual_material_overrides(custom_visual)
		_play_visual_animation(custom_visual)
		_update_visual_facing()
		return
	_ensure_debug_mesh(size)
	visual_root = get_node_or_null("DebugMesh") as Node3D
	_update_visual_facing()


func _build_custom_visual() -> Node3D:
	var visual_path: String = _resolve_visual_path()
	if visual_path.is_empty():
		return null
	var visual_root: Node3D = _load_visual_node_from_path(visual_path)
	if visual_root == null:
		return null
	visual_root.position = _to_vector3(projectile_def.get("visual_offset", projectile_def.get("model_offset", Vector3.ZERO)))
	visual_root.rotation_degrees = _to_vector3(projectile_def.get("visual_rotation_degrees", projectile_def.get("model_rotation_degrees", Vector3.ZERO)))
	visual_root.scale = _extract_visual_scale()
	return visual_root


func _resolve_visual_path() -> String:
	for key in ["visual_path", "model_path", "scene_path"]:
		var path: String = str(projectile_def.get(key, "")).strip_edges()
		if not path.is_empty():
			return path
	return ""


func _extract_visual_scale() -> Vector3:
	for key in ["visual_scale", "model_scale"]:
		if not projectile_def.has(key):
			continue
		var value = projectile_def.get(key)
		if value is int or value is float:
			return Vector3.ONE * float(value)
		if value is Vector3:
			return value
		if value is Array and value.size() >= 3:
			return Vector3(float(value[0]), float(value[1]), float(value[2]))
		if value is Dictionary:
			return Vector3(float(value.get("x", 1.0)), float(value.get("y", 1.0)), float(value.get("z", 1.0)))
	return Vector3.ONE


func _ensure_debug_mesh(size: Vector3) -> void:
	var mesh_node := get_node_or_null("DebugMesh") as MeshInstance3D
	if mesh_node == null:
		mesh_node = MeshInstance3D.new()
		mesh_node.name = "DebugMesh"
		add_child(mesh_node)
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(maxf(0.05, size.x), maxf(0.05, size.y), maxf(0.05, size.z)) * 1.1
	mesh_node.mesh = box_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.7, 0.1, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.1, 0.9)
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_node.material_override = mat
	_apply_material_override_from_def(mesh_node, mat)


func _ensure_trail() -> void:
	var existing_trail := get_node_or_null("TrailRoot") as GPUParticles3D
	if existing_trail != null:
		existing_trail.queue_free()
	trail_root = null
	if not bool(projectile_def.get("trail_enabled", false)):
		return
	var particles := GPUParticles3D.new()
	particles.name = "TrailRoot"
	particles.local_coords = false
	particles.amount = int(projectile_def.get("trail_amount", 18))
	particles.lifetime = maxf(0.05, float(projectile_def.get("trail_lifetime", 0.25)))
	particles.one_shot = false
	particles.explosiveness = 0.0
	particles.fixed_fps = 60
	particles.draw_order = GPUParticles3D.DRAW_ORDER_LIFETIME

	var quad := QuadMesh.new()
	var trail_size = projectile_def.get("trail_size", [0.28, 0.16])
	if trail_size is int or trail_size is float:
		quad.size = Vector2(float(trail_size), float(trail_size))
	elif trail_size is Array and trail_size.size() >= 2:
		quad.size = Vector2(float(trail_size[0]), float(trail_size[1]))
	else:
		quad.size = Vector2(0.28, 0.16)
	particles.draw_pass_1 = quad

	var process := ParticleProcessMaterial.new()
	process.direction = _trail_direction()
	process.initial_velocity_min = maxf(0.0, float(projectile_def.get("trail_velocity_min", 0.15)))
	process.initial_velocity_max = maxf(process.initial_velocity_min, float(projectile_def.get("trail_velocity_max", 0.45)))
	process.gravity = Vector3.ZERO
	process.scale_min = maxf(0.01, float(projectile_def.get("trail_scale_min", 0.18)))
	process.scale_max = maxf(process.scale_min, float(projectile_def.get("trail_scale_max", 0.42)))
	process.color = _color_from_variant(projectile_def.get("trail_color", Color(1.0, 0.6, 0.2, 0.8)), Color(1.0, 0.6, 0.2, 0.8))
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particles.process_material = process

	var trail_material := StandardMaterial3D.new()
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	trail_material.albedo_color = _color_from_variant(projectile_def.get("trail_color", Color(1.0, 0.6, 0.2, 0.8)), Color(1.0, 0.6, 0.2, 0.8))
	trail_material.emission_enabled = true
	trail_material.emission = _color_from_variant(projectile_def.get("trail_emission", projectile_def.get("trail_color", Color(1.0, 0.6, 0.2, 1.0))), Color(1.0, 0.6, 0.2, 1.0))
	trail_material.no_depth_test = bool(projectile_def.get("trail_no_depth_test", true))
	trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	particles.material_override = trail_material

	add_child(particles)
	trail_root = particles
	particles.emitting = true


func _play_visual_animation(root: Node) -> void:
	var player: AnimationPlayer = _find_animation_player_recursive(root)
	if player == null or player.get_animation_list().is_empty():
		return
	var animation_name: String = str(projectile_def.get("visual_animation", "")).strip_edges()
	if animation_name.is_empty():
		animation_name = str(player.get_animation_list()[0])
	if not player.has_animation(animation_name):
		return
	var should_loop: bool = bool(projectile_def.get("visual_animation_loop", true))
	var anim := player.get_animation(animation_name)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	player.speed_scale = float(projectile_def.get("visual_animation_speed", 1.0))
	player.play(animation_name)


func _apply_visual_material_overrides(root: Node) -> void:
	for child in root.find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D:
			var mesh_node := child as MeshInstance3D
			var base_material: BaseMaterial3D = null
			if mesh_node.material_override is BaseMaterial3D:
				base_material = (mesh_node.material_override as BaseMaterial3D).duplicate() as BaseMaterial3D
			else:
				for surface_idx in range(mesh_node.get_surface_override_material_count()):
					var surface_override: Material = mesh_node.get_surface_override_material(surface_idx)
					if surface_override is BaseMaterial3D:
						base_material = (surface_override as BaseMaterial3D).duplicate() as BaseMaterial3D
						break
				if base_material == null and mesh_node.mesh != null and mesh_node.mesh.get_surface_count() > 0:
					var surface_material: Material = mesh_node.mesh.surface_get_material(0)
					if surface_material is BaseMaterial3D:
						base_material = (surface_material as BaseMaterial3D).duplicate() as BaseMaterial3D
			if base_material == null:
				base_material = StandardMaterial3D.new()
			_apply_material_override_from_def(mesh_node, base_material)


func _apply_material_override_from_def(mesh_node: GeometryInstance3D, material: BaseMaterial3D) -> void:
	material.albedo_color = _color_from_variant(projectile_def.get("visual_tint", material.albedo_color), material.albedo_color)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if material.albedo_color.a < 0.999 else material.transparency
	if projectile_def.has("visual_unshaded"):
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if bool(projectile_def.get("visual_unshaded", false)) else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if projectile_def.has("visual_emission"):
		material.emission_enabled = true
		material.emission = _color_from_variant(projectile_def.get("visual_emission", Color.BLACK), Color.BLACK)
	if projectile_def.has("visual_no_depth_test"):
		material.no_depth_test = bool(projectile_def.get("visual_no_depth_test", false))
	material.cull_mode = BaseMaterial3D.CULL_DISABLED if bool(projectile_def.get("visual_double_sided", true)) else BaseMaterial3D.CULL_BACK
	mesh_node.material_override = material


func _update_visual_facing() -> void:
	if visual_root == null or not is_instance_valid(visual_root):
		return
	if bool(projectile_def.get("visual_face_velocity", true)) and velocity.length_squared() > 0.0001:
		visual_root.look_at(global_position + velocity.normalized(), Vector3.UP, true)
	visual_root.rotate_object_local(Vector3.UP, deg_to_rad(float(projectile_def.get("visual_yaw_offset_degrees", 0.0))))


func _update_trail_direction() -> void:
	if trail_root == null or not is_instance_valid(trail_root):
		return
	var process := trail_root.process_material as ParticleProcessMaterial
	if process == null:
		return
	process.direction = _trail_direction()


func _trail_direction() -> Vector3:
	if velocity.length_squared() <= 0.0001:
		return Vector3(-1.0, 0.0, 0.0)
	return -velocity.normalized()


func _find_animation_player_recursive(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found: AnimationPlayer = _find_animation_player_recursive(child)
		if found != null:
			return found
	return null


func _color_from_variant(value, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var text: String = str(value).strip_edges()
		if text.is_empty():
			return fallback
		return Color.from_string(text, fallback)
	if value is Array and value.size() >= 3:
		var alpha: float = float(value[3]) if value.size() >= 4 else 1.0
		return Color(float(value[0]), float(value[1]), float(value[2]), alpha)
	if value is Dictionary:
		return Color(float(value.get("r", fallback.r)), float(value.get("g", fallback.g)), float(value.get("b", fallback.b)), float(value.get("a", fallback.a)))
	return fallback


func _load_visual_node_from_path(path: String) -> Node3D:
	if path.is_empty():
		return null
	var lower: String = path.to_lower()

	if path.begins_with("user://") and (lower.ends_with(".gltf") or lower.ends_with(".glb")):
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		if gltf.append_from_file(path, state) != OK:
			return null
		var scene := gltf.generate_scene(state)
		if scene is Node3D:
			return scene as Node3D
		return null

	var loaded = ResourceLoader.load(path)
	if loaded is PackedScene:
		var inst := (loaded as PackedScene).instantiate()
		if inst is Node3D:
			return inst as Node3D
		return null

	if lower.ends_with(".gltf") or lower.ends_with(".glb"):
		var gltf2 := GLTFDocument.new()
		var state2 := GLTFState.new()
		if gltf2.append_from_file(path, state2) != OK:
			return null
		var scene2 := gltf2.generate_scene(state2)
		if scene2 is Node3D:
			return scene2 as Node3D
	return null


func _to_vector3(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO
