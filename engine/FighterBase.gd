extends CharacterBody3D
class_name FighterBase

signal explod_requested(anim_id: String, time_ticks: int, pos: Vector3, explod_id: int)

@export var character_id: String = ""
@export var max_health: int = 1000
@export var lock_to_z_axis: bool = false
@export var locked_z_position: float = 0.0
@export var lock_to_x_axis: bool = false
@export var locked_x_position: float = 0.0
@export var default_walk_speed: float = 3.2
@export var walk_deadzone: float = 0.2
@export var accepts_player_movement_input: bool = true
@export var facing_turn_speed: float = 12.0
@export var jump_action: StringName = &"p1_up"
@export var default_jump_speed: float = 7.5
@export var default_gravity: float = 18.0
@export var enforce_floor_clamp: bool = true
@export var floor_y_level: float = 0.0
@export var use_floor_y_fallback_grounding: bool = false
@export var ground_offset_y: float = 0.0
@export var max_resource: int = 100
@export var max_juggle_points: int = 6
@export var ko_dissolve_duration_seconds: float = 0.75
@export var ko_dissolve_edge_width: float = 0.08
@export var ko_dissolve_edge_emission: float = 2.2
@export var ko_dissolve_edge_color: Color = Color(1.0, 0.5, 0.1, 1.0)
@export var ko_dissolve_noise_scale: float = 7.5

const DEFAULT_BODY_RADIUS: float = 0.45
const DEFAULT_BODY_HEIGHT: float = 1.2
const DEFAULT_BODY_OFFSET_Y: float = 1.0
const DEFAULT_HURTBOX_RADIUS: float = 0.45
const DEFAULT_HURTBOX_HEIGHT: float = 1.2
const DEFAULT_HURTBOX_OFFSET_Y: float = 1.0
const RUN_DOUBLE_TAP_WINDOW_FRAMES: int = 12
const KO_DISSOLVE_SHADER: Shader = preload("res://ui/Battle/ko_dissolve.gdshader")

var health: int = 1000
var resource: int = 0
var last_hit_damage: int = 0
var last_combo_hits: int = 0
var last_combo_damage: int = 0
var juggle_points_used: int = 0
var character_data: Dictionary = {}
var physics_data: Dictionary = {}
var command_data: Dictionary = {}
var state_data: Dictionary = {}
var sounds_data: Dictionary = {}
var projectiles_data: Dictionary = {}
var transformations_data: Dictionary = {}
var costumes_data: Dictionary = {}
var opponent: FighterBase = null
var collision_scale: float = 1.0
var mod_directory: String = ""
var current_form_id: String = "base"
var active_form_data: Dictionary = {}
var current_costume_id: String = "base"
var active_costume_data: Dictionary = {}
var team_id: int = 0
var team_slot: int = 0
var is_active_tag_fighter: bool = true
var base_physics_data: Dictionary = {}
var base_state_data: Dictionary = {}
var base_sounds_data: Dictionary = {}
var runtime_model_root: Node3D = null
var base_model_scale: Vector3 = Vector3.ONE
var base_model_offset_y: float = 0.0
var base_model_path: String = ""
var current_model_path: String = ""
var grapple_target: FighterBase = null
var grapple_hit_data: Dictionary = {}
var grapple_frames_left: int = 0
var grapple_whiff_lock_frames_remaining: int = 0
var grabbed_by: FighterBase = null
var grabbed_offset: Vector3 = Vector3.ZERO
var grabbed_prev_accepts_input: bool = true
var grabbed_prev_reads_input: bool = true
var last_tap_direction: int = 0
var last_tap_frame: int = -999999
var previous_move_direction: int = 0
var debug_hitboxes_visible_requested: bool = true
var hitpause_frames_remaining: int = 0
var animations_paused_for_hitpause: bool = false
var last_attack_result: String = ""
var last_attack_result_frame: int = -999999
var knockdown_frames_remaining: int = 0
var knockdown_wakeup_state: String = "idle"
var last_knockdown_fall_vel: Vector3 = Vector3.ZERO
var last_knockdown_fall_damage: int = 0
var timed_state_frames_remaining: int = 0
var timed_state_id: String = ""
var timed_state_recover_state: String = "idle"
var guard_lock_frames_remaining: int = 0
var guard_lock_facing_right: bool = true
var smash_mode_enabled: bool = false
var smash_percent: float = 0.0
var smash_respawn_protect_frames_remaining: int = 0
var state_control_enabled: bool = true
var runtime_forced_statetype: String = ""
var runtime_forced_movetype: String = ""
var runtime_forced_physics: String = ""
var attack_mul: float = 1.0
var defence_mul: float = 1.0
var nothitby_slot0: String = ""
var nothitby_slot0_time: int = 0
var nothitby_slot1: String = ""
var nothitby_slot1_time: int = 0
var assert_special_invisible: bool = false
var assert_special_intro: bool = false
var assert_special_roundnotover: bool = false
var assert_special_noautoturn: bool = false
var assert_special_nojugglecheck: bool = false
var runtime_gravity_override: float = -1.0  # -1 = use physics_data
var runtime_screen_bound: bool = true  # false = allow off-screen
var forced_facing_frames: int = 0  # when > 0, skip auto-turn (set by TargetFacing)
var hit_override_slots: Array[Dictionary] = []  # up to 8 slots: {attr, stateno, time, forceair}
var hitby_slot0: String = ""
var hitby_slot0_time: int = 0
var hitby_slot1: String = ""
var hitby_slot1_time: int = 0
var runtime_pos_freeze: bool = false
var runtime_display_offset: Vector3 = Vector3.ZERO
var runtime_trans_type: String = ""  # none/add/sub/add1/addalpha
var runtime_trans_alpha: Vector2 = Vector2(256, 0)  # src, dest for addalpha
var runtime_player_push_disabled: bool = false
var runtime_spr_priority: int = 0
var ko_dissolve_active: bool = false
var ko_dissolve_completed: bool = false
var ko_dissolve_elapsed: float = 0.0
var ko_dissolve_materials: Array[ShaderMaterial] = []
var ko_dissolve_original_overrides: Dictionary = {}
var runtime_bind_target: Node3D = null
var runtime_bind_offset: Vector3 = Vector3.ZERO
var runtime_bind_time: int = 0
var helper_parent_ref: Node = null
var helper_root_ref: Node = null
var runtime_bind_to_parent_time: int = 0
var runtime_bind_to_parent_offset: Vector3 = Vector3.ZERO
var runtime_bind_to_root_time: int = 0
var runtime_bind_to_root_offset: Vector3 = Vector3.ZERO
var reversal_attr: String = ""  # ReversalDef: attr string that can be reversed (empty = any when parry_active)
var runtime_width_front: float = -1.0  # -1 = use default push radius
var runtime_width_back: float = -1.0
var victory_quote_id: String = ""
var runtime_reversal_p1stateno: String = ""
var runtime_reversal_p2stateno: String = ""
var active_explods: Dictionary = {}  # id -> {time, pos, anim_id, ...}
var runtime_guard_dist: float = -1.0  # AttackDist: -1 = no dist check, else max x-distance to allow block
var pal_fx_time_remaining: int = 0
var pal_fx_add: Color = Color.BLACK
var pal_fx_mul: Color = Color.WHITE
var pal_fx_base_colors: Dictionary = {}  # "mesh_path#surface" -> Color
var after_image_time_remaining: int = 0
var after_image_length: int = 20
var after_image_history: Array[Transform3D] = []
var after_image_node: Node3D = null

@onready var skeleton: Skeleton3D = $Skeleton3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var hurtboxes_root: Node3D = $Hurtboxes
@onready var hitboxes_root: Node3D = $Hitboxes
@onready var state_controller: StateController = $StateController
@onready var command_interpreter: CommandInterpreter = $CommandInterpreter

var hitbox_system: HitboxSystem
var damage_system: DamageSystem
var projectile_system: ProjectileSystem
var sfx_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer


func _ready() -> void:
	health = max_health
	resource = max_resource
	_ensure_body_collision_shape()
	_ensure_default_hurtbox()
	_apply_collision_scale()
	_configure_collision_layers()

	hitbox_system = HitboxSystem.new()
	hitbox_system.name = "HitboxSystem"
	add_child(hitbox_system)
	hitbox_system.setup(self, skeleton, hitboxes_root, hurtboxes_root)
	hitbox_system.hit_confirmed.connect(_on_hit_confirmed)

	damage_system = DamageSystem.new()
	damage_system.name = "DamageSystem"
	add_child(damage_system)
	damage_system.combo_event.connect(_on_combo_event)
	damage_system.combat_event.connect(_on_combat_event)

	projectile_system = ProjectileSystem.new()
	projectile_system.name = "ProjectileSystem"
	add_child(projectile_system)
	projectile_system.setup(self)
	projectile_system.projectile_hit.connect(_on_hit_confirmed)
	_ensure_audio_players()
	set_hitbox_debug_visible(debug_hitboxes_visible_requested)

	state_controller.set_fighter(self)
	command_interpreter.set_fighter(self)
	command_interpreter.command_matched.connect(_on_command_matched)


func _ensure_default_hurtbox() -> void:
	if hurtboxes_root == null:
		return
	for child in hurtboxes_root.get_children():
		if child is Area3D:
			return

	var hurtbox := Area3D.new()
	hurtbox.name = "DefaultHurtbox"
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	hurtbox.set_meta("is_hurtbox", true)
	hurtbox.set_meta("owner_fighter", self)

	var shape_node := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = DEFAULT_HURTBOX_RADIUS
	shape.height = DEFAULT_HURTBOX_HEIGHT
	shape_node.shape = shape
	hurtbox.add_child(shape_node)

	hurtbox.position = Vector3(0.0, DEFAULT_HURTBOX_OFFSET_Y, 0.0)
	hurtboxes_root.add_child(hurtbox)


func _ensure_body_collision_shape() -> void:
	for child in get_children():
		if child is CollisionShape3D:
			return

	var body_shape_node := CollisionShape3D.new()
	body_shape_node.name = "BodyCollision"
	var body_shape := CapsuleShape3D.new()
	body_shape.radius = DEFAULT_BODY_RADIUS
	body_shape.height = DEFAULT_BODY_HEIGHT
	body_shape_node.shape = body_shape
	body_shape_node.position = Vector3(0.0, DEFAULT_BODY_OFFSET_Y, 0.0)
	add_child(body_shape_node)


func _configure_collision_layers() -> void:
	# Fighters should not physically push each other; keep floor/world collisions only.
	for i in range(1, 33):
		set_collision_layer_value(i, false)
		set_collision_mask_value(i, false)
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)


func _physics_process(delta: float) -> void:
	assert_special_invisible = false
	assert_special_intro = false
	assert_special_roundnotover = false
	assert_special_noautoturn = false
	assert_special_nojugglecheck = false
	runtime_screen_bound = true
	runtime_pos_freeze = false
	runtime_trans_type = ""
	runtime_display_offset = Vector3.ZERO
	if get_meta("is_helper", false):
		if helper_root_ref != null and not is_instance_valid(helper_root_ref):
			queue_free()
			return
		if helper_parent_ref != null and not is_instance_valid(helper_parent_ref):
			helper_parent_ref = helper_root_ref
	if runtime_bind_time > 0:
		runtime_bind_time -= 1
		if runtime_bind_time <= 0:
			runtime_bind_target = null
	if _is_super_pause_active():
		return
	if state_controller != null:
		state_controller.step_physics(delta)
	if hitbox_system != null:
		hitbox_system.update_persistent_hurtboxes()
	if _update_hitpause():
		_update_ko_dissolve(delta)
		return
	_update_active_explods()
	_update_guard_lock()
	_update_nothitby_timers()
	_update_hit_override_timers()
	_update_smash_respawn_protection()
	var timed_state_active: bool = _update_timed_state()
	if _update_knockdown(delta):
		return
	_update_active_grapple()
	_update_grapple_whiff_lock()
	if _is_being_grabbed():
		_update_grabbed_transform()
		return
	if runtime_bind_to_parent_time > 0 and helper_parent_ref != null and is_instance_valid(helper_parent_ref) and helper_parent_ref is Node3D:
		runtime_bind_to_parent_time -= 1
		var bind_pos: Vector3 = (helper_parent_ref as Node3D).global_position
		var offset: Vector3 = runtime_bind_to_parent_offset
		if command_interpreter != null and not command_interpreter.get_facing_right():
			offset.x = -offset.x
		global_position = bind_pos + offset
		velocity = Vector3.ZERO
		_apply_floor_clamp()
		return
	if runtime_bind_to_root_time > 0 and helper_root_ref != null and is_instance_valid(helper_root_ref) and helper_root_ref is Node3D:
		runtime_bind_to_root_time -= 1
		var bind_pos: Vector3 = (helper_root_ref as Node3D).global_position
		var offset: Vector3 = runtime_bind_to_root_offset
		if command_interpreter != null and not command_interpreter.get_facing_right():
			offset.x = -offset.x
		global_position = bind_pos + offset
		velocity = Vector3.ZERO
		_apply_floor_clamp()
		return
	if runtime_bind_target != null and is_instance_valid(runtime_bind_target) and runtime_bind_target is Node3D:
		var bind_pos: Vector3 = (runtime_bind_target as Node3D).global_position
		var offset: Vector3 = runtime_bind_offset
		if command_interpreter != null and not command_interpreter.get_facing_right():
			offset.x = -offset.x
		global_position = bind_pos + offset
		velocity = Vector3.ZERO
		_apply_floor_clamp()
		return
	_update_facing_from_opponent(delta)
	if not runtime_pos_freeze:
		if not timed_state_active:
			_apply_locomotion()
		_apply_jump_and_gravity(delta)
	else:
		velocity = Vector3.ZERO
	if lock_to_z_axis:
		global_position.z = locked_z_position
	if lock_to_x_axis:
		global_position.x = locked_x_position
	move_and_slide()
	if lock_to_x_axis:
		global_position.x = locked_x_position
	_apply_floor_clamp()
	_apply_assert_special_visibility()
	_update_after_image()
	_update_ko_dissolve(delta)


