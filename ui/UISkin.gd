extends RefCounted
class_name UISkin

const SKIN_ROOT: String = "user://ui-skin/"
const TEXTURES_DIR: String = "user://ui-skin/textures/"
const UI_AUDIO_DIR: String = "user://ui-skin/audio/ui/"
const BATTLE_AUDIO_DIR: String = "user://ui-skin/audio/battle/"
const IMAGE_EXTS: Array[String] = [".png", ".webp", ".jpg", ".jpeg"]
const AUDIO_EXTS: Array[String] = [".ogg", ".wav", ".mp3"]
static func ensure_skin_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEXTURES_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(UI_AUDIO_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BATTLE_AUDIO_DIR))


static func _find_existing_file(base_path_no_ext: String, exts: Array[String]) -> String:
	for ext in exts:
		var candidate: String = "%s%s" % [base_path_no_ext, ext]
		if FileAccess.file_exists(candidate):
			return candidate
	return ""


static func load_texture(texture_name: String) -> Texture2D:
	ensure_skin_dirs()
	var normalized: String = texture_name.strip_edges()
	if normalized.is_empty():
		return null
	var path_no_ext: String = "%s%s" % [TEXTURES_DIR, normalized]
	var image_path: String = _find_existing_file(path_no_ext, IMAGE_EXTS)
	if image_path.is_empty():
		return null
	var tex = load(image_path)
	return tex as Texture2D if tex is Texture2D else null


static func get_audio_stream(category: String, event_id: String):
	ensure_skin_dirs()
	var cat: String = category.strip_edges().to_lower()
	var event_name: String = event_id.strip_edges()
	if event_name.is_empty():
		return null
	var base_dir: String = UI_AUDIO_DIR if cat == "ui" else BATTLE_AUDIO_DIR
	var path_no_ext: String = "%s%s" % [base_dir, event_name]
	var audio_path: String = _find_existing_file(path_no_ext, AUDIO_EXTS)
	if audio_path.is_empty():
		return null
	var stream = load(audio_path)
	return stream if stream is AudioStream else null


static func apply_background(root_control: Control, texture_name: String) -> void:
	ensure_ui_fits_screen()
	if root_control == null:
		return
	var tex: Texture2D = load_texture(texture_name)
	var background_color_node: Node = root_control.get_node_or_null("BackgroundColor")
	var skin_bg := root_control.get_node_or_null("SkinBackground") as TextureRect
	if tex == null:
		if skin_bg != null:
			skin_bg.queue_free()
		if background_color_node is CanvasItem:
			(background_color_node as CanvasItem).visible = true
		return
	if skin_bg == null:
		skin_bg = TextureRect.new()
		skin_bg.name = "SkinBackground"
		skin_bg.anchors_preset = Control.PRESET_FULL_RECT
		skin_bg.anchor_left = 0.0
		skin_bg.anchor_top = 0.0
		skin_bg.anchor_right = 1.0
		skin_bg.anchor_bottom = 1.0
		skin_bg.offset_left = 0.0
		skin_bg.offset_top = 0.0
		skin_bg.offset_right = 0.0
		skin_bg.offset_bottom = 0.0
		skin_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		skin_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		skin_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root_control.add_child(skin_bg)
		root_control.move_child(skin_bg, 0)
	skin_bg.texture = tex
	if background_color_node is CanvasItem:
		(background_color_node as CanvasItem).visible = false


static func setup_fighting_game_menu_chrome(root_control: Control) -> void:
	if root_control == null:
		return
	layout_legacy_controls(root_control)


static func attach_focus_arrow(root_control: Control) -> void:
	if root_control == null:
		return
	var arrow := root_control.get_node_or_null("UISkinFocusArrow") as Label
	if arrow == null:
		arrow = Label.new()
		arrow.name = "UISkinFocusArrow"
		arrow.text = "▶"
		arrow.add_theme_font_size_override("font_size", 28)
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.z_index = 200
		arrow.visible = false
		root_control.add_child(arrow)
	var vp := root_control.get_viewport()
	if vp == null:
		return
	# Keep parser-safe across engine patch versions; callers can re-run this on focus moves.
	_update_focus_arrow_position(root_control, arrow, vp.gui_get_focus_owner())


