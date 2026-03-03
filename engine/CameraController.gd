extends Camera3D
class_name CameraController

@export var fighter_a_path: NodePath
@export var fighter_b_path: NodePath
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

var look_target: Vector3 = Vector3.ZERO
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


func _process(delta: float) -> void:
	var fighter_a := get_node_or_null(fighter_a_path) as Node3D
	var fighter_b := get_node_or_null(fighter_b_path) as Node3D
	if fighter_a == null or fighter_b == null:
		return

	var midpoint: Vector3 = (fighter_a.global_position + fighter_b.global_position) * 0.5
	var spread_x: float = absf(fighter_a.global_position.x - fighter_b.global_position.x)
	var depth_t: float = clampf((spread_x - horizontal_deadzone) / maxf(0.01, max_tracked_distance - horizontal_deadzone), 0.0, 1.0)
	var spread_y: float = absf(fighter_a.global_position.y - fighter_b.global_position.y)
	var vertical_t: float = clampf(spread_y / maxf(0.01, max_vertical_span), 0.0, 1.0)
	var frame_t: float = maxf(depth_t, vertical_t)
	var desired_depth: float = lerpf(min_depth, max_depth, frame_t)

	var clamped_mid_x: float = clampf(midpoint.x, stage_left_limit, stage_right_limit)
	var target_position := Vector3(clamped_mid_x, midpoint.y + follow_height + spread_y * 0.4, midpoint.z + desired_depth)
	var clean_position: Vector3 = global_position.lerp(target_position, clampf(delta * position_smoothing, 0.0, 1.0))

	var avg_velocity_x: float = 0.0
	if fighter_a is CharacterBody3D and fighter_b is CharacterBody3D:
		avg_velocity_x = ((fighter_a as CharacterBody3D).velocity.x + (fighter_b as CharacterBody3D).velocity.x) * 0.5

	var desired_look := Vector3(clamped_mid_x + avg_velocity_x * velocity_look_lead, midpoint.y + 1.0 + spread_y * 0.2, midpoint.z)
	look_target = look_target.lerp(desired_look, clampf(delta * look_smoothing, 0.0, 1.0))
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
