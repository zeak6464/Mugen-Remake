extends Node
class_name StateController

signal state_changed(new_state: String)
signal state_frame_advanced(state_id: String, frame_in_state: int)

var states_data: Dictionary = {}
var current_state: String = ""
var previous_state: String = ""
var frame_in_state: int = 0
var fighter: Node = null
var state_change_serial: int = 0
var controller_last_exec_tick: Dictionary = {}
var controller_once_serial: Dictionary = {}
var int_vars: Array[int] = []
var float_vars: Array[float] = []

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"


func set_fighter(p_fighter: Node) -> void:
	fighter = p_fighter
	_ensure_controller_vars()


func _ensure_controller_vars() -> void:
	if int_vars.is_empty():
		int_vars.resize(60)
		for i in range(int_vars.size()):
			int_vars[i] = 0
	if float_vars.is_empty():
		float_vars.resize(40)
		for i in range(float_vars.size()):
			float_vars[i] = 0.0


func set_states_data(data: Dictionary) -> void:
	states_data = data.duplicate(true)


func load_states_from_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	set_states_data(parsed)
	return true


func change_state(id: String) -> void:
	if not states_data.has(id):
		return
	previous_state = current_state
	current_state = id
	frame_in_state = 0
	state_change_serial += 1
	_apply_state_enter_data(states_data[id])
	state_changed.emit(current_state)


func step_physics(_delta: float) -> void:
	_ensure_controller_vars()
	if current_state.is_empty():
		return
	var state_data: Dictionary = states_data.get(current_state, {})
	var in_hitpause: bool = fighter != null and fighter.has_method("is_in_hitpause") and bool(fighter.call("is_in_hitpause"))
	if in_hitpause:
		if not _state_has_ignore_hitpause_controllers(state_data):
			return
		_apply_state_frame_data(state_data, true)
		state_frame_advanced.emit(current_state, frame_in_state)
		return
	frame_in_state += 1
	_apply_state_frame_data(state_data, false)
	state_frame_advanced.emit(current_state, frame_in_state)




func get_current_state_data() -> Dictionary:
	return states_data.get(current_state, {})


func _apply_state_enter_data(state_data: Dictionary) -> void:
	var animation_name: String = str(state_data.get("animation", ""))
	var should_loop: bool = bool(state_data.get("animation_loop", true))
	if not animation_name.is_empty():
		var played := false
		if fighter != null and fighter.has_method("play_state_animation"):
			played = bool(fighter.call("play_state_animation", animation_name, should_loop))
		if not played and animation_player != null:
			var anim: Animation = animation_player.get_animation(animation_name)
			if anim != null:
				anim.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
				animation_player.play(animation_name)
	if fighter != null:
		if fighter.has_method("clear_runtime_state_overrides"):
			fighter.call("clear_runtime_state_overrides")
		if state_data.has("velocity"):
			var velocity_data = state_data.get("velocity", Vector3.ZERO)
			fighter.call("apply_state_velocity", velocity_data)
		if fighter.has_method("set_state_control_enabled"):
			if state_data.has("ctrl"):
				fighter.call("set_state_control_enabled", bool(state_data.get("ctrl", false)))
			elif state_data.has("allow_movement"):
				fighter.call("set_state_control_enabled", bool(state_data.get("allow_movement", true)))
		var sound_timeline: Array = state_data.get("sounds", [])
		fighter.call("play_state_sounds_for_frame", sound_timeline, 0)
		var projectile_timeline: Array = state_data.get("projectiles", [])
		fighter.call("spawn_projectiles_for_frame", projectile_timeline, 0)


func _apply_state_frame_data(state_data: Dictionary, in_hitpause: bool) -> void:
	if fighter == null:
		return

	if not in_hitpause:
		var hitbox_timeline: Array = state_data.get("hitboxes", [])
		fighter.call("update_hitboxes_for_state_frame", hitbox_timeline, frame_in_state)
		var throwbox_timeline: Array = state_data.get("throwboxes", [])
		fighter.call("update_throwboxes_for_state_frame", throwbox_timeline, frame_in_state)
		var hurtbox_timeline: Array = state_data.get("hurtboxes", [])
		fighter.call("update_hurtboxes_for_state_frame", hurtbox_timeline, frame_in_state)
		var sound_timeline: Array = state_data.get("sounds", [])
		fighter.call("play_state_sounds_for_frame", sound_timeline, frame_in_state)
		var projectile_timeline: Array = state_data.get("projectiles", [])
		fighter.call("spawn_projectiles_for_frame", projectile_timeline, frame_in_state)
	_apply_state_controllers(state_data, in_hitpause)

	# Timed/knockdown recovery should control when these states end.
	# If we also run per-state "next" transitions, states can appear to skip/flip early.
	var timed_active: bool = fighter.has_method("get") and int(fighter.get("timed_state_frames_remaining")) > 0
	var knockdown_active: bool = fighter.has_method("get") and int(fighter.get("knockdown_frames_remaining")) > 0
	if timed_active or knockdown_active:
		return

	var next_data = state_data.get("next", null)
	if typeof(next_data) == TYPE_DICTIONARY:
		var next_frame: int = int(next_data.get("frame", -1))
		var next_id: String = str(next_data.get("id", ""))
		if next_frame >= 0 and frame_in_state >= next_frame and not next_id.is_empty():
			if fighter != null and fighter.has_method("sync_position_to_animation_root"):
				fighter.sync_position_to_animation_root()
			change_state(next_id)


func _state_has_ignore_hitpause_controllers(state_data: Dictionary) -> bool:
	var controllers = state_data.get("controllers", [])
	if typeof(controllers) != TYPE_ARRAY:
		return false
	for entry in controllers:
		if typeof(entry) == TYPE_DICTIONARY and bool((entry as Dictionary).get("ignorehitpause", false)):
			return true
	return false


func _apply_state_controllers(state_data: Dictionary, in_hitpause: bool) -> void:
	var controllers = state_data.get("controllers", [])
	if typeof(controllers) != TYPE_ARRAY:
		return
	var controllers_array: Array = controllers
	for idx in range(controllers_array.size()):
		var serial_before: int = state_change_serial
		var entry = controllers_array[idx]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var controller: Dictionary = entry
		if in_hitpause and not bool(controller.get("ignorehitpause", false)):
			continue
		if not _controller_triggers_pass(controller):
			continue
		if not _can_execute_controller(controller, idx):
			continue
		_execute_state_controller(controller)
		if state_change_serial != serial_before:
			return


func _can_execute_controller(controller: Dictionary, idx: int) -> bool:
	var key: String = _controller_key(idx)
	var persistent: int = int(controller.get("persistent", 1))
	var tick_now: int = int(Engine.get_physics_frames())
	if persistent == 0:
		if int(controller_once_serial.get(key, -1)) == state_change_serial:
			return false
		controller_once_serial[key] = state_change_serial
		return true
	if persistent <= 1:
		controller_last_exec_tick[key] = tick_now
		return true
	var last_tick: int = int(controller_last_exec_tick.get(key, -999999))
	if tick_now - last_tick < persistent:
		return false
	controller_last_exec_tick[key] = tick_now
	return true


