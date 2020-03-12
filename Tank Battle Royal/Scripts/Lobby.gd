extends Control

onready var _host_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Host
onready var _connect_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Connect
onready var _disconnect_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Disconnect
onready var _name_edit = $Panel/VBoxContainer/HBoxContainer/NameEdit
onready var _host_edit = $Panel/VBoxContainer/HBoxContainer2/Hostname
onready var _game = $Panel/VBoxContainer/Game

func _ready() -> void:
	# Called when the node is added to the scene for the first time.
	# Initialization here
	#Connect gamestate signals to lobby functions
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")


func _on_Host_pressed() -> void:
	#Don't host if no name is entered
	if _name_edit.text == "":
		return

	_host_btn.disabled = true
	_name_edit.editable = false
	_host_edit.editable = false
	_connect_btn.hide()
	_disconnect_btn.show()
	var player_name = _name_edit.text
	gamestate.host_game(player_name)
	refresh_lobby()


func _on_Connect_pressed() -> void:
	#Don't join if no name is entered
	if _name_edit.text == "":
		return

	var ip = _host_edit.text
	if not ip.is_valid_ip_address():
		get_node("Panel/VBoxContainer/Game/HBoxContainer/RichTextLabel").text="Invalid IPv4 address!"
		return

	get_node("Panel/VBoxContainer/Game/HBoxContainer/RichTextLabel").text=""
	_host_edit.editable = false
	_connect_btn.hide()
	_disconnect_btn.show()
	var player_name = _name_edit.text
	gamestate.join_game(ip, player_name)
	# refresh_lobby() gets called by the player_list_changed signal


func _on_connection_success() -> void:
	_connect_btn.hide()


func _on_connection_failed() -> void:
	_host_btn.disabled=false
	_connect_btn.disabled=false


func _on_game_ended() -> void:
	show()

func refresh_lobby() -> void:
	var players = gamestate.get_player_list()
	players.sort()
	get_node("Panel/VBoxContainer/Game/HBoxContainer/VBoxContainer/ItemList").clear()
	get_node("Panel/VBoxContainer/Game/HBoxContainer/VBoxContainer/ItemList").add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		get_node("Panel/VBoxContainer/Game/HBoxContainer/VBoxContainer/ItemList").add_item(p)

	get_node("Panel/VBoxContainer/Game/HBoxContainer/VBoxContainer/Action").disabled=not get_tree().is_network_server()

func _on_start_pressed() -> void:
	gamestate.begin_game()
