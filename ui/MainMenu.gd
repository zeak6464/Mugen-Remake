extends Control

const RING_MENU_SCENE: PackedScene = preload("res://ui/components/RingMenu.tscn")
const CONTENT_IMPORT_SERVICE = preload("res://engine/ContentImportService.gd")

@export var training_scene_path: String = "res://ui/CharacterSelect.tscn"
@export var match_options_scene_path: String = "res://ui/MatchOptionsMenu.tscn"
@export var options_scene_path: String = "res://ui/OptionsMenu.tscn"
@export var replay_select_path: String = "res://ui/ReplaySelect.tscn"
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
@onready var online_submenu: Control = $CenterContainer/VBoxContainer/OnlineSubmenu
@onready var online_host_button: Button = $CenterContainer/VBoxContainer/OnlineSubmenu/OnlineHostButton
@onready var online_join_button: Button = $CenterContainer/VBoxContainer/OnlineSubmenu/OnlineJoinButton
@onready var online_back_button: Button = $CenterContainer/VBoxContainer/OnlineSubmenu/OnlineSubmenuButtons/OnlineBackButton
@onready var single_player_submenu: Control = $CenterContainer/VBoxContainer/SinglePlayerSubmenu
@onready var single_player_training_button: Button = $CenterContainer/VBoxContainer/SinglePlayerSubmenu/SinglePlayerTrainingButton
@onready var single_player_arcade_button: Button = $CenterContainer/VBoxContainer/SinglePlayerSubmenu/SinglePlayerArcadeButton
@onready var single_player_survival_button: Button = $CenterContainer/VBoxContainer/SinglePlayerSubmenu/SinglePlayerSurvivalButton
@onready var single_player_watch_button: Button = $CenterContainer/VBoxContainer/SinglePlayerSubmenu/SinglePlayerWatchButton
@onready var single_player_cpu_training_vs_p2_button: Button = $CenterContainer/VBoxContainer/SinglePlayerSubmenu/SinglePlayerCpuTrainingVsP2Button
@onready var single_player_cpu_training_vs_cpu_button: Button = $CenterContainer/VBoxContainer/SinglePlayerSubmenu/SinglePlayerCpuTrainingVsCpuButton
@onready var single_player_back_button: Button = $CenterContainer/VBoxContainer/SinglePlayerSubmenu/SinglePlayerSubmenuButtons/SinglePlayerBackButton
@onready var watch_submenu: Control = $CenterContainer/VBoxContainer/WatchSubmenu
@onready var watch_versus_button: Button = $CenterContainer/VBoxContainer/WatchSubmenu/WatchVersusButton
@onready var watch_smash_button: Button = $CenterContainer/VBoxContainer/WatchSubmenu/WatchSmashButton
@onready var watch_tag_button: Button = $CenterContainer/VBoxContainer/WatchSubmenu/WatchTagButton
@onready var watch_submenu_back_button: Button = $CenterContainer/VBoxContainer/WatchSubmenu/WatchSubmenuButtons/WatchBackButton
@onready var editors_submenu: Control = $CenterContainer/VBoxContainer/EditorsSubmenu
@onready var editors_box_button: Button = $CenterContainer/VBoxContainer/EditorsSubmenu/EditorsBoxButton
@onready var editors_json_button: Button = $CenterContainer/VBoxContainer/EditorsSubmenu/EditorsJsonButton
@onready var editors_commands_button: Button = $CenterContainer/VBoxContainer/EditorsSubmenu/EditorsCommandsButton
@onready var editors_preview_button: Button = $CenterContainer/VBoxContainer/EditorsSubmenu/EditorsPreviewButton
@onready var editors_stage_button: Button = $CenterContainer/VBoxContainer/EditorsSubmenu/EditorsStageButton
@onready var editors_back_button: Button = $CenterContainer/VBoxContainer/EditorsSubmenu/EditorsSubmenuButtons/EditorsBackButton
@onready var import_submenu: Control = $CenterContainer/VBoxContainer/ImportSubmenu
@onready var import_submenu_open_mods_button: Button = $CenterContainer/VBoxContainer/ImportSubmenu/ImportOpenModsButton
@onready var import_submenu_open_stages_button: Button = $CenterContainer/VBoxContainer/ImportSubmenu/ImportOpenStagesButton
@onready var import_submenu_character_button: Button = $CenterContainer/VBoxContainer/ImportSubmenu/ImportCharacterButton
@onready var import_submenu_stage_button: Button = $CenterContainer/VBoxContainer/ImportSubmenu/ImportStageButton
@onready var import_submenu_back_button: Button = $CenterContainer/VBoxContainer/ImportSubmenu/ImportSubmenuButtons/ImportBackButton
@onready var local_multiplayer_submenu: Control = $CenterContainer/VBoxContainer/LocalMultiplayerSubmenu
@onready var local_multiplayer_versus_button: Button = $CenterContainer/VBoxContainer/LocalMultiplayerSubmenu/LocalMultiplayerVersusButton
@onready var local_multiplayer_smash_button: Button = $CenterContainer/VBoxContainer/LocalMultiplayerSubmenu/LocalMultiplayerSmashButton
@onready var local_multiplayer_team_button: Button = $CenterContainer/VBoxContainer/LocalMultiplayerSubmenu/LocalMultiplayerTeamButton
@onready var local_multiplayer_coop_button: Button = $CenterContainer/VBoxContainer/LocalMultiplayerSubmenu/LocalMultiplayerCoopButton
@onready var local_multiplayer_tournament_button: Button = $CenterContainer/VBoxContainer/LocalMultiplayerSubmenu/LocalMultiplayerTournamentButton
@onready var local_multiplayer_back_button: Button = $CenterContainer/VBoxContainer/LocalMultiplayerSubmenu/LocalMultiplayerSubmenuButtons/LocalMultiplayerBackButton
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
@onready var import_character_button: Button = $CenterContainer/VBoxContainer/ImportCharacterButton
@onready var import_stage_button: Button = $CenterContainer/VBoxContainer/ImportStageButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitGameButton
@onready var options_status_label: Label = $CenterContainer/VBoxContainer/OptionsStatusLabel
@onready var import_summary_panel: Panel = $ImportSummaryPanel
@onready var import_summary_label: RichTextLabel = $ImportSummaryPanel/MarginContainer/VBoxContainer/ImportSummaryLabel
@onready var import_open_character_button: Button = $ImportSummaryPanel/MarginContainer/VBoxContainer/ActionsRow/OpenCharacterEditorButton
@onready var import_open_stage_button: Button = $ImportSummaryPanel/MarginContainer/VBoxContainer/ActionsRow/OpenStageEditorButton
@onready var import_summary_close_button: Button = $ImportSummaryPanel/MarginContainer/VBoxContainer/ActionsRow/CloseImportSummaryButton
@onready var import_character_dialog: FileDialog = $ImportCharacterDialog
@onready var import_stage_dialog: FileDialog = $ImportStageDialog

