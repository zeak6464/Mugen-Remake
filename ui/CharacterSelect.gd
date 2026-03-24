extends Node3D

@export var mods_roots: Array[String] = ["user://mods/", "res://mods/"]
@export var stage_select_scene_path: String = "res://ui/StageSelect.tscn"
@export var preview_model_y_rotation_degrees: float = 0.0
@export var auto_fit_preview_models: bool = false

var preview_spawn_point_p1: Marker3D = null
var preview_spawn_point_p2: Marker3D = null
var instruction_label: Label = null
var mode_label: Label = null
var status_label: Label = null

var p1_team_slots: Control = null
var p1_cursor_label: Label = null
var p1_roster_row: Control = null
var p1_roster_scroll: Control = null
var p1_folder_roster_row: HBoxContainer = null
var p1_roster_cursor_marker: Control = null
var p1_panel: Panel = null

var p2_ui: Control = null
var p2_team_slots: Control = null
var p2_cursor_label: Label = null
var p2_roster_row: Control = null
var p2_roster_scroll: Control = null
var p2_folder_roster_row: HBoxContainer = null
var p2_roster_cursor_marker: Control = null
var p2_panel: Panel = null

var p1_folder_panel: Panel = null
var p1_folder_summary_rich: RichTextLabel = null
var p1_folder_hints_rich: RichTextLabel = null
var p1_variant_row: Control = null
var p2_folder_panel: Panel = null
var p2_folder_summary_rich: RichTextLabel = null
var p2_folder_hints_rich: RichTextLabel = null
var p2_variant_row: Control = null
var p1_preview_texture: TextureRect = null
var p2_preview_texture: TextureRect = null

var lock_overlay: ColorRect = null
var lock_overlay_label: Label = null

var available_mods: Array[Dictionary] = []
var p1_roster_buttons: Array[Button] = []
var p2_roster_buttons: Array[Button] = []
var p1_variant_buttons: Array[Button] = []
var p2_variant_buttons: Array[Button] = []
var p1_preview_viewport: SubViewport = null
var p2_preview_viewport: SubViewport = null
var p1_preview_stage: Node3D = null
var p2_preview_stage: Node3D = null
var p1_preview_model: Node3D = null
var p2_preview_model: Node3D = null
var preview_camera_p1_source: Camera3D = null
var preview_camera_p2_source: Camera3D = null
var preview_key_light_p1_source: DirectionalLight3D = null
var preview_key_light_p2_source: DirectionalLight3D = null
var preview_fill_light_p1_source: OmniLight3D = null
var preview_fill_light_p2_source: OmniLight3D = null
var _preview_shader_loader: ModLoader = null
## Avoids clearing/rebuilding 3D preview when selection (mod/form/costume) is unchanged.
var _preview_p1_key: String = ""
var _preview_p2_key: String = ""

const ROSTER_PAGE_SIZE: int = 8
const ROSTER_ICON_BUTTON_SIZE := Vector2(92, 52)
const ROSTER_TEXT_BUTTON_SIZE := Vector2(124, 54)
const FOLDER_STAGE_FORM: int = 0
const FOLDER_STAGE_COSTUME: int = 1

var game_mode: String = "training"
var watch_match_type: String = ""
var team_mode_subtype: String = "simul"
var team_size_p1: int = 2
var team_size_p2: int = 2

var active_player: int = 1
var p1_cursor_index: int = 0
var p2_cursor_index: int = 0
var p1_page_index: int = 0
var p2_page_index: int = 0

var p1_locked: bool = false
var p2_locked: bool = false
var p1_selected_mod: String = ""
var p2_selected_mod: String = ""
## Short label for HUD/roster when mod path is a unique load key (e.g. duplicate folder names).
var p1_selected_display: String = ""
var p2_selected_display: String = ""
var p1_selected_form: String = ""
var p2_selected_form: String = ""
var p1_selected_costume: String = ""
var p2_selected_costume: String = ""

var p1_team_roster: Array[Dictionary] = []
var p2_team_roster: Array[Dictionary] = []

var folder_open: bool = false
var folder_player: int = 1
var folder_mod_index: int = -1
var folder_variant_index: int = 0 # 0 = Base, 1.. = forms
var folder_costume_index: int = 0 # 0 = Default, 1.. = costumes_data keys
var folder_stage: int = FOLDER_STAGE_FORM

func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	_bind_ui_nodes()
	_setup_preview_viewports()
	call_deferred("_sync_preview_viewport_sizes")
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_sync_preview_viewport_sizes):
		vp.size_changed.connect(_sync_preview_viewport_sizes)
	SystemSFX.play_menu_music_from(self, "charactersel", true, -8.0)
	_resolve_mode()
	_load_mod_entries()
	if p2_ui != null:
		p2_ui.visible = _uses_dual_player()
	_build_roster_rows()
	_refresh_ui()


func _unhandled_input(event: InputEvent) -> void:
	if available_mods.is_empty():
		return
	if _pressed(event, &"ui_cancel") or _pressed(event, &"p1_k") or _pressed(event, &"p2_k"):
		_handle_cancel()
		return

	var control_player: int = _control_player_for_input(event)
	if control_player == 0:
		return

	if _pressed(event, &"p1_up") or _pressed(event, &"p2_up"):
		_move_page(control_player, -1)
		return
	if _pressed(event, &"p1_down") or _pressed(event, &"p2_down"):
		_move_page(control_player, 1)
		return

	if _pressed(event, &"p1_left") or _pressed(event, &"p2_left"):
		_move_cursor(control_player, -1)
		return
	if _pressed(event, &"p1_right") or _pressed(event, &"p2_right"):
		_move_cursor(control_player, 1)
		return
	if _pressed(event, &"p1_h") or _pressed(event, &"p2_h"):
		_move_variant(-1)
		return
	if _pressed(event, &"p1_s") or _pressed(event, &"p2_s"):
		_move_variant(1)
		return
	if _pressed(event, &"p1_p") or _pressed(event, &"p2_p"):
		_confirm_player(control_player)
		return


func _pressed(event: InputEvent, action: StringName) -> bool:
	if not InputMap.has_action(action):
		return false
	if not event.is_action_pressed(action):
		return false
	if event is InputEventKey and (event as InputEventKey).echo:
		return false
	return true


func _tree_meta_bool(key: StringName, default_value: bool = false) -> bool:
	if not is_inside_tree():
		return default_value
	var tree := get_tree()
	if tree == null:
		return default_value
	return bool(tree.get_meta(key, default_value))


func _tree_meta_str(key: StringName, default_value: String = "") -> String:
	if not is_inside_tree():
		return default_value
	var tree := get_tree()
	if tree == null:
		return default_value
	return str(tree.get_meta(key, default_value))


func _control_player_for_input(event: InputEvent) -> int:
	if game_mode == "watch" or _cpu_training_smash_cpu_single_draft():
		# Watch: one controller drafts both CPU sides.
		# CPU Training (Smash) vs CPU: same — P1 keys alone can pick P1 then CPU after P1 locks.
		if _pressed(event, &"p1_up") or _pressed(event, &"p1_down") or _pressed(event, &"p1_left") or _pressed(event, &"p1_right") or _pressed(event, &"p1_p") or _pressed(event, &"p1_k") or _pressed(event, &"p1_s") or _pressed(event, &"p1_h"):
			return active_player
		if _pressed(event, &"p2_up") or _pressed(event, &"p2_down") or _pressed(event, &"p2_left") or _pressed(event, &"p2_right") or _pressed(event, &"p2_p") or _pressed(event, &"p2_k") or _pressed(event, &"p2_s") or _pressed(event, &"p2_h"):
			return active_player
		return 0
	# Training (Smash): before P1 locks, P1/P2 keys control their sides; after P1 locks, both key sets drive P2 so one keyboard can finish.
	if _training_smash_p2_pick_in_progress():
		if _pressed(event, &"p1_up") or _pressed(event, &"p1_down") or _pressed(event, &"p1_left") or _pressed(event, &"p1_right") or _pressed(event, &"p1_p") or _pressed(event, &"p1_k") or _pressed(event, &"p1_s") or _pressed(event, &"p1_h"):
			return 2
		if _pressed(event, &"p2_up") or _pressed(event, &"p2_down") or _pressed(event, &"p2_left") or _pressed(event, &"p2_right") or _pressed(event, &"p2_p") or _pressed(event, &"p2_k") or _pressed(event, &"p2_s") or _pressed(event, &"p2_h"):
			return 2
		return 0
	if _pressed(event, &"p2_up") or _pressed(event, &"p2_down") or _pressed(event, &"p2_left") or _pressed(event, &"p2_right") or _pressed(event, &"p2_p") or _pressed(event, &"p2_k") or _pressed(event, &"p2_s") or _pressed(event, &"p2_h"):
		return 2
	if _pressed(event, &"p1_up") or _pressed(event, &"p1_down") or _pressed(event, &"p1_left") or _pressed(event, &"p1_right") or _pressed(event, &"p1_p") or _pressed(event, &"p1_k") or _pressed(event, &"p1_s") or _pressed(event, &"p1_h"):
		return 1
	return 0


