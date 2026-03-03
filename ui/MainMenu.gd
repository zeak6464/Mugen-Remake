extends Control

const RING_MENU_SCENE: PackedScene = preload("res://ui/components/RingMenu.tscn")

@export var training_scene_path: String = "res://ui/CharacterSelect.tscn"
@export var options_scene_path: String = "res://ui/OptionsMenu.tscn"
@export var box_editor_scene_path: String = "res://ui/CharacterEditor.tscn"
@export var json_editor_scene_path: String = "res://ui/CharacterEditor.tscn"
@export var stage_editor_scene_path: String = "res://ui/StageEditor.tscn"
@export var model_viewer_scene_path: String = "res://ui/ModelViewer.tscn"
@export var bootstrap_bundled_content_on_menu: bool = true
@export var background_video_paths: Array[String] = [
	"user://ui-skin/videos/mainmenu.ogv",
	"user://videos/mainmenu.ogv",
	"res://videos/mainmenu.ogv"
]

@onready var training_button: Button = $CenterContainer/VBoxContainer/TrainingModeButton
@onready var arcade_button: Button = $CenterContainer/VBoxContainer/ArcadeModeButton
@onready var versus_button: Button = $CenterContainer/VBoxContainer/VersusModeButton
@onready var smash_button: Button = $CenterContainer/VBoxContainer/SmashModeButton
@onready var team_button: Button = $CenterContainer/VBoxContainer/TeamModeButton
@onready var team_submenu: Control = $CenterContainer/VBoxContainer/TeamModeSubmenu
@onready var team_subtype_option: OptionButton = $CenterContainer/VBoxContainer/TeamModeSubmenu/TeamSubtypeRow/TeamSubtypeOption
@onready var team_p1_size_option: OptionButton = $CenterContainer/VBoxContainer/TeamModeSubmenu/TeamP1SizeRow/TeamP1SizeOption
@onready var team_p2_size_option: OptionButton = $CenterContainer/VBoxContainer/TeamModeSubmenu/TeamP2SizeRow/TeamP2SizeOption
@onready var team_start_button: Button = $CenterContainer/VBoxContainer/TeamModeSubmenu/TeamSubmenuButtons/TeamStartButton
@onready var team_back_button: Button = $CenterContainer/VBoxContainer/TeamModeSubmenu/TeamSubmenuButtons/TeamBackButton
@onready var survival_button: Button = $CenterContainer/VBoxContainer/SurvivalModeButton
@onready var watch_button: Button = $CenterContainer/VBoxContainer/WatchModeButton
@onready var options_button: Button = $CenterContainer/VBoxContainer/OptionsButton
@onready var character_editor_button: Button = $CenterContainer/VBoxContainer/BoxEditorButton
@onready var character_editor_submenu: Control = $CenterContainer/VBoxContainer/CharacterEditorSubmenu
@onready var character_editor_box_button: Button = $CenterContainer/VBoxContainer/CharacterEditorSubmenu/CharacterEditorBoxButton
@onready var json_editor_button: Button = $CenterContainer/VBoxContainer/CharacterEditorSubmenu/JsonEditorButton
@onready var character_editor_commands_button: Button = $CenterContainer/VBoxContainer/CharacterEditorSubmenu/CharacterEditorCommandsButton
@onready var character_editor_preview_button: Button = $CenterContainer/VBoxContainer/CharacterEditorSubmenu/CharacterEditorPreviewButton
@onready var stage_editor_button: Button = $CenterContainer/VBoxContainer/StageEditorButton
@onready var open_mods_folder_button: Button = $CenterContainer/VBoxContainer/OpenModsFolderButton
@onready var open_stages_folder_button: Button = $CenterContainer/VBoxContainer/OpenStagesFolderButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitGameButton
@onready var options_status_label: Label = $CenterContainer/VBoxContainer/OptionsStatusLabel

