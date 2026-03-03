extends CanvasLayer

@onready var p1_stocks_label: Label = $TopBar/P1Stocks
@onready var p2_stocks_label: Label = $TopBar/P2Stocks
@onready var p1_percent_label: Label = $TopBar/P1Percent
@onready var p2_percent_label: Label = $TopBar/P2Percent
@onready var center_status_label: Label = $TopBar/CenterInfo/Status
@onready var center_round_label: Label = $TopBar/CenterInfo/Round


func _ready() -> void:
	UISkin.ensure_ui_fits_screen()


func set_battle_state(data: Dictionary) -> void:
	var p1_stocks: int = int(data.get("p1_stocks", 0))
	var p2_stocks: int = int(data.get("p2_stocks", 0))
	var p1_percent: float = float(data.get("p1_percent", 0.0))
	var p2_percent: float = float(data.get("p2_percent", 0.0))
	var round_number: int = int(data.get("round_number", 1))
	var status_text: String = str(data.get("status", ""))

	p1_stocks_label.text = "P1 Stocks: %d" % p1_stocks
	p2_stocks_label.text = "P2 Stocks: %d" % p2_stocks
	p1_percent_label.text = "P1: %.0f%%" % p1_percent
	p2_percent_label.text = "P2: %.0f%%" % p2_percent
	center_round_label.text = "Round: %d" % round_number
	center_status_label.text = status_text