func _resolve_mode() -> void:
	game_mode = str(get_tree().get_meta("game_mode", "training")).to_lower()
	if (
		game_mode != "arcade"
		and game_mode != "versus"
		and game_mode != "smash"
		and game_mode != "team"
		and game_mode != "survival"
		and game_mode != "watch"
		and game_mode != "online"
		and game_mode != "coop"
		and game_mode != "tournament"
		and game_mode != "cpu_training"
	):
		game_mode = "training"
	var training_smash: bool = bool(get_tree().get_meta("training_smash_rules", false))
	watch_match_type = str(get_tree().get_meta("watch_match_type", "")).to_lower() if game_mode == "watch" else ""
	team_mode_subtype = str(get_tree().get_meta("team_mode_subtype", "simul")).to_lower()
	if team_mode_subtype != "simul" and team_mode_subtype != "turns" and team_mode_subtype != "tag":
		team_mode_subtype = "simul"
	team_size_p1 = clampi(int(get_tree().get_meta("team_size_p1", 2)), 2, 4)
	team_size_p2 = clampi(int(get_tree().get_meta("team_size_p2", 2)), 2, 4)

	match game_mode:
		"arcade":
			_set_label_text(instruction_label, "Arcade Mode - P1 Draft")
			_set_label_text(mode_label, "ARCADE")
		"survival":
			_set_label_text(instruction_label, "Survival Mode - P1 Draft")
			_set_label_text(mode_label, "SURVIVAL")
		"versus":
			_set_label_text(instruction_label, "2P Versus - Draft both teams")
			_set_label_text(mode_label, "VERSUS")
		"team":
			_set_label_text(instruction_label, "Team %s - Draft both rosters" % team_mode_subtype.capitalize())
			_set_label_text(mode_label, "TEAM %s" % team_mode_subtype.to_upper())
		"smash":
			_set_label_text(instruction_label, "Smash Mode - Draft both teams")
			_set_label_text(mode_label, "SMASH")
		"watch":
			if watch_match_type == "team":
				_set_label_text(instruction_label, "Watch: Tag - P1 drafts both CPU rosters")
			else:
				_set_label_text(instruction_label, "Watch Mode - P1 drafts both CPU teams")
			_set_label_text(mode_label, "WATCH")
		"coop":
			_set_label_text(instruction_label, "Co-op vs CPU - P1 and P2 pick your team, then continue")
			_set_label_text(mode_label, "CO-OP")
		"tournament":
			var n: int = clampi(int(get_tree().get_meta("tournament_size", 4)), 4, 16)
			_set_label_text(instruction_label, "Tournament - Press Attack(P) to draw %d random CPU fighters" % n)
			_set_label_text(mode_label, "TOURNAMENT")
		"online":
			_set_label_text(instruction_label, "Online - Pick your character")
			_set_label_text(mode_label, "ONLINE")
		"cpu_training":
			if training_smash:
				if str(get_tree().get_meta("cpu_training_opponent", "player")).to_lower() == "cpu":
					_set_label_text(
						instruction_label,
						"CPU Training (Smash) — Lock P1 first, then use the same keys to pick the CPU’s fighter (P2 column)."
					)
				else:
					_set_label_text(instruction_label, "CPU Training (Smash) — Draft both fighters")
				_set_label_text(mode_label, "CPU TRAINING · SMASH")
			else:
				_set_label_text(instruction_label, "CPU Training Mode — P1 Draft")
				_set_label_text(mode_label, "CPU TRAINING")
		_:
			if training_smash:
				_set_label_text(
					instruction_label,
					"Training (Smash) — Lock P1 first, then use the same keys to pick P2 (or use P2 keys)."
				)
				_set_label_text(mode_label, "TRAINING · SMASH")
			else:
				_set_label_text(instruction_label, "Training Mode - P1 Draft")
				_set_label_text(mode_label, "TRAINING")


func _uses_dual_player() -> bool:
	if _tree_meta_bool(&"training_smash_rules", false):
		if game_mode == "training":
			return true
		if game_mode == "cpu_training":
			return true
	return (
		game_mode == "versus"
		or game_mode == "smash"
		or game_mode == "team"
		or game_mode == "watch"
		or game_mode == "online"
		or game_mode == "coop"
	)


## CPU Training (Smash) vs CPU: one person picks both fighters; P1/P2 keys follow active_player like Watch mode.
func _cpu_training_smash_cpu_single_draft() -> bool:
	return (
		game_mode == "cpu_training"
		and _tree_meta_bool(&"training_smash_rules", false)
		and _tree_meta_str(&"cpu_training_opponent", "player").to_lower() == "cpu"
	)


func _training_smash_p2_pick_in_progress() -> bool:
	return (
		game_mode == "training"
		and _tree_meta_bool(&"training_smash_rules", false)
		and p1_locked
		and not p2_locked
	)


func _training_smash_active_player_sync_eligible() -> bool:
	return game_mode == "training" and _tree_meta_bool(&"training_smash_rules", false)


func _is_team_roster_mode() -> bool:
	return game_mode == "team" or game_mode == "coop" or (game_mode == "watch" and watch_match_type == "team")


func _load_mod_entries() -> void:
	available_mods.clear()
	for content_entry in ContentResolver.scan_character_entries(mods_roots, "playable"):
		var mod_path: String = str(content_entry.get("path", ""))
		var forms_data: Dictionary = _load_mod_forms_data(mod_path)
		var forms: Array[String] = []
		for form_key in forms_data.keys():
			forms.append(str(form_key))
		forms.sort()
		available_mods.append(
			{
				"name": str(content_entry.get("name", "")),
				"path": mod_path,
				"display_name": str(content_entry.get("display_name", content_entry.get("name", ""))),
				"forms": forms,
				"forms_data": forms_data,
				"costumes_data": _load_mod_costumes_data(mod_path),
				"icon_texture": _load_mod_icon_texture(mod_path),
				"model_path": str(content_entry.get("model_path", "")),
				"def_data": content_entry.get("def_data", {})
			}
		)
	available_mods.sort_custom(
		func(a, b): return str(a.get("display_name", a.get("name", ""))) < str(b.get("display_name", b.get("name", "")))
	)


func _build_roster_rows() -> void:
	if p1_roster_row == null or p2_roster_row == null:
		push_warning("CharacterSelect: roster rows are missing. UI can still load, but roster buttons cannot be built.")
		return
	for child in p1_roster_row.get_children():
		child.queue_free()
	for child in p2_roster_row.get_children():
		child.queue_free()
	p1_roster_buttons.clear()
	p2_roster_buttons.clear()

	for idx in range(available_mods.size()):
		var mod_entry: Dictionary = available_mods[idx]
		var b1 := _create_roster_button(mod_entry, 1, idx)
		p1_roster_row.add_child(b1)
		p1_roster_buttons.append(b1)
		var b2 := _create_roster_button(mod_entry, 2, idx)
		p2_roster_row.add_child(b2)
		p2_roster_buttons.append(b2)


func _ensure_roster_folder_rows() -> void:
	p1_folder_roster_row = _create_roster_folder_row(p1_roster_scroll, "FolderRosterRowP1")
	p2_folder_roster_row = _create_roster_folder_row(p2_roster_scroll, "FolderRosterRowP2")


func _create_roster_folder_row(scroll: Control, node_name: String) -> HBoxContainer:
	if scroll == null:
		return null
	var existing := scroll.get_node_or_null(node_name) as HBoxContainer
	if existing != null:
		return existing
	var row := HBoxContainer.new()
	row.name = node_name
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.anchor_left = 0.0
	row.anchor_top = 0.0
	row.anchor_right = 1.0
	row.anchor_bottom = 1.0
	row.offset_left = 0.0
	row.offset_top = 0.0
	row.offset_right = 0.0
	row.offset_bottom = 0.0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.visible = false
	scroll.add_child(row)
	return row


func _create_roster_button(mod_entry: Dictionary, player_id: int, index: int) -> Button:
	var button := Button.new()
	var icon_tex := mod_entry.get("icon_texture", null) as Texture2D
	button.custom_minimum_size = ROSTER_ICON_BUTTON_SIZE if icon_tex != null else ROSTER_TEXT_BUTTON_SIZE
	var full_name: String = str(mod_entry.get("display_name", mod_entry.get("name", "Unknown")))
	button.text = ""
	if icon_tex == null:
		button.text = _short_roster_name(full_name.to_upper(), 11)
	else:
		button.icon = icon_tex
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.flat = false
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.tooltip_text = full_name
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_roster_button_pressed.bind(player_id, index))
	return button


func _on_roster_button_pressed(player_id: int, index: int) -> void:
	if player_id == 2 and not _uses_dual_player():
		return
	if _is_player_locked(player_id):
		return
	_set_cursor(player_id, index)
	_open_folder(player_id, index)
	SystemSFX.play_ui_from(self, "ui_move")
	_refresh_ui()


func _cycle_active_player() -> void:
	if not _uses_dual_player():
		active_player = 1
	elif game_mode == "watch":
		active_player = 1 if not p1_locked else 2
	else:
		active_player = 2 if active_player == 1 else 1
	SystemSFX.play_ui_from(self, "ui_move")
	_refresh_ui()


func _move_cursor(player_id: int, delta: int) -> void:
	if _is_player_locked(player_id):
		return
	if folder_open and folder_player == player_id and folder_mod_index >= 0 and folder_mod_index < available_mods.size():
		var mod_entry: Dictionary = available_mods[folder_mod_index]
		if folder_stage == FOLDER_STAGE_COSTUME:
			var ckeys: Array[String] = _costume_keys_sorted(mod_entry)
			var ctotal: int = ckeys.size() + 1
			if ctotal > 0:
				folder_costume_index = wrapi(folder_costume_index + delta, 0, ctotal)
		else:
			var forms: Array[String] = mod_entry.get("forms", [])
			var total: int = 1 + forms.size()
			folder_variant_index = wrapi(folder_variant_index + delta, 0, total)
		SystemSFX.play_ui_from(self, "ui_move")
		_refresh_ui()
		return
	var count: int = available_mods.size()
	if count <= 0:
		return
	var page_idx: int = _get_page(player_id)
	var page_start: int = page_idx * ROSTER_PAGE_SIZE
	var page_end: int = min(count - 1, page_start + (ROSTER_PAGE_SIZE - 1))
	var current: int = _get_cursor(player_id)
	if current < page_start or current > page_end:
		current = page_start
	var next_idx: int = current + delta
	if next_idx < page_start:
		next_idx = page_end
	elif next_idx > page_end:
		next_idx = page_start
	_set_cursor(player_id, next_idx)
	_close_folder()
	SystemSFX.play_ui_from(self, "ui_move")
	_refresh_ui()


func _move_page(player_id: int, delta: int) -> void:
	if _is_player_locked(player_id):
		return
	var count: int = available_mods.size()
	if count <= 0:
		return
	var max_page: int = maxi(0, int(ceil(float(count) / float(ROSTER_PAGE_SIZE))) - 1)
	var page_idx: int = clampi(_get_page(player_id) + delta, 0, max_page)
	_set_page(player_id, page_idx)
	var page_start: int = page_idx * ROSTER_PAGE_SIZE
	var page_end: int = min(count - 1, page_start + (ROSTER_PAGE_SIZE - 1))
	var current: int = _get_cursor(player_id)
	if current < page_start or current > page_end:
		_set_cursor(player_id, page_start)
	_close_folder()
	SystemSFX.play_ui_from(self, "ui_move")
	_refresh_ui()


