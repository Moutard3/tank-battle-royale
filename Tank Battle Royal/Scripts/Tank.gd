extends KinematicBody2D
class_name Tank

var _id : int
var _life : int = 100

var _bodyRotation : float = 0.0
var _turretRotation : float = 0.0;
export var _bodyRotationSpeed : float = 1.5
export var _turretRotationSpeed : float = 1.0
var _turretNode : KinematicBody2D
var _positionShootNode : Position2D
var _bodySprite : AnimatedSprite

export var _moveSpeed : int = 100
var _velocity : Vector2 = Vector2()

var _canFire : bool = true
var _fireRate :float = 0.8

puppet var puppetPosition : Vector2 = Vector2()
puppet var puppetVelocity : Vector2 = Vector2()
puppet var puppetRotation : float = 0.0
puppet var puppetTurretRotation : float = 0.0

signal damage_taken(damage)

func setPosition(newPosition : Vector2) -> void:
	self.position = newPosition

func getPosition() -> Vector2:
	return self.position
	
func setPositionShootNode(newPositionShootNode : Position2D) -> void:
	self._positionShootNode = newPositionShootNode

func getPositionShootNode() -> Position2D:
	return self._positionShootNode

func setTurretNode(newTurretNode : KinematicBody2D) -> void:
	self._turretNode = newTurretNode

func getTurretNode() -> KinematicBody2D:
	return self._turretNode

func setRotation(newRotation : float) -> void:
	self.rotation = newRotation
	
func getRotation() -> float:
	return self.rotation
	
func setVelocity(newVelocity : Vector2) -> void:
	self._velocity = newVelocity
	
func getVelocity() -> Vector2:
	return self._velocity
	
func setId(newId : int) -> void:
	self._id = newId
	
func getId() -> int:
	return self._id
	
sync func setAnimationTank(runAnimation : bool) -> void:
	if(runAnimation):
		self._bodySprite.play()
	else :
		self._bodySprite.stop()

sync func setFrameTank(frame : int) -> void:
	self._bodySprite.frame = frame

func _ready() -> void:
	#var blueTank = Tank.new(get_node("/Game/Tank/AnimatedSprite"))
	self._bodySprite = get_node("BodyTank")
	self._turretNode = get_node("Turret")
	self._positionShootNode = get_node("Turret/TurretSprite/PositionShoot")
	self.connect("damage_taken", self, "_on_damage_taken")
	
	if (is_network_master()):
		get_node("Camera2D").current = true

func _physics_process(delta) -> void:
	if (is_network_master()):
		move()
		shoot()
		rset("puppetVelocity", self.getVelocity())
		rset("puppetPosition", self.getPosition())
		rset("puppetRotation", self.getRotation())
		rset("puppetTurretRotation", self._turretRotation)
	else:
		self.setPosition(puppetPosition)
		self.setVelocity(puppetVelocity)
		self.setRotation(puppetRotation)
		self._turretRotation = puppetTurretRotation
	
	self.setVelocity(move_and_slide(self.getVelocity()))
	self.setRotation(
		self.getRotation() + 
		(_bodyRotation * _bodyRotationSpeed * delta)
	)
	_turretNode.rotation += _turretRotation * _turretRotationSpeed * delta

func _on_damage_taken(damage : int) -> void:
	self._life -= damage
	if (self._life <= 0):
		get_node("Camera2D").current = false
		get_node("/root/Game/Camera2D").current = true
		rpc("destroy_tank", self.getId())

remotesync func destroy_tank(id : int) -> void:
	get_node("/root/Game/Tank_"+str(id)).queue_free()

remotesync func createBullet(id:int) -> void:
	var bullet = preload("res://Scenes/Bullet_Tank.tscn").instance()
	bullet.position = get_node("/root/Game/Tank_"+str(id)).getPositionShootNode().global_position
	bullet.rotation_degrees = get_node("/root/Game/Tank_"+str(id)).getTurretNode().global_rotation_degrees
	get_parent().add_child(bullet)

func shoot():
	if (Input.is_action_pressed("shoot") && self._canFire):
		self._canFire = false;
		rpc_unreliable("createBullet",self.getId());
		yield(get_tree().create_timer(self._fireRate), "timeout")
		self._canFire=true;

func move() ->void:
	var oldVelocity = self.getVelocity()
	self._bodyRotation = 0
	self._turretRotation = 0
	self.setVelocity(Vector2())
	
	if (Input.is_action_pressed("turret_right")):
		self._turretRotation += 1
	elif (Input.is_action_pressed("turret_left")):
		self._turretRotation -= 1
	if (Input.is_action_pressed("move_right")):
		self._bodyRotation += 1
	elif (Input.is_action_pressed("move_left")):
		self._bodyRotation -= 1

	if (Input.is_action_pressed("move_down")):
		self.setVelocity(Vector2(-self._moveSpeed, 0).rotated(self.getRotation()))
	elif (Input.is_action_pressed("move_up")):
		self.setVelocity(Vector2(self._moveSpeed, 0).rotated(self.getRotation()))

	self.setVelocity(self.getVelocity().normalized() * self._moveSpeed)
	if (self.getVelocity().length() > 0):
		if(oldVelocity.length() == 0 ):
			rpc_unreliable("setFrameTank", (self._bodySprite.frame + 1) % 3);
		rpc_unreliable("setAnimationTank",true)
	elif(oldVelocity.length() > 0 ):
		rpc_unreliable("setAnimationTank",false)
