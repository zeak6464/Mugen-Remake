extends CanvasLayer

@onready var p1_health_bar: TextureProgressBar = $TopBar/P1HealthBar
@onready var p2_health_bar: TextureProgressBar = $TopBar/P2HealthBar
@onready var p1_health_label: Label = $TopBar/P1Health
@onready var p2_health_label: Label = $TopBar/P2Health
@onready var p1_resource_bar: TextureProgressBar = $TopBar/P1ResourceBar
@onready var p2_resource_bar: TextureProgressBar = $TopBar/P2ResourceBar
@onready var p1_resource_label: Label = $TopBar/P1Resource
@onready var p2_resource_label: Label = $TopBar/P2Resource
@onready var timer_label: Label = $TopBar/CenterInfo/Timer
@onready var round_label: Label = $TopBar/CenterInfo/Round
@onready var score_label: Label = $TopBar/CenterInfo/Score
@onready var status_label: Label = $TopBar/CenterInfo/Status
@onready var team_info_label: Label = $TopBar/CenterInfo/TeamInfo
@onready var result_damage_container: Control = $TopBar/CenterInfo/ResultDamage
@onready var result_damage_p1: Label = $TopBar/CenterInfo/ResultDamage/P1Damage
@onready var result_damage_p2: Label = $TopBar/CenterInfo/ResultDamage/P2Damage

var compact_team_layout_enabled: bool = false


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()


func set_battle_state(data: Dictionary) -> void:
	var team_mode: bool = bool(data.get("team_mode", false))
	var team_subtype: String = str(data.get("team_mode_subtype", "")).to_lower()
	var compact_layout: bool = team_mode and team_subtype == "simul"
	if compact_layout != compact_team_layout_enabled:
		compact_team_layout_enabled = compact_layout
		_apply_layout_mode(compact_layout)

	var p1_health: int = int(data.get("p1_health", 0))
	var p2_health: int = int(data.get("p2_health", 0))
	var p1_max: int = maxi(1, int(data.get("p1_max_health", 1000)))
	var p2_max: int = maxi(1, int(data.get("p2_max_health", 1000)))
	var p1_resource: int = int(data.get("p1_resource", 0))
	var p2_resource: int = int(data.get("p2_resource", 0))
	var p1_max_resource: int = maxi(1, int(data.get("p1_max_resource", 100)))
	var p2_max_resource: int = maxi(1, int(data.get("p2_max_resource", 100)))

	p1_health_bar.max_value = p1_max
	p1_health_bar.value = clampi(p1_health, 0, p1_max)
	p2_health_bar.max_value = p2_max
	p2_health_bar.value = clampi(p2_health, 0, p2_max)

	var p1_name: String = str(data.get("p1_name", "")).strip_edges()
	var p2_name: String = str(data.get("p2_name", "")).strip_edges()
	p1_health_label.text = ("%s - " % p1_name if not p1_name.is_empty() else "") + "P1 HP: %d/%d" % [p1_health, p1_max]
	p2_health_label.text = "P2 HP: %d/%d" % [p2_health, p2_max] + (" - %s" % p2_name if not p2_name.is_empty() else "")
	p1_resource_bar.max_value = p1_max_resource
	p2_resource_bar.max_value = p2_max_resource
	p1_resource_bar.value = clampi(p1_resource, 0, p1_max_resource)
	p2_resource_bar.value = clampi(p2_resource, 0, p2_max_resource)
	p1_resource_label.text = "P1 RES: %d/%d" % [p1_resource, p1_max_resource]
	p2_resource_label.text = "P2 RES: %d/%d" % [p2_resource, p2_max_resource]
	timer_label.text = "Time: %d" % int(data.get("time_left", 0))
	round_label.text = "Round: %d" % int(data.get("round_number", 1))
	score_label.text = "Score: %d - %d" % [int(data.get("p1_wins", 0)), int(data.get("p2_wins", 0))]
	status_label.text = str(data.get("status", ""))
	var show_result: bool = bool(data.get("show_round_result", false))
	var p1_dmg: int = int(data.get("p1_damage_dealt", 0))
	var p2_dmg: int = int(data.get("p2_damage_dealt", 0))
	if result_damage_container != null:
		result_damage_container.visible = show_result
		if result_damage_p1 != null:
			result_damage_p1.text = "P1 Damage: %d" % p1_dmg
		if result_damage_p2 != null:
			result_damage_p2.text = "P2 Damage: %d" % p2_dmg
	if team_mode:
		team_info_label.visible = true
		team_info_label.text = "Team %s | Remaining %d - %d" % [
			team_subtype.to_upper(),
			int(data.get("p1_team_remaining", 1)),
			int(data.get("p2_team_remaining", 1))
		]
	else:
		team_info_label.visible = false
		team_info_label.text = ""

	if compact_layout:
		p1_resource_label.text = _compact_team_text("P1", data.get("p1_team_status", []))
		p2_resource_label.text = _compact_team_text("P2", data.get("p2_team_status", []))


