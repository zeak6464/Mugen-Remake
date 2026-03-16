extends Node
class_name InputReplayRecorder

## Records and plays back per-frame input for P1 and P2.
## Used for Replay mode and for rewind (re-simulate from inputs).
## Each frame is { "p1": { "direction": Vector2, "pressed": [], "held": [], "released": [] }, "p2": {...} }.

var _recorded_frames: Array[Dictionary] = []
var _recording: bool = false
var _playback_data: Array = []
var _playback_index: int = 0


func is_recording() -> bool:
	return _recording


func start_recording() -> void:
	_recording = true
	_recorded_frames.clear()


func stop_recording() -> void:
	_recording = false


func record_frame(p1_input: Dictionary, p2_input: Dictionary) -> void:
	if not _recording:
		return
	_recorded_frames.append({
		"p1": _copy_input(p1_input),
		"p2": _copy_input(p2_input)
	})


func _copy_input(inp: Dictionary) -> Dictionary:
	var dir = inp.get("direction", Vector2.ZERO)
	return {
		"direction": Vector2(dir.x, dir.y),
		"pressed": (inp.get("pressed", []) as Array).duplicate(),
		"held": (inp.get("held", []) as Array).duplicate(),
		"released": (inp.get("released", []) as Array).duplicate()
	}


func get_recorded_frames() -> Array:
	var out: Array = []
	for frame in _recorded_frames:
		out.append({
			"p1": _copy_input(frame["p1"]),
			"p2": _copy_input(frame["p2"])
		})
	return out


func get_recorded_frame_count() -> int:
	return _recorded_frames.size()


func clear() -> void:
	_recorded_frames.clear()
	_playback_data.clear()
	_playback_index = 0


## Set data for playback (e.g. from get_recorded_frames() or from file).
## Each element must have "p1" and "p2" with direction, pressed, held, released.
func set_playback_data(data: Array) -> void:
	_playback_data = data
	_playback_index = 0


func get_playback_length() -> int:
	return _playback_data.size()


func get_playback_index() -> int:
	return _playback_index


## Returns the input for the current playback frame, or null if past end.
## Call advance_playback() after consuming.
func get_playback_frame() -> Dictionary:
	if _playback_index < 0 or _playback_index >= _playback_data.size():
		return {}
	return _playback_data[_playback_index]


func advance_playback() -> void:
	_playback_index += 1


func seek_playback_to_frame(frame_index: int) -> void:
	_playback_index = clampi(frame_index, 0, _playback_data.size())


## Returns a JSON-serializable copy of recorded frames (for saving to file).
## direction becomes [x, y].
func to_serializable() -> Array:
	var out: Array = []
	for frame in _recorded_frames:
		var p1 = frame.get("p1", {})
		var p2 = frame.get("p2", {})
		var d1: Vector2 = p1.get("direction", Vector2.ZERO)
		var d2: Vector2 = p2.get("direction", Vector2.ZERO)
		out.append({
			"p1": {
				"direction": [d1.x, d1.y],
				"pressed": p1.get("pressed", []),
				"held": p1.get("held", []),
				"released": p1.get("released", [])
			},
			"p2": {
				"direction": [d2.x, d2.y],
				"pressed": p2.get("pressed", []),
				"held": p2.get("held", []),
				"released": p2.get("released", [])
			}
		})
	return out


## Load from a serialized array (e.g. from JSON file).
## Expects each frame with "p1"/"p2" and direction as [x, y].
func from_serializable(data: Array) -> void:
	_playback_data.clear()
	for frame in data:
		if typeof(frame) != TYPE_DICTIONARY:
			continue
		var p1 = (frame.get("p1", {}) as Dictionary).duplicate()
		var p2 = (frame.get("p2", {}) as Dictionary).duplicate()
		var d1 = p1.get("direction", [0.0, 0.0])
		var d2 = p2.get("direction", [0.0, 0.0])
		var v1: Vector2 = Vector2(float(d1[0]) if d1.size() > 0 else 0.0, float(d1[1]) if d1.size() > 1 else 0.0)
		var v2: Vector2 = Vector2(float(d2[0]) if d2.size() > 0 else 0.0, float(d2[1]) if d2.size() > 1 else 0.0)
		p1["direction"] = v1
		p2["direction"] = v2
		_playback_data.append({"p1": p1, "p2": p2})
	_playback_index = 0
