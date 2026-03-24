extends Node

## Handles online multiplayer: ENet host/join and lockstep input sync.
## Host sends combined frame inputs; client receives and applies to fighters.

signal connection_succeeded()
signal connection_failed()
signal peer_disconnected()
signal match_started(seed_value: int)
signal frame_received(frame_id: int, p1_input: Dictionary, p2_input: Dictionary)

const DEFAULT_PORT: int = 49152
const MAX_FRAME_QUEUE: int = 120

var _peer: ENetMultiplayerPeer = null
var _is_host: bool = false
var _session_active: bool = false
var _sim_frame: int = 0
var _host_inputs: Dictionary = {}
var _client_input_for_frame: Dictionary = {}
var _frame_queue: Array[Dictionary] = []
var _match_seed: int = 0
var _opponent_character_mod: String = ""


func is_online_session() -> bool:
	return _session_active and _peer != null and _peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func is_host() -> bool:
	return _is_host


func get_sim_frame() -> int:
	return _sim_frame


func host(port: int = DEFAULT_PORT) -> Error:
	_close_peer()
	_peer = ENetMultiplayerPeer.new()
	var err: Error = _peer.create_server(port, 1)
	if err != OK:
		_close_peer()
		connection_failed.emit()
		return err
	_multiplayer_peer_set()
	_is_host = true
	_session_active = true
	_sim_frame = 0
	_host_inputs.clear()
	_client_input_for_frame.clear()
	_frame_queue.clear()
	connection_succeeded.emit()
	return OK


func join(ip: String, port: int = DEFAULT_PORT) -> Error:
	_close_peer()
	_peer = ENetMultiplayerPeer.new()
	var err: Error = _peer.create_client(ip, port)
	if err != OK:
		_close_peer()
		connection_failed.emit()
		return err
	_multiplayer_peer_set()
	_is_host = false
	_session_active = true
	_sim_frame = 0
	_frame_queue.clear()
	connection_succeeded.emit()
	return OK


func disconnect_session() -> void:
	_session_active = false
	_close_peer()
	_is_host = false
	_sim_frame = 0
	_host_inputs.clear()
	_client_input_for_frame.clear()
	_frame_queue.clear()
	_opponent_character_mod = ""


func start_match(seed_value: int) -> void:
	_match_seed = seed_value
	if _is_host:
		_rpc_start_match.rpc(seed_value)
	match_started.emit(seed_value)


func _close_peer() -> void:
	if _peer != null:
		var tree: SceneTree = get_tree()
		if tree != null and tree.get_multiplayer().multiplayer_peer == _peer:
			tree.get_multiplayer().multiplayer_peer = null
		_peer.close()
		_peer = null


func _multiplayer_peer_set() -> void:
	var tree: SceneTree = get_tree()
	if tree == null or _peer == null:
		return
	var mp: MultiplayerAPI = tree.get_multiplayer()
	mp.multiplayer_peer = _peer
	mp.server_relay = false


func _ready() -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		var mp: MultiplayerAPI = tree.get_multiplayer()
		mp.peer_connected.connect(_on_peer_connected)
		mp.peer_disconnected.connect(_on_peer_disconnected)


func _on_peer_connected(_peer_id: int) -> void:
	pass


func _on_peer_disconnected(_peer_id: int) -> void:
	peer_disconnected.emit()


## Serialize one frame input for network (direction as array for RPC).
static func serialize_input(direction: Vector2, pressed: Array, held: Array, released: Array) -> Dictionary:
	return {
		"d": [direction.x, direction.y],
		"p": pressed.duplicate(),
		"h": held.duplicate(),
		"r": released.duplicate()
	}


static func deserialize_input(data: Dictionary) -> Dictionary:
	var d: Array = data.get("d", [0.0, 0.0])
	var dir: Vector2 = Vector2(float(d[0]) if d.size() >= 1 else 0.0, float(d[1]) if d.size() >= 2 else 0.0)
	return {
		"direction": dir,
		"pressed": data.get("p", []),
		"held": data.get("h", []),
		"released": data.get("r", [])
	}


## Call every physics frame from arena. Returns true if a frame was applied (client) or sent (host).
func poll_and_advance(
	read_p1_input: Callable,
	read_p2_input: Callable,
	apply_frame: Callable
) -> bool:
	if not is_online_session():
		return false
	if _is_host:
		return _host_poll(read_p1_input, read_p2_input, apply_frame)
	else:
		return _client_poll(apply_frame)


