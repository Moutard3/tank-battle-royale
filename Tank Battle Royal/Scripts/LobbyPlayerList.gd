extends Control

const _crown = preload("res://img/crown.png")

remote func start_game(spawn_points: Dictionary):
	var players = gamestate.get_players();
	var game = preload("res://Scenes/Game.tscn")
	var gameInstance = game.instance()
	get_tree().get_root().add_child(gameInstance)
	var player = preload("res://Scenes/Tank.tscn")
	
	for p_id in spawn_points:
		var tank = player.instance()
		tank.name = "player "+str(p_id)
		tank.position = get_tree().get_root().get_node("Game").get_node("Spawn"+str(spawn_points[p_id])).position
		tank.setId(p_id)
		tank.set_name("Tank_"+str(p_id))
		tank.set_network_master(p_id)
		get_tree().get_root().get_node("Game").add_child(tank)

sync func _log(what):
	$HBoxContainer/RichTextLabel.add_text(what + "\n")

func _on_Action_pressed():
	var spawn_points = {}
	spawn_points[1] = 1 # Server in spawn point 0
	var spawn_point_idx = 2
	var players = gamestate.get_players();
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
	
	for id in players :
		rpc_id(id, "start_game", spawn_points)
	start_game(spawn_points)
