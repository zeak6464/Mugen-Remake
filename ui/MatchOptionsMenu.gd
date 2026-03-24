extends Control

## Mode-specific match options. Shown after picking a game mode; "Fight" goes to Character Select.

const ROUNDS_CHOICES: Array[int] = [1, 3, 5]
const TIME_LIMIT_CHOICES: Array[int] = [0, 60, 99, 120]
const TIME_LIMIT_LABELS: Array[String] = ["Infinite", "60 sec", "99 sec", "120 sec"]
const SMASH_STOCK_MAX: int = 99
const DEFAULT_ROUNDS_INDEX: int = 1
const DEFAULT_TIME_INDEX: int = 1
const DEFAULT_STOCKS_INDEX: int = 2
const TOURNAMENT_SIZE_CHOICES: Array[int] = [4, 8, 16]
const DEFAULT_TOURNAMENT_SIZE_INDEX: int = 0

@export var character_select_path: String = "res://ui/CharacterSelect.tscn"
@export var main_menu_path: String = "res://ui/MainMenu.tscn"

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var rounds_row: Control = $MarginContainer/VBoxContainer/RoundsRow
@onready var rounds_option: OptionButton = $MarginContainer/VBoxContainer/RoundsRow/RoundsOption
@onready var time_limit_row: Control = $MarginContainer/VBoxContainer/TimeLimitRow
@onready var time_limit_option: OptionButton = $MarginContainer/VBoxContainer/TimeLimitRow/TimeLimitOption
@onready var stocks_row: Control = $MarginContainer/VBoxContainer/StocksRow
@onready var stocks_option: OptionButton = $MarginContainer/VBoxContainer/StocksRow/StocksOption
@onready var tournament_size_row: Control = $MarginContainer/VBoxContainer/TournamentSizeRow
@onready var tournament_size_option: OptionButton = $MarginContainer/VBoxContainer/TournamentSizeRow/TournamentSizeOption
@onready var save_replay_check: CheckBox = $MarginContainer/VBoxContainer/SaveReplayRow/SaveReplayCheck
@onready var training_smash_row: Control = $MarginContainer/VBoxContainer/TrainingSmashRow
@onready var training_smash_check: CheckBox = $MarginContainer/VBoxContainer/TrainingSmashRow/TrainingSmashCheck
@onready var fight_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/FightButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/BackButton

var game_mode: String = "training"
var watch_match_type: String = ""


