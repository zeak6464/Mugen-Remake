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
var p1_roster_cursor_marker: Control = null
var p1_panel: Panel = null

var p2_ui: Control = null
var p2_team_slots: Control = null
var p2_cursor_label: Label = null
var p2_roster_row: Control = null
var p2_roster_scroll: Control = null
var p2_roster_cursor_marker: Control = null
var p2_panel: Panel = null

var p1_folder_panel: Panel = null
var p1_folder_title_label: Label = null
var p1_variant_row: Control = null
var p2_folder_panel: Panel = null
var p2_folder_title_label: Label = null
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

const ROSTER_PAGE_SIZE: int = 8

var game_mode: String = "training"
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


func _control_player_for_input(event: InputEvent) -> int:
	if game_mode == "watch":
		# In watch mode, one controller drafts both sides.
		# Route confirm/move to whichever side is currently active.
		if _pressed(event, &"p1_up") or _pressed(event, &"p1_down") or _pressed(event, &"p1_left") or _pressed(event, &"p1_right") or _pressed(event, &"p1_p") or _pressed(event, &"p1_k") or _pressed(event, &"p1_s") or _pressed(event, &"p1_h"):
			return active_player
		if _pressed(event, &"p2_up") or _pressed(event, &"p2_down") or _pressed(event, &"p2_left") or _pressed(event, &"p2_right") or _pressed(event, &"p2_p") or _pressed(event, &"p2_k") or _pressed(event, &"p2_s") or _pressed(event, &"p2_h"):
			return active_player
		return 0
	if _pressed(event, &"p2_up") or _pressed(event, &"p2_down") or _pressed(event, &"p2_left") or _pressed(event, &"p2_right") or _pressed(event, &"p2_p") or _pressed(event, &"p2_k") or _pressed(event, &"p2_s") or _pressed(event, &"p2_h"):
		return 2
	if _pressed(event, &"p1_up") or _pressed(event, &"p1_down") or _pressed(event, &"p1_left") or _pressed(event, &"p1_right") or _pressed(event, &"p1_p") or _pressed(event, &"p1_k") or _pressed(event, &"p1_s") or _pressed(event, &"p1_h"):
		return 1
	return 0


func _resolve_mode() -> void:
	game_mode = str(get_tree().get_meta("game_mode", "training")).to_lower()
	if game_mode != "arcade" and game_mode != "versus" and game_mode != "smash" and game_mode != "team" and game_mode != "survival" and game_mode != "watch":
		game_mode = "training"
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
			_set_label_text(instruction_label, "Watch Mode - P1 drafts both CPU teams")
			_set_label_text(mode_label, "WATCH")
		_:
			_set_label_text(instruction_label, "Training Mode - P1 Draft")
			_set_label_text(mode_label, "TRAINING")


func _uses_dual_player() -> bool:
	return game_mode == "versus" or game_mode == "smash" or game_mode == "team" or game_mode == "watch"


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
				"forms": forms,
				"forms_data": forms_data,
				"costumes_data": _load_mod_costumes_data(mod_path),
				"icon_texture": _load_mod_icon_texture(mod_path),
				"model_path": str(content_entry.get("model_path", "")),
				"def_data": content_entry.get("def_data", {})
			}
		)
	available_mods.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))


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