var background_video_player: VideoStreamPlayer = null
var main_ring_menu: RingMenu = null
var main_ring_items: Array[Dictionary] = []
var last_import_report: Dictionary = {}


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
	import_character_button.pressed.connect(_on_import_character_pressed)
	import_stage_button.pressed.connect(_on_import_stage_pressed)
	import_open_character_button.pressed.connect(_on_open_imported_character_editor_pressed)
	import_open_stage_button.pressed.connect(_on_open_imported_stage_editor_pressed)
	import_summary_close_button.pressed.connect(_on_close_import_summary_pressed)
	import_character_dialog.file_selected.connect(_on_import_character_path_selected)
	import_character_dialog.dir_selected.connect(_on_import_character_path_selected)
	import_stage_dialog.file_selected.connect(_on_import_stage_path_selected)
	import_stage_dialog.dir_selected.connect(_on_import_stage_path_selected)
	quit_button.pressed.connect(_on_quit_game_pressed)
	if online_host_button != null:
		online_host_button.pressed.connect(_on_online_host_pressed)
	if online_join_button != null:
		online_join_button.pressed.connect(_on_online_join_pressed)
	if online_back_button != null:
		online_back_button.pressed.connect(_on_online_back_pressed)
	if single_player_training_button != null:
		single_player_training_button.pressed.connect(_on_training_mode_pressed)
	if single_player_arcade_button != null:
		single_player_arcade_button.pressed.connect(_on_arcade_mode_pressed)
	if single_player_survival_button != null:
		single_player_survival_button.pressed.connect(_on_survival_mode_pressed)
	if single_player_watch_button != null:
		single_player_watch_button.pressed.connect(_on_watch_mode_pressed)
	if single_player_cpu_training_vs_p2_button != null:
		single_player_cpu_training_vs_p2_button.pressed.connect(_on_cpu_training_vs_p2_pressed)
	if single_player_cpu_training_vs_cpu_button != null:
		single_player_cpu_training_vs_cpu_button.pressed.connect(_on_cpu_training_vs_cpu_pressed)
	if single_player_back_button != null:
		single_player_back_button.pressed.connect(_on_single_player_back_pressed)
	if watch_versus_button != null:
		watch_versus_button.pressed.connect(_on_watch_versus_pressed)
	if watch_smash_button != null:
		watch_smash_button.pressed.connect(_on_watch_smash_pressed)
	if watch_tag_button != null:
		watch_tag_button.pressed.connect(_on_watch_tag_pressed)
	if watch_submenu_back_button != null:
		watch_submenu_back_button.pressed.connect(_on_watch_submenu_back_pressed)
	if editors_box_button != null:
		editors_box_button.pressed.connect(_on_box_editor_pressed)
	if editors_json_button != null:
		editors_json_button.pressed.connect(_on_json_editor_pressed)
	if editors_commands_button != null:
		editors_commands_button.pressed.connect(_on_commands_editor_pressed)
	if editors_preview_button != null:
		editors_preview_button.pressed.connect(_on_character_preview_pressed)
	if editors_stage_button != null:
		editors_stage_button.pressed.connect(_on_stage_editor_pressed)
	if editors_back_button != null:
		editors_back_button.pressed.connect(_on_editors_back_pressed)
	if import_submenu_open_mods_button != null:
		import_submenu_open_mods_button.pressed.connect(_on_open_mods_folder_pressed)
	if import_submenu_open_stages_button != null:
		import_submenu_open_stages_button.pressed.connect(_on_open_stages_folder_pressed)
	if import_submenu_character_button != null:
		import_submenu_character_button.pressed.connect(_on_import_character_pressed)
	if import_submenu_stage_button != null:
		import_submenu_stage_button.pressed.connect(_on_import_stage_pressed)
	if import_submenu_back_button != null:
		import_submenu_back_button.pressed.connect(_on_import_back_pressed)
	if local_multiplayer_versus_button != null:
		local_multiplayer_versus_button.pressed.connect(_on_versus_mode_pressed)
	if local_multiplayer_smash_button != null:
		local_multiplayer_smash_button.pressed.connect(_on_smash_mode_pressed)
	if local_multiplayer_team_button != null:
		local_multiplayer_team_button.pressed.connect(_on_local_team_pressed)
	if local_multiplayer_coop_button != null:
		local_multiplayer_coop_button.pressed.connect(_on_coop_mode_pressed)
	if local_multiplayer_tournament_button != null:
		local_multiplayer_tournament_button.pressed.connect(_on_tournament_mode_pressed)
	if local_multiplayer_back_button != null:
		local_multiplayer_back_button.pressed.connect(_on_local_multiplayer_back_pressed)
	var window := get_window()
	if window != null and not window.files_dropped.is_connected(_on_files_dropped):
		window.files_dropped.connect(_on_files_dropped)
	training_button.grab_focus()
	options_status_label.visible = false
	character_editor_submenu.visible = false
	team_submenu.visible = false
	if online_submenu != null:
		online_submenu.visible = false
	if single_player_submenu != null:
		single_player_submenu.visible = false
	if editors_submenu != null:
		editors_submenu.visible = false
	if import_submenu != null:
		import_submenu.visible = false
	if local_multiplayer_submenu != null:
		local_multiplayer_submenu.visible = false
	if watch_submenu != null:
		watch_submenu.visible = false
	import_summary_panel.visible = false
	_build_team_mode_options()
	_setup_main_ring_menu()
	_set_legacy_main_buttons_visible(false)


