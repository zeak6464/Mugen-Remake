extends Node
class_name ProjectileSystem

signal projectile_hit(attacker: Node, defender: Node, hit_data: Dictionary)

var fighter: Node = null
var projectiles_data: Dictionary = {}
var active_projectiles: Array[ProjectileBase] = []


func setup(p_fighter: Node) -> void:
	fighter = p_fighter


func set_projectiles_data(data: Dictionary) -> void:
	projectiles_data = data.duplicate(true)


func spawn_projectile(projectile_id: String, facing_right: bool, spawn_origin: Vector3) -> ProjectileBase:
	if projectile_id.is_empty() or fighter == null:
		return null
	var def: Dictionary = _get_projectile_definition(projectile_id)
	if def.is_empty():
		return null

	var spawn_offset: Vector3 = _to_vector3(def.get("spawn_offset", Vector3.ZERO))
	if not facing_right:
		spawn_offset.x *= -1.0

	var velocity: Vector3 = _to_vector3(def.get("velocity", Vector3.ZERO))
	var stationary: bool = bool(def.get("stationary", false))
	if not stationary and velocity.is_zero_approx():
		var speed: float = float(def.get("speed", 8.0))
		velocity = Vector3(speed if facing_right else -speed, 0.0, 0.0)
	elif not facing_right and not velocity.is_zero_approx():
		velocity.x *= -1.0

	var size: Vector3 = _to_vector3(def.get("size", Vector3(0.4, 0.4, 0.4)))
	var lifetime_frames: int = int(def.get("lifetime_frames", 90))
	var despawn_on_hit: bool = bool(def.get("despawn_on_hit", true))
	var hit_data: Dictionary = def.get("hit_data", {}).duplicate(true)

	var projectile := ProjectileBase.new()
	projectile.name = "Projectile_%s_%d" % [projectile_id, Time.get_ticks_msec()]
	var root: Node = fighter.get_parent() if fighter.get_parent() != null else self
	root.add_child(projectile)
	projectile.setup(fighter, spawn_origin + spawn_offset, velocity, lifetime_frames, hit_data, size, despawn_on_hit, def)
	projectile.projectile_hit.connect(_on_projectile_hit)
	projectile.projectile_expired.connect(_on_projectile_expired)
	active_projectiles.append(projectile)
	return projectile


func _on_projectile_hit(attacker: Node, defender: Node, hit_data: Dictionary) -> void:
	projectile_hit.emit(attacker, defender, hit_data)


func _on_projectile_expired(projectile: ProjectileBase) -> void:
	active_projectiles.erase(projectile)


func clear_active_projectiles() -> void:
	for p in active_projectiles:
		if is_instance_valid(p):
			p.queue_free()
	active_projectiles.clear()


func _get_projectile_definition(projectile_id: String) -> Dictionary:
	if projectiles_data.has("projectiles") and projectiles_data["projectiles"] is Array:
		for entry in projectiles_data["projectiles"]:
			if typeof(entry) == TYPE_DICTIONARY and str(entry.get("id", "")) == projectile_id:
				return (entry as Dictionary).duplicate(true)
	if projectiles_data.has(projectile_id) and typeof(projectiles_data[projectile_id]) == TYPE_DICTIONARY:
		var out: Dictionary = (projectiles_data[projectile_id] as Dictionary).duplicate(true)
		if not out.has("id"):
			out["id"] = projectile_id
		return out
	return {}


func _to_vector3(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO
