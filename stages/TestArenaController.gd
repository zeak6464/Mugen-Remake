extends Node
class_name TestArenaController

const BOX_EDITOR_SCENE: PackedScene = preload("res://ui/Battle/HITBOX/BoxEditor.tscn")
const CPU_MELEE_RANGE: float = 1.35
const CPU_THROW_RANGE: float = 0.8
const CPU_PROJECTILE_RANGE: float = 3.4
const CPU_APPROACH_RANGE: float = 1.1
const CPU_GUARD_RANGE: float = 2.2
const CPU_PROJECTILE_GUARD_RANGE: float = 7.5
const CPU_VERTICAL_COMMIT_RANGE: float = 1.5
const CPU_ATTACK_COOLDOWN_FRAMES: int = 9
const CPU_COMBO_COOLDOWN_FRAMES: int = 4
const CPU_PROJECTILE_COOLDOWN_FRAMES: int = 18
const CPU_GUARD_HOLD_FRAMES: int = 5

@export var bootstrap_sample_mod: bool = true
@export var sample_mod_name: String = "sample_fighter"
@export var reset_action: StringName = &"round_reset"
@export var toggle_dummy_action: StringName = &"toggle_dummy_control"
@export var reset_key: Key = KEY_F5
@export var replay_key: Key = KEY_R
@export var toggle_dummy_key: Key = KEY_F6
@export var toggle_hitbox_debug_key: Key = KEY_BACKSLASH
@export var toggle_hitbox_debug_key_alt: Key = KEY_F7
@export var toggle_hitbox_edit_key: Key = KEY_BRACKETLEFT
@export var save_hitbox_edit_key: Key = KEY_BRACKETRIGHT
@export var hitbox_offset_step: float = 0.05
@export var hitbox_size_step: float = 0.05
@export var arena_left_limit: float = -30.0
@export var arena_right_limit: float = 30.0
@export var fall_reset_y: float = -8.0
@export var round_time_seconds: int = 99
@export var round_reset_delay_seconds: float = 2.0
@export var round_intro_delay_seconds: float = 1.0
@export var rounds_to_win: int = 2
@export var arcade_match_end_delay_seconds: float = 2.5
@export var match_end_return_delay_seconds: float = 2.0
@export var arcade_post_match_scene_path: String = "res://ui/CharacterSelect.tscn"
@export var training_options_key: Key = KEY_ESCAPE
@export var stage_folder_path: String = "res://stages/Test"
@export var fallback_stage_music_path: String = ""
@export var fallback_music_loop: bool = true
@export var fallback_music_volume_db: float = -6.0
@export var smash_starting_stocks: int = 3
@export var smash_blast_left: float = -32.0
@export var smash_blast_right: float = 32.0
@export var smash_blast_top: float = 22.0
@export var smash_blast_bottom: float = -9.0
@export var smash_respawn_protect_frames: int = 45
@export var smash_offstage_margin: float = 0.25
@export var smash_offstage_min_fall_speed: float = 6.0
@export var simul_ko_remove_delay_seconds: float = 0.8

@onready var fighter_a_fallback: FighterBase = $"../FighterA"
@onready var fighter_b_fallback: FighterBase = $"../FighterB"
@onready var camera_controller: CameraController = $"../CameraController"
@onready var input_buffer_viewer: CanvasLayer = $"../InputBufferViewer"
@onready var battle_hud: CanvasLayer = $"../BattleHUD"
@onready var smash_battle_hud: CanvasLayer = $"../SmashBattleHUD"
@onready var training_options_menu: CanvasLayer = $"../TrainingOptionsMenu"
@onready var team_fighters_root: Node3D = get_node_or_null("../TeamFighters") as Node3D
@onready var stage_root_fallback: Node3D = get_node_or_null("../Stage") as Node3D
@onready var floor_body: StaticBody3D = $"../Floor"

var mod_loader: ModLoader
var input_replay_recorder: InputReplayRecorder
var active_fighter_a: FighterBase = null
var active_fighter_b: FighterBase = null
var training_box_editor_layer: CanvasLayer = null
var training_box_editor: Control = null
var fighter_a_spawn: Vector3 = Vector3(-1.25, 0.0, 0.0)
var fighter_b_spawn: Vector3 = Vector3(1.25, 0.0, 0.0)
var dummy_uses_local_input: bool = false
var camera_default_left_limit: float = -100.0
var camera_default_right_limit: float = 100.0
var show_hitbox_debug: bool = true
var hitbox_edit_mode: bool = false
var hitbox_edit_state_id: String = ""
var hitbox_edit_index: int = 0
var round_number: int = 1
var p1_wins: int = 0
var p2_wins: int = 0
var round_time_left: int = 99
var round_accumulator: float = 0.0
var round_active: bool = false
var round_reset_pending: bool = false
var round_reset_timer: float = 0.0
var replay_playback_active: bool = false
var _last_p2_cpu_frame: Dictionary = {}
var round_intro_pending: bool = false
var round_intro_timer: float = 0.0
var match_over: bool = false
var match_over_timer: float = 0.0
var match_over_return_scene: String = "res://ui/CharacterSelect.tscn"
var tournament_next_match_pending: bool = false
var tournament_next_match_timer: float = 0.0
var record_learned_ai: bool = false
var learned_ai_record_buffer: Array = []
var learned_ai_record_frame_counter: int = 0
var learned_ai_cache: Dictionary = {}
const LEARNED_AI_MAX_SAMPLES: int = 3000
const LEARNED_AI_RECORD_INTERVAL: int = 5
const LEARNED_AI_FILENAME: String = "learned_ai.json"
var status_text: String = "Ready"
var stage_music_player: AudioStreamPlayer = null
var loaded_stage_instance: Node = null
var runtime_stage_environment: WorldEnvironment = null
var runtime_stage_key_light: DirectionalLight3D = null
var fallback_stage_base_position: Vector3 = Vector3.ZERO
var stage_floor_y_level: float = 0.0
var current_stage_def: Dictionary = {}
var camera_base_position: Vector3 = Vector3.ZERO
var camera_base_look_target: Vector3 = Vector3.ZERO
var training_options_open: bool = false
var round_active_before_menu: bool = false
var game_mode: String = "training"
var cpu_enabled: bool = false
var watch_mode_enabled: bool = false
var survival_mode_enabled: bool = false
var team_mode_enabled: bool = false
var team_mode_subtype: String = "simul"
var team_size_p1: int = 2
var team_size_p2: int = 2
var team_roster_p1: Array[Dictionary] = []
var team_roster_p2: Array[Dictionary] = []
var team_fighters_p1: Array[FighterBase] = []
var team_fighters_p2: Array[FighterBase] = []
var team_turns_next_idx_p1: int = 0
var team_turns_next_idx_p2: int = 0
var team_tag_active_idx_p1: int = 0
var team_tag_active_idx_p2: int = 0
var tag_swap_cooldown_frames: int = 0
var simul_ko_retire_timers: Dictionary = {}
var cpu_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var cpu_brains: Dictionary = {}
var smash_mode_enabled: bool = false
var smash_blast_left_default: float = -32.0
var smash_blast_right_default: float = 32.0
var smash_blast_top_default: float = 22.0
var smash_blast_bottom_default: float = -9.0
var p1_stocks: int = 0
var p2_stocks: int = 0
var super_pause_frames_remaining: int = 0


func _ready() -> void:
	cpu_rng.randomize()
	smash_blast_left_default = smash_blast_left
	smash_blast_right_default = smash_blast_right
	smash_blast_top_default = smash_blast_top
	smash_blast_bottom_default = smash_blast_bottom
	if stage_root_fallback != null:
		fallback_stage_base_position = stage_root_fallback.position
	if camera_controller != null:
		camera_base_position = camera_controller.global_position
		camera_base_look_target = camera_controller.look_target
	call_deferred("_initialize_arena")


func _physics_process(_delta: float) -> void:
	if super_pause_frames_remaining > 0:
		super_pause_frames_remaining -= 1
		return
	if tag_swap_cooldown_frames > 0:
		tag_swap_cooldown_frames -= 1
	if replay_playback_active:
		var frame_data: Dictionary = input_replay_recorder.get_playback_frame() if input_replay_recorder != null else {}
		if frame_data.is_empty():
			_end_replay()
		else:
			var p1: Dictionary = frame_data.get("p1", {})
			var p2: Dictionary = frame_data.get("p2", {})
			if active_fighter_a != null and active_fighter_a.command_interpreter != null:
				active_fighter_a.command_interpreter.enqueue_external_input(
					p1.get("direction", Vector2.ZERO),
					_to_string_array(p1.get("pressed", [])),
					_to_string_array(p1.get("held", [])),
					_to_string_array(p1.get("released", []))
				)
			if active_fighter_b != null and active_fighter_b.command_interpreter != null:
				active_fighter_b.command_interpreter.enqueue_external_input(
					p2.get("direction", Vector2.ZERO),
					_to_string_array(p2.get("pressed", [])),
					_to_string_array(p2.get("held", [])),
					_to_string_array(p2.get("released", []))
				)
			input_replay_recorder.advance_playback()
	else:
		_last_p2_cpu_frame = {}
		if game_mode == "online":
			_update_online_input()
		else:
			_update_cpu_input()
		if input_replay_recorder != null and input_replay_recorder.is_recording() and round_active:
			var p1_in: Dictionary = _read_player_input(1)
			var p2_in: Dictionary
			if dummy_uses_local_input:
				p2_in = _read_player_input(2)
			elif cpu_enabled and not team_mode_enabled:
				p2_in = _last_p2_cpu_frame
			else:
				p2_in = {"direction": Vector2.ZERO, "pressed": [], "held": [], "released": []}
			input_replay_recorder.record_frame(p1_in, p2_in)
		if record_learned_ai and (game_mode == "training" or game_mode == "cpu_training") and round_active and active_fighter_a != null and active_fighter_b != null:
			var mod_dir: String = active_fighter_a.get_mod_directory()
			if not mod_dir.is_empty():
				learned_ai_record_frame_counter += 1
				if learned_ai_record_frame_counter >= LEARNED_AI_RECORD_INTERVAL:
					learned_ai_record_frame_counter = 0
					var state: Array = _learned_ai_state_vector(active_fighter_a, active_fighter_b)
					var action: Dictionary = _read_player_input(1)
					var pa: Vector3 = active_fighter_a.global_position
					var pb: Vector3 = active_fighter_b.global_position
					learned_ai_record_buffer.append({
						"s": state,
						"a": _learned_ai_action_to_serializable(action),
						"m": {"rel_x": pb.x - pa.x, "rel_y": pb.y - pa.y}
					})
	_enforce_arena_bounds()
	_resolve_fighter_pushbox()


func request_super_pause(time_ticks: int) -> void:
	super_pause_frames_remaining = maxi(super_pause_frames_remaining, maxi(1, time_ticks))


func _process(delta: float) -> void:
	if training_options_open:
		_update_hud()
		return
	if super_pause_frames_remaining > 0:
		_update_hud()
		return
	_update_simul_ko_retire(delta)
	_update_round_logic(delta)
	_update_hud()


func _initialize_arena() -> void:
	SystemSFX.stop_menu_music_from(self)
	game_mode = str(get_tree().get_meta("game_mode", "training")).to_lower()
	if game_mode != "arcade" and game_mode != "versus" and game_mode != "smash" and game_mode != "team" and game_mode != "survival" and game_mode != "watch" and game_mode != "online" and game_mode != "coop" and game_mode != "tournament" and game_mode != "cpu_training":
		game_mode = "training"
	watch_mode_enabled = game_mode == "watch"
	survival_mode_enabled = game_mode == "survival"
	team_mode_enabled = game_mode == "team" or game_mode == "coop"
	var watch_match_type: String = str(get_tree().get_meta("watch_match_type", "")).to_lower() if watch_mode_enabled else ""
	if watch_mode_enabled and watch_match_type == "team":
		team_mode_enabled = true
	team_mode_subtype = str(get_tree().get_meta("team_mode_subtype", "simul")).to_lower()
	if team_mode_subtype != "simul" and team_mode_subtype != "turns" and team_mode_subtype != "tag":
		team_mode_subtype = "simul"
	team_size_p1 = clampi(int(get_tree().get_meta("team_size_p1", 2)), 2, 4)
	team_size_p2 = clampi(int(get_tree().get_meta("team_size_p2", 2)), 2, 4)
	smash_mode_enabled = game_mode == "smash" or (watch_mode_enabled and watch_match_type == "smash")
	rounds_to_win = clampi(int(get_tree().get_meta("option_rounds_to_win", rounds_to_win)), 1, 99)
	round_time_seconds = clampi(int(get_tree().get_meta("option_round_time_seconds", round_time_seconds)), 0, 999)
	smash_starting_stocks = clampi(int(get_tree().get_meta("option_smash_stocks", smash_starting_stocks)), 1, 99)
	_apply_game_options()
	_apply_hud_mode()
	cpu_enabled = game_mode == "arcade" or survival_mode_enabled or watch_mode_enabled or game_mode == "coop" or game_mode == "tournament" or (game_mode == "cpu_training" and str(get_tree().get_meta("cpu_training_opponent", "player")).to_lower() == "cpu")
	dummy_uses_local_input = game_mode == "versus" or game_mode == "smash" or team_mode_enabled or (game_mode == "cpu_training" and str(get_tree().get_meta("cpu_training_opponent", "player")).to_lower() != "cpu")
	if game_mode == "cpu_training":
		record_learned_ai = true

	mod_loader = ModLoader.new()
	mod_loader.name = "ModLoader"
	add_child(mod_loader)
	input_replay_recorder = InputReplayRecorder.new()
	input_replay_recorder.name = "InputReplayRecorder"
	add_child(input_replay_recorder)
	_apply_selected_stage()
	_apply_stage_configuration()
	_setup_stage_music()
	if camera_controller != null:
		camera_default_left_limit = camera_controller.stage_left_limit
		camera_default_right_limit = camera_controller.stage_right_limit

	if bootstrap_sample_mod:
		_bootstrap_bundled_content()

	var mods: Array[Dictionary] = mod_loader.scan_mods()
	team_roster_p1 = _read_team_roster_meta("team_roster_p1", team_size_p1)
	team_roster_p2 = _read_team_roster_meta("team_roster_p2", team_size_p2)
	var selected_mod_a: String = str(get_tree().get_meta("training_p1_mod", ""))
	var selected_mod_b: String = str(get_tree().get_meta("training_p2_mod", ""))
	var selected_form_a: String = str(get_tree().get_meta("training_p1_form", ""))
	var selected_form_b: String = str(get_tree().get_meta("training_p2_form", ""))
	var selected_costume_a: String = str(get_tree().get_meta("training_p1_costume", ""))
	var selected_costume_b: String = str(get_tree().get_meta("training_p2_costume", ""))
	if game_mode == "tournament":
		var entrants: Array = get_tree().get_meta("tournament_entrants", [])
		var match_idx: int = int(get_tree().get_meta("tournament_match_index", 0))
		var round_results: Array = get_tree().get_meta("tournament_round_results", [])
		var n: int = entrants.size()
		var indices: Array = _tournament_get_opponents(n, match_idx, round_results)
		if indices.size() >= 2:
			var left_idx: int = int(indices[0])
			var right_idx: int = int(indices[1])
			if left_idx >= 0 and right_idx >= 0 and entrants.size() > left_idx and entrants.size() > right_idx:
				var le: Dictionary = entrants[left_idx]
				var re: Dictionary = entrants[right_idx]
				selected_mod_a = str(le.get("mod", ""))
				selected_mod_b = str(re.get("mod", ""))
				selected_form_a = str(le.get("form", ""))
				selected_form_b = str(re.get("form", ""))
				selected_costume_a = str(le.get("costume", ""))
				selected_costume_b = str(re.get("costume", ""))
	if team_mode_enabled and not team_roster_p1.is_empty() and not team_roster_p2.is_empty():
		_spawn_team_mode_fighters()
	elif not selected_mod_a.is_empty():
		if selected_mod_b.is_empty():
			selected_mod_b = selected_mod_a
		_spawn_mod_fighters(selected_mod_a, selected_mod_b, selected_form_a, selected_form_b, selected_costume_a, selected_costume_b)
	elif mods.size() >= 2:
		_spawn_mod_fighters(mods[0]["name"], mods[1]["name"])
	elif mods.size() == 1:
		_spawn_mod_fighters(mods[0]["name"], mods[0]["name"])
	else:
		_apply_runtime_links(fighter_a_fallback, fighter_b_fallback)
	_apply_input_buffer_setting()
	_setup_training_options_menu()
	if game_mode == "online" and NetworkManager.is_online_session() and NetworkManager.is_host():
		NetworkManager.start_match(randi())


func _spawn_mod_fighters(mod_a_name: String, mod_b_name: String, form_a: String = "", form_b: String = "", costume_a: String = "", costume_b: String = "") -> void:
	var fighter_a := mod_loader.load_character(mod_a_name, get_parent())
	var fighter_b := mod_loader.load_character(mod_b_name, get_parent())
	if fighter_a == null or fighter_b == null:
		_apply_runtime_links(fighter_a_fallback, fighter_b_fallback)
		return

	fighter_a.name = "FighterA"
	fighter_b.name = "FighterB"
	fighter_a.global_position = fighter_a_spawn
	fighter_b.global_position = fighter_b_spawn
	fighter_a.lock_to_z_axis = true
	fighter_b.lock_to_z_axis = true
	fighter_a.locked_z_position = 0.0
	fighter_b.locked_z_position = 0.0

	if fighter_a_fallback != null and fighter_a_fallback != fighter_a:
		fighter_a_fallback.queue_free()
	if fighter_b_fallback != null and fighter_b_fallback != fighter_b:
		fighter_b_fallback.queue_free()

	_apply_runtime_links(fighter_a, fighter_b)
	if not form_a.is_empty():
		fighter_a.apply_start_form(form_a)
	if not form_b.is_empty():
		fighter_b.apply_start_form(form_b)
	if not costume_a.is_empty():
		fighter_a.apply_start_costume(costume_a)
	if not costume_b.is_empty():
		fighter_b.apply_start_costume(costume_b)


func _read_team_roster_meta(meta_key: String, team_size: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var raw_value = get_tree().get_meta(meta_key, [])
	if typeof(raw_value) != TYPE_ARRAY:
		return out
	var raw_array: Array = raw_value
	for item in raw_array:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = item
		var mod_name: String = str(entry.get("mod", "")).strip_edges()
		if mod_name.is_empty():
			continue
		out.append(
			{
				"mod": mod_name,
				"form": str(entry.get("form", "")),
				"costume": str(entry.get("costume", ""))
			}
		)
		if out.size() >= team_size:
			break
	return out


func _apply_game_options() -> void:
	var tree := get_tree()
	var scale_val: float = float(tree.get_meta("option_game_speed_scale", 1.0))
	if scale_val <= 0.0:
		var cfg := ConfigFile.new()
		if cfg.load("user://options.cfg") == OK:
			scale_val = float(cfg.get_value("gameplay", "game_speed_scale", 1.0))
		if scale_val <= 0.0:
			scale_val = 1.0
	Engine.time_scale = scale_val


func _apply_life_percent_to_fighter(fighter: FighterBase) -> void:
	if fighter == null or not is_instance_valid(fighter):
		return
	var tree := get_tree()
	var life_percent: float = float(tree.get_meta("option_life_percent", 100.0))
	if life_percent <= 0.0:
		var cfg := ConfigFile.new()
		if cfg.load("user://options.cfg") == OK:
			life_percent = float(cfg.get_value("gameplay", "life_percent", 100.0))
		if life_percent <= 0.0:
			life_percent = 100.0
	if life_percent >= 99.0 and life_percent <= 101.0:
		return
	var scale: float = life_percent / 100.0
	fighter.max_health = maxi(1, int(fighter.max_health * scale))
	fighter.set_health(fighter.max_health)


func _clear_team_mode_runtime() -> void:
	for fighter in team_fighters_p1:
		if fighter != null and is_instance_valid(fighter) and fighter != active_fighter_a and fighter != active_fighter_b:
			fighter.queue_free()
	for fighter in team_fighters_p2:
		if fighter != null and is_instance_valid(fighter) and fighter != active_fighter_a and fighter != active_fighter_b:
			fighter.queue_free()
	team_fighters_p1.clear()
	team_fighters_p2.clear()
	team_turns_next_idx_p1 = 0
	team_turns_next_idx_p2 = 0
	team_tag_active_idx_p1 = 0
	team_tag_active_idx_p2 = 0
	tag_swap_cooldown_frames = 0
	simul_ko_retire_timers.clear()


func _spawn_team_mode_fighters() -> void:
	_clear_team_mode_runtime()
	if team_roster_p1.is_empty() or team_roster_p2.is_empty():
		return
	if team_mode_subtype == "simul":
		for i in range(team_roster_p1.size()):
			var fighter_p1: FighterBase = _instantiate_team_fighter(team_roster_p1[i], true, i)
			if fighter_p1 != null:
				team_fighters_p1.append(fighter_p1)
		for j in range(team_roster_p2.size()):
			var fighter_p2: FighterBase = _instantiate_team_fighter(team_roster_p2[j], false, j)
			if fighter_p2 != null:
				team_fighters_p2.append(fighter_p2)
		if team_fighters_p1.is_empty() or team_fighters_p2.is_empty():
			return
		_apply_runtime_links(team_fighters_p1[0], team_fighters_p2[0])
		for fighter in team_fighters_p1:
			fighter.set_opponent(team_fighters_p2[0])
		for fighter in team_fighters_p2:
			fighter.set_opponent(team_fighters_p1[0])
		_apply_team_control_modes()
		return

	var first_p1: FighterBase = _instantiate_team_fighter(team_roster_p1[0], true, 0)
	var first_p2: FighterBase = _instantiate_team_fighter(team_roster_p2[0], false, 0)
	if first_p1 == null or first_p2 == null:
		return
	team_fighters_p1.append(first_p1)
	team_fighters_p2.append(first_p2)
	team_turns_next_idx_p1 = 1
	team_turns_next_idx_p2 = 1
	team_tag_active_idx_p1 = 0
	team_tag_active_idx_p2 = 0
	_apply_runtime_links(first_p1, first_p2)


func _instantiate_team_fighter(entry: Dictionary, is_p1: bool, slot_idx: int) -> FighterBase:
	if mod_loader == null:
		return null
	var parent_node: Node = team_fighters_root if team_fighters_root != null else get_parent()
	var fighter: FighterBase = mod_loader.load_character(str(entry.get("mod", "")), parent_node)
	if fighter == null:
		return null
	fighter.name = "Team%s_%d" % ["A" if is_p1 else "B", slot_idx]
	fighter.team_id = 1 if is_p1 else 2
	fighter.team_slot = slot_idx
	fighter.is_active_tag_fighter = true
	var spawn: Vector3 = _team_spawn_position(is_p1, slot_idx)
	fighter.global_position = spawn
	fighter.lock_to_z_axis = true
	fighter.locked_z_position = 0.0
	fighter.floor_y_level = stage_floor_y_level
	fighter.use_floor_y_fallback_grounding = false
	if str(entry.get("form", "")).strip_edges() != "":
		fighter.apply_start_form(str(entry.get("form", "")))
	if str(entry.get("costume", "")).strip_edges() != "":
		fighter.apply_start_costume(str(entry.get("costume", "")))
	if entry.has("saved_health"):
		fighter.set_health(mini(fighter.max_health, maxi(1, int(entry.get("saved_health", fighter.max_health)))))
	if entry.has("saved_resource"):
		fighter.set_resource(clampi(int(entry.get("saved_resource", fighter.resource)), 0, fighter.max_resource))
	if fighter.command_interpreter != null:
		if is_p1:
			fighter.jump_action = &"p1_up"
			fighter.command_interpreter.action_up = &"p1_up"
			fighter.command_interpreter.action_down = &"p1_down"
			fighter.command_interpreter.action_left = &"p1_left"
			fighter.command_interpreter.action_right = &"p1_right"
			fighter.command_interpreter.button_actions = {"P": &"p1_p", "K": &"p1_k", "S": &"p1_s", "H": &"p1_h"}
		else:
			fighter.jump_action = &"p2_up"
			fighter.command_interpreter.action_up = &"p2_up"
			fighter.command_interpreter.action_down = &"p2_down"
			fighter.command_interpreter.action_left = &"p2_left"
			fighter.command_interpreter.action_right = &"p2_right"
			fighter.command_interpreter.button_actions = {"P": &"p2_p", "K": &"p2_k", "S": &"p2_s", "H": &"p2_h"}
	_apply_life_percent_to_fighter(fighter)
	return fighter


func _team_spawn_position(is_p1: bool, slot_idx: int) -> Vector3:
	var base: Vector3 = fighter_a_spawn if is_p1 else fighter_b_spawn
	var spread: float = 0.85
	var centered: float = float(slot_idx) - 1.5
	var offset_x: float = centered * spread
	if is_p1:
		offset_x -= 0.6
	else:
		offset_x += 0.6
	return Vector3(base.x + offset_x, base.y, 0.0)


func _apply_runtime_links(fighter_a: FighterBase, fighter_b: FighterBase) -> void:
	active_fighter_a = fighter_a
	active_fighter_b = fighter_b

	fighter_a.global_position = fighter_a_spawn
	fighter_b.global_position = fighter_b_spawn
	fighter_a.floor_y_level = stage_floor_y_level
	fighter_b.floor_y_level = stage_floor_y_level
	fighter_a.use_floor_y_fallback_grounding = false
	fighter_b.use_floor_y_fallback_grounding = false
	fighter_a.set_opponent(fighter_b)
	fighter_b.set_opponent(fighter_a)
	_apply_life_percent_to_fighter(fighter_a)
	_apply_life_percent_to_fighter(fighter_b)
	if team_mode_enabled:
		for f in team_fighters_p1:
			if f != null and is_instance_valid(f):
				_apply_life_percent_to_fighter(f)
		for f in team_fighters_p2:
			if f != null and is_instance_valid(f):
				_apply_life_percent_to_fighter(f)
	_configure_smash_mode_for_fighters()
	_configure_player_input_bindings()
	_apply_control_modes()

	if camera_controller != null:
		camera_controller.fighter_a_path = camera_controller.get_path_to(fighter_a)
		camera_controller.fighter_b_path = camera_controller.get_path_to(fighter_b)
		_refresh_camera_tracked_fighters()
	if input_buffer_viewer != null:
		input_buffer_viewer.target_fighter_path = input_buffer_viewer.get_path_to(fighter_a)
	_apply_hitbox_debug_state()
	call_deferred("_apply_hitbox_debug_state")
	var replay_path: String = get_tree().get_meta("replay_path", "")
	if not replay_path.is_empty() and get_tree().get_meta("replay_mode", false):
		_start_replay_from_file(replay_path)
	else:
		_start_round()


func _input(event: InputEvent) -> void:
	if team_mode_enabled and team_mode_subtype == "tag":
		if _is_tag_action_pressed(event, true):
			_try_tag_swap(true)
			get_viewport().set_input_as_handled()
			return
		if _is_tag_action_pressed(event, false):
			_try_tag_swap(false)
			get_viewport().set_input_as_handled()
			return
	if _is_key_pressed(event, training_options_key):
		_toggle_training_options_menu()
		return
	if training_options_open:
		return
	if round_reset_pending and not replay_playback_active and _is_key_pressed(event, replay_key):
		if dummy_uses_local_input and input_replay_recorder != null and input_replay_recorder.get_recorded_frame_count() > 0:
			_start_replay()
			get_viewport().set_input_as_handled()
			return
	if _is_action_or_key_pressed(event, reset_action, reset_key):
		_reset_round()
	elif _is_action_or_key_pressed(event, toggle_dummy_action, toggle_dummy_key):
		_toggle_dummy_control()
	elif _is_key_pressed(event, toggle_hitbox_debug_key) or _is_key_pressed(event, toggle_hitbox_debug_key_alt):
		show_hitbox_debug = not show_hitbox_debug
		_apply_hitbox_debug_state()
	elif _is_key_pressed(event, toggle_hitbox_edit_key):
		hitbox_edit_mode = not hitbox_edit_mode
		_sync_hitbox_editor_target()
	elif hitbox_edit_mode:
		_handle_hitbox_editor_input(event)


func _is_tag_action_pressed(event: InputEvent, is_p1: bool) -> bool:
	if not (event is InputEvent):
		return false
	var tag_action: StringName = &"p1_tag" if is_p1 else &"p2_tag"
	if InputMap.has_action(tag_action) and event.is_action_pressed(tag_action):
		return true
	# Backward compatibility with older configs that used the S button.
	var fallback_action: StringName = &"p1_s" if is_p1 else &"p2_s"
	if not InputMap.has_action(fallback_action):
		return false
	return event.is_action_pressed(fallback_action)


func _setup_training_options_menu() -> void:
	if training_options_menu == null:
		return
	training_options_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_training_options_menu_state()
	training_options_menu.call("hide_menu")
	if training_options_menu.has_signal("resume_requested"):
		training_options_menu.resume_requested.connect(_on_training_resume_requested)
	if training_options_menu.has_signal("exit_requested"):
		training_options_menu.exit_requested.connect(_on_pause_exit_requested)
	if training_options_menu.has_signal("reset_round_requested"):
		training_options_menu.reset_round_requested.connect(_on_training_reset_round_requested)
	if training_options_menu.has_signal("toggle_dummy_requested"):
		training_options_menu.toggle_dummy_requested.connect(_on_training_toggle_dummy_requested)
	if training_options_menu.has_signal("toggle_hitbox_requested"):
		training_options_menu.toggle_hitbox_requested.connect(_on_training_toggle_hitbox_requested)
	if training_options_menu.has_signal("open_hitbox_editor_requested"):
		training_options_menu.open_hitbox_editor_requested.connect(_on_training_open_hitbox_editor_requested)
	if training_options_menu.has_signal("return_to_menu_requested"):
		training_options_menu.return_to_menu_requested.connect(_on_training_return_to_menu_requested)
	if training_options_menu.has_signal("record_learned_ai_requested"):
		training_options_menu.record_learned_ai_requested.connect(_on_record_learned_ai_requested)


func _toggle_training_options_menu() -> void:
	if _is_training_box_editor_open():
		_close_training_box_editor_overlay()
		return
	if training_options_open:
		_set_training_options_visible(false)
	else:
		_set_training_options_visible(true)


func _set_training_options_visible(visible_value: bool) -> void:
	training_options_open = visible_value
	if training_options_menu == null:
		return
	if visible_value:
		round_active_before_menu = round_active
		round_active = false
		_set_training_inputs_enabled(false)
		get_tree().paused = true
		_refresh_training_options_menu_state()
		training_options_menu.call("show_menu")
	else:
		get_tree().paused = false
		if record_learned_ai:
			_learned_ai_flush_record_buffer()
		_close_training_box_editor_overlay(false)
		training_options_menu.call("hide_menu")
		if not round_reset_pending:
			round_active = round_active_before_menu
		_set_training_inputs_enabled(true)


func _set_training_inputs_enabled(enabled: bool) -> void:
	var should_enable: bool = enabled and round_active and not round_intro_pending and not match_over
	if active_fighter_a != null:
		active_fighter_a.command_interpreter.read_local_input = should_enable
		active_fighter_a.accepts_player_movement_input = should_enable
	if active_fighter_b != null:
		if cpu_enabled:
			active_fighter_b.command_interpreter.read_local_input = false
			active_fighter_b.accepts_player_movement_input = should_enable
		elif game_mode == "versus" or game_mode == "smash":
			active_fighter_b.command_interpreter.read_local_input = should_enable
			active_fighter_b.accepts_player_movement_input = should_enable
		elif dummy_uses_local_input:
			active_fighter_b.command_interpreter.read_local_input = should_enable
			active_fighter_b.accepts_player_movement_input = should_enable
		else:
			active_fighter_b.command_interpreter.read_local_input = false
			active_fighter_b.accepts_player_movement_input = false


func _on_training_resume_requested() -> void:
	_set_training_options_visible(false)


func _on_training_reset_round_requested() -> void:
	_set_training_options_visible(false)
	_reset_round()


func _on_training_toggle_dummy_requested() -> void:
	_toggle_dummy_control()
	_refresh_training_options_menu_state()


func _on_training_toggle_hitbox_requested() -> void:
	show_hitbox_debug = not show_hitbox_debug
	_apply_hitbox_debug_state()
	_refresh_training_options_menu_state()


func _on_record_learned_ai_requested(enabled: bool) -> void:
	record_learned_ai = enabled


func _on_training_open_hitbox_editor_requested() -> void:
	if game_mode != "training" and game_mode != "cpu_training":
		return
	_ensure_training_box_editor()
	_sync_training_box_editor_target()
	if training_options_menu != null:
		training_options_menu.call("hide_menu")
	if training_box_editor_layer != null:
		training_box_editor_layer.visible = true


func _on_training_return_to_menu_requested() -> void:
	if record_learned_ai:
		_learned_ai_flush_record_buffer()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")


func _refresh_training_options_menu_state() -> void:
	if training_options_menu == null:
		return
	training_options_menu.call("set_menu_state", game_mode == "training" or game_mode == "cpu_training", dummy_uses_local_input, show_hitbox_debug, record_learned_ai)
	training_options_menu.call("set_move_list_text", _build_pause_move_list_text())


func _ensure_training_box_editor() -> void:
	if training_box_editor != null and is_instance_valid(training_box_editor):
		return
	training_box_editor_layer = CanvasLayer.new()
	training_box_editor_layer.name = "TrainingBoxEditorLayer"
	training_box_editor_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	training_box_editor_layer.visible = false
	get_parent().add_child(training_box_editor_layer)
	var instance: Node = BOX_EDITOR_SCENE.instantiate()
	if not (instance is Control):
		if instance != null:
			instance.queue_free()
		return
	training_box_editor = instance as Control
	training_box_editor.process_mode = Node.PROCESS_MODE_ALWAYS
	training_box_editor_layer.add_child(training_box_editor)
	if training_box_editor.has_method("set_embedded_mode"):
		training_box_editor.call("set_embedded_mode", true)
	if training_box_editor.has_signal("embedded_close_requested"):
		training_box_editor.embedded_close_requested.connect(_on_training_box_editor_close_requested)
	if training_box_editor.has_signal("box_data_applied"):
		training_box_editor.box_data_applied.connect(_on_training_box_editor_data_applied)


func _sync_training_box_editor_target() -> void:
	if training_box_editor == null or not is_instance_valid(training_box_editor):
		return
	if active_fighter_a == null:
		return
	var mod_name: String = _derive_mod_name_from_path(active_fighter_a.get_mod_directory())
	if not mod_name.is_empty() and training_box_editor.has_method("select_mod_by_name"):
		training_box_editor.call("select_mod_by_name", mod_name)
	if training_box_editor.has_method("select_box_type_by_key"):
		training_box_editor.call("select_box_type_by_key", "hitboxes")
	var state_id: String = active_fighter_a.state_controller.current_state if active_fighter_a.state_controller != null else ""
	if state_id.is_empty():
		state_id = "idle"
	if training_box_editor.has_method("select_state_by_name"):
		training_box_editor.call("select_state_by_name", state_id, "hitboxes")


func _derive_mod_name_from_path(path: String) -> String:
	var trimmed: String = path.strip_edges().trim_suffix("/")
	if trimmed.is_empty():
		return ""
	var parts: PackedStringArray = trimmed.split("/")
	return parts[parts.size() - 1] if not parts.is_empty() else ""


func _is_training_box_editor_open() -> bool:
	return training_box_editor_layer != null and is_instance_valid(training_box_editor_layer) and training_box_editor_layer.visible


func _close_training_box_editor_overlay(show_training_menu: bool = true) -> void:
	if training_box_editor_layer != null and is_instance_valid(training_box_editor_layer):
		training_box_editor_layer.visible = false
	if show_training_menu and training_options_open and training_options_menu != null:
		_refresh_training_options_menu_state()
		training_options_menu.call("show_menu")


func _on_training_box_editor_close_requested() -> void:
	_close_training_box_editor_overlay()


func _on_training_box_editor_data_applied(states_data: Dictionary, persistent_hurtboxes: Array) -> void:
	if active_fighter_a == null:
		return
	var states_copy: Dictionary = states_data.duplicate(true)
	active_fighter_a.state_data = states_copy
	active_fighter_a.base_state_data = states_copy.duplicate(true)
	active_fighter_a.character_data["states"] = states_copy.duplicate(true)
	if active_fighter_a.state_controller != null:
		active_fighter_a.state_controller.set_states_data(states_copy)
	if persistent_hurtboxes.is_empty():
		if active_fighter_a.has_method("_configure_persistent_hurtboxes"):
			active_fighter_a.call("_configure_persistent_hurtboxes", active_fighter_a.character_data.get("def", {}))
	else:
		if active_fighter_a.hitbox_system != null and active_fighter_a.hitbox_system.has_method("set_persistent_hurtboxes"):
			active_fighter_a.hitbox_system.call("set_persistent_hurtboxes", persistent_hurtboxes.duplicate(true))
		active_fighter_a.persistent_debug_hurtbox_profile = persistent_hurtboxes.duplicate(true)
	_apply_hitbox_debug_state()


func _on_pause_button_config_requested() -> void:
	# Kept for backwards compatibility; pause menu now opens embedded Controls UI.
	pass


func _on_pause_exit_requested(target_scene: String) -> void:
	var destination: String = target_scene.strip_edges()
	if destination.is_empty():
		destination = "res://ui/MainMenu.tscn"
	_set_training_options_visible(false)
	get_tree().paused = false
	get_tree().change_scene_to_file(destination)


func _reset_round() -> void:
	if active_fighter_a == null or active_fighter_b == null:
		return
	simul_ko_retire_timers.clear()
	if team_mode_enabled and team_mode_subtype == "simul":
		for i in range(team_fighters_p1.size()):
			var fighter_p1: FighterBase = team_fighters_p1[i]
			if fighter_p1 != null and is_instance_valid(fighter_p1):
				_reset_fighter(fighter_p1, _team_spawn_position(true, i))
		for j in range(team_fighters_p2.size()):
			var fighter_p2: FighterBase = team_fighters_p2[j]
			if fighter_p2 != null and is_instance_valid(fighter_p2):
				_reset_fighter(fighter_p2, _team_spawn_position(false, j))
		if not team_fighters_p1.is_empty() and not team_fighters_p2.is_empty():
			active_fighter_a = team_fighters_p1[0]
			active_fighter_b = team_fighters_p2[0]
			for fighter in team_fighters_p1:
				if fighter != null and is_instance_valid(fighter):
					fighter.set_opponent(active_fighter_b)
			for fighter in team_fighters_p2:
				if fighter != null and is_instance_valid(fighter):
					fighter.set_opponent(active_fighter_a)
		_start_round()
		return
	if smash_mode_enabled:
		p1_stocks = maxi(1, smash_starting_stocks)
		p2_stocks = maxi(1, smash_starting_stocks)
	_reset_fighter(active_fighter_a, fighter_a_spawn)
	_reset_fighter(active_fighter_b, fighter_b_spawn)
	active_fighter_a.set_opponent(active_fighter_b)
	active_fighter_b.set_opponent(active_fighter_a)
	_start_round()


func _reset_fighter(fighter: FighterBase, spawn_position: Vector3) -> void:
	fighter.set_health(fighter.max_health)
	fighter.reset_smash_state()
	fighter.enforce_floor_clamp = true
	fighter.use_floor_y_fallback_grounding = false
	fighter.visible = true
	fighter.set_process(true)
	fighter.set_physics_process(true)
	fighter.global_position = spawn_position
	fighter.velocity = Vector3.ZERO
	var initial_state := _get_initial_state(fighter)
	if not initial_state.is_empty():
		fighter.state_controller.change_state(initial_state)


func _start_replay_from_file(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		status_text = "Replay file not found."
		_start_round()
		return
	var json_text: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed == null:
		status_text = "Invalid replay file."
		_start_round()
		return
	var frames_data: Array = []
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("frames"):
		frames_data = parsed.get("frames", [])
	elif typeof(parsed) == TYPE_ARRAY:
		frames_data = parsed
	else:
		status_text = "Invalid replay file."
		_start_round()
		return
	if input_replay_recorder == null:
		_start_round()
		return
	input_replay_recorder.from_serializable(frames_data)
	if input_replay_recorder.get_playback_length() <= 0:
		status_text = "Replay has no frames."
		_start_round()
		return
	replay_playback_active = true
	round_active = true
	round_intro_pending = false
	round_reset_pending = false
	round_reset_timer = 0.0
	round_time_left = round_time_seconds
	round_accumulator = 0.0
	status_text = "Replay"
	get_tree().set_meta("replay_return_scene", "res://ui/ReplaySelect.tscn")
	if active_fighter_a != null and active_fighter_a.command_interpreter != null:
		active_fighter_a.command_interpreter.clear_external_input_queue()
		active_fighter_a.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
		active_fighter_a.command_interpreter.read_local_input = false
	if active_fighter_b != null and active_fighter_b.command_interpreter != null:
		active_fighter_b.command_interpreter.clear_external_input_queue()
		active_fighter_b.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
		active_fighter_b.command_interpreter.read_local_input = false


func _start_replay() -> void:
	if input_replay_recorder == null or input_replay_recorder.get_recorded_frame_count() <= 0:
		return
	input_replay_recorder.set_playback_data(input_replay_recorder.get_recorded_frames())
	_reset_round_for_replay()
	replay_playback_active = true
	round_reset_pending = false
	round_reset_timer = 0.0
	status_text = "Replay"
	if active_fighter_a != null and active_fighter_a.command_interpreter != null:
		active_fighter_a.command_interpreter.clear_external_input_queue()
		active_fighter_a.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
		active_fighter_a.command_interpreter.read_local_input = false
	if active_fighter_b != null and active_fighter_b.command_interpreter != null:
		active_fighter_b.command_interpreter.clear_external_input_queue()
		active_fighter_b.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
		active_fighter_b.command_interpreter.read_local_input = false


func _reset_round_for_replay() -> void:
	if active_fighter_a == null or active_fighter_b == null:
		return
	if smash_mode_enabled:
		p1_stocks = maxi(1, smash_starting_stocks)
		p2_stocks = maxi(1, smash_starting_stocks)
	_reset_fighter(active_fighter_a, fighter_a_spawn)
	_reset_fighter(active_fighter_b, fighter_b_spawn)
	_clear_fighter_projectiles(active_fighter_a)
	_clear_fighter_projectiles(active_fighter_b)
	active_fighter_a.set_opponent(active_fighter_b)
	active_fighter_b.set_opponent(active_fighter_a)
	round_time_left = round_time_seconds
	round_accumulator = 0.0
	round_active = true
	round_intro_pending = false
	_restore_camera_targets_for_round()
	_refresh_camera_tracked_fighters()
	_set_fighter_input_enabled(false)


func _clear_fighter_projectiles(fighter: FighterBase) -> void:
	if fighter == null:
		return
	var ps = fighter.projectile_system
	if ps != null and ps.has_method("clear_active_projectiles"):
		ps.clear_active_projectiles()


func _end_replay() -> void:
	replay_playback_active = false
	round_active = false
	status_text = "Replay ended"
	var file_replay: bool = not get_tree().get_meta("replay_path", "").is_empty()
	if file_replay:
		round_reset_pending = false
		round_reset_timer = 0.0
		match_over = true
		match_over_return_scene = get_tree().get_meta("replay_return_scene", "res://ui/ReplaySelect.tscn")
		match_over_timer = 2.0
	else:
		round_reset_pending = true
		round_reset_timer = 2.0
	if active_fighter_a != null and active_fighter_a.command_interpreter != null:
		active_fighter_a.command_interpreter.set_input_mode(CommandInterpreter.InputMode.LOCAL)
	if active_fighter_b != null and active_fighter_b.command_interpreter != null:
		active_fighter_b.command_interpreter.set_input_mode(CommandInterpreter.InputMode.LOCAL)


func _save_replay_to_file() -> bool:
	if input_replay_recorder == null:
		return false
	var dir := DirAccess.open("user://")
	if dir == null:
		return false
	if not dir.dir_exists("replays"):
		if dir.make_dir_recursive("replays") != OK:
			return false
	var now := Time.get_datetime_dict_from_system()
	var filename: String = "replay_%04d%02d%02d_%02d%02d%02d.json" % [now.year, now.month, now.day, now.hour, now.minute, now.second]
	var path: String = "user://replays/%s" % filename
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var tree := get_tree()
	var payload: Dictionary = {
		"meta": {
			"training_p1_mod": str(tree.get_meta("training_p1_mod", "")),
			"training_p2_mod": str(tree.get_meta("training_p2_mod", "")),
			"training_p1_form": str(tree.get_meta("training_p1_form", "")),
			"training_p2_form": str(tree.get_meta("training_p2_form", "")),
			"training_p1_costume": str(tree.get_meta("training_p1_costume", "")),
			"training_p2_costume": str(tree.get_meta("training_p2_costume", "")),
			"training_stage_folder": str(tree.get_meta("training_stage_folder", "")),
			"game_mode": str(game_mode)
		},
		"frames": input_replay_recorder.to_serializable()
	}
	file.store_string(JSON.stringify(payload))
	file.close()
	return true


func _get_initial_state(fighter: FighterBase) -> String:
	var candidate: String = str(fighter.character_data.get("initial_state", ""))
	if not candidate.is_empty() and fighter.state_controller.states_data.has(candidate):
		return candidate
	if fighter.state_controller.states_data.has("idle"):
		return "idle"
	if fighter.state_controller.states_data.keys().size() > 0:
		return str(fighter.state_controller.states_data.keys()[0])
	return ""


func _update_simul_ko_retire(delta: float) -> void:
	if not team_mode_enabled or team_mode_subtype != "simul":
		return
	if team_fighters_p1.is_empty() and team_fighters_p2.is_empty():
		return
	_track_simul_ko_candidates(team_fighters_p1)
	_track_simul_ko_candidates(team_fighters_p2)
	var retire_ids: Array[int] = []
	for key in simul_ko_retire_timers.keys():
		var id_text: String = str(key)
		var fighter_id: int = int(id_text)
		var entry_raw: Variant = simul_ko_retire_timers.get(key, null)
		if not (entry_raw is Dictionary):
			retire_ids.append(fighter_id)
			continue
		var entry: Dictionary = entry_raw
		var fighter_raw: Variant = entry.get("fighter", null)
		var fighter: FighterBase = fighter_raw as FighterBase
		if fighter == null or not is_instance_valid(fighter):
			retire_ids.append(fighter_id)
			continue
		var remaining: float = float(entry.get("remaining", 0.0)) - delta
		if remaining <= 0.0:
			_retire_simul_fighter(fighter)
			retire_ids.append(fighter_id)
		else:
			entry["remaining"] = remaining
			simul_ko_retire_timers[fighter_id] = entry
	for fighter_id in retire_ids:
		simul_ko_retire_timers.erase(fighter_id)


func _track_simul_ko_candidates(fighters: Array[FighterBase]) -> void:
	for fighter in fighters:
		if fighter == null or not is_instance_valid(fighter):
			continue
		if fighter.health > 0:
			continue
		if not fighter.visible:
			continue
		var fighter_id: int = fighter.get_instance_id()
		if simul_ko_retire_timers.has(fighter_id):
			continue
		if fighter.state_controller != null and fighter.state_controller.states_data.has("ko"):
			fighter.state_controller.change_state("ko")
		fighter.accepts_player_movement_input = false
		if fighter.command_interpreter != null:
			fighter.command_interpreter.read_local_input = false
			fighter.command_interpreter.clear_external_input_queue()
			fighter.command_interpreter.reset_latest_input()
		simul_ko_retire_timers[fighter_id] = {"fighter": fighter, "remaining": maxf(0.2, simul_ko_remove_delay_seconds)}


func _retire_simul_fighter(fighter: FighterBase) -> void:
	if fighter == null or not is_instance_valid(fighter):
		return
	fighter.visible = false
	fighter.accepts_player_movement_input = false
	fighter.velocity = Vector3.ZERO
	fighter.set_process(false)
	fighter.set_physics_process(false)
	_refresh_simul_active_fighters()


func _refresh_simul_active_fighters() -> void:
	if not team_mode_enabled or team_mode_subtype != "simul":
		return
	active_fighter_a = _first_alive_simul_fighter(team_fighters_p1)
	active_fighter_b = _first_alive_simul_fighter(team_fighters_p2)
	if active_fighter_a == null or active_fighter_b == null:
		return
	for fighter in team_fighters_p1:
		if fighter == null or not is_instance_valid(fighter) or fighter.health <= 0 or not fighter.visible:
			continue
		fighter.set_opponent(active_fighter_b)
	for fighter in team_fighters_p2:
		if fighter == null or not is_instance_valid(fighter) or fighter.health <= 0 or not fighter.visible:
			continue
		fighter.set_opponent(active_fighter_a)
	_relink_active_fighters()


func _first_alive_simul_fighter(fighters: Array[FighterBase]) -> FighterBase:
	for fighter in fighters:
		if fighter != null and is_instance_valid(fighter) and fighter.health > 0 and fighter.visible:
			return fighter
	return null


func _toggle_dummy_control() -> void:
	if cpu_enabled:
		return
	dummy_uses_local_input = not dummy_uses_local_input
	_apply_control_modes()


func _is_action_or_key_pressed(event: InputEvent, _action: StringName, fallback_key: Key) -> bool:
	if _action != StringName() and InputMap.has_action(_action) and event.is_action_pressed(_action):
		if event is InputEventKey and (event as InputEventKey).echo:
			return false
		return true
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and not key_event.echo and key_event.keycode == fallback_key
	return false


func _is_key_pressed(event: InputEvent, key: Key) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and not key_event.echo and key_event.keycode == key
	return false


func _apply_control_modes() -> void:
	if game_mode == "online":
		_apply_online_control_modes()
		return
	if game_mode == "tournament":
		_apply_tournament_control_modes()
		return
	if team_mode_enabled:
		_apply_team_control_modes()
		return
	if active_fighter_a != null:
		if watch_mode_enabled:
			active_fighter_a.command_interpreter.clear_external_input_queue()
			active_fighter_a.command_interpreter.reset_latest_input()
			active_fighter_a.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
			active_fighter_a.command_interpreter.read_local_input = false
			active_fighter_a.accepts_player_movement_input = true
		else:
			active_fighter_a.command_interpreter.set_input_mode(CommandInterpreter.InputMode.LOCAL)
			active_fighter_a.command_interpreter.read_local_input = true
			active_fighter_a.accepts_player_movement_input = true
		active_fighter_a.lock_to_x_axis = false
		active_fighter_a.set_physics_process(true)
	if active_fighter_b != null:
		if cpu_enabled:
			active_fighter_b.command_interpreter.clear_external_input_queue()
			active_fighter_b.command_interpreter.reset_latest_input()
			active_fighter_b.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
			active_fighter_b.command_interpreter.read_local_input = false
			active_fighter_b.accepts_player_movement_input = true
			active_fighter_b.lock_to_x_axis = false
			active_fighter_b.set_physics_process(true)
		elif game_mode == "versus" or game_mode == "smash" or team_mode_enabled:
			active_fighter_b.command_interpreter.set_input_mode(CommandInterpreter.InputMode.LOCAL)
			active_fighter_b.command_interpreter.read_local_input = true
			active_fighter_b.accepts_player_movement_input = true
			active_fighter_b.lock_to_x_axis = false
			active_fighter_b.set_physics_process(true)
		elif dummy_uses_local_input:
			active_fighter_b.command_interpreter.set_input_mode(CommandInterpreter.InputMode.LOCAL)
			active_fighter_b.command_interpreter.read_local_input = true
			active_fighter_b.accepts_player_movement_input = true
			active_fighter_b.lock_to_x_axis = false
			active_fighter_b.set_physics_process(true)
		else:
			active_fighter_b.command_interpreter.clear_external_input_queue()
			active_fighter_b.command_interpreter.reset_latest_input()
			active_fighter_b.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
			active_fighter_b.command_interpreter.read_local_input = false
			active_fighter_b.accepts_player_movement_input = false
			active_fighter_b.lock_to_x_axis = false
			active_fighter_b.set_physics_process(true)
	if camera_controller != null:
		camera_controller.stage_left_limit = camera_default_left_limit
		camera_controller.stage_right_limit = camera_default_right_limit


func _apply_tournament_control_modes() -> void:
	if active_fighter_a != null and active_fighter_a.command_interpreter != null:
		active_fighter_a.command_interpreter.clear_external_input_queue()
		active_fighter_a.command_interpreter.reset_latest_input()
		active_fighter_a.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
		active_fighter_a.command_interpreter.read_local_input = false
		active_fighter_a.accepts_player_movement_input = true
	if active_fighter_b != null and active_fighter_b.command_interpreter != null:
		active_fighter_b.command_interpreter.clear_external_input_queue()
		active_fighter_b.command_interpreter.reset_latest_input()
		active_fighter_b.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
		active_fighter_b.command_interpreter.read_local_input = false
		active_fighter_b.accepts_player_movement_input = true
	if camera_controller != null:
		camera_controller.stage_left_limit = camera_default_left_limit
		camera_controller.stage_right_limit = camera_default_right_limit


func _apply_online_control_modes() -> void:
	if active_fighter_a != null and active_fighter_a.command_interpreter != null:
		active_fighter_a.command_interpreter.clear_external_input_queue()
		active_fighter_a.command_interpreter.reset_latest_input()
		active_fighter_a.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
		active_fighter_a.command_interpreter.read_local_input = false
		active_fighter_a.accepts_player_movement_input = true
	if active_fighter_b != null and active_fighter_b.command_interpreter != null:
		active_fighter_b.command_interpreter.clear_external_input_queue()
		active_fighter_b.command_interpreter.reset_latest_input()
		active_fighter_b.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
		active_fighter_b.command_interpreter.read_local_input = false
		active_fighter_b.accepts_player_movement_input = true
	if camera_controller != null:
		camera_controller.stage_left_limit = camera_default_left_limit
		camera_controller.stage_right_limit = camera_default_right_limit


func _apply_team_control_modes() -> void:
	# Co-op: both P1 team fighters use local input (P1 and P2); all P2 team are CPU.
	if game_mode == "coop":
		for i in range(team_fighters_p1.size()):
			var fighter: FighterBase = team_fighters_p1[i] if i < team_fighters_p1.size() else null
			if fighter == null or not is_instance_valid(fighter) or fighter.command_interpreter == null:
				continue
			fighter.command_interpreter.set_input_mode(CommandInterpreter.InputMode.LOCAL)
			fighter.command_interpreter.read_local_input = true
			fighter.accepts_player_movement_input = true
		for fighter in team_fighters_p2:
			if fighter == null or not is_instance_valid(fighter) or fighter.command_interpreter == null:
				continue
			fighter.command_interpreter.clear_external_input_queue()
			fighter.command_interpreter.reset_latest_input()
			fighter.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
			fighter.command_interpreter.read_local_input = false
			fighter.accepts_player_movement_input = true
		if camera_controller != null:
			camera_controller.stage_left_limit = camera_default_left_limit
			camera_controller.stage_right_limit = camera_default_right_limit
		return
	# Active slots always follow normal P1/P2 local-vs-cpu rules.
	if active_fighter_a != null and active_fighter_a.command_interpreter != null:
		active_fighter_a.command_interpreter.set_input_mode(CommandInterpreter.InputMode.LOCAL)
		active_fighter_a.command_interpreter.read_local_input = true
		active_fighter_a.accepts_player_movement_input = true
	if active_fighter_b != null and active_fighter_b.command_interpreter != null:
		if dummy_uses_local_input:
			active_fighter_b.command_interpreter.set_input_mode(CommandInterpreter.InputMode.LOCAL)
			active_fighter_b.command_interpreter.read_local_input = true
		else:
			active_fighter_b.command_interpreter.clear_external_input_queue()
			active_fighter_b.command_interpreter.reset_latest_input()
			active_fighter_b.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
			active_fighter_b.command_interpreter.read_local_input = false
		active_fighter_b.accepts_player_movement_input = true
	if team_mode_subtype == "simul":
		for fighter in team_fighters_p1:
			if fighter == null or not is_instance_valid(fighter) or fighter == active_fighter_a:
				continue
			if fighter.command_interpreter != null:
				fighter.command_interpreter.clear_external_input_queue()
				fighter.command_interpreter.reset_latest_input()
				fighter.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
				fighter.command_interpreter.read_local_input = false
			fighter.accepts_player_movement_input = true
		for fighter in team_fighters_p2:
			if fighter == null or not is_instance_valid(fighter) or fighter == active_fighter_b:
				continue
			if fighter.command_interpreter != null:
				fighter.command_interpreter.clear_external_input_queue()
				fighter.command_interpreter.reset_latest_input()
				fighter.command_interpreter.set_input_mode(CommandInterpreter.InputMode.EXTERNAL)
				fighter.command_interpreter.read_local_input = false
			fighter.accepts_player_movement_input = true
	if camera_controller != null:
		camera_controller.stage_left_limit = camera_default_left_limit
		camera_controller.stage_right_limit = camera_default_right_limit


func _configure_player_input_bindings() -> void:
	if active_fighter_a != null and active_fighter_a.command_interpreter != null:
		active_fighter_a.jump_action = &"p1_up"
		active_fighter_a.command_interpreter.action_up = &"p1_up"
		active_fighter_a.command_interpreter.action_down = &"p1_down"
		active_fighter_a.command_interpreter.action_left = &"p1_left"
		active_fighter_a.command_interpreter.action_right = &"p1_right"
		active_fighter_a.command_interpreter.button_actions = {
			"P": StringName("p1_p"),
			"K": StringName("p1_k"),
			"S": StringName("p1_s"),
			"H": StringName("p1_h")
		}
	if active_fighter_b != null and active_fighter_b.command_interpreter != null:
		active_fighter_b.jump_action = &"p2_up"
		active_fighter_b.command_interpreter.action_up = &"p2_up"
		active_fighter_b.command_interpreter.action_down = &"p2_down"
		active_fighter_b.command_interpreter.action_left = &"p2_left"
		active_fighter_b.command_interpreter.action_right = &"p2_right"
		active_fighter_b.command_interpreter.button_actions = {
			"P": StringName("p2_p"),
			"K": StringName("p2_k"),
			"S": StringName("p2_s"),
			"H": StringName("p2_h")
		}


func _apply_hitbox_debug_state() -> void:
	var debug_visible: bool = game_mode == "training" and show_hitbox_debug
	if team_mode_enabled and team_mode_subtype == "simul":
		for fighter in team_fighters_p1:
			if fighter != null and is_instance_valid(fighter):
				fighter.set_hitbox_debug_visible(debug_visible)
		for fighter in team_fighters_p2:
			if fighter != null and is_instance_valid(fighter):
				fighter.set_hitbox_debug_visible(debug_visible)
		return
	if active_fighter_a != null:
		active_fighter_a.set_hitbox_debug_visible(debug_visible)
	if active_fighter_b != null:
		active_fighter_b.set_hitbox_debug_visible(debug_visible)


func _handle_hitbox_editor_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if _is_key_pressed(event, save_hitbox_edit_key):
		_save_active_fighter_states_to_mod()
		return

	_sync_hitbox_editor_target()
	if active_fighter_a == null or hitbox_edit_state_id.is_empty():
		return

	var state_data: Dictionary = active_fighter_a.state_data.get(hitbox_edit_state_id, {})
	var hitboxes: Array = state_data.get("hitboxes", [])
	if hitboxes.is_empty():
		return

	if key_event.keycode == KEY_TAB:
		_advance_training_hitbox_selection()
		return

	hitbox_edit_index = clampi(hitbox_edit_index, 0, hitboxes.size() - 1)
	var entry: Dictionary = hitboxes[hitbox_edit_index]
	var changed: bool = false

	var offset: Vector3 = _to_vector3(entry.get("offset", Vector3.ZERO))
	var size: Vector3 = _to_vector3(entry.get("size", Vector3.ONE))

	match key_event.keycode:
		KEY_LEFT:
			offset.x -= hitbox_offset_step
			changed = true
		KEY_RIGHT:
			offset.x += hitbox_offset_step
			changed = true
		KEY_UP:
			offset.y += hitbox_offset_step
			changed = true
		KEY_DOWN:
			offset.y -= hitbox_offset_step
			changed = true
		KEY_PAGEUP:
			offset.z += hitbox_offset_step
			changed = true
		KEY_PAGEDOWN:
			offset.z -= hitbox_offset_step
			changed = true
		KEY_EQUAL:
			size += Vector3.ONE * hitbox_size_step
			changed = true
		KEY_MINUS:
			size -= Vector3.ONE * hitbox_size_step
			changed = true

	if not changed:
		return

	size.x = maxf(0.05, size.x)
	size.y = maxf(0.05, size.y)
	size.z = maxf(0.05, size.z)

	entry["offset"] = [offset.x, offset.y, offset.z]
	entry["size"] = [size.x, size.y, size.z]
	hitboxes[hitbox_edit_index] = entry
	state_data["hitboxes"] = hitboxes
	active_fighter_a.state_data[hitbox_edit_state_id] = state_data
	active_fighter_a.state_controller.set_states_data(active_fighter_a.state_data)


func _sync_hitbox_editor_target() -> void:
	if active_fighter_a == null:
		hitbox_edit_state_id = ""
		hitbox_edit_index = 0
		return
	var current_state: String = active_fighter_a.state_controller.current_state
	if current_state.is_empty():
		current_state = "idle"
	if hitbox_edit_state_id != current_state:
		hitbox_edit_state_id = current_state
		hitbox_edit_index = 0


func _advance_training_hitbox_selection() -> void:
	_sync_hitbox_editor_target()
	if active_fighter_a == null or hitbox_edit_state_id.is_empty():
		return
	var state_data: Dictionary = active_fighter_a.state_data.get(hitbox_edit_state_id, {})
	var hitboxes: Array = state_data.get("hitboxes", [])
	if hitboxes.is_empty():
		hitbox_edit_index = 0
		return
	hitbox_edit_index = (hitbox_edit_index + 1) % hitboxes.size()


func _build_hitbox_edit_status_text() -> String:
	if game_mode != "training" and game_mode != "cpu_training":
		return "Live Hitbox Edit: Training Only"
	if not hitbox_edit_mode:
		return "Live Hitbox Edit: OFF"
	_sync_hitbox_editor_target()
	if active_fighter_a == null or hitbox_edit_state_id.is_empty():
		return "Live Hitbox Edit: ON | No active state"
	var state_data: Dictionary = active_fighter_a.state_data.get(hitbox_edit_state_id, {})
	var hitboxes: Array = state_data.get("hitboxes", [])
	if hitboxes.is_empty():
		return "Live Hitbox Edit: ON | %s has no hitboxes" % hitbox_edit_state_id
	var selected_index: int = clampi(hitbox_edit_index, 0, hitboxes.size() - 1)
	return "Live Hitbox Edit: ON | %s | Box %d/%d" % [hitbox_edit_state_id, selected_index + 1, hitboxes.size()]


func _save_active_fighter_states_to_mod() -> void:
	if active_fighter_a == null:
		return
	var mod_dir: String = active_fighter_a.get_mod_directory()
	if mod_dir.is_empty():
		return
	var states_path: String = "%sstates.json" % mod_dir
	var file := FileAccess.open(states_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(active_fighter_a.state_data, "\t"))


func _to_vector3(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO


func _setup_stage_music() -> void:
	if stage_music_player == null:
		stage_music_player = AudioStreamPlayer.new()
		stage_music_player.name = "StageMusicPlayer"
		add_child(stage_music_player)

	var stage_def: Dictionary = _load_stage_def("%s/stage.def" % stage_folder_path)
	var music_path: String = str(stage_def.get("music", fallback_stage_music_path))
	if music_path.is_empty():
		return

	music_path = _resolve_stage_resource_path(stage_folder_path, music_path)
	if not ResourceLoader.exists(music_path):
		return
	var stream := ResourceLoader.load(music_path)
	if stream == null or not (stream is AudioStream):
		return

	var loop_music: bool = bool(stage_def.get("music_loop", fallback_music_loop))
	var volume_db: float = float(stage_def.get("music_volume_db", fallback_music_volume_db))
	_apply_stream_loop(stream, loop_music)

	stage_music_player.stream = stream
	stage_music_player.volume_db = volume_db
	if not stage_music_player.playing:
		stage_music_player.play()


func _apply_selected_stage() -> void:
	var selected_stage_folder: String = str(get_tree().get_meta("training_stage_folder", stage_folder_path))
	if selected_stage_folder.is_empty():
		selected_stage_folder = stage_folder_path
	stage_folder_path = selected_stage_folder
	var model_path: String = _find_stage_model_path(stage_folder_path)
	if model_path.is_empty():
		return
	var stage_parent: Node = get_parent()
	if stage_parent == null:
		return
	var stage_scene: Node = _load_stage_node(model_path)
	if stage_scene == null:
		return
	if stage_root_fallback != null:
		stage_root_fallback.visible = false
	if loaded_stage_instance != null:
		loaded_stage_instance.queue_free()
	loaded_stage_instance = stage_scene
	loaded_stage_instance.name = "RuntimeStage"
	stage_parent.add_child(loaded_stage_instance)
	_ensure_runtime_stage_collision(loaded_stage_instance)
	_ensure_runtime_stage_lighting(stage_parent, loaded_stage_instance)


func _find_stage_model_path(folder: String) -> String:
	return ContentResolver.find_stage_model_path(folder, _load_stage_def("%s/stage.def" % folder))


func _load_stage_node(path: String) -> Node:
	var lower: String = path.to_lower()
	if path.begins_with("user://") and (lower.ends_with(".gltf") or lower.ends_with(".glb")):
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		if gltf.append_from_file(path, state) == OK:
			return gltf.generate_scene(state)
		return null
	var loaded = ResourceLoader.load(path)
	if loaded is PackedScene:
		return (loaded as PackedScene).instantiate()
	if lower.ends_with(".gltf") or lower.ends_with(".glb"):
		var gltf2 := GLTFDocument.new()
		var state2 := GLTFState.new()
		if gltf2.append_from_file(path, state2) == OK:
			return gltf2.generate_scene(state2)
	return null


func _ensure_runtime_stage_collision(stage_scene: Node) -> void:
	if stage_scene == null or not (stage_scene is Node3D):
		return
	var stage_root := stage_scene as Node3D
	if _stage_has_collision(stage_root):
		return

	var collision_root := StaticBody3D.new()
	collision_root.name = "RuntimeStageCollision"
	stage_root.add_child(collision_root)

	var stack: Array[Node] = [stage_root]
	var collider_count: int = 0
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh != null and mesh_node.visible:
				var faces: PackedVector3Array = mesh_node.mesh.get_faces()
				if not faces.is_empty():
					var shape := ConcavePolygonShape3D.new()
					shape.set_faces(faces)
					var shape_node := CollisionShape3D.new()
					shape_node.name = "AutoCol_%d" % collider_count
					shape_node.shape = shape
					shape_node.global_transform = mesh_node.global_transform
					collision_root.add_child(shape_node)
					collider_count += 1
		for child in node.get_children():
			stack.append(child)


func _stage_has_collision(root: Node) -> bool:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CollisionObject3D or node is CollisionShape3D:
			return true
		for child in node.get_children():
			stack.append(child)
	return false


func _ensure_runtime_stage_lighting(stage_parent: Node, stage_scene: Node) -> void:
	if stage_parent == null or stage_scene == null:
		return
	var has_stage_lights: bool = _stage_has_light_nodes(stage_scene)
	# Ensure we always have at least ambient fill so unlit/poorly-lit imports are visible.
	if runtime_stage_environment == null or not is_instance_valid(runtime_stage_environment):
		runtime_stage_environment = WorldEnvironment.new()
		runtime_stage_environment.name = "RuntimeStageEnvironment"
		stage_parent.add_child(runtime_stage_environment)
	if runtime_stage_environment.environment == null:
		runtime_stage_environment.environment = Environment.new()
	var env: Environment = runtime_stage_environment.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.09, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.74, 0.78, 1.0)
	env.ambient_light_energy = 0.8
	# Only add a directional fallback when the imported stage has no lights.
	if has_stage_lights:
		if runtime_stage_key_light != null and is_instance_valid(runtime_stage_key_light):
			runtime_stage_key_light.queue_free()
			runtime_stage_key_light = null
		return
	if runtime_stage_key_light == null or not is_instance_valid(runtime_stage_key_light):
		runtime_stage_key_light = DirectionalLight3D.new()
		runtime_stage_key_light.name = "RuntimeStageKeyLight"
		runtime_stage_key_light.light_energy = 1.5
		runtime_stage_key_light.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
		stage_parent.add_child(runtime_stage_key_light)


func _stage_has_light_nodes(root: Node) -> bool:
	if root == null:
		return false
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Light3D:
			return true
		for child in node.get_children():
			stack.append(child)
	return false


func _apply_stage_configuration() -> void:
	current_stage_def = _load_stage_def("%s/stage.def" % stage_folder_path)
	fighter_a_spawn = _stage_vector3_from_value(current_stage_def.get("spawn_p1", fighter_a_spawn), fighter_a_spawn)
	fighter_b_spawn = _stage_vector3_from_value(current_stage_def.get("spawn_p2", fighter_b_spawn), fighter_b_spawn)

	stage_floor_y_level = float(current_stage_def.get("floor_y", stage_floor_y_level))
	arena_left_limit = float(current_stage_def.get("arena_left", arena_left_limit))
	arena_right_limit = float(current_stage_def.get("arena_right", arena_right_limit))
	fall_reset_y = float(current_stage_def.get("fall_reset_y", fall_reset_y))
	smash_blast_left = float(current_stage_def.get("smash_blast_left", current_stage_def.get("blast_left", smash_blast_left_default)))
	smash_blast_right = float(current_stage_def.get("smash_blast_right", current_stage_def.get("blast_right", smash_blast_right_default)))
	smash_blast_top = float(current_stage_def.get("smash_blast_top", current_stage_def.get("blast_top", smash_blast_top_default)))
	smash_blast_bottom = float(current_stage_def.get("smash_blast_bottom", current_stage_def.get("blast_bottom", smash_blast_bottom_default)))

	var stage_offset: Vector3 = _stage_vector3_from_value(current_stage_def.get("stage_offset", Vector3.ZERO), Vector3.ZERO)
	var stage_rotation: Vector3 = _stage_vector3_from_value(current_stage_def.get("stage_rotation", Vector3.ZERO), Vector3.ZERO)
	var stage_scale: Vector3 = _stage_vector3_from_value(current_stage_def.get("stage_scale", Vector3.ONE), Vector3.ONE)
	_apply_stage_transform(stage_offset, stage_rotation, stage_scale)
	_set_floor_top_y(stage_floor_y_level)
	_apply_stage_camera_overrides()
	_apply_stage_shader_overrides()
	_apply_stage_animation_overrides()


func _apply_stage_transform(offset: Vector3, rotation_degrees: Vector3, scale_value: Vector3) -> void:
	if stage_root_fallback != null:
		stage_root_fallback.position = fallback_stage_base_position + offset
		stage_root_fallback.rotation_degrees = rotation_degrees
		stage_root_fallback.scale = scale_value
	if loaded_stage_instance != null and loaded_stage_instance is Node3D:
		var runtime_stage := loaded_stage_instance as Node3D
		runtime_stage.position = offset
		runtime_stage.rotation_degrees = rotation_degrees
		runtime_stage.scale = scale_value


func _set_floor_top_y(_top_y: float) -> void:
	if floor_body == null:
		return
	# Mesh-ground first: disable legacy fallback floor collider.
	floor_body.visible = false
	floor_body.collision_layer = 0
	floor_body.collision_mask = 0
	floor_body.process_mode = Node.PROCESS_MODE_DISABLED
	var shape_node_disabled := floor_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node_disabled != null:
		shape_node_disabled.disabled = true


func _apply_stage_camera_overrides() -> void:
	if camera_controller == null:
		return
	var camera_pos: Vector3 = _stage_vector3_from_value(current_stage_def.get("camera_position", camera_base_position), camera_base_position)
	var camera_look: Vector3 = _stage_vector3_from_value(current_stage_def.get("camera_look_target", camera_base_look_target), camera_base_look_target)
	camera_controller.global_position = camera_pos
	if camera_controller.has_method("set_stage_camera_anchor"):
		camera_controller.call("set_stage_camera_anchor", camera_pos, camera_look)
	camera_controller.look_target = camera_look
	camera_controller.look_at(camera_look, Vector3.UP)


func _load_stage_def(path: String) -> Dictionary:
	return ContentResolver.load_stage_def(path)


func _parse_stage_def_value(raw_value: String):
	var lower := raw_value.to_lower()
	if lower == "true":
		return true
	if lower == "false":
		return false
	if raw_value.is_valid_float():
		return raw_value.to_float()
	return raw_value


func _stage_vector3_from_value(value, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)), float(value.get("z", fallback.z)))
	if value is String:
		var parts: PackedStringArray = (value as String).split(",", false)
		if parts.size() >= 3:
			return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
	return fallback


func _stage_color_from_value(value, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var parts: PackedStringArray = (value as String).split(",", false)
		if parts.size() >= 3:
			var r: float = float(parts[0])
			var g: float = float(parts[1])
			var b: float = float(parts[2])
			var a: float = 1.0
			if parts.size() >= 4:
				a = float(parts[3])
			return Color(r, g, b, a)
	return fallback


func _apply_stage_shader_overrides() -> void:
	if loaded_stage_instance == null:
		return
	var shader_enabled: bool = bool(current_stage_def.get("shader_enabled", true))
	if not shader_enabled:
		return
	var shader_path_raw: String = str(current_stage_def.get("shader_path", ""))
	if shader_path_raw.is_empty():
		return
	var shader_path: String = _resolve_stage_file_path(stage_folder_path, shader_path_raw)
	var shader: Shader = _load_shader_from_path(shader_path)
	if shader == null:
		return

	var shader_params: Dictionary = {}
	if current_stage_def.has("shader_tint"):
		shader_params["stage_tint"] = _stage_color_from_value(current_stage_def.get("shader_tint", "1,1,1,1"), Color.WHITE)
	if current_stage_def.has("shader_fog_color"):
		shader_params["fog_color"] = _stage_color_from_value(current_stage_def.get("shader_fog_color", "0.30,0.34,0.40,1"), Color(0.30, 0.34, 0.40, 1.0))
	if current_stage_def.has("shader_fog_near"):
		shader_params["fog_near"] = float(current_stage_def.get("shader_fog_near", 18.0))
	if current_stage_def.has("shader_fog_far"):
		shader_params["fog_far"] = float(current_stage_def.get("shader_fog_far", 65.0))
	if current_stage_def.has("shader_fog_strength"):
		shader_params["fog_strength"] = float(current_stage_def.get("shader_fog_strength", 0.35))
	if current_stage_def.has("shader_contrast"):
		shader_params["contrast"] = float(current_stage_def.get("shader_contrast", 1.0))

	_apply_shader_to_model_tree(loaded_stage_instance, shader, shader_params)


func _apply_stage_animation_overrides() -> void:
	if loaded_stage_instance == null:
		return
	var anim_autoplay: bool = bool(current_stage_def.get("anim_autoplay", true))
	if not anim_autoplay:
		return
	var anim_name: String = str(current_stage_def.get("anim", "")).strip_edges()
	var anim_speed: float = float(current_stage_def.get("anim_speed", 1.0))
	var players: Array[AnimationPlayer] = _collect_stage_animation_players(loaded_stage_instance)
	for player in players:
		if player == null:
			continue
		player.speed_scale = anim_speed
		if not anim_name.is_empty() and player.has_animation(anim_name):
			player.play(anim_name)
		else:
			var names: PackedStringArray = player.get_animation_list()
			if not names.is_empty():
				player.play(names[0])


func _collect_stage_animation_players(root: Node) -> Array[AnimationPlayer]:
	var result: Array[AnimationPlayer] = []
	if root == null:
		return result
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is AnimationPlayer:
			result.append(node as AnimationPlayer)
		for child in node.get_children():
			stack.append(child)
	return result


func _resolve_stage_file_path(stage_folder: String, raw_path: String) -> String:
	if raw_path.begins_with("res://") or raw_path.begins_with("user://"):
		return raw_path
	return "%s/%s" % [stage_folder, raw_path]


func _load_shader_from_path(path: String) -> Shader:
	if path.is_empty():
		return null
	if path.begins_with("res://"):
		if not FileAccess.file_exists(path):
			return null
		var loaded = ResourceLoader.load(path)
		if loaded is Shader:
			return loaded as Shader
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var shader := Shader.new()
	shader.code = file.get_as_text()
	return shader


func _apply_shader_to_model_tree(root: Node, shader: Shader, params: Dictionary) -> void:
	if root == null or shader == null:
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh != null:
				var surface_count: int = mesh_node.mesh.get_surface_count()
				for i in range(surface_count):
					var mat := ShaderMaterial.new()
					mat.shader = shader
					var source_mat: Material = _resolve_surface_source_material(mesh_node, i)
					var albedo_tex: Texture2D = _extract_albedo_texture_from_material(source_mat)
					var albedo_color: Color = _extract_albedo_color_from_material(source_mat)
					if albedo_tex != null:
						mat.set_shader_parameter("albedo_texture", albedo_tex)
						mat.set_shader_parameter("use_albedo_texture", true)
					else:
						mat.set_shader_parameter("use_albedo_texture", false)
					mat.set_shader_parameter("material_color", albedo_color)
					for key in params.keys():
						mat.set_shader_parameter(str(key), params[key])
					mesh_node.set_surface_override_material(i, mat)
		for child in node.get_children():
			stack.append(child)


func _resolve_surface_source_material(mesh_node: MeshInstance3D, surface_index: int) -> Material:
	if mesh_node == null or mesh_node.mesh == null:
		return null
	var source_mat: Material = mesh_node.get_active_material(surface_index)
	if source_mat == null and mesh_node.material_override != null:
		source_mat = mesh_node.material_override
	if source_mat == null:
		source_mat = mesh_node.mesh.surface_get_material(surface_index)
	return source_mat


func _extract_albedo_texture_from_material(material: Material) -> Texture2D:
	if material == null:
		return null
	if material is BaseMaterial3D:
		return (material as BaseMaterial3D).albedo_texture
	if material is ShaderMaterial:
		var shader_mat := material as ShaderMaterial
		var tex = shader_mat.get_shader_parameter("albedo_texture")
		if tex is Texture2D:
			return tex as Texture2D
		tex = shader_mat.get_shader_parameter("texture_albedo")
		if tex is Texture2D:
			return tex as Texture2D
	return null


func _extract_albedo_color_from_material(material: Material) -> Color:
	if material == null:
		return Color.WHITE
	if material is BaseMaterial3D:
		return (material as BaseMaterial3D).albedo_color
	if material is ShaderMaterial:
		var shader_mat := material as ShaderMaterial
		var value = shader_mat.get_shader_parameter("albedo")
		if value is Color:
			return value as Color
	return Color.WHITE


func _resolve_stage_resource_path(stage_folder: String, raw_path: String) -> String:
	if raw_path.begins_with("res://") or raw_path.begins_with("user://"):
		return raw_path
	var shared_user: String = "user://sounds/%s" % raw_path
	if FileAccess.file_exists(shared_user):
		return shared_user
	var shared_res: String = "res://sounds/%s" % raw_path
	if FileAccess.file_exists(shared_res):
		return shared_res
	return "%s/%s" % [stage_folder, raw_path]


func _apply_stream_loop(stream: AudioStream, loop_music: bool) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop_music
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if loop_music else AudioStreamWAV.LOOP_DISABLED


func _bootstrap_sample_mod() -> void:
	# Legacy entry point retained for compatibility.
	_bootstrap_bundled_content()


func _bootstrap_bundled_content() -> void:
	_sync_all_from_res_root("mods", "user://mods/")
	_sync_all_from_res_root("stages", "user://stages/")


func _sync_all_from_res_root(res_root_name: String, user_root_path: String) -> void:
	var res_root: String = "res://%s/" % res_root_name
	var user_root: String = user_root_path if user_root_path.ends_with("/") else "%s/" % user_root_path
	var user_root_abs := ProjectSettings.globalize_path(user_root)
	DirAccess.make_dir_recursive_absolute(user_root_abs)
	var folder_names: Array[String] = _list_child_directories(res_root)
	for folder_name in folder_names:
		var src_dir: String = "%s%s" % [res_root, folder_name]
		var dst_dir: String = "%s%s" % [user_root, folder_name]
		_sync_directory_recursive(ProjectSettings.globalize_path(src_dir), ProjectSettings.globalize_path(dst_dir))


func _list_child_directories(root_path: String) -> Array[String]:
	var names: Array[String] = []
	var dir := DirAccess.open(root_path)
	if dir == null:
		return names
	dir.list_dir_begin()
	var item: String = dir.get_next()
	while not item.is_empty():
		if dir.current_is_dir() and item != "." and item != "..":
			names.append(item)
		item = dir.get_next()
	dir.list_dir_end()
	return names


func _write_file(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(contents)


func _write_file_if_missing(path: String, contents: String) -> void:
	if FileAccess.file_exists(path):
		return
	_write_file(path, contents)


func _sync_res_mod_assets_to_user(mod_name: String, user_mod_dir: String) -> void:
	var res_mod_dir: String = "res://mods/%s" % mod_name
	var res_abs := ProjectSettings.globalize_path(res_mod_dir)
	var user_abs := ProjectSettings.globalize_path(user_mod_dir)
	if not DirAccess.dir_exists_absolute(res_abs):
		return
	_sync_directory_recursive(res_abs, user_abs)


func _sync_directory_recursive(src_abs_dir: String, dst_abs_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dst_abs_dir)
	var src_local_dir: String = ProjectSettings.localize_path(src_abs_dir)
	if src_local_dir.is_empty():
		return
	var dir := DirAccess.open(src_local_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while not item.is_empty():
		if item == "." or item == "..":
			item = dir.get_next()
			continue
		var src_item_abs: String = "%s/%s" % [src_abs_dir, item]
		var dst_item_abs: String = "%s/%s" % [dst_abs_dir, item]
		if dir.current_is_dir():
			_sync_directory_recursive(src_item_abs, dst_item_abs)
		else:
			var lower := item.to_lower()
			if not lower.ends_with(".import"):
				_copy_file_absolute(src_item_abs, dst_item_abs)
		item = dir.get_next()
	dir.list_dir_end()


func _copy_file_absolute(src: String, dst: String) -> void:
	var in_file := FileAccess.open(src, FileAccess.READ)
	if in_file == null:
		return
	var bytes := in_file.get_buffer(in_file.get_length())
	var out_file := FileAccess.open(dst, FileAccess.WRITE)
	if out_file == null:
		return
	out_file.store_buffer(bytes)


func _enforce_arena_bounds() -> void:
	if smash_mode_enabled:
		_check_smash_blast_zones()
		return
	if team_mode_enabled and team_mode_subtype == "simul":
		for i in range(team_fighters_p1.size()):
			_clamp_fighter_to_stage(team_fighters_p1[i], _team_spawn_position(true, i))
		for j in range(team_fighters_p2.size()):
			_clamp_fighter_to_stage(team_fighters_p2[j], _team_spawn_position(false, j))
		return
	if active_fighter_a != null:
		var pos_a := active_fighter_a.global_position
		if active_fighter_a.get("runtime_screen_bound") != false:
			pos_a.x = clampf(pos_a.x, arena_left_limit, arena_right_limit)
		active_fighter_a.global_position = pos_a
		_snap_fighter_to_mesh_ground(active_fighter_a)
		if active_fighter_a.global_position.y < fall_reset_y:
			_handle_standard_fallout(active_fighter_a)

	if active_fighter_b != null:
		var pos_b := active_fighter_b.global_position
		if active_fighter_b.get("runtime_screen_bound") != false:
			pos_b.x = clampf(pos_b.x, arena_left_limit, arena_right_limit)
		active_fighter_b.global_position = pos_b
		_snap_fighter_to_mesh_ground(active_fighter_b)
		if active_fighter_b.global_position.y < fall_reset_y:
			_handle_standard_fallout(active_fighter_b)


func _clamp_fighter_to_stage(fighter: FighterBase, _respawn_pos: Vector3) -> void:
	if fighter == null or not is_instance_valid(fighter):
		return
	var pos: Vector3 = fighter.global_position
	if fighter.get("runtime_screen_bound") != false:
		pos.x = clampf(pos.x, arena_left_limit, arena_right_limit)
	fighter.global_position = pos
	_snap_fighter_to_mesh_ground(fighter)
	if fighter.global_position.y < fall_reset_y:
		_handle_standard_fallout(fighter)


func _handle_standard_fallout(fighter: FighterBase) -> void:
	if fighter == null or not is_instance_valid(fighter):
		return
	if fighter.health <= 0:
		return
	fighter.set_health(0)


func _snap_fighter_to_mesh_ground(fighter: FighterBase) -> void:
	if fighter == null or not is_instance_valid(fighter):
		return
	# Never snap while moving upward (jump/rise).
	if fighter.velocity.y > 0.0:
		return
	var world := fighter.get_world_3d()
	if world == null:
		return
	var origin: Vector3 = fighter.global_position
	# Small probe range: only correct tiny mesh penetration near feet.
	var from: Vector3 = origin + Vector3(0.0, 0.12, 0.0)
	var to: Vector3 = origin + Vector3(0.0, -0.28, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [fighter]
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
	if hit_normal.angle_to(Vector3.UP) > deg_to_rad(60.0):
		return
	var hit_pos: Vector3 = hit.get("position", origin)
	var target_y: float = hit_pos.y + float(fighter.ground_offset_y)
	# Only snap when very close to ground and moving downward/idle.
	var gap: float = origin.y - target_y
	if gap < 0.0 or gap > 0.08:
		return
	if fighter.velocity.y < -2.0:
		return
	if absf(gap) <= 0.002:
		return
	origin.y = target_y
	fighter.global_position = origin
	if fighter.velocity.y < 0.0:
		var vel: Vector3 = fighter.velocity
		vel.y = 0.0
		fighter.velocity = vel


func _check_smash_blast_zones() -> void:
	if not round_active or round_intro_pending or match_over:
		return
	if active_fighter_a != null:
		_update_smash_floor_clamp(active_fighter_a)
		_check_smash_ringout_for_fighter(active_fighter_a, true)
	if active_fighter_b != null:
		_update_smash_floor_clamp(active_fighter_b)
		_check_smash_ringout_for_fighter(active_fighter_b, false)


func _check_smash_ringout_for_fighter(fighter: FighterBase, is_p1: bool) -> void:
	if fighter == null:
		return
	_force_smash_offstage_fall(fighter)
	var pos: Vector3 = fighter.global_position
	var out_of_bounds: bool = pos.x < smash_blast_left or pos.x > smash_blast_right or pos.y < smash_blast_bottom or pos.y > smash_blast_top
	if not out_of_bounds:
		return
	if is_p1:
		p1_stocks = maxi(0, p1_stocks - 1)
		if p1_stocks <= 0:
			fighter.set_health(0)
			_end_round_with_winner(2, "P2 Wins!")
			return
		_reset_fighter(fighter, fighter_a_spawn)
		fighter.activate_smash_respawn_protection(smash_respawn_protect_frames)
	else:
		p2_stocks = maxi(0, p2_stocks - 1)
		if p2_stocks <= 0:
			fighter.set_health(0)
			_end_round_with_winner(1, "P1 Wins!")
			return
		_reset_fighter(fighter, fighter_b_spawn)
		fighter.activate_smash_respawn_protection(smash_respawn_protect_frames)


func _force_smash_offstage_fall(fighter: FighterBase) -> void:
	if fighter == null or not is_instance_valid(fighter):
		return
	var pos: Vector3 = fighter.global_position
	var left_edge: float = arena_left_limit - smash_offstage_margin
	var right_edge: float = arena_right_limit + smash_offstage_margin
	var is_offstage: bool = pos.x < left_edge or pos.x > right_edge
	if not is_offstage:
		return
	var vel: Vector3 = fighter.velocity
	vel.y = minf(vel.y, -absf(smash_offstage_min_fall_speed))
	fighter.velocity = vel


func _update_smash_floor_clamp(fighter: FighterBase) -> void:
	if fighter == null or not is_instance_valid(fighter):
		return
	var pos: Vector3 = fighter.global_position
	var left_edge: float = arena_left_limit - smash_offstage_margin
	var right_edge: float = arena_right_limit + smash_offstage_margin
	var is_offstage: bool = pos.x < left_edge or pos.x > right_edge
	fighter.enforce_floor_clamp = not is_offstage


func _resolve_fighter_pushbox() -> void:
	if team_mode_enabled and team_mode_subtype == "simul":
		_resolve_simul_pushboxes()
		return
	if active_fighter_a == null or active_fighter_b == null:
		return
	if not round_active or round_intro_pending or training_options_open:
		return
	if active_fighter_a.health <= 0 or active_fighter_b.health <= 0:
		return
	if active_fighter_a.has_method("_is_being_grabbed") and bool(active_fighter_a.call("_is_being_grabbed")):
		return
	if active_fighter_b.has_method("_is_being_grabbed") and bool(active_fighter_b.call("_is_being_grabbed")):
		return

	var pos_a: Vector3 = active_fighter_a.global_position
	var pos_b: Vector3 = active_fighter_b.global_position
	var vertical_gap: float = absf(pos_b.y - pos_a.y)
	if vertical_gap > _fighter_push_vertical_overlap_gap(active_fighter_a, active_fighter_b):
		return
	if vertical_gap >= _fighter_airborne_cross_gap(active_fighter_a, active_fighter_b) and _fighters_are_in_airborne_cross(active_fighter_a, active_fighter_b):
		return
	var dx: float = pos_b.x - pos_a.x
	var distance: float = absf(dx)
	var min_distance: float = _fighter_push_radius(active_fighter_a) + _fighter_push_radius(active_fighter_b)
	if distance >= min_distance:
		return

	var overlap: float = min_distance - distance
	var push_dir: float = 1.0 if dx >= 0.0 else -1.0
	if distance < 0.001:
		push_dir = 1.0 if int(Engine.get_physics_frames()) % 2 == 0 else -1.0

	var push_each: float = overlap * 0.5
	var can_push_a: bool = not active_fighter_a.lock_to_x_axis and active_fighter_a.get("runtime_player_push_disabled") != true
	var can_push_b: bool = not active_fighter_b.lock_to_x_axis and active_fighter_b.get("runtime_player_push_disabled") != true
	if can_push_a and can_push_b:
		pos_a.x -= push_dir * push_each
		pos_b.x += push_dir * push_each
	elif can_push_a:
		pos_a.x -= push_dir * overlap
	elif can_push_b:
		pos_b.x += push_dir * overlap
	else:
		return

	if not smash_mode_enabled:
		pos_a.x = clampf(pos_a.x, arena_left_limit, arena_right_limit)
		pos_b.x = clampf(pos_b.x, arena_left_limit, arena_right_limit)
	active_fighter_a.global_position = pos_a
	active_fighter_b.global_position = pos_b


func _resolve_simul_pushboxes() -> void:
	if not round_active or round_intro_pending or training_options_open:
		return
	var all_fighters: Array[FighterBase] = []
	all_fighters.append_array(team_fighters_p1)
	all_fighters.append_array(team_fighters_p2)
	for i in range(all_fighters.size()):
		for j in range(i + 1, all_fighters.size()):
			var a: FighterBase = all_fighters[i]
			var b: FighterBase = all_fighters[j]
			if a == null or b == null or not is_instance_valid(a) or not is_instance_valid(b):
				continue
			if a.health <= 0 or b.health <= 0:
				continue
			# Teammates should not push each other in Simul.
			if a.team_id > 0 and a.team_id == b.team_id:
				continue
			var pos_a: Vector3 = a.global_position
			var pos_b: Vector3 = b.global_position
			var vertical_gap: float = absf(pos_b.y - pos_a.y)
			if vertical_gap > _fighter_push_vertical_overlap_gap(a, b):
				continue
			if vertical_gap >= _fighter_airborne_cross_gap(a, b) and _fighters_are_in_airborne_cross(a, b):
				continue
			var dx: float = pos_b.x - pos_a.x
			var distance: float = absf(dx)
			var min_distance: float = _fighter_push_radius(a) + _fighter_push_radius(b)
			if distance >= min_distance:
				continue
			var overlap: float = min_distance - distance
			var push_dir: float = 1.0 if dx >= 0.0 else -1.0
			var push_each: float = overlap * 0.5
			pos_a.x = clampf(pos_a.x - push_dir * push_each, arena_left_limit, arena_right_limit)
			pos_b.x = clampf(pos_b.x + push_dir * push_each, arena_left_limit, arena_right_limit)
			a.global_position = pos_a
			b.global_position = pos_b


func _fighter_push_radius(fighter: FighterBase) -> float:
	if fighter == null:
		return 0.45
	var wf: float = float(fighter.get("runtime_width_front"))
	var wb: float = float(fighter.get("runtime_width_back"))
	if wf >= 0.0 or wb >= 0.0:
		var front: float = maxf(0.0, wf) if wf >= 0 else 0.45
		var back: float = maxf(0.0, wb) if wb >= 0 else 0.45
		return (front + back) * 0.5 * 0.01
	var scale: float = maxf(0.1, float(fighter.collision_scale))
	return 0.45 * scale


func _fighter_push_vertical_overlap_gap(fighter_a: FighterBase, fighter_b: FighterBase) -> float:
	return (_single_fighter_push_height(fighter_a) + _single_fighter_push_height(fighter_b)) * 0.5


func _single_fighter_push_height(fighter: FighterBase) -> float:
	if fighter == null:
		return 1.05
	var scale: float = maxf(0.1, float(fighter.collision_scale))
	return 1.05 * scale


func _fighter_airborne_cross_gap(fighter_a: FighterBase, fighter_b: FighterBase) -> float:
	var gap_a: float = _single_fighter_airborne_cross_gap(fighter_a)
	var gap_b: float = _single_fighter_airborne_cross_gap(fighter_b)
	return maxf(0.35, minf(gap_a, gap_b))


func _single_fighter_airborne_cross_gap(fighter: FighterBase) -> float:
	if fighter == null:
		return 0.75
	var scale: float = maxf(0.1, float(fighter.collision_scale))
	return 0.75 * scale


func _fighters_are_in_airborne_cross(fighter_a: FighterBase, fighter_b: FighterBase) -> bool:
	return _fighter_is_rising_airborne(fighter_a) or _fighter_is_rising_airborne(fighter_b)


func _fighter_is_rising_airborne(fighter: FighterBase) -> bool:
	if fighter == null:
		return false
	var grounded: bool = fighter.has_method("is_grounded_for_juggle") and bool(fighter.call("is_grounded_for_juggle"))
	if grounded:
		return false
	return fighter.velocity.y > 0.05


func _start_round() -> void:
	round_time_left = round_time_seconds
	round_accumulator = 0.0
	round_active = false
	round_intro_pending = true
	round_intro_timer = maxf(0.0, round_intro_delay_seconds)
	round_reset_pending = false
	round_reset_timer = 0.0
	match_over = false
	status_text = "Smash - Ready" if smash_mode_enabled else "Round %d - Ready" % round_number
	SystemSFX.play_battle_from(self, "round_ready")
	_restore_camera_targets_for_round()
	_apply_control_modes()
	_set_fighter_input_enabled(false)
	_apply_hitbox_debug_state()


func _restore_camera_targets_for_round() -> void:
	if camera_controller == null:
		return
	if active_fighter_a == null or active_fighter_b == null:
		return
	if not is_instance_valid(active_fighter_a) or not is_instance_valid(active_fighter_b):
		return
	camera_controller.fighter_a_path = camera_controller.get_path_to(active_fighter_a)
	camera_controller.fighter_b_path = camera_controller.get_path_to(active_fighter_b)
	_refresh_camera_tracked_fighters()


func _is_team_side_eliminated(is_p1: bool) -> bool:
	var fighters: Array[FighterBase] = team_fighters_p1 if is_p1 else team_fighters_p2
	if fighters.is_empty():
		return true
	for fighter in fighters:
		if fighter != null and is_instance_valid(fighter) and fighter.health > 0:
			return false
	return true


func _try_turns_substitute(is_p1: bool) -> bool:
	if not team_mode_enabled or (team_mode_subtype != "turns" and team_mode_subtype != "tag"):
		return false
	var roster: Array[Dictionary] = team_roster_p1 if is_p1 else team_roster_p2
	var next_idx: int = team_turns_next_idx_p1 if is_p1 else team_turns_next_idx_p2
	if next_idx >= roster.size():
		return false
	var old_fighter: FighterBase = active_fighter_a if is_p1 else active_fighter_b
	if old_fighter != null and is_instance_valid(old_fighter):
		old_fighter.queue_free()
	var replacement: FighterBase = _instantiate_team_fighter(roster[next_idx], is_p1, next_idx)
	if replacement == null:
		return false
	if is_p1:
		team_fighters_p1.append(replacement)
		active_fighter_a = replacement
		if team_mode_subtype == "turns":
			team_turns_next_idx_p1 += 1
		else:
			team_tag_active_idx_p1 = next_idx
			team_turns_next_idx_p1 = next_idx + 1
	else:
		team_fighters_p2.append(replacement)
		active_fighter_b = replacement
		if team_mode_subtype == "turns":
			team_turns_next_idx_p2 += 1
		else:
			team_tag_active_idx_p2 = next_idx
			team_turns_next_idx_p2 = next_idx + 1
	_relink_active_fighters()
	return true


func _relink_active_fighters() -> void:
	if active_fighter_a == null or active_fighter_b == null:
		return
	active_fighter_a.set_opponent(active_fighter_b)
	active_fighter_b.set_opponent(active_fighter_a)
	if camera_controller != null:
		camera_controller.fighter_a_path = camera_controller.get_path_to(active_fighter_a)
		camera_controller.fighter_b_path = camera_controller.get_path_to(active_fighter_b)
		_refresh_camera_tracked_fighters()
	if input_buffer_viewer != null:
		input_buffer_viewer.target_fighter_path = input_buffer_viewer.get_path_to(active_fighter_a)
	_configure_smash_mode_for_fighters()
	_configure_player_input_bindings()
	_apply_control_modes()
	_apply_hitbox_debug_state()


func _find_next_tag_available_index(is_p1: bool) -> int:
	var roster: Array[Dictionary] = team_roster_p1 if is_p1 else team_roster_p2
	var active_idx: int = team_tag_active_idx_p1 if is_p1 else team_tag_active_idx_p2
	if roster.is_empty():
		return -1
	for step in range(1, roster.size() + 1):
		var idx: int = (active_idx + step) % roster.size()
		var hp: int = int(roster[idx].get("saved_health", 1))
		if hp > 0:
			return idx
	return -1


func _try_tag_swap(is_p1: bool) -> void:
	if not team_mode_enabled or team_mode_subtype != "tag":
		return
	if tag_swap_cooldown_frames > 0 or not round_active or round_intro_pending:
		return
	var roster: Array[Dictionary] = team_roster_p1 if is_p1 else team_roster_p2
	var active_idx: int = team_tag_active_idx_p1 if is_p1 else team_tag_active_idx_p2
	if roster.size() <= 1:
		return
	var outgoing: FighterBase = active_fighter_a if is_p1 else active_fighter_b
	var next_idx: int = _find_next_tag_available_index(is_p1)
	if next_idx < 0 or next_idx == active_idx:
		return
	var incoming: FighterBase = _instantiate_team_fighter(roster[next_idx], is_p1, next_idx)
	if incoming == null:
		return
	if outgoing != null and is_instance_valid(outgoing):
		var kept_health: int = outgoing.health
		var kept_resource: int = outgoing.resource
		roster[active_idx]["saved_health"] = kept_health
		roster[active_idx]["saved_resource"] = kept_resource
		# Tag swaps should keep combat continuity at the current fighter position.
		incoming.global_position = outgoing.global_position
		incoming.velocity = Vector3.ZERO
		outgoing.queue_free()
	if roster[next_idx].has("saved_health"):
		incoming.set_health(int(roster[next_idx].get("saved_health", incoming.max_health)))
	if roster[next_idx].has("saved_resource"):
		incoming.set_resource(int(roster[next_idx].get("saved_resource", incoming.resource)))
	if is_p1:
		active_fighter_a = incoming
		team_fighters_p1.append(incoming)
		team_tag_active_idx_p1 = next_idx
		team_roster_p1 = roster
	else:
		active_fighter_b = incoming
		team_fighters_p2.append(incoming)
		team_tag_active_idx_p2 = next_idx
		team_roster_p2 = roster
	tag_swap_cooldown_frames = 20
	_relink_active_fighters()
	status_text = "Tag Swap!"


func _update_round_logic(delta: float) -> void:
	if active_fighter_a == null or active_fighter_b == null:
		return

	if match_over:
		if match_over_timer > 0.0:
			match_over_timer -= delta
			if match_over_timer <= 0.0:
				var return_scene: String = match_over_return_scene.strip_edges()
				if return_scene.is_empty():
					return_scene = "res://ui/CharacterSelect.tscn"
				get_tree().change_scene_to_file(return_scene)
		return
	if round_intro_pending:
		round_intro_timer -= delta
		if round_intro_timer <= 0.0:
			round_intro_pending = false
			round_active = true
			if input_replay_recorder != null and game_mode != "online" and (dummy_uses_local_input or get_tree().get_meta("save_replay", false)):
				input_replay_recorder.start_recording()
			status_text = "Fight!"
			SystemSFX.play_battle_from(self, "round_fight")
			_set_fighter_input_enabled(true)
	elif round_active and not replay_playback_active:
		if not smash_mode_enabled and round_time_seconds > 0:
			round_accumulator += delta
			while round_accumulator >= 1.0:
				round_accumulator -= 1.0
				round_time_left = maxi(0, round_time_left - 1)
		_check_round_end_conditions()
	elif tournament_next_match_pending:
		tournament_next_match_timer -= delta
		if tournament_next_match_timer <= 0.0:
			tournament_next_match_pending = false
			_prepare_next_tournament_match()
	elif round_reset_pending:
		round_reset_timer -= delta
		if round_reset_timer <= 0.0:
			_prepare_next_round()
			_reset_round()


func _check_round_end_conditions() -> void:
	if active_fighter_a == null or active_fighter_b == null:
		return
	if team_mode_enabled:
		if team_mode_subtype == "simul":
			var p1_out: bool = _is_team_side_eliminated(true)
			var p2_out: bool = _is_team_side_eliminated(false)
			if p1_out and not p2_out:
				_end_round_with_winner(2, "P2 Team Wins!")
				return
			if p2_out and not p1_out:
				_end_round_with_winner(1, "P1 Team Wins!")
				return
			if p1_out and p2_out:
				_end_round_with_winner(0, "Double KO")
				return
			# In Simul, one KO is not round end; only full-team elimination ends the round.
			return
		elif team_mode_subtype == "turns":
			var p1_dead_turns: bool = active_fighter_a.health <= 0
			var p2_dead_turns: bool = active_fighter_b.health <= 0
			if p1_dead_turns and not _try_turns_substitute(true):
				_end_round_with_winner(2, "P2 Team Wins!")
				return
			if p2_dead_turns and not _try_turns_substitute(false):
				_end_round_with_winner(1, "P1 Team Wins!")
				return
		elif team_mode_subtype == "tag":
			var p1_dead_tag: bool = active_fighter_a.health <= 0
			var p2_dead_tag: bool = active_fighter_b.health <= 0
			if p1_dead_tag:
				team_roster_p1[team_tag_active_idx_p1]["saved_health"] = 0
				team_turns_next_idx_p1 = _find_next_tag_available_index(true)
				if not _try_turns_substitute(true):
					_end_round_with_winner(2, "P2 Team Wins!")
					return
			if p2_dead_tag:
				team_roster_p2[team_tag_active_idx_p2]["saved_health"] = 0
				team_turns_next_idx_p2 = _find_next_tag_available_index(false)
				if not _try_turns_substitute(false):
					_end_round_with_winner(1, "P1 Team Wins!")
					return
	if smash_mode_enabled:
		if p1_stocks <= 0 and p2_stocks > 0:
			_end_round_with_winner(2, "P2 Wins!")
		elif p2_stocks <= 0 and p1_stocks > 0:
			_end_round_with_winner(1, "P1 Wins!")
		elif p1_stocks <= 0 and p2_stocks <= 0:
			_end_round_with_winner(0, "Draw")
		return

	var p1_dead: bool = active_fighter_a.health <= 0
	var p2_dead: bool = active_fighter_b.health <= 0
	if p1_dead or p2_dead:
		if p1_dead and not p2_dead:
			_end_round_with_winner(2, "P2 Wins!")
		elif p2_dead and not p1_dead:
			_end_round_with_winner(1, "P1 Wins!")
		else:
			_end_round_with_winner(0, "Double KO")
		return

	if round_time_seconds > 0 and round_time_left <= 0:
		if active_fighter_a.health > active_fighter_b.health:
			_end_round_with_winner(1, "Time Up - P1 Wins")
		elif active_fighter_b.health > active_fighter_a.health:
			_end_round_with_winner(2, "Time Up - P2 Wins")
		else:
			_end_round_with_winner(0, "Time Up - Draw")


func _end_round_with_winner(winner: int, message: String) -> void:
	round_active = false
	round_intro_pending = false
	if (game_mode == "training" or game_mode == "cpu_training") and record_learned_ai:
		_learned_ai_flush_record_buffer()
	var replay_saved: bool = false
	if input_replay_recorder != null and input_replay_recorder.is_recording():
		input_replay_recorder.stop_recording()
		if get_tree().get_meta("save_replay", false) and input_replay_recorder.get_recorded_frame_count() > 0:
			replay_saved = _save_replay_to_file()
	status_text = message
	if replay_saved:
		status_text += " (Replay saved)"
	if winner == 1:
		p1_wins += 1
	elif winner == 2:
		p2_wins += 1
	if active_fighter_a != null:
		active_fighter_a.accepts_player_movement_input = false
		active_fighter_a.command_interpreter.read_local_input = false
	if active_fighter_b != null:
		active_fighter_b.accepts_player_movement_input = false
		active_fighter_b.command_interpreter.read_local_input = false
	_focus_camera_on_winner(winner)
	_play_round_end_states(winner)
	if smash_mode_enabled:
		match_over = true
		match_over_return_scene = "res://ui/CharacterSelect.tscn"
		match_over_timer = maxf(0.1, match_end_return_delay_seconds)
		round_reset_pending = false
		round_reset_timer = 0.0
		status_text = "%s - Returning..." % message
		SystemSFX.play_battle_from(self, "round_match")
		return
	if survival_mode_enabled:
		if winner == 1:
			round_reset_pending = true
			round_reset_timer = round_reset_delay_seconds
			status_text = "Survival - Next Opponent"
			SystemSFX.play_battle_from(self, "round_win")
		else:
			match_over = true
			match_over_return_scene = arcade_post_match_scene_path
			match_over_timer = maxf(0.0, arcade_match_end_delay_seconds)
			round_reset_pending = false
			round_reset_timer = 0.0
			status_text = "Survival Over - Returning..."
			SystemSFX.play_battle_from(self, "round_match")
		return
	if game_mode == "arcade" and winner != 0 and (p1_wins >= rounds_to_win or p2_wins >= rounds_to_win):
		match_over = true
		match_over_return_scene = arcade_post_match_scene_path
		match_over_timer = maxf(0.0, arcade_match_end_delay_seconds)
		round_reset_pending = false
		round_reset_timer = 0.0
		status_text = "P%d Match Wins! Returning..." % winner if game_mode == "arcade" else "P%d Match Wins!" % winner
		SystemSFX.play_battle_from(self, "round_match")
		return
	if game_mode == "tournament" and winner != 0 and (p1_wins >= rounds_to_win or p2_wins >= rounds_to_win):
		var match_idx: int = int(get_tree().get_meta("tournament_match_index", 0))
		var round_results: Array = get_tree().get_meta("tournament_round_results", [])
		var entrants: Array = get_tree().get_meta("tournament_entrants", [])
		var n: int = entrants.size()
		var total: int = _tournament_total_matches(n)
		var indices: Array = _tournament_get_opponents(n, match_idx, round_results)
		var winner_idx: int = -1
		if indices.size() >= 2:
			var left_idx: int = int(indices[0])
			var right_idx: int = int(indices[1])
			winner_idx = left_idx if winner == 1 else right_idx
		round_results.append(winner_idx)
		get_tree().set_meta("tournament_round_results", round_results)
		var next_idx: int = match_idx + 1
		get_tree().set_meta("tournament_match_index", next_idx)
		round_active = false
		if next_idx >= total:
			var champ_name: String = "Unknown"
			if winner_idx >= 0 and winner_idx < entrants.size():
				champ_name = str(entrants[winner_idx].get("mod", "Unknown"))
			match_over = true
			match_over_return_scene = "res://ui/MainMenu.tscn"
			match_over_timer = maxf(2.0, arcade_match_end_delay_seconds)
			round_reset_pending = false
			round_reset_timer = 0.0
			tournament_next_match_pending = false
			status_text = "Champion: %s!" % champ_name
			SystemSFX.play_battle_from(self, "round_match")
		else:
			tournament_next_match_pending = true
			tournament_next_match_timer = maxf(1.0, round_reset_delay_seconds)
			round_reset_pending = false
			round_reset_timer = 0.0
			status_text = "Next match..."
			SystemSFX.play_battle_from(self, "round_win")
		return
	round_reset_pending = true
	round_reset_timer = round_reset_delay_seconds
	if message.begins_with("Time Up"):
		SystemSFX.play_battle_from(self, "time_up")
	else:
		SystemSFX.play_battle_from(self, "round_win")


func _play_round_end_states(winner: int) -> void:
	if active_fighter_a == null or active_fighter_b == null:
		return
	var fighter_a_dead: bool = active_fighter_a.health <= 0
	var fighter_b_dead: bool = active_fighter_b.health <= 0

	if fighter_a_dead and active_fighter_a.state_controller.states_data.has("ko"):
		active_fighter_a.state_controller.change_state("ko")
	if fighter_b_dead and active_fighter_b.state_controller.states_data.has("ko"):
		active_fighter_b.state_controller.change_state("ko")

	if winner == 1 and active_fighter_a.state_controller.states_data.has("victory"):
		active_fighter_a.state_controller.change_state("victory")
	elif winner == 2 and active_fighter_b.state_controller.states_data.has("victory"):
		active_fighter_b.state_controller.change_state("victory")


func _focus_camera_on_winner(winner: int) -> void:
	if camera_controller == null:
		return
	var winner_fighter: FighterBase = null
	if winner == 1:
		winner_fighter = active_fighter_a
	elif winner == 2:
		winner_fighter = active_fighter_b
	if winner_fighter == null or not is_instance_valid(winner_fighter):
		return
	camera_controller.stage_left_limit = camera_default_left_limit
	camera_controller.stage_right_limit = camera_default_right_limit
	var winner_path: NodePath = camera_controller.get_path_to(winner_fighter)
	camera_controller.fighter_a_path = winner_path
	camera_controller.fighter_b_path = winner_path
	if camera_controller.has_method("set_tracked_fighter_paths"):
		var winner_paths: Array[NodePath] = [winner_path]
		camera_controller.set_tracked_fighter_paths(winner_paths)


func _refresh_camera_tracked_fighters() -> void:
	if camera_controller == null or not camera_controller.has_method("set_tracked_fighter_paths"):
		return
	var tracked_paths: Array[NodePath] = []
	if team_mode_enabled and team_mode_subtype == "simul":
		for fighter in team_fighters_p1:
			if fighter != null and is_instance_valid(fighter) and fighter.health > 0:
				tracked_paths.append(camera_controller.get_path_to(fighter))
		for fighter in team_fighters_p2:
			if fighter != null and is_instance_valid(fighter) and fighter.health > 0:
				tracked_paths.append(camera_controller.get_path_to(fighter))
	else:
		if active_fighter_a != null and is_instance_valid(active_fighter_a):
			tracked_paths.append(camera_controller.get_path_to(active_fighter_a))
		if active_fighter_b != null and is_instance_valid(active_fighter_b):
			tracked_paths.append(camera_controller.get_path_to(active_fighter_b))
	camera_controller.set_tracked_fighter_paths(tracked_paths)


func _prepare_next_round() -> void:
	round_number += 1
	status_text = "Smash - Next Round" if smash_mode_enabled else "Round %d" % round_number


func _tournament_get_opponents(num_entrants: int, match_idx: int, round_results: Array) -> Array:
	if num_entrants < 2:
		return [-1, -1]
	var first_round_matches: int = int(num_entrants / 2)
	if match_idx < first_round_matches:
		return [match_idx * 2, match_idx * 2 + 1]
	var source_start: int = 0
	var source_size: int = first_round_matches
	var match_start: int = first_round_matches
	while source_size > 1 and match_start + int(source_size / 2) <= match_idx:
		match_start += int(source_size / 2)
		source_start += int(source_size / 2)
		source_size = int(source_size / 2)
	var offset: int = match_idx - match_start
	var base: int = source_start + offset * 2
	if base + 1 >= round_results.size():
		return [-1, -1]
	return [int(round_results[base]), int(round_results[base + 1])]


func _tournament_total_matches(num_entrants: int) -> int:
	return maxi(0, num_entrants - 1)


func _prepare_next_tournament_match() -> void:
	p1_wins = 0
	p2_wins = 0
	round_number = 1
	round_reset_pending = false
	round_reset_timer = 0.0
	if active_fighter_a != null and is_instance_valid(active_fighter_a):
		active_fighter_a.queue_free()
	if active_fighter_b != null and is_instance_valid(active_fighter_b):
		active_fighter_b.queue_free()
	active_fighter_a = null
	active_fighter_b = null
	var entrants: Array = get_tree().get_meta("tournament_entrants", [])
	var match_idx: int = int(get_tree().get_meta("tournament_match_index", 0))
	var round_results: Array = get_tree().get_meta("tournament_round_results", [])
	var n: int = entrants.size()
	var total: int = _tournament_total_matches(n)
	var indices: Array = _tournament_get_opponents(n, match_idx, round_results)
	if match_idx < int(n / 2):
		status_text = "Tournament - Round 1 Match %d" % (match_idx + 1)
	elif total > 1 and match_idx < total - 1:
		status_text = "Tournament - Match %d" % (match_idx + 1)
	else:
		status_text = "Tournament - Final"
	if indices.size() >= 2:
		var left_idx: int = int(indices[0])
		var right_idx: int = int(indices[1])
		if left_idx >= 0 and right_idx >= 0 and entrants.size() > left_idx and entrants.size() > right_idx:
			var le: Dictionary = entrants[left_idx]
			var re: Dictionary = entrants[right_idx]
			_spawn_mod_fighters(
				str(le.get("mod", "")),
				str(re.get("mod", "")),
				str(le.get("form", "")),
				str(re.get("form", "")),
				str(le.get("costume", "")),
				str(re.get("costume", ""))
			)


func _set_fighter_input_enabled(enabled: bool) -> void:
	if team_mode_enabled and team_mode_subtype == "simul":
		if game_mode == "coop":
			for fighter in team_fighters_p1:
				if fighter == null or not is_instance_valid(fighter) or fighter.command_interpreter == null:
					continue
				fighter.accepts_player_movement_input = enabled
				fighter.command_interpreter.read_local_input = enabled
			for fighter in team_fighters_p2:
				if fighter == null or not is_instance_valid(fighter) or fighter.command_interpreter == null:
					continue
				fighter.accepts_player_movement_input = enabled
				fighter.command_interpreter.read_local_input = false
			return
		for fighter in team_fighters_p1:
			if fighter == null or not is_instance_valid(fighter) or fighter.command_interpreter == null:
				continue
			if fighter == active_fighter_a:
				fighter.accepts_player_movement_input = enabled
				fighter.command_interpreter.read_local_input = enabled
			else:
				fighter.accepts_player_movement_input = enabled
				fighter.command_interpreter.read_local_input = false
		for fighter in team_fighters_p2:
			if fighter == null or not is_instance_valid(fighter) or fighter.command_interpreter == null:
				continue
			if fighter == active_fighter_b and dummy_uses_local_input:
				fighter.accepts_player_movement_input = enabled
				fighter.command_interpreter.read_local_input = enabled
			else:
				fighter.accepts_player_movement_input = enabled
				fighter.command_interpreter.read_local_input = false
		return
	if active_fighter_a != null:
		if watch_mode_enabled:
			active_fighter_a.accepts_player_movement_input = enabled
			active_fighter_a.command_interpreter.read_local_input = false
		else:
			active_fighter_a.accepts_player_movement_input = enabled
			active_fighter_a.command_interpreter.read_local_input = enabled
	if active_fighter_b != null:
		if cpu_enabled:
			active_fighter_b.accepts_player_movement_input = enabled
			active_fighter_b.command_interpreter.read_local_input = false
		elif dummy_uses_local_input or game_mode == "versus" or game_mode == "smash" or team_mode_enabled:
			active_fighter_b.accepts_player_movement_input = enabled
			active_fighter_b.command_interpreter.read_local_input = enabled
		else:
			active_fighter_b.accepts_player_movement_input = false
			active_fighter_b.command_interpreter.read_local_input = false


func _update_cpu_input() -> void:
	if training_options_open or round_intro_pending or not round_active or match_over:
		return
	if active_fighter_a == null or active_fighter_b == null:
		return
	if team_mode_enabled:
		if team_mode_subtype == "simul":
			if game_mode != "coop":
				for fighter in team_fighters_p1:
					if fighter == null or not is_instance_valid(fighter) or fighter == active_fighter_a:
						continue
					_drive_cpu_fighter(fighter, active_fighter_b)
			for fighter in team_fighters_p2:
				if fighter == null or not is_instance_valid(fighter):
					continue
				if game_mode == "coop":
					_drive_cpu_fighter(fighter, active_fighter_a)
					continue
				if fighter == active_fighter_b and dummy_uses_local_input:
					continue
				_drive_cpu_fighter(fighter, active_fighter_a)
			return
		if not dummy_uses_local_input:
			_drive_cpu_fighter(active_fighter_b, active_fighter_a)
		return
	if not cpu_enabled and game_mode != "tournament":
		return
	if watch_mode_enabled or game_mode == "tournament":
		_drive_cpu_fighter(active_fighter_a, active_fighter_b)
		_drive_cpu_fighter(active_fighter_b, active_fighter_a)
		return
	_drive_cpu_fighter(active_fighter_b, active_fighter_a)


func _to_string_array(arr: Variant) -> Array[String]:
	var out: Array[String] = []
	if arr is Array:
		for x in arr:
			out.append(str(x))
	return out


func _read_player_input(player: int) -> Dictionary:
	var prefix: String = "p1_" if player == 1 else "p2_"
	var x: float = 0.0
	var y: float = 0.0
	if InputMap.has_action(prefix + "right"):
		x += Input.get_action_strength(prefix + "right")
	if InputMap.has_action(prefix + "left"):
		x -= Input.get_action_strength(prefix + "left")
	if InputMap.has_action(prefix + "down"):
		y -= Input.get_action_strength(prefix + "down")
	if InputMap.has_action(prefix + "up"):
		y += Input.get_action_strength(prefix + "up")
	var pressed: Array[String] = []
	var held: Array[String] = []
	var released: Array[String] = []
	for btn in ["P", "K", "S", "H"]:
		var action: StringName = StringName(prefix + btn.to_lower())
		if btn == "P":
			action = StringName(prefix + "p")
		elif btn == "K":
			action = StringName(prefix + "k")
		elif btn == "S":
			action = StringName(prefix + "s")
		elif btn == "H":
			action = StringName(prefix + "h")
		if InputMap.has_action(action):
			if Input.is_action_just_pressed(action):
				pressed.append(btn)
			if Input.is_action_pressed(action):
				held.append(btn)
			if Input.is_action_just_released(action):
				released.append(btn)
	return {
		"direction": Vector2(x, y),
		"pressed": pressed,
		"held": held,
		"released": released
	}


func _apply_online_frame(_frame_id: int, p1_input: Dictionary, p2_input: Dictionary) -> void:
	if active_fighter_a != null and active_fighter_a.command_interpreter != null:
		active_fighter_a.command_interpreter.enqueue_external_input(
			p1_input.get("direction", Vector2.ZERO),
			_to_string_array(p1_input.get("pressed", [])),
			_to_string_array(p1_input.get("held", [])),
			_to_string_array(p1_input.get("released", []))
		)
	if active_fighter_b != null and active_fighter_b.command_interpreter != null:
		active_fighter_b.command_interpreter.enqueue_external_input(
			p2_input.get("direction", Vector2.ZERO),
			_to_string_array(p2_input.get("pressed", [])),
			_to_string_array(p2_input.get("held", [])),
			_to_string_array(p2_input.get("released", []))
		)


func _update_online_input() -> void:
	if not NetworkManager.is_online_session() or active_fighter_a == null or active_fighter_b == null:
		return
	var read_p1: Callable = func(): return _read_player_input(1)
	var read_p2: Callable = func(): return _read_player_input(2)
	var apply: Callable = func(fid: int, p1: Dictionary, p2: Dictionary): _apply_online_frame(fid, p1, p2)
	if NetworkManager.is_host():
		NetworkManager.poll_and_advance(read_p1, read_p2, apply)
	else:
		var max_catch_up: int = 5
		for _i in range(max_catch_up):
			if not NetworkManager.poll_and_advance(Callable(), Callable(), apply):
				break
		var my_in: Dictionary = _read_player_input(2)
		NetworkManager.send_my_input(
			my_in.get("direction", Vector2.ZERO),
			my_in.get("pressed", []),
			my_in.get("held", []),
			my_in.get("released", [])
		)


func _learned_ai_state_vector(fighter: FighterBase, target: FighterBase) -> Array:
	var dx: float = target.global_position.x - fighter.global_position.x
	var abs_dx: float = absf(dx)
	var dist_bucket: int = 0
	if abs_dx > 4.5:
		dist_bucket = 2
	elif abs_dx > 1.8:
		dist_bucket = 1
	var facing_right: bool = true
	if fighter.command_interpreter != null:
		facing_right = fighter.command_interpreter.get_facing_right()
	var facing: int = 1 if (dx > 0 and facing_right) or (dx < 0 and not facing_right) else -1
	var opp_movetype: int = 0
	if target.has_method("get_runtime_movetype"):
		var mt: String = str(target.call("get_runtime_movetype"))
		if mt == "A":
			opp_movetype = 1
		elif mt == "H":
			opp_movetype = 2
	var self_control: int = 1 if bool(fighter.get("state_control_enabled")) else 0
	var dy: float = target.global_position.y - fighter.global_position.y
	var rel_y_bucket: int = 0
	if dy > 0.4:
		rel_y_bucket = 1
	elif dy < -0.4:
		rel_y_bucket = 2
	return [dist_bucket, facing, opp_movetype, self_control, rel_y_bucket]


func _learned_ai_action_to_serializable(action: Dictionary) -> Dictionary:
	var d: Vector2 = action.get("direction", Vector2.ZERO)
	return {
		"d": [d.x, d.y],
		"p": _to_string_array(action.get("pressed", [])),
		"h": _to_string_array(action.get("held", [])),
		"r": _to_string_array(action.get("released", []))
	}


func _learned_ai_action_from_serializable(data: Dictionary) -> Dictionary:
	var arr_d: Array = data.get("d", [0.0, 0.0])
	var dir: Vector2 = Vector2(float(arr_d[0]) if arr_d.size() > 0 else 0.0, float(arr_d[1]) if arr_d.size() > 1 else 0.0)
	return _cpu_input_frame(dir, _to_string_array(data.get("p", [])), _to_string_array(data.get("h", [])), _to_string_array(data.get("r", [])))


func _learned_ai_load(mod_directory: String) -> Array:
	if mod_directory.is_empty():
		return []
	if learned_ai_cache.has(mod_directory):
		return learned_ai_cache[mod_directory]
	var path: String = "%s%s" % [mod_directory, LEARNED_AI_FILENAME]
	if not FileAccess.file_exists(path):
		learned_ai_cache[mod_directory] = []
		return []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		learned_ai_cache[mod_directory] = []
		return []
	var text: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		learned_ai_cache[mod_directory] = []
		return []
	var samples: Array = parsed.get("samples", [])
	if not (samples is Array):
		learned_ai_cache[mod_directory] = []
		return []
	learned_ai_cache[mod_directory] = samples
	return samples


func _learned_ai_save(mod_directory: String, new_samples: Array) -> void:
	if mod_directory.is_empty() or new_samples.is_empty():
		return
	var existing: Array = _learned_ai_load(mod_directory)
	for s in new_samples:
		existing.append(s)
	while existing.size() > LEARNED_AI_MAX_SAMPLES:
		existing.remove_at(0)
	learned_ai_cache[mod_directory] = existing
	var path: String = "%s%s" % [mod_directory, LEARNED_AI_FILENAME]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"samples": existing}))
	file.close()


func _learned_ai_lookup(cpu: FighterBase, target: FighterBase) -> Dictionary:
	var mod_dir: String = cpu.get_mod_directory()
	if mod_dir.is_empty():
		return {}
	var samples: Array = _learned_ai_load(mod_dir)
	if samples.is_empty():
		return {}
	var state: Array = _learned_ai_state_vector(cpu, target)
	var matches: Array = []
	for entry in samples:
		if not (entry is Dictionary):
			continue
		var s: Array = entry.get("s", [])
		var compare_len: int = mini(s.size(), state.size())
		if compare_len < 4:
			continue
		var same: bool = true
		for i in range(compare_len):
			var si: int = int(s[i]) if i < s.size() else 0
			var st: int = int(state[i]) if i < state.size() else 0
			if si != st:
				same = false
				break
		if same:
			matches.append(entry)
	if matches.is_empty():
		return {}
	var chosen: Dictionary = matches[cpu_rng.randi_range(0, matches.size() - 1)]
	var a: Variant = chosen.get("a", {})
	if a is Dictionary:
		return _learned_ai_action_from_serializable(a)
	return {}


func _learned_ai_flush_record_buffer() -> void:
	if learned_ai_record_buffer.is_empty():
		return
	if active_fighter_a == null or not is_instance_valid(active_fighter_a):
		return
	var mod_dir: String = active_fighter_a.get_mod_directory()
	if mod_dir.is_empty():
		return
	_learned_ai_save(mod_dir, learned_ai_record_buffer.duplicate())
	learned_ai_record_buffer.clear()


func _drive_cpu_fighter(cpu: FighterBase, target: FighterBase) -> void:
	if cpu == null or target == null:
		return
	if cpu.health <= 0:
		return
	if cpu.command_interpreter == null:
		return
	var learned_action: Dictionary = _learned_ai_lookup(cpu, target)
	if not learned_action.is_empty():
		_cpu_submit_ai_frame(cpu, learned_action)
		return
	var brain: Dictionary = _cpu_brain(cpu)
	_tick_cpu_brain(brain)
	var dx: float = target.global_position.x - cpu.global_position.x
	var abs_dx: float = absf(dx)
	var abs_dy: float = absf(target.global_position.y - cpu.global_position.y)
	var target_attacking: bool = target.has_method("get_runtime_movetype") and str(target.call("get_runtime_movetype")) == "A"
	var target_in_hitstun: bool = target.has_method("get_runtime_movetype") and str(target.call("get_runtime_movetype")) == "H"
	var target_has_projectile: bool = target.has_method("get_num_projectiles") and int(target.call("get_num_projectiles")) > 0
	var can_control: bool = bool(cpu.get("state_control_enabled"))

	if _cpu_should_guard(cpu, target, abs_dx, abs_dy, target_attacking, target_has_projectile):
		brain["guard_frames"] = maxi(int(brain.get("guard_frames", 0)), CPU_GUARD_HOLD_FRAMES)
	if int(brain.get("guard_frames", 0)) > 0:
		_cpu_submit_ai_frame(cpu, _cpu_guard_frame(cpu, target))
		return

	if not can_control:
		_cpu_submit_ai_frame(cpu, _cpu_input_frame(Vector2.ZERO))
		return

	var action_cooldown: int = int(brain.get("action_cooldown", 0))
	var command_entry: Dictionary = {}
	if abs_dy <= CPU_VERTICAL_COMMIT_RANGE:
		if abs_dx >= CPU_PROJECTILE_RANGE and action_cooldown <= 0 and not target_in_hitstun and not _cpu_has_active_projectile(cpu):
			command_entry = _cpu_pick_projectile_command(cpu)
			if _cpu_try_use_command(cpu, command_entry):
				brain["action_cooldown"] = CPU_PROJECTILE_COOLDOWN_FRAMES
				return
		if abs_dx <= CPU_THROW_RANGE and action_cooldown <= 0 and not target_in_hitstun and cpu_rng.randf() < 0.18:
			command_entry = _cpu_pick_throw_command(cpu)
			if _cpu_try_use_command(cpu, command_entry):
				brain["action_cooldown"] = CPU_ATTACK_COOLDOWN_FRAMES
				return
		if abs_dx <= CPU_MELEE_RANGE and action_cooldown <= 0:
			command_entry = _cpu_pick_melee_command(cpu, target_in_hitstun)
			if _cpu_try_use_command(cpu, command_entry):
				brain["action_cooldown"] = CPU_COMBO_COOLDOWN_FRAMES if target_in_hitstun else CPU_ATTACK_COOLDOWN_FRAMES
				return

	_cpu_submit_ai_frame(cpu, _cpu_input_frame(Vector2(_cpu_move_toward_target(dx, abs_dx, target_in_hitstun, action_cooldown), 0.0)))


func _cpu_brain(cpu: FighterBase) -> Dictionary:
	var key: int = cpu.get_instance_id()
	if not cpu_brains.has(key):
		cpu_brains[key] = {
			"action_cooldown": 0,
			"guard_frames": 0
		}
	return cpu_brains[key]


func _tick_cpu_brain(brain: Dictionary) -> void:
	var action_cooldown: int = int(brain.get("action_cooldown", 0))
	if action_cooldown > 0:
		brain["action_cooldown"] = action_cooldown - 1
	var guard_frames: int = int(brain.get("guard_frames", 0))
	if guard_frames > 0:
		brain["guard_frames"] = guard_frames - 1


func _cpu_should_guard(cpu: FighterBase, target: FighterBase, abs_dx: float, abs_dy: float, target_attacking: bool, target_has_projectile: bool) -> bool:
	if abs_dy > CPU_VERTICAL_COMMIT_RANGE * 1.35:
		return false
	if target_attacking and abs_dx <= CPU_GUARD_RANGE:
		return true
	if target_has_projectile and abs_dx <= CPU_PROJECTILE_GUARD_RANGE:
		return true
	if target_attacking and target.global_position.y > cpu.global_position.y and abs_dx <= CPU_GUARD_RANGE * 1.2:
		return true
	return false


func _cpu_guard_frame(cpu: FighterBase, target: FighterBase) -> Dictionary:
	var raw_back: float = _cpu_back_axis(cpu)
	var guard_y: float = 0.0
	if target.has_method("get_runtime_statetype") and str(target.call("get_runtime_statetype")) != "A":
		guard_y = 1.0
	return _cpu_input_frame(Vector2(raw_back, guard_y))


func _cpu_move_toward_target(dx: float, abs_dx: float, target_in_hitstun: bool, action_cooldown: int) -> float:
	if target_in_hitstun and abs_dx > 0.7:
		return signf(dx)
	if abs_dx > CPU_MELEE_RANGE:
		return signf(dx)
	if abs_dx < 0.65 and action_cooldown > 0:
		return -signf(dx)
	if abs_dx > CPU_APPROACH_RANGE:
		return signf(dx)
	return 0.0


func _cpu_pick_projectile_command(cpu: FighterBase) -> Dictionary:
	var candidates: Array = []
	for entry_variant in _cpu_command_entries(cpu):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if not _cpu_command_is_projectile(cpu, entry):
			continue
		if _cpu_build_command_frames(cpu, entry).is_empty():
			continue
		candidates.append(entry)
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a, b): return _cpu_command_score(str(a.get("id", "")), true) < _cpu_command_score(str(b.get("id", "")), true))
	return candidates[0]