var background_video_player: VideoStreamPlayer = null
var main_ring_menu: RingMenu = null
var main_ring_items: Array[Dictionary] = []


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	var has_video: bool = _setup_looping_background_video(background_video_paths)
	if not has_video:
		UISkin.apply_background(self, "main_menu_bg")
	SystemSFX.play_menu_music_from(self, "mainmenu", true, -8.0)
	if bootstrap_bundled_content_on_menu:
		_bootstrap_bundled_content()
	training_button.pressed.connect(_on_training_mode_pressed)
	arcade_button.pressed.connect(_on_arcade_mode_pressed)
	versus_button.pressed.connect(_on_versus_mode_pressed)
	smash_button.pressed.connect(_on_smash_mode_pressed)
	team_button.pressed.connect(_on_team_mode_pressed)
	team_start_button.pressed.connect(_on_team_start_pressed)
	team_back_button.pressed.connect(_on_team_back_pressed)
	survival_button.pressed.connect(_on_survival_mode_pressed)
	watch_button.pressed.connect(_on_watch_mode_pressed)
	options_button.pressed.connect(_on_options_pressed)
	character_editor_button.pressed.connect(_on_character_editor_pressed)
	character_editor_box_button.pressed.connect(_on_box_editor_pressed)
	json_editor_button.pressed.connect(_on_json_editor_pressed)
	character_editor_commands_button.pressed.connect(_on_commands_editor_pressed)
	character_editor_preview_button.pressed.connect(_on_character_preview_pressed)
	stage_editor_button.pressed.connect(_on_stage_editor_pressed)
	open_mods_folder_button.pressed.connect(_on_open_mods_folder_pressed)
	open_stages_folder_button.pressed.connect(_on_open_stages_folder_pressed)
	quit_button.pressed.connect(_on_quit_game_pressed)
	training_button.grab_focus()
	options_status_label.visible = false
	character_editor_submenu.visible = false
	team_submenu.visible = false
	_build_team_mode_options()
	_setup_main_ring_menu()
	_set_legacy_main_buttons_visible(false)


func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	# Ring navigation is the primary top-level navigation mode.
	if not team_submenu.visible and not character_editor_submenu.visible and main_ring_menu != null:
		var prev_page_pressed: bool = _menu_action_pressed(event, &"p1_h") or _menu_action_pressed(event, &"p2_h")
		var next_page_pressed: bool = _menu_action_pressed(event, &"p1_s") or _menu_action_pressed(event, &"p2_s")
		var left_pressed_ring: bool = _menu_action_pressed(event, &"p1_left") or _menu_action_pressed(event, &"p2_left")
		var right_pressed_ring: bool = _menu_action_pressed(event, &"p1_right") or _menu_action_pressed(event, &"p2_right")
		var up_pressed_ring: bool = _menu_action_pressed(event, &"p1_up") or _menu_action_pressed(event, &"p2_up")
		var down_pressed_ring: bool = _menu_action_pressed(event, &"p1_down") or _menu_action_pressed(event, &"p2_down")
		var confirm_ring: bool = _menu_action_pressed(event, &"p1_p") or _menu_action_pressed(event, &"p2_p")
		if prev_page_pressed:
			viewport.set_input_as_handled()
			main_ring_menu.previous_page()
			SystemSFX.play_ui_from(self, "ui_move")
			return
		if next_page_pressed:
			viewport.set_input_as_handled()
			main_ring_menu.next_page()
			SystemSFX.play_ui_from(self, "ui_move")
			return
		if left_pressed_ring or up_pressed_ring:
			viewport.set_input_as_handled()
			main_ring_menu.rotate_selection(-1)
			SystemSFX.play_ui_from(self, "ui_move")
			return
		if right_pressed_ring or down_pressed_ring:
			viewport.set_input_as_handled()
			main_ring_menu.rotate_selection(1)
			SystemSFX.play_ui_from(self, "ui_move")
			return
		if confirm_ring:
			viewport.set_input_as_handled()
			_activate_main_ring_selection(main_ring_menu.get_selected_index())
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
		var option := focused as OptionButton
		if left_pressed:
			_adjust_option_button(option, -1)
			viewport.set_input_as_handled()
			return
		if right_pressed:
			_adjust_option_button(option, 1)
			viewport.set_input_as_handled()
			return

	if confirm_pressed:
		if focused is Button:
			viewport.set_input_as_handled()
			(focused as Button).emit_signal("pressed")
			return
		if focused is OptionButton:
			_adjust_option_button(focused as OptionButton, 1)
			viewport.set_input_as_handled()
			return

	if cancel_pressed:
		if team_submenu.visible:
			viewport.set_input_as_handled()
			_on_team_back_pressed()
			return
		if character_editor_submenu.visible:
			viewport.set_input_as_handled()
			SystemSFX.play_ui_from(self, "ui_back")
			character_editor_submenu.visible = false
			if main_ring_menu != null:
				main_ring_menu.visible = not team_submenu.visible
			return


func _setup_main_ring_menu() -> void:
	var ring_instance: Node = RING_MENU_SCENE.instantiate()
	if not (ring_instance is RingMenu):
		return
	main_ring_menu = ring_instance as RingMenu
	main_ring_menu.name = "MainRingMenu"
	main_ring_menu.radius = 210.0
	main_ring_menu.item_min_size = Vector2(190, 42)
	main_ring_menu.max_items_per_page = 8
	$CenterContainer.add_child(main_ring_menu)
	$CenterContainer.move_child(main_ring_menu, 1)
	_build_main_ring_items()
	main_ring_menu.set_items(main_ring_items)
	main_ring_menu.item_confirmed.connect(_activate_main_ring_selection)


