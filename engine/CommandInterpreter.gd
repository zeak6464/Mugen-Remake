extends Node
class_name CommandInterpreter

signal input_buffer_updated
signal command_matched(command_id: String, command_entry: Dictionary)

class InputFrame:
	var numpad_direction: int
	var buttons_pressed: Array[String]
	var buttons_held: Array[String]
	var buttons_released: Array[String]
	var frame_index: int
	var timestamp_ms: int

	func _init(
		p_numpad_direction: int,
		p_buttons_pressed: Array[String],
		p_buttons_held: Array[String],
		p_buttons_released: Array[String],
		p_frame_index: int,
		p_timestamp_ms: int
	) -> void:
		numpad_direction = p_numpad_direction
		buttons_pressed = p_buttons_pressed.duplicate()
		buttons_held = p_buttons_held.duplicate()
		buttons_released = p_buttons_released.duplicate()
		frame_index = p_frame_index
		timestamp_ms = p_timestamp_ms


const DEFAULT_BUFFER_SIZE: int = 20
const DEADZONE: float = 0.25

enum InputMode {
	LOCAL,
	EXTERNAL
}

@export var read_local_input: bool = true
@export var input_mode: InputMode = InputMode.LOCAL
@export var action_up: StringName = &"p1_up"
@export var action_down: StringName = &"p1_down"
@export var action_left: StringName = &"p1_left"
@export var action_right: StringName = &"p1_right"
@export var button_actions: Dictionary = {
	"P": StringName("p1_p"),
	"K": StringName("p1_k"),
	"S": StringName("p1_s"),
	"H": StringName("p1_h")
}

var buffer_size: int = DEFAULT_BUFFER_SIZE
var input_buffer: Array[InputFrame] = []
var frame_counter: int = 0
var facing_right: bool = true
var fighter: Node = null
var command_data: Dictionary = {}
var last_command_frame: Dictionary = {}
var external_input_queue: Array[Dictionary] = []
var last_matched_command_id: String = ""
var last_matched_command_frame: int = -999999
var latest_raw_direction: Vector2 = Vector2.ZERO


func set_fighter(p_fighter: Node) -> void:
	fighter = p_fighter


func set_facing_direction(is_facing_right: bool) -> void:
	facing_right = is_facing_right


func set_command_data(data: Dictionary) -> void:
	command_data = data.duplicate(true)


func set_input_mode(mode: InputMode) -> void:
	input_mode = mode


func enqueue_external_input(
	raw_direction: Vector2,
	buttons_pressed: Array[String],
	buttons_held: Array[String] = [],
	buttons_released: Array[String] = []
) -> void:
	external_input_queue.append(
		{
			"direction": raw_direction,
			"pressed": buttons_pressed.duplicate(),
			"held": buttons_held.duplicate(),
			"released": buttons_released.duplicate()
		}
	)


func clear_external_input_queue() -> void:
	external_input_queue.clear()


func reset_latest_input() -> void:
	latest_raw_direction = Vector2.ZERO


func get_last_matched_command_id() -> String:
	return last_matched_command_id


func get_last_matched_command_frame() -> int:
	return last_matched_command_frame


func get_frame_counter() -> int:
	return frame_counter


func get_latest_raw_direction() -> Vector2:
	return latest_raw_direction


func get_facing_right() -> bool:
	return facing_right


func _physics_process(_delta: float) -> void:
	if input_mode == InputMode.EXTERNAL:
		_consume_external_input()
	elif read_local_input:
		submit_frame_input(_read_direction_from_actions(), _read_pressed_buttons(), _read_held_buttons(), _read_released_buttons())
	_evaluate_commands()


func submit_frame_input(
	raw_direction: Vector2,
	buttons_pressed: Array[String],
	buttons_held: Array[String] = [],
	buttons_released: Array[String] = []
) -> void:
	frame_counter += 1
	latest_raw_direction = raw_direction
	var converted_direction: int = _direction_to_numpad(raw_direction)
	var frame := InputFrame.new(
		converted_direction,
		buttons_pressed,
		buttons_held,
		buttons_released,
		frame_counter,
		Time.get_ticks_msec()
	)
	input_buffer.append(frame)
	if input_buffer.size() > buffer_size:
		input_buffer.pop_front()
	input_buffer_updated.emit()