func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	# Ring navigation is the primary top-level navigation mode.
	if not team_submenu.visible and not character_editor_submenu.visible and (online_submenu == null or not online_submenu.visible) and (single_player_submenu == null or not single_player_submenu.visible) and (editors_submenu == null or not editors_submenu.visible) and (import_submenu == null or not import_submenu.visible) and (local_multiplayer_submenu == null or not local_multiplayer_submenu.visible) and (watch_submenu == null or not watch_submenu.visible) and main_ring_menu != null:
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
		if online_submenu != null and online_submenu.visible:
			viewport.set_input_as_handled()
			_on_online_back_pressed()
			return
		if single_player_submenu != null and single_player_submenu.visible:
			viewport.set_input_as_handled()
			_on_single_player_back_pressed()
			return
		if watch_submenu != null and watch_submenu.visible:
			viewport.set_input_as_handled()
			_on_watch_submenu_back_pressed()
			return
		if editors_submenu != null and editors_submenu.visible:
			viewport.set_input_as_handled()
			_on_editors_back_pressed()
			return
		if import_submenu != null and import_submenu.visible:
			viewport.set_input_as_handled()
			_on_import_back_pressed()
			return
		if local_multiplayer_submenu != null and local_multiplayer_submenu.visible:
			viewport.set_input_as_handled()
			_on_local_multiplayer_back_pressed()
			return
		if character_editor_submenu.visible:
			viewport.set_input_as_handled()
			SystemSFX.play_ui_from(self, "ui_back")
			character_editor_submenu.visible = false
			if main_ring_menu != null:
				main_ring_menu.visible = not team_submenu.visible and (online_submenu == null or not online_submenu.visible) and (single_player_submenu == null or not single_player_submenu.visible) and (editors_submenu == null or not editors_submenu.visible) and (import_submenu == null or not import_submenu.visible) and (local_multiplayer_submenu == null or not local_multiplayer_submenu.visible) and (watch_submenu == null or not watch_submenu.visible)
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
		{"id": "single_player", "label": "Single Player"},
		{"id": "online", "label": "Online"},
		{"id": "local_multiplayer", "label": "Local Multiplayer"},
		{"id": "replays", "label": "Replays"},
		{"id": "model_viewer", "label": "Model Viewer"},
		{"id": "editors", "label": "Editors"},
		{"id": "import", "label": "Import"},
		{"id": "options", "label": "Options"},
		{"id": "quit", "label": "Quit Game"}
	]