func _move_variant(delta: int) -> void:
	if not folder_open:
		return
	var mod_entry: Dictionary = available_mods[folder_mod_index]
	if folder_stage == FOLDER_STAGE_COSTUME and not _costume_keys_sorted(mod_entry).is_empty():
		var ck: Array[String] = _costume_keys_sorted(mod_entry)
		var ctotal: int = ck.size() + 1
		folder_costume_index = wrapi(folder_costume_index + delta, 0, ctotal)
	else:
		var forms: Array[String] = mod_entry.get("forms", [])
		var total: int = 1 + forms.size()
		folder_variant_index = wrapi(folder_variant_index + delta, 0, total)
	SystemSFX.play_ui_from(self, "ui_move")
	_refresh_ui()


func _confirm_player(player_id: int) -> void:
	if player_id == 2 and not _uses_dual_player():
		return
	if game_mode == "tournament":
		_commit_selection()
		return
	if _is_player_locked(player_id):
		if (
			player_id == 1
			and not p2_locked
			and (_training_smash_p2_pick_in_progress() or _cpu_training_smash_cpu_single_draft())
		):
			_confirm_player(2)
			return
		if _all_required_locked():
			_commit_selection()
		return
	var cursor_index: int = _get_cursor(player_id)
	if not folder_open or folder_player != player_id or folder_mod_index != cursor_index:
		_open_folder(player_id, cursor_index)
		SystemSFX.play_ui_from(self, "ui_move")
		_refresh_ui()
		return
	if folder_stage == FOLDER_STAGE_FORM:
		var mod_entry: Dictionary = available_mods[folder_mod_index]
		if _costume_keys_sorted(mod_entry).is_empty():
			_commit_folder_pick(player_id)
			return
		folder_stage = FOLDER_STAGE_COSTUME
		folder_costume_index = 0
		SystemSFX.play_ui_from(self, "ui_move")
		_refresh_ui()
		return
	_commit_folder_pick(player_id)


func _commit_folder_pick(player_id: int) -> void:
	if folder_mod_index < 0 or folder_mod_index >= available_mods.size():
		return
	var mod_entry: Dictionary = available_mods[folder_mod_index]
	var load_key: String = _mod_load_key(mod_entry)
	var mod_disp: String = str(mod_entry.get("display_name", mod_entry.get("name", "")))
	if load_key.is_empty():
		return
	var form_id: String = _folder_selected_form(mod_entry)
	var costume_id: String = _folder_selected_costume(mod_entry)

	if _is_team_roster_mode():
		var roster: Array[Dictionary]
		var size_limit: int
		if game_mode == "coop":
			roster = p1_team_roster
			size_limit = team_size_p1
		else:
			roster = p1_team_roster if player_id == 1 else p2_team_roster
			size_limit = team_size_p1 if player_id == 1 else team_size_p2
		if roster.size() < size_limit:
			roster.append({"mod": load_key, "mod_display": mod_disp, "form": form_id, "costume": costume_id})
		if game_mode == "coop":
			p1_team_roster = roster
			if player_id == 1:
				p1_selected_mod = load_key
				p1_selected_display = mod_disp
				p1_selected_form = form_id
				p1_selected_costume = costume_id
			else:
				p2_selected_mod = load_key
				p2_selected_display = mod_disp
				p2_selected_form = form_id
				p2_selected_costume = costume_id
			p1_locked = p1_team_roster.size() >= 1
			p2_locked = p1_team_roster.size() >= 2
		elif player_id == 1:
			p1_team_roster = roster
			p1_selected_mod = load_key
			p1_selected_display = mod_disp
			p1_selected_form = form_id
			p1_selected_costume = costume_id
			p1_locked = p1_team_roster.size() >= team_size_p1
		else:
			p2_team_roster = roster
			p2_selected_mod = load_key
			p2_selected_display = mod_disp
			p2_selected_form = form_id
			p2_selected_costume = costume_id
			p2_locked = p2_team_roster.size() >= team_size_p2
	else:
		if player_id == 1:
			p1_selected_mod = load_key
			p1_selected_display = mod_disp
			p1_selected_form = form_id
			p1_selected_costume = costume_id
			p1_locked = true
		else:
			p2_selected_mod = load_key
			p2_selected_display = mod_disp
			p2_selected_form = form_id
			p2_selected_costume = costume_id
			p2_locked = true

	_close_folder()
	if (
		(game_mode == "watch" or _cpu_training_smash_cpu_single_draft() or _training_smash_active_player_sync_eligible())
		and not _all_required_locked()
	):
		active_player = 2 if p1_locked else 1
	SystemSFX.play_ui_from(self, "ui_confirm")
	_refresh_ui()


func _handle_cancel() -> void:
	if folder_open:
		if folder_stage == FOLDER_STAGE_COSTUME:
			folder_stage = FOLDER_STAGE_FORM
			folder_costume_index = 0
			SystemSFX.play_ui_from(self, "ui_back")
			_refresh_ui()
			return
		_close_folder()
		SystemSFX.play_ui_from(self, "ui_back")
		_refresh_ui()
		return
	if active_player == 1 and p1_locked:
		p1_locked = false
		if _is_team_roster_mode() and not p1_team_roster.is_empty():
			p1_team_roster.remove_at(p1_team_roster.size() - 1)
		if game_mode == "watch" or _cpu_training_smash_cpu_single_draft() or _training_smash_active_player_sync_eligible():
			active_player = 1
		SystemSFX.play_ui_from(self, "ui_back")
		_refresh_ui()
		return
	if _uses_dual_player() and active_player == 2 and p2_locked:
		p2_locked = false
		if _is_team_roster_mode():
			if game_mode == "coop" and not p1_team_roster.is_empty():
				p1_team_roster.remove_at(p1_team_roster.size() - 1)
			elif not p2_team_roster.is_empty():
				p2_team_roster.remove_at(p2_team_roster.size() - 1)
		if game_mode == "watch" or _cpu_training_smash_cpu_single_draft() or _training_smash_active_player_sync_eligible():
			active_player = 2
		SystemSFX.play_ui_from(self, "ui_back")
		_refresh_ui()
		return
	SystemSFX.play_ui_from(self, "ui_back")
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")


func _open_folder(player_id: int, mod_index: int) -> void:
	folder_open = true
	folder_player = player_id
	folder_mod_index = clampi(mod_index, 0, max(0, available_mods.size() - 1))
	folder_variant_index = 0
	folder_stage = FOLDER_STAGE_FORM
	var me: Dictionary = available_mods[folder_mod_index]
	var me_key: String = _mod_load_key(me)
	var preset_cos: String = ""
	if player_id == 1:
		preset_cos = p1_selected_costume if p1_selected_mod == me_key else ""
	else:
		preset_cos = p2_selected_costume if p2_selected_mod == me_key else ""
	folder_costume_index = _costume_row_index_for_id(me, preset_cos)


func _close_folder() -> void:
	folder_open = false
	folder_mod_index = -1
	folder_variant_index = 0
	folder_costume_index = 0
	folder_stage = FOLDER_STAGE_FORM


func _folder_selected_form(mod_entry: Dictionary) -> String:
	var forms: Array[String] = mod_entry.get("forms", [])
	if folder_variant_index <= 0:
		return ""
	var idx: int = folder_variant_index - 1
	if idx < 0 or idx >= forms.size():
		return ""
	return forms[idx]


func _costume_keys_sorted(mod_entry: Dictionary) -> Array[String]:
	var cd: Dictionary = mod_entry.get("costumes_data", {})
	if typeof(cd) != TYPE_DICTIONARY:
		return []
	var keys: Array[String] = []
	for k in cd.keys():
		keys.append(str(k))
	keys.sort()
	return keys


func _folder_selected_costume(mod_entry: Dictionary) -> String:
	if folder_stage != FOLDER_STAGE_COSTUME:
		return ""
	var keys: Array[String] = _costume_keys_sorted(mod_entry)
	if folder_costume_index <= 0:
		return ""
	var idx: int = folder_costume_index - 1
	if idx < 0 or idx >= keys.size():
		return ""
	return keys[idx]


func _costume_row_index_for_id(mod_entry: Dictionary, costume_id: String) -> int:
	if costume_id.is_empty():
		return 0
	var keys: Array[String] = _costume_keys_sorted(mod_entry)
	var idx: int = keys.find(costume_id)
	return 0 if idx < 0 else idx + 1


func _get_cursor(player_id: int) -> int:
	return p1_cursor_index if player_id == 1 else p2_cursor_index


func _set_cursor(player_id: int, value: int) -> void:
	var clamped_value: int = value
	if not available_mods.is_empty():
		clamped_value = clampi(value, 0, available_mods.size() - 1)
	if player_id == 1:
		p1_cursor_index = clamped_value
		p1_page_index = clamped_value / ROSTER_PAGE_SIZE
	else:
		p2_cursor_index = clamped_value
		p2_page_index = clamped_value / ROSTER_PAGE_SIZE


func _get_page(player_id: int) -> int:
	return p1_page_index if player_id == 1 else p2_page_index


func _set_page(player_id: int, value: int) -> void:
	if player_id == 1:
		p1_page_index = value
	else:
		p2_page_index = value


func _is_player_locked(player_id: int) -> bool:
	return p1_locked if player_id == 1 else p2_locked


func _all_required_locked() -> bool:
	if game_mode == "online":
		if bool(get_tree().get_meta("online_host", false)):
			return p1_locked
		return p2_locked
	if _is_team_roster_mode():
		return p1_locked and p2_locked
	if _uses_dual_player():
		return p1_locked and p2_locked
	return p1_locked


