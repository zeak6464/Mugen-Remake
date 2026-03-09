extends CanvasLayer

signal resume_requested
signal button_config_requested
signal exit_requested(target_scene: String)
signal toggle_hitbox_requested
signal open_hitbox_editor_requested

const SETTINGS_PATH: String = "user://options.cfg"
const CONTROLS_MENU_SCENE: PackedScene = preload("res://ui/ControlsMenu.tscn")

@onready var title_label: Label = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox/TitleLabel
@onready var debug_state_label: Label = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox/DebugStateLabel
@onready var toggle_hitbox_button: Button = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox/ToggleHitboxButton
@onready var hitbox_editor_hint_label: Label = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox/HitboxEditStatusLabel
@onready var open_hitbox_editor_button: Button = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox/ToggleHitboxEditButton
@onready var content_root: Control = $Root/CenterContainer/Panel/Content
@onready var main_scroll: ScrollContainer = $Root/CenterContainer/Panel/Content/MainScroll
@onready var main_vbox: Control = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox
@onready var resume_button: Button = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox/ResumeButton
@onready var move_list_button: Button = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox/MoveListButton
@onready var button_config_button: Button = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox/ButtonConfigButton
@onready var sound_config_button: Button = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox/SoundConfigButton
@onready var exit_character_select_button: Button = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox/ExitCharacterSelectButton
@onready var exit_main_menu_button: Button = $Root/CenterContainer/Panel/Content/MainScroll/MainVBox/ExitMainMenuButton
@onready var move_list_panel: Control = $Root/CenterContainer/Panel/Content/MoveListPanel
@onready var move_list_title: Label = $Root/CenterContainer/Panel/Content/MoveListPanel/MoveListTitle
@onready var move_list_text: RichTextLabel = $Root/CenterContainer/Panel/Content/MoveListPanel/MoveListText
@onready var move_list_back_button: Button = $Root/CenterContainer/Panel/Content/MoveListPanel/MoveListBackButton
@onready var sound_panel: Control = $Root/CenterContainer/Panel/Content/SoundPanel
@onready var master_slider: HSlider = $Root/CenterContainer/Panel/Content/SoundPanel/MasterRow/MasterSlider
@onready var sfx_slider: HSlider = $Root/CenterContainer/Panel/Content/SoundPanel/SfxRow/SfxSlider
@onready var bgm_slider: HSlider = $Root/CenterContainer/Panel/Content/SoundPanel/BgmRow/BgmSlider
@onready var master_value: Label = $Root/CenterContainer/Panel/Content/SoundPanel/MasterRow/MasterValue
@onready var sfx_value: Label = $Root/CenterContainer/Panel/Content/SoundPanel/SfxRow/SfxValue
@onready var bgm_value: Label = $Root/CenterContainer/Panel/Content/SoundPanel/BgmRow/BgmValue
@onready var sound_back_button: Button = $Root/CenterContainer/Panel/Content/SoundPanel/SoundBackButton

