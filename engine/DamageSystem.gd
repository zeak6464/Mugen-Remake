extends Node
class_name DamageSystem

signal combo_event(attacker: Node, defender: Node, total_hits: int, total_damage: int)
signal combat_event(event_id: String, attacker: Node, defender: Node, hit_data: Dictionary)
signal damage_dealt(attacker: Node, defender: Node, amount: int)

var combo_tracker: Dictionary = {}
var smash_mode_enabled: bool = false


func apply_hit(attacker: Node, defender: Node, hit_data: Dictionary) -> void:
	if attacker == null or defender == null:
		return
	if not defender.has_method("set_health"):
		return
	if smash_mode_enabled and defender.has_method("is_smash_respawn_protected") and bool(defender.call("is_smash_respawn_protected")):
		return
	if defender.has_method("_nothitby_blocks") and bool(defender.call("_nothitby_blocks", hit_data)):
		return
	if defender.has_method("_hitby_blocks") and bool(defender.call("_hitby_blocks", hit_data)):
		return

	var is_grapple: bool = bool(hit_data.get("grapple", false)) or str(hit_data.get("attack_type", "")) == "grapple"
	var is_parry_active: bool = defender.has_method("_is_parry_active") and bool(defender.call("_is_parry_active"))
	var reversal_matches: bool = true
	if is_parry_active and defender.has_method("_reversal_matches_hit"):
		reversal_matches = bool(defender.call("_reversal_matches_hit", hit_data))
	if not is_grapple and is_parry_active and reversal_matches:
		if attacker.has_method("enter_hitstun"):
			var recoil_state: String = str(hit_data.get("parry_recoil_state", "hitstun"))
			attacker.call("enter_hitstun", recoil_state)
		if defender.has_method("add_resource"):
			defender.call("add_resource", int(hit_data.get("parry_meter_gain", 25)))
		combat_event.emit("parry", attacker, defender, hit_data)
		return

	var throw_invuln: bool = false
	if defender.has_method("get") and defender.get("state_controller") != null:
		var sc = defender.get("state_controller")
		if sc != null and sc.has_method("get_current_state_data"):
			var info: Dictionary = sc.call("get_current_state_data")
			throw_invuln = bool(info.get("throw_invuln", false))
	if is_grapple and throw_invuln:
		return
	if is_grapple and bool(hit_data.get("grapple_hold", false)):
		if defender.has_method("can_throw_tech") and bool(defender.call("can_throw_tech", hit_data, attacker)):
			var tech_pushback: Vector3 = _to_vector3(hit_data.get("throw_tech_pushback", Vector3(-0.6, 0.0, 0.0)))
			if attacker.has_method("apply_pushback"):
				attacker.call("apply_pushback", tech_pushback)
			combat_event.emit("throw_tech", attacker, defender, hit_data)
			return
		var started: bool = false
		if attacker.has_method("start_grapple_sequence"):
			started = bool(attacker.call("start_grapple_sequence", defender, hit_data))
			if started:
				combat_event.emit("throw_start", attacker, defender, hit_data)
		if not started and attacker.has_method("notify_grapple_whiff"):
			attacker.call("notify_grapple_whiff", hit_data)
		# Grapple-hold attacks should never fall through to normal hit damage on whiff/fail.
		# Damage for successful throws is applied on grapple release.
		return

	var is_guarding: bool = defender.has_method("_is_guarding") and bool(defender.call("_is_guarding"))
	var block_check_available: bool = defender.has_method("_can_block_hit")
	var can_block_hit: bool = bool(defender.call("_can_block_hit", hit_data)) if block_check_available else is_guarding
	var is_blocking: bool = bool(hit_data.get("is_blocked", false)) or (not is_grapple and can_block_hit)
	if is_blocking and not is_grapple:
		if defender.has_method("lock_guard_direction_for_frames"):
			defender.call("lock_guard_direction_for_frames", attacker, int(hit_data.get("guard_lock_frames", 10)))
		var block_pause_attacker: int = int(hit_data.get("block_pause_attacker", 7))
		var block_pause_defender: int = int(hit_data.get("block_pause_defender", 9))
		var guard_pause_pair: Array[int] = _read_pause_pair(hit_data.get("guard_pausetime", hit_data.get("guard.pausetime", null)), block_pause_attacker, block_pause_defender)
		block_pause_attacker = guard_pause_pair[0]
		block_pause_defender = guard_pause_pair[1]
		if smash_mode_enabled:
			block_pause_attacker = int(hit_data.get("smash_block_pause_attacker", 1))
			block_pause_defender = int(hit_data.get("smash_block_pause_defender", 2))
		_apply_hitpause(attacker, defender, block_pause_attacker, block_pause_defender)
		var chip_damage: int = int(hit_data.get("chip_damage", 0))
		var current_hp_block: int = int(defender.get("health"))
		if smash_mode_enabled:
			if chip_damage > 0 and defender.has_method("add_smash_percent"):
				defender.call("add_smash_percent", float(chip_damage))
		else:
			defender.call("set_health", maxi(0, current_hp_block - chip_damage))
		if defender.has_method("add_resource"):
			defender.call("add_resource", int(hit_data.get("guard_meter_gain", 8)))
		var blockstun_state: String = str(hit_data.get("blockstun_state", "guard"))
		var blockstun_frames: int = int(hit_data.get("blockstun_frames", 0))
		var block_recover_state: String = str(hit_data.get("block_recover_state", "idle"))
		if blockstun_frames > 0 and defender.has_method("enter_timed_state"):
			defender.call("enter_timed_state", blockstun_state, blockstun_frames, block_recover_state)
		elif defender.has_method("enter_hitstun"):
			if not blockstun_state.is_empty():
				defender.call("enter_hitstun", blockstun_state)
		combat_event.emit("block", attacker, defender, hit_data)
		return

	_apply_damage_resolution(attacker, defender, hit_data, is_grapple)
	if defender.has_method("get") and defender.get("grapple_target") == attacker and defender.has_method("on_hit_by_grapple_target"):
		defender.call("on_hit_by_grapple_target", attacker, hit_data)


