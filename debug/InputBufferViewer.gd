extends CanvasLayer

@export var target_fighter_path: NodePath
@export var toggle_action: StringName = &"debug_toggle"
@export var toggle_key: Key = KEY_F3

@onready var input_lines_label: Label = $PanelContainer/MarginContainer/VBoxContainer/InputLines
@onready var state_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CurrentState
@onready var state_frame_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StateFrame
@onready var health_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Health
@onready var last_command_label: Label = $PanelContainer/MarginContainer/VBoxContainer/LastCommand
@onready var positions_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Positions
@onready var last_hit_label: Label = $PanelContainer/MarginContainer/VBoxContainer/LastHit
@onready var combo_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Combo
@onready var hitbox_debug_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HitboxDebug


func _ready() -> void:
	visible = true


func _process(_delta: float) -> void:
	var fighter := get_node_or_null(target_fighter_path)
	if fighter == null:
		input_lines_label.text = "No fighter selected."
		state_label.text = "State: -"
		state_frame_label.text = "State Frame: -"
		health_label.text = "Health: -"
		last_command_label.text = "Last Command: -"
		positions_label.text = "P1/P2 X: -"
		last_hit_label.text = "Last Hit: -"
		combo_label.text = "Combo: -"
		hitbox_debug_label.text = "Hitbox Debug: -"
		return

	var interpreter = fighter.get_node_or_null("CommandInterpreter")
	var controller = fighter.get_node_or_null("StateController")
	if interpreter == null or controller == null:
		return

	var frames: Array = interpreter.get_buffer_snapshot()
	input_lines_label.text = _build_prompt_history_text(frames)
	state_label.text = "State: %s" % controller.current_state
	state_frame_label.text = "State Frame: %d" % int(controller.frame_in_state)
	health_label.text = "Health: %d" % int(fighter.get("health"))
	last_command_label.text = "Last Command: %s" % interpreter.get_last_matched_command_id()
	var opponent = fighter.get("opponent")
	if opponent is Node3D:
		positions_label.text = "P1/P2 X: %.2f / %.2f" % [fighter.global_position.x, (opponent as Node3D).global_position.x]
	else:
		positions_label.text = "P1/P2 X: %.2f / -" % fighter.global_position.x
	last_hit_label.text = "Last Hit: %d" % int(fighter.get("last_hit_damage"))
	combo_label.text = "Combo: %d (%d dmg)" % [int(fighter.get("last_combo_hits")), int(fighter.get("last_combo_damage"))]
	var hb_info: Dictionary = fighter.call("get_hitbox_debug_info")
	hitbox_debug_label.text = "Hitbox Debug: %s | Hurt:%d | Active:%d" % [
		"ON" if bool(hb_info.get("enabled", false)) else "OFF",
		int(hb_info.get("hurtboxes", 0)),
		int(hb_info.get("active_hitboxes", 0))
	]


func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action(toggle_action):
		if event.is_action_pressed(toggle_action):
			visible = not visible
	else:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == toggle_key:
			visible = not visible


func _build_prompt_history_text(frames: Array) -> String:
	if frames.is_empty():
		return "P=Punch  K=Kick  S=Special  H=Heavy\n(no input yet)"
	var events: Array[String] = []
	var start: int = maxi(0, frames.size() - 24)
	var last_direction: int = 5
	for idx in range(start, frames.size()):
		var frame_raw = frames[idx]
		if not (frame_raw is Dictionary):
			continue
		var frame: Dictionary = frame_raw
		var direction: int = int(frame.get("direction", 5))
		var pressed: Array = frame.get("pressed", [])
		var released: Array = frame.get("released", [])
		var has_buttons: bool = not pressed.is_empty() or not released.is_empty()
		var direction_changed: bool = direction != last_direction and direction != 5
		last_direction = direction
		if not has_buttons and not direction_changed:
			continue
		var tokens: Array[String] = []
		if direction_changed:
			tokens.append(_direction_label(direction))
		for p in pressed:
			tokens.append(_button_label(str(p)))
		for r in released:
			tokens.append("(%s)" % _button_label(str(r)))
		if tokens.is_empty():
			continue
		events.append(" ".join(tokens))
	if events.is_empty():
		return "P=Punch  K=Kick  S=Special  H=Heavy\n(no input yet)"
	return "P=Punch  K=Kick  S=Special  H=Heavy\n%s" % "  >  ".join(events)


func _direction_label(numpad_direction: int) -> String:
	match numpad_direction:
		1:
			return "DB"
		2:
			return "D"
		3:
			return "DF"
		4:
			return "B"
		6:
			return "F"
		7:
			return "UB"
		8:
			return "U"
		9:
			return "UF"
		_:
			return "N"


func _button_label(raw: String) -> String:
	var key: String = raw.strip_edges().to_upper()
	match key:
		"P":
			return "P"
		"K":
			return "K"
		"S":
			return "S"
		"H":
			return "H"
		_:
			return key