var current_move_list_text: String = "No moves available."
var controls_overlay: Control = null
var current_is_training_mode: bool = true


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	_load_sound_settings()
	resume_button.pressed.connect(
		func() -> void:
			SystemSFX.play_ui_from(self, "ui_confirm")
			resume_requested.emit()
	)
	toggle_hitbox_button.pressed.connect(
		func() -> void:
			SystemSFX.play_ui_from(self, "ui_confirm")
			toggle_hitbox_requested.emit()
	)
	open_hitbox_editor_button.pressed.connect(
		func() -> void:
			SystemSFX.play_ui_from(self, "ui_confirm")
			open_hitbox_editor_requested.emit()
	)
	move_list_button.pressed.connect(
		func() -> void:
			SystemSFX.play_ui_from(self, "ui_confirm")
			_show_move_list_panel()
	)
	button_config_button.pressed.connect(
		func() -> void:
			SystemSFX.play_ui_from(self, "ui_confirm")
			button_config_requested.emit()
			_show_controls_overlay()
	)
	sound_config_button.pressed.connect(
		func() -> void:
			SystemSFX.play_ui_from(self, "ui_confirm")
			_show_sound_panel()
	)
	exit_character_select_button.pressed.connect(
		func() -> void:
			SystemSFX.play_ui_from(self, "ui_back")
			exit_requested.emit("res://ui/CharacterSelect.tscn")
	)
	exit_main_menu_button.pressed.connect(
		func() -> void:
			SystemSFX.play_ui_from(self, "ui_back")
			exit_requested.emit("res://ui/MainMenu.tscn")
	)
	move_list_back_button.pressed.connect(
		func() -> void:
			SystemSFX.play_ui_from(self, "ui_back")
			_show_main_panel()
	)
	sound_back_button.pressed.connect(
		func() -> void:
			SystemSFX.play_ui_from(self, "ui_back")
			_save_sound_settings()
			_show_main_panel()
	)
	master_slider.value_changed.connect(
		func(value: float) -> void:
			_apply_bus_volume("Master", value)
			_update_sound_labels()
	)
	sfx_slider.value_changed.connect(
		func(value: float) -> void:
			_apply_bus_volume("SFX", value)
			_update_sound_labels()
	)
	bgm_slider.value_changed.connect(
		func(value: float) -> void:
			_apply_bus_volume("BGM", value)
			_update_sound_labels()
	)
	hide_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if controls_overlay != null and is_instance_valid(controls_overlay):
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var up_pressed: bool = _menu_action_pressed(event, &"p1_up") or _menu_action_pressed(event, &"p2_up")
	var down_pressed: bool = _menu_action_pressed(event, &"p1_down") or _menu_action_pressed(event, &"p2_down")
	var left_pressed: bool = _menu_action_pressed(event, &"p1_left") or _menu_action_pressed(event, &"p2_left")
	var right_pressed: bool = _menu_action_pressed(event, &"p1_right") or _menu_action_pressed(event, &"p2_right")
	var confirm_pressed: bool = _menu_action_pressed(event, &"p1_p") or _menu_action_pressed(event, &"p2_p")
	var cancel_pressed: bool = _menu_action_pressed(event, &"p1_k") or _menu_action_pressed(event, &"p2_k")
	if up_pressed:
		_focus_move(-1)
		viewport.set_input_as_handled()
		return
	if down_pressed:
		_focus_move(1)
		viewport.set_input_as_handled()
		return
	var focused: Control = viewport.gui_get_focus_owner()
	if focused is HSlider:
		var slider := focused as HSlider
		if left_pressed:
			slider.value = maxf(slider.min_value, slider.value - maxf(0.01, slider.step))
			viewport.set_input_as_handled()
			return
		if right_pressed:
			slider.value = minf(slider.max_value, slider.value + maxf(0.01, slider.step))
			viewport.set_input_as_handled()
			return
	if confirm_pressed:
		if focused is Button:
			(focused as Button).emit_signal("pressed")
			viewport.set_input_as_handled()
			return
	if cancel_pressed:
		if sound_panel.visible:
			sound_back_button.emit_signal("pressed")
		elif move_list_panel.visible:
			move_list_back_button.emit_signal("pressed")
		else:
			resume_button.emit_signal("pressed")
		viewport.set_input_as_handled()
		return


func _menu_action_pressed(event: InputEvent, action: StringName) -> bool:
	if not InputMap.has_action(action):
		return false
	if not event.is_action_pressed(action):
		return false
	if event is InputEventKey and (event as InputEventKey).echo:
		return false
	return true


func _focus_move(direction: int) -> void:
	var controls: Array[Control] = _menu_focus_controls()
	if controls.is_empty():
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var focused: Control = viewport.gui_get_focus_owner()
	var index: int = controls.find(focused)
	if index < 0:
		controls[0].grab_focus()
		return
	var next_index: int = posmod(index + direction, controls.size())
	controls[next_index].grab_focus()


func _menu_focus_controls() -> Array[Control]:
	var out: Array[Control] = []
	if sound_panel.visible:
		_append_focus_if_visible(out, master_slider)
		_append_focus_if_visible(out, sfx_slider)
		_append_focus_if_visible(out, bgm_slider)
		_append_focus_if_visible(out, sound_back_button)
		return out
	if move_list_panel.visible:
		_append_focus_if_visible(out, move_list_back_button)
		return out
	_append_focus_if_visible(out, resume_button)
	_append_focus_if_visible(out, toggle_hitbox_button)
	_append_focus_if_visible(out, open_hitbox_editor_button)
	_append_focus_if_visible(out, move_list_button)
	_append_focus_if_visible(out, button_config_button)
	_append_focus_if_visible(out, sound_config_button)
	_append_focus_if_visible(out, exit_character_select_button)
	_append_focus_if_visible(out, exit_main_menu_button)
	return out


func _append_focus_if_visible(out: Array[Control], control: Control) -> void:
	if control == null or not control.visible or not control.is_inside_tree():
		return
	if control.focus_mode == Control.FOCUS_NONE:
		control.focus_mode = Control.FOCUS_ALL
	out.append(control)


func show_menu() -> void:
	visible = true
	title_label.text = "Training Menu" if current_is_training_mode else "Pause Menu"
	_show_main_panel()
	resume_button.grab_focus()


func hide_menu() -> void:
	visible = false
	_close_controls_overlay()


