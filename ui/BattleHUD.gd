extends CanvasLayer

const _PATH_P1_BAR := "TopBar/MainHBox/P1Column/P1HpFrame/P1HealthBar"
const _PATH_P2_BAR := "TopBar/MainHBox/P2Column/P2HpFrame/P2HealthBar"
const _PATH_P1_RES := "TopBar/MainHBox/P1Column/P1ResFrame/P1ResourceBar"
const _PATH_P2_RES := "TopBar/MainHBox/P2Column/P2ResFrame/P2ResourceBar"

@onready var p1_health_bar: TextureProgressBar = get_node(_PATH_P1_BAR)
@onready var p2_health_bar: TextureProgressBar = get_node(_PATH_P2_BAR)
@onready var p1_health_label: Label = $TopBar/MainHBox/P1Column/P1Health
@onready var p2_health_label: Label = $TopBar/MainHBox/P2Column/P2Health
@onready var p1_resource_bar: TextureProgressBar = get_node(_PATH_P1_RES)
@onready var p2_resource_bar: TextureProgressBar = get_node(_PATH_P2_RES)
@onready var p1_resource_label: Label = $TopBar/MainHBox/P1Column/P1Resource
@onready var p2_resource_label: Label = $TopBar/MainHBox/P2Column/P2Resource
@onready var p1_name_label: Label = $TopBar/MainHBox/P1Column/P1Name
@onready var p2_name_label: Label = $TopBar/MainHBox/P2Column/P2Name
@onready var p1_tag: Label = $TopBar/MainHBox/P1Column/P1Tag
@onready var p2_tag: Label = $TopBar/MainHBox/P2Column/P2Tag
@onready var main_hbox: HBoxContainer = $TopBar/MainHBox
@onready var center_column: VBoxContainer = $TopBar/MainHBox/CenterColumn
@onready var timer_small: Label = $TopBar/MainHBox/CenterColumn/TimerLabelSmall
@onready var timer_label: Label = $TopBar/MainHBox/CenterColumn/Timer
@onready var round_label: Label = $TopBar/MainHBox/CenterColumn/Round
@onready var score_label: Label = $TopBar/MainHBox/CenterColumn/Score
@onready var status_label: Label = $TopBar/MainHBox/CenterColumn/Status
@onready var team_info_label: Label = $TopBar/MainHBox/CenterColumn/TeamInfo
@onready var result_damage_container: Control = $TopBar/MainHBox/CenterColumn/ResultDamage
@onready var result_damage_p1: Label = $TopBar/MainHBox/CenterColumn/ResultDamage/P1Damage
@onready var result_damage_p2: Label = $TopBar/MainHBox/CenterColumn/ResultDamage/P2Damage

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
	p1_name_label.text = p1_name if not p1_name.is_empty() else "P1"
	p2_name_label.text = p2_name if not p2_name.is_empty() else "P2"
	p1_health_label.text = "%d  /  %d" % [p1_health, p1_max]
	p2_health_label.text = "%d  /  %d" % [p2_health, p2_max]
	p1_resource_bar.max_value = p1_max_resource
	p2_resource_bar.max_value = p2_max_resource
	p1_resource_bar.value = clampi(p1_resource, 0, p1_max_resource)
	p2_resource_bar.value = clampi(p2_resource, 0, p2_max_resource)
	p1_resource_label.text = "SUPER  %d / %d" % [p1_resource, p1_max_resource]
	p2_resource_label.text = "SUPER  %d / %d" % [p2_resource, p2_max_resource]
	var time_left: int = int(data.get("time_left", 0))
	var time_unlimited: bool = bool(data.get("time_unlimited", false))
	timer_label.text = "∞" if time_unlimited else str(maxi(0, time_left))
	round_label.text = "ROUND  %d" % int(data.get("round_number", 1))
	var w1: int = int(data.get("p1_wins", 0))
	var w2: int = int(data.get("p2_wins", 0))
	score_label.text = "%d     %d" % [w1, w2]
	status_label.text = str(data.get("status", ""))
	var show_result: bool = bool(data.get("show_round_result", false))
	var p1_dmg: int = int(data.get("p1_damage_dealt", 0))
	var p2_dmg: int = int(data.get("p2_damage_dealt", 0))
	if result_damage_container != null:
		result_damage_container.visible = show_result
		if result_damage_p1 != null:
			result_damage_p1.text = "P1 dealt  %d" % p1_dmg
		if result_damage_p2 != null:
			result_damage_p2.text = "P2 dealt  %d" % p2_dmg
	if team_mode:
		team_info_label.visible = true
		team_info_label.text = "%s  ·  Active %d vs %d" % [
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
		return "%s  —" % prefix
	var entries: Array = raw_entries
	if entries.is_empty():
		return "%s  —" % prefix
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
		parts.append("#%d %d/%d ·%d/%d%s" % [slot, hp, hp_max, res, res_max, state_suffix])
	return "%s  %s" % [prefix, "  |  ".join(parts)]


func _apply_layout_mode(compact: bool) -> void:
	if compact:
		p1_tag.visible = false
		p2_tag.visible = false
		main_hbox.add_theme_constant_override("separation", 12)
		main_hbox.offset_left = 8.0
		main_hbox.offset_right = -8.0
		main_hbox.offset_top = 6.0
		main_hbox.offset_bottom = -8.0
		center_column.custom_minimum_size = Vector2(168, 0)
		timer_small.add_theme_font_size_override("font_size", 10)
		timer_label.add_theme_font_size_override("font_size", 32)
		round_label.add_theme_font_size_override("font_size", 12)
		score_label.add_theme_font_size_override("font_size", 14)
		status_label.add_theme_font_size_override("font_size", 11)
		p1_name_label.add_theme_font_size_override("font_size", 16)
		p2_name_label.add_theme_font_size_override("font_size", 16)
		p1_health_bar.custom_minimum_size = Vector2(0, 22)
		p2_health_bar.custom_minimum_size = Vector2(0, 22)
		p1_resource_bar.custom_minimum_size = Vector2(0, 11)
		p2_resource_bar.custom_minimum_size = Vector2(0, 11)
		p1_health_label.add_theme_font_size_override("font_size", 12)
		p2_health_label.add_theme_font_size_override("font_size", 12)
		p1_resource_label.add_theme_font_size_override("font_size", 11)
		p2_resource_label.add_theme_font_size_override("font_size", 11)
	else:
		p1_tag.visible = true
		p2_tag.visible = true
		main_hbox.remove_theme_constant_override("separation")
		main_hbox.offset_left = 18.0
		main_hbox.offset_right = -18.0
		main_hbox.offset_top = 10.0
		main_hbox.offset_bottom = -12.0
		center_column.custom_minimum_size = Vector2(232, 0)
		timer_small.remove_theme_font_size_override("font_size")
		timer_label.remove_theme_font_size_override("font_size")
		round_label.remove_theme_font_size_override("font_size")
		score_label.remove_theme_font_size_override("font_size")
		status_label.remove_theme_font_size_override("font_size")
		p1_name_label.remove_theme_font_size_override("font_size")
		p2_name_label.remove_theme_font_size_override("font_size")
		p1_health_bar.custom_minimum_size = Vector2(0, 30)
		p2_health_bar.custom_minimum_size = Vector2(0, 30)
		p1_resource_bar.custom_minimum_size = Vector2(0, 14)
		p2_resource_bar.custom_minimum_size = Vector2(0, 14)
		p1_health_label.remove_theme_font_size_override("font_size")
		p2_health_label.remove_theme_font_size_override("font_size")
		p1_resource_label.remove_theme_font_size_override("font_size")
		p2_resource_label.remove_theme_font_size_override("font_size")