func _refresh_ui() -> void:
	_refresh_roster_markers()
	_refresh_roster_folder_rows()
	_refresh_team_slots(p1_team_slots, p1_team_roster, team_size_p1, "P1")
	_refresh_team_slots(p2_team_slots, p2_team_roster, team_size_p2, "P2")

	var p1_prefix: String = ">> " if active_player == 1 else ""
	var p2_prefix: String = ">> " if active_player == 2 and _uses_dual_player() else ""
	var p1_pages_total: int = _roster_total_pages()
	var p2_pages_total: int = _roster_total_pages()
	var p1_cos: String = _current_costume_display_suffix(1)
	var p2_cos: String = _current_costume_display_suffix(2)
	_set_label_text(
		p1_cursor_label,
		"%s%s%s\nFORM %s%s  PAGE %d/%d"
		% [p1_prefix, _mod_name_at(p1_cursor_index), " [LOCKED]" if p1_locked else "", _current_form_display_name(1), p1_cos, p1_page_index + 1, p1_pages_total]
	)
	_set_label_text(
		p2_cursor_label,
		"%s%s%s\nFORM %s%s  PAGE %d/%d"
		% [p2_prefix, _mod_name_at(p2_cursor_index), " [LOCKED]" if p2_locked else "", _current_form_display_name(2), p2_cos, p2_page_index + 1, p2_pages_total]
	)
	if p2_ui != null:
		p2_ui.visible = _uses_dual_player()
	_refresh_active_player_highlight()

	_refresh_folder_panel()
	_refresh_player_preview_model(1)
	if _uses_dual_player():
		_refresh_player_preview_model(2)
	else:
		_clear_preview_model(2)
	_refresh_overlay_and_status()


func _refresh_roster_markers() -> void:
	_apply_roster_page_visibility(1, p1_roster_buttons, p1_page_index)
	_apply_roster_page_visibility(2, p2_roster_buttons, p2_page_index)
	for i in range(p1_roster_buttons.size()):
		var b: Button = p1_roster_buttons[i]
		var tags: Array[String] = []
		if i == p1_cursor_index:
			tags.append("P1")
		if folder_open and folder_player == 1 and i == folder_mod_index:
			tags.append("OPEN")
		if p1_locked and p1_selected_mod == _mod_load_key_at(i):
			tags.append("LOCK")
		var base_name: String = _mod_name_at(i)
		if b.icon == null:
			b.text = _short_roster_name(base_name.to_upper(), 11)
		b.tooltip_text = "%s%s" % [base_name, "" if tags.is_empty() else " [%s]" % ",".join(tags)]
		_apply_roster_button_visual_state(
			b,
			i == p1_cursor_index,
			folder_open and folder_player == 1 and i == folder_mod_index,
			p1_locked and p1_selected_mod == _mod_load_key_at(i),
			1
		)

	for i in range(p2_roster_buttons.size()):
		var b: Button = p2_roster_buttons[i]
		var tags: Array[String] = []
		if _uses_dual_player() and i == p2_cursor_index:
			tags.append("P2")
		if folder_open and folder_player == 2 and i == folder_mod_index:
			tags.append("OPEN")
		if p2_locked and p2_selected_mod == _mod_load_key_at(i):
			tags.append("LOCK")
		var base_name: String = _mod_name_at(i)
		if b.icon == null:
			b.text = _short_roster_name(base_name.to_upper(), 11)
		b.tooltip_text = "%s%s" % [base_name, "" if tags.is_empty() else " [%s]" % ",".join(tags)]
		_apply_roster_button_visual_state(
			b,
			_uses_dual_player() and i == p2_cursor_index,
			folder_open and folder_player == 2 and i == folder_mod_index,
			p2_locked and p2_selected_mod == _mod_load_key_at(i),
			2
		)
	call_deferred("_refresh_visual_roster_cursors")


func _refresh_roster_folder_rows() -> void:
	_refresh_roster_folder_row_for_player(1, p1_roster_row, p1_folder_roster_row)
	if _uses_dual_player():
		_refresh_roster_folder_row_for_player(2, p2_roster_row, p2_folder_roster_row)
	else:
		if p2_roster_row != null:
			p2_roster_row.visible = true
		if p2_folder_roster_row != null:
			p2_folder_roster_row.visible = false


func _refresh_roster_folder_row_for_player(player_id: int, base_row: Control, folder_row: HBoxContainer) -> void:
	if base_row == null:
		return
	var cursor_index: int = _get_cursor(player_id)
	var folder_here: bool = (
		folder_open
		and folder_player == player_id
		and folder_mod_index == cursor_index
		and folder_mod_index >= 0
		and folder_mod_index < available_mods.size()
	)
	if folder_row == null:
		base_row.visible = true
		return
	for child in folder_row.get_children():
		child.queue_free()
	if not folder_here:
		base_row.visible = true
		folder_row.visible = false
		return
	base_row.visible = false
	folder_row.visible = true
	var mod_entry: Dictionary = available_mods[folder_mod_index]
	if folder_stage == FOLDER_STAGE_COSTUME:
		var ckeys: Array[String] = _costume_keys_sorted(mod_entry)
		var cos_labels: Array[String] = ["Default"]
		for ck in ckeys:
			cos_labels.append(ck)
		for j in range(cos_labels.size()):
			var b := Button.new()
			b.custom_minimum_size = ROSTER_TEXT_BUTTON_SIZE
			b.text = _folder_strip_button_text(cos_labels[j].to_upper(), j == folder_costume_index)
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(_on_costume_pressed.bind(player_id, j))
			_apply_roster_button_visual_state(b, j == folder_costume_index, true, false, player_id)
			folder_row.add_child(b)
		return
	var labels: Array[String] = ["Base"]
	var forms: Array[String] = mod_entry.get("forms", [])
	for form_id in forms:
		labels.append(str(form_id))
	for i in range(labels.size()):
		var b := Button.new()
		b.custom_minimum_size = ROSTER_TEXT_BUTTON_SIZE
		b.text = _folder_strip_button_text(labels[i].to_upper(), i == folder_variant_index)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_variant_pressed.bind(player_id, i))
		_apply_roster_button_visual_state(b, i == folder_variant_index, true, false, player_id)
		folder_row.add_child(b)


func _apply_roster_button_visual_state(button: Button, is_cursor: bool, is_open: bool, is_locked: bool, player_id: int) -> void:
	if button == null:
		return
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.09, 0.14, 0.95)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	var border_color := Color(0.2, 0.32, 0.48, 0.9)
	if is_locked:
		border_color = Color(0.98, 0.86, 0.32, 1.0)
	elif is_open:
		border_color = Color(0.95, 0.97, 1.0, 1.0)
	elif is_cursor:
		border_color = Color(0.36, 0.74, 1.0, 1.0) if player_id == 1 else Color(1.0, 0.48, 0.56, 1.0)
	bg.border_color = border_color
	button.add_theme_stylebox_override("normal", bg)
	button.add_theme_stylebox_override("hover", bg)
	button.add_theme_stylebox_override("pressed", bg)


func _apply_roster_page_visibility(player_id: int, buttons: Array[Button], page_index: int) -> void:
	var count: int = buttons.size()
	if count <= 0:
		return
	var max_page: int = maxi(0, int(ceil(float(count) / float(ROSTER_PAGE_SIZE))) - 1)
	var page: int = clampi(page_index, 0, max_page)
	_set_page(player_id, page)
	var start_idx: int = page * ROSTER_PAGE_SIZE
	var end_idx: int = min(count - 1, start_idx + (ROSTER_PAGE_SIZE - 1))
	for i in range(count):
		var b: Button = buttons[i]
		b.visible = i >= start_idx and i <= end_idx


func _short_roster_name(name: String, max_chars: int) -> String:
	var trimmed: String = name.strip_edges()
	if trimmed.length() <= max_chars:
		return trimmed
	return "%s…" % trimmed.substr(0, max(0, max_chars - 1))


func _refresh_active_player_highlight() -> void:
	pass


func _refresh_visual_roster_cursors() -> void:
	if not is_inside_tree():
		return
	_update_roster_cursor_marker(p1_roster_buttons, p1_cursor_index, p1_roster_cursor_marker, false)
	if _uses_dual_player():
		_update_roster_cursor_marker(p2_roster_buttons, p2_cursor_index, p2_roster_cursor_marker, true)
	elif p2_roster_cursor_marker != null:
		p2_roster_cursor_marker.visible = false


func _update_roster_cursor_marker(buttons: Array[Button], cursor_index: int, marker: Control, place_above: bool) -> void:
	if marker == null:
		return
	if cursor_index < 0 or cursor_index >= buttons.size():
		marker.visible = false
		return
	var target: Button = buttons[cursor_index]
	if target == null or not is_instance_valid(target) or not target.visible:
		marker.visible = false
		return
	var parent_ctrl := marker.get_parent() as Control
	if parent_ctrl == null:
		marker.visible = false
		return
	var button_rect: Rect2 = target.get_global_rect()
	var parent_rect: Rect2 = parent_ctrl.get_global_rect()
	var center_x: float = (button_rect.position.x - parent_rect.position.x) + (button_rect.size.x * 0.5)
	var marker_size: Vector2 = marker.size
	if marker_size.x <= 1.0 or marker_size.y <= 1.0:
		marker_size = marker.get_combined_minimum_size()
		if marker_size.x <= 1.0:
			marker_size = Vector2(36.0, 20.0)
	var marker_x: float = clampf(center_x - (marker_size.x * 0.5), 0.0, maxf(0.0, parent_ctrl.size.x - marker_size.x))
	var marker_y: float = button_rect.position.y - parent_rect.position.y - marker_size.y - 2.0 if place_above else button_rect.end.y - parent_rect.position.y + 2.0
	marker.position = Vector2(marker_x, marker_y)
	marker.visible = true


func _refresh_team_slots(container: Control, roster: Array[Dictionary], size_required: int, player_label: String) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()
	var needed: int = size_required if _is_team_roster_mode() else 2
	for i in range(needed):
		var slot := Label.new()
		slot.custom_minimum_size = Vector2(118, 28)
		if i < roster.size():
			var entry: Dictionary = roster[i]
			var mod_label: String = str(entry.get("mod_display", entry.get("mod", "--")))
			var form_name: String = str(entry.get("form", ""))
			var cos_name: String = str(entry.get("costume", ""))
			var form_part: String = "" if form_name.is_empty() else " (%s)" % form_name
			var cos_part: String = "" if cos_name.is_empty() else " [%s]" % cos_name
			slot.text = "%s%s%s" % [mod_label, form_part, cos_part]
		else:
			slot.text = "%s Slot %d" % [player_label, i + 1]
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		container.add_child(slot)


