extends CharacterBody3D

@onready var navagent = $NavigationAgent3D

const SPEED = 3.0

func _physics_process(delta):
	var currentlocation = global_transform.origin
	var next = navagent.get_next_path_position()
	
	var new_vel = (next - currentlocation).normalized() * SPEED
	
	navagent.set_velocity(new_vel)

func update_target_location(target):
	navagent.target_position = target


func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, .25)
	move_and_slide()