func inject_character_data(data: Dictionary) -> void:
	character_data = data.duplicate(true)
	physics_data = character_data.get("physics", {})
	command_data = character_data.get("commands", {})
	state_data = character_data.get("states", {})
	_ensure_required_states()
	sounds_data = character_data.get("sounds", {})
	projectiles_data = character_data.get("projectiles", {})
	transformations_data = character_data.get("transformations", {})
	costumes_data = character_data.get("costumes", {})
	base_physics_data = physics_data.duplicate(true)
	base_state_data = state_data.duplicate(true)
	base_sounds_data = sounds_data.duplicate(true)
	current_form_id = "base"
	active_form_data = {}
	current_costume_id = "base"
	active_costume_data = {}
	var def_data: Dictionary = character_data.get("def", {})
	collision_scale = maxf(0.1, float(def_data.get("collision_scale", 1.0)))
	ground_offset_y = float(def_data.get("ground_offset_y", 0.0))
	max_resource = maxi(1, int(def_data.get("max_resource", max_resource)))
	max_juggle_points = maxi(1, int(def_data.get("max_juggle_points", max_juggle_points)))
	resource = clampi(int(def_data.get("starting_resource", resource)), 0, max_resource)
	reset_juggle_state()
	_apply_collision_scale()
	_configure_persistent_hurtboxes(def_data)
	command_interpreter.set_command_data(command_data)
	if projectile_system != null:
		projectile_system.set_projectiles_data(projectiles_data)
	if state_data.size() > 0:
		state_controller.set_states_data(state_data)
		var initial_state: String = str(character_data.get("initial_state", "idle"))
		if state_data.has(initial_state):
			state_controller.change_state(initial_state)
		elif state_data.keys().size() > 0:
			state_controller.change_state(str(state_data.keys()[0]))


func apply_state_velocity(state_velocity) -> void:
	velocity = _to_vector3(state_velocity)


func update_hitboxes_for_state_frame(hitbox_timeline: Array, frame_in_state: int) -> void:
	if hitbox_system == null:
		return
	hitbox_system.update_hitboxes_for_frame(hitbox_timeline, frame_in_state)


func update_hurtboxes_for_state_frame(hurtbox_timeline: Array, frame_in_state: int) -> void:
	if hitbox_system == null:
		return
	hitbox_system.update_hurtboxes_for_frame(hurtbox_timeline, frame_in_state)


func update_throwboxes_for_state_frame(throwbox_timeline: Array, frame_in_state: int) -> void:
	if hitbox_system == null:
		return
	hitbox_system.update_throwboxes_for_frame(throwbox_timeline, frame_in_state)


func apply_pushback(pushback: Vector3) -> void:
	velocity += pushback


func apply_launch_velocity(launch_velocity: Vector3) -> void:
	velocity = launch_velocity


func controller_vel_set(params: Dictionary) -> void:
	var facing_sign: float = _facing_x_sign()
	if params.has("x"):
		velocity.x = float(params.get("x", 0.0)) * facing_sign
	if params.has("y"):
		velocity.y = float(params.get("y", 0.0))
	if params.has("z"):
		velocity.z = float(params.get("z", 0.0))


func controller_vel_add(params: Dictionary) -> void:
	var facing_sign: float = _facing_x_sign()
	if params.has("x"):
		velocity.x += float(params.get("x", 0.0)) * facing_sign
	if params.has("y"):
		velocity.y += float(params.get("y", 0.0))
	if params.has("z"):
		velocity.z += float(params.get("z", 0.0))


func controller_vel_mul(params: Dictionary) -> void:
	if params.has("x"):
		velocity.x *= float(params.get("x", 1.0))
	if params.has("y"):
		velocity.y *= float(params.get("y", 1.0))
	if params.has("z"):
		velocity.z *= float(params.get("z", 1.0))


func controller_pos_set(params: Dictionary) -> void:
	var pos: Vector3 = global_position
	if params.has("x"):
		pos.x = float(params.get("x", pos.x))
	if params.has("y"):
		pos.y = float(params.get("y", pos.y))
	if params.has("z"):
		pos.z = float(params.get("z", pos.z))
	global_position = pos
	_apply_floor_clamp()


func controller_pos_add(params: Dictionary) -> void:
	var facing_sign: float = _facing_x_sign() if bool(params.get("facing_relative", true)) else 1.0
	var offset := Vector3.ZERO
	if params.has("x"):
		offset.x = float(params.get("x", 0.0)) * facing_sign
	if params.has("y"):
		offset.y = float(params.get("y", 0.0))
	if params.has("z"):
		offset.z = float(params.get("z", 0.0))
	global_position += offset
	_apply_floor_clamp()


func controller_turn() -> void:
	if command_interpreter == null:
		return
	command_interpreter.set_facing_direction(not command_interpreter.get_facing_right())


func clear_runtime_state_overrides() -> void:
	runtime_forced_statetype = ""
	runtime_forced_movetype = ""
	runtime_forced_physics = ""


func controller_state_type_set(params: Dictionary) -> void:
	var st_value: String = ""
	if params.has("statetype"):
		st_value = str(params.get("statetype", ""))
	elif params.has("state_type"):
		st_value = str(params.get("state_type", ""))
	if not st_value.is_empty():
		runtime_forced_statetype = _normalize_mugen_letter(st_value)

	var mt_value: String = ""
	if params.has("movetype"):
		mt_value = str(params.get("movetype", ""))
	elif params.has("move_type"):
		mt_value = str(params.get("move_type", ""))
	if not mt_value.is_empty():
		runtime_forced_movetype = _normalize_mugen_letter(mt_value)

	var ph_value: String = ""
	if params.has("physics"):
		ph_value = str(params.get("physics", ""))
	if not ph_value.is_empty():
		runtime_forced_physics = _normalize_mugen_letter(ph_value)


func controller_target_state(state_id: String, ctrl_value = null) -> void:
	if state_id.is_empty():
		return
	if opponent == null or not is_instance_valid(opponent):
		return
	if opponent.state_controller == null:
		return
	if not opponent.state_controller.states_data.has(state_id):
		return
	opponent.state_controller.change_state(state_id)
	if ctrl_value != null:
		opponent.set_state_control_enabled(bool(ctrl_value))


func controller_target_life_add(amount: int, can_kill: bool = true) -> void:
	if opponent == null or not is_instance_valid(opponent):
		return
	opponent.controller_life_add(amount, can_kill)


func controller_target_power_add(amount: int) -> void:
	if opponent == null or not is_instance_valid(opponent):
		return
	opponent.add_resource(amount)


func controller_target_vel_set(params: Dictionary) -> void:
	if opponent == null or not is_instance_valid(opponent):
		return
	opponent.controller_vel_set(params)


func controller_target_vel_add(params: Dictionary) -> void:
	if opponent == null or not is_instance_valid(opponent):
		return
	opponent.controller_vel_add(params)


func controller_target_pos_set(params: Dictionary) -> void:
	if opponent == null or not is_instance_valid(opponent):
		return
	opponent.controller_pos_set(params)


func _nothitby_blocks(hit_data: Dictionary) -> bool:
	if nothitby_slot0_time > 0 and _attr_matches_nothitby(nothitby_slot0, hit_data):
		return true
	if nothitby_slot1_time > 0 and _attr_matches_nothitby(nothitby_slot1, hit_data):
		return true
	return false


func _hitby_blocks(hit_data: Dictionary) -> bool:
	if hitby_slot0_time > 0 and not _attr_matches_hitby(hitby_slot0, hit_data):
		return true
	if hitby_slot1_time > 0 and not _attr_matches_hitby(hitby_slot1, hit_data):
		return true
	return false


func _attr_matches_hitby(attr_string: String, hit_data: Dictionary) -> bool:
	if attr_string.strip_edges().is_empty():
		return true
	var attr: String = attr_string.strip_edges().to_lower()
	if attr == "all" or attr == "sca":
		return true
	var is_grapple: bool = bool(hit_data.get("grapple", false)) or str(hit_data.get("attack_type", "")).to_lower() == "grapple"
	var is_projectile: bool = hit_data.get("is_projectile", false)
	if (attr.find("grapple") >= 0 or attr.find("g") >= 0) and is_grapple:
		return true
	if (attr.find("projectile") >= 0 or attr.find("p") >= 0) and is_projectile:
		return true
	if (attr.find("normal") >= 0 or attr.find("n") >= 0 or attr.find("na") >= 0) and not is_grapple and not is_projectile:
		return true
	var hit_attr: String = str(hit_data.get("attr", hit_data.get("attribute", ""))).to_lower()
	if hit_attr.is_empty():
		return not is_grapple and not is_projectile
	return attr.find(hit_attr) >= 0


func _attr_matches_nothitby(attr_string: String, hit_data: Dictionary) -> bool:
	if attr_string.is_empty():
		return false
	var attr: String = attr_string.strip_edges().to_lower()
	if attr == "all" or attr == "sca":
		return true
	var is_grapple: bool = bool(hit_data.get("grapple", false)) or str(hit_data.get("attack_type", "")).to_lower() == "grapple"
	var is_projectile: bool = hit_data.get("is_projectile", false)
	if attr.find("grapple") != -1 and is_grapple:
		return true
	if attr.find("projectile") != -1 and is_projectile:
		return true
	if attr.find("normal") != -1 and not is_grapple and not is_projectile:
		return true
	return false


func _update_nothitby_timers() -> void:
	if nothitby_slot0_time > 0:
		nothitby_slot0_time -= 1
	if nothitby_slot1_time > 0:
		nothitby_slot1_time -= 1
	_update_hitby_timers()


func _update_hitby_timers() -> void:
	if hitby_slot0_time > 0:
		hitby_slot0_time -= 1
	if hitby_slot1_time > 0:
		hitby_slot1_time -= 1


func controller_target_pos_add(params: Dictionary) -> void:
	if opponent == null or not is_instance_valid(opponent):
		return
	opponent.controller_pos_add(params)


func controller_nothitby(attr_string: String, time_frames: int, slot: int) -> void:
	var attr: String = str(attr_string).strip_edges()
	var duration: int = maxi(1, int(time_frames))
	if slot == 1:
		nothitby_slot1 = attr
		nothitby_slot1_time = duration
	else:
		nothitby_slot0 = attr
		nothitby_slot0_time = duration


func controller_attack_mul_set(value: float) -> void:
	attack_mul = maxf(0.0, float(value))


func controller_defence_mul_set(value: float) -> void:
	defence_mul = maxf(0.0, float(value))


func controller_assert_special(flag1: String, flag2: String = "", flag3: String = "") -> void:
	var flags: Array[String] = [flag1, flag2, flag3]
	for f in flags:
		var flag: String = str(f).strip_edges().to_lower()
		match flag:
			"invisible":
				assert_special_invisible = true
			"intro":
				assert_special_intro = true
			"roundnotover":
				assert_special_roundnotover = true
			"noautoturn":
				assert_special_noautoturn = true
			"nojugglecheck":
				assert_special_nojugglecheck = true
			_:
				pass


func _take_pal_fx_base_snapshot() -> void:
	if runtime_model_root == null or pal_fx_base_colors.size() > 0:
		return
	_collect_material_albedo(runtime_model_root, pal_fx_base_colors)


func _collect_material_albedo(node: Node, out: Dictionary) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh != null:
			var surf_count: int = mesh.get_surface_count()
			for surf_idx in range(surf_count):
				var mat: Material = mi.get_surface_override_material(surf_idx)
				if mat == null:
					mat = mesh.surface_get_material(surf_idx)
				if mat is StandardMaterial3D:
					var key: String = "%s#%d" % [str(mi.get_path()), surf_idx]
					out[key] = (mat as StandardMaterial3D).albedo_color
	for child in node.get_children():
		_collect_material_albedo(child, out)


func _apply_pal_fx_to_materials(node: Node, base_colors: Dictionary, add: Color, mul: Color) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh != null:
			var surf_count: int = mesh.get_surface_count()
			for surf_idx in range(surf_count):
				var key: String = "%s#%d" % [str(mi.get_path()), surf_idx]
				if not base_colors.has(key):
					continue
				var mat: Material = mi.get_surface_override_material(surf_idx)
				if mat == null:
					mat = mesh.surface_get_material(surf_idx)
				if mat is StandardMaterial3D:
					if mi.get_surface_override_material(surf_idx) == null:
						mi.set_surface_override_material(surf_idx, (mat as StandardMaterial3D).duplicate())
					var std: StandardMaterial3D = mi.get_surface_override_material(surf_idx) as StandardMaterial3D
					if std != null:
						var base_c: Color = base_colors[key]
						std.albedo_color = (base_c + add) * mul
	for child in node.get_children():
		_apply_pal_fx_to_materials(child, base_colors, add, mul)


func _restore_pal_fx_base(node: Node, base_colors: Dictionary) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh != null:
			var surf_count: int = mesh.get_surface_count()
			for surf_idx in range(surf_count):
				var key: String = "%s#%d" % [str(mi.get_path()), surf_idx]
				if not base_colors.has(key):
					continue
				var mat: Material = mi.get_surface_override_material(surf_idx)
				if mat is StandardMaterial3D:
					(mat as StandardMaterial3D).albedo_color = base_colors[key]
	for child in node.get_children():
		_restore_pal_fx_base(child, base_colors)


func _apply_assert_special_visibility() -> void:
	if runtime_model_root != null:
		runtime_model_root.visible = not assert_special_invisible
		runtime_model_root.position.x = runtime_display_offset.x
		runtime_model_root.position.y = base_model_offset_y + runtime_display_offset.y
	if pal_fx_time_remaining > 0:
		pal_fx_time_remaining -= 1
		if runtime_model_root != null and pal_fx_base_colors.size() > 0:
			_apply_pal_fx_to_materials(runtime_model_root, pal_fx_base_colors, pal_fx_add, pal_fx_mul)
	elif pal_fx_base_colors.size() > 0 and runtime_model_root != null:
		_restore_pal_fx_base(runtime_model_root, pal_fx_base_colors)
		pal_fx_base_colors.clear()


func controller_gravity(value: float = -1.0) -> void:
	runtime_gravity_override = float(value) if value >= 0.0 else -1.0


func controller_target_facing(value: int) -> void:
	if opponent == null or not is_instance_valid(opponent):
		return
	var facing_right: bool = value > 0
	if command_interpreter != null and command_interpreter.has_method("get_facing_right"):
		facing_right = bool(command_interpreter.call("get_facing_right"))
	if value < 0:
		facing_right = not facing_right
	if opponent.has_method("_set_facing_from_controller"):
		opponent.call("_set_facing_from_controller", facing_right)
		opponent.set("forced_facing_frames", 2)
	elif opponent.get("command_interpreter") != null:
		var opp_ci = opponent.get("command_interpreter")
		if opp_ci != null and opp_ci.has_method("set_facing_direction"):
			opp_ci.call("set_facing_direction", facing_right)
		opponent.set("forced_facing_frames", 2)