func _ready() -> void:
	_ensure_ui_fits_screen()
	_apply_background_fallback()
	game_mode = str(get_tree().get_meta("game_mode", "training")).to_lower()
	watch_match_type = str(get_tree().get_meta("watch_match_type", "")).to_lower() if game_mode == "watch" else ""
	_apply_title()
	_build_options()
	_load_saved_or_defaults()
	_show_rows_for_mode()
	if training_smash_check != null:
		training_smash_check.toggled.connect(_on_training_smash_toggled)
	fight_button.pressed.connect(_on_fight_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_ensure_focus_modes()
	fight_button.grab_focus()


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
	if confirm_pressed:
		if focused is Button:
			(focused as Button).emit_signal("pressed")
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


func _ensure_focus_modes() -> void:
	for c in _menu_focus_controls():
		if c != null and c.focus_mode == Control.FOCUS_NONE:
			c.focus_mode = Control.FOCUS_ALL


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
	if rounds_row.visible:
		_append_focus(out, rounds_option)
	if time_limit_row.visible:
		_append_focus(out, time_limit_option)
	if tournament_size_row.visible and tournament_size_option != null:
		_append_focus(out, tournament_size_option)
	if training_smash_row != null and training_smash_row.visible and training_smash_check != null:
		_append_focus(out, training_smash_check)
	if stocks_row.visible:
		_append_focus(out, stocks_option)
	_append_focus(out, save_replay_check)
	_append_focus(out, fight_button)
	_append_focus(out, back_button)
	return out


func _append_focus(out: Array[Control], control: Control) -> void:
	if control == null:
		return
	if control.focus_mode == Control.FOCUS_NONE:
		control.focus_mode = Control.FOCUS_ALL
	out.append(control)


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


func _apply_title() -> void:
	if game_mode == "watch" and watch_match_type != "":
		var watch_titles: Dictionary = {
			"versus": "Watch: Versus (Rounds)",
			"smash": "Watch: Smash (Stocks)",
			"team": "Watch: Tag (Team)"
		}
		title_label.text = watch_titles.get(watch_match_type, "Watch Mode Options")
		return
	var titles: Dictionary = {
		"training": "Training Options",
		"cpu_training": "CPU Training Options",
		"versus": "Versus Options",
		"smash": "Smash Mode Options",
		"team": "Team Mode Options",
		"arcade": "Arcade Options",
		"survival": "Survival Options",
		"watch": "Watch Mode Options",
		"online": "Online Match Options",
		"coop": "Co-op Options",
		"tournament": "Tournament Options"
	}
	title_label.text = titles.get(game_mode, "Match Options")


func _build_options() -> void:
	rounds_option.clear()
	for i in range(ROUNDS_CHOICES.size()):
		rounds_option.add_item(str(ROUNDS_CHOICES[i]), i)
	time_limit_option.clear()
	for i in range(TIME_LIMIT_CHOICES.size()):
		time_limit_option.add_item(TIME_LIMIT_LABELS[i] if i < TIME_LIMIT_LABELS.size() else ("%d sec" % TIME_LIMIT_CHOICES[i]), i)
	stocks_option.clear()
	for i in range(1, SMASH_STOCK_MAX + 1):
		stocks_option.add_item(str(i), i - 1)


func _show_rows_for_mode() -> void:
	var use_rounds_time: bool = game_mode in ["training", "cpu_training", "versus", "team", "arcade", "survival", "online", "coop", "tournament"]
	if game_mode == "watch":
		use_rounds_time = watch_match_type in ["", "versus", "team"]
	var training_smash_eligible: bool = game_mode == "training" or game_mode == "cpu_training"
	if training_smash_row != null:
		training_smash_row.visible = training_smash_eligible
	var ts_on: bool = (
		training_smash_eligible
		and training_smash_check != null
		and training_smash_check.button_pressed
	)
	var use_stocks: bool = (
		game_mode == "smash"
		or (game_mode == "watch" and watch_match_type == "smash")
		or ts_on
	)
	rounds_row.visible = use_rounds_time
	time_limit_row.visible = use_rounds_time
	tournament_size_row.visible = game_mode == "tournament"
	stocks_row.visible = use_stocks
	if game_mode == "tournament" and tournament_size_option != null:
		tournament_size_option.clear()
		for i in range(TOURNAMENT_SIZE_CHOICES.size()):
			tournament_size_option.add_item("%d fighters" % TOURNAMENT_SIZE_CHOICES[i], i)


const OPTIONS_CFG_PATH: String = "user://options.cfg"

func _int_meta(tree: SceneTree, key: String, default: int) -> int:
	var v = tree.get_meta(key, default)
	if v is int:
		return int(v)
	return default


func _nearest_time_limit_index(seconds: int) -> int:
	if seconds <= 0:
		return 0
	var best: int = 1
	var best_dist: int = abs(TIME_LIMIT_CHOICES[1] - seconds)
	for i in range(2, TIME_LIMIT_CHOICES.size()):
		var d: int = abs(TIME_LIMIT_CHOICES[i] - seconds)
		if d < best_dist:
			best_dist = d
			best = i
	return best


func _load_saved_or_defaults() -> void:
	var tree: SceneTree = get_tree()
	var rounds_idx: int = _int_meta(tree, "option_rounds_index", DEFAULT_ROUNDS_INDEX)
	var time_idx: int = _int_meta(tree, "option_time_limit_index", -1)
	var stocks_idx: int = _int_meta(tree, "option_smash_stock_index", -1)

	if time_idx < 0 or stocks_idx < 0:
		var cfg := ConfigFile.new()
		if cfg.load(OPTIONS_CFG_PATH) == OK:
			if time_idx < 0:
				var sec: int = int(cfg.get_value("gameplay", "time_limit_seconds", TIME_LIMIT_CHOICES[DEFAULT_TIME_INDEX]))
				time_idx = _nearest_time_limit_index(sec)
			if stocks_idx < 0:
				stocks_idx = clampi(int(cfg.get_value("gameplay", "smash_stock_index", DEFAULT_STOCKS_INDEX)), 0, SMASH_STOCK_MAX - 1)
	if time_idx < 0:
		time_idx = DEFAULT_TIME_INDEX
	if stocks_idx < 0:
		stocks_idx = DEFAULT_STOCKS_INDEX

	rounds_idx = clampi(rounds_idx, 0, ROUNDS_CHOICES.size() - 1)
	time_idx = clampi(time_idx, 0, TIME_LIMIT_CHOICES.size() - 1)
	stocks_idx = clampi(stocks_idx, 0, SMASH_STOCK_MAX - 1)
	rounds_option.select(rounds_idx)
	time_limit_option.select(time_idx)
	stocks_option.select(stocks_idx)
	var tournament_size_idx: int = _int_meta(tree, "option_tournament_size_index", DEFAULT_TOURNAMENT_SIZE_INDEX)
	if game_mode == "tournament":
		var cfg_tournament: ConfigFile = ConfigFile.new()
		if cfg_tournament.load(OPTIONS_CFG_PATH) == OK:
			tournament_size_idx = clampi(int(cfg_tournament.get_value("gameplay", "tournament_size_index", DEFAULT_TOURNAMENT_SIZE_INDEX)), 0, TOURNAMENT_SIZE_CHOICES.size() - 1)
		tournament_size_idx = clampi(tournament_size_idx, 0, TOURNAMENT_SIZE_CHOICES.size() - 1)
		if tournament_size_option != null and tournament_size_option.item_count > 0:
			tournament_size_option.select(tournament_size_idx)
	var cfg := ConfigFile.new()
	if cfg.load(OPTIONS_CFG_PATH) == OK:
		save_replay_check.button_pressed = bool(cfg.get_value("gameplay", "save_replay", false))
		if training_smash_check != null:
			training_smash_check.button_pressed = bool(cfg.get_value("gameplay", "training_smash_rules", false))


func _on_training_smash_toggled(_toggled_on: bool) -> void:
	_show_rows_for_mode()


func _on_fight_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	var tree: SceneTree = get_tree()
	var ts_rules: bool = (
		(game_mode == "training" or game_mode == "cpu_training")
		and training_smash_check != null
		and training_smash_check.button_pressed
	)
	tree.set_meta("training_smash_rules", ts_rules)
	tree.set_meta("option_rounds_to_win", ROUNDS_CHOICES[rounds_option.selected])
	tree.set_meta("option_round_time_seconds", TIME_LIMIT_CHOICES[time_limit_option.selected])
	tree.set_meta("option_rounds_index", rounds_option.selected)
	tree.set_meta("option_time_limit_index", time_limit_option.selected)
	tree.set_meta("option_smash_stocks", stocks_option.selected + 1)
	tree.set_meta("option_smash_stock_index", stocks_option.selected)
	if game_mode == "tournament" and tournament_size_option != null and tournament_size_option.item_count > 0:
		var size: int = TOURNAMENT_SIZE_CHOICES[tournament_size_option.selected]
		tree.set_meta("tournament_size", size)
		tree.set_meta("option_tournament_size_index", tournament_size_option.selected)
		var cfg_tournament := ConfigFile.new()
		cfg_tournament.load(OPTIONS_CFG_PATH)
		cfg_tournament.set_value("gameplay", "tournament_size_index", tournament_size_option.selected)
		cfg_tournament.save(OPTIONS_CFG_PATH)
	tree.set_meta("save_replay", save_replay_check.button_pressed)
	var cfg := ConfigFile.new()
	cfg.load(OPTIONS_CFG_PATH)
	cfg.set_value("gameplay", "save_replay", save_replay_check.button_pressed)
	if training_smash_check != null:
		cfg.set_value("gameplay", "training_smash_rules", training_smash_check.button_pressed)
	cfg.save(OPTIONS_CFG_PATH)
	tree.change_scene_to_file(character_select_path)


func _on_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	get_tree().change_scene_to_file(main_menu_path)


func _ensure_ui_fits_screen() -> void:
	var width: int = int(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
	var height: int = int(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
	var window := get_window()
	if window != null:
		window.min_size = Vector2i(maxi(1, width), maxi(1, height))


func _apply_background_fallback() -> void:
	var bg := get_node_or_null("BackgroundColor") as ColorRect
	if bg != null:
		bg.visible = true