func _refresh_folder_panel() -> void:
	if p1_folder_panel != null:
		p1_folder_panel.visible = false
	if p2_folder_panel != null:
		p2_folder_panel.visible = false


func _refresh_folder_panel_for_player(player_id: int, panel: Panel, summary_rich: RichTextLabel, hints_rich: RichTextLabel, row: Control, cache: Array[Button]) -> void:
	if panel == null or row == null:
		return
	for child in row.get_children():
		child.queue_free()
	cache.clear()

	var cursor_index: int = _get_cursor(player_id)
	if cursor_index < 0 or cursor_index >= available_mods.size():
		panel.visible = false
		if summary_rich != null:
			summary_rich.text = ""
		if hints_rich != null:
			hints_rich.text = ""
		return
	var mod_entry: Dictionary = available_mods[cursor_index]
	var ckeys: Array[String] = _costume_keys_sorted(mod_entry)
	var folder_here: bool = folder_open and folder_player == player_id and folder_mod_index == cursor_index
	panel.visible = folder_here
	if not folder_here:
		if summary_rich != null:
			summary_rich.text = ""
		if hints_rich != null:
			hints_rich.text = ""
		return
	var showing_costume_folder: bool = folder_here and folder_stage == FOLDER_STAGE_COSTUME
	var hint: String = "[b]H[/b]/[b]S[/b] change  |  [b]P[/b] select form"
	if showing_costume_folder:
		hint = "[b]H[/b]/[b]S[/b] change  |  [b]P[/b] confirm costume"
	if summary_rich != null:
		summary_rich.text = _folder_title_summary_bbcode(player_id, mod_entry, folder_here)
	if hints_rich != null:
		hints_rich.text = _folder_title_hints_bbcode(hint)

	var labels: Array[String] = ["Base"]
	var forms: Array[String] = mod_entry.get("forms", [])
	for form_id in forms:
		labels.append(str(form_id))

	var form_sel: int = 0
	if folder_here:
		form_sel = folder_variant_index
	elif player_id == 1 and p1_locked:
		form_sel = _form_index_for_player(mod_entry, p1_selected_form)
	elif player_id == 2 and p2_locked:
		form_sel = _form_index_for_player(mod_entry, p2_selected_form)

	var cos_sel: int = 0
	if showing_costume_folder:
		cos_sel = folder_costume_index
	elif player_id == 1 and p1_locked and p1_selected_mod == _mod_load_key(mod_entry):
		cos_sel = _costume_row_index_for_id(mod_entry, p1_selected_costume)
	elif player_id == 2 and p2_locked and p2_selected_mod == _mod_load_key(mod_entry):
		cos_sel = _costume_row_index_for_id(mod_entry, p2_selected_costume)

	var scroll_to: int = 0
	if showing_costume_folder and not ckeys.is_empty():
		var cos_labels: Array[String] = ["Default"]
		for ck in ckeys:
			cos_labels.append(ck)
		for j in range(cos_labels.size()):
			var cb := Button.new()
			cb.custom_minimum_size = Vector2(100, 30)
			cb.text = _folder_strip_button_text(cos_labels[j], j == cos_sel)
			cb.focus_mode = Control.FOCUS_NONE
			cb.pressed.connect(_on_costume_pressed.bind(player_id, j))
			row.add_child(cb)
			cache.append(cb)
			if j == cos_sel:
				scroll_to = j
	else:
		for i in range(labels.size()):
			var b := Button.new()
			b.custom_minimum_size = Vector2(106, 30)
			b.text = _folder_strip_button_text(labels[i], i == form_sel)
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(_on_variant_pressed.bind(player_id, i))
			row.add_child(b)
			cache.append(b)
			if i == form_sel:
				scroll_to = i

	var row_w: float = 100.0 * (ckeys.size() + 1) if showing_costume_folder and not ckeys.is_empty() else 106.0 * labels.size()
	row.custom_minimum_size = Vector2(row_w, 30.0)
	call_deferred("_scroll_variant_row_to_selected", row, scroll_to)


func _form_index_for_player(mod_entry: Dictionary, form_id: String) -> int:
	if form_id.is_empty():
		return 0
	var forms: Array[String] = mod_entry.get("forms", [])
	var idx: int = forms.find(form_id)
	return 0 if idx < 0 else idx + 1


func _on_variant_pressed(player_id: int, index: int) -> void:
	if _is_player_locked(player_id):
		return
	var cursor_index: int = _get_cursor(player_id)
	if cursor_index < 0 or cursor_index >= available_mods.size():
		return
	if not folder_open or folder_player != player_id or folder_mod_index != cursor_index:
		_open_folder(player_id, cursor_index)
	folder_stage = FOLDER_STAGE_FORM
	folder_variant_index = index
	var mod_entry: Dictionary = available_mods[cursor_index]
	if not _costume_keys_sorted(mod_entry).is_empty():
		folder_stage = FOLDER_STAGE_COSTUME
		folder_costume_index = 0
	SystemSFX.play_ui_from(self, "ui_move")
	_refresh_ui()


func _on_costume_pressed(player_id: int, index: int) -> void:
	if _is_player_locked(player_id):
		return
	var cursor_index: int = _get_cursor(player_id)
	if cursor_index < 0 or cursor_index >= available_mods.size():
		return
	if not folder_open or folder_player != player_id or folder_mod_index != cursor_index:
		_open_folder(player_id, cursor_index)
	folder_stage = FOLDER_STAGE_COSTUME
	folder_costume_index = index
	SystemSFX.play_ui_from(self, "ui_move")
	_refresh_ui()


func _folder_strip_button_text(base: String, is_selected: bool) -> String:
	if is_selected:
		return "[%s]" % base
	return base


func _folder_costume_value_string(player_id: int, mod_entry: Dictionary, folder_here: bool) -> String:
	if folder_here:
		if folder_stage != FOLDER_STAGE_COSTUME:
			return "—"
		if _folder_selected_costume(mod_entry).is_empty():
			return "Default"
		return _folder_selected_costume(mod_entry)
	if player_id == 1 and p1_locked and p1_selected_mod == _mod_load_key(mod_entry):
		return "Default" if p1_selected_costume.is_empty() else p1_selected_costume
	if player_id == 2 and p2_locked and p2_selected_mod == _mod_load_key(mod_entry):
		return "Default" if p2_selected_costume.is_empty() else p2_selected_costume
	return "—"


func _folder_title_summary_bbcode(player_id: int, mod_entry: Dictionary, folder_here: bool) -> String:
	var cname: String = str(mod_entry.get("display_name", mod_entry.get("name", "Character")))
	var form: String = _current_form_display_name(player_id)
	var cos: String = _folder_costume_value_string(player_id, mod_entry, folder_here)
	var dot: String = "[color=#4a5c78]·[/color]"
	var tag_col: String = "#7eb8ff" if player_id == 1 else "#ff9494"
	var show_costume: bool = false
	if folder_here:
		show_costume = folder_stage == FOLDER_STAGE_COSTUME
	elif player_id == 1 and p1_locked and p1_selected_mod == _mod_load_key(mod_entry):
		show_costume = true
	elif player_id == 2 and p2_locked and p2_selected_mod == _mod_load_key(mod_entry):
		show_costume = true
	if show_costume:
		return (
			"[b][color=%s]P%d[/color][/b]  [color=#f2f6ff]%s[/color]  %s  [b]Form[/b]  [color=#dce8ff]%s[/color]  %s  [b]Costume[/b]  [color=#dce8ff]%s[/color]"
			% [tag_col, player_id, cname, dot, form, dot, cos]
		)
	return (
		"[b][color=%s]P%d[/color][/b]  [color=#f2f6ff]%s[/color]  %s  [b]Form[/b]  [color=#dce8ff]%s[/color]"
		% [tag_col, player_id, cname, dot, form]
	)


func _folder_title_hints_bbcode(hint_bbcode: String) -> String:
	var sep: String = "  [color=#4a5c78]|[/color]  "
	var parts: PackedStringArray = hint_bbcode.split("  |  ", false)
	if parts.is_empty():
		return ""
	var out: String = ""
	for i in range(parts.size()):
		if i > 0:
			out += sep
		out += parts[i].strip_edges()
	return out


func _current_costume_display_suffix(player_id: int) -> String:
	if player_id != 1 and player_id != 2:
		return ""
	var cursor_index: int = _get_cursor(player_id)
	if cursor_index < 0 or cursor_index >= available_mods.size():
		return ""
	var mod_entry: Dictionary = available_mods[cursor_index]
	if _costume_keys_sorted(mod_entry).is_empty():
		return ""
	var cid: String = ""
	var show_costume: bool = false
	if folder_open and folder_player == player_id and folder_mod_index == cursor_index:
		if folder_stage != FOLDER_STAGE_COSTUME:
			return ""
		cid = _folder_selected_costume(mod_entry)
		show_costume = true
	elif player_id == 1 and p1_locked:
		cid = p1_selected_costume
		show_costume = true
	elif player_id == 2 and p2_locked:
		cid = p2_selected_costume
		show_costume = true
	if not show_costume:
		return ""
	if cid.is_empty():
		return "  CST Default"
	return "  CST %s" % cid.to_upper()


