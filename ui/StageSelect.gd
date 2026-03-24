extends Control

const RING_MENU_SCENE: PackedScene = preload("res://ui/components/RingMenu.tscn")
const OPTIONS_CFG_PATH: String = "user://options.cfg"
const OPTIONS_SECTION_STAGE: String = "stage_select"

@export var stages_roots: Array[String] = ["user://stages/", "res://stages/"]
@export var music_scan_roots: Array[String] = ["user://sounds/", "res://sounds/"]
@export var training_scene_path: String = "res://stages/TestArena.tscn"
@export var tournament_bracket_scene_path: String = "res://ui/TournamentBracket.tscn"
@export var grid_columns: int = 5
@export var use_stage_ring_menu: bool = false

@onready var instruction_label: Label = $MarginContainer/VBoxContainer/InstructionLabel
@onready var stage_preview: TextureRect = $MarginContainer/VBoxContainer/PreviewPanel/PreviewRow/StagePreview
@onready var selected_stage_label: Label = $MarginContainer/VBoxContainer/PreviewPanel/PreviewRow/PreviewInfo/SelectedStageLabel
@onready var cursor_hint_label: Label = $MarginContainer/VBoxContainer/PreviewPanel/PreviewRow/PreviewInfo/CursorHintLabel
@onready var bgm_option_button: OptionButton = $MarginContainer/VBoxContainer/PreviewPanel/PreviewRow/PreviewInfo/BgmRow/BgmOptionButton
@onready var grid_container: Control = $MarginContainer/VBoxContainer/GridPanel/GridScroll/GridContainer
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var back_button: Button = $MarginContainer/VBoxContainer/BottomRow/BackButton

var game_mode: String = "training"
var stage_entries: Array[Dictionary] = []
var stage_tiles: Array[Dictionary] = []
var tile_buttons: Array[Button] = []
var cursor_index: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var stage_locked: bool = false
var stage_locked_index: int = -1
var preview_viewport: SubViewport = null
var preview_stage_root: Node3D = null
var preview_model: Node3D = null
var preview_camera: Camera3D = null
var stage_ring_menu: RingMenu = null
var stage_ring_syncing: bool = false
var _bgm_populate_syncing: bool = false


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	UISkin.attach_focus_arrow(self)
	UISkin.apply_background(self, "stage_select_bg")
	SystemSFX.play_menu_music_from(self, "mapsel", true, -8.0)
	rng.randomize()
	back_button.pressed.connect(_on_back_pressed)
	_setup_3d_preview()
	_resolve_mode()
	_scan_stages()
	_build_stage_tiles()
	_build_stage_grid()
	if bgm_option_button != null:
		bgm_option_button.item_selected.connect(_on_bgm_item_selected)
	_populate_bgm_options()
	if use_stage_ring_menu:
		_setup_stage_ring_menu()
	else:
		if grid_container != null:
			grid_container.visible = true
	_refresh_ui()


func _unhandled_input(event: InputEvent) -> void:
	if stage_tiles.is_empty():
		return
	if _event_action_pressed(event, &"ui_cancel") or _event_action_pressed(event, &"p1_k"):
		if stage_locked:
			_unlock_stage_selection()
		else:
			_on_back_pressed()
		return
	if stage_locked and _event_action_pressed(event, &"p1_p"):
		_start_selected_stage()
		return
	if stage_locked:
		return
	if _event_action_pressed(event, &"p1_up") or _event_action_pressed(event, &"p1_left"):
		_move_cursor(-1, 0)
	elif _event_action_pressed(event, &"p1_down") or _event_action_pressed(event, &"p1_right"):
		_move_cursor(1, 0)
	elif _event_action_pressed(event, &"p1_h"):
		if stage_ring_menu != null:
			stage_ring_menu.previous_page()
		_refresh_ui()
	elif _event_action_pressed(event, &"p1_s"):
		if stage_ring_menu != null:
			stage_ring_menu.next_page()
		_refresh_ui()
	elif _event_action_pressed(event, &"p1_p"):
		_lock_stage_selection()


