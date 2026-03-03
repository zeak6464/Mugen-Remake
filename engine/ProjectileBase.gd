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


func setup(owner_node: Node, spawn_position: Vector3, projectile_velocity: Vector3, frames_to_live: int, data: Dictionary, size: Vector3, should_despawn_on_hit: bool) -> void:
	owner_fighter = owner_node
	global_position = spawn_position
	velocity = projectile_velocity
	lifetime_frames = maxi(1, frames_to_live)
	hit_data = data.duplicate(true)
	despawn_on_hit = should_despawn_on_hit
	monitoring = true
	monitorable = true
	set_meta("owner_fighter", owner_fighter)
	_ensure_collision_shape(size)
	_ensure_debug_mesh(size)


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	frame_count += 1
	if frame_count >= lifetime_frames:
		projectile_expired.emit(self)
		queue_free()


func _on_area_entered(other_area: Area3D) -> void:
	if other_area == null or not other_area.has_meta("is_hurtbox"):
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


func reflect_to(new_owner: Node) -> void:
	if new_owner == null:
		return
	owner_fighter = new_owner
	set_meta("owner_fighter", owner_fighter)
	velocity.x *= -1.0
	hit_target_ids.clear()


func _ensure_collision_shape(size: Vector3) -> void:
	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		shape_node = CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		add_child(shape_node)
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(0.05, size.x), maxf(0.05, size.y), maxf(0.05, size.z))
	shape_node.shape = box


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