func _activate_main_ring_selection(index: int) -> void:
	if index < 0 or index >= main_ring_items.size():
		return
	var item: Dictionary = main_ring_items[index]
	match str(item.get("id", "")):
		"single_player":
			_on_single_player_pressed()
		"online":
			_on_online_pressed()
		"local_multiplayer":
			_on_local_multiplayer_pressed()
		"replays":
			_on_replays_pressed()
		"model_viewer":
			_on_model_viewer_pressed()
		"editors":
			_on_editors_pressed()
		"import":
			_on_import_pressed()
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
	if online_submenu != null and online_submenu.visible:
		_append_focus_if_visible(out, online_host_button)
		_append_focus_if_visible(out, online_join_button)
		_append_focus_if_visible(out, online_back_button)
	if single_player_submenu != null and single_player_submenu.visible:
		_append_focus_if_visible(out, single_player_training_button)
		_append_focus_if_visible(out, single_player_arcade_button)
		_append_focus_if_visible(out, single_player_survival_button)
		_append_focus_if_visible(out, single_player_watch_button)
		_append_focus_if_visible(out, single_player_cpu_training_vs_p2_button)
		_append_focus_if_visible(out, single_player_cpu_training_vs_cpu_button)
		_append_focus_if_visible(out, single_player_back_button)
	if watch_submenu != null and watch_submenu.visible:
		_append_focus_if_visible(out, watch_versus_button)
		_append_focus_if_visible(out, watch_smash_button)
		_append_focus_if_visible(out, watch_tag_button)
		_append_focus_if_visible(out, watch_submenu_back_button)
	if editors_submenu != null and editors_submenu.visible:
		_append_focus_if_visible(out, editors_box_button)
		_append_focus_if_visible(out, editors_json_button)
		_append_focus_if_visible(out, editors_commands_button)
		_append_focus_if_visible(out, editors_preview_button)
		_append_focus_if_visible(out, editors_stage_button)
		_append_focus_if_visible(out, editors_back_button)
	if import_submenu != null and import_submenu.visible:
		_append_focus_if_visible(out, import_submenu_open_mods_button)
		_append_focus_if_visible(out, import_submenu_open_stages_button)
		_append_focus_if_visible(out, import_submenu_character_button)
		_append_focus_if_visible(out, import_submenu_stage_button)
		_append_focus_if_visible(out, import_submenu_back_button)
	if local_multiplayer_submenu != null and local_multiplayer_submenu.visible:
		_append_focus_if_visible(out, local_multiplayer_versus_button)
		_append_focus_if_visible(out, local_multiplayer_smash_button)
		_append_focus_if_visible(out, local_multiplayer_team_button)
		_append_focus_if_visible(out, local_multiplayer_coop_button)
		_append_focus_if_visible(out, local_multiplayer_tournament_button)
		_append_focus_if_visible(out, local_multiplayer_back_button)
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
	_append_focus_if_visible(out, import_character_button)
	_append_focus_if_visible(out, import_stage_button)
	if import_summary_panel.visible:
		_append_focus_if_visible(out, import_open_character_button)
		_append_focus_if_visible(out, import_open_stage_button)
		_append_focus_if_visible(out, import_summary_close_button)
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