func _controller_key(idx: int) -> String:
	return "%d:%s:%d" % [state_change_serial, current_state, idx]


func _controller_triggers_pass(controller: Dictionary) -> bool:
	var has_trigger: bool = false
	if controller.has("triggerall"):
		has_trigger = true
		if not _evaluate_trigger_entry(controller.get("triggerall", false)):
			return false

	var any_trigger_passed: bool = false
	for raw_key in controller.keys():
		var key: String = str(raw_key).to_lower()
		if key == "triggerall":
			continue
		if not key.begins_with("trigger"):
			continue
		has_trigger = true
		if _evaluate_trigger_entry(controller.get(raw_key, false)):
			any_trigger_passed = true
	if not has_trigger:
		return true
	return any_trigger_passed or not _has_numbered_triggers(controller)


func _has_numbered_triggers(controller: Dictionary) -> bool:
	for raw_key in controller.keys():
		var key: String = str(raw_key).to_lower()
		if key.begins_with("trigger") and key != "triggerall":
			return true
	return false


func _evaluate_trigger_entry(entry) -> bool:
	if entry is Array:
		var arr: Array = entry
		for atom in arr:
			if not _evaluate_trigger_atom(atom):
				return false
		return true
	return _evaluate_trigger_atom(entry)


func _evaluate_trigger_atom(atom) -> bool:
	match typeof(atom):
		TYPE_BOOL:
			return bool(atom)
		TYPE_INT:
			return int(atom) != 0
		TYPE_FLOAT:
			return absf(float(atom)) > 0.00001
		TYPE_STRING:
			return _evaluate_trigger_string(str(atom))
		TYPE_DICTIONARY:
			return _evaluate_trigger_dictionary(atom as Dictionary)
	return false


func _evaluate_trigger_dictionary(data: Dictionary) -> bool:
	var lhs_name: String = str(data.get("lhs", data.get("left", ""))).strip_edges()
	var rhs_value = data.get("rhs", data.get("right", true))
	var op: String = str(data.get("op", data.get("operator", "=="))).strip_edges()
	if lhs_name.is_empty():
		return false
	var special_result = _evaluate_special_trigger(lhs_name, rhs_value, op)
	if special_result != null:
		return bool(special_result)
	var lhs_value = _trigger_value_for_token(lhs_name)
	return _compare_trigger_values(lhs_value, rhs_value, op)


func _evaluate_trigger_string(expression: String) -> bool:
	var expr: String = expression.strip_edges()
	if expr.is_empty():
		return false
	if expr.find("||") != -1:
		var any_true: bool = false
		for part in expr.split("||", false):
			if _evaluate_trigger_string(str(part)):
				any_true = true
				break
		return any_true
	if expr.find("&&") != -1:
		for part in expr.split("&&", false):
			if not _evaluate_trigger_string(str(part)):
				return false
		return true
	if expr.begins_with("!"):
		return not _evaluate_trigger_string(expr.substr(1))
	for op in ["!=", ">=", "<=", "==", "=", ">", "<"]:
		var idx: int = expr.find(op)
		if idx == -1:
			continue
		var lhs_name: String = expr.substr(0, idx).strip_edges()
		var rhs_raw: String = expr.substr(idx + op.length()).strip_edges()
		if lhs_name.is_empty():
			return false
		var rhs_value = _parse_trigger_value(rhs_raw)
		var special_result = _evaluate_special_trigger(lhs_name, rhs_value, op)
		if special_result != null:
			return bool(special_result)
		var lhs_value = _trigger_value_for_token(lhs_name)
		return _compare_trigger_values(lhs_value, rhs_value, op)
	var value = _trigger_value_for_token(expr)
	return _truthy_trigger_value(value)


func _evaluate_special_trigger(lhs_name: String, rhs_value, op: String):
	var lhs_token: String = lhs_name.strip_edges().to_lower()
	var normalized_op: String = "==" if op == "=" else op
	if lhs_token == "command":
		if normalized_op != "==" and normalized_op != "!=":
			return false
		var expected_command: String = str(rhs_value)
		var matched: bool = _was_command_matched_recently(expected_command)
		return matched if normalized_op == "==" else not matched
	return null


func _parse_trigger_value(raw: String):
	var token: String = raw.strip_edges()
	if token.length() >= 2:
		if (token.begins_with("\"") and token.ends_with("\"")) or (token.begins_with("'") and token.ends_with("'")):
			return token.substr(1, token.length() - 2)
	var lowered: String = token.to_lower()
	if lowered == "true":
		return true
	if lowered == "false":
		return false
	if lowered == "null" or lowered == "none":
		return null
	if token.is_valid_int():
		return int(token)
	if token.is_valid_float():
		return float(token)
	return _trigger_value_for_token(token)


