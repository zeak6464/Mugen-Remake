extends Control

const SETTINGS_PATH: String = "user://options.cfg"

const RESOLUTION_CHOICES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]
const DIFFICULTY_CHOICES: Array[String] = [
	"Easy 1",
	"Easy 2",
	"Easy 3",
	"Medium 4",
	"Hard 5",
	"Hard 6",
	"Very Hard 7",
	"Very Hard 8"
]
const TIME_LIMIT_CHOICES: Array[int] = [0, 30, 60, 99, 120, 180]
const SMASH_STOCK_MAX: int = 99
const GAME_SPEED_CHOICES: Array[String] = ["Slow", "Normal", "Fast", "Turbo"]
const GAME_SPEED_SCALES: Array[float] = [0.9, 1.0, 1.1, 1.2]
const DEFAULT_DIFFICULTY_INDEX: int = 3
const DEFAULT_TIME_LIMIT_INDEX: int = 3
const DEFAULT_SMASH_STOCK_INDEX: int = 2
const DEFAULT_GAME_SPEED_INDEX: int = 1
const DEFAULT_LIFE_PERCENT: float = 100.0
const DEFAULT_MASTER_VOLUME: float = 1.0
const DEFAULT_SFX_VOLUME: float = 0.8
const DEFAULT_BGM_VOLUME: float = 0.75
const DEFAULT_SHOW_INPUT_BUFFER: bool = false

@onready var margin_container: Control = $MarginContainer
@onready var vbox_container: Control = $MarginContainer/VBoxContainer
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var difficulty_row: Control = $MarginContainer/VBoxContainer/DifficultyRow
@onready var difficulty_option: OptionButton = $MarginContainer/VBoxContainer/DifficultyRow/DifficultyOption
@onready var life_row: Control = $MarginContainer/VBoxContainer/LifeRow
@onready var life_slider: HSlider = $MarginContainer/VBoxContainer/LifeRow/LifeSlider
@onready var life_value_label: Label = $MarginContainer/VBoxContainer/LifeRow/LifeValueLabel
@onready var time_limit_row: Control = $MarginContainer/VBoxContainer/TimeLimitRow
@onready var time_limit_option: OptionButton = $MarginContainer/VBoxContainer/TimeLimitRow/TimeLimitOption
@onready var smash_stocks_row: Control = $MarginContainer/VBoxContainer/SmashStocksRow
@onready var smash_stocks_option: OptionButton = $MarginContainer/VBoxContainer/SmashStocksRow/SmashStocksOption
@onready var game_speed_row: Control = $MarginContainer/VBoxContainer/GameSpeedRow
@onready var game_speed_option: OptionButton = $MarginContainer/VBoxContainer/GameSpeedRow/GameSpeedOption
@onready var resolution_row: Control = $MarginContainer/VBoxContainer/ResolutionRow
@onready var resolution_option: OptionButton = $MarginContainer/VBoxContainer/ResolutionRow/ResolutionOption
@onready var master_sound_row: Control = $MarginContainer/VBoxContainer/MasterSoundRow
@onready var master_sound_slider: HSlider = $MarginContainer/VBoxContainer/MasterSoundRow/MasterSoundSlider
@onready var master_sound_value_label: Label = $MarginContainer/VBoxContainer/MasterSoundRow/MasterSoundValueLabel
@onready var sfx_row: Control = $MarginContainer/VBoxContainer/SfxRow
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/SfxRow/SfxSlider
@onready var sfx_value_label: Label = $MarginContainer/VBoxContainer/SfxRow/SfxValueLabel
@onready var bgm_row: Control = $MarginContainer/VBoxContainer/BgmRow
@onready var bgm_slider: HSlider = $MarginContainer/VBoxContainer/BgmRow/BgmSlider
@onready var bgm_value_label: Label = $MarginContainer/VBoxContainer/BgmRow/BgmValueLabel
@onready var debug_row: Control = $MarginContainer/VBoxContainer/DebugRow
@onready var input_buffer_check: CheckBox = $MarginContainer/VBoxContainer/DebugRow/InputBufferCheck
@onready var controls_button: Button = $MarginContainer/VBoxContainer/ControlsButton
@onready var action_buttons_row: Control = $MarginContainer/VBoxContainer/ActionButtons
@onready var load_button: Button = $MarginContainer/VBoxContainer/ActionButtons/LoadButton
@onready var save_button: Button = $MarginContainer/VBoxContainer/ActionButtons/SaveButton
@onready var defaults_button: Button = $MarginContainer/VBoxContainer/ActionButtons/DefaultsButton
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var bottom_buttons_row: Control = $MarginContainer/VBoxContainer/BottomButtons
@onready var back_button: Button = $MarginContainer/VBoxContainer/BottomButtons/BackButton

