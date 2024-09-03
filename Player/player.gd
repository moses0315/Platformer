extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var health = 50

var attack_power = 10
var attack_ready = true
var is_attacking = false
var slide_ready = true
var is_sliding = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# 버퍼링 입력 및 코요테 타임 관련 변수
#var jump_buffer_time = 0.15  # 150ms 버퍼링 입력 시간
#var coyote_time = 0.25  # 250ms 코요테 타임
@onready var jump_buffer_timer = $JumpBufferTimer#0.0
@onready var coyote_timer = $CoyoteTimer#0.0
@onready var animaition_player = $AnimationPlayer
@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar

func _ready():
	health_bar.max_value = health
	health_bar.value = health
	
func _physics_process(delta):


	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		coyote_timer.start()  # 땅에 닿으면 코요테 타이머 초기화

	# 점프 버퍼링 처리
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()  # 점프 입력시 버퍼 타이머 시작

	# Handle jump.
	if jump_buffer_timer.time_left > 0 and (is_on_floor() or coyote_timer.time_left > 0):
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer.stop()  # 점프가 성공적으로 실행되면 버퍼 타이머 리셋
		coyote_timer.stop()  # 점프 후 코요테 타이머 리셋
		animaition_player.play("jump")

	var direction = Input.get_axis("left", "right")
	
	if not is_attacking:
		if direction < 0:
			animated_sprite.scale.x = -1
		elif direction > 0:
			animated_sprite.scale.x = 1
		
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Handle animation
	if is_on_floor() and not is_attacking and not is_sliding:
		if direction == 0:
			animaition_player.play("idle")
		else:
			animaition_player.play("run")
	elif not is_on_floor() and not is_attacking and not is_sliding:
		if velocity.y < 0:
			animaition_player.play("jump")
		else:
			animaition_player.play("fall")

	if Input.is_action_pressed("slide") and slide_ready:
		slide_ready = false
		is_sliding = true
		$SlideTimer.start()
		animaition_player.play("slide")
		
	if Input.is_action_pressed("attack") and attack_ready and not is_sliding:
		attack_ready = false
		is_attacking = true
		$AttackTimer.start()
		animaition_player.play("attack")

	move_and_slide()
	
func take_damage(damage):
	health -= damage
	health_bar.value = health
	if health <= 0:
		queue_free()
	animated_sprite.set_modulate(Color(1000, 1000, 1000))
	await get_tree().create_timer(0.15).timeout
	animated_sprite.set_modulate(Color(1, 1, 1))
	
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack":
		is_attacking = false
	elif anim_name == "slide":
		is_sliding= false

func _on_slide_timer_timeout():
	slide_ready = true
	
func _on_attack_timer_timeout():
	attack_ready = true


func _on_attack_area_2d_body_entered(body):
	if animated_sprite.scale.x == 1:
		body.take_damage(attack_power, 1)
	else:
		body.take_damage(attack_power, -1)
