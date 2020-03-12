extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

# Default game port
const DEFAULT_PORT: int = 10567

# Max number of players
const MAX_PEERS: int = 2

# Name for my player
var player_name: String = "Good Name"

# Names for remote players in id:name format
var players: = {}

# Signals to let lobby GUI know what's going on
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

# Callback from SceneTree
func _player_connected(id: int) -> void:
	# This is not used in this demo, because _connected_ok is called for clients
	# on success and will do the job.
	pass


# Callback from SceneTree
func _player_disconnected(id: int) -> void:
	if get_tree().is_network_server():
		if has_node("/root/Main"): # Game is in progress
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			end_game()
		else: # Game is not in progress
			# If we are the server, send to the new dude all the already registered players
			unregister_player(id)
			for p_id in players:
				# Erase in the server
				rpc_id(p_id, "unregister_player", id)


# Callback from SceneTree, only for clients (not server)
func _connected_ok() -> void:
	# Registration of a client beings here, tell everyone that we are here
	rpc("register_player", get_tree().get_network_unique_id(), player_name)
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server)
func _server_disconnected() -> void:
	emit_signal("game_error", "Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server)
func _connected_fail() -> void:
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")


# Lobby management functions

remote func register_player(id: int, new_player_name: String) -> void:
	if get_tree().is_network_server():
		# If we are the server, let everyone know about the new player
		rpc_id(id, "register_player", 1, player_name) # Send myself to new dude
		for p_id in players: # Then, for each remote player
			rpc_id(id, "register_player", p_id, players[p_id]) # Send player to new dude
			rpc_id(p_id, "register_player", id, new_player_name) # Send new dude to player

	players[id] = new_player_name
	emit_signal("player_list_changed")


remote func unregister_player(id: int) -> void:
	players.erase(id)
	emit_signal("player_list_changed")

remote func post_start_game() -> void:
	get_tree().set_pause(false) # Unpause and unleash the game!

var players_ready: = []


remote func ready_to_start(id: int) -> void:
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()

func get_players()-> Dictionary:
	return players
	
func host_game(new_player_name: String) -> void:
	player_name = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)


func join_game(ip: String, new_player_name: String) -> void:
	player_name = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)


func get_player_list() -> Array:
	return players.values()


func get_player_name() -> String:
	return player_name

func end_game() -> void:
	if has_node("/root/Main"): # Game is in progress
		# End it
		get_node("/root/Main").queue_free()

	emit_signal("game_ended")
	players.clear()
	get_tree().set_network_peer(null) # End networking


func _ready() -> void:
	# Called when the node is added to the scene for the first time.
	# Initialization here
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
