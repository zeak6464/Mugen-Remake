extends CanvasLayer

@onready var p1_name_label: Label = $TopBar/MainHBox/P1Column/P1Name
@onready var p2_name_label: Label = $TopBar/MainHBox/P2Column/P2Name
@onready var p1_stocks_label: Label = $TopBar/MainHBox/P1Column/P1Stocks
@onready var p2_stocks_label: Label = $TopBar/MainHBox/P2Column/P2Stocks
@onready var p1_percent_label: Label = $TopBar/MainHBox/P1Column/P1Percent
@onready var p2_percent_label: Label = $TopBar/MainHBox/P2Column/P2Percent
@onready var center_status_label: Label = $TopBar/MainHBox/CenterColumn/Status
@onready var center_round_label: Label = $TopBar/MainHBox/CenterColumn/Round


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()


func set_battle_state(data: Dictionary) -> void:
	var p1_stocks: int = int(data.get("p1_stocks", 0))
	var p2_stocks: int = int(data.get("p2_stocks", 0))
	var p1_percent: float = float(data.get("p1_percent", 0.0))
	var p2_percent: float = float(data.get("p2_percent", 0.0))
	var round_number: int = int(data.get("round_number", 1))
	var status_text: String = str(data.get("status", ""))
	var p1_name: String = str(data.get("p1_name", "")).strip_edges()
	var p2_name: String = str(data.get("p2_name", "")).strip_edges()

	p1_name_label.text = p1_name if not p1_name.is_empty() else "P1"
	p2_name_label.text = p2_name if not p2_name.is_empty() else "P2"
	p1_stocks_label.text = _stocks_dots(p1_stocks)
	p2_stocks_label.text = _stocks_dots(p2_stocks)
	p1_percent_label.text = "%.0f%%" % p1_percent
	p2_percent_label.text = "%.0f%%" % p2_percent
	_color_damage_percent(p1_percent_label, p1_percent)
	_color_damage_percent(p2_percent_label, p2_percent)
	center_round_label.text = "GAME  %d" % round_number
	center_status_label.text = status_text


func _stocks_dots(count: int) -> String:
	var n: int = clampi(count, 0, 12)
	if n <= 0:
		return "—"
	var out: String = ""
	for i in range(n):
		out += "●"
	return out


func _color_damage_percent(label: Label, pct: float) -> void:
	if pct < 60.0:
		label.add_theme_color_override("font_color", Color(0.88, 0.94, 1, 1))
	elif pct < 100.0:
		label.add_theme_color_override("font_color", Color(1, 0.72, 0.35, 1))
	elif pct < 150.0:
		label.add_theme_color_override("font_color", Color(1, 0.45, 0.32, 1))
	else:
		label.add_theme_color_override("font_color", Color(1, 0.25, 0.45, 1))