func _set_facing_from_controller(facing_right: bool) -> void:
	if command_interpreter != null and command_interpreter.has_method("set_facing_direction"):
		command_interpreter.call("set_facing_direction", facing_right)


func controller_snd_pan(channel: int, pan: float) -> void:
	_ensure_audio_players()
	var pan_norm: float = clampf(pan / 100.0, -1.0, 1.0)
	var bus_name: String = _ensure_pan_bus_for_channel(channel)
	if bus_name.is_empty():
		return
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return
	if AudioServer.get_bus_effect_count(bus_idx) > 0:
		var eff: AudioEffect = AudioServer.get_bus_effect(bus_idx, 0)
		if eff is AudioEffectPanner:
			(eff as AudioEffectPanner).pan = pan_norm
	var player: AudioStreamPlayer = sfx_player
	if channel == 2:
		player = voice_player
	if player != null:
		player.bus = bus_name


func _ensure_pan_bus_for_channel(channel: int) -> String:
	var bus_name: String = "Fighter_%d_Ch%d" % [get_instance_id(), channel]
	if AudioServer.get_bus_index(bus_name) >= 0:
		return bus_name
	var idx: int = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	var panner: AudioEffectPanner = AudioEffectPanner.new()
	AudioServer.add_bus_effect(idx, panner)
	return bus_name


func controller_spr_priority(priority: int) -> void:
	runtime_spr_priority = clampi(priority, -5, 5)
	if runtime_model_root != null:
		_apply_spr_priority_to_model(runtime_model_root, runtime_spr_priority)


func _apply_spr_priority_to_model(node: Node, priority: int) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).sorting_offset = float(priority) * 0.1
	for child in node.get_children():
		_apply_spr_priority_to_model(child, priority)


func controller_bind_to_target(time_ticks: int, offset_x: float = 0.0, offset_y: float = 0.0) -> void:
	if opponent == null or not is_instance_valid(opponent) or not (opponent is Node3D):
		return
	runtime_bind_target = opponent as Node3D
	runtime_bind_offset = Vector3(offset_x, offset_y, 0.0)
	runtime_bind_time = maxi(1, time_ticks)


func controller_target_bind(time_ticks: int, offset_x: float = 0.0, offset_y: float = 0.0) -> void:
	if opponent == null or not is_instance_valid(opponent) or not (opponent is FighterBase):
		return
	var target: FighterBase = opponent as FighterBase
	target.runtime_bind_target = self as Node3D
	var off: Vector3 = Vector3(offset_x, offset_y, 0.0)
	if target.command_interpreter != null and not target.command_interpreter.get_facing_right():
		off.x = -off.x
	target.runtime_bind_offset = off
	target.runtime_bind_time = maxi(1, time_ticks)


func _is_super_pause_active() -> bool:
	var arena = get_parent()
	if arena == null:
		return false
	var ctrl = arena.get_node_or_null("ArenaController")
	if ctrl == null:
		return false
	var frames_val = ctrl.get("super_pause_frames_remaining")
	if frames_val == null:
		return false
	return int(frames_val) > 0


func controller_super_pause(time_ticks: int) -> void:
	var arena = get_parent()
	if arena == null:
		return
	var ctrl = arena.get_node_or_null("ArenaController")
	if ctrl != null and ctrl.has_method("request_super_pause"):
		ctrl.call("request_super_pause", time_ticks)


func controller_reversal_def(attr_string: String, p1stateno: String = "", p2stateno: String = "") -> void:
	reversal_attr = str(attr_string).strip_edges()
	runtime_reversal_p1stateno = str(p1stateno).strip_edges()
	runtime_reversal_p2stateno = str(p2stateno).strip_edges()


func controller_target_drop(_exclude_id: int = -1, _keep_one: bool = true) -> void:
	# Current runtime supports a single active grapple target.
	# exclude_id / keep_one are accepted for compatibility.
	if grapple_target == null or not is_instance_valid(grapple_target):
		_clear_grapple_sequence()
		return
	var held_target: FighterBase = grapple_target
	_clear_grapple_sequence()
	held_target._clear_grabbed_by(self)


func controller_width(edge_front: float = 0.0, edge_back: float = 0.0, player_front: float = 0.0, player_back: float = 0.0) -> void:
	runtime_width_front = player_front if player_front != 0.0 else edge_front
	runtime_width_back = player_back if player_back != 0.0 else edge_back
	if runtime_width_front == 0.0 and runtime_width_back == 0.0:
		runtime_width_front = -1.0
		runtime_width_back = -1.0


func controller_victory_quote(quote_id: String) -> void:
	victory_quote_id = str(quote_id).strip_edges()


func _resolve_explod_anchor(postype: String) -> Vector3:
	var mode: String = str(postype).strip_edges().to_lower()
	var arena = get_parent()
	var ctrl: Node = arena.get_node_or_null("ArenaController") if arena != null else null
	match mode:
		"p2":
			if opponent != null and is_instance_valid(opponent):
				return opponent.global_position
		"left":
			if ctrl != null:
				var left_val = ctrl.get("arena_left_limit")
				if left_val != null:
					return Vector3(float(left_val), global_position.y, global_position.z)
		"right":
			if ctrl != null:
				var right_val = ctrl.get("arena_right_limit")
				if right_val != null:
					return Vector3(float(right_val), global_position.y, global_position.z)
		"front":
			var sign_front: float = _facing_x_sign()
			return global_position + Vector3(sign_front, 0.0, 0.0)
		"back":
			var sign_back: float = _facing_x_sign()
			return global_position + Vector3(-sign_back, 0.0, 0.0)
	return global_position


func _resolve_explod_position(postype: String, pos_offset: Vector3) -> Vector3:
	var base: Vector3 = _resolve_explod_anchor(postype)
	var offset: Vector3 = pos_offset
	var mode: String = str(postype).strip_edges().to_lower()
	if mode == "p1" or mode == "p2" or mode == "front" or mode == "back":
		if command_interpreter != null and not command_interpreter.get_facing_right():
			offset.x = -offset.x
	return base + offset


func controller_explod(anim_id: String, time_ticks: int, pos_offset: Vector3, explod_id: int = 0, postype: String = "p1") -> void:
	var pos: Vector3 = _resolve_explod_position(postype, pos_offset)
	active_explods[explod_id] = {"time": maxi(1, time_ticks), "pos": pos, "anim_id": anim_id, "offset": pos_offset, "postype": postype}
	explod_requested.emit(anim_id, time_ticks, pos, explod_id)


func controller_remove_explod(explod_id: int) -> void:
	active_explods.erase(explod_id)


func controller_modify_explod(explod_id: int, time_ticks: int, pos_offset: Vector3, postype: String = "", has_pos: bool = false) -> void:
	if not active_explods.has(explod_id):
		return
	var data: Dictionary = active_explods[explod_id]
	if time_ticks >= 0:
		data["time"] = time_ticks
	var resolved_postype: String = str(data.get("postype", "p1"))
	if not postype.is_empty():
		resolved_postype = postype
		data["postype"] = postype
	if has_pos:
		data["offset"] = pos_offset
	var resolved_offset: Vector3 = data.get("offset", pos_offset)
	data["pos"] = _resolve_explod_position(resolved_postype, resolved_offset)


func _update_active_explods() -> void:
	if active_explods.is_empty():
		return
	var to_remove: Array[int] = []
	for key in active_explods.keys():
		var explod_id: int = int(key)
		var data: Dictionary = active_explods.get(key, {})
		var remaining: int = int(data.get("time", 0))
		if remaining <= 0:
			to_remove.append(explod_id)
			continue
		remaining -= 1
		data["time"] = remaining
		var postype: String = str(data.get("postype", "p1"))
		var offset: Vector3 = data.get("offset", Vector3.ZERO)
		data["pos"] = _resolve_explod_position(postype, offset)
		active_explods[key] = data
		if remaining <= 0:
			to_remove.append(explod_id)
	for eid in to_remove:
		active_explods.erase(eid)


func controller_after_image(time_ticks: int, length: int = 20) -> void:
	after_image_time_remaining = maxi(1, time_ticks)
	after_image_length = clampi(length, 1, 60)
	if after_image_node == null:
		after_image_node = Node3D.new()
		after_image_node.name = "AfterImageRoot"
		after_image_node.top_level = true
		add_child(after_image_node)


func controller_after_image_time(time_ticks: int) -> void:
	after_image_time_remaining = maxi(after_image_time_remaining, maxi(1, time_ticks))


func _update_after_image() -> void:
	if after_image_time_remaining <= 0 or after_image_node == null:
		return
	after_image_time_remaining -= 1
	var new_t: Transform3D = global_transform
	after_image_history.insert(0, new_t)
	while after_image_history.size() > after_image_length:
		after_image_history.pop_back()
	_draw_after_image_trail()
	if after_image_time_remaining <= 0:
		_clear_after_image_trail()
		after_image_history.clear()


func _draw_after_image_trail() -> void:
	if after_image_node == null:
		return
	var need_count: int = after_image_history.size()
	while after_image_node.get_child_count() < need_count:
		var mi: MeshInstance3D = MeshInstance3D.new()
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.25
		sphere.height = 0.5
		mi.mesh = sphere
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 1, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = mat
		after_image_node.add_child(mi)
	while after_image_node.get_child_count() > need_count:
		after_image_node.get_child(after_image_node.get_child_count() - 1).queue_free()
	for i in range(after_image_history.size()):
		var mi: Node = after_image_node.get_child(i)
		if mi is MeshInstance3D:
			(mi as MeshInstance3D).global_transform = after_image_history[i]
			var alpha: float = 1.0 - (float(i) / maxf(1.0, float(after_image_history.size())))
			if mi.material_override is StandardMaterial3D:
				var c: Color = (mi.material_override as StandardMaterial3D).albedo_color
				c.a = alpha * 0.5
				(mi.material_override as StandardMaterial3D).albedo_color = c


func _clear_after_image_trail() -> void:
	if after_image_node == null:
		return
	for c in after_image_node.get_children():
		c.queue_free()


func controller_pal_fx(time_ticks: int, add_r: int = 0, add_g: int = 0, add_b: int = 0, mul_r: int = 256, mul_g: int = 256, mul_b: int = 256) -> void:
	pal_fx_time_remaining = maxi(1, time_ticks)
	pal_fx_add = Color(add_r / 255.0, add_g / 255.0, add_b / 255.0)
	pal_fx_mul = Color(mul_r / 256.0, mul_g / 256.0, mul_b / 256.0)
	_take_pal_fx_base_snapshot()


func controller_angle_set(angle: float) -> void:
	rotation.y = deg_to_rad(angle)


func controller_angle_add(angle_delta: float) -> void:
	rotation.y += deg_to_rad(angle_delta)


func controller_attack_dist(guard_dist: float) -> void:
	runtime_guard_dist = maxf(-1.0, float(guard_dist))


func controller_fall_env_shake(time_ticks: int = 8, freq: float = 60.0, ampl: float = -0.2, phase: float = 0.0) -> void:
	if knockdown_frames_remaining > 0 and last_knockdown_fall_damage > 0:
		controller_env_shake(time_ticks, freq, ampl, phase)


func controller_force_feedback(waveform: int, time_ticks: int, amplitude: int) -> void:
	var pads: PackedInt32Array = Input.get_connected_joypads()
	if pads.is_empty():
		return
	var amp: float = clampf(float(amplitude) / 255.0, 0.0, 1.0)
	var duration_sec: float = maxf(0.01, float(maxi(1, time_ticks)) / 60.0)
	var weak: float = amp
	var strong: float = amp
	match waveform:
		1:
			weak = amp
			strong = 0.0
		2:
			weak = 0.0
			strong = amp
	for device_id in pads:
		Input.start_joy_vibration(device_id, weak, strong, duration_sec)


func controller_display_to_clipboard(text: String) -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(str(text))


func controller_clear_clipboard() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set("")


func controller_append_to_clipboard(text: String) -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		var current: String = DisplayServer.clipboard_get()
		DisplayServer.clipboard_set(current + str(text))


func controller_helper(helper_name: String, helper_id: int, pos: Vector3, stateno: int) -> void:
	var loader: Node = _find_mod_loader()
	if loader == null or not loader.has_method("instantiate_helper"):
		return
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	var h: FighterBase = loader.call("instantiate_helper", self, pos, str(stateno))
	if h != null:
		h.set_meta("is_helper", true)
		h.set_meta("helper_name", helper_name)
		h.set_meta("helper_id", helper_id)
		if not helper_name.is_empty():
			h.name = "%s_%d" % [helper_name, h.get_instance_id()]
		h.helper_parent_ref = self
		if helper_root_ref != null and is_instance_valid(helper_root_ref):
			h.helper_root_ref = helper_root_ref
		else:
			h.helper_root_ref = self
		parent_node.add_child(h)
		var world_pos: Vector3 = global_position
		var offset: Vector3 = pos
		if command_interpreter != null and not command_interpreter.get_facing_right():
			offset.x = -offset.x
		world_pos += offset
		h.global_position = world_pos
		h.floor_y_level = floor_y_level
		h.lock_to_z_axis = lock_to_z_axis
		h.locked_z_position = locked_z_position
		h.lock_to_x_axis = lock_to_x_axis
		h.locked_x_position = locked_x_position
		if opponent != null and is_instance_valid(opponent):
			h.set_opponent(opponent)
		if h.state_controller != null and h.state_controller.states_data.has(str(stateno)):
			h.state_controller.change_state(str(stateno))


func _find_mod_loader() -> Node:
	var root: Node = get_tree().current_scene
	if root != null:
		var m: Node = root.find_child("ModLoader", true, false)
		if m != null and m.has_method("instantiate_helper"):
			return m
	return null


func controller_parent_var_set(var_index: int, value, use_float: bool = false) -> void:
	if helper_parent_ref == null or not is_instance_valid(helper_parent_ref):
		return
	if not (helper_parent_ref is FighterBase):
		return
	var parent_fighter: FighterBase = helper_parent_ref as FighterBase
	if use_float and parent_fighter.has_method("set_state_var_float"):
		var fv: float = float(value) if value != null else 0.0
		parent_fighter.set_state_var_float(clampi(var_index, 0, 39), fv)
		return
	if parent_fighter.has_method("set_state_var_int"):
		var v: int = int(value) if value != null else 0
		parent_fighter.set_state_var_int(clampi(var_index, 0, 59), v)


