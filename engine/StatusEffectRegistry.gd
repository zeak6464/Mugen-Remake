extends Node

## Autoload: StatusEffectRegistry. Register custom status effect types. Built-in types (poison, burn, defence_down, attack_up)
## are handled by StatusEffectSystem; any other type can be registered here.
##
## Example (e.g. from a mod _ready() or autoload):
##   StatusEffectRegistry.register("frost", my_tick_callback, my_attack_mul_callback, my_defence_mul_callback)
##
## Callbacks:
##   tick_cb(fighter: Node, effect: Dictionary) -> void
##     effect has: type, duration_frames, params, frames_until_tick, source_id
##     Decrement frames_until_tick / duration_frames yourself if needed; return when duration_frames <= 0 the effect is removed by the system.
##   attack_mul_cb(effect: Dictionary) -> float  (1.0 = no change)
##   defence_mul_cb(effect: Dictionary) -> float (1.0 = no change)

var _tick_handlers: Dictionary = {}   # type_id -> Callable(fighter, effect)
var _attack_mul_handlers: Dictionary = {}  # type_id -> Callable(effect) -> float
var _defence_mul_handlers: Dictionary = {} # type_id -> Callable(effect) -> float


func register(type_id: String, tick_callback: Callable = Callable(), attack_mul_callback: Callable = Callable(), defence_mul_callback: Callable = Callable()) -> void:
	var key: String = str(type_id).strip_edges().to_lower()
	if key.is_empty():
		return
	if tick_callback.is_valid():
		_tick_handlers[key] = tick_callback
	if attack_mul_callback.is_valid():
		_attack_mul_handlers[key] = attack_mul_callback
	if defence_mul_callback.is_valid():
		_defence_mul_handlers[key] = defence_mul_callback


func unregister(type_id: String) -> void:
	var key: String = str(type_id).strip_edges().to_lower()
	_tick_handlers.erase(key)
	_attack_mul_handlers.erase(key)
	_defence_mul_handlers.erase(key)


func get_tick_handler(type_id: String) -> Callable:
	return _tick_handlers.get(str(type_id).strip_edges().to_lower(), Callable())


func get_attack_mul_handler(type_id: String) -> Callable:
	return _attack_mul_handlers.get(str(type_id).strip_edges().to_lower(), Callable())


func get_defence_mul_handler(type_id: String) -> Callable:
	return _defence_mul_handlers.get(str(type_id).strip_edges().to_lower(), Callable())


func has_custom_type(type_id: String) -> bool:
	var key: String = str(type_id).strip_edges().to_lower()
	return _tick_handlers.has(key) or _attack_mul_handlers.has(key) or _defence_mul_handlers.has(key)