func _trigger_value_for_token(token_raw: String):
	var token: String = token_raw.strip_edges().to_lower()
	var var_index: int = _parse_indexed_token(token, "var")
	if var_index >= 0:
		return _read_int_var(var_index)
	var fvar_index: int = _parse_indexed_token(token, "fvar")
	if fvar_index >= 0:
		return _read_float_var(fvar_index)
	match token:
		"time":
			return frame_in_state
		"statetime":
			return frame_in_state
		"ctrl":
			if fighter != null:
				return bool(fighter.get("state_control_enabled"))
			return false
		"statetype":
			if fighter != null and fighter.has_method("get_runtime_statetype"):
				return str(fighter.call("get_runtime_statetype"))
			return "S"
		"movetype":
			if fighter != null and fighter.has_method("get_runtime_movetype"):
				return str(fighter.call("get_runtime_movetype"))
			return "I"
		"physics":
			if fighter != null and fighter.has_method("get_runtime_physics"):
				return str(fighter.call("get_runtime_physics"))
			return "S"
		"anim":
			if fighter != null and fighter.has_method("get_current_animation_name"):
				return str(fighter.call("get_current_animation_name"))
			return ""
		"animtime":
			if fighter != null and fighter.has_method("get_current_animation_time_left_frames"):
				return int(fighter.call("get_current_animation_time_left_frames"))
			return 0
		"stateno":
			var cs: String = String(current_state)
			if cs.is_valid_int():
				return int(cs)
			return current_state
		"prevstateno":
			var ps: String = String(previous_state)
			if ps.is_valid_int():
				return int(ps)
			return previous_state
		"hitpause":
			if fighter != null and fighter.has_method("is_in_hitpause"):
				return bool(fighter.call("is_in_hitpause"))
			return false
		"movehit":
			return _recent_attack_result_matches("hit")
		"moveguarded":
			return _recent_attack_result_matches("block")
		"movecontact":
			return _recent_attack_result_matches("hit") or _recent_attack_result_matches("block")
		"life":
			if fighter != null:
				return int(fighter.get("health"))
			return 0
		"p2life":
			return _opponent_health()
		"numtarget":
			return 1 if _opponent_node() != null and _opponent_health() > 0 else 0
		"power":
			if fighter != null:
				return int(fighter.get("resource"))
			return 0
		"numproj":
			if fighter != null and fighter.has_method("get_num_projectiles"):
				return int(fighter.call("get_num_projectiles"))
			return 0
		"p2power":
			return _opponent_power()
		"alive":
			if fighter != null:
				return int(fighter.get("health")) > 0
			return false
		"p2alive":
			return _opponent_health() > 0
		"velx", "vel.x", "vel x":
			return _fighter_velocity_component("x")
		"vely", "vel.y", "vel y":
			return _fighter_velocity_component("y")
		"velz", "vel.z", "vel z":
			return _fighter_velocity_component("z")
		"posx", "pos.x", "pos x":
			return _fighter_position_component("x")
		"posy", "pos.y", "pos y":
			return _fighter_position_component("y")
		"posz", "pos.z", "pos z":
			return _fighter_position_component("z")
		"p2distx", "p2dist.x", "p2dist x":
			return _fighter_opponent_distance_component("x")
		"p2disty", "p2dist.y", "p2dist y":
			return _fighter_opponent_distance_component("y")
		"p2stateno":
			return _opponent_state_no()
		"p2statetype":
			return _opponent_state_type()
		"p2movetype":
			return _opponent_move_type()
		"facing":
			return _fighter_facing_value()
		"random":
			return int(randi() % 1000)
		"combocount", "hitadd":
			if fighter != null and fighter.has_method("get_combo_hits"):
				var opp = fighter.get("opponent")
				if opp != null and is_instance_valid(opp):
					var ds = fighter.get("damage_system")
					if ds != null and ds.has_method("get_combo_hits"):
						return ds.call("get_combo_hits", fighter, opp)
			return 0
	return token_raw


func _parse_indexed_token(token: String, prefix: String) -> int:
	var expected_prefix: String = "%s(" % prefix
	if not token.begins_with(expected_prefix) or not token.ends_with(")"):
		return -1
	var inner: String = token.substr(expected_prefix.length(), token.length() - expected_prefix.length() - 1).strip_edges()
	if not inner.is_valid_int():
		return -1
	return int(inner)


func _read_int_var(index: int) -> int:
	_ensure_controller_vars()
	if index < 0 or index >= int_vars.size():
		return 0
	return int_vars[index]


func _read_float_var(index: int) -> float:
	_ensure_controller_vars()
	if index < 0 or index >= float_vars.size():
		return 0.0
	return float_vars[index]


func _recent_attack_result_matches(result_id: String, window_frames: int = 20) -> bool:
	if fighter == null:
		return false
	var last_result: String = str(fighter.get("last_attack_result")).to_lower()
	var last_frame: int = int(fighter.get("last_attack_result_frame"))
	if last_result != result_id:
		return false
	return int(Engine.get_physics_frames()) - last_frame <= maxi(1, window_frames)


func _was_command_matched_recently(command_id: String, window_frames: int = 8) -> bool:
	if fighter == null:
		return false
	var interpreter = fighter.get("command_interpreter")
	if interpreter == null:
		return false
	if not interpreter.has_method("get_last_matched_command_id"):
		return false
	if not interpreter.has_method("get_last_matched_command_frame"):
		return false
	var last_id: String = str(interpreter.call("get_last_matched_command_id"))
	var last_frame: int = int(interpreter.call("get_last_matched_command_frame"))
	if last_id != command_id:
		return false
	return int(Engine.get_physics_frames()) - last_frame <= maxi(1, window_frames)


func _fighter_velocity_component(axis: String) -> float:
	if fighter == null:
		return 0.0
	var vel = fighter.get("velocity")
	if vel is Vector3:
		match axis:
			"x":
				return (vel as Vector3).x
			"y":
				return (vel as Vector3).y
			"z":
				return (vel as Vector3).z
	return 0.0


func _fighter_position_component(axis: String) -> float:
	if fighter == null or not (fighter is Node3D):
		return 0.0
	var pos: Vector3 = (fighter as Node3D).global_position
	match axis:
		"x":
			return pos.x
		"y":
			return pos.y
		"z":
			return pos.z
	return 0.0


func _fighter_opponent_distance_component(axis: String) -> float:
	if fighter == null or not (fighter is Node3D):
		return 0.0
	var opponent = fighter.get("opponent")
	if opponent == null or not (opponent is Node3D):
		return 0.0
	var self_pos: Vector3 = (fighter as Node3D).global_position
	var opp_pos: Vector3 = (opponent as Node3D).global_position
	var delta: Vector3 = opp_pos - self_pos
	match axis:
		"x":
			return delta.x
		"y":
			return delta.y
		"z":
			return delta.z
	return 0.0


func _fighter_facing_value() -> int:
	if fighter == null:
		return 1
	var interpreter = fighter.get("command_interpreter")
	if interpreter != null and interpreter.has_method("get_facing_right"):
		return 1 if bool(interpreter.call("get_facing_right")) else -1
	return 1


func _opponent_node() -> Node:
	if fighter == null:
		return null
	return fighter.get("opponent")


func _opponent_health() -> int:
	var opp: Node = _opponent_node()
	if opp == null:
		return 0
	return int(opp.get("health"))


func _opponent_power() -> int:
	var opp: Node = _opponent_node()
	if opp == null:
		return 0
	return int(opp.get("resource"))


func _opponent_state_no():
	var opp: Node = _opponent_node()
	if opp == null:
		return ""
	var opp_state_controller = opp.get("state_controller")
	if opp_state_controller == null:
		return ""
	var opp_state = str(opp_state_controller.get("current_state"))
	if opp_state.is_valid_int():
		return int(opp_state)
	return opp_state


func _opponent_state_type() -> String:
	var opp: Node = _opponent_node()
	if opp != null and opp.has_method("get_runtime_statetype"):
		return str(opp.call("get_runtime_statetype"))
	return "S"


func _opponent_move_type() -> String:
	var opp: Node = _opponent_node()
	if opp != null and opp.has_method("get_runtime_movetype"):
		return str(opp.call("get_runtime_movetype"))
	return "I"