func _cpu_pick_throw_command(cpu: FighterBase) -> Dictionary:
	var candidates: Array = []
	for entry_variant in _cpu_command_entries(cpu):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if not _cpu_command_is_throw(cpu, entry):
			continue
		if _cpu_build_command_frames(cpu, entry).is_empty():
			continue
		candidates.append(entry)
	if candidates.is_empty():
		return {}
	return candidates[0]


func _cpu_pick_melee_command(cpu: FighterBase, prefer_fast: bool) -> Dictionary:
	var candidates: Array = []
	for entry_variant in _cpu_command_entries(cpu):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if not _cpu_command_is_melee(cpu, entry):
			continue
		if _cpu_build_command_frames(cpu, entry).is_empty():
			continue
		candidates.append(entry)
	if candidates.is_empty():
		return {}
	candidates.sort_custom(
		func(a, b):
			return _cpu_command_score(_cpu_command_label(a), prefer_fast) < _cpu_command_score(_cpu_command_label(b), prefer_fast)
	)
	var best_count: int = mini(candidates.size(), 2)
	return candidates[cpu_rng.randi_range(0, best_count - 1)]


func _cpu_command_entries(cpu: FighterBase) -> Array:
	if cpu.command_data.has("commands") and cpu.command_data.get("commands") is Array:
		return cpu.command_data.get("commands", [])
	return []