func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	UISkin.apply_background(self, "options_menu_bg")
	_build_difficulty_options()
	_build_time_limit_options()
	_build_smash_stock_options()
	_build_game_speed_options()
	_build_resolution_options()

	difficulty_option.item_selected.connect(_on_generic_option_changed)
	life_slider.value_changed.connect(_on_life_slider_changed)
	time_limit_option.item_selected.connect(_on_generic_option_changed)
	smash_stocks_option.item_selected.connect(_on_generic_option_changed)
	game_speed_option.item_selected.connect(_on_game_speed_changed)
	resolution_option.item_selected.connect(_on_resolution_changed)
	master_sound_slider.value_changed.connect(_on_master_sound_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	input_buffer_check.toggled.connect(_on_input_buffer_toggled)
	controls_button.pressed.connect(_on_controls_pressed)
	load_button.pressed.connect(_on_load_pressed)
	save_button.pressed.connect(_on_save_pressed)
	defaults_button.pressed.connect(_on_defaults_pressed)
	back_button.pressed.connect(_on_back_pressed)

	_load_and_apply_settings()
	status_label.text = ""
	_ensure_focus_modes()
	difficulty_option.grab_focus()


func _input(event: InputEvent) -> void:
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
	if focused is OptionButton:
		if left_pressed:
			_adjust_option_button(focused as OptionButton, -1)
			viewport.set_input_as_handled()
			return
		if right_pressed:
			_adjust_option_button(focused as OptionButton, 1)
			viewport.set_input_as_handled()
			return
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
		if focused is CheckBox:
			var checkbox := focused as CheckBox
			checkbox.button_pressed = not checkbox.button_pressed
			viewport.set_input_as_handled()
			return
		if focused is OptionButton:
			_adjust_option_button(focused as OptionButton, 1)
			viewport.set_input_as_handled()
			return
	if cancel_pressed:
		_on_back_pressed()
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
	var focused: Control = get_viewport().gui_get_focus_owner()
	var index: int = controls.find(focused)
	if index < 0:
		controls[0].grab_focus()
		return
	var next_index: int = wrapi(index + direction, 0, controls.size())
	controls[next_index].grab_focus()


func _menu_focus_controls() -> Array[Control]:
	var out: Array[Control] = []
	_append_focus_if_visible(out, difficulty_option)
	_append_focus_if_visible(out, life_slider)
	_append_focus_if_visible(out, time_limit_option)
	_append_focus_if_visible(out, smash_stocks_option)
	_append_focus_if_visible(out, game_speed_option)
	_append_focus_if_visible(out, resolution_option)
	_append_focus_if_visible(out, master_sound_slider)
	_append_focus_if_visible(out, sfx_slider)
	_append_focus_if_visible(out, bgm_slider)
	_append_focus_if_visible(out, input_buffer_check)
	_append_focus_if_visible(out, controls_button)
	_append_focus_if_visible(out, load_button)
	_append_focus_if_visible(out, save_button)
	_append_focus_if_visible(out, defaults_button)
	_append_focus_if_visible(out, back_button)
	return out


func _append_focus_if_visible(out: Array[Control], control: Control) -> void:
	if control == null:
		return
	if not control.visible:
		return
	if control.focus_mode == Control.FOCUS_NONE:
		control.focus_mode = Control.FOCUS_ALL
	out.append(control)


func _ensure_focus_modes() -> void:
	for control in _menu_focus_controls():
		if control.focus_mode == Control.FOCUS_NONE:
			control.focus_mode = Control.FOCUS_ALL


func _adjust_option_button(option: OptionButton, delta: int) -> void:
	if option == null:
		return
	var count: int = option.item_count
	if count <= 0:
		return
	var selected: int = option.selected
	if selected < 0:
		selected = 0
	var next: int = wrapi(selected + delta, 0, count)
	option.select(next)
	option.emit_signal("item_selected", next)




func _build_resolution_options() -> void:
	resolution_option.clear()
	for i in range(RESOLUTION_CHOICES.size()):
		var res: Vector2i = RESOLUTION_CHOICES[i]
		resolution_option.add_item("%dx%d" % [res.x, res.y], i)
	resolution_option.disabled = false


func _build_difficulty_options() -> void:
	difficulty_option.clear()
	for i in range(DIFFICULTY_CHOICES.size()):
		difficulty_option.add_item(DIFFICULTY_CHOICES[i], i)


func _build_time_limit_options() -> void:
	time_limit_option.clear()
	time_limit_option.add_item("Infinite", 0)
	for i in range(1, TIME_LIMIT_CHOICES.size()):
		time_limit_option.add_item(str(TIME_LIMIT_CHOICES[i]), i)


func _build_smash_stock_options() -> void:
	smash_stocks_option.clear()
	for i in range(SMASH_STOCK_MAX):
		smash_stocks_option.add_item(str(i + 1), i)


func _build_game_speed_options() -> void:
	game_speed_option.clear()
	for i in range(GAME_SPEED_CHOICES.size()):
		game_speed_option.add_item(GAME_SPEED_CHOICES[i], i)


func _on_resolution_changed(index: int) -> void:
	if index < 0 or index >= RESOLUTION_CHOICES.size():
		return
	SystemSFX.play_ui_from(self, "ui_move")
	var resolution_size: Vector2i = RESOLUTION_CHOICES[index]
	DisplayServer.window_set_size(resolution_size)
	_save_current_settings()
	status_label.text = "Resolution set to %dx%d" % [resolution_size.x, resolution_size.y]


func _on_generic_option_changed(_index: int) -> void:
	SystemSFX.play_ui_from(self, "ui_move")
	_save_current_settings()


func _on_life_slider_changed(value: float) -> void:
	life_value_label.text = "%d%%" % int(round(value))
	_save_current_settings()


func _on_game_speed_changed(index: int) -> void:
	var clamped_index: int = clampi(index, 0, GAME_SPEED_SCALES.size() - 1)
	Engine.time_scale = GAME_SPEED_SCALES[clamped_index]
	SystemSFX.play_ui_from(self, "ui_move")
	_save_current_settings()


func _on_master_sound_slider_changed(value: float) -> void:
	_apply_bus_volume("Master", value)
	master_sound_value_label.text = "%d%%" % int(round(value * 100.0))
	_save_current_settings()


func _on_sfx_slider_changed(value: float) -> void:
	_apply_bus_volume("SFX", value)
	sfx_value_label.text = "%d%%" % int(round(value * 100.0))
	_save_current_settings()


func _on_bgm_slider_changed(value: float) -> void:
	_apply_bus_volume("BGM", value)
	bgm_value_label.text = "%d%%" % int(round(value * 100.0))
	_save_current_settings()


func _on_input_buffer_toggled(_enabled: bool) -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_save_current_settings()


func _on_controls_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().change_scene_to_file("res://ui/ControlsMenu.tscn")


func _on_load_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_load_and_apply_settings()
	status_label.text = "Settings loaded."


func _on_save_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_save_current_settings()
	status_label.text = "Settings saved."


func _on_defaults_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_apply_defaults()
	_save_current_settings()
	status_label.text = "Default values restored."


func _on_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")


func _load_and_apply_settings() -> void:
	var cfg := ConfigFile.new()
	var err: int = cfg.load(SETTINGS_PATH)

	var difficulty_index: int = DEFAULT_DIFFICULTY_INDEX
	var life_percent: float = DEFAULT_LIFE_PERCENT
	var time_limit_index: int = DEFAULT_TIME_LIMIT_INDEX
	var smash_stock_index: int = DEFAULT_SMASH_STOCK_INDEX
	var game_speed_index: int = DEFAULT_GAME_SPEED_INDEX
	var resolution_index: int = 0
	var master_volume: float = DEFAULT_MASTER_VOLUME
	var sfx_volume: float = DEFAULT_SFX_VOLUME
	var bgm_volume: float = DEFAULT_BGM_VOLUME
	var show_input_buffer: bool = DEFAULT_SHOW_INPUT_BUFFER

	if err == OK:
		difficulty_index = int(cfg.get_value("gameplay", "difficulty_index", difficulty_index))
		life_percent = float(cfg.get_value("gameplay", "life_percent", life_percent))
		time_limit_index = int(cfg.get_value("gameplay", "time_limit_index", time_limit_index))
		smash_stock_index = int(cfg.get_value("gameplay", "smash_stock_index", smash_stock_index))
		game_speed_index = int(cfg.get_value("gameplay", "game_speed_index", game_speed_index))
		resolution_index = int(cfg.get_value("video", "resolution_index", resolution_index))
		master_volume = float(cfg.get_value("audio", "master_volume", master_volume))
		sfx_volume = float(cfg.get_value("audio", "sfx_volume", sfx_volume))
		bgm_volume = float(cfg.get_value("audio", "bgm_volume", bgm_volume))
		show_input_buffer = bool(cfg.get_value("debug", "show_input_buffer", show_input_buffer))

	difficulty_index = clampi(difficulty_index, 0, DIFFICULTY_CHOICES.size() - 1)
	difficulty_option.select(difficulty_index)

	life_percent = clampf(life_percent, life_slider.min_value, life_slider.max_value)
	life_slider.value = life_percent
	life_value_label.text = "%d%%" % int(round(life_percent))

	time_limit_index = clampi(time_limit_index, 0, TIME_LIMIT_CHOICES.size() - 1)
	time_limit_option.select(time_limit_index)

	smash_stock_index = clampi(smash_stock_index, 0, SMASH_STOCK_MAX - 1)
	smash_stocks_option.select(smash_stock_index)

	game_speed_index = clampi(game_speed_index, 0, GAME_SPEED_CHOICES.size() - 1)
	game_speed_option.select(game_speed_index)
	Engine.time_scale = GAME_SPEED_SCALES[game_speed_index]

	resolution_index = clampi(resolution_index, 0, RESOLUTION_CHOICES.size() - 1)
	resolution_option.select(resolution_index)
	var resolution_size: Vector2i = RESOLUTION_CHOICES[resolution_index]
	DisplayServer.window_set_size(resolution_size)

	master_volume = clampf(master_volume, 0.0, 1.0)
	sfx_volume = clampf(sfx_volume, 0.0, 1.0)
	bgm_volume = clampf(bgm_volume, 0.0, 1.0)
	master_sound_slider.value = master_volume
	sfx_slider.value = sfx_volume
	bgm_slider.value = bgm_volume
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("SFX", sfx_volume)
	_apply_bus_volume("BGM", bgm_volume)
	master_sound_value_label.text = "%d%%" % int(round(master_volume * 100.0))
	sfx_value_label.text = "%d%%" % int(round(sfx_volume * 100.0))
	bgm_value_label.text = "%d%%" % int(round(bgm_volume * 100.0))
	input_buffer_check.button_pressed = show_input_buffer
	_publish_runtime_option_meta()


func _save_current_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("gameplay", "difficulty_index", difficulty_option.get_selected_id())
	cfg.set_value("gameplay", "life_percent", life_slider.value)
	cfg.set_value("gameplay", "time_limit_index", time_limit_option.get_selected_id())
	cfg.set_value("gameplay", "time_limit_seconds", TIME_LIMIT_CHOICES[time_limit_option.get_selected_id()])
	cfg.set_value("gameplay", "smash_stock_index", smash_stocks_option.get_selected_id())
	cfg.set_value("gameplay", "smash_stocks", smash_stocks_option.get_selected_id() + 1)
	cfg.set_value("gameplay", "game_speed_index", game_speed_option.get_selected_id())
	cfg.set_value("gameplay", "game_speed_scale", GAME_SPEED_SCALES[game_speed_option.get_selected_id()])
	cfg.set_value("video", "resolution_index", resolution_option.get_selected_id())
	cfg.set_value("audio", "master_volume", master_sound_slider.value)
	cfg.set_value("audio", "sfx_volume", sfx_slider.value)
	cfg.set_value("audio", "bgm_volume", bgm_slider.value)
	cfg.set_value("debug", "show_input_buffer", input_buffer_check.button_pressed)
	cfg.save(SETTINGS_PATH)
	_publish_runtime_option_meta()


func _apply_bus_volume(bus_name: String, linear_value: float) -> void:
	var target_name: String = bus_name if AudioServer.get_bus_index(bus_name) >= 0 else "Master"
	var bus_index: int = AudioServer.get_bus_index(target_name)
	if bus_index < 0:
		return
	if linear_value <= 0.0001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))