func _compare_trigger_values(lhs, rhs, op: String) -> bool:
	var normalized_op: String = "==" if op == "=" else op
	var lhs_numeric = _coerce_numeric_trigger_value(lhs)
	var rhs_numeric = _coerce_numeric_trigger_value(rhs)
	if lhs_numeric != null and rhs_numeric != null:
		var lf_num: float = float(lhs_numeric)
		var rf_num: float = float(rhs_numeric)
		match normalized_op:
			"==":
				return is_equal_approx(lf_num, rf_num)
			"!=":
				return not is_equal_approx(lf_num, rf_num)
			">":
				return lf_num > rf_num
			">=":
				return lf_num >= rf_num
			"<":
				return lf_num < rf_num
			"<=":
				return lf_num <= rf_num
		return false
	if lhs is String or rhs is String:
		if normalized_op == ">" or normalized_op == ">=" or normalized_op == "<" or normalized_op == "<=":
			return false
		var ls: String = str(lhs)
		var rs: String = str(rhs)
		match normalized_op:
			"==":
				return ls == rs
			"!=":
				return ls != rs
			">":
				return ls > rs
			">=":
				return ls >= rs
			"<":
				return ls < rs
			"<=":
				return ls <= rs
		return false

	var lf: float = float(lhs)
	var rf: float = float(rhs)
	match normalized_op:
		"==":
			return is_equal_approx(lf, rf)
		"!=":
			return not is_equal_approx(lf, rf)
		">":
			return lf > rf
		">=":
			return lf >= rf
		"<":
			return lf < rf
		"<=":
			return lf <= rf
	return false


func _coerce_numeric_trigger_value(value):
	match typeof(value):
		TYPE_INT, TYPE_FLOAT:
			return value
		TYPE_STRING:
			var s: String = String(value).strip_edges()
			if s.is_valid_int():
				return int(s)
			if s.is_valid_float():
				return float(s)
	return null


func _truthy_trigger_value(value) -> bool:
	match typeof(value):
		TYPE_NIL:
			return false
		TYPE_BOOL:
			return bool(value)
		TYPE_INT:
			return int(value) != 0
		TYPE_FLOAT:
			return absf(float(value)) > 0.00001
		TYPE_STRING:
			return not String(value).is_empty()
	return true


func _execute_state_controller(controller: Dictionary) -> void:
	var controller_type: String = str(controller.get("type", controller.get("controller", ""))).to_lower()
	match controller_type:
		"changestate":
			_execute_change_state_controller(controller)
		"selfstate":
			_execute_change_state_controller(controller)
		"ctrlset":
			_execute_ctrl_set_controller(controller)
		"null":
			pass
		"turn":
			_execute_turn_controller()
		"velset":
			_execute_velocity_controller(controller, "set")
		"veladd":
			_execute_velocity_controller(controller, "add")
		"velmul":
			_execute_velocity_controller(controller, "mul")
		"posset":
			_execute_position_controller(controller, "set")
		"posadd":
			_execute_position_controller(controller, "add")
		"poweradd":
			_execute_power_add_controller(controller)
		"powerset":
			_execute_power_set_controller(controller)
		"lifeadd":
			_execute_life_add_controller(controller)
		"lifeset":
			_execute_life_set_controller(controller)
		"playsnd":
			_execute_play_snd_controller(controller)
		"changeanim":
			_execute_change_anim_controller(controller)
		"changeanim2":
			_execute_change_anim2_controller(controller)
		"projectile":
			_execute_projectile_controller(controller)
		"targetstate":
			_execute_target_state_controller(controller)
		"targetlifeadd":
			_execute_target_life_add_controller(controller)
		"targetpoweradd":
			_execute_target_power_add_controller(controller)
		"targetvelset":
			_execute_target_velocity_controller(controller, "set")
		"targetveladd":
			_execute_target_velocity_controller(controller, "add")
		"targetposset":
			_execute_target_position_controller(controller, "set")
		"targetposadd":
			_execute_target_position_controller(controller, "add")
		"pause":
			_execute_pause_controller(controller)
		"nothitby":
			_execute_nothitby_controller(controller)
		"attackmulset":
			_execute_attack_mul_set_controller(controller)
		"defencemulset":
			_execute_defence_mul_set_controller(controller)
		"assertspecial":
			_execute_assert_special_controller(controller)
		"gravity":
			_execute_gravity_controller(controller)
		"targetfacing":
			_execute_target_facing_controller(controller)
		"screenbound":
			_execute_screen_bound_controller(controller)
		"stopsnd":
			_execute_stop_snd_controller(controller)
		"hitoverride":
			_execute_hit_override_controller(controller)
		"hitadd":
			_execute_hit_add_controller(controller)
		"hitfallvel":
			_execute_hitfallvel_controller(controller)
		"movehitreset":
			_execute_move_hit_reset_controller()
		"hitby":
			_execute_hitby_controller(controller)
		"posfreeze":
			_execute_pos_freeze_controller(controller)
		"trans":
			_execute_trans_controller(controller)
		"offset":
			_execute_offset_controller(controller)
		"playerpush":
			_execute_player_push_controller(controller)
		"varrandom":
			_execute_var_random_controller(controller)
		"varrangeset":
			_execute_var_range_set_controller(controller)
		"hitfallset":
			_execute_hitfallset_controller(controller)
		"hitfalldamage":
			_execute_hitfall_damage_controller(controller)
		"envshake":
			_execute_env_shake_controller(controller)
		"envcolor":
			_execute_env_color_controller(controller)
		"sndpan":
			_execute_snd_pan_controller(controller)
		"sprpriority":
			_execute_spr_priority_controller(controller)
		"bindtotarget":
			_execute_bind_to_target_controller(controller)
		"targetbind":
			_execute_target_bind_controller(controller)
		"superpause":
			_execute_super_pause_controller(controller)
		"reversaldef":
			_execute_reversal_def_controller(controller)
		"targetdrop":
			_execute_target_drop_controller(controller)
		"width":
			_execute_width_controller(controller)
		"victoryquote":
			_execute_victory_quote_controller(controller)
		"explod":
			_execute_explod_controller(controller)
		"removeexplod":
			_execute_remove_explod_controller(controller)
		"modifyexplod":
			_execute_modify_explod_controller(controller)
		"afterimage":
			_execute_after_image_controller(controller)
		"afterimagetime":
			_execute_after_image_time_controller(controller)
		"palfx":
			_execute_pal_fx_controller(controller)
		"angleset":
			_execute_angle_set_controller(controller)
		"angleadd":
			_execute_angle_add_controller(controller)
		"attackdist":
			_execute_attack_dist_controller(controller)
		"fallenvshake":
			_execute_fall_env_shake_controller(controller)
		"forcefeedback":
			_execute_force_feedback_controller(controller)
		"displaytoclipboard":
			_execute_display_to_clipboard_controller(controller)
		"clearclipboard":
			_execute_clear_clipboard_controller(controller)
		"appendtoclipboard":
			_execute_append_to_clipboard_controller(controller)
		"helper":
			_execute_helper_controller(controller)
		"parentvarset":
			_execute_parent_var_set_controller(controller)
		"parentvaradd":
			_execute_parent_var_add_controller(controller)
		"bindtoroot":
			_execute_bind_to_root_controller(controller)
		"bindtoparent":
			_execute_bind_to_parent_controller(controller)
		"destroyself":
			_execute_destroy_self_controller(controller)
		"statetypeset":
			_execute_state_type_set_controller(controller)
		"varset":
			_execute_var_set_controller(controller)
		"varadd":
			_execute_var_add_controller(controller)
		"fvarset":
			_execute_fvar_set_controller(controller)
		"fvaradd":
			_execute_fvar_add_controller(controller)


