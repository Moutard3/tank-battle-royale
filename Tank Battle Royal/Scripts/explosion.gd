extends Sprite


func _ready():
	get_node("animationExplo").play("fade_out")
	yield(get_node("animationExplo"),"animation_finished")
	queue_free()