func _refresh_player_preview_model(player_id: int) -> void:
	var cursor_index: int = _get_cursor(player_id)
	if cursor_index < 0 or cursor_index >= available_mods.size():
		_clear_preview_model(player_id)
		if player_id == 1:
			_preview_p1_key = ""
		else:
			_preview_p2_key = ""
		return
	var mod_entry: Dictionary = available_mods[cursor_index]
	var form_id: String = ""
	if folder_open and folder_player == player_id and folder_mod_index == cursor_index:
		form_id = _folder_selected_form(mod_entry)
	elif player_id == 1 and p1_locked:
		form_id = p1_selected_form
	elif player_id == 2 and p2_locked:
		form_id = p2_selected_form
	var costume_id: String = ""
	if folder_open and folder_player == player_id and folder_mod_index == cursor_index:
		costume_id = _folder_selected_costume(mod_entry)
	elif player_id == 1 and p1_locked and p1_selected_mod == _mod_load_key(mod_entry):
		costume_id = p1_selected_costume
	elif player_id == 2 and p2_locked and p2_selected_mod == _mod_load_key(mod_entry):
		costume_id = p2_selected_costume

	var slot_key: String = "%s|%s|%s" % [_mod_load_key(mod_entry), form_id, costume_id]
	if player_id == 1:
		if slot_key == _preview_p1_key and p1_preview_model != null and is_instance_valid(p1_preview_model):
			return
	else:
		if slot_key == _preview_p2_key and p2_preview_model != null and is_instance_valid(p2_preview_model):
			return

	_clear_preview_model(player_id)
	var model_root: Node3D = _instantiate_preview_model(mod_entry, form_id, costume_id)
	if model_root == null:
		var empty_tex: TextureRect = p1_preview_texture if player_id == 1 else p2_preview_texture
		if empty_tex != null:
			empty_tex.texture = null
		return

	var stage: Node3D = p1_preview_stage if player_id == 1 else p2_preview_stage
	var viewport: SubViewport = p1_preview_viewport if player_id == 1 else p2_preview_viewport
	var preview_tex: TextureRect = p1_preview_texture if player_id == 1 else p2_preview_texture
	if stage == null or viewport == null:
		model_root.queue_free()
		return
	stage.add_child(model_root)
	var spawn: Marker3D = preview_spawn_point_p1 if player_id == 1 else preview_spawn_point_p2
	if spawn != null:
		model_root.transform = spawn.global_transform
	if auto_fit_preview_models:
		_fit_model_to_preview(model_root)
	if player_id == 1:
		p1_preview_model = model_root
		_preview_p1_key = slot_key
	else:
		p2_preview_model = model_root
		_preview_p2_key = slot_key
	_sync_preview_viewport_sizes()
	if preview_tex != null:
		preview_tex.texture = viewport.get_texture()


func _refresh_overlay_and_status() -> void:
	if lock_overlay != null:
		lock_overlay.visible = _all_required_locked()
		if lock_overlay.visible:
			_set_label_text(lock_overlay_label, "Teams locked. Press Attack(P) to continue.")
	if folder_open:
		if folder_stage == FOLDER_STAGE_FORM:
			_set_label_text(
				status_label,
				"Form folder: pick Base/Form with H/S or click, then press Attack(P)."
			)
		else:
			_set_label_text(
				status_label,
				"Costume folder: pick Default/Costume with H/S or click, then press Attack(P) to lock."
			)
	elif game_mode == "tournament":
		var n: int = clampi(int(get_tree().get_meta("tournament_size", 4)), 4, 16)
		_set_label_text(status_label, "Press Attack(P) to draw %d random CPU fighters and start tournament." % n)
	elif _is_team_roster_mode():
		_set_label_text(status_label, "Team draft: open a character folder, choose the form, and lock each team slot.")
	else:
		_set_label_text(status_label, "Attack(P) opens the character folder, then Attack(P) locks the highlighted Base/Form.")


func _mod_name_at(index: int) -> String:
	if index < 0 or index >= available_mods.size():
		return "Unknown"
	return str(available_mods[index].get("display_name", available_mods[index].get("name", "Unknown")))


func _mod_load_key(mod_entry: Dictionary) -> String:
	var p: String = str(mod_entry.get("path", "")).strip_edges()
	if not p.is_empty():
		return p
	return str(mod_entry.get("name", "")).strip_edges()


func _mod_load_key_at(index: int) -> String:
	if index < 0 or index >= available_mods.size():
		return ""
	return _mod_load_key(available_mods[index])


func _display_for_mod_load_key(load_key: String) -> String:
	for e in available_mods:
		if _mod_load_key(e) == load_key:
			return str(e.get("display_name", e.get("name", load_key)))
	var trimmed: String = load_key.strip_edges().trim_suffix("/")
	if trimmed.contains("/"):
		return trimmed.get_file()
	return load_key


func _commit_selection() -> void:
	if game_mode == "tournament":
		var n: int = clampi(int(get_tree().get_meta("tournament_size", 4)), 4, 16)
		var entrants: Array = _draw_random_entrants(n)
		if entrants.size() >= 2:
			get_tree().set_meta("tournament_entrants", entrants)
			get_tree().set_meta("tournament_match_index", 0)
			get_tree().set_meta("tournament_round_results", [])
			get_tree().change_scene_to_file(stage_select_scene_path)
		return
	if p1_selected_mod.is_empty() and not available_mods.is_empty():
		p1_selected_mod = _mod_load_key(available_mods[0])
		p1_selected_display = str(available_mods[0].get("display_name", available_mods[0].get("name", "")))

	if _is_team_roster_mode():
		if p1_team_roster.is_empty() and not p1_selected_mod.is_empty():
			p1_team_roster.append(
				{
					"mod": p1_selected_mod,
					"mod_display": _display_for_mod_load_key(p1_selected_mod),
					"form": p1_selected_form,
					"costume": p1_selected_costume
				}
			)
		if game_mode == "coop":
			while p2_team_roster.size() < team_size_p2:
				var seed_mod: String = p1_team_roster[0].get("mod", "") if not p1_team_roster.is_empty() else ""
				var opp: String = _pick_arcade_opponent(seed_mod)
				p2_team_roster.append(
					{"mod": opp, "mod_display": _display_for_mod_load_key(opp), "form": "", "costume": ""}
				)
		elif p2_team_roster.is_empty():
			if not p2_selected_mod.is_empty():
				p2_team_roster.append(
					{
						"mod": p2_selected_mod,
						"mod_display": _display_for_mod_load_key(p2_selected_mod),
						"form": p2_selected_form,
						"costume": p2_selected_costume
					}
				)
			elif not p1_team_roster.is_empty():
				p2_team_roster = p1_team_roster.duplicate(true)
		get_tree().set_meta("team_mode_subtype", team_mode_subtype)
		get_tree().set_meta("team_size_p1", team_size_p1)
		get_tree().set_meta("team_size_p2", team_size_p2)
		get_tree().set_meta("team_roster_p1", p1_team_roster.duplicate(true))
		get_tree().set_meta("team_roster_p2", p2_team_roster.duplicate(true))
		var p1_first: Dictionary = p1_team_roster[0] if not p1_team_roster.is_empty() else {}
		var p2_first: Dictionary = p2_team_roster[0] if not p2_team_roster.is_empty() else p1_first
		get_tree().set_meta("training_p1_mod", str(p1_first.get("mod", "")))
		get_tree().set_meta("training_p1_form", str(p1_first.get("form", "")))
		get_tree().set_meta("training_p1_costume", str(p1_first.get("costume", "")))
		get_tree().set_meta("training_p2_mod", str(p2_first.get("mod", "")))
		get_tree().set_meta("training_p2_form", str(p2_first.get("form", "")))
		get_tree().set_meta("training_p2_costume", str(p2_first.get("costume", "")))
		get_tree().change_scene_to_file(stage_select_scene_path)
		return

	if game_mode == "online":
		var is_host: bool = bool(get_tree().get_meta("online_host", false))
		if is_host:
			get_tree().set_meta("training_p1_mod", p1_selected_mod)
			get_tree().set_meta("training_p1_form", p1_selected_form)
			get_tree().set_meta("training_p1_costume", p1_selected_costume)
			get_tree().set_meta("training_p2_mod", "")
			get_tree().set_meta("training_p2_form", "")
			get_tree().set_meta("training_p2_costume", "")
		else:
			NetworkManager.send_my_character_selection(p2_selected_mod)
			get_tree().set_meta("training_p1_mod", "")
			get_tree().set_meta("training_p1_form", "")
			get_tree().set_meta("training_p1_costume", "")
			get_tree().set_meta("training_p2_mod", p2_selected_mod)
			get_tree().set_meta("training_p2_form", p2_selected_form)
			get_tree().set_meta("training_p2_costume", p2_selected_costume)
		get_tree().set_meta("team_roster_p1", [])
		get_tree().set_meta("team_roster_p2", [])
		get_tree().change_scene_to_file(stage_select_scene_path)
		return

	var p2_mod_name: String = p2_selected_mod
	var p2_form_name: String = p2_selected_form
	var p2_costume_name: String = p2_selected_costume
	var training_smash: bool = bool(get_tree().get_meta("training_smash_rules", false))
	match game_mode:
		"arcade", "survival":
			p2_mod_name = _pick_arcade_opponent(p1_selected_mod)
			p2_form_name = ""
			p2_costume_name = ""
		"training":
			if not training_smash:
				p2_mod_name = p1_selected_mod
				p2_form_name = p1_selected_form
				p2_costume_name = p1_selected_costume
		"cpu_training":
			if training_smash:
				if p2_mod_name.is_empty():
					p2_mod_name = p1_selected_mod
					p2_form_name = p1_selected_form
					p2_costume_name = p1_selected_costume
			else:
				p2_mod_name = p1_selected_mod
				p2_form_name = p1_selected_form
				p2_costume_name = p1_selected_costume
		_:
			if p2_mod_name.is_empty():
				p2_mod_name = p1_selected_mod
				p2_form_name = p1_selected_form
				p2_costume_name = p1_selected_costume

	get_tree().set_meta("training_p1_mod", p1_selected_mod)
	get_tree().set_meta("training_p1_form", p1_selected_form)
	get_tree().set_meta("training_p1_costume", p1_selected_costume)
	get_tree().set_meta("training_p2_mod", p2_mod_name)
	get_tree().set_meta("training_p2_form", p2_form_name)
	get_tree().set_meta("training_p2_costume", p2_costume_name)
	get_tree().set_meta("team_roster_p1", [])
	get_tree().set_meta("team_roster_p2", [])
	get_tree().change_scene_to_file(stage_select_scene_path)


func _draw_random_entrants(n: int) -> Array:
	var out: Array = []
	if available_mods.is_empty():
		return out
	n = maxi(2, mini(n, 16))
	for i in range(n):
		var idx: int = randi() % available_mods.size()
		var entry: Dictionary = available_mods[idx]
		var load_key: String = _mod_load_key(entry)
		var disp: String = str(entry.get("display_name", entry.get("name", "")))
		var forms: Array = entry.get("forms", [])
		var form_id: String = ""
		if forms.size() > 0:
			form_id = str(forms[randi() % forms.size()])
		out.append({"mod": load_key, "mod_display": disp, "form": form_id, "costume": ""})
	return out