func set_menu_state(is_training_mode: bool, _dummy_local_input: bool, hitbox_debug: bool) -> void:
	current_is_training_mode = is_training_mode
	_update_debug_state_label(hitbox_debug)
	_update_hitbox_editor_ui()


func _update_debug_state_label(enabled: bool) -> void:
	if debug_state_label == null:
		return
	debug_state_label.visible = current_is_training_mode
	if toggle_hitbox_button != null:
		toggle_hitbox_button.visible = current_is_training_mode
	if current_is_training_mode:
		debug_state_label.text = "Debug View: Hitboxes + Hurtboxes %s" % ("ON" if enabled else "OFF")
		if toggle_hitbox_button != null:
			toggle_hitbox_button.text = "Hitboxes + Hurtboxes: %s" % ("ON" if enabled else "OFF")


func _update_hitbox_editor_ui() -> void:
	var visible_training_tools: bool = current_is_training_mode
	if hitbox_editor_hint_label != null:
		hitbox_editor_hint_label.visible = visible_training_tools
	if open_hitbox_editor_button != null:
		open_hitbox_editor_button.visible = visible_training_tools


func set_move_list_text(value: String) -> void:
	current_move_list_text = value.strip_edges()
	if current_move_list_text.is_empty():
		current_move_list_text = "No moves available."
	move_list_text.text = current_move_list_text


func _show_main_panel() -> void:
	main_scroll.visible = true
	move_list_panel.visible = false
	sound_panel.visible = false
	main_scroll.scroll_vertical = 0


func _show_move_list_panel() -> void:
	main_scroll.visible = false
	move_list_panel.visible = true
	sound_panel.visible = false
	move_list_text.text = current_move_list_text
	move_list_text.add_theme_color_override("default_color", Color(0.96, 0.98, 1.0, 1.0))
	move_list_text.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 1.0))
	move_list_text.add_theme_constant_override("outline_size", 1)
	move_list_title.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0, 1.0))
	move_list_back_button.grab_focus()


func _show_sound_panel() -> void:
	main_scroll.visible = false
	move_list_panel.visible = false
	sound_panel.visible = true
	_update_sound_labels()
	sound_back_button.grab_focus()


func _show_controls_overlay() -> void:
	if controls_overlay != null and is_instance_valid(controls_overlay):
		return
	var instance: Node = CONTROLS_MENU_SCENE.instantiate()
	if not (instance is Control):
		if instance != null:
			instance.queue_free()
		return
	controls_overlay = instance as Control
	controls_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	if controls_overlay.has_method("set_embedded_mode"):
		controls_overlay.call("set_embedded_mode", true)
	if controls_overlay.has_signal("closed"):
		controls_overlay.closed.connect(_on_controls_overlay_closed)
	$Root.add_child(controls_overlay)


func _close_controls_overlay() -> void:
	if controls_overlay != null and is_instance_valid(controls_overlay):
		controls_overlay.queue_free()
	controls_overlay = null


func _on_controls_overlay_closed() -> void:
	controls_overlay = null
	button_config_button.grab_focus()


func _load_sound_settings() -> void:
	var cfg := ConfigFile.new()
	var master: float = 1.0
	var sfx: float = 0.8
	var bgm: float = 0.75
	if cfg.load(SETTINGS_PATH) == OK:
		master = float(cfg.get_value("audio", "master_volume", master))
		sfx = float(cfg.get_value("audio", "sfx_volume", sfx))
		bgm = float(cfg.get_value("audio", "bgm_volume", bgm))
	master_slider.value = clampf(master, 0.0, 1.0)
	sfx_slider.value = clampf(sfx, 0.0, 1.0)
	bgm_slider.value = clampf(bgm, 0.0, 1.0)
	_apply_bus_volume("Master", master_slider.value)
	_apply_bus_volume("SFX", sfx_slider.value)
	_apply_bus_volume("BGM", bgm_slider.value)
	_update_sound_labels()


func _save_sound_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "master_volume", master_slider.value)
	cfg.set_value("audio", "sfx_volume", sfx_slider.value)
	cfg.set_value("audio", "bgm_volume", bgm_slider.value)
	cfg.save(SETTINGS_PATH)


func _apply_bus_volume(bus_name: String, normalized_value: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return
	var value: float = clampf(normalized_value, 0.0, 1.0)
	var db: float = linear_to_db(value) if value > 0.0001 else -80.0
	AudioServer.set_bus_volume_db(bus_idx, db)


func _update_sound_labels() -> void:
	master_value.text = "%d%%" % int(round(master_slider.value * 100.0))
	sfx_value.text = "%d%%" % int(round(sfx_slider.value * 100.0))
	bgm_value.text = "%d%%" % int(round(bgm_slider.value * 100.0))
