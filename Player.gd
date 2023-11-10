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

const SPEED = 7.0
const HANGING_SPEED = 1.5

const JUMP_VELOCITY = 5.5
const HANG_JUMP_VELOCITY = 6.5

var can_jump = true
var hanging = false

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
#	if hanging or not is_on_floor():
#			return HANGING_SPEED
#	return SPEED
	return HANGING_SPEED if hanging else SPEED

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		can_jump = false
	else: 
		can_jump = true
		
	if Input.is_action_just_pressed("sneak"):
		stab_ray.force_raycast_update()
		var collider = stab_ray.get_collider()
		if collider and collider.is_in_group("enemies"):
			var enemy = collider as CharacterBody3D
			var rotation_difference = abs(enemy.rotation.y - rotation.y)

			print(rotation_difference)
			enemy.set_dead()

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
				
				# Staighten the player to the edge
				ledge_ray_horizontal_l.force_raycast_update()
				ledge_ray_horizontal_r.force_raycast_update()

				if ledge_ray_horizontal_l.is_colliding() and not ledge_ray_horizontal_r.is_colliding():
					body.rotation.y += 0.1
				if ledge_ray_horizontal_r.is_colliding() and not ledge_ray_horizontal_l.is_colliding():
					body.rotation.y -= 0.1
				
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = HANG_JUMP_VELOCITY if hanging else JUMP_VELOCITY
	
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

	anim_tree.set("parameters/BlendSpace1D/blend_position", velocity.length() / get_speed())

	move_and_slide()