func _execute_change_state_controller(controller: Dictionary) -> void:
	var next_state_id: String = str(controller.get("value", controller.get("state", controller.get("state_id", ""))))
	if not next_state_id.is_empty():
		change_state(next_state_id)
	if fighter == null:
		return
	if controller.has("ctrl") and fighter.has_method("set_state_control_enabled"):
		fighter.call("set_state_control_enabled", bool(controller.get("ctrl", false)))
	var anim_name: String = str(controller.get("anim", ""))
	if not anim_name.is_empty() and fighter.has_method("play_state_animation"):
		var should_loop: bool = bool(controller.get("animation_loop", true))
		fighter.call("play_state_animation", anim_name, should_loop)


func _execute_ctrl_set_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("set_state_control_enabled"):
		return
	var ctrl_value: bool = bool(controller.get("value", controller.get("ctrl", false)))
	fighter.call("set_state_control_enabled", ctrl_value)


func _execute_velocity_controller(controller: Dictionary, mode: String) -> void:
	if fighter == null:
		return
	var params: Dictionary = _velocity_params_from_controller(controller)
	match mode:
		"set":
			if fighter.has_method("controller_vel_set"):
				fighter.call("controller_vel_set", params)
		"add":
			if fighter.has_method("controller_vel_add"):
				fighter.call("controller_vel_add", params)
		"mul":
			if fighter.has_method("controller_vel_mul"):
				fighter.call("controller_vel_mul", params)


func _execute_position_controller(controller: Dictionary, mode: String) -> void:
	if fighter == null:
		return
	var params: Dictionary = _position_params_from_controller(controller)
	match mode:
		"set":
			if fighter.has_method("controller_pos_set"):
				fighter.call("controller_pos_set", params)
		"add":
			if fighter.has_method("controller_pos_add"):
				fighter.call("controller_pos_add", params)


func _execute_turn_controller() -> void:
	if fighter == null or not fighter.has_method("controller_turn"):
		return
	fighter.call("controller_turn")


func _execute_power_add_controller(controller: Dictionary) -> void:
	if fighter == null:
		return
	if not fighter.has_method("add_resource"):
		return
	var value: int = int(controller.get("value", 0))
	if controller.has("amount"):
		value = int(controller.get("amount", value))
	if value != 0:
		fighter.call("add_resource", value)


func _execute_power_set_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_power_set"):
		return
	var value: int = int(controller.get("value", 0))
	if controller.has("amount"):
		value = int(controller.get("amount", value))
	fighter.call("controller_power_set", value)


func _execute_life_add_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_life_add"):
		return
	var value: int = int(controller.get("value", 0))
	if controller.has("amount"):
		value = int(controller.get("amount", value))
	var can_kill: bool = bool(controller.get("kill", true))
	fighter.call("controller_life_add", value, can_kill)


func _execute_life_set_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_life_set"):
		return
	var value: int = int(controller.get("value", 0))
	if controller.has("amount"):
		value = int(controller.get("amount", value))
	fighter.call("controller_life_set", value)


func _execute_play_snd_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("play_character_sound"):
		return
	var sound_id: String = str(controller.get("id", controller.get("value", "")))
	if sound_id.is_empty():
		return
	var channel: String = str(controller.get("channel", "sfx"))
	fighter.call("play_character_sound", sound_id, channel)


func _execute_change_anim_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("play_state_animation"):
		return
	var anim_name: String = str(controller.get("value", controller.get("anim", controller.get("id", ""))))
	if anim_name.is_empty():
		return
	var should_loop: bool = bool(controller.get("animation_loop", controller.get("loop", true)))
	fighter.call("play_state_animation", anim_name, should_loop)


func _execute_projectile_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_spawn_projectile"):
		return
	var projectile_id: String = str(controller.get("id", controller.get("value", "")))
	if projectile_id.is_empty():
		return
	fighter.call("controller_spawn_projectile", projectile_id)


func _execute_target_state_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_target_state"):
		return
	var next_state_id: String = str(controller.get("value", controller.get("state", controller.get("state_id", ""))))
	if next_state_id.is_empty():
		return
	var ctrl_value = controller.get("ctrl", null)
	fighter.call("controller_target_state", next_state_id, ctrl_value)


func _execute_target_life_add_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_target_life_add"):
		return
	var value: int = int(controller.get("value", controller.get("amount", 0)))
	var can_kill: bool = bool(controller.get("kill", true))
	fighter.call("controller_target_life_add", value, can_kill)


func _execute_target_power_add_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_target_power_add"):
		return
	var value: int = int(controller.get("value", controller.get("amount", 0)))
	fighter.call("controller_target_power_add", value)


func _execute_target_velocity_controller(controller: Dictionary, mode: String) -> void:
	if fighter == null:
		return
	var params: Dictionary = _velocity_params_from_controller(controller)
	match mode:
		"set":
			if fighter.has_method("controller_target_vel_set"):
				fighter.call("controller_target_vel_set", params)
		"add":
			if fighter.has_method("controller_target_vel_add"):
				fighter.call("controller_target_vel_add", params)


func _execute_target_position_controller(controller: Dictionary, mode: String) -> void:
	if fighter == null:
		return
	var params: Dictionary = _position_params_from_controller(controller)
	match mode:
		"set":
			if fighter.has_method("controller_target_pos_set"):
				fighter.call("controller_target_pos_set", params)
		"add":
			if fighter.has_method("controller_target_pos_add"):
				fighter.call("controller_target_pos_add", params)


func _execute_pause_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_pause"):
		return
	var time_value = controller.get("time", controller.get("value", 0))
	var attacker_frames: int = 0
	var defender_frames: int = 0
	if time_value is Array:
		var arr: Array = time_value
		attacker_frames = int(arr[0]) if arr.size() >= 1 else 0
		defender_frames = int(arr[1]) if arr.size() >= 2 else attacker_frames
	else:
		attacker_frames = int(time_value)
		defender_frames = attacker_frames
	fighter.call("controller_pause", attacker_frames, defender_frames)


func _execute_nothitby_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_nothitby"):
		return
	var attr: String = str(controller.get("value", controller.get("attr", "")))
	var time_val: int = int(controller.get("time", 1))
	if time_val < 0:
		time_val = 999999
	var slot: int = int(controller.get("slot", 0))
	fighter.call("controller_nothitby", attr, time_val, slot)