func _build_main_ring_items() -> void:
	main_ring_items = [
		{"id": "training", "label": "Training Mode"},
		{"id": "arcade", "label": "Arcade Mode"},
		{"id": "versus", "label": "2P Versus"},
		{"id": "smash", "label": "Smash Mode"},
		{"id": "team", "label": "Team Mode"},
		{"id": "survival", "label": "Survival Mode"},
		{"id": "watch", "label": "Watch Mode"},
		{"id": "model_viewer", "label": "Model Viewer"},
		{"id": "character_editor", "label": "Character Editor"},
		{"id": "stage_editor", "label": "Stage Editor"},
		{"id": "open_mods", "label": "Open Mods Folder"},
		{"id": "open_stages", "label": "Open Stages Folder"},
		{"id": "options", "label": "Options"},
		{"id": "quit", "label": "Quit Game"}
	]


func _activate_main_ring_selection(index: int) -> void:
	if index < 0 or index >= main_ring_items.size():
		return
	var item: Dictionary = main_ring_items[index]
	match str(item.get("id", "")):
		"training":
			_on_training_mode_pressed()
		"arcade":
			_on_arcade_mode_pressed()
		"versus":
			_on_versus_mode_pressed()
		"smash":
			_on_smash_mode_pressed()
		"team":
			_on_team_mode_pressed()
		"survival":
			_on_survival_mode_pressed()
		"watch":
			_on_watch_mode_pressed()
		"model_viewer":
			_on_model_viewer_pressed()
		"character_editor":
			_on_character_editor_pressed()
		"stage_editor":
			_on_stage_editor_pressed()
		"open_mods":
			_on_open_mods_folder_pressed()
		"open_stages":
			_on_open_stages_folder_pressed()
		"options":
			_on_options_pressed()
		"quit":
			_on_quit_game_pressed()


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
		SystemSFX.play_ui_from(self, "ui_move")
		return
	var next_index: int = posmod(index + direction, controls.size())
	controls[next_index].grab_focus()
	SystemSFX.play_ui_from(self, "ui_move")


func _menu_focus_controls() -> Array[Control]:
	var out: Array[Control] = []
	_append_focus_if_visible(out, training_button)
	_append_focus_if_visible(out, arcade_button)
	_append_focus_if_visible(out, versus_button)
	_append_focus_if_visible(out, smash_button)
	_append_focus_if_visible(out, team_button)
	if team_submenu.visible:
		_append_focus_if_visible(out, team_subtype_option)
		_append_focus_if_visible(out, team_p1_size_option)
		_append_focus_if_visible(out, team_p2_size_option)
		_append_focus_if_visible(out, team_start_button)
		_append_focus_if_visible(out, team_back_button)
	_append_focus_if_visible(out, survival_button)
	_append_focus_if_visible(out, watch_button)
	_append_focus_if_visible(out, options_button)
	_append_focus_if_visible(out, character_editor_button)
	if character_editor_submenu.visible:
		_append_focus_if_visible(out, character_editor_box_button)
		_append_focus_if_visible(out, json_editor_button)
		_append_focus_if_visible(out, character_editor_commands_button)
		_append_focus_if_visible(out, character_editor_preview_button)
	_append_focus_if_visible(out, stage_editor_button)
	_append_focus_if_visible(out, open_mods_folder_button)
	_append_focus_if_visible(out, open_stages_folder_button)
	_append_focus_if_visible(out, quit_button)
	return out


func _append_focus_if_visible(out: Array[Control], control: Control) -> void:
	if control == null:
		return
	if not control.visible:
		return
	if not control.is_inside_tree():
		return
	if control.focus_mode == Control.FOCUS_NONE:
		control.focus_mode = Control.FOCUS_ALL
	out.append(control)


func _adjust_option_button(option: OptionButton, delta: int) -> void:
	if option == null or option.item_count <= 0:
		return
	var next_index: int = clampi(option.selected + delta, 0, option.item_count - 1)
	if next_index == option.selected:
		return
	option.select(next_index)
	option.emit_signal("item_selected", next_index)
	SystemSFX.play_ui_from(self, "ui_move")


func _on_training_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "training")
	get_tree().change_scene_to_file(training_scene_path)


func _on_arcade_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "arcade")
	get_tree().change_scene_to_file(training_scene_path)


