extends RefCounted
class_name JoypadMotionAssist

## Blends controller gravity / tilt into the 2D move vector for CommandInterpreter.
## Requires a Godot build whose Input singleton exposes per-joypad motion (e.g. get_joy_gravity,
## set_joy_motion_sensors_enabled, has_joy_motion_sensors). If those are missing, helpers no-op.


static func per_joy_motion_api_available() -> bool:
	return (
		Input.has_method("set_joy_motion_sensors_enabled")
		and (Input.has_method("get_joy_gravity") or Input.has_method("get_joy_accelerometer"))
	)


static func resolve_device_id(preferred: int) -> int:
	if preferred >= 0:
		return preferred
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return -1
	return int(pads[0])


static func try_enable_motion_sensors(device_id: int) -> bool:
	if device_id < 0:
		return false
	if not Input.has_method("set_joy_motion_sensors_enabled"):
		return false
	if Input.has_method("has_joy_motion_sensors") and not bool(Input.call("has_joy_motion_sensors", device_id)):
		return false
	Input.call("set_joy_motion_sensors_enabled", device_id, true)
	return true


static func _sample_tilt_xy(device_id: int) -> Vector2:
	if device_id < 0:
		return Vector2.ZERO
	var v := Vector3.ZERO
	if Input.has_method("get_joy_gravity"):
		v = Input.call("get_joy_gravity", device_id)
	elif Input.has_method("get_joy_accelerometer"):
		v = Input.call("get_joy_accelerometer", device_id)
	if v.length_squared() < 0.0001:
		return Vector2.ZERO
	return Vector2(clampf(v.x, -1.0, 1.0), clampf(-v.z, -1.0, 1.0))


static func apply_direction_blend(base: Vector2, preferred_device_id: int, blend: float) -> Vector2:
	if blend <= 0.0:
		return base
	if not per_joy_motion_api_available():
		return base
	var dev: int = resolve_device_id(preferred_device_id)
	if dev < 0:
		return base
	if not try_enable_motion_sensors(dev):
		return base
	var tilt: Vector2 = _sample_tilt_xy(dev)
	if tilt.length_squared() < 0.0001:
		return base
	tilt = tilt.limit_length(1.0)
	var stick_mag: float = base.length()
	var scale: float = blend * (1.0 - clampf(stick_mag, 0.0, 1.0) * 0.75)
	var out: Vector2 = base + tilt * scale
	return out.limit_length(1.0)
