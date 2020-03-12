extends Node

func _process(delta):
	var turretNode = get_node("Node2D/Turret");
	var mousePos   = get_viewport().get_mouse_position();
	turretNode.look_at(mousePos);
	turretNode.rotate(deg2rad(-90));

func _on_Left_click():
	var sound = get_node("AudioStreamPlayer").play()

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			_on_Left_click();