func _on_single_player_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	if single_player_submenu != null:
		single_player_submenu.visible = true
	if main_ring_menu != null:
		main_ring_menu.visible = false


func _on_single_player_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	if single_player_submenu != null:
		single_player_submenu.visible = false
	if main_ring_menu != null:
		main_ring_menu.visible = not team_submenu.visible and not character_editor_submenu.visible and (online_submenu == null or not online_submenu.visible) and (editors_submenu == null or not editors_submenu.visible) and (import_submenu == null or not import_submenu.visible) and (local_multiplayer_submenu == null or not local_multiplayer_submenu.visible) and (watch_submenu == null or not watch_submenu.visible)


func _on_training_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "training")
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_cpu_training_vs_p2_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "cpu_training")
	get_tree().set_meta("cpu_training_opponent", "player")
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_cpu_training_vs_cpu_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "cpu_training")
	get_tree().set_meta("cpu_training_opponent", "cpu")
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_arcade_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "arcade")
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_local_multiplayer_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	if local_multiplayer_submenu != null:
		local_multiplayer_submenu.visible = true
	if main_ring_menu != null:
		main_ring_menu.visible = false


func _on_local_multiplayer_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	if local_multiplayer_submenu != null:
		local_multiplayer_submenu.visible = false
	if main_ring_menu != null:
		main_ring_menu.visible = not team_submenu.visible and not character_editor_submenu.visible and (online_submenu == null or not online_submenu.visible) and (single_player_submenu == null or not single_player_submenu.visible) and (editors_submenu == null or not editors_submenu.visible) and (import_submenu == null or not import_submenu.visible) and (local_multiplayer_submenu == null or not local_multiplayer_submenu.visible) and (watch_submenu == null or not watch_submenu.visible)


