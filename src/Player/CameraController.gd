extends Node3D

@export var sensitivity = 5
var is_mouse_captured = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_mouse_captured = true

func _process(delta):
	global_position = $"..".global_position
	if Input.is_action_pressed("mouse_controll"):
		Input.mouse_mode =Input.MOUSE_MODE_VISIBLE
		is_mouse_captured = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		is_mouse_captured = true
		

func _input(event):
	if event is InputEventMouseMotion and is_mouse_captured:
		var xRot = clamp(rotation.x - event.relative.y / 1000 * sensitivity, -0.4, 0.4)
		var yRot = rotation.y - event.relative.x / 1000 * sensitivity
		rotation = Vector3(xRot, yRot, 0)
	if event is InputEventMouseButton and is_mouse_captured:
		if event.button_index == 5:
			if get_node("SpringArm3D").spring_length < 300:
				get_node("SpringArm3D").spring_length += 1.0
		if event.button_index == 4:
			if get_node("SpringArm3D").spring_length > 100:
				get_node("SpringArm3D").spring_length -= 1.0