func _on_versus_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "versus")
	get_tree().change_scene_to_file(training_scene_path)


func _on_smash_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "smash")
	get_tree().change_scene_to_file(training_scene_path)


func _on_team_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	team_submenu.visible = not team_submenu.visible
	if main_ring_menu != null:
		main_ring_menu.visible = not team_submenu.visible and not character_editor_submenu.visible


func _on_team_start_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().set_meta("game_mode", "team")
	get_tree().set_meta("team_mode_subtype", _selected_team_subtype())
	get_tree().set_meta("team_size_p1", _selected_team_size(team_p1_size_option))
	get_tree().set_meta("team_size_p2", _selected_team_size(team_p2_size_option))
	get_tree().change_scene_to_file(training_scene_path)


func _on_team_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	team_submenu.visible = false
	if main_ring_menu != null:
		main_ring_menu.visible = not character_editor_submenu.visible


func _on_survival_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "survival")
	get_tree().change_scene_to_file(training_scene_path)


func _on_watch_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "watch")
	get_tree().change_scene_to_file(training_scene_path)


func _on_model_viewer_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().change_scene_to_file(model_viewer_scene_path)


func _on_options_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().change_scene_to_file(options_scene_path)


func _on_character_editor_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	character_editor_submenu.visible = not character_editor_submenu.visible
	if main_ring_menu != null:
		main_ring_menu.visible = not character_editor_submenu.visible and not team_submenu.visible


func _set_legacy_main_buttons_visible(visible_value: bool) -> void:
	training_button.visible = visible_value
	arcade_button.visible = visible_value
	versus_button.visible = visible_value
	smash_button.visible = visible_value
	team_button.visible = visible_value
	survival_button.visible = visible_value
	watch_button.visible = visible_value
	character_editor_button.visible = visible_value
	stage_editor_button.visible = visible_value
	open_mods_folder_button.visible = visible_value
	open_stages_folder_button.visible = visible_value
	options_button.visible = visible_value
	quit_button.visible = visible_value
	options_status_label.visible = false


func _on_box_editor_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().set_meta("character_editor_section", "boxes")
	get_tree().change_scene_to_file(box_editor_scene_path)


func _on_json_editor_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().set_meta("character_editor_section", "files")
	get_tree().change_scene_to_file(json_editor_scene_path)


func _on_commands_editor_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().set_meta("character_editor_section", "commands")
	get_tree().change_scene_to_file(box_editor_scene_path)


func _on_character_preview_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().set_meta("character_editor_section", "preview")
	get_tree().change_scene_to_file(box_editor_scene_path)


func _on_stage_editor_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().change_scene_to_file(stage_editor_scene_path)


func _on_open_mods_folder_pressed() -> void:
	_open_user_content_folder("user://mods/")


func _on_open_stages_folder_pressed() -> void:
	_open_user_content_folder("user://stages/")


func _open_user_content_folder(user_path: String) -> void:
	var normalized_path: String = user_path if user_path.ends_with("/") else "%s/" % user_path
	var abs_path: String = ProjectSettings.globalize_path(normalized_path)
	DirAccess.make_dir_recursive_absolute(abs_path)
	SystemSFX.play_ui_from(self, "ui_confirm")
	var err: Error = OS.shell_open(abs_path)
	if err != OK:
		push_warning("Failed to open folder: %s (error %d)" % [abs_path, err])


func _on_quit_game_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().quit()


func _bootstrap_bundled_content() -> void:
	_sync_all_from_res_root("mods", "user://mods/")
	_sync_all_from_res_root("stages", "user://stages/")


func _sync_all_from_res_root(res_root_name: String, user_root_path: String) -> void:
	var res_root: String = "res://%s/" % res_root_name
	var user_root: String = user_root_path if user_root_path.ends_with("/") else "%s/" % user_root_path
	var user_root_abs := ProjectSettings.globalize_path(user_root)
	DirAccess.make_dir_recursive_absolute(user_root_abs)
	var folder_names: Array[String] = _list_child_directories(res_root)
	for folder_name in folder_names:
		var src_dir: String = "%s%s" % [res_root, folder_name]
		var dst_dir: String = "%s%s" % [user_root, folder_name]
		_sync_directory_recursive(ProjectSettings.globalize_path(src_dir), ProjectSettings.globalize_path(dst_dir))


func _list_child_directories(root_path: String) -> Array[String]:
	var names: Array[String] = []
	var dir := DirAccess.open(root_path)
	if dir == null:
		return names
	dir.list_dir_begin()
	var item: String = dir.get_next()
	while not item.is_empty():
		if dir.current_is_dir() and item != "." and item != "..":
			names.append(item)
		item = dir.get_next()
	dir.list_dir_end()
	return names


