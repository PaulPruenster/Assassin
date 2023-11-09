extends CharacterBody3D

enum STATE {
	IDLE,
	ALERT,
	SEARCHING
}

@onready var navagent = $NavigationAgent3D
@onready var label = $Label3D
@onready var state = STATE.IDLE

const SPEED = 3.0

func _unhandled_input(event):
	if event.is_action_pressed("use"):
		state = (state + 1) % 3

func _physics_process(delta):
	if state == STATE.IDLE:
		label.text = ''
	if state == STATE.ALERT:
		label.text = '!'
	if state == STATE.SEARCHING:
		label.text = '?'
	
	var currentlocation = global_transform.origin
	
	var next = navagent.get_next_path_position()
	var new_vel = (next - currentlocation).normalized() * SPEED
	navagent.set_velocity(new_vel)

func update_target_location(target):
	if state == STATE.ALERT:
		navagent.target_position = target


func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, .25)
	move_and_slide()


func _on_navigation_agent_3d_target_reached():
	pass