func _cpu_command_is_projectile(cpu: FighterBase, entry: Dictionary) -> bool:
	if bool(entry.get("revert_transform", false)) or entry.has("transform_to"):
		return false
	var state_info: Dictionary = _cpu_target_state_info(cpu, entry)
	var projectiles = state_info.get("projectiles", [])
	if projectiles is Array and not (projectiles as Array).is_empty():
		return true
	var label: String = _cpu_command_label(entry)
	return (
		label.find("projectile") != -1
		or label.find("qcf") != -1
		or label.find("fireball") != -1
		or label.find("blast") != -1
		or label.find("beam") != -1
		or label.find("special") != -1
		or label.find("shoot") != -1
	)


func _cpu_command_is_throw(cpu: FighterBase, entry: Dictionary) -> bool:
	var state_info: Dictionary = _cpu_target_state_info(cpu, entry)
	var throwboxes = state_info.get("throwboxes", [])
	if throwboxes is Array and not (throwboxes as Array).is_empty():
		return true
	var label: String = _cpu_command_label(entry)
	return label.find("throw") != -1 or label.find("grapple") != -1 or label.find("grab") != -1


func _cpu_command_is_melee(cpu: FighterBase, entry: Dictionary) -> bool:
	if _cpu_command_is_projectile(cpu, entry) or _cpu_command_is_throw(cpu, entry):
		return false
	if bool(entry.get("revert_transform", false)) or entry.has("transform_to"):
		return false
	var label: String = _cpu_command_label(entry)
	if label.find("parry") != -1 or label.find("guard") != -1:
		return false
	var state_info: Dictionary = _cpu_target_state_info(cpu, entry)
	var hitboxes = state_info.get("hitboxes", [])
	return hitboxes is Array and not (hitboxes as Array).is_empty()


