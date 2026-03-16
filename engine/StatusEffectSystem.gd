extends RefCounted
class_name StatusEffectSystem

## Holds and ticks status effects (poison, burn, defence_down, attack_up, + custom types).
## Custom types: register via StatusEffectRegistry (autoload) with tick / attack_mul / defence_mul callbacks.
## Apply via hit_data "status_effect" / "status_effects" or fighter.apply_status_effect().

var _effects: Array[Dictionary] = []
var _next_id: int = 0
var _registry: Node = null  # StatusEffectRegistry autoload, resolved from tree when we have a node


func apply_effect(effect_def: Dictionary, source: Node = null) -> void:
	if effect_def.is_empty():
		return
	var typ: String = str(effect_def.get("type", "")).strip_edges().to_lower()
	if typ.is_empty():
		return
	var duration: int = int(effect_def.get("duration_frames", 60))
	if duration <= 0:
		return
	var params: Dictionary = {}
	if effect_def.has("params") and effect_def["params"] is Dictionary:
		params = (effect_def["params"] as Dictionary).duplicate()
	else:
		for key in effect_def.keys():
			if key != "type" and key != "duration_frames" and key != "params":
				params[key] = effect_def[key]
	var source_id: int = source.get_instance_id() if source != null else -1
	var tick_interval: int = int(params.get("tick_interval_frames", 30))
	if tick_interval <= 0:
		tick_interval = 30
	var entry: Dictionary = {
		"id": _next_id,
		"type": typ,
		"duration_frames": duration,
		"params": params,
		"frames_until_tick": tick_interval,
		"source_id": source_id
	}
	_next_id += 1
	_effects.append(entry)


func _ensure_registry(node: Node) -> void:
	if _registry != null:
		return
	if node != null and node.get_tree() != null:
		_registry = node.get_tree().root.get_node_or_null("StatusEffectRegistry")


func tick(fighter: Node) -> void:
	if fighter == null:
		return
	_ensure_registry(fighter)
	var to_remove: Array[int] = []
	for i in range(_effects.size() - 1, -1, -1):
		var e: Dictionary = _effects[i]
		e["duration_frames"] = int(e["duration_frames"]) - 1
		if int(e["duration_frames"]) <= 0:
			to_remove.append(i)
			continue
		var typ: String = str(e.get("type", ""))
		var params: Dictionary = e.get("params", {})
		# Built-in DoT
		if typ == "poison" or typ == "burn":
			var until: int = int(e.get("frames_until_tick", 30)) - 1
			e["frames_until_tick"] = until
			if until <= 0:
				var damage: int = int(params.get("damage_per_tick", 1))
				var interval: int = int(params.get("tick_interval_frames", 30))
				if interval <= 0:
					interval = 30
				e["frames_until_tick"] = interval
				if fighter.has_method("set_health"):
					var cur: int = int(fighter.get("health"))
					fighter.call("set_health", maxi(0, cur - damage))
		# Custom type from registry
		elif _registry != null and _registry.has_method("get_tick_handler"):
			var cb: Callable = _registry.call("get_tick_handler", typ)
			if cb.is_valid():
				cb.call(fighter, e)
	to_remove.sort()
	to_remove.reverse()
	for idx in to_remove:
		_effects.remove_at(idx)


func get_attack_mul_modifier(from_node: Node = null) -> float:
	if from_node != null:
		_ensure_registry(from_node)
	var mul: float = 1.0
	for e in _effects:
		var typ: String = str(e.get("type", ""))
		var params: Dictionary = e.get("params", {})
		var v: float = 1.0
		if typ == "attack_up" or params.has("attack_mul"):
			v = float(params.get("attack_mul", 1.0))
		elif _registry != null and _registry.has_method("get_attack_mul_handler"):
			var cb: Callable = _registry.call("get_attack_mul_handler", typ)
			if cb.is_valid():
				v = float(cb.call(e))
		if v > 0.0:
			mul *= v
	return mul


func get_defence_mul_modifier(from_node: Node = null) -> float:
	if from_node != null:
		_ensure_registry(from_node)
	var mul: float = 1.0
	for e in _effects:
		var typ: String = str(e.get("type", ""))
		var params: Dictionary = e.get("params", {})
		var v: float = 1.0
		if typ == "defence_down" or params.has("defence_mul"):
			v = float(params.get("defence_mul", 1.0))
		elif _registry != null and _registry.has_method("get_defence_mul_handler"):
			var cb: Callable = _registry.call("get_defence_mul_handler", typ)
			if cb.is_valid():
				v = float(cb.call(e))
		if v > 0.0:
			mul *= v
	return mul


func has_effects() -> bool:
	return _effects.size() > 0


func get_effect_count() -> int:
	return _effects.size()
