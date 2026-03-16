extends Camera3D
class_name CameraController

@export var fighter_a_path: NodePath
@export var fighter_b_path: NodePath
@export var tracked_fighter_paths: Array[NodePath] = []
@export var follow_height: float = 4.0
@export var min_depth: float = 9.0
@export var max_depth: float = 16.0
@export var horizontal_deadzone: float = 1.5
@export var max_tracked_distance: float = 12.0
@export var max_vertical_span: float = 6.0
@export var position_smoothing: float = 5.5
@export var look_smoothing: float = 6.5
@export var velocity_look_lead: float = 0.22
@export var stage_left_limit: float = -100.0
@export var stage_right_limit: float = 100.0
@export var min_fov: float = 48.0
@export var max_fov: float = 72.0
@export var stage_anchor_follow_strength: float = 0.85
@export var distance_depth_factor: float = 0.7
@export var look_height_offset: float = 1.0
@export var distance_height_factor: float = 0.22
## When true, camera stays focused on the stage and only zooms out based on player distance (Smash-style). Reduces shake.
@export var use_focus_camera: bool = true
## When use_focus_camera is true, how much the look target can drift toward player midpoint (0 = pure stage, 1 = old behavior).
@export var focus_camera_pan_blend: float = 0.0
## When true and only one fighter is tracked (e.g. round end), camera zooms in on the winner.
var winner_zoom_enabled: bool = false
@export var winner_zoom_depth: float = 5.5
@export var winner_zoom_fov: float = 36.0

var look_target: Vector3 = Vector3.ZERO
var stage_anchor_position: Vector3 = Vector3.ZERO
var stage_anchor_look_target: Vector3 = Vector3.ZERO
var shake_time_remaining: float = 0.0
var shake_freq: float = 60.0
var shake_ampl: float = -0.16
var shake_phase: float = 0.0
var base_position_for_shake: Vector3 = Vector3.ZERO


func request_screen_shake(time_ticks: int, freq: float = 60.0, ampl: float = -0.16, phase: float = 0.0) -> void:
	shake_time_remaining = maxf(shake_time_remaining, float(time_ticks) / 60.0)
	shake_freq = freq
	shake_ampl = ampl
	shake_phase = phase
	if base_position_for_shake == Vector3.ZERO:
		base_position_for_shake = global_position


func _ready() -> void:
	look_target = global_position + -global_transform.basis.z * 8.0
	stage_anchor_position = global_position
	stage_anchor_look_target = look_target


func set_stage_camera_anchor(position_value: Vector3, look_value: Vector3) -> void:
	stage_anchor_position = position_value
	stage_anchor_look_target = look_value
	look_target = look_value


func set_tracked_fighter_paths(paths: Array[NodePath]) -> void:
	tracked_fighter_paths = paths.duplicate()


