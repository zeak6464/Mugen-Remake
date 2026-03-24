extends Control
class_name RingMenu

signal selection_changed(index: int)
signal item_confirmed(index: int)

@export var radius: float = 220.0
@export var item_min_size: Vector2 = Vector2(160, 48)
@export var max_items_per_page: int = 10
@export var focus_scale: float = 1.12
@export var list_spacing: float = 8.0
@export var selection_tween_sec: float = 0.14

var _items: Array[Dictionary] = []
var _buttons: Array[Button] = []
var _page: int = 0
var _selected_index: int = 0
var _visible_indices: Array[int] = []
var _layout_tween: Tween = null
var _animate_layout: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild_buttons()
	call_deferred("_enable_layout_animation")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_list(false)


func set_items(items: Array[Dictionary]) -> void:
	_items = items.duplicate(true)
	_selected_index = clampi(_selected_index, 0, max(0, _items.size() - 1))
	_page = 0
	_animate_layout = false
	_rebuild_buttons()
	call_deferred("_enable_layout_animation")
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


func _enable_layout_animation() -> void:
	_animate_layout = true


func _rebuild_buttons() -> void:
	_visible_indices = _items_for_page(_page)
	var want_count: int = _visible_indices.size()
	while _buttons.size() < want_count:
		var slot: int = _buttons.size()
		var button := Button.new()
		button.custom_minimum_size = item_min_size
		button.flat = false
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_slot_pressed.bind(slot))
		add_child(button)
		_buttons.append(button)
	while _buttons.size() > want_count:
		var remove_button: Button = _buttons.pop_back()
		if remove_button != null and is_instance_valid(remove_button):
			remove_button.queue_free()
	for i in range(want_count):
		var absolute_index: int = _visible_indices[i]
		if absolute_index < 0 or absolute_index >= _items.size():
			continue
		var item: Dictionary = _items[absolute_index]
		var button: Button = _buttons[i]
		button.text = str(item.get("label", ""))
		var icon_tex: Texture2D = item.get("icon", null)
		if icon_tex != null:
			button.icon = icon_tex
			button.expand_icon = false
		else:
			button.icon = null
	_layout_list(_animate_layout)


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
	_layout_list(_animate_layout)


func _layout_list(animate: bool = true) -> void:
	if _buttons.is_empty():
		return
	var row_width: float = maxf(1.0, item_min_size.x)
	var row_height: float = maxf(1.0, item_min_size.y)
	var count: int = _buttons.size()
	var total_height: float = (row_height * float(count)) + (list_spacing * float(maxi(0, count - 1)))
	var start_x: float = (size.x * 0.5) - (row_width * 0.5)
	var start_y: float = (size.y * 0.5) - (total_height * 0.5)
	if _layout_tween != null and is_instance_valid(_layout_tween):
		_layout_tween.kill()
		_layout_tween = null
	var use_tween: bool = animate and _animate_layout and selection_tween_sec > 0.001
	var tw: Tween = null
	if use_tween:
		tw = create_tween()
		tw.set_parallel(true)
		tw.set_trans(Tween.TRANS_CUBIC)
		tw.set_ease(Tween.EASE_OUT)
		_layout_tween = tw
	for i in range(count):
		var button: Button = _buttons[i]
		if button == null or not is_instance_valid(button):
			continue
		button.pivot_offset = Vector2(row_width * 0.5, row_height * 0.5)
		button.size = Vector2(row_width, row_height)
		var target_pos := Vector2(start_x, start_y + (float(i) * (row_height + list_spacing)))
		button.position = target_pos
		var absolute_index: int = _visible_indices[i] if i < _visible_indices.size() else -1
		var is_selected: bool = absolute_index == _selected_index
		var target_scale: Vector2 = Vector2.ONE * (focus_scale if is_selected else 1.0)
		var target_modulate: Color = Color(1, 1, 1, 1.0 if is_selected else 0.72)
		if use_tween:
			tw.tween_property(button, "scale", target_scale, selection_tween_sec)
			tw.tween_property(button, "modulate", target_modulate, selection_tween_sec)
		else:
			button.scale = target_scale
			button.modulate = target_modulate


func _on_slot_pressed(slot: int) -> void:
	if slot < 0 or slot >= _visible_indices.size():
		return
	set_selected_index(_visible_indices[slot])
	confirm_selection()


func _emit_selection_changed() -> void:
	selection_changed.emit(_selected_index)