func apply_grapple_release(attacker: Node, defender: Node, hit_data: Dictionary) -> void:
	if attacker == null or defender == null:
		return
	if not defender.has_method("set_health"):
		return
	_apply_damage_resolution(attacker, defender, hit_data, true)


func set_smash_mode_enabled(enabled: bool) -> void:
	smash_mode_enabled = enabled


func get_combo_hits(attacker: Node, defender: Node) -> int:
	if attacker == null or defender == null:
		return 0
	var combo_key: String = "%s->%s" % [attacker.get_instance_id(), defender.get_instance_id()]
	var data: Dictionary = combo_tracker.get(combo_key, {"hits": 0, "damage": 0})
	return int(data.get("hits", 0))


func add_combo_hits(attacker: Node, defender: Node, add_count: int) -> void:
	if attacker == null or defender == null or add_count <= 0:
		return
	var combo_key: String = "%s->%s" % [attacker.get_instance_id(), defender.get_instance_id()]
	var data: Dictionary = combo_tracker.get(combo_key, {"hits": 0, "damage": 0})
	data["hits"] = int(data["hits"]) + maxi(0, add_count)
	combo_tracker[combo_key] = data
	combo_event.emit(attacker, defender, data["hits"], data["damage"])


func _apply_damage_resolution(attacker: Node, defender: Node, hit_data: Dictionary, is_grapple: bool) -> void:
	var damage: int = int(hit_data.get("damage", 0))
	var attack_mul_val: float = 1.0
	if attacker.has_method("get_effective_attack_mul"):
		attack_mul_val = attacker.call("get_effective_attack_mul")
	elif attacker.has_method("get") and attacker.get("attack_mul") != null:
		attack_mul_val = float(attacker.get("attack_mul"))
	damage = int(roundf(float(damage) * attack_mul_val))
	var defence_mul_val: float = 1.0
	if defender.has_method("get_effective_defence_mul"):
		defence_mul_val = defender.call("get_effective_defence_mul")
	elif defender.has_method("get") and defender.get("defence_mul") != null:
		defence_mul_val = float(defender.get("defence_mul"))
	damage = int(roundf(float(damage) * defence_mul_val))
	var pushback: Vector3 = _to_vector3(hit_data.get("pushback", Vector3.ZERO))
	var launch_velocity: Vector3 = _to_vector3(hit_data.get("launch_velocity", Vector3.ZERO))
	pushback = _orient_knockback_from_attacker(attacker, defender, pushback)
	launch_velocity = _orient_knockback_from_attacker(attacker, defender, launch_velocity)
	var hitstun_state: String = str(hit_data.get("hitstun_state", "hitstun"))
	if is_grapple:
		hitstun_state = str(hit_data.get("grapple_state", hitstun_state))

	# Air followups consume juggle points. Grounded launchers can opt-in with force_juggle.
	var juggle_cost: int = int(hit_data.get("juggle_cost", 1))
	var force_juggle: bool = bool(hit_data.get("force_juggle", false))
	var defender_grounded: bool = defender.has_method("is_grounded_for_juggle") and bool(defender.call("is_grounded_for_juggle"))
	var skip_juggle: bool = defender.get("assert_special_nojugglecheck") == true
	if not is_grapple and not skip_juggle and (force_juggle or not defender_grounded):
		if defender.has_method("can_take_juggle_hit"):
			if not bool(defender.call("can_take_juggle_hit", juggle_cost)):
				return
		if defender.has_method("register_juggle_hit"):
			defender.call("register_juggle_hit", juggle_cost)

	var smash_percent_damage: float = float(damage)
	if smash_mode_enabled and (hit_data.has("smash_percent") or hit_data.has("smash_damage")):
		var sp: Variant = hit_data.get("smash_percent", hit_data.get("smash_damage", damage))
		smash_percent_damage = float(sp)
	var knockback_scale: float = 1.0
	if smash_mode_enabled and defender.has_method("get_smash_knockback_multiplier"):
		knockback_scale = maxf(1.0, float(defender.call("get_smash_knockback_multiplier")))
	if smash_mode_enabled:
		knockback_scale *= 1.0 + (smash_percent_damage * 0.01)
	pushback *= knockback_scale
	launch_velocity *= knockback_scale

	var current_health: int = int(defender.get("health"))
	var new_health: int = current_health
	if smash_mode_enabled:
		if defender.has_method("add_smash_percent"):
			defender.call("add_smash_percent", smash_percent_damage)
	else:
		new_health = maxi(0, current_health - damage)
	var hit_pause_attacker: int = int(hit_data.get("hit_pause_attacker", 9))
	var hit_pause_defender: int = int(hit_data.get("hit_pause_defender", 11))
	var hit_pause_pair: Array[int] = _read_pause_pair(hit_data.get("pausetime", null), hit_pause_attacker, hit_pause_defender)
	hit_pause_attacker = hit_pause_pair[0]
	hit_pause_defender = hit_pause_pair[1]
	if smash_mode_enabled:
		hit_pause_attacker = int(hit_data.get("smash_hit_pause_attacker", 2))
		hit_pause_defender = int(hit_data.get("smash_hit_pause_defender", 3))
	_apply_hitpause(attacker, defender, hit_pause_attacker, hit_pause_defender)
	defender.call("set_health", new_health)
	var actual_damage: int = current_health - new_health
	if actual_damage > 0:
		damage_dealt.emit(attacker, defender, actual_damage)
	if new_health <= 0:
		# KO should remain in KO state, not be overwritten by hitstun.
		if attacker.has_method("add_resource"):
			attacker.call("add_resource", int(hit_data.get("meter_gain_on_hit", 10)))
		if defender.has_method("add_resource"):
			defender.call("add_resource", int(hit_data.get("meter_gain_on_taken", 5)))
		var ko_combo_key: String = "%s->%s" % [attacker.get_instance_id(), defender.get_instance_id()]
		var ko_data: Dictionary = combo_tracker.get(ko_combo_key, {"hits": 0, "damage": 0})
		ko_data["hits"] = int(ko_data["hits"]) + 1
		ko_data["damage"] = int(ko_data["damage"]) + damage
		combo_tracker[ko_combo_key] = ko_data
		combo_event.emit(attacker, defender, ko_data["hits"], ko_data["damage"])
		combat_event.emit("ko", attacker, defender, hit_data)
		return
	var override_state: String = ""
	if defender.has_method("get_hit_override_state"):
		override_state = str(defender.call("get_hit_override_state", hit_data)).strip_edges()
	if not override_state.is_empty():
		var sc = defender.get("state_controller")
		if sc != null and sc.has_method("change_state"):
			sc.call("change_state", override_state)
	elif not smash_mode_enabled:
		var causes_knockdown: bool = bool(hit_data.get("knockdown", false))
		if not causes_knockdown and launch_velocity.y > float(hit_data.get("knockdown_launch_threshold", 5.5)):
			causes_knockdown = true
		if causes_knockdown and defender.has_method("enter_knockdown"):
			defender.call("enter_knockdown", hit_data)
		else:
			var hitstun_frames: int = int(hit_data.get("hitstun_frames", 0))
			var hit_recover_state: String = str(hit_data.get("hit_recover_state", "idle"))
			if hitstun_frames > 0 and defender.has_method("enter_timed_state"):
				defender.call("enter_timed_state", hitstun_state, hitstun_frames, hit_recover_state)
			else:
				defender.call("enter_hitstun", hitstun_state)
	elif defender.has_method("enter_timed_state"):
		var smash_dmg_for_stun: float = float(damage)
		if hit_data.has("smash_percent") or hit_data.has("smash_damage"):
			smash_dmg_for_stun = float(hit_data.get("smash_percent", hit_data.get("smash_damage", damage)))
		var smash_hitstun_frames: int = int(hit_data.get("smash_hitstun_frames", maxi(4, mini(18, int(round(smash_dmg_for_stun * 0.35) + 4)))))
		defender.call("enter_timed_state", hitstun_state, smash_hitstun_frames, "idle")
	defender.call("apply_pushback", pushback)
	if launch_velocity.length_squared() > 0.0001 and defender.has_method("apply_launch_velocity"):
		defender.call("apply_launch_velocity", launch_velocity)
	if attacker.has_method("add_resource"):
		attacker.call("add_resource", int(hit_data.get("meter_gain_on_hit", 10)))
	if defender.has_method("add_resource"):
		defender.call("add_resource", int(hit_data.get("meter_gain_on_taken", 5)))
	combat_event.emit("throw_hit" if is_grapple else "hit", attacker, defender, hit_data)

	_apply_hit_status_effects(attacker, defender, hit_data)

	var combo_key: String = "%s->%s" % [attacker.get_instance_id(), defender.get_instance_id()]
	var data: Dictionary = combo_tracker.get(combo_key, {"hits": 0, "damage": 0})
	data["hits"] = int(data["hits"]) + 1
	data["damage"] = int(data["damage"]) + damage
	combo_tracker[combo_key] = data
	combo_event.emit(attacker, defender, data["hits"], data["damage"])