func _event_action_pressed(event: InputEvent, action: StringName) -> bool:
	if not InputMap.has_action(action):
		return false
	return event.is_action_pressed(action)


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
	match game_mode:
		"arcade":
			instruction_label.text = "Arcade Mode"
		"survival":
			instruction_label.text = "Survival Mode"
		"versus":
			instruction_label.text = "2P Versus"
		"team":
			instruction_label.text = "Team Mode"
		"smash":
			instruction_label.text = "Smash Mode"
		"watch":
			instruction_label.text = "Watch Mode"
		"coop":
			instruction_label.text = "Co-op vs CPU"
		"tournament":
			instruction_label.text = "Tournament - Select stage"
		"online":
			instruction_label.text = "Online"
		"cpu_training":
			instruction_label.text = "CPU Training"
		_:
			instruction_label.text = "Training Mode"


func _scan_stages() -> void:
	stage_entries.clear()
	for entry in ContentResolver.scan_stage_entries(stages_roots):
		var folder_path: String = str(entry.get("folder_path", ""))
		stage_entries.append(
			{
				"name": str(entry.get("name", "")),
				"display_name": str(entry.get("display_name", entry.get("name", ""))),
				"folder_path": folder_path,
				"preview_texture": _load_stage_preview_texture(folder_path),
				"stage_def": entry.get("stage_def", {}),
				"model_path": str(entry.get("model_path", ""))
			}
		)
	stage_entries.sort_custom(
		func(a, b): return str(a.get("display_name", a.get("name", ""))) < str(b.get("display_name", b.get("name", "")))
	)


func _build_stage_tiles() -> void:
	stage_tiles.clear()
	for entry in stage_entries:
		stage_tiles.append({"kind": "stage", "entry": entry})
	if not stage_entries.is_empty():
		stage_tiles.append({"kind": "random"})
	cursor_index = 0


func _build_stage_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	tile_buttons.clear()
	if grid_container is GridContainer:
		(grid_container as GridContainer).columns = maxi(1, grid_columns)
	for idx in range(stage_tiles.size()):
		var tile: Dictionary = stage_tiles[idx]
		var button := Button.new()
		button.custom_minimum_size = Vector2(128, 84)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if str(tile.get("kind", "")) == "stage":
			var entry: Dictionary = tile.get("entry", {})
			var preview_tex: Texture2D = entry.get("preview_texture", null)
			button.tooltip_text = str(entry.get("display_name", entry.get("name", "Unknown Stage")))
			if preview_tex != null:
				button.icon = preview_tex
				button.expand_icon = true
				button.text = ""
			else:
				button.text = _tile_title(tile)
		else:
			button.tooltip_text = "Random"
			button.text = "RANDOM"
		button.pressed.connect(_on_stage_tile_pressed.bind(idx))
		grid_container.add_child(button)
		tile_buttons.append(button)


func _on_stage_tile_pressed(index: int) -> void:
	cursor_index = clampi(index, 0, stage_tiles.size() - 1)
	if stage_ring_menu != null:
		stage_ring_menu.set_selected_index(cursor_index)
	if stage_locked:
		if cursor_index == stage_locked_index:
			_start_selected_stage()
			return
		_unlock_stage_selection()
	_lock_stage_selection()


func _move_cursor(dx: int, dy: int) -> void:
	var count: int = stage_tiles.size()
	if count <= 0:
		return
	var step: int = dx if dx != 0 else dy
	cursor_index = wrapi(cursor_index + step, 0, count)
	if stage_ring_menu != null:
		stage_ring_menu.set_selected_index(cursor_index)
	SystemSFX.play_ui_from(self, "ui_move")
	_refresh_ui()