func _sync_directory_recursive(src_abs_dir: String, dst_abs_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dst_abs_dir)
	var src_local_dir: String = ProjectSettings.localize_path(src_abs_dir)
	if src_local_dir.is_empty():
		return
	var dir := DirAccess.open(src_local_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while not item.is_empty():
		if item == "." or item == "..":
			item = dir.get_next()
			continue
		var src_item_abs: String = "%s/%s" % [src_abs_dir, item]
		var dst_item_abs: String = "%s/%s" % [dst_abs_dir, item]
		if dir.current_is_dir():
			_sync_directory_recursive(src_item_abs, dst_item_abs)
		else:
			var lower := item.to_lower()
			if not lower.ends_with(".import"):
				_copy_file_absolute(src_item_abs, dst_item_abs)
		item = dir.get_next()
	dir.list_dir_end()


func _copy_file_absolute(src: String, dst: String) -> void:
	var in_file := FileAccess.open(src, FileAccess.READ)
	if in_file == null:
		return
	var bytes := in_file.get_buffer(in_file.get_length())
	var out_file := FileAccess.open(dst, FileAccess.WRITE)
	if out_file == null:
		return
	out_file.store_buffer(bytes)


func _setup_looping_background_video(paths: Array[String]) -> bool:
	var stream: VideoStream = _load_first_video_stream(paths)
	if stream == null:
		return false
	background_video_player = VideoStreamPlayer.new()
	background_video_player.name = "BackgroundVideo"
	background_video_player.anchor_left = 0.0
	background_video_player.anchor_top = 0.0
	background_video_player.anchor_right = 1.0
	background_video_player.anchor_bottom = 1.0
	background_video_player.offset_left = 0.0
	background_video_player.offset_top = 0.0
	background_video_player.offset_right = 0.0
	background_video_player.offset_bottom = 0.0
	background_video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_video_player.expand = true
	background_video_player.stream = stream
	background_video_player.autoplay = true
	add_child(background_video_player)
	move_child(background_video_player, 0)
	if stream is VideoStreamTheora:
		(stream as VideoStreamTheora).loop = true
	background_video_player.play()
	return true


func _load_first_video_stream(paths: Array[String]) -> VideoStream:
	for path_value in paths:
		var path: String = str(path_value).strip_edges()
		if path.is_empty():
			continue
		var stream: VideoStream = _load_video_stream(path)
		if stream != null:
			return stream
	return null


func _load_video_stream(path: String) -> VideoStream:
	var resolved_path: String = path
	if not ResourceLoader.exists(resolved_path):
		var remap_path: String = _resolve_imported_resource_path(path)
		if remap_path.is_empty():
			return null
		resolved_path = remap_path
	if not ResourceLoader.exists(resolved_path):
		return null
	var loaded = ResourceLoader.load(resolved_path)
	if loaded is VideoStream:
		return loaded as VideoStream
	return null


func _resolve_imported_resource_path(source_path: String) -> String:
	var import_path: String = "%s.import" % source_path
	if not FileAccess.file_exists(import_path):
		return ""
	var cfg := ConfigFile.new()
	if cfg.load(import_path) != OK:
		return ""
	return str(cfg.get_value("remap", "path", "")).strip_edges()


func _build_team_mode_options() -> void:
	team_subtype_option.clear()
	team_subtype_option.add_item("Simul")
	team_subtype_option.add_item("Turns")
	team_subtype_option.add_item("Tag")
	team_subtype_option.select(0)
	team_p1_size_option.clear()
	team_p2_size_option.clear()
	for value in [2, 3, 4]:
		team_p1_size_option.add_item(str(value))
		team_p2_size_option.add_item(str(value))
	team_p1_size_option.select(0)
	team_p2_size_option.select(0)


func _selected_team_subtype() -> String:
	match team_subtype_option.selected:
		1:
			return "turns"
		2:
			return "tag"
		_:
			return "simul"


func _selected_team_size(option: OptionButton) -> int:
	if option == null or option.selected < 0 or option.selected >= option.item_count:
		return 2
	return clampi(int(option.get_item_text(option.selected)), 2, 4)


func _clear_team_mode_meta() -> void:
	get_tree().set_meta("team_mode_subtype", "simul")
	get_tree().set_meta("team_size_p1", 2)
	get_tree().set_meta("team_size_p2", 2)
	get_tree().set_meta("team_roster_p1", [])
	get_tree().set_meta("team_roster_p2", [])