func _apply_hit_status_effects(attacker: Node, defender: Node, hit_data: Dictionary) -> void:
	if defender == null or not defender.has_method("apply_status_effect"):
		return
	var single: Variant = hit_data.get("status_effect", null)
	if single != null and single is Dictionary:
		defender.call("apply_status_effect", single, attacker)
	var list: Variant = hit_data.get("status_effects", null)
	if list != null and list is Array:
		for entry in list:
			if entry is Dictionary:
				defender.call("apply_status_effect", entry, attacker)


func _apply_hitpause(attacker: Node, defender: Node, attacker_frames: int, defender_frames: int) -> void:
	if attacker != null and attacker.has_method("apply_hitpause"):
		attacker.call("apply_hitpause", maxi(0, attacker_frames))
	if defender != null and defender.has_method("apply_hitpause"):
		defender.call("apply_hitpause", maxi(0, defender_frames))


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


func _orient_knockback_from_attacker(attacker: Node, defender: Node, value: Vector3) -> Vector3:
	if value.x == 0.0:
		return value
	if not (attacker is Node3D) or not (defender is Node3D):
		return value
	var out: Vector3 = value
	var attacker_pos: Vector3 = (attacker as Node3D).global_position
	var defender_pos: Vector3 = (defender as Node3D).global_position
	var away_sign: float = 1.0 if defender_pos.x >= attacker_pos.x else -1.0
	out.x = absf(value.x) * away_sign
	return out


func _read_pause_pair(value, default_attacker: int, default_defender: int) -> Array[int]:
	var attacker_frames: int = default_attacker
	var defender_frames: int = default_defender
	if value is Array:
		var arr: Array = value
		if arr.size() >= 1:
			attacker_frames = int(arr[0])
		if arr.size() >= 2:
			defender_frames = int(arr[1])
	elif value is String:
		var parts: PackedStringArray = (value as String).split(",", false)
		if parts.size() >= 1:
			attacker_frames = int(parts[0].strip_edges().to_int())
		if parts.size() >= 2:
			defender_frames = int(parts[1].strip_edges().to_int())
	elif value is Dictionary:
		var dict_value: Dictionary = value
		attacker_frames = int(dict_value.get("attacker", attacker_frames))
		defender_frames = int(dict_value.get("defender", defender_frames))
	return [maxi(0, attacker_frames), maxi(0, defender_frames)]