func _pick_arcade_opponent(player_mod_path: String) -> String:
	for entry in available_mods:
		if _mod_load_key(entry) != player_mod_path:
			return _mod_load_key(entry)
	return player_mod_path


func _clear_preview_model(player_id: int) -> void:
	_purge_preview_stage_models(player_id)
	if player_id == 1:
		if p1_preview_model != null and is_instance_valid(p1_preview_model):
			if p1_preview_model.get_parent() != null:
				p1_preview_model.get_parent().remove_child(p1_preview_model)
			p1_preview_model.free()
		p1_preview_model = null
		if p1_preview_texture != null:
			p1_preview_texture.texture = null
	else:
		if p2_preview_model != null and is_instance_valid(p2_preview_model):
			if p2_preview_model.get_parent() != null:
				p2_preview_model.get_parent().remove_child(p2_preview_model)
			p2_preview_model.free()
		p2_preview_model = null
		if p2_preview_texture != null:
			p2_preview_texture.texture = null


func _instantiate_preview_model(mod_entry: Dictionary, form_id: String = "", costume_id: String = "") -> Node3D:
	var model_path: String = _resolve_preview_model_path(mod_entry, form_id, costume_id)
	if model_path.is_empty() or not _is_candidate_model_file(model_path):
		return null
	var model_scene: Node = _load_preview_model_node(model_path)
	if model_scene == null or not (model_scene is Node3D):
		return null
	var root := Node3D.new()
	root.name = "PreviewModelRoot"
	root.set_meta("is_preview_model", true)
	var model_3d := model_scene as Node3D
	var def_data: Dictionary = mod_entry.get("def_data", {})
	root.rotation_degrees.y = preview_model_y_rotation_degrees
	model_3d.scale = _extract_model_scale(def_data)
	model_3d.position.y += float(def_data.get("model_offset_y", 0.0))
	root.add_child(model_3d)
	_play_preview_animation(model_3d)
	var mod_path_sel: String = str(mod_entry.get("path", "")).strip_edges()
	if not mod_path_sel.is_empty():
		if _preview_shader_loader == null:
			_preview_shader_loader = ModLoader.new()
		var base_def: Dictionary = mod_entry.get("def_data", {})
		if typeof(base_def) != TYPE_DICTIONARY:
			base_def = {}
		var fdata: Dictionary = _get_form_data(mod_entry, form_id)
		var cdata: Dictionary = _get_costume_data(mod_entry, costume_id)
		var def_eff: Dictionary = _preview_shader_loader.character_def_with_costume_overrides(base_def, fdata)
		def_eff = _preview_shader_loader.character_def_with_costume_overrides(def_eff, cdata)
		_preview_shader_loader.apply_character_def_shader_to_model(model_3d, mod_path_sel, def_eff, model_path)
	return root


func _purge_preview_stage_models(player_id: int) -> void:
	var stage: Node3D = p1_preview_stage if player_id == 1 else p2_preview_stage
	if stage == null:
		return
	for child in stage.get_children():
		if not (child is Node3D):
			continue
		var n3d := child as Node3D
		var keep_light: bool = n3d is DirectionalLight3D or n3d is OmniLight3D or n3d is SpotLight3D
		var keep_camera: bool = n3d is Camera3D
		if keep_light or keep_camera:
			continue
		stage.remove_child(n3d)
		n3d.free()


func _fit_model_to_preview(model_root: Node3D) -> void:
	if model_root == null:
		return
	var bounds: AABB = _collect_model_aabb(model_root)
	if bounds.size.length() <= 0.0001:
		return
	var max_dimension: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if max_dimension <= 0.0001:
		return
	# Normalize huge/small mod models so they stay inside preview frame.
	var target_size: float = 1.8
	var fit_scale: float = target_size / max_dimension
	model_root.scale *= Vector3.ONE * fit_scale

	# Recompute and center model after scaling.
	bounds = _collect_model_aabb(model_root)
	var center: Vector3 = bounds.position + (bounds.size * 0.5)
	model_root.position -= center
	model_root.position.y -= bounds.position.y


func _collect_model_aabb(root: Node3D) -> AABB:
	var stack: Array[Node] = [root]
	var has_bounds: bool = false
	var merged: AABB = AABB()
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh != null:
				var local_box: AABB = mi.mesh.get_aabb()
				var world_box: AABB = mi.global_transform * local_box
				if not has_bounds:
					merged = world_box
					has_bounds = true
				else:
					merged = merged.merge(world_box)
		for child in n.get_children():
			stack.append(child)
	if not has_bounds:
		return AABB(Vector3.ZERO, Vector3.ZERO)
	return merged


## Prefer imported PackedScene (res:// *.glb) so previews skip full GLTF re-parse each refresh.
func _load_preview_model_node(model_path: String) -> Node:
	var lower_path: String = model_path.to_lower()
	var is_gltf_ext: bool = lower_path.ends_with(".gltf") or lower_path.ends_with(".glb")
	if ResourceLoader.exists(model_path):
		var res: Resource = ResourceLoader.load(model_path)
		if res is PackedScene:
			var inst: Node = (res as PackedScene).instantiate()
			if inst != null:
				return inst
		if not is_gltf_ext:
			return null
	if is_gltf_ext:
		return _load_gltf_scene_any_path(model_path)
	return null


func _resolve_preview_model_path(mod_entry: Dictionary, form_id: String, costume_id: String) -> String:
	var model_path: String = str(mod_entry.get("model_path", ""))
	if not form_id.is_empty():
		var form_data: Dictionary = _get_form_data(mod_entry, form_id)
		var form_model_path: String = _resolve_mod_relative_path(mod_entry, str(form_data.get("model_path", "")).strip_edges())
		if not form_model_path.is_empty():
			model_path = form_model_path
	if not costume_id.is_empty():
		var costume_data: Dictionary = _get_costume_data(mod_entry, costume_id)
		var costume_model_path: String = _resolve_mod_relative_path(mod_entry, str(costume_data.get("model_path", "")).strip_edges())
		if not costume_model_path.is_empty():
			model_path = costume_model_path
	return model_path


func _get_form_data(mod_entry: Dictionary, form_id: String) -> Dictionary:
	if form_id.is_empty():
		return {}
	var forms_data: Dictionary = mod_entry.get("forms_data", {})
	if typeof(forms_data) != TYPE_DICTIONARY:
		return {}
	var value = forms_data.get(form_id, {})
	return value if typeof(value) == TYPE_DICTIONARY else {}


func _get_costume_data(mod_entry: Dictionary, costume_id: String) -> Dictionary:
	if costume_id.is_empty():
		return {}
	var costumes_data: Dictionary = mod_entry.get("costumes_data", {})
	if typeof(costumes_data) != TYPE_DICTIONARY:
		return {}
	var value = costumes_data.get(costume_id, {})
	return value if typeof(value) == TYPE_DICTIONARY else {}


func _resolve_mod_relative_path(mod_entry: Dictionary, raw_path: String) -> String:
	if raw_path.is_empty():
		return ""
	if raw_path.begins_with("res://") or raw_path.begins_with("user://"):
		return raw_path
	var mod_path: String = str(mod_entry.get("path", ""))
	return "%s%s" % [mod_path, raw_path]


func _load_gltf_scene_any_path(model_path: String) -> Node:
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	if gltf.append_from_file(model_path, state) == OK:
		return gltf.generate_scene(state)
	var absolute_path: String = ProjectSettings.globalize_path(model_path)
	if absolute_path.is_empty() or absolute_path == model_path:
		return null
	var gltf_abs := GLTFDocument.new()
	var state_abs := GLTFState.new()
	if gltf_abs.append_from_file(absolute_path, state_abs) != OK:
		return null
	return gltf_abs.generate_scene(state_abs)


func _play_preview_animation(root: Node) -> void:
	if root == null:
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is AnimationPlayer:
			var player := node as AnimationPlayer
			var names: PackedStringArray = player.get_animation_list()
			if not names.is_empty():
				var anim_name: StringName = names[0]
				var anim: Animation = player.get_animation(anim_name)
				if anim != null:
					anim.loop_mode = Animation.LOOP_LINEAR
				player.play(anim_name)
				return
		for child in node.get_children():
			stack.append(child)


func _is_valid_mod_folder(mod_path: String) -> bool:
	return bool(ContentResolver.build_character_entry(mod_path.trim_suffix("/").get_file(), mod_path).get("is_playable", false))


func _has_any_model_file(mod_path: String) -> bool:
	return not ContentResolver.find_character_model_path(mod_path, _load_character_def("%scharacter.def" % mod_path)).is_empty()


func _find_model_file(mod_path: String) -> String:
	return ContentResolver.find_character_model_path(mod_path, _load_character_def("%scharacter.def" % mod_path))


func _resolve_model_path_from_def(mod_path: String) -> String:
	var def_data: Dictionary = _load_character_def("%scharacter.def" % mod_path)
	var raw_path: String = str(def_data.get("model_path", def_data.get("model_file", ""))).strip_edges()
	return ContentResolver.resolve_relative_or_absolute_path(mod_path, raw_path)


func _load_mod_forms_data(mod_path: String) -> Dictionary:
	var path: String = "%stransformations.json" % mod_path
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var forms_dict: Dictionary = (parsed as Dictionary).get("forms", {})
	return forms_dict if typeof(forms_dict) == TYPE_DICTIONARY else {}


func _load_mod_costumes_data(mod_path: String) -> Dictionary:
	var path: String = "%scostumes.json" % mod_path
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var costumes_dict: Dictionary = (parsed as Dictionary).get("costumes", {})
	return costumes_dict if typeof(costumes_dict) == TYPE_DICTIONARY else {}


func _load_mod_icon_texture(mod_path: String) -> Texture2D:
	var mod_name: String = mod_path.trim_suffix("/").get_file()
	var candidates: Array[String] = [
		"%simages/Icon.png" % mod_path,
		"%simages/icon.png" % mod_path,
		"%sIcon.png" % mod_path,
		"%sicon.png" % mod_path,
		"res://mods/%s/images/Icon.png" % mod_name,
		"res://mods/%s/images/icon.png" % mod_name
	]
	for candidate in candidates:
		var texture := _load_texture_from_path(candidate)
		if texture != null:
			return texture
	return null


