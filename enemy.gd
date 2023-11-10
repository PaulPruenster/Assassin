extends CharacterBody3D

enum STATE {
	IDLE,
	ALERT,
	SEARCHING,
	DEAD
}

@onready var navagent = $NavigationAgent3D
@onready var label = $Label3D
@onready var body = $Body

@onready var raycast = $CanSeePlayer

@onready var state = STATE.IDLE

const SPEED = 5.0

func _unhandled_input(event):
	if event.is_action_pressed("use") and state != STATE.DEAD:
		state = (state + 1) % 3 as STATE
		
func can_see_player(target):
	raycast.target_position = target - raycast.global_position
	raycast.force_raycast_update()
	var collider = raycast.get_collider()
	
	return collider and collider.is_in_group("player")

func set_alert():
	if state != STATE.DEAD:
		state = STATE.ALERT
		
func set_dead():
	state = STATE.DEAD
	get_tree().call_group("enemies", "set_alert")
	$CollisionShape3D.disabled = true
	$DespawnTimer.start()

func _physics_process(delta):
	if state == STATE.DEAD:
		label.font_size = 50
		label.text = 'RIP'
		navagent.set_velocity(Vector3(0,0,0))
		return
	if state == STATE.IDLE:
		label.text = ''
	if state == STATE.ALERT:
		label.text = '!'
	if state == STATE.SEARCHING:
		label.text = '?'
	
	var currentlocation = global_transform.origin
	
	var next = navagent.get_next_path_position()
	var new_vel = (next - currentlocation).normalized() * SPEED
	
	body.rotation.y = lerp_angle(body.rotation.y, atan2(velocity.x, velocity.z), .3)
	navagent.set_velocity(new_vel)

func update_target_location(target):	
	var sees_player = can_see_player(target)
	
	if state == STATE.ALERT:
		if sees_player:
			navagent.target_position = target
		else:
			state = STATE.SEARCHING
			$SearchTimer.start()
		
	if state == STATE.SEARCHING and sees_player:
		state = STATE.ALERT
		$SearchTimer.stop()


func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, .25)
	$AnimationTree.set("parameters/BlendSpace1D/blend_position", velocity.length() / SPEED)
	move_and_slide()


func _on_navigation_agent_3d_target_reached():
	pass


func _on_despawn_timer_timeout():
	queue_free()


func _on_search_timer_timeout():
	state = STATE.IDLE