func _refresh_ui() -> void:
	_rebuild_stage_ring_items()
	for idx in range(tile_buttons.size()):
		var button: Button = tile_buttons[idx]
		var title: String = _tile_title(stage_tiles[idx])
		var markers: Array[String] = []
		if idx == cursor_index and not stage_locked:
			markers.append("CURSOR")
		if stage_locked and idx == stage_locked_index:
			markers.append("READY")
		if markers.is_empty():
			if button.icon == null:
				button.text = title
			else:
				button.text = ""
		else:
			if button.icon == null:
				button.text = "%s\n[%s]" % [title, ",".join(markers)]
			else:
				button.text = "[%s]" % ",".join(markers)

	if stage_tiles.is_empty():
		selected_stage_label.text = "Stage: None"
		stage_preview.texture = null
		status_label.text = "No stages found in user://stages/ or res://stages/"
		return
	var tile: Dictionary = stage_tiles[cursor_index]
	var kind: String = str(tile.get("kind", ""))
	if kind == "stage":
		var entry: Dictionary = tile.get("entry", {})
		if stage_locked:
			selected_stage_label.text = "Stage: %s (Ready)" % str(entry.get("display_name", entry.get("name", "Unknown")))
		else:
			selected_stage_label.text = "Stage: %s" % str(entry.get("display_name", entry.get("name", "Unknown")))
		_update_stage_preview(entry)
	else:
		selected_stage_label.text = "Stage: Random%s" % (" (Ready)" if stage_locked else "")
		_clear_stage_preview_model()
		stage_preview.texture = null

	if stage_locked:
		status_label.text = "Stage locked. Press Attack(P) again when ready, or Kick(K) to change."
	elif game_mode == "arcade":
		status_label.text = "Pick a stage for Arcade."
	elif game_mode == "survival":
		status_label.text = "Pick a stage for Survival."
	elif game_mode == "versus":
		status_label.text = "Pick a stage for 2P Versus."
	elif game_mode == "team":
		status_label.text = "Pick a stage for Team Mode."
	elif game_mode == "smash":
		status_label.text = "Pick a stage for Smash."
	elif game_mode == "watch":
		status_label.text = "Pick a stage for Watch Mode."
	else:
		status_label.text = "Pick a stage for Training."
	cursor_hint_label.text = "Move: P1 directions | Select/Ready: P1 attack | Back/Unready: Esc or P1 Kick"


func _setup_stage_ring_menu() -> void:
	if not use_stage_ring_menu:
		return
	var ring_instance: Node = RING_MENU_SCENE.instantiate()
	if not (ring_instance is RingMenu):
		return
	stage_ring_menu = ring_instance as RingMenu
	stage_ring_menu.name = "StageRingMenu"
	stage_ring_menu.radius = 230.0
	stage_ring_menu.item_min_size = Vector2(136, 82)
	stage_ring_menu.max_items_per_page = 10
	$MarginContainer/VBoxContainer/GridPanel.add_child(stage_ring_menu)
	grid_container.visible = false
	stage_ring_menu.selection_changed.connect(_on_stage_ring_selection_changed)
	stage_ring_menu.item_confirmed.connect(_on_stage_ring_item_confirmed)
	_rebuild_stage_ring_items()


func _rebuild_stage_ring_items() -> void:
	if stage_ring_menu == null:
		return
	stage_ring_syncing = true
	var items: Array[Dictionary] = []
	for idx in range(stage_tiles.size()):
		var tile: Dictionary = stage_tiles[idx]
		var title: String = _tile_title(tile)
		var label: String = title
		if idx == cursor_index and not stage_locked:
			label = "%s\n[CURSOR]" % title
		if stage_locked and idx == stage_locked_index:
			label = "%s\n[READY]" % title
		var icon_tex: Texture2D = null
		if str(tile.get("kind", "")) == "stage":
			var entry: Dictionary = tile.get("entry", {})
			icon_tex = entry.get("preview_texture", null)
		items.append({"label": label, "icon": icon_tex})
	stage_ring_menu.set_items(items)
	stage_ring_menu.set_selected_index(cursor_index)
	stage_ring_syncing = false


func _on_stage_ring_selection_changed(index: int) -> void:
	if stage_ring_syncing:
		return
	if stage_tiles.is_empty():
		return
	cursor_index = clampi(index, 0, stage_tiles.size() - 1)
	_refresh_ui()


func _on_stage_ring_item_confirmed(index: int) -> void:
	cursor_index = clampi(index, 0, max(0, stage_tiles.size() - 1))
	_on_stage_tile_pressed(cursor_index)


func _lock_stage_selection() -> void:
	if stage_tiles.is_empty():
		return
	stage_locked = true
	stage_locked_index = cursor_index
	SystemSFX.play_ui_from(self, "ui_confirm")
	_refresh_ui()


func _unlock_stage_selection() -> void:
	stage_locked = false
	stage_locked_index = -1
	SystemSFX.play_ui_from(self, "ui_back")
	_refresh_ui()