func controller_parent_var_add(var_index: int, value, use_float: bool = false) -> void:
	if helper_parent_ref == null or not is_instance_valid(helper_parent_ref):
		return
	if not (helper_parent_ref is FighterBase):
		return
	var parent_fighter: FighterBase = helper_parent_ref as FighterBase
	if use_float and parent_fighter.has_method("add_state_var_float"):
		var fv: float = float(value) if value != null else 0.0
		parent_fighter.add_state_var_float(clampi(var_index, 0, 39), fv)
		return
	if parent_fighter.has_method("add_state_var_int"):
		var v: int = int(value) if value != null else 0
		parent_fighter.add_state_var_int(clampi(var_index, 0, 59), v)


func controller_bind_to_root(time_ticks: int, offset_vec: Vector3) -> void:
	runtime_bind_to_root_time = maxi(1, time_ticks)
	runtime_bind_to_root_offset = offset_vec
	if helper_root_ref == null or not is_instance_valid(helper_root_ref):
		if helper_parent_ref != null and is_instance_valid(helper_parent_ref) and helper_parent_ref is FighterBase:
			var parent_fighter: FighterBase = helper_parent_ref as FighterBase
			helper_root_ref = parent_fighter.helper_root_ref if parent_fighter.helper_root_ref != null else parent_fighter
		else:
			helper_root_ref = self


func controller_bind_to_parent(time_ticks: int, offset_vec: Vector3) -> void:
	runtime_bind_to_parent_time = maxi(1, time_ticks)
	runtime_bind_to_parent_offset = offset_vec
	if helper_parent_ref == null or not is_instance_valid(helper_parent_ref):
		if get_meta("is_helper", false):
			helper_parent_ref = helper_root_ref
		else:
			helper_parent_ref = null


func controller_destroy_self() -> void:
	if get_meta("is_helper", false) and is_inside_tree():
		queue_free()


func set_state_var_int(index: int, value: int) -> void:
	if state_controller == null:
		return
	state_controller._ensure_controller_vars()
	if index >= 0 and index < state_controller.int_vars.size():
		state_controller.int_vars[index] = value


func set_state_var_float(index: int, value: float) -> void:
	if state_controller == null:
		return
	state_controller._ensure_controller_vars()
	if index >= 0 and index < state_controller.float_vars.size():
		state_controller.float_vars[index] = value


func add_state_var_int(index: int, delta: int) -> void:
	if state_controller == null:
		return
	state_controller._ensure_controller_vars()
	if index >= 0 and index < state_controller.int_vars.size():
		state_controller.int_vars[index] += delta


func add_state_var_float(index: int, delta: float) -> void:
	if state_controller == null:
		return
	state_controller._ensure_controller_vars()
	if index >= 0 and index < state_controller.float_vars.size():
		state_controller.float_vars[index] += delta


func controller_screen_bound(value: int) -> void:
	runtime_screen_bound = bool(value)


func controller_hit_override(attr: String, stateno: String, slot: int = 0, time_frames: int = 1, forceair: bool = false) -> void:
	_ensure_hit_override_slots()
	var s: int = clampi(slot, 0, 7)
	var t: int = time_frames
	if t < 0:
		t = 999999
	hit_override_slots[s] = {"attr": str(attr).strip_edges(), "stateno": str(stateno).strip_edges(), "time": t, "forceair": forceair}


func _ensure_hit_override_slots() -> void:
	while hit_override_slots.size() < 8:
		hit_override_slots.append({"attr": "", "stateno": "", "time": 0, "forceair": false})


func _update_hit_override_timers() -> void:
	_ensure_hit_override_slots()
	for i in range(hit_override_slots.size()):
		var slot: Dictionary = hit_override_slots[i]
		var t: int = int(slot.get("time", 0))
		if t > 0:
			slot["time"] = t - 1


func get_hit_override_state(hit_data: Dictionary) -> String:
	_ensure_hit_override_slots()
	for slot in hit_override_slots:
		if int(slot.get("time", 0)) <= 0:
			continue
		var slot_attr: String = str(slot.get("attr", "")).strip_edges()
		if _attr_matches_hit_override(slot_attr, hit_data):
			return str(slot.get("stateno", ""))
	return ""


func _attr_matches_hit_override(attr_string: String, hit_data: Dictionary) -> bool:
	if attr_string.is_empty():
		return false
	var attr: String = attr_string.to_lower()
	if attr == "all" or attr == "sca":
		return true
	var is_grapple: bool = bool(hit_data.get("grapple", false)) or str(hit_data.get("attack_type", "")).to_lower() == "grapple"
	var is_projectile: bool = hit_data.get("is_projectile", false)
	if attr.find("grapple") >= 0 and is_grapple:
		return true
	if attr.find("projectile") >= 0 and is_projectile:
		return true
	if attr.find("normal") >= 0 and not is_grapple and not is_projectile:
		return true
	var hit_attr: String = str(hit_data.get("attr", hit_data.get("attribute", ""))).to_lower()
	if hit_attr.is_empty():
		return false
	return attr.find(hit_attr) >= 0 or hit_attr.find(attr) >= 0


func controller_move_hit_reset() -> void:
	last_attack_result = ""
	last_attack_result_frame = -999999


func controller_hitfallset(value: int, xvel: float, yvel: float) -> void:
	if value >= 0:
		var away_sign: float = 1.0
		if opponent != null and is_instance_valid(opponent) and opponent is Node3D:
			away_sign = 1.0 if global_position.x >= opponent.global_position.x else -1.0
		last_knockdown_fall_vel = Vector3(absf(xvel) * away_sign, yvel, 0.0)


func controller_hitfall_damage() -> void:
	if knockdown_frames_remaining > 0 and last_knockdown_fall_damage > 0:
		health = maxi(0, health - last_knockdown_fall_damage)
		last_knockdown_fall_damage = 0


func controller_hitfallvel() -> void:
	if knockdown_frames_remaining > 0 and last_knockdown_fall_vel.length_squared() > 0.0001:
		velocity.x = last_knockdown_fall_vel.x
		velocity.y = last_knockdown_fall_vel.y
		if velocity.z != last_knockdown_fall_vel.z:
			velocity.z = last_knockdown_fall_vel.z


func controller_hit_add(value: int) -> void:
	if damage_system == null or opponent == null or not is_instance_valid(opponent):
		return
	damage_system.add_combo_hits(self, opponent, value)


func controller_change_anim2(anim_name: String, should_loop: bool = true) -> void:
	if opponent == null or not is_instance_valid(opponent):
		return
	var anim: String = str(anim_name).strip_edges()
	if anim.is_empty():
		return
	if opponent.has_method("play_state_animation"):
		opponent.call("play_state_animation", anim, should_loop)


func controller_hitby(attr_string: String, time_frames: int, slot: int) -> void:
	var attr: String = str(attr_string).strip_edges()
	var duration: int = maxi(1, int(time_frames))
	if slot == 1:
		hitby_slot1 = attr
		hitby_slot1_time = duration
	else:
		hitby_slot0 = attr
		hitby_slot0_time = duration


func controller_pos_freeze(value: int) -> void:
	runtime_pos_freeze = bool(value)


func controller_trans(trans_type: String, alpha_src: int = 256, alpha_dest: int = 0) -> void:
	var t: String = str(trans_type).strip_edges().to_lower()
	runtime_trans_type = t
	runtime_trans_alpha = Vector2(clampi(alpha_src, 0, 256), clampi(alpha_dest, 0, 256))


func controller_offset(x: float, y: float) -> void:
	runtime_display_offset.x = float(x)
	runtime_display_offset.y = float(y)


func controller_env_shake(time_ticks: int, freq: float = 60.0, ampl: float = -0.16, phase: float = 0.0) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null and cam.has_method("request_screen_shake"):
		cam.call("request_screen_shake", time_ticks, freq, ampl, phase)


func controller_env_color(r: int, g: int, b: int, time_ticks: int) -> void:
	var arena = get_parent()
	if arena != null and arena.has_method("request_env_color"):
		arena.call("request_env_color", r, g, b, time_ticks)


func controller_player_push(value: int) -> void:
	runtime_player_push_disabled = (value == 0)


func controller_stop_snd(channel: int) -> void:
	_ensure_audio_players()
	if channel == -1:
		if sfx_player != null:
			sfx_player.stop()
		if voice_player != null:
			voice_player.stop()
	else:
		if channel == 0 or channel == 1:
			if sfx_player != null:
				sfx_player.stop()
		elif channel == 2:
			if voice_player != null:
				voice_player.stop()


func controller_pause(attacker_frames: int, defender_frames: int) -> void:
	if attacker_frames > 0 and has_method("apply_hitpause"):
		call("apply_hitpause", attacker_frames)
	if defender_frames > 0 and opponent != null and is_instance_valid(opponent) and opponent.has_method("apply_hitpause"):
		opponent.call("apply_hitpause", defender_frames)


func controller_spawn_projectile(projectile_id: String) -> void:
	if projectile_system == null or projectile_id.is_empty():
		return
	var facing_right: bool = true
	if command_interpreter != null and command_interpreter.has_method("get_facing_right"):
		facing_right = bool(command_interpreter.call("get_facing_right"))
	projectile_system.spawn_projectile(projectile_id, facing_right, global_position)


func get_num_projectiles() -> int:
	if projectile_system == null:
		return 0
	return projectile_system.active_projectiles.size()


func get_runtime_statetype() -> String:
	if not runtime_forced_statetype.is_empty():
		return runtime_forced_statetype
	if not _is_grounded_for_jump():
		return "A"
	if state_controller != null and state_controller.current_state.to_lower().find("crouch") != -1:
		return "C"
	return "S"


func get_runtime_movetype() -> String:
	if not runtime_forced_movetype.is_empty():
		return runtime_forced_movetype
	if state_controller != null:
		var state_id: String = state_controller.current_state.to_lower()
		if state_id == "hitstun" or state_id == "ko" or state_id == "grabbed" or state_id == "knockdown":
			return "H"
		var state_info: Dictionary = state_controller.get_current_state_data()
		var hitboxes = state_info.get("hitboxes", [])
		if typeof(hitboxes) == TYPE_ARRAY and not (hitboxes as Array).is_empty():
			return "A"
	return "I"


func get_runtime_physics() -> String:
	if not runtime_forced_physics.is_empty():
		return runtime_forced_physics
	if not state_control_enabled:
		return "N"
	return "A" if not _is_grounded_for_jump() else "S"


func _normalize_mugen_letter(value: String) -> String:
	if value.is_empty():
		return ""
	return value.substr(0, 1).to_upper()


func controller_power_set(value: int) -> void:
	set_resource(value)


func controller_life_add(amount: int, can_kill: bool = true) -> void:
	if amount == 0:
		return
	var next_health: int = health + amount
	if not can_kill and amount < 0 and next_health <= 0:
		next_health = 1
	set_health(next_health)


func controller_life_set(value: int) -> void:
	set_health(value)


func _facing_x_sign() -> float:
	if command_interpreter == null:
		return 1.0
	return 1.0 if command_interpreter.get_facing_right() else -1.0


func is_grounded_for_juggle() -> bool:
	return _is_grounded_for_jump()


func can_take_juggle_hit(cost: int) -> bool:
	var clamped_cost: int = maxi(1, cost)
	if is_grounded_for_juggle():
		return true
	return (juggle_points_used + clamped_cost) <= max_juggle_points


func register_juggle_hit(cost: int) -> void:
	var clamped_cost: int = maxi(1, cost)
	if is_grounded_for_juggle():
		juggle_points_used = 0
	juggle_points_used += clamped_cost


func reset_juggle_state() -> void:
	juggle_points_used = 0


func enter_hitstun(hitstun_state: String) -> void:
	state_controller.change_state(hitstun_state)


func enter_timed_state(state_id: String, duration_frames: int, recover_state: String = "idle") -> void:
	if state_controller == null:
		return
	if not state_controller.states_data.has(state_id):
		return
	timed_state_frames_remaining = maxi(1, duration_frames)
	timed_state_id = state_id
	timed_state_recover_state = recover_state
	state_control_enabled = false
	state_controller.change_state(state_id)


func enter_knockdown(hit_data: Dictionary) -> void:
	if state_controller == null:
		return
	var fall_data = hit_data.get("fall", hit_data)
	var fall_x: float = float(fall_data.get("xvel", fall_data.get("x", hit_data.get("fall_xvel", 0))))
	var fall_y: float = float(fall_data.get("yvel", fall_data.get("y", hit_data.get("fall_yvel", 0))))
	var fall_dict = hit_data.get("fall", hit_data)
	last_knockdown_fall_damage = int(fall_dict.get("damage", hit_data.get("fall_damage", 0)))
	if fall_x == 0.0 and fall_y == 0.0:
		last_knockdown_fall_vel = _to_vector3(hit_data.get("launch_velocity", Vector3.ZERO))
	else:
		var away_sign: float = 1.0
		if opponent != null and is_instance_valid(opponent) and opponent is Node3D:
			away_sign = 1.0 if global_position.x >= opponent.global_position.x else -1.0
		last_knockdown_fall_vel = Vector3(absf(fall_x) * away_sign, fall_y, 0.0)
	var knockdown_state: String = str(hit_data.get("knockdown_state", "knockdown"))
	var wakeup_state: String = str(hit_data.get("wakeup_state", "wakeup"))
	if not state_controller.states_data.has(knockdown_state):
		knockdown_state = "hitstun"
	if not state_controller.states_data.has(wakeup_state):
		wakeup_state = "idle"
	knockdown_wakeup_state = wakeup_state
	knockdown_frames_remaining = maxi(1, int(hit_data.get("knockdown_frames", 24)))
	state_control_enabled = false
	state_controller.change_state(knockdown_state)


func lock_guard_direction_for_frames(_attacker: Node, frames: int = 8) -> void:
	if command_interpreter == null:
		return
	guard_lock_frames_remaining = maxi(0, frames)
	guard_lock_facing_right = command_interpreter.get_facing_right()


func set_health(value: int) -> void:
	health = clampi(value, 0, max_health)
	if health > 0 and (ko_dissolve_active or ko_dissolve_completed):
		_reset_ko_dissolve_effect()
	if health <= 0 and state_controller != null:
		if state_controller.current_state != "ko" and state_controller.states_data.has("ko"):
			state_controller.change_state("ko")


func set_resource(value: int) -> void:
	resource = clampi(value, 0, max_resource)