func _process(delta: float) -> void:
	var tracked_fighters: Array[Node3D] = _get_tracked_fighters()
	if tracked_fighters.is_empty():
		return

	# Winner zoom: single fighter (round/match end), zoom in on them
	if winner_zoom_enabled and tracked_fighters.size() == 1:
		var winner: Node3D = tracked_fighters[0]
		var target_pos: Vector3 = Vector3(
			winner.global_position.x,
			winner.global_position.y + follow_height,
			winner.global_position.z + winner_zoom_depth
		)
		var desired_look_pos: Vector3 = winner.global_position + Vector3(0.0, look_height_offset, 0.0)
		look_target = look_target.lerp(desired_look_pos, clampf(delta * look_smoothing, 0.0, 1.0))
		global_position = global_position.lerp(target_pos, clampf(delta * position_smoothing, 0.0, 1.0))
		look_at(look_target, Vector3.UP)
		fov = lerpf(fov, winner_zoom_fov, clampf(delta * 3.0, 0.0, 1.0))
		if shake_time_remaining > 0.0:
			shake_time_remaining -= delta
			var t: float = float(Engine.get_process_frames()) * 0.0166667 * shake_freq + shake_phase
			var shake_offset: float = shake_ampl * sin(t * TAU)
			var pos := global_position
			pos.y += shake_offset
			global_position = pos
		return

	var midpoint: Vector3 = Vector3.ZERO
	for fighter in tracked_fighters:
		midpoint += fighter.global_position
	midpoint /= float(tracked_fighters.size())

	var same_focus_target: bool = tracked_fighters.size() <= 1
	var furthest_distance: float = _furthest_tracked_distance(tracked_fighters)
	var spread_y: float = _tracked_vertical_span(tracked_fighters)
	var spread_from_center: float = _horizontal_spread_from_center(tracked_fighters)
	var depth_t: float = clampf((furthest_distance - horizontal_deadzone) / maxf(0.01, max_tracked_distance - horizontal_deadzone), 0.0, 1.0)
	var vertical_t: float = clampf(spread_y / maxf(0.01, max_vertical_span), 0.0, 1.0)
	var center_t: float = clampf(spread_from_center / maxf(0.01, max_tracked_distance), 0.0, 1.0)
	var frame_t: float
	var desired_depth: float
	if use_focus_camera:
		var zoom_t: float = 1.0 if same_focus_target else maxf(maxf(depth_t, vertical_t), center_t)
		frame_t = zoom_t
		desired_depth = clampf(min_depth + (maxf(furthest_distance, spread_from_center) * distance_depth_factor), min_depth, max_depth)
	else:
		frame_t = 1.0 if same_focus_target else maxf(depth_t, vertical_t)
		desired_depth = clampf(min_depth + (furthest_distance * distance_depth_factor), min_depth, max_depth)

	var target_position: Vector3
	var desired_look: Vector3
	if use_focus_camera:
		# Fixed on stage center; zoom out only (so both players visible even when on one side)
		var depth_offset: float = desired_depth - min_depth
		target_position = Vector3(
			stage_anchor_position.x,
			stage_anchor_position.y + (furthest_distance * distance_height_factor),
			stage_anchor_position.z + depth_offset
		)
		desired_look = stage_anchor_look_target
		look_target = look_target.lerp(desired_look, clampf(delta * look_smoothing, 0.0, 1.0))
	else:
		var clamped_mid_x: float = clampf(midpoint.x, stage_left_limit, stage_right_limit)
		target_position = Vector3(
			clamped_mid_x,
			midpoint.y + follow_height + (furthest_distance * distance_height_factor),
			midpoint.z + desired_depth
		)
		var avg_velocity_x: float = 0.0
		var velocity_sources: int = 0
		for fighter in tracked_fighters:
			if fighter is CharacterBody3D:
				avg_velocity_x += (fighter as CharacterBody3D).velocity.x
				velocity_sources += 1
		if velocity_sources > 0:
			avg_velocity_x /= float(velocity_sources)
		desired_look = Vector3(clamped_mid_x + avg_velocity_x * velocity_look_lead, midpoint.y + look_height_offset, midpoint.z)
		look_target = look_target.lerp(desired_look, clampf(delta * look_smoothing, 0.0, 1.0))

	var clean_position: Vector3 = global_position.lerp(target_position, clampf(delta * position_smoothing, 0.0, 1.0))
	look_at(look_target, Vector3.UP)

	fov = lerpf(min_fov, max_fov, frame_t)

	if shake_time_remaining > 0.0:
		shake_time_remaining -= delta
		var t: float = float(Engine.get_process_frames()) * 0.0166667 * shake_freq + shake_phase
		var shake_offset: float = shake_ampl * sin(t * TAU)
		clean_position.y += shake_offset
		if shake_time_remaining <= 0.0:
			shake_time_remaining = 0.0

	global_position = clean_position


func _get_tracked_fighters() -> Array[Node3D]:
	var result: Array[Node3D] = []
	var paths: Array[NodePath] = tracked_fighter_paths
	if paths.is_empty():
		paths = [fighter_a_path, fighter_b_path]
	for fighter_path in paths:
		if fighter_path.is_empty():
			continue
		var fighter := get_node_or_null(fighter_path) as Node3D
		if fighter == null:
			continue
		if result.has(fighter):
			continue
		result.append(fighter)
	return result


func _furthest_tracked_distance(fighters: Array[Node3D]) -> float:
	var furthest: float = 0.0
	for i in range(fighters.size()):
		for j in range(i + 1, fighters.size()):
			var a: Node3D = fighters[i]
			var b: Node3D = fighters[j]
			var dx: float = a.global_position.x - b.global_position.x
			var dy: float = a.global_position.y - b.global_position.y
			furthest = maxf(furthest, sqrt((dx * dx) + (dy * dy)))
	return furthest


func _tracked_vertical_span(fighters: Array[Node3D]) -> float:
	if fighters.is_empty():
		return 0.0
	var min_y: float = fighters[0].global_position.y
	var max_y: float = min_y
	for fighter in fighters:
		min_y = minf(min_y, fighter.global_position.y)
		max_y = maxf(max_y, fighter.global_position.y)
	return max_y - min_y


func _horizontal_spread_from_center(fighters: Array[Node3D]) -> float:
	if fighters.is_empty():
		return 0.0
	var center_x: float = stage_anchor_look_target.x
	var spread: float = 0.0
	for fighter in fighters:
		spread = maxf(spread, absf(fighter.global_position.x - center_x))
	return spread