func _execute_attack_mul_set_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_attack_mul_set"):
		return
	var value: float = float(controller.get("value", 1.0))
	fighter.call("controller_attack_mul_set", value)


func _execute_defence_mul_set_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_defence_mul_set"):
		return
	var value: float = float(controller.get("value", 1.0))
	fighter.call("controller_defence_mul_set", value)


func _execute_assert_special_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_assert_special"):
		return
	var flag1: String = str(controller.get("flag", controller.get("flag1", "")))
	var flag2: String = str(controller.get("flag2", ""))
	var flag3: String = str(controller.get("flag3", ""))
	fighter.call("controller_assert_special", flag1, flag2, flag3)


func _execute_gravity_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_gravity"):
		return
	var value: float = -1.0
	if controller.has("value"):
		value = float(controller.get("value"))
	fighter.call("controller_gravity", value)


func _execute_target_facing_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_target_facing"):
		return
	var value: int = int(controller.get("value", 1))
	fighter.call("controller_target_facing", value)


func _execute_screen_bound_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_screen_bound"):
		return
	var value: int = int(controller.get("value", 1))
	fighter.call("controller_screen_bound", value)


func _execute_stop_snd_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_stop_snd"):
		return
	var channel: int = int(controller.get("channel", controller.get("chan", 0)))
	fighter.call("controller_stop_snd", channel)


func _execute_hit_override_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_hit_override"):
		return
	var attr: String = str(controller.get("attr", controller.get("value", "")))
	var stateno: String = str(controller.get("stateno", controller.get("state", "")))
	var slot: int = int(controller.get("slot", 0))
	var time_val: int = int(controller.get("time", 1))
	if time_val < 0:
		time_val = 999999
	var forceair: bool = bool(controller.get("forceair", false))
	fighter.call("controller_hit_override", attr, stateno, slot, time_val, forceair)


func _execute_hit_add_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_hit_add"):
		return
	var value: int = int(controller.get("value", controller.get("add_count", 1)))
	fighter.call("controller_hit_add", value)