static func _update_focus_arrow_position(root_control: Control, arrow: Label, target: Control) -> void:
	if root_control == null or arrow == null:
		return
	if target == null or not is_instance_valid(target):
		arrow.visible = false
		return
	if not root_control.is_ancestor_of(target):
		arrow.visible = false
		return
	if not target.visible:
		arrow.visible = false
		return
	if target.focus_mode == Control.FOCUS_NONE:
		arrow.visible = false
		return
	var target_rect: Rect2 = target.get_global_rect()
	var root_rect: Rect2 = root_control.get_global_rect()
	var arrow_size: Vector2 = arrow.get_combined_minimum_size()
	if arrow_size.x <= 1.0 or arrow_size.y <= 1.0:
		arrow_size = Vector2(24.0, 24.0)
	arrow.position = Vector2(
		maxf(4.0, target_rect.position.x - root_rect.position.x - 28.0),
		target_rect.position.y - root_rect.position.y + (target_rect.size.y * 0.5) - (arrow_size.y * 0.5)
	)
	arrow.visible = true


static func ensure_ui_fits_screen() -> void:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return
	var tree := main_loop as SceneTree
	if tree.root == null:
		return
	var window: Window = tree.root
	window.min_size = _project_viewport_size()


static func _project_viewport_size() -> Vector2i:
	var width: int = int(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
	var height: int = int(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
	return Vector2i(maxi(1, width), maxi(1, height))


static func layout_legacy_controls(root_control: Control) -> void:
	if root_control == null:
		return
	_layout_legacy_recursive(root_control)


static func _layout_legacy_recursive(node: Node) -> void:
	if node is Control:
		var ctrl := node as Control
		var node_name: String = ctrl.name
		if _is_fill_parent_wrapper(node_name):
			_fill_single_child(ctrl)
		if _is_vertical_layout_node(node_name):
			_layout_vertical(ctrl)
		elif _is_horizontal_layout_node(node_name):
			_layout_horizontal(ctrl)
		elif _is_grid_layout_node(node_name):
			_layout_grid(ctrl, _grid_columns_for_node(ctrl))
	for child in node.get_children():
		_layout_legacy_recursive(child)


static func _is_fill_parent_wrapper(node_name: String) -> bool:
	return node_name in [
		"MarginContainer",
		"Content",
		"CenterContainer",
		"ContentScroll",
		"EditorPanel",
		"KeymapPanel",
		"PreviewPanel",
		"GridPanel",
		"FrameHost",
		"P1Panel",
		"P2Panel",
		"ColumnsRow"
	]


static func _is_vertical_layout_node(node_name: String) -> bool:
	if node_name.ends_with("VBoxContainer"):
		return true
	return node_name in ["MainVBox", "ContentVBox", "P1List", "P2List", "MoveListPanel", "SoundPanel", "TeamModeSubmenu", "CharacterEditorSubmenu"]


static func _is_horizontal_layout_node(node_name: String) -> bool:
	if node_name.ends_with("Row"):
		return true
	return node_name.ends_with("Buttons")


static func _is_grid_layout_node(node_name: String) -> bool:
	return node_name == "FormGrid" or node_name == "GridContainer"


static func _grid_columns_for_node(node: Control) -> int:
	if node.name == "FormGrid":
		if str(node.get_path()).find("StageEditor") >= 0:
			return 6
		return 4
	return 5


static func _fill_single_child(parent: Control) -> void:
	if parent.get_child_count() != 1:
		return
	var child := parent.get_child(0) as Control
	if child == null:
		return
	child.set_anchors_preset(Control.PRESET_FULL_RECT)
	child.offset_left = 0.0
	child.offset_top = 0.0
	child.offset_right = 0.0
	child.offset_bottom = 0.0


static func _layout_vertical(parent: Control) -> void:
	var separation_value: Variant = parent.get("theme_override_constants/separation")
	var separation: float = float(separation_value) if typeof(separation_value) != TYPE_NIL else 8.0
	var x: float = 0.0
	var y: float = 0.0
	var width: float = maxf(0.0, parent.size.x)
	for child in parent.get_children():
		var c := child as Control
		if c == null or not c.visible:
			continue
		var h: float = maxf(30.0, c.custom_minimum_size.y)
		if h <= 30.0:
			h = maxf(30.0, c.size.y)
		c.position = Vector2(x, y)
		c.size = Vector2(width, h)
		y += h + separation
	parent.custom_minimum_size.y = maxf(parent.custom_minimum_size.y, maxf(0.0, y - separation))


static func _layout_horizontal(parent: Control) -> void:
	var separation_value: Variant = parent.get("theme_override_constants/separation")
	var separation: float = float(separation_value) if typeof(separation_value) != TYPE_NIL else 8.0
	var controls: Array[Control] = []
	for child in parent.get_children():
		var c := child as Control
		if c != null and c.visible:
			controls.append(c)
	if controls.is_empty():
		return
	var available_w: float = maxf(0.0, parent.size.x)
	var fixed_w: float = 0.0
	var expand_count: int = 0
	for c in controls:
		var min_w: float = maxf(100.0, c.custom_minimum_size.x)
		var size_flags_h: int = int(c.size_flags_horizontal)
		var expand: bool = (size_flags_h & Control.SIZE_EXPAND) != 0
		if expand:
			expand_count += 1
		else:
			fixed_w += min_w
	var total_sep: float = separation * maxi(0, controls.size() - 1)
	var extra_per_expand: float = 0.0
	if expand_count > 0:
		extra_per_expand = maxf(0.0, (available_w - fixed_w - total_sep) / expand_count)
	var x: float = 0.0
	for c in controls:
		var min_w: float = maxf(100.0, c.custom_minimum_size.x)
		var h: float = maxf(30.0, c.custom_minimum_size.y)
		if h <= 30.0:
			h = maxf(30.0, c.size.y)
		var size_flags_h: int = int(c.size_flags_horizontal)
		var expand: bool = (size_flags_h & Control.SIZE_EXPAND) != 0
		var w: float = min_w + (extra_per_expand if expand else 0.0)
		c.position = Vector2(x, 0.0)
		c.size = Vector2(w, h)
		x += w + separation


static func _layout_grid(parent: Control, columns: int) -> void:
	var cols: int = maxi(1, columns)
	var sep_x_value: Variant = parent.get("theme_override_constants/h_separation")
	var sep_y_value: Variant = parent.get("theme_override_constants/v_separation")
	var sep_x: float = float(sep_x_value) if typeof(sep_x_value) != TYPE_NIL else 8.0
	var sep_y: float = float(sep_y_value) if typeof(sep_y_value) != TYPE_NIL else 8.0
	if sep_x <= 0.0:
		sep_x = 8.0
	if sep_y <= 0.0:
		sep_y = 8.0
	var cell_w: float = maxf(110.0, (maxf(1.0, parent.size.x) - sep_x * (cols - 1)) / cols)
	var row_h: float = 34.0
	var index: int = 0
	for child in parent.get_children():
		var c := child as Control
		if c == null or not c.visible:
			continue
		var col: int = index % cols
		var row: int = int(floor(float(index) / float(cols)))
		var h: float = maxf(row_h, c.custom_minimum_size.y)
		c.position = Vector2(col * (cell_w + sep_x), row * (h + sep_y))
		c.size = Vector2(cell_w, h)
		row_h = maxf(row_h, h)
		index += 1
	var rows: int = int(ceil(float(maxi(1, index)) / float(cols)))
	parent.custom_minimum_size.y = rows * row_h + maxi(0, rows - 1) * sep_y