func get_buffer_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for frame in input_buffer:
		snapshot.append(
			{
				"direction": frame.numpad_direction,
				"pressed": frame.buttons_pressed,
				"held": frame.buttons_held,
				"released": frame.buttons_released,
				"frame_index": frame.frame_index,
				"timestamp_ms": frame.timestamp_ms
			}
		)
	return snapshot


func match_command(pattern: Array, max_window: int = DEFAULT_BUFFER_SIZE) -> bool:
	if pattern.is_empty() or input_buffer.is_empty():
		return false

	var frames: Array[InputFrame] = _get_recent_frames(max_window)
	if frames.is_empty():
		return false

	if _is_hold_release_pattern(pattern):
		return _match_hold_release_pattern(frames, pattern)
	return _match_simple_pattern(frames, pattern)


func _direction_to_numpad(raw_direction: Vector2) -> int:
	var x: int = 0
	var y: int = 0

	if raw_direction.x > DEADZONE:
		x = 1
	elif raw_direction.x < -DEADZONE:
		x = -1

	if raw_direction.y > DEADZONE:
		y = 1
	elif raw_direction.y < -DEADZONE:
		y = -1

	if not facing_right:
		x *= -1

	if x == 0 and y == 0:
		return 5
	if x == -1 and y == -1:
		return 7
	if x == 0 and y == -1:
		return 8
	if x == 1 and y == -1:
		return 9
	if x == -1 and y == 0:
		return 4
	if x == 1 and y == 0:
		return 6
	if x == -1 and y == 1:
		return 1
	if x == 0 and y == 1:
		return 2
	return 3


func _get_recent_frames(max_window: int) -> Array[InputFrame]:
	var frames: Array[InputFrame] = []
	var start: int = maxi(0, input_buffer.size() - max_window)
	for idx in range(start, input_buffer.size()):
		frames.append(input_buffer[idx])
	return frames


func _is_hold_release_pattern(pattern: Array) -> bool:
	return (
		pattern.size() >= 6
		and pattern[0] == "hold"
		and pattern[3] == "release"
	)


func _match_simple_pattern(frames: Array[InputFrame], pattern: Array) -> bool:
	# Require the final token to be present on the latest frame.
	# This prevents stale inputs (e.g. one old "P") from re-triggering
	# commands across many subsequent frames.
	var search_index: int = frames.size() - 1
	var final_token = pattern[pattern.size() - 1]
	if not _frame_matches_token(frames[search_index], final_token):
		return false
	# Allow direction tokens on the same frame as the button (hold direction + press button).
	for token_index in range(pattern.size() - 2, -1, -1):
		var token = pattern[token_index]
		var found_index: int = _find_token_backwards(frames, token, search_index)
		if found_index == -1:
			return false
		search_index = found_index - 1
	return true


func _find_token_backwards(frames: Array[InputFrame], token, from_index: int) -> int:
	for idx in range(from_index, -1, -1):
		if _frame_matches_token(frames[idx], token):
			return idx
	return -1


func _frame_matches_token(frame: InputFrame, token) -> bool:
	if typeof(token) == TYPE_INT:
		return frame.numpad_direction == token
	if typeof(token) == TYPE_STRING:
		var text: String = str(token).strip_edges()
		if text.find("+") != -1:
			var parts: PackedStringArray = text.split("+", false)
			if parts.is_empty():
				return false
			for raw_part in parts:
				if not _frame_matches_string_token(frame, str(raw_part).strip_edges()):
					return false
			return true
		return _frame_matches_string_token(frame, text)
	return false


func _frame_matches_string_token(frame: InputFrame, token: String) -> bool:
	if token.is_empty():
		return false
	var upper: String = token.to_upper()
	if upper.begins_with("RELEASE:"):
		var release_button: String = _normalize_button_token(upper.substr(8))
		return not release_button.is_empty() and frame.buttons_released.has(release_button)
	if upper.begins_with("HOLD:"):
		var hold_button: String = _normalize_button_token(upper.substr(5))
		return not hold_button.is_empty() and frame.buttons_held.has(hold_button)
	var button_token: String = _normalize_button_token(upper)
	if not button_token.is_empty():
		return frame.buttons_pressed.has(button_token)
	var direction_token: int = _normalize_direction_token(upper)
	if direction_token != -1:
		return frame.numpad_direction == direction_token
	return false


func _normalize_button_token(token: String) -> String:
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


func _normalize_direction_token(token: String) -> int:
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