func _cpu_target_state_info(cpu: FighterBase, entry: Dictionary) -> Dictionary:
	var target_state: String = str(entry.get("target_state", ""))
	if target_state.is_empty():
		return {}
	if not cpu.state_data.has(target_state):
		return {}
	var state_info = cpu.state_data.get(target_state, {})
	return state_info if state_info is Dictionary else {}


func _cpu_command_label(entry: Dictionary) -> String:
	return ("%s %s" % [str(entry.get("id", "")), str(entry.get("target_state", ""))]).to_lower()


func _cpu_command_score(label: String, prefer_fast: bool) -> int:
	var score: int = 100
	if label.find("light") != -1 or label.find("jab") != -1 or label.find("p_light") != -1:
		score -= 35
	if label.find("punch") != -1 or label.find("kick") != -1:
		score -= 10
	if label.find("heavy") != -1 or label.find("strong") != -1:
		score += 18
	if label.find("qcf") != -1 or label.find("special") != -1:
		score += 10 if prefer_fast else -6
	if prefer_fast:
		score -= 12
	return score


func _cpu_try_use_command(cpu: FighterBase, entry: Dictionary) -> bool:
	if entry.is_empty() or cpu.state_controller == null:
		return false
	var command_id: String = str(entry.get("id", ""))
	var target_state: String = str(entry.get("target_state", ""))
	if command_id.is_empty() or target_state.is_empty():
		return false
	if not cpu._can_enter_state_from_current(target_state):
		return false
	var before_state: String = cpu.state_controller.current_state
	cpu._on_command_matched(command_id, entry)
	return cpu.state_controller.current_state != before_state