func _start_selected_stage() -> void:
	if stage_tiles.is_empty():
		return
	var resolved: Dictionary = _resolve_selected_stage_entry()
	var folder_path: String = str(resolved.get("folder_path", ""))
	if folder_path.is_empty():
		return
	SystemSFX.play_ui_from(self, "ui_confirm")
	var music_path: String = _get_selected_bgm_path()
	if game_mode == "online":
		if NetworkManager.is_host():
			var p2_mod: String = NetworkManager.get_opponent_character()
			if p2_mod.is_empty():
				if status_label != null:
					status_label.text = "Waiting for opponent to pick character..."
				return
			get_tree().set_meta("training_stage_folder", folder_path)
			get_tree().set_meta("training_stage_music_path", music_path)
			NetworkManager.start_battle_and_go(
				str(get_tree().get_meta("training_p1_mod", "")),
				p2_mod,
				folder_path,
				training_scene_path,
				music_path
			)
		else:
			if status_label != null:
				status_label.text = "Waiting for host to start..."
		return
	get_tree().set_meta("training_stage_folder", folder_path)
	get_tree().set_meta("training_stage_music_path", music_path)
	if game_mode == "tournament":
		get_tree().change_scene_to_file(tournament_bracket_scene_path)
	else:
		get_tree().change_scene_to_file(training_scene_path)


func _resolve_selected_stage_entry() -> Dictionary:
	var idx: int = stage_locked_index if stage_locked and stage_locked_index >= 0 else cursor_index
	idx = clampi(idx, 0, stage_tiles.size() - 1)
	var tile: Dictionary = stage_tiles[idx]
	if str(tile.get("kind", "")) == "stage":
		return tile.get("entry", {})
	if stage_entries.is_empty():
		return {}
	var random_idx: int = rng.randi_range(0, stage_entries.size() - 1)
	return stage_entries[random_idx]


func _tile_title(tile: Dictionary) -> String:
	if str(tile.get("kind", "")) == "stage":
		var entry: Dictionary = tile.get("entry", {})
		return str(entry.get("display_name", entry.get("name", "Unknown Stage")))
	return "RANDOM"


func _on_back_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_back")
	get_tree().change_scene_to_file("res://ui/CharacterSelect.tscn")


func _is_stage_folder(folder_path: String) -> bool:
	return ContentResolver.is_stage_folder(folder_path)


func _load_stage_preview_texture(folder_path: String) -> Texture2D:
	var candidates: Array[String] = [
		"%s/preview.png" % folder_path,
		"%s/Preview.png" % folder_path,
		"%s/icon.png" % folder_path,
		"%s/Icon.png" % folder_path
	]
	for candidate in candidates:
		var tex: Texture2D = _load_texture_from_path(candidate)
		if tex != null:
			return tex
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


func _normalize_root(root: String) -> String:
	var normalized: String = root.strip_edges()
	if normalized.is_empty():
		return ""
	if not normalized.ends_with("/"):
		normalized += "/"
	return normalized


