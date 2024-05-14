extends CharacterBody3D

enum STATE {
	IDLE,
	WALKING,
	RUNNING,
	HANGING,
	JUMPING,
	CROUCHING
}

var state = STATE.IDLE

@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D

@onready var body = $Body
@onready var ledge_ray = $Body/Raycasts/LedgeRay
@onready var ledge_ray_horizontal = $Body/Raycasts/LedgeRayHorizontal
@onready var ledge_ray_horizontal_r = $Body/Raycasts/LedgeRayHorizontalR
@onready var ledge_ray_horizontal_l = $Body/Raycasts/LedgeRayHorizontalL
@onready var stab_ray = $Body/Raycasts/Stab

@onready var anim_tree = $AnimationTree
@onready var state_maschine: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

const SPEED = 5.0
const HANGING_SPEED = 1.5
const RUNNING_SPEED = 7.0
const CROUCH_SPEED = 3.0

const JUMP_VELOCITY = 5.5
const HANG_JUMP_VELOCITY = 7.5

var can_jump = true
var hanging = false
var sneaking = false
var running = false
var hidden = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		spring_arm_pivot.rotate_y(-event.relative.x * 0.005)
		spring_arm.rotate_x(-event.relative.y * 0.005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/4)
		
func get_speed():
	if hanging: return HANGING_SPEED
	if running: return RUNNING_SPEED
	if hidden: return CROUCH_SPEED
	return SPEED
	
func is_hidden():
	if Input.is_action_pressed("sneak"):
		for index in range(get_slide_collision_count()):
				var collision = get_slide_collision(index)
				if collision.get_collider().is_in_group("hidable"):
					return true
	return false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		can_jump = false
	else:
		if not can_jump: # player just landed
			state_maschine.travel("move")
			can_jump = true
	
	# update hidden state for example for grass if enemies are alerted
	hidden = is_hidden()
	
	# sneaking
	$Label3D.text = ""
	sneaking = Input.is_action_pressed("sneak")
	if sneaking:
		# stabing an enemy
		stab_ray.force_raycast_update()
		var collider = stab_ray.get_collider()
		if collider and collider.is_in_group("enemies"):
			var enemy = collider as CharacterBody3D
			
			$Label3D.text = "(Left mouse) to stab"
			if Input.is_action_just_pressed("left_click"):
				enemy.set_dead()
				
	# running
	running = Input.is_action_pressed("run")

	#Ledge hanging
	hanging = false
	if !is_on_floor() and velocity.y < 0:
		ledge_ray.force_raycast_update()
		if ledge_ray.is_colliding():
			ledge_ray_horizontal.force_raycast_update()
			if ledge_ray_horizontal.is_colliding():
				hanging = true
				can_jump = true
				velocity.y = 0
				state_maschine.travel("hang")
				
				# Staighten the player to the edge
				ledge_ray_horizontal_l.force_raycast_update()
				ledge_ray_horizontal_r.force_raycast_update()

				if ledge_ray_horizontal_l.is_colliding() and not ledge_ray_horizontal_r.is_colliding():
					body.rotation.y += 0.1
				if ledge_ray_horizontal_r.is_colliding() and not ledge_ray_horizontal_l.is_colliding():
					body.rotation.y -= 0.1
					
	if not hanging and not is_on_floor():
		state_maschine.travel("falling")
				
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = HANG_JUMP_VELOCITY if hanging else JUMP_VELOCITY
		state_maschine.travel("jump_start")
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
	if direction:
		velocity.x = lerp(velocity.x, direction.x * get_speed(), .3)
		velocity.z = lerp(velocity.z, direction.z * get_speed(), .3)
		if not hanging:
			body.rotation.y = lerp_angle(body.rotation.y, atan2(-velocity.x, -velocity.z), .3)
	else:
		velocity.x = lerp(velocity.x, 0.0, .3)
		velocity.z = lerp(velocity.z, 0.0, .3)

	var move_mode = 1 if sneaking else 0
	var move_speed = velocity.length() / (get_speed()/2) if running else velocity.length() / get_speed()
	anim_tree.set("parameters/move/blend_position", Vector2(move_speed, move_mode))
	# TODO fix left right animations (too high)
	#anim_tree.set("parameters/hang/BlendSpace1D/blend_position", input_dir.x)
	move_and_slide()
