extends Control

signal closed

const SETTINGS_PATH: String = "user://options.cfg"
const P1_ACTIONS: Array[StringName] = [
	&"p1_up",
	&"p1_down",
	&"p1_left",
	&"p1_right",
	&"p1_p",
	&"p1_k",
	&"p1_s",
	&"p1_h",
	&"p1_tag"
]
const P2_ACTIONS: Array[StringName] = [
	&"p2_up",
	&"p2_down",
	&"p2_left",
	&"p2_right",
	&"p2_p",
	&"p2_k",
	&"p2_s",
	&"p2_h",
	&"p2_tag"
]
const KEYMAP_ACTIONS: Array[StringName] = [
	&"p1_up",
	&"p1_down",
	&"p1_left",
	&"p1_right",
	&"p1_p",
	&"p1_k",
	&"p1_s",
	&"p1_h",
	&"p1_tag",
	&"p2_up",
	&"p2_down",
	&"p2_left",
	&"p2_right",
	&"p2_p",
	&"p2_k",
	&"p2_s",
	&"p2_h",
	&"p2_tag"
]

@onready var p1_keymap_list: Control = $MarginContainer/VBoxContainer/KeymapPanel/KeymapScroll/ColumnsRow/P1Panel/P1List
@onready var p2_keymap_list: Control = $MarginContainer/VBoxContainer/KeymapPanel/KeymapScroll/ColumnsRow/P2Panel/P2List
@onready var keymap_scroll: ScrollContainer = $MarginContainer/VBoxContainer/KeymapPanel/KeymapScroll
@onready var columns_row: HBoxContainer = $MarginContainer/VBoxContainer/KeymapPanel/KeymapScroll/ColumnsRow
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var back_button: Button = $MarginContainer/VBoxContainer/BottomButtons/BackButton

var keymap_buttons: Dictionary = {}
var waiting_for_action: StringName = StringName()
var player_device_option_buttons: Dictionary = {}
var player_selected_device: Dictionary = {1: -1, 2: -1}
var embedded_mode: bool = false


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	UISkin.apply_background(self, "controls_menu_bg")
	keymap_scroll.follow_focus = true
	back_button.pressed.connect(_on_back_pressed)
	_build_keymap_list()
	_load_keymap_settings()
	status_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if waiting_for_action == StringName():
		return

	var action: StringName = waiting_for_action
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		waiting_for_action = StringName()
		_set_action_key(action, key_event.keycode)
		_save_keymap_settings()
		_refresh_keymap_button_text(action)
		SystemSFX.play_ui_from(self, "ui_confirm")
		status_label.text = "%s mapped to %s" % [String(action), OS.get_keycode_string(key_event.keycode)]
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadButton:
		var btn_event := event as InputEventJoypadButton
		if not btn_event.pressed:
			return
		waiting_for_action = StringName()
		_set_action_joy_button(action, btn_event.button_index)
		_save_keymap_settings()
		_refresh_keymap_button_text(action)
		SystemSFX.play_ui_from(self, "ui_confirm")
		status_label.text = "%s mapped to Joy Button %d" % [String(action), btn_event.button_index]
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		if absf(motion_event.axis_value) < 0.5:
			return
		waiting_for_action = StringName()
		var axis_sign: float = 1.0 if motion_event.axis_value > 0.0 else -1.0
		_set_action_joy_axis(action, motion_event.axis, axis_sign)
		_save_keymap_settings()
		_refresh_keymap_button_text(action)
		SystemSFX.play_ui_from(self, "ui_confirm")
		status_label.text = "%s mapped to Joy Axis %d %s" % [String(action), motion_event.axis, "+" if axis_sign > 0.0 else "-"]
		get_viewport().set_input_as_handled()
		return


func _build_keymap_list() -> void:
	for child in p1_keymap_list.get_children():
		child.queue_free()
	for child in p2_keymap_list.get_children():
		child.queue_free()
	keymap_buttons.clear()

	_add_player_section(p1_keymap_list, "Player 1", P1_ACTIONS)
	_add_player_section(p2_keymap_list, "Player 2", P2_ACTIONS)
	_update_keymap_scroll_content_size()


func _update_keymap_scroll_content_size() -> void:
	var p1_h: float = p1_keymap_list.get_combined_minimum_size().y
	var p2_h: float = p2_keymap_list.get_combined_minimum_size().y
	var target_h: float = maxf(p1_h, p2_h) + 24.0
	# Ensure ScrollContainer can scroll to the full action list (including tag).
	columns_row.custom_minimum_size = Vector2(columns_row.custom_minimum_size.x, target_h)