func _setup_3d_preview() -> void:
	preview_viewport = SubViewport.new()
	preview_viewport.disable_3d = false
	preview_viewport.transparent_bg = true
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_viewport.size = Vector2i(512, 320)
	add_child(preview_viewport)
	preview_stage_root = Node3D.new()
	preview_viewport.add_child(preview_stage_root)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-34.0, 44.0, 0.0)
	preview_stage_root.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-3.0, 4.0, 3.0)
	fill_light.light_energy = 0.65
	preview_stage_root.add_child(fill_light)
	preview_camera = Camera3D.new()
	preview_camera.position = Vector3(0.0, 3.0, 8.0)
	preview_stage_root.add_child(preview_camera)
	preview_camera.look_at_from_position(preview_camera.position, Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _update_stage_preview(entry: Dictionary) -> void:
	_clear_stage_preview_model()
	if preview_viewport == null or not is_instance_valid(preview_viewport):
		stage_preview.texture = entry.get("preview_texture", null)
		return
	var model_path: String = str(entry.get("model_path", ""))
	if model_path.is_empty():
		stage_preview.texture = entry.get("preview_texture", null)
		return
	var model_root: Node3D = _instantiate_stage_model(model_path)
	if model_root == null:
		stage_preview.texture = entry.get("preview_texture", null)
		return
	var stage_def: Dictionary = entry.get("stage_def", {})
	model_root.position = _parse_vec3(stage_def.get("stage_offset", Vector3.ZERO), Vector3.ZERO)
	model_root.rotation_degrees = _parse_vec3(stage_def.get("stage_rotation", Vector3.ZERO), Vector3.ZERO)
	model_root.scale = _parse_vec3(stage_def.get("stage_scale", Vector3.ONE), Vector3.ONE)
	preview_stage_root.add_child(model_root)
	preview_model = model_root
	var camera_pos: Vector3 = _parse_vec3(stage_def.get("camera_position", Vector3(0.0, 3.0, 8.0)), Vector3(0.0, 3.0, 8.0))
	var look_target: Vector3 = _parse_vec3(stage_def.get("camera_look_target", Vector3(0.0, 1.0, 0.0)), Vector3(0.0, 1.0, 0.0))
	if preview_camera != null and is_instance_valid(preview_camera):
		preview_camera.position = camera_pos
		preview_camera.look_at_from_position(preview_camera.position, look_target, Vector3.UP)
	stage_preview.texture = preview_viewport.get_texture()


func _clear_stage_preview_model() -> void:
	if preview_model != null and is_instance_valid(preview_model):
		preview_model.queue_free()
	preview_model = null


func _instantiate_stage_model(model_path: String) -> Node3D:
	if model_path.is_empty():
		return null
	var lower: String = model_path.to_lower()
	if model_path.begins_with("res://"):
		var loaded := ResourceLoader.load(model_path)
		if loaded is PackedScene:
			var node := (loaded as PackedScene).instantiate()
			if node is Node3D:
				return node as Node3D
	if lower.ends_with(".glb") or lower.ends_with(".gltf"):
		var gltf_scene: Node = _load_gltf_scene_any_path(model_path)
		if gltf_scene is Node3D:
			return gltf_scene as Node3D
	return null


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


func _load_stage_def(path: String) -> Dictionary:
	return ContentResolver.load_stage_def(path)


func _find_stage_model_file(folder_path: String, stage_def: Dictionary = {}) -> String:
	return ContentResolver.find_stage_model_path(folder_path, stage_def)


func _resolve_stage_relative_path(folder_path: String, raw_path: String) -> String:
	if raw_path.begins_with("res://") or raw_path.begins_with("user://"):
		return raw_path
	return "%s/%s" % [folder_path, raw_path]


func _can_load_stage_model(path: String) -> bool:
	if path.is_empty():
		return false
	if path.begins_with("res://"):
		if ResourceLoader.exists(path):
			return true
	var abs_path: String = ProjectSettings.globalize_path(path)
	return FileAccess.file_exists(abs_path)


func _parse_vec3(raw_value, fallback: Vector3) -> Vector3:
	if raw_value is Vector3:
		return raw_value
	var raw: String = str(raw_value).replace("(", "").replace(")", "")
	var parts: PackedStringArray = raw.split(",", false)
	if parts.size() < 3:
		return fallback
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))


func _populate_bgm_options() -> void:
	if bgm_option_button == null:
		return
	_bgm_populate_syncing = true
	bgm_option_button.clear()
	bgm_option_button.add_item("Stage default (stage.def)", 0)
	bgm_option_button.set_item_metadata(0, "")
	var tracks: Array[Dictionary] = ContentResolver.scan_music_track_entries(music_scan_roots)
	for t in tracks:
		var p: String = str(t.get("path", ""))
		var lbl: String = str(t.get("label", p))
		if p.is_empty():
			continue
		var id: int = bgm_option_button.get_item_count()
		bgm_option_button.add_item(lbl, id)
		bgm_option_button.set_item_metadata(id, p)
	var saved: String = _load_saved_stage_music_path().strip_edges()
	if not _select_bgm_by_path(saved) and bgm_option_button.get_item_count() > 0:
		bgm_option_button.select(0)
	_bgm_populate_syncing = false


func _select_bgm_by_path(path: String) -> bool:
	if bgm_option_button == null:
		return false
	if path.is_empty():
		bgm_option_button.select(0)
		return true
	for i in range(bgm_option_button.get_item_count()):
		var meta = bgm_option_button.get_item_metadata(i)
		if str(meta).strip_edges() == path:
			bgm_option_button.select(i)
			return true
	return false


func _get_selected_bgm_path() -> String:
	if bgm_option_button == null:
		return ""
	var idx: int = bgm_option_button.selected
	if idx < 0:
		return ""
	var meta = bgm_option_button.get_item_metadata(idx)
	if meta == null:
		return ""
	return str(meta).strip_edges()


func _load_saved_stage_music_path() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(OPTIONS_CFG_PATH) != OK:
		return ""
	return str(cfg.get_value(OPTIONS_SECTION_STAGE, "stage_music_path", ""))


func _save_stage_music_path(path: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(OPTIONS_CFG_PATH)
	cfg.set_value(OPTIONS_SECTION_STAGE, "stage_music_path", path)
	cfg.save(OPTIONS_CFG_PATH)


func _on_bgm_item_selected(_index: int) -> void:
	if _bgm_populate_syncing:
		return
	_save_stage_music_path(_get_selected_bgm_path())