func _on_local_team_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	if local_multiplayer_submenu != null:
		local_multiplayer_submenu.visible = false
	if team_submenu != null:
		team_submenu.visible = true
	if main_ring_menu != null:
		main_ring_menu.visible = false


func _on_versus_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "versus")
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_online_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	if online_submenu != null:
		online_submenu.visible = true
	if main_ring_menu != null:
		main_ring_menu.visible = false


func _on_online_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	if online_submenu != null:
		online_submenu.visible = false
	if main_ring_menu != null:
		main_ring_menu.visible = not character_editor_submenu.visible and (single_player_submenu == null or not single_player_submenu.visible) and (editors_submenu == null or not editors_submenu.visible) and (import_submenu == null or not import_submenu.visible) and (local_multiplayer_submenu == null or not local_multiplayer_submenu.visible) and (watch_submenu == null or not watch_submenu.visible)


func _on_online_host_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	var err: Error = NetworkManager.host(49152)
	if err != OK:
		options_status_label.visible = true
		options_status_label.text = "Failed to host (port 49152 may be in use)."
		return
	get_tree().set_meta("game_mode", "online")
	get_tree().set_meta("online_host", true)
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_online_join_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_show_join_ip_dialog()


func _show_join_ip_dialog() -> void:
	var win: Window = Window.new()
	win.title = "Join Game"
	win.size = Vector2i(320, 120)
	win.unresizable = true
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_child(vbox)
	win.add_child(margin)
	var label: Label = Label.new()
	label.text = "Host IP address:"
	vbox.add_child(label)
	var line_edit: LineEdit = LineEdit.new()
	line_edit.placeholder_text = "127.0.0.1"
	line_edit.text = "127.0.0.1"
	line_edit.custom_minimum_size.x = 200
	vbox.add_child(line_edit)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var cancel_btn: Button = Button.new()
	cancel_btn.text = "Cancel"
	var connect_btn: Button = Button.new()
	connect_btn.text = "Connect"
	row.add_child(cancel_btn)
	row.add_child(connect_btn)
	vbox.add_child(row)
	cancel_btn.pressed.connect(func():
		win.queue_free()
	)
	connect_btn.pressed.connect(func():
		var ip: String = line_edit.text.strip_edges()
		if ip.is_empty():
			ip = "127.0.0.1"
		var err: Error = NetworkManager.join(ip, 49152)
		win.queue_free()
		if err != OK:
			options_status_label.visible = true
			options_status_label.text = "Failed to connect to %s" % ip
			return
		_clear_team_mode_meta()
		get_tree().set_meta("game_mode", "online")
		get_tree().set_meta("online_host", false)
		get_tree().change_scene_to_file(match_options_scene_path)
	)
	get_tree().root.add_child(win)
	win.popup_centered()
	line_edit.grab_focus()


func _on_smash_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "smash")
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_coop_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	if local_multiplayer_submenu != null:
		local_multiplayer_submenu.visible = false
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "coop")
	get_tree().set_meta("team_mode_subtype", "simul")
	get_tree().set_meta("team_size_p1", 2)
	get_tree().set_meta("team_size_p2", 1)
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_tournament_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	if local_multiplayer_submenu != null:
		local_multiplayer_submenu.visible = false
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "tournament")
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_team_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	team_submenu.visible = not team_submenu.visible
	if main_ring_menu != null:
		main_ring_menu.visible = not team_submenu.visible and not character_editor_submenu.visible and (online_submenu == null or not online_submenu.visible) and (single_player_submenu == null or not single_player_submenu.visible) and (editors_submenu == null or not editors_submenu.visible) and (import_submenu == null or not import_submenu.visible) and (local_multiplayer_submenu == null or not local_multiplayer_submenu.visible) and (watch_submenu == null or not watch_submenu.visible)


