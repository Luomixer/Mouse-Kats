extends CharacterBody3D

@onready var JumpBufferTimer = $Timers/JumpBuffer
@onready var PlayerHitbox = $CollisionShape3D

var speed = 8.0
@export var WALK_SPEED = 8
@export var SPRINT_SPEED = 14
@export var CROUCH_SPEED = 4
@export var DECELERATION: float = 0.25
@export var ACCELERATION: float = 0.5
@export var AIR_DECELERATION: float = 2

const JUMP_HEIGHT: float = 5
const JUMP_PEAK: float = 0.64
const JUMP_DESCENT: float = 0.46
@onready var JUMP_VELOCITY: int = (2.0 * JUMP_HEIGHT) / JUMP_PEAK

# Get the gravity from the project settings to be synced with RigidBody nodes.
@onready var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var JUMP_GRAVITY: float = (2.0 * JUMP_HEIGHT) / (JUMP_PEAK * JUMP_PEAK)
@onready var FALL_GRAVITY: float = (2.0 * JUMP_HEIGHT) / (JUMP_DESCENT * JUMP_DESCENT)

@onready var neck := $CameraNeck
@onready var camera := $CameraNeck/Camera3D

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("LeftClick"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion:
		neck.rotate_y(-event.relative.x * 0.01)
		camera.rotate_x(-event.relative.y * 0.01)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GetGravity() * delta

	if Input.is_action_just_pressed("Jump"):
		JumpBufferTimer.start()
	
	var input_dir = Input.get_vector("MoveLeft","MoveRight","MoveForwards","MoveBackwards")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	ToggleSprinting()
	JumpBuffer()
	CrouchHandle()
	MoveHandle(direction, delta)
	move_and_slide()

func GetGravity():
	return JUMP_GRAVITY if velocity.y < 0.0 else FALL_GRAVITY

func JumpBuffer():
	if is_on_floor() and JumpBufferTimer.time_left > 0:
		velocity.y = JUMP_VELOCITY

func ToggleSprinting():
	if Input.is_action_pressed("Sprint"):
		print("sprinting")
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

func MoveHandle(direction, delta):
	if is_on_floor():
		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed, ACCELERATION)
			velocity.z = lerp(velocity.z, direction.z * speed, ACCELERATION)
		else:
			velocity.x = lerpf(velocity.x, 0, DECELERATION)
			velocity.z = lerpf(velocity.z, 0, DECELERATION)
	else:
		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * AIR_DECELERATION)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * AIR_DECELERATION)

func CrouchHandle():
	if Input.is_action_pressed("Crouch"):
		if !Input.is_action_pressed("Sprint"):
			neck.position.y = lerpf(neck.position.y,1.378, 0.1)
			PlayerHitbox.scale.y = lerpf(PlayerHitbox.scale.y, 0.5, 0.1)
		if is_on_floor():
			speed = CROUCH_SPEED
	else:
		PlayerHitbox.scale.y = lerpf(PlayerHitbox.scale.y, 1, 0.1)
		neck.position.y = lerpf(neck.position.y,1.878, 0.1)
