extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var attack_ready = true
var is_attacking = false
var slide_ready = true
var is_sliding = false
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D
@onready var anim = $AnimationPlayer

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		#animated_sprite.play("jump")

	var direction = Input.get_axis("left", "right")
	
	if direction < 0:
		animated_sprite.scale.x = -1
	elif direction > 0:
		animated_sprite.scale.x = 1
		
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	#Handle animation
	if is_on_floor() and not is_attacking and not is_sliding:
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	elif not is_on_floor() and not is_attacking and not is_sliding:
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")

	if Input.is_action_pressed("slide") and slide_ready:
		slide_ready = false
		is_sliding = true
		$SlideTimer.start()
		anim.play("slide")
		
	if Input.is_action_pressed("attack") and attack_ready and not is_sliding:
		attack_ready = false
		is_attacking = true
		$AttackTimer.start()
		anim.play("attack")

	move_and_slide()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack":
		is_attacking = false
	elif anim_name == "slide":
		is_sliding= false

func _on_slide_timer_timeout():
	slide_ready = true
	
func _on_attack_timer_timeout():
	attack_ready = true