func _host_poll(
	read_p1_input: Callable,
	_read_p2_input: Callable,
	apply_frame: Callable
) -> bool:
	var p1: Dictionary = read_p1_input.call() if read_p1_input.is_valid() else _empty_input()
	var p2: Dictionary = _client_input_for_frame.get(_sim_frame, _empty_input())
	_host_inputs[_sim_frame] = p1
	var p1_ser: Dictionary = serialize_input(
		p1.get("direction", Vector2.ZERO),
		p1.get("pressed", []),
		p1.get("held", []),
		p1.get("released", [])
	)
	var p2_ser: Dictionary = serialize_input(
		p2.get("direction", Vector2.ZERO),
		p2.get("pressed", []),
		p2.get("held", []),
		p2.get("released", [])
	)
	_rpc_frame_broadcast.rpc(_sim_frame, p1_ser, p2_ser)
	apply_frame.call(_sim_frame, p1, p2)
	_sim_frame += 1
	return true


func _client_poll(apply_frame: Callable) -> bool:
	if _frame_queue.is_empty():
		return false
	var entry: Dictionary = _frame_queue.pop_front()
	var frame_id: int = entry.get("frame_id", 0)
	var p1: Dictionary = deserialize_input(entry.get("p1", {}))
	var p2: Dictionary = deserialize_input(entry.get("p2", {}))
	apply_frame.call(frame_id, p1, p2)
	_sim_frame = frame_id + 1
	return true


func _empty_input() -> Dictionary:
	return {"direction": Vector2.ZERO, "pressed": [], "held": [], "released": []}


## Client: send my (P2) input for the next frame. Call every physics frame.
func send_my_input(direction: Vector2, pressed: Array, held: Array, released: Array) -> void:
	if not is_online_session() or _is_host:
		return
	var ser: Dictionary = serialize_input(direction, pressed, held, released)
	_rpc_client_input.rpc_id(1, ser)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_client_input(ser: Dictionary) -> void:
	if not _is_host:
		return
	_client_input_for_frame[_sim_frame] = deserialize_input(ser)


@rpc("authority", "call_remote", "reliable")
func _rpc_frame_broadcast(frame_id: int, p1_ser: Dictionary, p2_ser: Dictionary) -> void:
	if _frame_queue.size() >= MAX_FRAME_QUEUE:
		_frame_queue.pop_front()
	_frame_queue.append({
		"frame_id": frame_id,
		"p1": p1_ser,
		"p2": p2_ser
	})
	frame_received.emit(frame_id, deserialize_input(p1_ser), deserialize_input(p2_ser))


@rpc("authority", "call_remote", "reliable")
func _rpc_start_match(seed_value: int) -> void:
	_match_seed = seed_value
	match_started.emit(seed_value)


func get_match_seed() -> int:
	return _match_seed


func send_my_character_selection(mod_name: String) -> void:
	if not is_online_session() or _is_host:
		return
	_rpc_character_selection.rpc_id(1, mod_name)


func get_opponent_character() -> String:
	return _opponent_character_mod


@rpc("any_peer", "call_remote", "reliable")
func _rpc_character_selection(mod_name: String) -> void:
	if not _is_host:
		return
	_opponent_character_mod = str(mod_name).strip_edges()


func start_battle_and_go(
	p1_mod: String,
	p2_mod: String,
	stage_folder: String,
	battle_scene_path: String,
	stage_music_path: String = ""
) -> void:
	if not _is_host or not is_online_session():
		return
	var music_trim: String = str(stage_music_path).strip_edges()
	_rpc_start_battle.rpc(p1_mod, p2_mod, stage_folder, battle_scene_path, music_trim)
	if get_tree() != null:
		get_tree().set_meta("training_p1_mod", p1_mod)
		get_tree().set_meta("training_p2_mod", p2_mod)
		get_tree().set_meta("training_stage_folder", stage_folder)
		get_tree().set_meta("training_stage_music_path", music_trim)
		get_tree().change_scene_to_file(battle_scene_path)


@rpc("authority", "call_remote", "reliable")
func _rpc_start_battle(
	p1_mod: String,
	p2_mod: String,
	stage_folder: String,
	battle_scene_path: String,
	stage_music_path: String = ""
) -> void:
	if get_tree() != null:
		get_tree().set_meta("training_p1_mod", p1_mod)
		get_tree().set_meta("training_p2_mod", p2_mod)
		get_tree().set_meta("training_stage_folder", stage_folder)
		get_tree().set_meta("training_stage_music_path", str(stage_music_path).strip_edges())
		get_tree().change_scene_to_file(battle_scene_path)
