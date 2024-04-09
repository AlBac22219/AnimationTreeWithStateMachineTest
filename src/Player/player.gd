extends CharacterBody3D

@export var battle_mode_timer: Timer
@export var combo_timer: Timer
@export var jump_timer: Timer

var cameraControllerNode = null
const ACCELERATION = 3.0
const MAX_SPEED = 200.0
var finalSpeed = 0.0
const ROT = 2.0
const JUMP_VELOCITY = 70
var battleMode = false
var punchTimer = false
var combat_state = false
var last_punch = null
var enemies = []

enum states {
	IDLE,
	FALL,
	JUMP,
	WALK,
	FIGHT,
	PUNCH_ONE,
	PUNCH_TWO,
	PUNCH_THREE,
	POWER_PUNCH,
	FIGHT_WALK
}

var state = null

@onready var animaPlayer = $AnimationTree
@onready var playback = animaPlayer.get("parameters/playback")

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	state = states.IDLE
	cameraControllerNode = get_node("CameraController")

func _physics_process(delta):
	var new_state = null
	if not combat_state:
		new_state = states.IDLE
	var direction = Vector3(0, 0, Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward"))
	rotate_y((Input.get_action_strength("move_left") - Input.get_action_strength("move_right")) * ROT * delta)
	new_state = walk(direction, new_state)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not combat_state:
		new_state = states.JUMP
	if not is_on_floor():
		velocity.y -= gravity * delta
		new_state = states.FALL
	if (enemies.size() != 0 or battleMode) and not combat_state:
		match new_state:
			states.WALK:
				new_state = states.FIGHT_WALK
			_:
				new_state = states.FIGHT
	if not new_state == null and not new_state == state:
		state = new_state
	state_machine()
	move_and_slide()

func _input(event):
	if Input.is_action_just_pressed("left_click") and not combat_state:
		battle_mode_timer.start(10)
		battleMode = true
		combo_timer.start(3.2)
		punchTimer = true
		match last_punch:
			states.PUNCH_ONE:
				state = states.PUNCH_TWO
				last_punch = states.PUNCH_TWO
			states.PUNCH_TWO:
				state = states.PUNCH_THREE
				last_punch = states.PUNCH_THREE
			_:
				state = states.PUNCH_ONE
				last_punch = states.PUNCH_ONE
		combat_state = true
		velocity = Vector3.ZERO
		return
	if Input.is_action_pressed("left_click") and not combat_state:
		battle_mode_timer.start(10)
		battleMode = true
		combo_timer.start(1.4)
		punchTimer = true
		state = states.POWER_PUNCH
		last_punch = states.POWER_PUNCH
		combat_state = true
		velocity = Vector3.ZERO
		return

func walk(direction, old_state):
	if not combat_state:
		if direction:
			direction = direction.rotated(Vector3(0,1,0), rotation.y)
			velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION)
			velocity.z = move_toward(velocity.z, direction.z * MAX_SPEED, ACCELERATION)
			return states.WALK
		else:
			velocity.x = move_toward(velocity.x, 0, ACCELERATION*3)
			velocity.z = move_toward(velocity.z, 0, ACCELERATION*3)
		return old_state

func state_machine():
	match state:
		states.IDLE:
			$AnimationTree["parameters/playback"].travel("Idle_Idle")
		states.FALL:
			$AnimationTree["parameters/playback"].travel("Boxing_Falling_Idle")
		states.JUMP:
			$AnimationTree["parameters/playback"].travel("Boxing_Jump_up")
			jump_timer.start(0.7)
		states.WALK:
			var speed = get_velocity()
			var amount = sqrt((0.0 - speed[0]) * (0.0 - speed[0]) + (0.0 - speed[2]) * (0.0 - speed[2]))/MAX_SPEED
			$AnimationTree.set("parameters/Idle_movement/blend_position", amount)
			$AnimationTree["parameters/playback"].travel("Idle_movement")
		states.FIGHT:
			$AnimationTree["parameters/playback"].travel("Boxing_Boxing_Idle")
		states.PUNCH_ONE:
			$AnimationTree["parameters/playback"].travel("Boxing_Boxing_left_hook")
		states.PUNCH_TWO:
			$AnimationTree["parameters/playback"].travel("Boxing_Boxing_right_hook")
		states.PUNCH_THREE:
			$AnimationTree["parameters/playback"].travel("Boxing_Boxing_double_punch")
		states.POWER_PUNCH:
			$AnimationTree["parameters/playback"].travel("Boxing_Boxing_upper_cut")
		states.FIGHT_WALK:
			$AnimationTree["parameters/playback"].travel("Boxing_movement")


func _on_animation_tree_animation_finished(anim_name):
	match anim_name:
		"Boxing/Boxing_upper_cut":
			combat_state = false
		"Boxing/Boxing_left_hook":
			combat_state = false
		"Boxing/Boxing_right_hook":
			combat_state = false
		"Boxing/Boxing_double_punch":
			combat_state = false
	state = states.FIGHT

func _on_battle_mode_timer_timeout():
	battleMode = false


func _on_combo_timer_timeout():
	punchTimer = false
	last_punch = null


func _on_jump_timer_timeout():
	velocity.y = JUMP_VELOCITY