func _execute_hitfallvel_controller(_controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_hitfallvel"):
		return
	fighter.call("controller_hitfallvel")


func _execute_move_hit_reset_controller() -> void:
	if fighter == null or not fighter.has_method("controller_move_hit_reset"):
		return
	fighter.call("controller_move_hit_reset")


func _execute_change_anim2_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_change_anim2"):
		return
	var anim: String = str(controller.get("value", controller.get("anim", "")))
	var loop: bool = bool(controller.get("animation_loop", controller.get("loop", true)))
	fighter.call("controller_change_anim2", anim, loop)


func _execute_hitby_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_hitby"):
		return
	var attr: String = str(controller.get("value", controller.get("attr", "")))
	var time_val: int = int(controller.get("time", 1))
	if time_val < 0:
		time_val = 999999
	var slot: int = int(controller.get("slot", 0))
	fighter.call("controller_hitby", attr, time_val, slot)


func _execute_pos_freeze_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_pos_freeze"):
		return
	var value: int = int(controller.get("value", 1))
	fighter.call("controller_pos_freeze", value)


func _execute_trans_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_trans"):
		return
	var trans: String = str(controller.get("trans", controller.get("type", "none")))
	var alpha = controller.get("alpha", [256, 0])
	var src: int = 256
	var dest: int = 0
	if alpha is Array and alpha.size() >= 2:
		src = int(alpha[0])
		dest = int(alpha[1])
	elif alpha is Dictionary:
		src = int(alpha.get("src", 256))
		dest = int(alpha.get("dest", 0))
	fighter.call("controller_trans", trans, src, dest)


func _execute_offset_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_offset"):
		return
	var x: float = float(controller.get("x", 0))
	var y: float = float(controller.get("y", 0))
	fighter.call("controller_offset", x, y)


func _execute_player_push_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_player_push"):
		return
	var value: int = int(controller.get("value", 1))
	fighter.call("controller_player_push", value)


func _execute_var_random_controller(controller: Dictionary) -> void:
	_ensure_controller_vars()
	var idx: int = int(controller.get("v", controller.get("var", -1)))
	if idx < 0 or idx >= int_vars.size():
		return
	var range_val = controller.get("range", [0, 1000])
	var least: int = 0
	var greatest: int = 1000
	if range_val is Array:
		if range_val.size() >= 2:
			least = int(range_val[0])
			greatest = int(range_val[1])
		elif range_val.size() >= 1:
			least = 0
			greatest = int(range_val[0])
	int_vars[idx] = randi_range(least, greatest)


func _execute_var_range_set_controller(controller: Dictionary) -> void:
	_ensure_controller_vars()
	var first: int = int(controller.get("first", 0))
	var last: int = int(controller.get("last", 59))
	if controller.has("fvalue"):
		var val: float = float(controller.get("fvalue"))
		first = clampi(first, 0, float_vars.size() - 1)
		last = clampi(last, 0, float_vars.size() - 1)
		for i in range(first, last + 1):
			float_vars[i] = val
	else:
		var val: int = int(controller.get("value", 0))
		first = clampi(first, 0, int_vars.size() - 1)
		last = clampi(last, 0, int_vars.size() - 1)
		for i in range(first, last + 1):
			int_vars[i] = val


func _execute_hitfallset_controller(controller: Dictionary) -> void:
	if fighter == null:
		return
	var value: int = int(controller.get("value", -1))
	var xvel: float = float(controller.get("xvel", controller.get("x", 0)))
	var yvel: float = float(controller.get("yvel", controller.get("y", 0)))
	if fighter.has_method("controller_hitfallset"):
		fighter.call("controller_hitfallset", value, xvel, yvel)


func _execute_hitfall_damage_controller(_controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_hitfall_damage"):
		return
	fighter.call("controller_hitfall_damage")


func _execute_env_shake_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_env_shake"):
		return
	var time_val: int = int(controller.get("time", 1))
	var freq: float = float(controller.get("freq", 60.0))
	var ampl: float = float(controller.get("ampl", controller.get("amplitude", -0.16)))
	var phase: float = float(controller.get("phase", 0.0))
	fighter.call("controller_env_shake", time_val, freq, ampl, phase)


func _execute_snd_pan_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_snd_pan"):
		return
	var channel: int = int(controller.get("channel", controller.get("chan", 0)))
	var pan: float = float(controller.get("pan", controller.get("abspan", 0)))
	fighter.call("controller_snd_pan", channel, pan)


func _execute_bind_to_target_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_bind_to_target"):
		return
	var time_val: int = int(controller.get("time", 1))
	var pos_val = controller.get("pos", controller.get("offset", [0, 0]))
	var ox: float = 0.0
	var oy: float = 0.0
	if pos_val is Array and pos_val.size() >= 2:
		ox = float(pos_val[0])
		oy = float(pos_val[1])
	fighter.call("controller_bind_to_target", time_val, ox, oy)


func _execute_target_bind_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_target_bind"):
		return
	var time_val: int = int(controller.get("time", 1))
	var pos_val = controller.get("pos", controller.get("offset", [0, 0]))
	var ox: float = 0.0
	var oy: float = 0.0
	if pos_val is Array and pos_val.size() >= 2:
		ox = float(pos_val[0])
		oy = float(pos_val[1])
	fighter.call("controller_target_bind", time_val, ox, oy)


func _execute_spr_priority_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_spr_priority"):
		return
	var value: int = int(controller.get("value", 0))
	fighter.call("controller_spr_priority", value)


func _execute_super_pause_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_super_pause"):
		return
	var time_val: int = int(controller.get("time", 30))
	fighter.call("controller_super_pause", time_val)


func _execute_reversal_def_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_reversal_def"):
		return
	var rev = controller.get("reversal", {})
	var attr: String = str(rev.get("attr", controller.get("attr", "")))
	var p1stateno: String = str(controller.get("p1stateno", controller.get("p1state", "")))
	var p2stateno: String = str(controller.get("p2stateno", controller.get("p2state", "")))
	fighter.call("controller_reversal_def", attr, p1stateno, p2stateno)


func _execute_target_drop_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_target_drop"):
		return
	var exclude_id: int = int(controller.get("excludeID", controller.get("excludeid", -1)))
	var keep_one: bool = bool(controller.get("keepone", true))
	fighter.call("controller_target_drop", exclude_id, keep_one)


func _execute_width_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_width"):
		return
	var edge = controller.get("edge", [0, 0])
	var player = controller.get("player", [0, 0])
	var val = controller.get("value", null)
	var ef: float = 0.0
	var eb: float = 0.0
	var pf: float = 0.0
	var pb: float = 0.0
	if val is Array and val.size() >= 2:
		ef = float(val[0])
		eb = float(val[1])
		pf = ef
		pb = eb
	if edge is Array and edge.size() >= 2:
		ef = float(edge[0])
		eb = float(edge[1])
	if player is Array and player.size() >= 2:
		pf = float(player[0])
		pb = float(player[1])
	fighter.call("controller_width", ef, eb, pf, pb)


func _execute_victory_quote_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_victory_quote"):
		return
	var quote_id: String = str(controller.get("value", controller.get("quote", "")))
	fighter.call("controller_victory_quote", quote_id)


func _execute_explod_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_explod"):
		return
	var anim_id: String = str(controller.get("anim", controller.get("value", 0)))
	var time_val: int = int(controller.get("time", 1))
	var pos_val = controller.get("pos", controller.get("offset", [0, 0]))
	var ox: float = 0.0
	var oy: float = 0.0
	if pos_val is Array and pos_val.size() >= 2:
		ox = float(pos_val[0])
		oy = float(pos_val[1])
	var eid: int = int(controller.get("id", controller.get("ID", 0)))
	var postype: String = str(controller.get("postype", "p1"))
	fighter.call("controller_explod", anim_id, time_val, Vector3(ox, oy, 0), eid, postype)


func _execute_remove_explod_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_remove_explod"):
		return
	var eid: int = int(controller.get("id", controller.get("ID", -1)))
	fighter.call("controller_remove_explod", eid)


func _execute_modify_explod_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_modify_explod"):
		return
	var eid: int = int(controller.get("id", controller.get("ID", 0)))
	var time_val: int = int(controller.get("time", -1))
	var has_pos: bool = controller.has("pos") or controller.has("offset")
	var pos_val = controller.get("pos", controller.get("offset", [0, 0]))
	var postype: String = str(controller.get("postype", ""))
	var ox: float = 0.0
	var oy: float = 0.0
	if pos_val is Array and pos_val.size() >= 2:
		ox = float(pos_val[0])
		oy = float(pos_val[1])
	fighter.call("controller_modify_explod", eid, time_val, Vector3(ox, oy, 0), postype, has_pos)


func _execute_after_image_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_after_image"):
		return
	var time_val: int = int(controller.get("time", 1))
	var length: int = int(controller.get("length", 20))
	fighter.call("controller_after_image", time_val, length)


func _execute_after_image_time_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_after_image_time"):
		return
	var time_val: int = int(controller.get("time", controller.get("value", 1)))
	fighter.call("controller_after_image_time", time_val)


func _execute_pal_fx_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_pal_fx"):
		return
	var time_val: int = int(controller.get("time", 1))
	var add_val = controller.get("add", [0, 0, 0])
	var mul_val = controller.get("mul", [256, 256, 256])
	var ar: int = 0
	var ag: int = 0
	var ab: int = 0
	if add_val is Array and add_val.size() >= 3:
		ar = int(add_val[0])
		ag = int(add_val[1])
		ab = int(add_val[2])
	var mr: int = 256
	var mg: int = 256
	var mb: int = 256
	if mul_val is Array and mul_val.size() >= 3:
		mr = int(mul_val[0])
		mg = int(mul_val[1])
		mb = int(mul_val[2])
	fighter.call("controller_pal_fx", time_val, ar, ag, ab, mr, mg, mb)


func _execute_angle_set_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_angle_set"):
		return
	var angle: float = float(controller.get("value", controller.get("angle", 0)))
	fighter.call("controller_angle_set", angle)


func _execute_angle_add_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_angle_add"):
		return
	var angle: float = float(controller.get("value", controller.get("angle", 0)))
	fighter.call("controller_angle_add", angle)


func _execute_attack_dist_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_attack_dist"):
		return
	var dist: float = float(controller.get("value", 0))
	fighter.call("controller_attack_dist", dist)


func _execute_fall_env_shake_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_fall_env_shake"):
		return
	var time_val: int = int(controller.get("time", 8))
	var freq: float = float(controller.get("freq", 60.0))
	var ampl: float = float(controller.get("ampl", -0.2))
	var phase: float = float(controller.get("phase", 0.0))
	fighter.call("controller_fall_env_shake", time_val, freq, ampl, phase)


func _execute_force_feedback_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_force_feedback"):
		return
	var wave: int = int(controller.get("waveform", 0))
	var time_val: int = int(controller.get("time", 1))
	var ampl: int = int(controller.get("amplitude", 128))
	fighter.call("controller_force_feedback", wave, time_val, ampl)


func _execute_display_to_clipboard_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_display_to_clipboard"):
		return
	var text: String = str(controller.get("value", controller.get("text", "")))
	fighter.call("controller_display_to_clipboard", text)


func _execute_clear_clipboard_controller(_controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_clear_clipboard"):
		return
	fighter.call("controller_clear_clipboard")


func _execute_append_to_clipboard_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_append_to_clipboard"):
		return
	var text: String = str(controller.get("value", controller.get("text", "")))
	fighter.call("controller_append_to_clipboard", text)


func _execute_helper_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_helper"):
		return
	var name_str: String = str(controller.get("name", ""))
	var eid: int = int(controller.get("id", controller.get("ID", 0)))
	var pos_val = controller.get("pos", [0, 0])
	var ox: float = 0.0
	var oy: float = 0.0
	if pos_val is Array and pos_val.size() >= 2:
		ox = float(pos_val[0])
		oy = float(pos_val[1])
	var stateno: int = int(controller.get("stateno", controller.get("state", 0)))
	fighter.call("controller_helper", name_str, eid, Vector3(ox, oy, 0), stateno)


func _execute_parent_var_set_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_parent_var_set"):
		return
	var use_float: bool = controller.has("fvar")
	var idx: int = int(controller.get("fvar" if use_float else "v", controller.get("var", 0)))
	var value = controller.get("fvalue" if use_float else "value", controller.get("value", 0))
	fighter.call("controller_parent_var_set", idx, value, use_float)


func _execute_parent_var_add_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_parent_var_add"):
		return
	var use_float: bool = controller.has("fvar")
	var idx: int = int(controller.get("fvar" if use_float else "v", controller.get("var", 0)))
	var value = controller.get("fvalue" if use_float else "value", controller.get("value", 0))
	fighter.call("controller_parent_var_add", idx, value, use_float)


func _execute_bind_to_root_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_bind_to_root"):
		return
	var time_val: int = int(controller.get("time", 1))
	var pos_val = controller.get("pos", [0, 0])
	var ox: float = 0.0
	var oy: float = 0.0
	if pos_val is Array and pos_val.size() >= 2:
		ox = float(pos_val[0])
		oy = float(pos_val[1])
	fighter.call("controller_bind_to_root", time_val, Vector3(ox, oy, 0))


func _execute_bind_to_parent_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_bind_to_parent"):
		return
	var time_val: int = int(controller.get("time", 1))
	var pos_val = controller.get("pos", [0, 0])
	var ox: float = 0.0
	var oy: float = 0.0
	if pos_val is Array and pos_val.size() >= 2:
		ox = float(pos_val[0])
		oy = float(pos_val[1])
	fighter.call("controller_bind_to_parent", time_val, Vector3(ox, oy, 0))


func _execute_destroy_self_controller(_controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_destroy_self"):
		return
	fighter.call("controller_destroy_self")


func _execute_env_color_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_env_color"):
		return
	var col = controller.get("value", [255, 255, 255])
	var r: int = 255
	var g: int = 255
	var b: int = 255
	if col is Array and col.size() >= 3:
		r = int(col[0])
		g = int(col[1])
		b = int(col[2])
	var time_val: int = int(controller.get("time", 1))
	fighter.call("controller_env_color", r, g, b, time_val)


func _execute_state_type_set_controller(controller: Dictionary) -> void:
	if fighter == null or not fighter.has_method("controller_state_type_set"):
		return
	fighter.call("controller_state_type_set", controller)


func _execute_var_set_controller(controller: Dictionary) -> void:
	var index: int = _controller_var_index(controller)
	if index < 0:
		return
	int_vars[index] = int(_controller_var_value(controller, 0))


func _execute_var_add_controller(controller: Dictionary) -> void:
	var index: int = _controller_var_index(controller)
	if index < 0:
		return
	int_vars[index] += int(_controller_var_value(controller, 0))


func _execute_fvar_set_controller(controller: Dictionary) -> void:
	var index: int = _controller_fvar_index(controller)
	if index < 0:
		return
	float_vars[index] = float(_controller_var_value(controller, 0.0))


func _execute_fvar_add_controller(controller: Dictionary) -> void:
	var index: int = _controller_fvar_index(controller)
	if index < 0:
		return
	float_vars[index] += float(_controller_var_value(controller, 0.0))


func _controller_var_index(controller: Dictionary) -> int:
	_ensure_controller_vars()
	var raw_index: int = int(controller.get("v", controller.get("var", controller.get("index", -1))))
	if raw_index < 0 or raw_index >= int_vars.size():
		return -1
	return raw_index


func _controller_fvar_index(controller: Dictionary) -> int:
	_ensure_controller_vars()
	var raw_index: int = int(controller.get("v", controller.get("fvar", controller.get("index", -1))))
	if raw_index < 0 or raw_index >= float_vars.size():
		return -1
	return raw_index


func _controller_var_value(controller: Dictionary, default_value):
	if controller.has("value"):
		return controller.get("value")
	if controller.has("amount"):
		return controller.get("amount")
	return default_value


func _velocity_params_from_controller(controller: Dictionary) -> Dictionary:
	var params: Dictionary = {}
	if controller.has("x"):
		params["x"] = controller.get("x")
	if controller.has("y"):
		params["y"] = controller.get("y")
	if controller.has("z"):
		params["z"] = controller.get("z")

	var value = controller.get("value", null)
	if value is Array:
		var arr: Array = value
		if arr.size() >= 1 and not params.has("x"):
			params["x"] = arr[0]
		if arr.size() >= 2 and not params.has("y"):
			params["y"] = arr[1]
		if arr.size() >= 3 and not params.has("z"):
			params["z"] = arr[2]
	elif value is Dictionary:
		var value_dict: Dictionary = value
		if value_dict.has("x") and not params.has("x"):
			params["x"] = value_dict.get("x")
		if value_dict.has("y") and not params.has("y"):
			params["y"] = value_dict.get("y")
		if value_dict.has("z") and not params.has("z"):
			params["z"] = value_dict.get("z")
	return params


func _position_params_from_controller(controller: Dictionary) -> Dictionary:
	var params: Dictionary = {}
	if controller.has("x"):
		params["x"] = controller.get("x")
	if controller.has("y"):
		params["y"] = controller.get("y")
	if controller.has("z"):
		params["z"] = controller.get("z")
	params["facing_relative"] = bool(controller.get("facing_relative", true))

	var value = controller.get("value", null)
	if value is Array:
		var arr: Array = value
		if arr.size() >= 1 and not params.has("x"):
			params["x"] = arr[0]
		if arr.size() >= 2 and not params.has("y"):
			params["y"] = arr[1]
		if arr.size() >= 3 and not params.has("z"):
			params["z"] = arr[2]
	elif value is Dictionary:
		var value_dict: Dictionary = value
		if value_dict.has("x") and not params.has("x"):
			params["x"] = value_dict.get("x")
		if value_dict.has("y") and not params.has("y"):
			params["y"] = value_dict.get("y")
		if value_dict.has("z") and not params.has("z"):
			params["z"] = value_dict.get("z")
		if value_dict.has("facing_relative"):
			params["facing_relative"] = bool(value_dict.get("facing_relative", true))
	return params