func _create_roster_button(mod_entry: Dictionary, player_id: int, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(124, 54)
	var full_name: String = str(mod_entry.get("name", "Unknown"))
	button.text = _short_roster_name(full_name.to_upper(), 11)
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
	var forms: Array[String] = mod_entry.get("forms", [])
	var total: int = 1 + forms.size() # Base + forms
	folder_variant_index = wrapi(folder_variant_index + delta, 0, total)
	SystemSFX.play_ui_from(self, "ui_move")
	_refresh_ui()


func _confirm_player(player_id: int) -> void:
	if player_id == 2 and not _uses_dual_player():
		return
	if _is_player_locked(player_id):
		if _all_required_locked():
			_commit_selection()
		return
	var cursor_index: int = _get_cursor(player_id)
	if not folder_open or folder_player != player_id or folder_mod_index != cursor_index:
		_open_folder(player_id, cursor_index)
		SystemSFX.play_ui_from(self, "ui_move")
		_refresh_ui()
		return
	_commit_folder_pick(player_id)


func _commit_folder_pick(player_id: int) -> void:
	if folder_mod_index < 0 or folder_mod_index >= available_mods.size():
		return
	var mod_entry: Dictionary = available_mods[folder_mod_index]
	var mod_name: String = str(mod_entry.get("name", ""))
	if mod_name.is_empty():
		return
	var form_id: String = _folder_selected_form(mod_entry)
	var costume_id: String = ""

	if game_mode == "team":
		var roster: Array[Dictionary] = p1_team_roster if player_id == 1 else p2_team_roster
		var size_limit: int = team_size_p1 if player_id == 1 else team_size_p2
		if roster.size() < size_limit:
			roster.append({"mod": mod_name, "form": form_id, "costume": costume_id})
		if player_id == 1:
			p1_team_roster = roster
			p1_selected_mod = mod_name
			p1_selected_form = form_id
			p1_selected_costume = costume_id
			p1_locked = p1_team_roster.size() >= team_size_p1
		else:
			p2_team_roster = roster
			p2_selected_mod = mod_name
			p2_selected_form = form_id
			p2_selected_costume = costume_id
			p2_locked = p2_team_roster.size() >= team_size_p2
	else:
		if player_id == 1:
			p1_selected_mod = mod_name
			p1_selected_form = form_id
			p1_selected_costume = costume_id
			p1_locked = true
		else:
			p2_selected_mod = mod_name
			p2_selected_form = form_id
			p2_selected_costume = costume_id
			p2_locked = true

	_close_folder()
	if game_mode == "watch" and not _all_required_locked():
		active_player = 2 if p1_locked else 1
	SystemSFX.play_ui_from(self, "ui_confirm")
	_refresh_ui()


func _handle_cancel() -> void:
	if folder_open:
		_close_folder()
		SystemSFX.play_ui_from(self, "ui_back")
		_refresh_ui()
		return
	if active_player == 1 and p1_locked:
		p1_locked = false
		if game_mode == "team" and not p1_team_roster.is_empty():
			p1_team_roster.remove_at(p1_team_roster.size() - 1)
		if game_mode == "watch":
			active_player = 1
		SystemSFX.play_ui_from(self, "ui_back")
		_refresh_ui()
		return
	if _uses_dual_player() and active_player == 2 and p2_locked:
		p2_locked = false
		if game_mode == "team" and not p2_team_roster.is_empty():
			p2_team_roster.remove_at(p2_team_roster.size() - 1)
		if game_mode == "watch":
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


func _close_folder() -> void:
	folder_open = false
	folder_mod_index = -1
	folder_variant_index = 0


func _folder_selected_form(mod_entry: Dictionary) -> String:
	var forms: Array[String] = mod_entry.get("forms", [])
	if folder_variant_index <= 0:
		return ""
	var idx: int = folder_variant_index - 1
	if idx < 0 or idx >= forms.size():
		return ""
	return forms[idx]


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
	if game_mode == "team":
		return p1_locked and p2_locked
	if _uses_dual_player():
		return p1_locked and p2_locked
	return p1_locked


func _refresh_ui() -> void:
	_refresh_roster_markers()
	_refresh_team_slots(p1_team_slots, p1_team_roster, team_size_p1, "P1")
	_refresh_team_slots(p2_team_slots, p2_team_roster, team_size_p2, "P2")

	var p1_prefix: String = ">> " if active_player == 1 else ""
	var p2_prefix: String = ">> " if active_player == 2 and _uses_dual_player() else ""
	var p1_pages_total: int = _roster_total_pages()
	var p2_pages_total: int = _roster_total_pages()
	_set_label_text(
		p1_cursor_label,
		"%sP1  %s  FORM %s%s  PAGE %d/%d"
		% [p1_prefix, _mod_name_at(p1_cursor_index), _current_form_display_name(1), " [LOCKED]" if p1_locked else "", p1_page_index + 1, p1_pages_total]
	)
	_set_label_text(
		p2_cursor_label,
		"%sP2  %s  FORM %s%s  PAGE %d/%d"
		% [p2_prefix, _mod_name_at(p2_cursor_index), _current_form_display_name(2), " [LOCKED]" if p2_locked else "", p2_page_index + 1, p2_pages_total]
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
		if p1_locked and p1_selected_mod == _mod_name_at(i):
			tags.append("LOCK")
		var base_name: String = _mod_name_at(i)
		b.text = _short_roster_name(base_name.to_upper(), 11)
		b.tooltip_text = "%s%s" % [base_name, "" if tags.is_empty() else " [%s]" % ",".join(tags)]

	for i in range(p2_roster_buttons.size()):
		var b: Button = p2_roster_buttons[i]
		var tags: Array[String] = []
		if _uses_dual_player() and i == p2_cursor_index:
			tags.append("P2")
		if folder_open and folder_player == 2 and i == folder_mod_index:
			tags.append("OPEN")
		if p2_locked and p2_selected_mod == _mod_name_at(i):
			tags.append("LOCK")
		var base_name: String = _mod_name_at(i)
		b.text = _short_roster_name(base_name.to_upper(), 11)
		b.tooltip_text = "%s%s" % [base_name, "" if tags.is_empty() else " [%s]" % ",".join(tags)]
	call_deferred("_refresh_visual_roster_cursors")


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
	var needed: int = size_required if game_mode == "team" else 2
	for i in range(needed):
		var slot := Label.new()
		slot.custom_minimum_size = Vector2(118, 28)
		if i < roster.size():
			var entry: Dictionary = roster[i]
			var mod_name: String = str(entry.get("mod", "--"))
			var form_name: String = str(entry.get("form", ""))
			slot.text = "%s%s" % [mod_name, "" if form_name.is_empty() else " (%s)" % form_name]
		else:
			slot.text = "%s Slot %d" % [player_label, i + 1]
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		container.add_child(slot)


func _refresh_folder_panel() -> void:
	_refresh_folder_panel_for_player(1, p1_folder_panel, p1_folder_title_label, p1_variant_row, p1_variant_buttons)
	if _uses_dual_player():
		_refresh_folder_panel_for_player(2, p2_folder_panel, p2_folder_title_label, p2_variant_row, p2_variant_buttons)
	else:
		if p2_folder_panel != null:
			p2_folder_panel.visible = false


func _refresh_folder_panel_for_player(player_id: int, panel: Panel, title_label: Label, row: Control, cache: Array[Button]) -> void:
	if panel == null or row == null:
		return
	for child in row.get_children():
		child.queue_free()
	cache.clear()

	var cursor_index: int = _get_cursor(player_id)
	if cursor_index < 0 or cursor_index >= available_mods.size():
		panel.visible = false
		return
	panel.visible = true
	var mod_entry: Dictionary = available_mods[cursor_index]
	_set_label_text(
		title_label,
		"P%d: %s Forms  |  Current: %s  |  H/S or click to change, Attack(P) to confirm"
		% [player_id, str(mod_entry.get("name", "Character")), _current_form_display_name(player_id)]
	)

	var labels: Array[String] = ["Base"]
	var forms: Array[String] = mod_entry.get("forms", [])
	for form_id in forms:
		labels.append(str(form_id))

	var selected_idx: int = 0
	if folder_open and folder_player == player_id and folder_mod_index == cursor_index:
		selected_idx = folder_variant_index
	elif player_id == 1 and p1_locked:
		selected_idx = _form_index_for_player(mod_entry, p1_selected_form)
	elif player_id == 2 and p2_locked:
		selected_idx = _form_index_for_player(mod_entry, p2_selected_form)

	for i in range(labels.size()):
		var b := Button.new()
		b.custom_minimum_size = Vector2(106, 30)
		var label_text: String = labels[i]
		if i == selected_idx:
			label_text = "> %s <" % label_text
		b.text = label_text
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_variant_pressed.bind(player_id, i))
		row.add_child(b)
		cache.append(b)
	var forms_width: float = maxf(0.0, (106.0 * labels.size()) + (8.0 * max(0, labels.size() - 1)))
	row.custom_minimum_size = Vector2(forms_width, 30.0)
	call_deferred("_scroll_variant_row_to_selected", row, selected_idx)


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
	folder_variant_index = index
	SystemSFX.play_ui_from(self, "ui_move")
	_refresh_ui()


func _refresh_player_preview_model(player_id: int) -> void:
	var cursor_index: int = _get_cursor(player_id)
	if cursor_index < 0 or cursor_index >= available_mods.size():
		_clear_preview_model(player_id)
		return
	var mod_entry: Dictionary = available_mods[cursor_index]
	var form_id: String = ""
	if folder_open and folder_player == player_id and folder_mod_index == cursor_index:
		form_id = _folder_selected_form(mod_entry)
	elif player_id == 1 and p1_locked:
		form_id = p1_selected_form
	elif player_id == 2 and p2_locked:
		form_id = p2_selected_form

	_clear_preview_model(player_id)
	var model_root: Node3D = _instantiate_preview_model(mod_entry, form_id, "")
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
	else:
		p2_preview_model = model_root
	_sync_preview_viewport_sizes()
	if preview_tex != null:
		preview_tex.texture = viewport.get_texture()


func _refresh_overlay_and_status() -> void:
	if lock_overlay != null:
		lock_overlay.visible = _all_required_locked()
		if lock_overlay.visible:
			_set_label_text(lock_overlay_label, "Teams locked. Press Attack(P) to continue.")
	if folder_open:
		_set_label_text(
			status_label,
			"Folder open: current form is %s. Use H/S or click to change forms, then press Attack(P) to lock it."
			% _current_form_display_name(folder_player)
		)
	elif game_mode == "team":
		_set_label_text(status_label, "Team draft: open a character folder, choose the form, and lock each team slot.")
	else:
		_set_label_text(status_label, "Attack(P) opens the character folder, then Attack(P) locks the highlighted Base/Form.")


func _mod_name_at(index: int) -> String:
	if index < 0 or index >= available_mods.size():
		return "Unknown"
	return str(available_mods[index].get("name", "Unknown"))


func _commit_selection() -> void:
	if p1_selected_mod.is_empty() and not available_mods.is_empty():
		p1_selected_mod = str(available_mods[0].get("name", ""))

	if game_mode == "team":
		if p1_team_roster.is_empty() and not p1_selected_mod.is_empty():
			p1_team_roster.append({"mod": p1_selected_mod, "form": p1_selected_form, "costume": p1_selected_costume})
		if p2_team_roster.is_empty():
			if not p2_selected_mod.is_empty():
				p2_team_roster.append({"mod": p2_selected_mod, "form": p2_selected_form, "costume": p2_selected_costume})
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

	var p2_mod_name: String = p2_selected_mod
	var p2_form_name: String = p2_selected_form
	var p2_costume_name: String = p2_selected_costume
	match game_mode:
		"arcade", "survival":
			p2_mod_name = _pick_arcade_opponent(p1_selected_mod)
			p2_form_name = ""
			p2_costume_name = ""
		"training":
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


func _pick_arcade_opponent(player_mod: String) -> String:
	for entry in available_mods:
		var mod_name: String = str(entry.get("name", ""))
		if mod_name != player_mod:
			return mod_name
	return player_mod


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
	var model_scene: Node = null
	var lower_path: String = model_path.to_lower()
	var is_gltf: bool = lower_path.ends_with(".gltf") or lower_path.ends_with(".glb")
	# user:// gltf files must go through GLTFDocument directly, not ResourceLoader.
	if is_gltf:
		model_scene = _load_gltf_scene_any_path(model_path)
	else:
		var model_res: Resource = ResourceLoader.load(model_path)
		if model_res is PackedScene:
			model_scene = (model_res as PackedScene).instantiate()
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
				player.play(names[0])
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

	p1_folder_panel = _find_node_by_name("CharacterFolderPanelP1") as Panel
	p1_folder_title_label = _find_node_by_name("FolderTitleP1") as Label
	p1_variant_row = _find_node_by_name("VariantRowP1") as Control
	p2_folder_panel = _find_node_by_name("CharacterFolderPanelP2") as Panel
	p2_folder_title_label = _find_node_by_name("FolderTitleP2") as Label
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