func _update_ko_dissolve(delta: float) -> void:
	if runtime_model_root == null:
		return
	if health > 0:
		if ko_dissolve_active or ko_dissolve_completed:
			_reset_ko_dissolve_effect()
		return
	if not ko_dissolve_active and not ko_dissolve_completed and _should_start_ko_dissolve():
		_start_ko_dissolve_effect()
	if not ko_dissolve_active:
		return
	ko_dissolve_elapsed += maxf(0.0, delta)
	var duration: float = maxf(0.05, ko_dissolve_duration_seconds)
	var progress: float = clampf(ko_dissolve_elapsed / duration, 0.0, 1.0)
	for mat in ko_dissolve_materials:
		if mat != null:
			mat.set_shader_parameter("dissolve_progress", progress)
	if progress >= 1.0:
		ko_dissolve_active = false
		ko_dissolve_completed = true
		runtime_model_root.visible = false


func _should_start_ko_dissolve() -> bool:
	if state_controller == null:
		return false
	if state_controller.current_state.to_lower() != "ko":
		return false
	var frames_left: int = get_current_animation_time_left_frames()
	if frames_left == -1:
		# Fallback when KO animation is looped/misconfigured.
		return state_controller.frame_in_state >= 45
	return frames_left <= 0


func _start_ko_dissolve_effect() -> void:
	if runtime_model_root == null:
		return
	ko_dissolve_active = true
	ko_dissolve_completed = false
	ko_dissolve_elapsed = 0.0
	ko_dissolve_materials.clear()
	ko_dissolve_original_overrides.clear()
	_apply_ko_dissolve_to_model(runtime_model_root)


func _apply_ko_dissolve_to_model(node: Node) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh != null:
			for surf_idx in range(mesh.get_surface_count()):
				var key: String = "%s#%d" % [str(mi.get_path()), surf_idx]
				var existing_override: Material = mi.get_surface_override_material(surf_idx)
				ko_dissolve_original_overrides[key] = existing_override
				var source_mat: Material = existing_override
				if source_mat == null:
					source_mat = mesh.surface_get_material(surf_idx)
				var dissolve_mat := ShaderMaterial.new()
				dissolve_mat.shader = KO_DISSOLVE_SHADER
				dissolve_mat.set_shader_parameter("dissolve_progress", 0.0)
				dissolve_mat.set_shader_parameter("edge_width", ko_dissolve_edge_width)
				dissolve_mat.set_shader_parameter("edge_emission", ko_dissolve_edge_emission)
				dissolve_mat.set_shader_parameter("edge_color", ko_dissolve_edge_color)
				dissolve_mat.set_shader_parameter("noise_scale", ko_dissolve_noise_scale)
				if source_mat is BaseMaterial3D:
					var src_base: BaseMaterial3D = source_mat as BaseMaterial3D
					dissolve_mat.set_shader_parameter("base_color", src_base.albedo_color)
					if src_base.albedo_texture != null:
						dissolve_mat.set_shader_parameter("base_texture", src_base.albedo_texture)
				mi.set_surface_override_material(surf_idx, dissolve_mat)
				ko_dissolve_materials.append(dissolve_mat)
	for child in node.get_children():
		_apply_ko_dissolve_to_model(child)


func _reset_ko_dissolve_effect() -> void:
	if runtime_model_root != null:
		_restore_ko_dissolve_overrides(runtime_model_root)
		runtime_model_root.visible = true
	ko_dissolve_active = false
	ko_dissolve_completed = false
	ko_dissolve_elapsed = 0.0
	ko_dissolve_materials.clear()
	ko_dissolve_original_overrides.clear()


func _restore_ko_dissolve_overrides(node: Node) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh != null:
			for surf_idx in range(mesh.get_surface_count()):
				var key: String = "%s#%d" % [str(mi.get_path()), surf_idx]
				if ko_dissolve_original_overrides.has(key):
					mi.set_surface_override_material(surf_idx, ko_dissolve_original_overrides[key])
	for child in node.get_children():
		_restore_ko_dissolve_overrides(child)


func set_state_control_enabled(enabled: bool) -> void:
	state_control_enabled = enabled


func set_smash_mode_enabled(enabled: bool) -> void:
	smash_mode_enabled = enabled
	if not enabled:
		smash_percent = 0.0
		smash_respawn_protect_frames_remaining = 0


func reset_smash_state() -> void:
	smash_percent = 0.0
	smash_respawn_protect_frames_remaining = 0


func add_smash_percent(amount: float) -> void:
	if not smash_mode_enabled:
		return
	smash_percent = clampf(smash_percent + maxf(0.0, amount), 0.0, 999.0)


func get_smash_knockback_multiplier() -> float:
	if not smash_mode_enabled:
		return 1.0
	return clampf(1.0 + (smash_percent * 0.018), 1.0, 6.0)


func activate_smash_respawn_protection(frames: int) -> void:
	if not smash_mode_enabled:
		return
	smash_respawn_protect_frames_remaining = maxi(smash_respawn_protect_frames_remaining, maxi(0, frames))


func is_smash_respawn_protected() -> bool:
	return smash_mode_enabled and smash_respawn_protect_frames_remaining > 0


func add_resource(amount: int) -> void:
	set_resource(resource + amount)


func spend_resource(amount: int) -> bool:
	if amount <= 0:
		return true
	if resource < amount:
		return false
	resource -= amount
	return true


func set_opponent(value: FighterBase) -> void:
	opponent = value


func start_grapple_sequence(defender: Node, hit_data: Dictionary) -> bool:
	if defender == null or not (defender is FighterBase):
		return false
	var defender_fighter := defender as FighterBase
	if grapple_target != null or defender_fighter.grabbed_by != null:
		return false
	grapple_target = defender_fighter
	grapple_hit_data = hit_data.duplicate(true)
	grapple_frames_left = maxi(1, int(hit_data.get("grab_duration_frames", 10)))
	var grab_offset: Vector3 = _to_vector3(hit_data.get("grab_offset", Vector3(0.75, 1.0, 0.0)))
	var grabbed_state_id: String = str(hit_data.get("grabbed_state", "grabbed"))
	defender_fighter._set_grabbed_by(self, grab_offset, grabbed_state_id)
	return true


func can_throw_tech(hit_data: Dictionary, _attacker: Node = null) -> bool:
	if command_interpreter == null or state_controller == null:
		return false
	var state_info: Dictionary = state_controller.get_current_state_data()
	if bool(state_info.get("throw_tech_disabled", false)):
		return false
	if not bool(hit_data.get("throw_tech_enabled", true)):
		return false
	var required_command: String = str(hit_data.get("throw_tech_command", "throw"))
	if command_interpreter.get_last_matched_command_id() != required_command:
		return false
	var window_frames: int = int(hit_data.get("throw_tech_window", 6))
	var last_frame: int = int(command_interpreter.get_last_matched_command_frame())
	var now_frame: int = int(command_interpreter.get_frame_counter())
	return (now_frame - last_frame) <= maxi(1, window_frames)


func set_mod_directory(path: String) -> void:
	mod_directory = path


func set_runtime_model_root(node: Node3D, model_source_path: String = "") -> void:
	runtime_model_root = node
	if runtime_model_root != null:
		base_model_scale = runtime_model_root.scale
		base_model_offset_y = runtime_model_root.position.y
		current_model_path = model_source_path
		if base_model_path.is_empty() and not model_source_path.is_empty():
			base_model_path = model_source_path


func get_mod_directory() -> String:
	return mod_directory


func try_transform(form_id: String) -> bool:
	if form_id.is_empty() or current_form_id == form_id:
		return false
	var forms_data: Dictionary = transformations_data.get("forms", {})
	if not forms_data.has(form_id):
		return false
	var form_data: Dictionary = forms_data.get(form_id, {})
	var resource_cost: int = int(form_data.get("resource_cost", 0))
	if resource_cost > 0 and not spend_resource(resource_cost):
		return false
	active_form_data = form_data.duplicate(true)
	current_form_id = form_id
	_try_apply_form_model(form_data)
	_apply_form_overrides()
	var enter_state: String = str(form_data.get("enter_state", ""))
	if state_controller != null and not enter_state.is_empty() and state_controller.states_data.has(enter_state):
		state_controller.change_state(enter_state)
	var enter_sound: String = str(form_data.get("enter_sound", ""))
	if not enter_sound.is_empty():
		play_character_sound(enter_sound)
	return true


func apply_start_form(form_id: String) -> bool:
	if form_id.is_empty() or form_id == "base":
		if current_form_id != "base":
			_restore_base_form_data()
		return true
	if form_id == current_form_id:
		return true
	var forms_data: Dictionary = transformations_data.get("forms", {})
	if not forms_data.has(form_id):
		return false
	var form_data: Dictionary = forms_data.get(form_id, {})
	active_form_data = form_data.duplicate(true)
	current_form_id = form_id
	_try_apply_form_model(form_data)
	_apply_form_overrides()
	return true


func apply_start_costume(costume_id: String) -> bool:
	if costume_id.is_empty() or costume_id == "base":
		current_costume_id = "base"
		active_costume_data = {}
		return true
	if costume_id == current_costume_id:
		return true
	var costumes_dict: Dictionary = costumes_data.get("costumes", {})
	var resolved_key: String = costume_id
	if not costumes_dict.has(resolved_key):
		var needle: String = costume_id.strip_edges().to_lower()
		for key in costumes_dict.keys():
			if str(key).strip_edges().to_lower() == needle:
				resolved_key = str(key)
				break
	if not costumes_dict.has(resolved_key):
		return false
	var costume_data: Dictionary = costumes_dict.get(resolved_key, {})
	active_costume_data = costume_data.duplicate(true)
	current_costume_id = resolved_key
	_try_apply_costume_model(costume_data)
	_apply_costume_visual_overrides()
	return true


func revert_transform() -> bool:
	if current_form_id == "base":
		return false
	var revert_state: String = str(active_form_data.get("revert_state", ""))
	var revert_sound: String = str(active_form_data.get("revert_sound", ""))
	_restore_base_form_data()
	if state_controller != null and not revert_state.is_empty() and state_controller.states_data.has(revert_state):
		state_controller.change_state(revert_state)
	if not revert_sound.is_empty():
		play_character_sound(revert_sound)
	return true


func is_transformed() -> bool:
	return current_form_id != "base"


func _update_active_grapple() -> void:
	if grapple_target == null:
		return
	if not is_instance_valid(grapple_target):
		_clear_grapple_sequence()
		return
	grapple_frames_left -= 1
	if grapple_frames_left > 0:
		return
	_release_grapple_sequence()


func _release_grapple_sequence() -> void:
	if grapple_target == null:
		return
	var defender: FighterBase = grapple_target
	var hit_data: Dictionary = grapple_hit_data.duplicate(true)
	_clear_grapple_sequence()
	defender._clear_grabbed_by(self)
	if damage_system != null:
		damage_system.apply_grapple_release(self, defender, hit_data)


func _clear_grapple_sequence() -> void:
	grapple_target = null
	grapple_hit_data = {}
	grapple_frames_left = 0


func _set_grabbed_by(attacker: FighterBase, local_offset: Vector3, grabbed_state_id: String) -> void:
	grabbed_by = attacker
	grabbed_offset = local_offset
	grabbed_prev_accepts_input = accepts_player_movement_input
	grabbed_prev_reads_input = command_interpreter.read_local_input if command_interpreter != null else true
	accepts_player_movement_input = false
	if command_interpreter != null:
		command_interpreter.read_local_input = false
	velocity = Vector3.ZERO
	if state_controller != null and not grabbed_state_id.is_empty() and state_controller.states_data.has(grabbed_state_id):
		state_controller.change_state(grabbed_state_id)


func _clear_grabbed_by(attacker: FighterBase) -> void:
	if grabbed_by != attacker:
		return
	grabbed_by = null
	grabbed_offset = Vector3.ZERO
	accepts_player_movement_input = grabbed_prev_accepts_input
	if command_interpreter != null:
		command_interpreter.read_local_input = grabbed_prev_reads_input


func _is_being_grabbed() -> bool:
	return grabbed_by != null


func _update_grabbed_transform() -> void:
	if grabbed_by == null:
		return
	if not is_instance_valid(grabbed_by):
		grabbed_by = null
		grabbed_offset = Vector3.ZERO
		accepts_player_movement_input = grabbed_prev_accepts_input
		if command_interpreter != null:
			command_interpreter.read_local_input = grabbed_prev_reads_input
		return
	var offset := grabbed_offset
	var facing_right: bool = true
	if grabbed_by.command_interpreter != null:
		facing_right = grabbed_by.command_interpreter.get_facing_right()
	if not facing_right:
		offset.x = -offset.x
	global_position = grabbed_by.global_position + offset
	velocity = Vector3.ZERO


func play_state_animation(animation_name: String, should_loop: bool = true) -> bool:
	if animation_name.is_empty():
		return false
	if animation_player != null and animation_player.has_animation(animation_name):
		_set_animation_loop_mode(animation_player, animation_name, should_loop)
		animation_player.play(animation_name)
		return true
	if animation_player != null and animation_player.get_animation_list().size() == 1:
		var fallback_anim: String = str(animation_player.get_animation_list()[0])
		_set_animation_loop_mode(animation_player, fallback_anim, should_loop)
		animation_player.play(fallback_anim)
		return true
	var players: Array[Node] = find_children("*", "AnimationPlayer", true, false)
	for player_node in players:
		if player_node is AnimationPlayer:
			var player := player_node as AnimationPlayer
			if player.has_animation(animation_name):
				_set_animation_loop_mode(player, animation_name, should_loop)
				player.play(animation_name)
				return true
			if player.get_animation_list().size() == 1:
				var nested_fallback: String = str(player.get_animation_list()[0])
				_set_animation_loop_mode(player, nested_fallback, should_loop)
				player.play(nested_fallback)
				return true
	return false


func _set_animation_loop_mode(player: AnimationPlayer, animation_name: String, should_loop: bool) -> void:
	if player == null or not player.has_animation(animation_name):
		return
	var anim: Animation = player.get_animation(animation_name)
	if anim == null:
		return
	anim.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE


func get_current_animation_name() -> String:
	if animation_player == null:
		return ""
	return String(animation_player.current_animation)


func get_current_animation_time_left_frames() -> int:
	if animation_player == null:
		return 0
	var anim_name: String = String(animation_player.current_animation)
	if anim_name.is_empty() or not animation_player.has_animation(anim_name):
		return 0
	var anim: Animation = animation_player.get_animation(anim_name)
	if anim == null:
		return 0
	if anim.loop_mode != Animation.LOOP_NONE:
		return -1
	var speed_scale: float = absf(animation_player.speed_scale)
	if speed_scale <= 0.0001:
		return 0
	var remaining_seconds: float = maxf(0.0, anim.length - animation_player.current_animation_position) / speed_scale
	var physics_fps: float = float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60))
	return int(ceil(remaining_seconds * maxf(1.0, physics_fps)))


