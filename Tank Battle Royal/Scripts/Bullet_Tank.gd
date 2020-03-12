extends RigidBody2D

var projectile_speed = 400
var life_time = 3
const scn_explosion = preload("res://Scenes/explosion.tscn")
var _damage : int = 10


func _ready():
	applyImpulse(Vector2(), Vector2(0, projectile_speed).rotated(rotation))

func applyImpulse(vector2, rotation):
	apply_impulse(vector2, rotation)

func _on_Bullet_Tank_body_entered(body):
	if !body.is_a_parent_of(self):
		if body is KinematicBody2D:
			body.emit_signal("damage_taken", self._damage)
		var explosion = scn_explosion.instance()
		explosion.position = global_position
		get_tree().get_root().add_child(explosion)
		queue_free()