func _match_hold_release_pattern(frames: Array[InputFrame], pattern: Array) -> bool:
	var hold_direction: int = int(pattern[1])
	var hold_frames: int = int(pattern[2])
	var release_direction: int = int(pattern[4])
	var final_button: String = str(pattern[5])

	var release_idx: int = _find_direction_backwards(frames, release_direction, frames.size() - 1)
	if release_idx == -1:
		return false

	var button_idx: int = _find_button_backwards(frames, final_button, frames.size() - 1)
	if button_idx == -1 or button_idx < release_idx:
		return false

	var held_count: int = 0
	for idx in range(release_idx - 1, -1, -1):
		if frames[idx].numpad_direction == hold_direction:
			held_count += 1
			if held_count >= hold_frames:
				return true
	return false


func _find_direction_backwards(frames: Array[InputFrame], direction: int, from_index: int) -> int:
	for idx in range(from_index, -1, -1):
		if frames[idx].numpad_direction == direction:
			return idx
	return -1


func _find_button_backwards(frames: Array[InputFrame], button: String, from_index: int) -> int:
	for idx in range(from_index, -1, -1):
		if frames[idx].buttons_pressed.has(button):
			return idx
	return -1


func _read_direction_from_actions() -> Vector2:
	var right_strength: float = 0.0
	var left_strength: float = 0.0
	var down_strength: float = 0.0
	var up_strength: float = 0.0
	if InputMap.has_action(action_right):
		right_strength = Input.get_action_strength(action_right)
	if InputMap.has_action(action_left):
		left_strength = Input.get_action_strength(action_left)
	if InputMap.has_action(action_down):
		down_strength = Input.get_action_strength(action_down)
	if InputMap.has_action(action_up):
		up_strength = Input.get_action_strength(action_up)
	var x: float = right_strength - left_strength
	var y: float = down_strength - up_strength
	return Vector2(x, y)


func _read_pressed_buttons() -> Array[String]:
	var pressed: Array[String] = []
	for button_name in button_actions.keys():
		var action: StringName = StringName(button_actions[button_name])
		if not InputMap.has_action(action):
			continue
		if Input.is_action_just_pressed(action):
			pressed.append(str(button_name))
	return pressed


func _read_held_buttons() -> Array[String]:
	var held: Array[String] = []
	for button_name in button_actions.keys():
		var action: StringName = StringName(button_actions[button_name])
		if not InputMap.has_action(action):
			continue
		if Input.is_action_pressed(action):
			held.append(str(button_name))
	return held


func _read_released_buttons() -> Array[String]:
	var released: Array[String] = []
	for button_name in button_actions.keys():
		var action: StringName = StringName(button_actions[button_name])
		if not InputMap.has_action(action):
			continue
		if Input.is_action_just_released(action):
			released.append(str(button_name))
	return released


func _evaluate_commands() -> void:
	var command_entries: Array = _get_command_entries()
	if command_entries.is_empty():
		return
	for entry in command_entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var command_id: String = str(entry.get("id", ""))
		if command_id.is_empty():
			continue
		var pattern: Array = entry.get("pattern", [])
		if pattern.is_empty():
			continue
		var max_window: int = int(entry.get("max_window", DEFAULT_BUFFER_SIZE))
		if not match_command(pattern, max_window):
			continue
		var min_repeat_frames: int = int(entry.get("min_repeat_frames", 1))
		var last_frame: int = int(last_command_frame.get(command_id, -999999))
		if frame_counter - last_frame < min_repeat_frames:
			continue
		last_command_frame[command_id] = frame_counter
		last_matched_command_id = command_id
		last_matched_command_frame = frame_counter
		command_matched.emit(command_id, entry)


func _get_command_entries() -> Array:
	if command_data.has("commands") and command_data["commands"] is Array:
		return command_data["commands"]
	var entries: Array = []
	for command_id in command_data.keys():
		var value = command_data[command_id]
		if typeof(value) == TYPE_DICTIONARY:
			var entry: Dictionary = value.duplicate(true)
			if not entry.has("id"):
				entry["id"] = str(command_id)
			entries.append(entry)
	return entries


func _consume_external_input() -> void:
	if external_input_queue.is_empty():
		return
	var next_input: Dictionary = external_input_queue.pop_front()
	var raw_direction: Vector2 = next_input.get("direction", Vector2.ZERO)
	var pressed: Array[String] = next_input.get("pressed", [])
	var held: Array[String] = next_input.get("held", [])
	var released: Array[String] = next_input.get("released", [])
	submit_frame_input(raw_direction, pressed, held, released)