func get_debug_state_text() -> String:
	return "%s (%d)" % [state_controller.current_state, state_controller.frame_in_state]


func set_hitbox_debug_visible(enabled: bool) -> void:
	debug_hitboxes_visible_requested = enabled
	if hitbox_system != null:
		hitbox_system.set_debug_visuals_enabled(enabled)


func get_hitbox_debug_info() -> Dictionary:
	if hitbox_system == null:
		return {"enabled": false, "hurtboxes": 0, "active_hitboxes": 0}
	return hitbox_system.get_debug_info()


func _on_hit_confirmed(attacker: Node, defender: Node, hit_data: Dictionary) -> void:
	if damage_system == null:
		return
	if attacker == self:
		last_hit_damage = int(hit_data.get("damage", 0))
		var impact_sound_id: String = str(hit_data.get("hit_sound", ""))
		if not impact_sound_id.is_empty():
			play_character_sound(impact_sound_id)
	damage_system.apply_hit(attacker, defender, hit_data)


func try_reflect_projectile(projectile: Node, _attacker: Node, hit_data: Dictionary) -> bool:
	if not _is_reflect_active():
		return false
	if projectile == null or not projectile.has_method("reflect_to"):
		return false
	projectile.call("reflect_to", self)
	var meter_gain: int = int(hit_data.get("reflect_meter_gain", 20))
	add_resource(meter_gain)
	return true


func _on_combo_event(attacker: Node, _defender: Node, total_hits: int, total_damage: int) -> void:
	if attacker != self:
		return
	last_combo_hits = total_hits
	last_combo_damage = total_damage


func _on_combat_event(event_id: String, attacker: Node, defender: Node, _hit_data: Dictionary) -> void:
	if attacker != self and defender != self:
		return
	if attacker == self:
		if event_id == "hit" or event_id == "throw_hit":
			last_attack_result = "hit"
			last_attack_result_frame = int(Engine.get_physics_frames())
		elif event_id == "block":
			last_attack_result = "block"
			last_attack_result_frame = int(Engine.get_physics_frames())
	match event_id:
		"parry":
			if defender == self:
				_play_first_available_sound(["parry_success", "parry", "guard", "hit_light"])
			SystemSFX.play_battle_from(self, "battle_parry")
		"block":
			if defender == self:
				_play_first_available_sound(["block", "guard", "hit_light"])
			SystemSFX.play_battle_from(self, "battle_block")
		"throw_start":
			if attacker == self:
				_play_first_available_sound(["throw_start", "swing_heavy", "swing_light"])
			SystemSFX.play_battle_from(self, "battle_throw")
		"throw_hit":
			if attacker == self:
				_play_first_available_sound(["throw_hit", "hit_heavy", "hit_light"])
			elif defender == self:
				_play_first_available_sound(["thrown", "hit_heavy", "hit_light"])
			SystemSFX.play_battle_from(self, "battle_throw")
		"throw_tech":
			_play_first_available_sound(["parry_success", "parry", "guard"])
			SystemSFX.play_battle_from(self, "battle_parry")
		"ko":
			if defender == self:
				_play_first_available_sound(["ko", "hit_heavy", "hit_light"])
			SystemSFX.play_battle_from(self, "battle_ko")
		"hit":
			if attacker == self:
				_play_first_available_sound(["hit_confirm", "hit_light"])
			elif defender == self:
				_play_first_available_sound(["hurt", "hit_light"])
			SystemSFX.play_battle_from(self, "battle_hit")
	_try_play_battle_vfx(event_id, attacker, defender, _hit_data)


func _try_play_battle_vfx(event_id: String, attacker: Node, defender: Node, hit_data: Dictionary) -> void:
	var vfx: Node = get_node_or_null("/root/VFX")
	if vfx == null:
		return
	var world_pos: Vector3 = _combat_event_world_position(attacker, defender)
	var screen_pos: Vector2 = _world_to_screen_point(world_pos)
	match event_id:
		"hit", "throw_hit":
			if vfx.has_method("spawn_energy_burst"):
				vfx.call("spawn_energy_burst", screen_pos, Color(1.0, 0.25, 0.2))
			if vfx.has_method("freeze_frame"):
				vfx.call("freeze_frame", 0.045, 0.08)
			var damage: int = int(hit_data.get("damage", 0))
			if damage > 0 and vfx.has_method("spawn_damage_number"):
				vfx.call("spawn_damage_number", screen_pos + Vector2(0.0, -24.0), damage, damage >= 40)
		"block":
			if vfx.has_method("spawn_shield_break"):
				vfx.call("spawn_shield_break", screen_pos)
			if vfx.has_method("freeze_frame"):
				vfx.call("freeze_frame", 0.03, 0.1)
		"parry", "throw_tech":
			if vfx.has_method("spawn_combo_ring"):
				vfx.call("spawn_combo_ring", screen_pos)
			if vfx.has_method("freeze_frame"):
				vfx.call("freeze_frame", 0.04, 0.07)
		"ko":
			if vfx.has_method("kill_effect"):
				vfx.call("kill_effect", screen_pos)
			elif vfx.has_method("spawn_energy_burst"):
				vfx.call("spawn_energy_burst", screen_pos, Color(1.0, 0.5, 0.2))


func _combat_event_world_position(attacker: Node, defender: Node) -> Vector3:
	if defender is Node3D:
		return (defender as Node3D).global_position + Vector3(0.0, 1.2, 0.0)
	if attacker is Node3D:
		return (attacker as Node3D).global_position + Vector3(0.0, 1.2, 0.0)
	return global_position + Vector3(0.0, 1.2, 0.0)


func _world_to_screen_point(world_pos: Vector3) -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var camera := viewport.get_camera_3d()
	if camera == null:
		return viewport.get_visible_rect().size * 0.5
	if camera.is_position_behind(world_pos):
		return viewport.get_visible_rect().size * 0.5
	return camera.unproject_position(world_pos)


func _play_first_available_sound(sound_ids: Array[String]) -> bool:
	for sound_id in sound_ids:
		if play_character_sound(sound_id):
			return true
	return false


func _on_command_matched(_command_id: String, command_entry: Dictionary) -> void:
	if health <= 0:
		return
	if timed_state_frames_remaining > 0:
		return
	if bool(command_entry.get("revert_transform", false)):
		revert_transform()
		return
	var transform_to: String = str(command_entry.get("transform_to", ""))
	if not transform_to.is_empty():
		var changed: bool = try_transform(transform_to)
		if changed:
			var transform_state: String = str(command_entry.get("transform_state", ""))
			if state_controller != null and not transform_state.is_empty() and state_controller.states_data.has(transform_state):
				state_controller.change_state(transform_state)
			return
	_apply_custom_command_effects(command_entry)
	var target_state: String = str(command_entry.get("target_state", ""))
	if target_state.is_empty():
		return
	if grapple_whiff_lock_frames_remaining > 0 and _state_is_grapple_attempt(target_state):
		return
	if not _can_enter_state_from_current(target_state):
		return
	state_controller.change_state(target_state)


func _apply_custom_command_effects(command_entry: Dictionary) -> void:
	if command_entry.has("teleport_to"):
		var world_target: Vector3 = _to_vector3(command_entry.get("teleport_to", Vector3.ZERO))
		global_position = world_target
		_apply_floor_clamp()

	if command_entry.has("teleport_offset"):
		var offset: Vector3 = _to_vector3(command_entry.get("teleport_offset", Vector3.ZERO))
		if command_interpreter != null and not command_interpreter.get_facing_right():
			offset.x = -offset.x
		global_position += offset
		_apply_floor_clamp()

	if command_entry.has("teleport_to_opponent_offset") and opponent != null:
		var opp_offset: Vector3 = _to_vector3(command_entry.get("teleport_to_opponent_offset", Vector3.ZERO))
		var facing_right: bool = true
		if command_interpreter != null:
			facing_right = command_interpreter.get_facing_right()
		if not facing_right:
			opp_offset.x = -opp_offset.x
		global_position = opponent.global_position + opp_offset
		_apply_floor_clamp()

	var freeze_self_frames: int = int(command_entry.get("freeze_self_frames", 0))
	if freeze_self_frames > 0:
		_apply_command_freeze(self, freeze_self_frames, str(command_entry.get("freeze_self_state", "hitstun")))

	var freeze_opp_frames: int = int(command_entry.get("freeze_opponent_frames", 0))
	if freeze_opp_frames > 0 and opponent != null:
		_apply_command_freeze(opponent, freeze_opp_frames, str(command_entry.get("freeze_opponent_state", "hitstun")))

	var custom_actions = command_entry.get("custom_actions", [])
	if typeof(custom_actions) == TYPE_ARRAY:
		for action in custom_actions:
			if typeof(action) != TYPE_DICTIONARY:
				continue
			_apply_custom_action(action)


func _apply_custom_action(action: Dictionary) -> void:
	var action_type: String = str(action.get("type", "")).to_lower()
	match action_type:
		"teleport_self":
			var to_vec: Vector3 = _to_vector3(action.get("to", Vector3.ZERO))
			global_position = to_vec
			_apply_floor_clamp()
		"teleport_self_offset":
			var off: Vector3 = _to_vector3(action.get("offset", Vector3.ZERO))
			if command_interpreter != null and not command_interpreter.get_facing_right():
				off.x = -off.x
			global_position += off
			_apply_floor_clamp()
		"teleport_to_opponent":
			if opponent != null:
				var opp_off: Vector3 = _to_vector3(action.get("offset", Vector3.ZERO))
				if command_interpreter != null and not command_interpreter.get_facing_right():
					opp_off.x = -opp_off.x
				global_position = opponent.global_position + opp_off
				_apply_floor_clamp()
		"freeze_self":
			_apply_command_freeze(self, int(action.get("frames", 0)), str(action.get("state", "hitstun")))
		"freeze_opponent":
			if opponent != null:
				_apply_command_freeze(opponent, int(action.get("frames", 0)), str(action.get("state", "hitstun")))


func notify_grapple_whiff(hit_data: Dictionary) -> void:
	var lock_frames: int = int(hit_data.get("grapple_whiff_cooldown_frames", 16))
	grapple_whiff_lock_frames_remaining = maxi(grapple_whiff_lock_frames_remaining, maxi(1, lock_frames))


func _update_grapple_whiff_lock() -> void:
	if grapple_whiff_lock_frames_remaining <= 0:
		return
	grapple_whiff_lock_frames_remaining -= 1
	if grapple_whiff_lock_frames_remaining < 0:
		grapple_whiff_lock_frames_remaining = 0


func _state_is_grapple_attempt(state_id: String) -> bool:
	if state_id.is_empty() or not state_data.has(state_id):
		return false
	var state_info: Dictionary = state_data.get(state_id, {})
	if typeof(state_info) != TYPE_DICTIONARY:
		return false
	var throwboxes = state_info.get("throwboxes", [])
	if typeof(throwboxes) == TYPE_ARRAY and not (throwboxes as Array).is_empty():
		return true
	var hitboxes = state_info.get("hitboxes", [])
	if typeof(hitboxes) != TYPE_ARRAY:
		return false
	for entry in hitboxes:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = (entry as Dictionary).get("data", {})
		if typeof(data) != TYPE_DICTIONARY:
			continue
		if bool(data.get("grapple", false)) or bool(data.get("grapple_hold", false)):
			return true
		if str(data.get("attack_type", "")).to_lower() == "grapple":
			return true
	return false


func _apply_command_freeze(target: Node, frames: int, state_id: String) -> void:
	if target == null:
		return
	var duration: int = maxi(0, frames)
	if duration <= 0:
		return
	if target.has_method("enter_timed_state"):
		target.call("enter_timed_state", state_id, duration, "idle")
	elif target.has_method("apply_hitpause"):
		target.call("apply_hitpause", duration)