func _on_team_start_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().set_meta("game_mode", "team")
	get_tree().set_meta("team_mode_subtype", _selected_team_subtype())
	get_tree().set_meta("team_size_p1", _selected_team_size(team_p1_size_option))
	get_tree().set_meta("team_size_p2", _selected_team_size(team_p2_size_option))
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_team_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	team_submenu.visible = false
	if main_ring_menu != null:
		main_ring_menu.visible = not character_editor_submenu.visible and (online_submenu == null or not online_submenu.visible) and (single_player_submenu == null or not single_player_submenu.visible) and (editors_submenu == null or not editors_submenu.visible) and (import_submenu == null or not import_submenu.visible) and (local_multiplayer_submenu == null or not local_multiplayer_submenu.visible) and (watch_submenu == null or not watch_submenu.visible)


func _on_survival_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "survival")
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_watch_mode_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	if single_player_submenu != null:
		single_player_submenu.visible = false
	if watch_submenu != null:
		watch_submenu.visible = true
	if main_ring_menu != null:
		main_ring_menu.visible = false


func _on_watch_versus_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "watch")
	get_tree().set_meta("watch_match_type", "versus")
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_watch_smash_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	_clear_team_mode_meta()
	get_tree().set_meta("game_mode", "watch")
	get_tree().set_meta("watch_match_type", "smash")
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_watch_tag_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().set_meta("game_mode", "watch")
	get_tree().set_meta("watch_match_type", "team")
	get_tree().set_meta("team_mode_subtype", "tag")
	get_tree().set_meta("team_size_p1", 2)
	get_tree().set_meta("team_size_p2", 2)
	get_tree().change_scene_to_file(match_options_scene_path)


func _on_watch_submenu_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	if watch_submenu != null:
		watch_submenu.visible = false
	if main_ring_menu != null:
		main_ring_menu.visible = not team_submenu.visible and not character_editor_submenu.visible and (online_submenu == null or not online_submenu.visible) and (single_player_submenu == null or not single_player_submenu.visible) and (editors_submenu == null or not editors_submenu.visible) and (import_submenu == null or not import_submenu.visible) and (local_multiplayer_submenu == null or not local_multiplayer_submenu.visible) and (watch_submenu == null or not watch_submenu.visible)


func _on_replays_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().change_scene_to_file(replay_select_path)


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
		main_ring_menu.visible = not character_editor_submenu.visible and not team_submenu.visible and (import_submenu == null or not import_submenu.visible) and (local_multiplayer_submenu == null or not local_multiplayer_submenu.visible) and (watch_submenu == null or not watch_submenu.visible)


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
	import_character_button.visible = visible_value
	import_stage_button.visible = visible_value
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


func _on_editors_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	if editors_submenu != null:
		editors_submenu.visible = true
	if main_ring_menu != null:
		main_ring_menu.visible = false


func _on_editors_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	if editors_submenu != null:
		editors_submenu.visible = false
	if main_ring_menu != null:
		main_ring_menu.visible = not team_submenu.visible and not character_editor_submenu.visible and (online_submenu == null or not online_submenu.visible) and (single_player_submenu == null or not single_player_submenu.visible) and (import_submenu == null or not import_submenu.visible) and (editors_submenu == null or not editors_submenu.visible) and (local_multiplayer_submenu == null or not local_multiplayer_submenu.visible) and (watch_submenu == null or not watch_submenu.visible)


func _on_stage_editor_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().change_scene_to_file(stage_editor_scene_path)


func _on_import_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	if import_submenu != null:
		import_submenu.visible = true
	if main_ring_menu != null:
		main_ring_menu.visible = false


func _on_import_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	if import_submenu != null:
		import_submenu.visible = false
	if main_ring_menu != null:
		main_ring_menu.visible = not team_submenu.visible and not character_editor_submenu.visible and (online_submenu == null or not online_submenu.visible) and (single_player_submenu == null or not single_player_submenu.visible) and (editors_submenu == null or not editors_submenu.visible) and (import_submenu == null or not import_submenu.visible) and (local_multiplayer_submenu == null or not local_multiplayer_submenu.visible) and (watch_submenu == null or not watch_submenu.visible)