func _add_player_section(target_list: Control, title: String, actions: Array[StringName]) -> void:
	var player_id: int = 1 if "1" in title else 2
	var section_label := Label.new()
	section_label.text = title
	section_label.add_theme_font_size_override("font_size", 20)
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_list.add_child(section_label)

	var device_row := HBoxContainer.new()
	device_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	device_row.add_theme_constant_override("separation", 10)
	var device_label := Label.new()
	device_label.custom_minimum_size = Vector2(120, 0)
	device_label.text = "DEVICE"
	device_row.add_child(device_label)
	var device_option := OptionButton.new()
	device_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	device_option.item_selected.connect(_on_device_selected.bind(player_id))
	device_row.add_child(device_option)
	target_list.add_child(device_row)
	player_device_option_buttons[player_id] = device_option
	_populate_device_options(device_option, player_id)

	for action in actions:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)

		var action_label := Label.new()
		action_label.custom_minimum_size = Vector2(120, 0)
		action_label.text = _pretty_action_name(String(action))
		row.add_child(action_label)

		var key_button := Button.new()
		key_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_button.pressed.connect(_begin_rebind.bind(action))
		row.add_child(key_button)

		keymap_buttons[action] = key_button
		target_list.add_child(row)
		_refresh_keymap_button_text(action)


func _pretty_action_name(action: String) -> String:
	return action.replace("p1_", "").replace("p2_", "").replace("_", " ").to_upper()


func _begin_rebind(action: StringName) -> void:
	SystemSFX.play_ui_from(self, "ui_move")
	waiting_for_action = action
	status_label.text = "Press key/button/axis for %s..." % _pretty_action_name(String(action))


func _on_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	if embedded_mode:
		closed.emit()
		queue_free()
		return
	get_tree().change_scene_to_file("res://ui/OptionsMenu.tscn")


func set_embedded_mode(enabled: bool) -> void:
	embedded_mode = enabled


func _load_keymap_settings() -> void:
	var cfg := ConfigFile.new()
	var err: int = cfg.load(SETTINGS_PATH)
	if err != OK:
		return

	player_selected_device[1] = int(cfg.get_value("input", "joypad_device_p1", -1))
	player_selected_device[2] = int(cfg.get_value("input", "joypad_device_p2", -1))
	_refresh_device_options()

	var bindings = cfg.get_value("input", "bindings", {})
	if bindings is Dictionary and not (bindings as Dictionary).is_empty():
		for action in KEYMAP_ACTIONS:
			var action_bindings = (bindings as Dictionary).get(String(action), [])
			_set_action_bindings(action, action_bindings)
		for action in KEYMAP_ACTIONS:
			_refresh_keymap_button_text(action)
		return

	var keycodes: Dictionary = cfg.get_value("input", "keycodes", {})
	if not (keycodes is Dictionary):
		return
	for action in KEYMAP_ACTIONS:
		if keycodes.has(String(action)):
			_set_action_key(action, int(keycodes[String(action)]))
	for action in KEYMAP_ACTIONS:
		_refresh_keymap_button_text(action)


func _save_keymap_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	var keycodes: Dictionary = {}
	var bindings: Dictionary = {}
	for action in KEYMAP_ACTIONS:
		keycodes[String(action)] = _get_action_primary_keycode(action)
		bindings[String(action)] = _serialize_action_events(action)
	cfg.set_value("input", "keycodes", keycodes)
	cfg.set_value("input", "bindings", bindings)
	cfg.set_value("input", "joypad_device_p1", int(player_selected_device.get(1, -1)))
	cfg.set_value("input", "joypad_device_p2", int(player_selected_device.get(2, -1)))
	cfg.save(SETTINGS_PATH)