func _ensure_required_states() -> void:
	if state_data.is_empty():
		return

	var defaults: Dictionary = {
		"idle": {
			"animation": "bn01",
			"velocity": [0.0, 0.0, 0.0],
			"allow_movement": true,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"guard": {
			"animation": "bg01",
			"velocity": [0.0, 0.0, 0.0],
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
			"animation": "bd01",
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
			"animation": "bd01",
			"velocity": [0.0, 0.0, 0.0],
			"allow_movement": false,
			"can_guard": false,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {"frame": 22, "id": "idle"}
		},
		"knockdown": {
			"animation": "bd01",
			"velocity": [0.0, 0.0, 0.0],
			"allow_movement": false,
			"can_guard": false,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"wakeup": {
			"animation": "bn01",
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
			"animation": "bd02",
			"velocity": [0.0, 0.0, 0.0],
			"allow_movement": false,
			"can_guard": false,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		},
		"victory": {
			"animation": "bv01",
			"velocity": [0.0, 0.0, 0.0],
			"allow_movement": false,
			"cancel_into": [],
			"hitboxes": [],
			"hurtboxes": [],
			"next": {}
		}
	}

	for state_id in defaults.keys():
		if not state_data.has(state_id):
			state_data[state_id] = defaults[state_id]


func _apply_form_overrides() -> void:
	var physics_overrides: Dictionary = active_form_data.get("physics_overrides", {})
	var sounds_overrides: Dictionary = active_form_data.get("sounds_overrides", {})
	var state_overrides: Dictionary = active_form_data.get("state_overrides", {})
	var command_overrides: Dictionary = active_form_data.get("command_overrides", {})

	physics_data = base_physics_data.duplicate(true)
	sounds_data = base_sounds_data.duplicate(true)
	state_data = base_state_data.duplicate(true)
	command_data = character_data.get("commands", {}).duplicate(true)

	var form_states_path: String = str(active_form_data.get("states_path", ""))
	var form_commands_path: String = str(active_form_data.get("commands_path", ""))
	var form_physics_path: String = str(active_form_data.get("physics_path", ""))
	var form_sounds_path: String = str(active_form_data.get("sounds_path", ""))

	if not form_states_path.is_empty():
		var loaded_states: Dictionary = _load_form_dictionary_file(form_states_path)
		if not loaded_states.is_empty():
			state_data = loaded_states
	if not form_commands_path.is_empty():
		var loaded_commands: Dictionary = _load_form_dictionary_file(form_commands_path)
		if not loaded_commands.is_empty():
			command_data = loaded_commands
	if not form_physics_path.is_empty():
		var loaded_physics: Dictionary = _load_form_dictionary_file(form_physics_path)
		if not loaded_physics.is_empty():
			physics_data = loaded_physics
	if not form_sounds_path.is_empty():
		var loaded_sounds: Dictionary = _load_form_dictionary_file(form_sounds_path)
		if not loaded_sounds.is_empty():
			sounds_data = loaded_sounds

	physics_data = _merge_dictionary_overrides(physics_data, physics_overrides)
	sounds_data = _merge_dictionary_overrides(sounds_data, sounds_overrides)
	state_data = _merge_dictionary_overrides(state_data, state_overrides)
	command_data = _merge_dictionary_overrides(command_data, command_overrides)

	if state_controller != null:
		state_controller.set_states_data(state_data)
	if command_interpreter != null:
		command_interpreter.set_command_data(command_data)

	if runtime_model_root != null:
		var model_scale := base_model_scale
		var custom_scale = active_form_data.get("model_scale", null)
		if custom_scale is Array and custom_scale.size() >= 3:
			model_scale = Vector3(float(custom_scale[0]), float(custom_scale[1]), float(custom_scale[2]))
		else:
			var scale_mult: float = float(active_form_data.get("model_scale_multiplier", 1.0))
			model_scale = base_model_scale * scale_mult
		runtime_model_root.scale = model_scale

		var model_y: float = base_model_offset_y + float(active_form_data.get("model_offset_y_add", 0.0))
		if active_form_data.has("model_offset_y"):
			model_y = float(active_form_data.get("model_offset_y", model_y))
		var model_pos := runtime_model_root.position
		model_pos.y = model_y
		runtime_model_root.position = model_pos
	if current_costume_id != "base" and not active_costume_data.is_empty():
		_try_apply_costume_model(active_costume_data)
		_apply_costume_visual_overrides()


func _restore_base_form_data() -> void:
	current_form_id = "base"
	active_form_data = {}
	physics_data = base_physics_data.duplicate(true)
	sounds_data = base_sounds_data.duplicate(true)
	state_data = base_state_data.duplicate(true)
	command_data = character_data.get("commands", {}).duplicate(true)
	if state_controller != null:
		state_controller.set_states_data(state_data)
	if command_interpreter != null:
		command_interpreter.set_command_data(command_data)
	if not base_model_path.is_empty() and current_model_path != base_model_path:
		var base_model_node: Node3D = _load_model_node_from_path(base_model_path)
		if base_model_node != null:
			_replace_runtime_model_root(base_model_node, base_model_path)
	if runtime_model_root != null:
		runtime_model_root.scale = base_model_scale
		var model_pos := runtime_model_root.position
		model_pos.y = base_model_offset_y
		runtime_model_root.position = model_pos
	if current_costume_id != "base" and not active_costume_data.is_empty():
		_try_apply_costume_model(active_costume_data)
		_apply_costume_visual_overrides()


func _merge_dictionary_overrides(base_dict: Dictionary, overrides: Dictionary) -> Dictionary:
	var merged := base_dict.duplicate(true)
	for key in overrides.keys():
		merged[key] = overrides[key]
	return merged


func _load_form_dictionary_file(path_raw: String) -> Dictionary:
	var resolved_path: String = _resolve_mod_resource_path(path_raw)
	if resolved_path.is_empty() or not FileAccess.file_exists(resolved_path):
		return {}
	var file := FileAccess.open(resolved_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed as Dictionary
	return {}


func _try_apply_form_model(form_data: Dictionary) -> void:
	var model_path_raw: String = str(form_data.get("model_path", ""))
	if model_path_raw.is_empty():
		return
	var resolved_path: String = _resolve_mod_resource_path(model_path_raw)
	if resolved_path.is_empty() or resolved_path == current_model_path:
		return
	var model_node: Node3D = _load_model_node_from_path(resolved_path)
	if model_node == null:
		return
	_replace_runtime_model_root(model_node, resolved_path)


func _try_apply_costume_model(costume_data: Dictionary) -> void:
	var model_path_raw: String = str(costume_data.get("model_path", ""))
	if model_path_raw.is_empty():
		return
	var resolved_path: String = _resolve_mod_resource_path(model_path_raw)
	if resolved_path.is_empty() or resolved_path == current_model_path:
		return
	var model_node: Node3D = _load_model_node_from_path(resolved_path)
	if model_node == null:
		return
	_replace_runtime_model_root(model_node, resolved_path)


func _apply_costume_visual_overrides() -> void:
	if runtime_model_root == null:
		return
	var model_scale: Vector3 = runtime_model_root.scale
	if active_costume_data.has("model_scale"):
		var custom_scale = active_costume_data.get("model_scale", null)
		if custom_scale is Array and custom_scale.size() >= 3:
			model_scale = Vector3(float(custom_scale[0]), float(custom_scale[1]), float(custom_scale[2]))
	elif active_costume_data.has("model_scale_multiplier"):
		model_scale *= float(active_costume_data.get("model_scale_multiplier", 1.0))
	runtime_model_root.scale = model_scale
	if active_costume_data.has("model_offset_y") or active_costume_data.has("model_offset_y_add"):
		var model_pos := runtime_model_root.position
		var final_y: float = model_pos.y
		if active_costume_data.has("model_offset_y"):
			final_y = float(active_costume_data.get("model_offset_y", final_y))
		final_y += float(active_costume_data.get("model_offset_y_add", 0.0))
		model_pos.y = final_y
		runtime_model_root.position = model_pos


func _replace_runtime_model_root(new_model_root: Node3D, model_source_path: String) -> void:
	if skeleton == null or new_model_root == null:
		return
	if runtime_model_root != null:
		_reset_ko_dissolve_effect()
		runtime_model_root.queue_free()
	runtime_model_root = new_model_root
	skeleton.add_child(runtime_model_root)
	current_model_path = model_source_path


func _load_model_node_from_path(path: String) -> Node3D:
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


func _can_enter_state_from_current(target_state: String) -> bool:
	if state_controller.current_state.is_empty():
		return true
	var current_data: Dictionary = state_controller.get_current_state_data()
	if _can_cancel_via_windows(current_data, target_state):
		return true
	# Explicit cancel list now controls command interruption.
	# If the state does not list target_state, the move must finish
	# (or be interrupted by hit/guard state changes) before new commands apply.
	if current_data.has("cancel_into"):
		var cancel_into = current_data.get("cancel_into", [])
		if typeof(cancel_into) == TYPE_ARRAY:
			return (cancel_into as Array).has(target_state)
		return false
	# Backward compatibility for very old states: no cancel_into key means no interrupt.
	return false


func _can_cancel_via_windows(current_data: Dictionary, target_state: String) -> bool:
	var windows = current_data.get("cancel_windows", [])
	if typeof(windows) != TYPE_ARRAY or windows.is_empty():
		return false
	var frame_now: int = state_controller.frame_in_state
	for entry in windows:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var start_frame: int = int(entry.get("start", -1))
		var end_frame: int = int(entry.get("end", -1))
		if start_frame >= 0 and frame_now < start_frame:
			continue
		if end_frame >= 0 and frame_now > end_frame:
			continue
		var into = entry.get("into", [])
		if typeof(into) == TYPE_ARRAY and not into.is_empty() and not into.has(target_state):
			continue
		var required_result: String = str(entry.get("on", "any")).to_lower()
		if required_result == "any":
			return true
		var result_window_frames: int = int(entry.get("result_window_frames", 20))
		var recent_enough: bool = int(Engine.get_physics_frames()) - last_attack_result_frame <= maxi(1, result_window_frames)
		if recent_enough and last_attack_result == required_result:
			return true
	return false


func apply_hitpause(frames: int) -> void:
	var clamped_frames: int = maxi(0, frames)
	if clamped_frames <= 0:
		return
	hitpause_frames_remaining = maxi(hitpause_frames_remaining, clamped_frames)
	if not animations_paused_for_hitpause:
		_set_animation_pause(true)


func is_in_hitpause() -> bool:
	return hitpause_frames_remaining > 0


func _update_hitpause() -> bool:
	if hitpause_frames_remaining <= 0:
		return false
	hitpause_frames_remaining -= 1
	if hitpause_frames_remaining <= 0:
		hitpause_frames_remaining = 0
		_set_animation_pause(false)
	return true


func _update_knockdown(delta: float) -> bool:
	if knockdown_frames_remaining <= 0:
		return false
	knockdown_frames_remaining -= 1
	state_control_enabled = false
	_apply_jump_and_gravity(delta)
	if lock_to_z_axis:
		global_position.z = locked_z_position
	move_and_slide()
	_apply_floor_clamp()
	if knockdown_frames_remaining <= 0:
		knockdown_frames_remaining = 0
		state_control_enabled = true
		if state_controller != null and state_controller.states_data.has(knockdown_wakeup_state):
			state_controller.change_state(knockdown_wakeup_state)
	return true


func _update_timed_state() -> bool:
	if timed_state_frames_remaining <= 0:
		return false
	if state_controller == null:
		timed_state_frames_remaining = 0
		timed_state_id = ""
		return false
	timed_state_frames_remaining -= 1
	state_control_enabled = false
	if timed_state_frames_remaining <= 0:
		timed_state_frames_remaining = 0
		var recover_state: String = timed_state_recover_state if not timed_state_recover_state.is_empty() else "idle"
		if state_controller.states_data.has(recover_state):
			state_controller.change_state(recover_state)
		timed_state_id = ""
		state_control_enabled = true
	return true


func _update_guard_lock() -> void:
	if guard_lock_frames_remaining <= 0:
		return
	guard_lock_frames_remaining -= 1
	if guard_lock_frames_remaining < 0:
		guard_lock_frames_remaining = 0


func _update_smash_respawn_protection() -> void:
	if smash_respawn_protect_frames_remaining <= 0:
		return
	smash_respawn_protect_frames_remaining -= 1
	if smash_respawn_protect_frames_remaining < 0:
		smash_respawn_protect_frames_remaining = 0


func _set_animation_pause(paused: bool) -> void:
	animations_paused_for_hitpause = paused
	var players: Array[Node] = []
	if animation_player != null:
		players.append(animation_player)
	players.append_array(find_children("*", "AnimationPlayer", true, false))
	for player_node in players:
		if player_node is AnimationPlayer:
			var player := player_node as AnimationPlayer
			player.speed_scale = 0.0 if paused else 1.0


func _update_facing_from_opponent(delta: float) -> void:
	if opponent == null or assert_special_noautoturn:
		return
	if forced_facing_frames > 0:
		forced_facing_frames -= 1
		return
	command_interpreter.set_facing_direction(global_position.x <= opponent.global_position.x)
	var to_opponent := opponent.global_position - global_position
	to_opponent.y = 0.0
	if to_opponent.length_squared() < 0.0001:
		return
	var target_yaw: float = atan2(to_opponent.x, to_opponent.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * facing_turn_speed, 0.0, 1.0))


func _apply_locomotion() -> void:
	if command_interpreter == null or state_controller == null:
		previous_move_direction = 0
		return
	if not accepts_player_movement_input or not state_control_enabled:
		velocity.x = move_toward(velocity.x, 0.0, default_walk_speed * 0.5)
		previous_move_direction = 0
		return

	var state_info: Dictionary = state_controller.get_current_state_data()
	if not _state_allows_movement(state_info):
		velocity.x = move_toward(velocity.x, 0.0, default_walk_speed * 0.35)
		previous_move_direction = 0
		return

	var state_id: String = state_controller.current_state
	var move_input: float = command_interpreter.get_latest_raw_direction().x
	var grounded: bool = _is_grounded_for_jump()
	var walk_speed: float = float(physics_data.get("walk_speed", default_walk_speed))
	var run_speed: float = float(physics_data.get("run_speed", walk_speed * 1.8))
	var move_direction: int = 0
	if move_input > walk_deadzone:
		move_direction = 1
	elif move_input < -walk_deadzone:
		move_direction = -1

	# Detect a double tap from neutral -> direction -> neutral -> same direction.
	if move_direction != 0 and previous_move_direction == 0 and state_id != "run":
		var frame_now: int = int(Engine.get_physics_frames())
		var can_run_state: bool = state_controller.states_data.has("run")
		var can_enter_run: bool = state_id == "idle" or state_id == "walk"
		if can_run_state and can_enter_run and move_direction == last_tap_direction and frame_now - last_tap_frame <= RUN_DOUBLE_TAP_WINDOW_FRAMES:
			state_controller.change_state("run")
			state_id = "run"
		last_tap_direction = move_direction
		last_tap_frame = frame_now

	# Keep locomotion state in sync with movement input so walk/run animations play.
	if state_id != "run":
		if absf(move_input) > walk_deadzone and state_id == "idle" and state_controller.states_data.has("walk"):
			state_controller.change_state("walk")
			state_id = state_controller.current_state
		elif absf(move_input) <= walk_deadzone and state_id == "walk" and state_controller.states_data.has("idle"):
			state_controller.change_state("idle")
			state_id = state_controller.current_state

	var movement_speed: float = run_speed if state_id == "run" else walk_speed
	if state_id == "run" and absf(move_input) <= walk_deadzone:
		if state_controller.states_data.has("idle"):
			state_controller.change_state("idle")
		velocity.x = move_toward(velocity.x, 0.0, movement_speed * 0.5)
		return
	if absf(move_input) > walk_deadzone:
		if smash_mode_enabled and not grounded:
			var smash_air_speed: float = float(physics_data.get("smash_air_speed", walk_speed * 0.85))
			var smash_air_accel: float = float(physics_data.get("smash_air_accel", 0.45))
			var target_x: float = move_input * smash_air_speed
			velocity.x = move_toward(velocity.x, target_x, smash_air_accel)
		else:
			velocity.x = move_input * movement_speed
	else:
		if smash_mode_enabled and not grounded:
			var smash_air_brake: float = float(physics_data.get("smash_air_brake", 0.2))
			velocity.x = move_toward(velocity.x, 0.0, smash_air_brake)
		else:
			velocity.x = move_toward(velocity.x, 0.0, movement_speed * 0.5)
	previous_move_direction = move_direction


func _state_allows_movement(state_info: Dictionary) -> bool:
	if state_info.has("allow_movement"):
		return bool(state_info["allow_movement"])
	var state_id: String = state_controller.current_state
	return state_id == "idle" or state_id == "walk"


func _is_parry_active() -> bool:
	if state_controller == null:
		return false
	var state_info: Dictionary = state_controller.get_current_state_data()
	return bool(state_info.get("parry_active", false))


func _reversal_matches_hit(hit_data: Dictionary) -> bool:
	if reversal_attr.is_empty():
		return true
	var attr: String = reversal_attr.strip_edges().to_lower()
	if attr == "all" or attr == "sca":
		return true
	var is_grapple: bool = bool(hit_data.get("grapple", false)) or str(hit_data.get("attack_type", "")).to_lower() == "grapple"
	var is_projectile: bool = hit_data.get("is_projectile", false)
	if (attr.find("grapple") >= 0 or attr.find("t") >= 0) and is_grapple:
		return true
	if (attr.find("projectile") >= 0 or attr.find("p") >= 0) and is_projectile:
		return true
	var hit_attr: String = str(hit_data.get("attr", hit_data.get("attribute", ""))).to_lower()
	if hit_attr.is_empty():
		return not is_grapple and not is_projectile
	return attr.find(hit_attr) >= 0


func _is_reflect_active() -> bool:
	if state_controller == null:
		return false
	var state_info: Dictionary = state_controller.get_current_state_data()
	return bool(state_info.get("reflect_active", false))


func _is_guarding() -> bool:
	if state_controller == null:
		return false
	var state_info: Dictionary = state_controller.get_current_state_data()
	var can_guard: bool = true
	if state_info.has("can_guard"):
		can_guard = bool(state_info.get("can_guard", true))
	elif state_controller.current_state == "hitstun" or state_controller.current_state == "ko" or state_controller.current_state == "grabbed":
		can_guard = false
	if not can_guard:
		return false
	if bool(state_info.get("guard_active", false)) or state_controller.current_state == "guard":
		return true
	var auto_guard: bool = bool(state_info.get("auto_guard", true))
	return auto_guard and is_holding_back_for_guard()


func is_holding_back_for_guard() -> bool:
	if command_interpreter == null:
		return false
	var raw: Vector2 = command_interpreter.get_latest_raw_direction()
	var facing_right: bool = guard_lock_facing_right if guard_lock_frames_remaining > 0 else command_interpreter.get_facing_right()
	if facing_right:
		return raw.x < -walk_deadzone
	return raw.x > walk_deadzone


func get_guard_stance() -> String:
	if state_controller == null:
		return "stand"
	var state_info: Dictionary = state_controller.get_current_state_data()
	if state_info.has("guard_stance"):
		return str(state_info.get("guard_stance", "stand")).to_lower()
	var state_id: String = state_controller.current_state.to_lower()
	if state_id.find("crouch") != -1:
		return "crouch"
	if not _is_grounded_for_jump():
		return "air"
	return "stand"


func _can_block_hit(hit_data: Dictionary) -> bool:
	if not _is_guarding():
		return false
	if bool(hit_data.get("blockable", true)) == false:
		return false
	var guard_dist: float = float(hit_data.get("guard_dist", hit_data.get("guard", {}).get("dist", runtime_guard_dist)))
	if guard_dist >= 0.0 and opponent != null and is_instance_valid(opponent) and opponent is Node3D:
		var dx: float = absf(global_position.x - (opponent as Node3D).global_position.x)
		if dx > guard_dist * 0.01:
			return false
	var block_requirement: String = str(hit_data.get("block_requirement", hit_data.get("attack_level", "mid"))).to_lower()
	if block_requirement == "unblockable":
		return false
	if block_requirement == "any" or block_requirement == "mid":
		return true

	var stance: String = get_guard_stance()
	if block_requirement == "low":
		return stance == "crouch"
	if block_requirement == "high":
		return stance == "stand" or stance == "air"
	if block_requirement == "air":
		return stance == "air"
	return true


func _apply_jump_and_gravity(delta: float) -> void:
	var gravity: float = default_gravity
	if runtime_gravity_override >= 0.0:
		gravity = runtime_gravity_override
	else:
		gravity = float(physics_data.get("gravity", default_gravity))
	var jump_speed: float = float(physics_data.get("jump_speed", default_jump_speed))
	var max_fall_speed: float = float(physics_data.get("max_fall_speed", 25.0 if smash_mode_enabled else 1000.0))
	var grounded: bool = _is_grounded_for_jump()

	if grounded:
		if juggle_points_used > 0:
			reset_juggle_state()
		if use_floor_y_fallback_grounding and global_position.y < floor_y_level:
			global_position.y = floor_y_level
		if velocity.y < 0.0:
			velocity.y = 0.0
		if accepts_player_movement_input and _can_jump() and InputMap.has_action(jump_action) and Input.is_action_just_pressed(jump_action):
			velocity.y = jump_speed
	else:
		velocity.y -= gravity * delta
		velocity.y = maxf(velocity.y, -max_fall_speed)


func _can_jump() -> bool:
	var state_info: Dictionary = state_controller.get_current_state_data()
	if state_info.has("allow_jump"):
		return bool(state_info["allow_jump"])
	return _state_allows_movement(state_info)


func _is_grounded_for_jump() -> bool:
	if is_on_floor():
		return true
	# Mesh-ground fallback: allow jumping when a surface is directly beneath,
	# even if CharacterBody3D floor flag is not set this frame.
	if velocity.y <= 0.0 and _has_mesh_ground_beneath(0.22):
		return true
	# Optional legacy fallback for flat stages with no proper mesh collision.
	if use_floor_y_fallback_grounding and enforce_floor_clamp and global_position.y <= floor_y_level + 0.05 and velocity.y <= 0.0:
		return true
	return false


func _apply_floor_clamp() -> void:
	if not enforce_floor_clamp:
		return
	if not use_floor_y_fallback_grounding:
		return
	var clamp_y: float = floor_y_level
	if global_position.y < clamp_y:
		var pos := global_position
		pos.y = clamp_y
		global_position = pos
		if velocity.y < 0.0:
			velocity.y = 0.0


func _has_mesh_ground_beneath(max_distance: float = 0.22) -> bool:
	var world := get_world_3d()
	if world == null:
		return false
	var from: Vector3 = global_position + Vector3(0.0, 0.08, 0.0)
	var to: Vector3 = from + Vector3(0.0, -absf(max_distance), 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	return not hit.is_empty()


func _apply_collision_scale() -> void:
	var body_collision := get_node_or_null("BodyCollision") as CollisionShape3D
	if body_collision != null and body_collision.shape is CapsuleShape3D:
		var body_shape := body_collision.shape as CapsuleShape3D
		body_shape.radius = DEFAULT_BODY_RADIUS * collision_scale
		body_shape.height = DEFAULT_BODY_HEIGHT * collision_scale
		body_collision.position.y = DEFAULT_BODY_OFFSET_Y * collision_scale

	if hurtboxes_root != null:
		var hurtbox := hurtboxes_root.get_node_or_null("DefaultHurtbox") as Area3D
		if hurtbox != null:
			hurtbox.position.y = DEFAULT_HURTBOX_OFFSET_Y * collision_scale
			var hurt_shape_node := hurtbox.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if hurt_shape_node != null and hurt_shape_node.shape is CapsuleShape3D:
				var hurt_shape := hurt_shape_node.shape as CapsuleShape3D
				hurt_shape.radius = DEFAULT_HURTBOX_RADIUS * collision_scale
				hurt_shape.height = DEFAULT_HURTBOX_HEIGHT * collision_scale


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


func _configure_persistent_hurtboxes(def_data: Dictionary) -> void:
	if hitbox_system == null:
		return
	var profile: Array = _load_hurtbox_profile_from_def(def_data)
	if profile.is_empty():
		profile = _build_default_bone_hurtbox_profile()
	hitbox_system.set_persistent_hurtboxes(profile)


func _load_hurtbox_profile_from_def(def_data: Dictionary) -> Array:
	if mod_directory.is_empty():
		return []
	var path_key: String = str(def_data.get("hurtboxes_file", "")).strip_edges()
	if path_key.is_empty():
		path_key = str(def_data.get("hurtboxes_path", "")).strip_edges()
	if path_key.is_empty():
		return []
	var resolved_path: String = path_key
	if not resolved_path.begins_with("res://") and not resolved_path.begins_with("user://"):
		resolved_path = "%s%s" % [mod_directory, resolved_path]
	if not FileAccess.file_exists(resolved_path):
		return []
	var file := FileAccess.open(resolved_path, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_ARRAY:
		return parsed as Array
	if typeof(parsed) == TYPE_DICTIONARY:
		var dict: Dictionary = parsed
		var hurtboxes = dict.get("hurtboxes", [])
		if typeof(hurtboxes) == TYPE_ARRAY:
			return hurtboxes as Array
	return []


func _build_default_bone_hurtbox_profile() -> Array:
	var profile: Array = []
	var has_skeleton: bool = skeleton != null and skeleton.get_bone_count() > 0
	if not has_skeleton:
		profile.append({
			"id": "body_core",
			"offset": [0.0, 1.0, 0.0],
			"size": [1.2, 2.2, 1.0]
		})
		return profile
	var torso_bone: String = _find_first_bone_name([
		"spine.003", "spine3", "chest", "torso", "spine_03", "spine2", "spine.002", "spine", "hips"
	])
	var pelvis_bone: String = _find_first_bone_name(["hips", "pelvis", "root"])
	var head_bone: String = _find_first_bone_name(["head", "head.x", "mixamorig:head"])
	var arm_l_bone: String = _find_first_bone_name(["upperarm.l", "arm.l", "leftarm", "mixamorig:leftarm"])
	var arm_r_bone: String = _find_first_bone_name(["upperarm.r", "arm.r", "rightarm", "mixamorig:rightarm"])
	var leg_l_bone: String = _find_first_bone_name(["upperleg.l", "thigh.l", "leftupleg", "mixamorig:leftupleg"])
	var leg_r_bone: String = _find_first_bone_name(["upperleg.r", "thigh.r", "rightupleg", "mixamorig:rightupleg"])
	if not torso_bone.is_empty():
		profile.append({"id": "torso", "bone": torso_bone, "offset": [0.0, 0.0, 0.0], "size": [1.0, 1.1, 0.8]})
	if not pelvis_bone.is_empty():
		profile.append({"id": "pelvis", "bone": pelvis_bone, "offset": [0.0, 0.1, 0.0], "size": [0.9, 0.9, 0.8]})
	if not head_bone.is_empty():
		profile.append({"id": "head", "bone": head_bone, "offset": [0.0, 0.0, 0.0], "size": [0.55, 0.55, 0.55]})
	if not arm_l_bone.is_empty():
		profile.append({"id": "arm_l", "bone": arm_l_bone, "offset": [0.0, -0.15, 0.0], "size": [0.45, 0.75, 0.45]})
	if not arm_r_bone.is_empty():
		profile.append({"id": "arm_r", "bone": arm_r_bone, "offset": [0.0, -0.15, 0.0], "size": [0.45, 0.75, 0.45]})
	if not leg_l_bone.is_empty():
		profile.append({"id": "leg_l", "bone": leg_l_bone, "offset": [0.0, -0.25, 0.0], "size": [0.55, 0.95, 0.55]})
	if not leg_r_bone.is_empty():
		profile.append({"id": "leg_r", "bone": leg_r_bone, "offset": [0.0, -0.25, 0.0], "size": [0.55, 0.95, 0.55]})
	if profile.is_empty():
		profile.append({
			"id": "fallback",
			"offset": [0.0, 1.0, 0.0],
			"size": [1.2, 2.2, 1.0]
		})
	return profile


func _find_first_bone_name(candidates: Array) -> String:
	if skeleton == null:
		return ""
	var lowered_to_actual: Dictionary = {}
	for i in range(skeleton.get_bone_count()):
		var name: String = skeleton.get_bone_name(i)
		lowered_to_actual[name.to_lower()] = name
	for candidate in candidates:
		var key: String = str(candidate).to_lower()
		if lowered_to_actual.has(key):
			return str(lowered_to_actual[key])
	return ""


func play_state_sounds_for_frame(sound_timeline: Array, target_frame: int) -> void:
	if sound_timeline.is_empty():
		return
	for entry in sound_timeline:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var frame: int = int(entry.get("frame", -1))
		if frame != target_frame:
			continue
		var sound_id: String = str(entry.get("id", ""))
		if sound_id.is_empty():
			continue
		var channel: String = str(entry.get("channel", "sfx"))
		play_character_sound(sound_id, channel)


func spawn_projectiles_for_frame(projectile_timeline: Array, target_frame: int) -> void:
	if projectile_system == null or projectile_timeline.is_empty():
		return
	var facing_right: bool = true
	if command_interpreter != null and command_interpreter.has_method("get_facing_right"):
		facing_right = bool(command_interpreter.call("get_facing_right"))
	for entry in projectile_timeline:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var frame: int = int(entry.get("frame", -1))
		if frame != target_frame:
			continue
		var projectile_id: String = str(entry.get("id", ""))
		if projectile_id.is_empty():
			continue
		projectile_system.spawn_projectile(projectile_id, facing_right, global_position)


func play_character_sound(sound_id: String, channel: String = "sfx") -> bool:
	if sound_id.is_empty() or sounds_data.is_empty():
		return false
	var sound_entry = sounds_data.get(sound_id, null)
	if typeof(sound_entry) != TYPE_DICTIONARY:
		return false
	var path: String = str(sound_entry.get("path", ""))
	if path.is_empty():
		return false
	var resolved_path: String = _resolve_mod_resource_path(path)
	var stream: AudioStream = _load_audio_stream(resolved_path)
	if stream == null:
		return false

	_ensure_audio_players()
	var player: AudioStreamPlayer = sfx_player
	if channel == "voice":
		player = voice_player
	if player == null:
		return false

	player.stream = stream
	player.volume_db = float(sound_entry.get("volume_db", 0.0))
	player.pitch_scale = float(sound_entry.get("pitch_scale", 1.0))
	player.bus = str(sound_entry.get("bus", "Master"))
	player.play()
	return true


func _ensure_audio_players() -> void:
	if sfx_player == null:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer"
		add_child(sfx_player)
	if voice_player == null:
		voice_player = AudioStreamPlayer.new()
		voice_player.name = "VoicePlayer"
		add_child(voice_player)


func _resolve_mod_resource_path(raw_path: String) -> String:
	if raw_path.begins_with("res://") or raw_path.begins_with("user://"):
		return raw_path
	if mod_directory.is_empty():
		return raw_path
	return "%s%s" % [mod_directory, raw_path]


func _load_audio_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	var lower := path.to_lower()
	if path.begins_with("res://"):
		var res := ResourceLoader.load(path)
		if res is AudioStream:
			return res as AudioStream
	if not FileAccess.file_exists(path):
		return null
	if lower.ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_file(path)
	if lower.ends_with(".mp3"):
		return AudioStreamMP3.load_from_file(path)
	if lower.ends_with(".wav"):
		return AudioStreamWAV.load_from_file(path)
	return null