func _on_open_mods_folder_pressed() -> void:
	_open_user_content_folder("user://mods/")


func _on_open_stages_folder_pressed() -> void:
	_open_user_content_folder("user://stages/")


func _on_import_character_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	import_character_dialog.popup_centered_ratio(0.7)


func _on_import_stage_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	import_stage_dialog.popup_centered_ratio(0.7)


func _on_import_character_path_selected(path: String) -> void:
	_handle_import_report(CONTENT_IMPORT_SERVICE.import_character_source(path))


func _on_import_stage_path_selected(path: String) -> void:
	_handle_import_report(CONTENT_IMPORT_SERVICE.import_stage_source(path))


func _on_files_dropped(files: PackedStringArray) -> void:
	if files.is_empty():
		return
	if files.size() > 1:
		options_status_label.visible = true
		options_status_label.text = "Drop one file or folder at a time."
		return
	var path: String = str(files[0])
	if _looks_like_stage_source(path):
		_handle_import_report(CONTENT_IMPORT_SERVICE.import_stage_source(path))
		return
	_handle_import_report(CONTENT_IMPORT_SERVICE.import_character_source(path))


func _looks_like_stage_source(path: String) -> bool:
	var abs_path: String = path
	if path.begins_with("res://") or path.begins_with("user://"):
		abs_path = ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(abs_path):
		if FileAccess.file_exists("%s/stage.def" % path) or FileAccess.file_exists("%s\\stage.def" % abs_path):
			return true
		var lowered_dir: String = abs_path.to_lower()
		return lowered_dir.find("stage") >= 0 or lowered_dir.find("arena") >= 0 or lowered_dir.find("map") >= 0
	var lowered: String = abs_path.to_lower()
	return lowered.find("stage") >= 0 or lowered.find("arena") >= 0 or lowered.find("map") >= 0


func _handle_import_report(report: Dictionary) -> void:
	last_import_report = report.duplicate(true)
	_show_import_summary(last_import_report)
	options_status_label.visible = true
	options_status_label.text = str(report.get("summary", "Import finished."))


func _show_import_summary(report: Dictionary) -> void:
	import_summary_panel.visible = true
	var lines: PackedStringArray = []
	var ok: bool = bool(report.get("ok", false))
	lines.append("[b]%s[/b]" % ("Import Complete" if ok else "Import Needs Attention"))
	lines.append("Type: %s" % str(report.get("kind", "content")).capitalize())
	lines.append("Name: %s" % str(report.get("content_name", "")))
	lines.append("Target: %s" % str(report.get("target_path", "")))
	var generated_files: Array = report.get("generated_files", [])
	if not generated_files.is_empty():
		lines.append("Generated: %s" % ", ".join(generated_files))
	var warnings: Array = report.get("warnings", [])
	if not warnings.is_empty():
		lines.append("Warnings:")
		for warning in warnings:
			lines.append("- %s" % str(warning))
	import_summary_label.text = "\n".join(lines)
	var kind: String = str(report.get("kind", ""))
	import_open_character_button.visible = ok and kind == "character"
	import_open_stage_button.visible = ok and kind == "stage"


func _on_open_imported_character_editor_pressed() -> void:
	var mod_name: String = str(last_import_report.get("content_name", "")).strip_edges()
	if mod_name.is_empty():
		return
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().set_meta("character_editor_mod_name", mod_name)
	get_tree().set_meta("character_editor_section", "states")
	get_tree().change_scene_to_file(box_editor_scene_path)


func _on_open_imported_stage_editor_pressed() -> void:
	var stage_name: String = str(last_import_report.get("content_name", "")).strip_edges()
	if stage_name.is_empty():
		return
	SystemSFX.play_ui_from(self, "ui_confirm")
	get_tree().set_meta("stage_editor_stage_name", stage_name)
	get_tree().change_scene_to_file(stage_editor_scene_path)


func _on_close_import_summary_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	import_summary_panel.visible = false


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
