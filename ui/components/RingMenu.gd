extends Control
class_name RingMenu

signal selection_changed(index: int)
signal item_confirmed(index: int)

@export var radius: float = 220.0
@export var item_min_size: Vector2 = Vector2(160, 48)
@export var max_items_per_page: int = 10
@export var focus_scale: float = 1.12
@export var list_spacing: float = 8.0

var _items: Array[Dictionary] = []
var _buttons: Array[Button] = []
var _page: int = 0
var _selected_index: int = 0
var _visible_indices: Array[int] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild_buttons()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_ring()


func set_items(items: Array[Dictionary]) -> void:
	_items = items.duplicate(true)
	_selected_index = clampi(_selected_index, 0, max(0, _items.size() - 1))
	_page = 0
	_rebuild_buttons()
	_emit_selection_changed()


func get_items() -> Array[Dictionary]:
	return _items.duplicate(true)


func set_selected_index(index: int) -> void:
	if _items.is_empty():
		_selected_index = 0
		return
	_selected_index = wrapi(index, 0, _items.size())
	_page = 0
	_rebuild_buttons()
	_emit_selection_changed()


func get_selected_index() -> int:
	return _selected_index


func rotate_selection(step: int) -> void:
	if _items.is_empty():
		return
	set_selected_index(_selected_index + step)


func next_page() -> void:
	# Continuous-loop mode: page buttons behave like next item.
	rotate_selection(1)


func previous_page() -> void:
	# Continuous-loop mode: page buttons behave like previous item.
	rotate_selection(-1)


func confirm_selection() -> void:
	if _items.is_empty():
		return
	item_confirmed.emit(_selected_index)


func get_page() -> int:
	return _page


func get_page_count() -> int:
	return _total_pages()


func _total_pages() -> int:
	if _items.is_empty():
		return 1
	return int(ceil(float(_items.size()) / float(maxi(1, max_items_per_page))))


func _page_for_index(index: int) -> int:
	return int(floor(float(maxi(0, index)) / float(maxi(1, max_items_per_page))))


func _rebuild_buttons() -> void:
	for button in _buttons:
		if button != null and is_instance_valid(button):
			button.queue_free()
	_buttons.clear()
	_visible_indices = _items_for_page(_page)
	for i in range(_visible_indices.size()):
		var absolute_index: int = _visible_indices[i]
		if absolute_index < 0 or absolute_index >= _items.size():
			continue
		var item: Dictionary = _items[absolute_index]
		var button := Button.new()
		button.custom_minimum_size = item_min_size
		button.text = str(item.get("label", ""))
		var icon_tex: Texture2D = item.get("icon", null)
		if icon_tex != null:
			button.icon = icon_tex
			# Keep list entries readable and avoid giant icon blocks.
			button.expand_icon = false
		button.flat = false
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_button_pressed.bind(absolute_index))
		add_child(button)
		_buttons.append(button)
	_layout_list()


func _items_for_page(_page_index: int) -> Array[int]:
	var out: Array[int] = []
	if _items.is_empty():
		return out
	var visible_count: int = mini(_items.size(), maxi(1, max_items_per_page))
	var half: int = int(floor(float(visible_count) * 0.5))
	var start: int = _selected_index - half
	for i in range(visible_count):
		var idx: int = wrapi(start + i, 0, _items.size())
		out.append(idx)
	return out


func _layout_ring() -> void:
	# Backward-compatible name used by existing call sites.
	_layout_list()


func _layout_list() -> void:
	if _buttons.is_empty():
		return
	var row_width: float = maxf(1.0, item_min_size.x)
	var row_height: float = maxf(1.0, item_min_size.y)
	var count: int = _buttons.size()
	var total_height: float = (row_height * float(count)) + (list_spacing * float(maxi(0, count - 1)))
	var start_x: float = (size.x * 0.5) - (row_width * 0.5)
	var start_y: float = (size.y * 0.5) - (total_height * 0.5)
	for i in range(count):
		var button: Button = _buttons[i]
		if button == null or not is_instance_valid(button):
			continue
		button.size = Vector2(row_width, row_height)
		button.position = Vector2(start_x, start_y + (float(i) * (row_height + list_spacing)))
		var absolute_index: int = _visible_indices[i] if i < _visible_indices.size() else -1
		var is_selected: bool = absolute_index == _selected_index
		button.scale = Vector2.ONE * (focus_scale if is_selected else 1.0)
		button.modulate = Color(1, 1, 1, 1.0 if is_selected else 0.78)


func _on_button_pressed(index: int) -> void:
	set_selected_index(index)
	confirm_selection()


func _emit_selection_changed() -> void:
	selection_changed.emit(_selected_index)