func _get_current_resolution_index() -> int:
	var current_size: Vector2i = DisplayServer.window_get_size()
	for i in range(RESOLUTION_CHOICES.size()):
		if current_size == RESOLUTION_CHOICES[i]:
			return i
	return 0


func _apply_defaults() -> void:
	difficulty_option.select(DEFAULT_DIFFICULTY_INDEX)
	life_slider.value = DEFAULT_LIFE_PERCENT
	life_value_label.text = "%d%%" % int(round(DEFAULT_LIFE_PERCENT))
	time_limit_option.select(DEFAULT_TIME_LIMIT_INDEX)
	smash_stocks_option.select(DEFAULT_SMASH_STOCK_INDEX)
	game_speed_option.select(DEFAULT_GAME_SPEED_INDEX)
	Engine.time_scale = GAME_SPEED_SCALES[DEFAULT_GAME_SPEED_INDEX]
	resolution_option.select(0)
	DisplayServer.window_set_size(RESOLUTION_CHOICES[0])
	master_sound_slider.value = DEFAULT_MASTER_VOLUME
	sfx_slider.value = DEFAULT_SFX_VOLUME
	bgm_slider.value = DEFAULT_BGM_VOLUME
	_apply_bus_volume("Master", DEFAULT_MASTER_VOLUME)
	_apply_bus_volume("SFX", DEFAULT_SFX_VOLUME)
	_apply_bus_volume("BGM", DEFAULT_BGM_VOLUME)
	master_sound_value_label.text = "%d%%" % int(round(DEFAULT_MASTER_VOLUME * 100.0))
	sfx_value_label.text = "%d%%" % int(round(DEFAULT_SFX_VOLUME * 100.0))
	bgm_value_label.text = "%d%%" % int(round(DEFAULT_BGM_VOLUME * 100.0))
	input_buffer_check.button_pressed = DEFAULT_SHOW_INPUT_BUFFER


func _publish_runtime_option_meta() -> void:
	var tree := get_tree()
	tree.set_meta("option_difficulty_index", difficulty_option.get_selected_id())
	tree.set_meta("option_life_percent", life_slider.value)
	tree.set_meta("option_time_limit_seconds", TIME_LIMIT_CHOICES[time_limit_option.get_selected_id()])
	tree.set_meta("option_smash_stocks", smash_stocks_option.get_selected_id() + 1)
	tree.set_meta("option_game_speed_scale", GAME_SPEED_SCALES[game_speed_option.get_selected_id()])
