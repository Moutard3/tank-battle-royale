extends Button

func _on_Join_lobby_pressed():
	get_tree().change_scene("res://Scenes/Lobby.tscn")
	 


func _on_Quit_pressed():
	get_tree().quit()