func _compact_team_text(prefix: String, raw_entries: Variant) -> String:
	if not (raw_entries is Array):
		return "%s RES: -" % prefix
	var entries: Array = raw_entries
	if entries.is_empty():
		return "%s RES: -" % prefix
	var parts: Array[String] = []
	for entry_raw in entries:
		if not (entry_raw is Dictionary):
			continue
		var entry: Dictionary = entry_raw
		var slot: int = int(entry.get("slot", parts.size() + 1))
		var hp: int = int(entry.get("hp", 0))
		var hp_max: int = maxi(1, int(entry.get("hp_max", 1)))
		var res: int = int(entry.get("res", 0))
		var res_max: int = maxi(1, int(entry.get("res_max", 1)))
		var alive: bool = bool(entry.get("alive", hp > 0))
		var state_suffix: String = "" if alive else " KO"
		parts.append("#%d %d/%d %d/%d%s" % [slot, hp, hp_max, res, res_max, state_suffix])
	return "%s TEAM: %s" % [prefix, "  |  ".join(parts)]


func _apply_layout_mode(compact: bool) -> void:
	if compact:
		p1_health_bar.offset_left = 10.0
		p1_health_bar.offset_top = 10.0
		p1_health_bar.offset_right = 280.0
		p1_health_bar.offset_bottom = 30.0
		p1_resource_bar.offset_left = 10.0
		p1_resource_bar.offset_top = 34.0
		p1_resource_bar.offset_right = 280.0
		p1_resource_bar.offset_bottom = 48.0
		p1_health_label.offset_left = 10.0
		p1_health_label.offset_top = 50.0
		p1_health_label.offset_right = 320.0
		p1_health_label.offset_bottom = 66.0
		p1_resource_label.offset_left = 10.0
		p1_resource_label.offset_top = 66.0
		p1_resource_label.offset_right = 620.0
		p1_resource_label.offset_bottom = 84.0
		p1_resource_label.add_theme_font_size_override("font_size", 12)

		p2_health_bar.offset_left = 854.0
		p2_health_bar.offset_top = 10.0
		p2_health_bar.offset_right = 1124.0
		p2_health_bar.offset_bottom = 30.0
		p2_resource_bar.offset_left = 854.0
		p2_resource_bar.offset_top = 34.0
		p2_resource_bar.offset_right = 1124.0
		p2_resource_bar.offset_bottom = 48.0
		p2_health_label.offset_left = 814.0
		p2_health_label.offset_top = 50.0
		p2_health_label.offset_right = 1124.0
		p2_health_label.offset_bottom = 66.0
		p2_resource_label.offset_left = 510.0
		p2_resource_label.offset_top = 66.0
		p2_resource_label.offset_right = 1124.0
		p2_resource_label.offset_bottom = 84.0
		p2_resource_label.add_theme_font_size_override("font_size", 12)

		p1_health_label.add_theme_font_size_override("font_size", 13)
		p2_health_label.add_theme_font_size_override("font_size", 13)
	else:
		p1_health_bar.offset_left = 10.0
		p1_health_bar.offset_top = 10.0
		p1_health_bar.offset_right = 410.0
		p1_health_bar.offset_bottom = 40.0
		p2_health_bar.offset_left = 724.0
		p2_health_bar.offset_top = 3.0
		p2_health_bar.offset_right = 1124.0
		p2_health_bar.offset_bottom = 33.0
		p1_resource_bar.offset_left = 10.0
		p1_resource_bar.offset_top = 72.0
		p1_resource_bar.offset_right = 410.0
		p1_resource_bar.offset_bottom = 92.0
		p2_resource_bar.offset_left = 724.0
		p2_resource_bar.offset_top = 72.0
		p2_resource_bar.offset_right = 1124.0
		p2_resource_bar.offset_bottom = 92.0
		p1_health_label.offset_left = 10.0
		p1_health_label.offset_top = 44.0
		p1_health_label.offset_right = 220.0
		p1_health_label.offset_bottom = 66.0
		p2_health_label.offset_left = 907.0
		p2_health_label.offset_top = 31.0
		p2_health_label.offset_right = 1117.0
		p2_health_label.offset_bottom = 54.0
		p1_resource_label.offset_left = 10.0
		p1_resource_label.offset_top = 94.0
		p1_resource_label.offset_right = 220.0
		p1_resource_label.offset_bottom = 116.0
		p2_resource_label.offset_left = 907.0
		p2_resource_label.offset_top = 94.0
		p2_resource_label.offset_right = 1117.0
		p2_resource_label.offset_bottom = 116.0
		p1_health_label.remove_theme_font_size_override("font_size")
		p2_health_label.remove_theme_font_size_override("font_size")
		p1_resource_label.remove_theme_font_size_override("font_size")
		p2_resource_label.remove_theme_font_size_override("font_size")