func _cpu_build_command_frames(cpu: FighterBase, entry: Dictionary) -> Array:
	var pattern = entry.get("pattern", [])
	if not (pattern is Array) or (pattern as Array).is_empty():
		return []
	var source_pattern: Array = pattern
	if source_pattern.size() >= 6 and str(source_pattern[0]).to_lower() == "hold":
		return []
	var frames: Array = []
	for token in source_pattern:
		var frame: Dictionary = _cpu_frame_for_pattern_token(cpu, token)
		if frame.is_empty():
			return []
		frames.append(frame)
	return frames


func _cpu_frame_for_pattern_token(cpu: FighterBase, token) -> Dictionary:
	if typeof(token) == TYPE_INT:
		return _cpu_input_frame(_cpu_raw_vector_from_numpad(cpu, int(token)))
	if typeof(token) != TYPE_STRING:
		return {}
	var text: String = str(token).strip_edges()
	if text.is_empty():
		return {}
	var direction: Vector2 = Vector2.ZERO
	var pressed: Array[String] = []
	var held: Array[String] = []
	var released: Array[String] = []
	for part in text.split("+", false):
		var trimmed: String = str(part).strip_edges()
		if trimmed.is_empty():
			continue
		var upper: String = trimmed.to_upper()
		var direction_token: int = _cpu_direction_token_to_numpad(upper)
		if direction_token != -1:
			direction = _cpu_raw_vector_from_numpad(cpu, direction_token)
			continue
		if upper.begins_with("HOLD:"):
			var held_button: String = _cpu_button_token(upper.substr(5))
			if held_button.is_empty():
				return {}
			held.append(held_button)
			continue
		if upper.begins_with("RELEASE:"):
			var released_button: String = _cpu_button_token(upper.substr(8))
			if released_button.is_empty():
				return {}
			released.append(released_button)
			continue
		var button: String = _cpu_button_token(upper)
		if button.is_empty():
			return {}
		pressed.append(button)
	return _cpu_input_frame(direction, pressed, held, released)