func _set_action_key(action: StringName, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	event.keycode = keycode as Key
	event.physical_keycode = keycode as Key
	InputMap.action_add_event(action, event)


func _set_action_joy_button(action: StringName, button_index: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var event := InputEventJoypadButton.new()
	event.device = _device_for_action(action)
	event.button_index = button_index as JoyButton
	event.pressed = true
	InputMap.action_add_event(action, event)


func _set_action_joy_axis(action: StringName, axis: int, axis_sign: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var event := InputEventJoypadMotion.new()
	event.device = _device_for_action(action)
	event.axis = axis as JoyAxis
	event.axis_value = axis_sign
	InputMap.action_add_event(action, event)


func _get_action_primary_keycode(action: StringName) -> int:
	if not InputMap.has_action(action):
		return 0
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.keycode != 0:
				return key_event.keycode
	return 0


func _refresh_keymap_button_text(action: StringName) -> void:
	var button = keymap_buttons.get(action, null)
	if button == null or not (button is Button):
		return
	var button_node := button as Button
	var text: String = _describe_primary_binding(action)
	if text.is_empty():
		button_node.text = "Unbound"
	else:
		button_node.text = text


func _on_device_selected(index: int, player_id: int) -> void:
	var option = player_device_option_buttons.get(player_id, null)
	if option == null or not (option is OptionButton):
		return
	var option_button := option as OptionButton
	var device_value: int = int(option_button.get_item_id(index))
	player_selected_device[player_id] = device_value
	_save_keymap_settings()
	SystemSFX.play_ui_from(self, "ui_move")
	status_label.text = "Player %d device set to %s" % [player_id, option_button.get_item_text(index)]


func _populate_device_options(option: OptionButton, player_id: int) -> void:
	option.clear()
	option.add_item("Auto", -1)
	var pads: PackedInt32Array = Input.get_connected_joypads()
	for device_id in pads:
		var pad_name: String = Input.get_joy_name(device_id)
		var label: String = "Joypad %d: %s" % [device_id, pad_name]
		option.add_item(label, device_id)
	var wanted_device: int = int(player_selected_device.get(player_id, -1))
	_select_device_option(option, wanted_device)


func _select_device_option(option: OptionButton, device_id: int) -> void:
	for i in range(option.item_count):
		if option.get_item_id(i) == device_id:
			option.select(i)
			return
	option.select(0)


func _refresh_device_options() -> void:
	var p1_option = player_device_option_buttons.get(1, null)
	if p1_option is OptionButton:
		_populate_device_options(p1_option as OptionButton, 1)
	var p2_option = player_device_option_buttons.get(2, null)
	if p2_option is OptionButton:
		_populate_device_options(p2_option as OptionButton, 2)


func _device_for_action(action: StringName) -> int:
	var action_text: String = String(action)
	if action_text.begins_with("p2_"):
		return int(player_selected_device.get(2, -1))
	return int(player_selected_device.get(1, -1))


func _describe_primary_binding(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	if events.is_empty():
		return ""
	var event: InputEvent = events[0]
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return OS.get_keycode_string(key_event.keycode)
	if event is InputEventJoypadButton:
		var btn_event := event as InputEventJoypadButton
		return "Btn %d%s" % [btn_event.button_index, _device_suffix(btn_event.device)]
	if event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		return "Axis %d %s%s" % [motion_event.axis, "+" if motion_event.axis_value > 0.0 else "-", _device_suffix(motion_event.device)]
	return ""


func _device_suffix(device_id: int) -> String:
	if device_id < 0:
		return ""
	return " (D%d)" % device_id


func _serialize_action_events(action: StringName) -> Array:
	var packed: Array = []
	if not InputMap.has_action(action):
		return packed
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			var key_event := event as InputEventKey
			packed.append({"type": "key", "keycode": int(key_event.keycode)})
		elif event is InputEventJoypadButton:
			var btn_event := event as InputEventJoypadButton
			packed.append(
				{
					"type": "joy_button",
					"device": int(btn_event.device),
					"button_index": int(btn_event.button_index)
				}
			)
		elif event is InputEventJoypadMotion:
			var motion_event := event as InputEventJoypadMotion
			packed.append(
				{
					"type": "joy_axis",
					"device": int(motion_event.device),
					"axis": int(motion_event.axis),
					"axis_value": float(motion_event.axis_value)
				}
			)
	return packed


func _set_action_bindings(action: StringName, packed_bindings) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	if not (packed_bindings is Array):
		return
	for entry_raw in packed_bindings:
		if not (entry_raw is Dictionary):
			continue
		var entry: Dictionary = entry_raw
		var binding_type: String = str(entry.get("type", ""))
		match binding_type:
			"key":
				var key_event := InputEventKey.new()
				key_event.keycode = int(entry.get("keycode", 0)) as Key
				key_event.physical_keycode = key_event.keycode
				InputMap.action_add_event(action, key_event)
			"joy_button":
				var btn_event := InputEventJoypadButton.new()
				btn_event.device = int(entry.get("device", -1))
				btn_event.button_index = int(entry.get("button_index", 0)) as JoyButton
				btn_event.pressed = true
				InputMap.action_add_event(action, btn_event)
			"joy_axis":
				var motion_event := InputEventJoypadMotion.new()
				motion_event.device = int(entry.get("device", -1))
				motion_event.axis = int(entry.get("axis", 0)) as JoyAxis
				motion_event.axis_value = float(entry.get("axis_value", 1.0))
				InputMap.action_add_event(action, motion_event)