func _load_texture_from_path(path: String) -> Texture2D:
	var abs_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path):
		return null
	if path.begins_with("res://"):
		var loaded := ResourceLoader.load(path)
		if loaded is Texture2D:
			return loaded as Texture2D
	var image := Image.new()
	if image.load(abs_path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _load_character_def(path: String) -> Dictionary:
	return ContentResolver.load_character_def(path)


func _extract_model_scale(def_data: Dictionary) -> Vector3:
	var uniform_scale: float = float(def_data.get("model_scale", 1.0))
	var x: float = float(def_data.get("model_scale_x", uniform_scale))
	var y: float = float(def_data.get("model_scale_y", uniform_scale))
	var z: float = float(def_data.get("model_scale_z", uniform_scale))
	return Vector3(x, y, z)


func _normalize_root(root: String) -> String:
	var normalized: String = root.strip_edges()
	if normalized.is_empty():
		return ""
	if not normalized.ends_with("/"):
		normalized += "/"
	return normalized


func _is_candidate_model_file(path: String) -> bool:
	return ContentResolver.is_candidate_model_file(path)


func _bind_ui_nodes() -> void:
	preview_spawn_point_p1 = get_node_or_null("CharacterPreviewP1/PreviewSpawnPointP1") as Marker3D
	if preview_spawn_point_p1 == null:
		preview_spawn_point_p1 = get_node_or_null("CharacterPreview/PreviewSpawnPoint") as Marker3D
		if preview_spawn_point_p1 == null:
			preview_spawn_point_p1 = find_child("PreviewSpawnPointP1", true, false) as Marker3D
	if preview_spawn_point_p1 == null:
		preview_spawn_point_p1 = find_child("PreviewSpawnPoint", true, false) as Marker3D
	preview_spawn_point_p2 = get_node_or_null("CharacterPreviewP2/PreviewSpawnPointP2") as Marker3D
	if preview_spawn_point_p2 == null:
		preview_spawn_point_p2 = preview_spawn_point_p1

	instruction_label = _find_node_by_name("InstructionLabel") as Label
	mode_label = _find_node_by_name("ModeLabel") as Label
	status_label = _find_node_by_name("StatusLabel") as Label

	p2_ui = _find_node_by_name("Player2UI") as Control

	var p1_ui: Node = _find_node_by_name("Player1UI")
	p1_team_slots = _find_child_from(p1_ui, "TeamSlots") as Control
	p1_cursor_label = _find_child_from(p1_ui, "Cursor") as Label
	p1_roster_scroll = _find_child_from(p1_ui, "RosterScroll") as Control
	p1_roster_row = _find_child_from(p1_ui, "RosterRow") as Control
	p1_roster_cursor_marker = _find_child_from(p1_ui, "RosterCursorMarkerP1") as Control
	p1_panel = _find_child_from(p1_ui, "P1Panel") as Panel

	var p2_ui_node: Node = p2_ui
	p2_team_slots = _find_child_from(p2_ui_node, "TeamSlots") as Control
	p2_cursor_label = _find_child_from(p2_ui_node, "Cursor") as Label
	p2_roster_scroll = _find_child_from(p2_ui_node, "RosterScroll") as Control
	p2_roster_row = _find_child_from(p2_ui_node, "RosterRow") as Control
	p2_roster_cursor_marker = _find_child_from(p2_ui_node, "RosterCursorMarkerP2") as Control
	p2_panel = _find_child_from(p2_ui_node, "P2Panel") as Panel
	p1_preview_texture = _find_child_from(p1_ui, "PreviewTexture") as TextureRect
	p2_preview_texture = _find_child_from(p2_ui_node, "PreviewTexture") as TextureRect
	_configure_preview_texture(p1_preview_texture)
	_configure_preview_texture(p2_preview_texture)
	_ensure_roster_folder_rows()

	p1_folder_panel = _find_node_by_name("CharacterFolderPanelP1") as Panel
	p1_folder_summary_rich = _find_node_by_name("FolderSummaryP1") as RichTextLabel
	p1_folder_hints_rich = _find_node_by_name("FolderHintsP1") as RichTextLabel
	p1_variant_row = _find_node_by_name("VariantRowP1") as Control
	p2_folder_panel = _find_node_by_name("CharacterFolderPanelP2") as Panel
	p2_folder_summary_rich = _find_node_by_name("FolderSummaryP2") as RichTextLabel
	p2_folder_hints_rich = _find_node_by_name("FolderHintsP2") as RichTextLabel
	p2_variant_row = _find_node_by_name("VariantRowP2") as Control

	lock_overlay = _find_node_by_name("LockInOverlay") as ColorRect
	lock_overlay_label = _find_node_by_name("LockLabel") as Label
	preview_camera_p1_source = get_node_or_null("CameraRigP1/PreviewCameraP1") as Camera3D
	preview_camera_p2_source = get_node_or_null("CameraRigP2/PreviewCameraP2") as Camera3D
	preview_key_light_p1_source = get_node_or_null("CameraRigP1/SunLightP1") as DirectionalLight3D
	preview_key_light_p2_source = get_node_or_null("CameraRigP2/SunLightP2") as DirectionalLight3D
	preview_fill_light_p1_source = get_node_or_null("FillLightP1") as OmniLight3D
	preview_fill_light_p2_source = get_node_or_null("FillLightP2") as OmniLight3D


func _find_node_by_name(node_name: String) -> Node:
	return find_child(node_name, true, false)


func _find_child_from(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	return root.find_child(node_name, true, false)


func _set_label_text(label: Label, value: String) -> void:
	if label != null:
		label.text = value


func _configure_preview_texture(tex: TextureRect) -> void:
	if tex == null:
		return


func _setup_preview_viewports() -> void:
	var p1_data: Dictionary = _create_preview_viewport(1)
	p1_preview_viewport = p1_data.get("viewport", null)
	p1_preview_stage = p1_data.get("stage", null)
	var p2_data: Dictionary = _create_preview_viewport(2)
	p2_preview_viewport = p2_data.get("viewport", null)
	p2_preview_stage = p2_data.get("stage", null)
	_sync_preview_viewport_sizes()


func _create_preview_viewport(player_id: int) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.disable_3d = false
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = Vector2i(400, 220)
	add_child(viewport)

	var stage := Node3D.new()
	viewport.add_child(stage)

	var key_src: DirectionalLight3D = preview_key_light_p1_source if player_id == 1 else preview_key_light_p2_source
	var key_light := key_src.duplicate() as DirectionalLight3D if key_src != null else DirectionalLight3D.new()
	if key_src == null:
		key_light.rotation_degrees = Vector3(-30.0, 30.0, 0.0)
	stage.add_child(key_light)
	if key_src != null:
		key_light.transform = key_src.global_transform

	var fill_src: OmniLight3D = preview_fill_light_p1_source if player_id == 1 else preview_fill_light_p2_source
	var fill_light := fill_src.duplicate() as OmniLight3D if fill_src != null else OmniLight3D.new()
	if fill_src == null:
		fill_light.position = Vector3(-1.2, 1.5, 1.3)
		fill_light.light_energy = 0.7
	stage.add_child(fill_light)
	if fill_src != null:
		fill_light.transform = fill_src.global_transform

	var cam_src: Camera3D = preview_camera_p1_source if player_id == 1 else preview_camera_p2_source
	var camera := cam_src.duplicate() as Camera3D if cam_src != null else Camera3D.new()
	if cam_src == null:
		camera.position = Vector3(0.0, 1.2, 2.8)
		camera.look_at_from_position(camera.position, Vector3(0.0, 1.0, 0.0), Vector3.UP)
	camera.current = true
	stage.add_child(camera)
	if cam_src != null:
		camera.transform = cam_src.global_transform
	return {"viewport": viewport, "stage": stage}


func _sync_preview_viewport_sizes() -> void:
	if p1_preview_viewport != null and is_instance_valid(p1_preview_viewport) and p1_preview_texture != null:
		var size1: Vector2 = p1_preview_texture.size
		if size1.x > 1.0 and size1.y > 1.0:
			p1_preview_viewport.size = Vector2i(maxi(1, int(size1.x)), maxi(1, int(size1.y)))
	if p2_preview_viewport != null and is_instance_valid(p2_preview_viewport) and p2_preview_texture != null:
		var size2: Vector2 = p2_preview_texture.size
		if size2.x > 1.0 and size2.y > 1.0:
			p2_preview_viewport.size = Vector2i(maxi(1, int(size2.x)), maxi(1, int(size2.y)))
	call_deferred("_refresh_visual_roster_cursors")


func _roster_total_pages() -> int:
	if available_mods.is_empty():
		return 1
	return maxi(1, int(ceil(float(available_mods.size()) / float(ROSTER_PAGE_SIZE))))


func _scroll_variant_row_to_selected(row: Control, selected_idx: int) -> void:
	if row == null:
		return
	var scroll := row.get_parent() as ScrollContainer
	if scroll == null:
		return
	if selected_idx < 0 or selected_idx >= row.get_child_count():
		return
	var child := row.get_child(selected_idx) as Control
	if child == null:
		return
	var viewport_width: float = scroll.size.x
	if viewport_width <= 1.0:
		return
	var left: float = child.position.x
	var right: float = left + child.size.x
	var current: float = float(scroll.scroll_horizontal)
	if left < current:
		scroll.scroll_horizontal = int(left)
	elif right > current + viewport_width:
		scroll.scroll_horizontal = int(right - viewport_width)


func _current_form_display_name(player_id: int) -> String:
	if player_id != 1 and player_id != 2:
		return "BASE"
	var cursor_index: int = _get_cursor(player_id)
	if cursor_index < 0 or cursor_index >= available_mods.size():
		return "BASE"
	var mod_entry: Dictionary = available_mods[cursor_index]
	if folder_open and folder_player == player_id and folder_mod_index == cursor_index:
		var folder_form: String = _folder_selected_form(mod_entry)
		return "BASE" if folder_form.is_empty() else folder_form.to_upper()
	if player_id == 1 and p1_locked:
		return "BASE" if p1_selected_form.is_empty() else p1_selected_form.to_upper()
	if player_id == 2 and p2_locked:
		return "BASE" if p2_selected_form.is_empty() else p2_selected_form.to_upper()
	return "BASE"