func _cpu_button_token(token: String) -> String:
	match token.strip_edges().to_upper():
		"P", "PUNCH":
			return "P"
		"K", "KICK":
			return "K"
		"S", "SPECIAL":
			return "S"
		"H", "HEAVY":
			return "H"
	return ""


func _cpu_direction_token_to_numpad(token: String) -> int:
	var text: String = token.strip_edges().to_upper()
	if text.is_valid_int():
		var value: int = int(text)
		if value >= 1 and value <= 9:
			return value
	match text:
		"U", "UP":
			return 8
		"D", "DOWN":
			return 2
		"L", "LEFT", "B", "BACK":
			return 4
		"R", "RIGHT", "F", "FORWARD":
			return 6
		"UB", "UPBACK", "UP-BACK":
			return 7
		"UF", "UPFORWARD", "UP-FORWARD":
			return 9
		"DB", "DOWNBACK", "DOWN-BACK":
			return 1
		"DF", "DOWNFORWARD", "DOWN-FORWARD":
			return 3
		"N", "NEUTRAL":
			return 5
	return -1


func _cpu_raw_vector_from_numpad(cpu: FighterBase, numpad: int) -> Vector2:
	var facing_right: bool = cpu.command_interpreter == null or cpu.command_interpreter.get_facing_right()
	var x: float = 0.0
	var y: float = 0.0
	match numpad:
		1:
			x = -1.0
			y = 1.0
		2:
			y = 1.0
		3:
			x = 1.0
			y = 1.0
		4:
			x = -1.0
		6:
			x = 1.0
		7:
			x = -1.0
			y = -1.0
		8:
			y = -1.0
		9:
			x = 1.0
			y = -1.0
	if not facing_right:
		x *= -1.0
	return Vector2(x, y)


func _cpu_back_axis(cpu: FighterBase) -> float:
	if cpu.command_interpreter == null or cpu.command_interpreter.get_facing_right():
		return -1.0
	return 1.0


func _cpu_has_active_projectile(cpu: FighterBase) -> bool:
	return cpu.has_method("get_num_projectiles") and int(cpu.call("get_num_projectiles")) > 0


func _cpu_input_frame(direction: Vector2, pressed: Array[String] = [], held: Array[String] = [], released: Array[String] = []) -> Dictionary:
	return {
		"direction": direction,
		"pressed": pressed.duplicate(),
		"held": held.duplicate(),
		"released": released.duplicate()
	}


func _cpu_submit_ai_frame(cpu: FighterBase, frame: Dictionary) -> void:
	if cpu == active_fighter_b:
		_last_p2_cpu_frame = {
			"direction": frame.get("direction", Vector2.ZERO),
			"pressed": (frame.get("pressed", []) as Array).duplicate(),
			"held": (frame.get("held", []) as Array).duplicate(),
			"released": (frame.get("released", []) as Array).duplicate()
		}
	cpu.command_interpreter.enqueue_external_input(
		frame.get("direction", Vector2.ZERO),
		_to_string_array(frame.get("pressed", [])),
		_to_string_array(frame.get("held", [])),
		_to_string_array(frame.get("released", []))
	)


func _update_hud() -> void:
	var target_hud: CanvasLayer = smash_battle_hud if smash_mode_enabled else battle_hud
	if target_hud == null:
		return
	var p1_health: int = active_fighter_a.health if active_fighter_a != null else 0
	var p2_health: int = active_fighter_b.health if active_fighter_b != null else 0
	var p1_max_health: int = active_fighter_a.max_health if active_fighter_a != null else 1000
	var p2_max_health: int = active_fighter_b.max_health if active_fighter_b != null else 1000
	var p1_resource: int = active_fighter_a.resource if active_fighter_a != null else 0
	var p2_resource: int = active_fighter_b.resource if active_fighter_b != null else 0
	var p1_max_resource: int = active_fighter_a.max_resource if active_fighter_a != null else 100
	var p2_max_resource: int = active_fighter_b.max_resource if active_fighter_b != null else 100
	var status_display: String = status_text
	var p1_team_remaining: int = 1
	var p2_team_remaining: int = 1
	var team_mode_label: String = ""
	var p1_team_status: Array[Dictionary] = []
	var p2_team_status: Array[Dictionary] = []
	if team_mode_enabled:
		p1_team_remaining = _count_team_remaining(true)
		p2_team_remaining = _count_team_remaining(false)
		team_mode_label = team_mode_subtype.to_upper()
		status_display = "%s | P1:%d P2:%d | %s" % [team_mode_label, p1_team_remaining, p2_team_remaining, status_text]
		if team_mode_subtype == "simul":
			p1_team_status = _build_simul_team_status(true)
			p2_team_status = _build_simul_team_status(false)
	if smash_mode_enabled and active_fighter_a != null and active_fighter_b != null:
		status_display = "P1 %d stock | %.0f%%   vs   P2 %d stock | %.0f%%" % [p1_stocks, active_fighter_a.smash_percent, p2_stocks, active_fighter_b.smash_percent]
	if round_reset_pending and not replay_playback_active and dummy_uses_local_input and input_replay_recorder != null and input_replay_recorder.get_recorded_frame_count() > 0:
		status_display += " | R=Replay"
	target_hud.call(
		"set_battle_state",
		{
			"p1_health": p1_health,
			"p2_health": p2_health,
			"p1_max_health": p1_max_health,
			"p2_max_health": p2_max_health,
			"p1_resource": p1_resource,
			"p2_resource": p2_resource,
			"p1_max_resource": p1_max_resource,
			"p2_max_resource": p2_max_resource,
			"time_left": round_time_left,
			"round_number": round_number,
			"p1_wins": p1_wins,
			"p2_wins": p2_wins,
			"status": status_display,
			"p1_stocks": p1_stocks,
			"p2_stocks": p2_stocks,
			"p1_percent": active_fighter_a.smash_percent if active_fighter_a != null else 0.0,
			"p2_percent": active_fighter_b.smash_percent if active_fighter_b != null else 0.0,
			"team_mode": team_mode_enabled,
			"team_mode_subtype": team_mode_subtype,
			"p1_team_remaining": p1_team_remaining,
			"p2_team_remaining": p2_team_remaining,
			"p1_team_status": p1_team_status,
			"p2_team_status": p2_team_status
		}
	)


func _count_team_remaining(is_p1: bool) -> int:
	if not team_mode_enabled:
		return 1
	if team_mode_subtype == "tag":
		var roster: Array[Dictionary] = team_roster_p1 if is_p1 else team_roster_p2
		var alive_slots: int = 0
		for entry in roster:
			if int(entry.get("saved_health", 1)) > 0:
				alive_slots += 1
		return alive_slots
	var fighters: Array[FighterBase] = team_fighters_p1 if is_p1 else team_fighters_p2
	var count: int = 0
	for fighter in fighters:
		if fighter != null and is_instance_valid(fighter) and fighter.health > 0:
			count += 1
	return count


func _build_simul_team_status(is_p1: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var fighters: Array[FighterBase] = team_fighters_p1 if is_p1 else team_fighters_p2
	for idx in range(fighters.size()):
		var fighter: FighterBase = fighters[idx]
		if fighter == null or not is_instance_valid(fighter):
			continue
		out.append(
			{
				"slot": idx + 1,
				"hp": fighter.health,
				"hp_max": fighter.max_health,
				"res": fighter.resource,
				"res_max": fighter.max_resource,
				"alive": fighter.health > 0 and fighter.visible
			}
		)
	return out


func _build_pause_move_list_text() -> String:
	var lines: Array[String] = []
	lines.append("P1 Moves")
	lines.append_array(_extract_move_list_for_fighter(active_fighter_a))
	lines.append("")
	lines.append("P2 Moves")
	lines.append_array(_extract_move_list_for_fighter(active_fighter_b))
	return "\n".join(lines)


func _extract_move_list_for_fighter(fighter: FighterBase) -> Array[String]:
	var lines: Array[String] = []
	if fighter == null:
		lines.append("- No fighter loaded")
		return lines
	var commands_root: Dictionary = fighter.command_data if fighter.command_data != null else {}
	var command_list_raw = commands_root.get("commands", [])
	if not (command_list_raw is Array) or (command_list_raw as Array).is_empty():
		lines.append("- No commands found")
		return lines
	for entry_raw in command_list_raw:
		if not (entry_raw is Dictionary):
			continue
		var entry: Dictionary = entry_raw
		var command_id: String = str(entry.get("id", "move")).replace("_", " ").to_upper()
		var pattern_text: String = _format_command_pattern(entry.get("pattern", []))
		if pattern_text.is_empty():
			pattern_text = "N/A"
		lines.append("- %s : %s" % [command_id, pattern_text])
	if lines.is_empty():
		lines.append("- No commands found")
	return lines


func _format_command_pattern(raw_pattern: Variant) -> String:
	if not (raw_pattern is Array):
		return ""
	var parts: Array[String] = []
	for step in raw_pattern:
		match typeof(step):
			TYPE_INT, TYPE_FLOAT:
				parts.append(_num_to_direction(int(step)))
			_:
				parts.append(str(step).to_upper())
	return " > ".join(parts)


func _num_to_direction(value: int) -> String:
	match value:
		1:
			return "DOWN-BACK"
		2:
			return "DOWN"
		3:
			return "DOWN-FORWARD"
		4:
			return "BACK"
		5:
			return "NEUTRAL"
		6:
			return "FORWARD"
		7:
			return "UP-BACK"
		8:
			return "UP"
		9:
			return "UP-FORWARD"
		_:
			return str(value)


func _apply_hud_mode() -> void:
	if battle_hud != null:
		battle_hud.visible = not smash_mode_enabled
	if smash_battle_hud != null:
		smash_battle_hud.visible = smash_mode_enabled


func _configure_smash_mode_for_fighters() -> void:
	if active_fighter_a == null or active_fighter_b == null:
		return
	active_fighter_a.set_smash_mode_enabled(smash_mode_enabled)
	active_fighter_b.set_smash_mode_enabled(smash_mode_enabled)
	active_fighter_a.reset_smash_state()
	active_fighter_b.reset_smash_state()
	if active_fighter_a.damage_system != null:
		active_fighter_a.damage_system.set_smash_mode_enabled(smash_mode_enabled)
	if active_fighter_b.damage_system != null:
		active_fighter_b.damage_system.set_smash_mode_enabled(smash_mode_enabled)
	if smash_mode_enabled:
		p1_stocks = maxi(1, smash_starting_stocks)
		p2_stocks = maxi(1, smash_starting_stocks)


func _apply_input_buffer_setting() -> void:
	if input_buffer_viewer == null:
		return
	var cfg := ConfigFile.new()
	var show_viewer: bool = false
	if cfg.load("user://options.cfg") == OK:
		show_viewer = bool(cfg.get_value("debug", "show_input_buffer", false))
	input_buffer_viewer.visible = show_viewer
