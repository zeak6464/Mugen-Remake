extends Control

## Shows tournament bracket after each match. Continue goes to next match (Arena) or Main Menu (if champion).

@export var arena_scene_path: String = "res://stages/TestArena.tscn"
@export var main_menu_path: String = "res://ui/MainMenu.tscn"

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var bracket_scroll: ScrollContainer = $MarginContainer/VBoxContainer/BracketScroll
@onready var bracket_content: VBoxContainer = $MarginContainer/VBoxContainer/BracketScroll/BracketContent
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/ContinueButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/BackButton

var entrants: Array = []
var round_results: Array = []
var match_index: int = 0
var total_matches: int = 0
var tournament_over: bool = false
var champion_name: String = ""


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()
	entrants = _get_meta_array("tournament_entrants")
	round_results = _get_meta_array("tournament_round_results")
	match_index = int(get_tree().get_meta("tournament_match_index", 0))
	var n: int = entrants.size()
	total_matches = _total_matches(n)
	tournament_over = match_index >= total_matches
	if tournament_over and round_results.size() > 0:
		var champ_idx: int = int(round_results[round_results.size() - 1])
		if champ_idx >= 0 and champ_idx < entrants.size():
			var ce: Dictionary = entrants[champ_idx]
			champion_name = str(ce.get("mod_display", ce.get("mod", "Unknown")))
		else:
			champion_name = "Unknown"
	_build_bracket_display(n)
	_update_status()
	if continue_button != null:
		continue_button.pressed.connect(_on_continue_pressed)
	if back_button != null:
		back_button.visible = false
	continue_button.grab_focus()


func _get_meta_array(key: String) -> Array:
	var v = get_tree().get_meta(key, null)
	if v is Array:
		return v.duplicate()
	return []


func _total_matches(num_entrants: int) -> int:
	return maxi(0, num_entrants - 1)


func _get_opponents(num_entrants: int, match_idx: int, results: Array) -> Array:
	if num_entrants < 2:
		return [-1, -1]
	var first_round: int = int(num_entrants / 2)
	if match_idx < first_round:
		return [match_idx * 2, match_idx * 2 + 1]
	var source_start: int = 0
	var source_size: int = first_round
	var match_start: int = first_round
	while source_size > 1 and match_start + int(source_size / 2) <= match_idx:
		match_start += int(source_size / 2)
		source_start += int(source_size / 2)
		source_size = int(source_size / 2)
	var offset: int = match_idx - match_start
	var base: int = source_start + offset * 2
	if base + 1 >= results.size():
		return [-1, -1]
	return [int(results[base]), int(results[base + 1])]


func _entrant_name(idx: int) -> String:
	if idx < 0 or idx >= entrants.size():
		return "?"
	var ent: Dictionary = entrants[idx]
	return str(ent.get("mod_display", ent.get("mod", "?")))


func _build_bracket_display(num_entrants: int) -> void:
	if bracket_content == null:
		return
	for c in bracket_content.get_children():
		c.queue_free()
	var first_round_matches: int = int(num_entrants / 2)
	var round_num: int = 1
	var match_idx: int = 0
	while match_idx < total_matches:
		var round_label: Label = Label.new()
		round_label.text = "Round %d" % round_num
		round_label.add_theme_font_size_override("font_size", 20)
		bracket_content.add_child(round_label)
		var matches_in_round: int = maxi(1, int(first_round_matches / (1 << (round_num - 1))))
		for _i in range(matches_in_round):
			if match_idx >= total_matches:
				break
			var indices: Array = _get_opponents(num_entrants, match_idx, round_results)
			var left_idx: int = int(indices[0]) if indices.size() > 0 else -1
			var right_idx: int = int(indices[1]) if indices.size() > 1 else -1
			var winner_idx: int = -1
			if match_idx < round_results.size():
				winner_idx = int(round_results[match_idx])
			var left_name: String = _entrant_name(left_idx)
			var right_name: String = _entrant_name(right_idx)
			var line: String = "  Match %d: %s vs %s" % [match_idx + 1, left_name, right_name]
			if winner_idx >= 0:
				line += "  → %s" % _entrant_name(winner_idx)
			var row: Label = Label.new()
			row.text = line
			row.add_theme_font_size_override("font_size", 16)
			bracket_content.add_child(row)
			match_idx += 1
		round_num += 1
		var spacer: Control = Control.new()
		spacer.custom_minimum_size.y = 12
		bracket_content.add_child(spacer)


func _update_status() -> void:
	if status_label == null:
		return
	if tournament_over:
		status_label.text = "Champion: %s!" % champion_name
		if continue_button != null:
			continue_button.text = "Back to Main Menu"
	else:
		var n: int = entrants.size()
		var indices: Array = _get_opponents(n, match_index, round_results)
		var a: String = _entrant_name(int(indices[0]) if indices.size() > 0 else -1)
		var b: String = _entrant_name(int(indices[1]) if indices.size() > 1 else -1)
		status_label.text = "Next: %s vs %s" % [a, b]
		if continue_button != null:
			continue_button.text = "Continue to Next Match"


func _on_continue_pressed() -> void:
	SystemSFX.play_ui_from(self, "ui_confirm")
	if tournament_over:
		get_tree().change_scene_to_file(main_menu_path)
	else:
		get_tree().change_scene_to_file(arena_scene_path)
