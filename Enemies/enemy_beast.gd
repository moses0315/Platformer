extends CharacterBody2D
@export var target_direction = "center"
var min_heap_class = preload("res://min_heap.gd")

@onready var player = null
@onready var tile_map = $"../TileMap"
@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var health_bar = $HealthBar

enum State {WANDERING, CHASING_FAR, CHASING_CLOSE}
var goal
var previous_goal = Vector2i(-1, -1)  # 이전 목표 위치를 저장하는 변수
var speed = 100
var grid_map = {}
var path: Array[Vector2i]
var current_path: Array[Vector2i]
const DIRECTIONS = [
	Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, -1),
	Vector2i(1, -1), Vector2i(-1, 1)
]
const GOAL_DIRECTIONS = {
	"left":  [Vector2i(-4, 0), Vector2i(-3, 0), Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0)],
	"right": [Vector2i(4, 0), Vector2i(3, 0), Vector2i(2, 0), Vector2i(1, 0), Vector2i(0, 0)],
	"up":    [Vector2i(0, -4), Vector2i(0, -3), Vector2i(0, -2), Vector2i(0, -1), Vector2i(0, 0)],
	"down":  [Vector2i(0, 4), Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 1), Vector2i(0, 0)],
	"center":[Vector2i(0, 0)] 
}
const GRID_SIZE = Vector2i(58, 27)
const TILE_SIZE = 16

var can_attack = true
var player_in_attack_range = false
var attack_power = 10
var is_attacking = false
var health = 50

var is_close_to_player = false
var knuckback_timer = 0.0
var knuckback_direction
func _ready():
	animated_sprite.play("idle")
	health_bar.max_value = health
	health_bar.value = health
	set_grid_map(tile_map)
	
func _physics_process(delta):
	if knuckback_timer > 0: 
		knuckback_timer -= delta
		velocity.x = knuckback_direction * 1000
		move_and_slide()
		return
	else:
		velocity = Vector2(0, 0)

	move(speed)
	if player_in_attack_range and can_attack:
		attack()
	move_and_slide()

func attack():
	if global_position.x - player.global_position.x > 0:
		animated_sprite.scale.x = -1
	elif global_position.x - player.global_position.x < 0:
		animated_sprite.scale.x = 1
	is_attacking = true
	can_attack = false
	$AttackTimer.start()
	animation_player.play("attack")
	
func move(speed):
	if player:
		#if path.is_empty():#첫번째에만 실행
		var start = tile_map.local_to_map(global_position)
		is_close_to_player = false
		for i in GOAL_DIRECTIONS[target_direction]:
			if tile_map.local_to_map(global_position) == tile_map.local_to_map(player.global_position)+i:
				is_close_to_player = true
		if not is_close_to_player:
			goal = set_goal()#tile_map.local_to_map(player.global_position)
		else:
			goal = tile_map.local_to_map(player.global_position)
					# 새로운 목표 위치가 이전 목표 위치와 다르면 경로 초기화
		if goal != previous_goal:
			path = a_star(start, goal, grid_map)
			current_path = path.slice(1)
			previous_goal = goal  # 현재 목표 위치를 저장
		#print_grid(grid_map, path)
		
		#if goal != set_goal():#플레이어 위치 바뀌면 path 초기화
			#path = []
	if current_path.is_empty():#도착했으면 종료
		path = []
		#다음 목표는 target_position이 아닌 player position
		return

	var next_target = tile_map.map_to_local(current_path.front())
	velocity = (next_target - global_position).normalized() * speed
	if not is_attacking:
		if velocity.x < 0:
			animated_sprite.scale.x = -1
		elif velocity.x > 0:
			animated_sprite.scale.x = 1
	if global_position.distance_to(next_target) < 4:
		velocity = Vector2(0, 0)
		current_path.pop_front()
#func move(speed):
	#if player:
		#var start = tile_map.local_to_map(global_position)
		#if not is_close_to_player:
			#print("123456789")
			#goal = set_goal()#tile_map.local_to_map(player.global_position)
		#else:
			#print("not!!")
			#goal = tile_map.local_to_map(player.global_position)
		#path = a_star(start, goal, grid_map)
		#current_path = path.slice(1)#path를 복사, 시작점도 경로에 포함되므로 첫번째 경로를 삭제
		##print_grid(grid_map, path)
		#
	#if current_path.is_empty():#도착했으면 종료
		#return
	#var next_target = tile_map.map_to_local(current_path.front())
	#velocity = (next_target - global_position).normalized() * speed
	#if not is_attacking:
		#if velocity.x < 0:
			#animated_sprite.scale.x = -1
		#elif velocity.x > 0:
			#animated_sprite.scale.x = 1
	#if global_position.distance_to(next_target) < 10:
		#velocity = Vector2(0, 0)
		#current_path.pop_front()
		
func set_grid_map(tile_map):
	var used_rect = tile_map.get_used_rect()

	for x in range(used_rect.size.x):
		for y in range(used_rect.size.y):
			var tile_position = Vector2i(
				x + used_rect.position.x,
				y + used_rect.position.y
			)
			var tile_data = tile_map.get_cell_tile_data(0, tile_position)
			if tile_data == null or tile_data.get_custom_data("walkable") == true:
				grid_map[tile_position] = {"wall": false}
			else:
				grid_map[tile_position] = {"wall": true}
				
func set_goal():
	var player_position = tile_map.local_to_map(player.global_position)
	for offset in GOAL_DIRECTIONS[target_direction]:
		var target_tile = player_position + offset

		if is_walkable(target_tile, grid_map) and is_walkable(target_tile+Vector2i(0,1), grid_map):
			return target_tile# 벽이 아닌 타일을 찾으면 해당 타일을 목표로 설정
	return player_position  # 모든 타일이 벽일 경우, 플레이어 위치 반환

func a_star(start: Vector2i, goal: Vector2i, grid_map):
	#경로를 덱 방식으로 바꾸기
	#open_set에 중복 추가되는 노드 삭제하기
	var open_set = min_heap_class.new()
	open_set.push([0, start])
	
	var came_from = {}
	var g_score = {start: 0}
	var f_score = {start: heuristic(start, goal)}
	
	var closed_set = {}
	var tile_check_count = 0  # 타일 검사 개수 추적용 변수

	while not open_set.is_empty():
		var current = open_set.pop()[1]
		# 타일 검사 카운트 증가
		tile_check_count += 1

		# 타일 검사 개수가 100개를 넘으면 경고 메시지 출력
		#if tile_check_count > 1100:
			#print("경고: 타일 검사 개수가 많습니다! (", tile_check_count, "개)")
		#경로를 다 찾았으면 경로 재구성 후 종료
		if current == goal:
			var path = [current] as Array[Vector2i]
			while current in came_from:
				current = came_from[current]
				path.append(current)
			path.reverse()
			return path
			
		closed_set[current] = true
		
		#이웃 노드 조사
		for neighbor in get_neighbors(current, grid_map, closed_set):
			var tentative_g_score
			if current.x != neighbor.x and current.y != neighbor.y:
				tentative_g_score = g_score[current] + 14
			else:
				tentative_g_score = g_score[current] + 10
			
			# 이웃 노드가 처음 방문되었거나 더 좋은 경로가 발견되면 정보를 갱신합니다.
			if neighbor not in g_score or tentative_g_score < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + heuristic(neighbor, goal)
				open_set.push([f_score[neighbor], neighbor])
				
	return [] as Array[Vector2i]
				
		

func get_neighbors(current: Vector2i, grid_map, closed_set):
	var neighbors = []
	
	for direction in DIRECTIONS:
		var neighbor = current + direction
		
		# Check for diagonal movement
		if abs(direction.x) == 1 and abs(direction.y) == 1:
			var adjacent1 = Vector2i(current.x + direction.x, current.y)
			var adjacent2 = Vector2i(current.x, current.y + direction.y)
			var adjacent3 = Vector2i(current.x + direction.x, current.y + 1)
			var adjacent4 = Vector2i(current.x, current.y + 1 + direction.y)
			
			# If any of the straight or diagonal blocks are obstacles, continue to the next direction
			if not (is_walkable(adjacent1, grid_map) and is_walkable(adjacent2, grid_map) and
					is_walkable(adjacent3, grid_map) and is_walkable(adjacent4, grid_map)):
				continue
				
		# Check for vertical movement
		elif direction.y != 0:
			var next_row = current.y + direction.y
			if not is_walkable(Vector2i(current.x, next_row), grid_map) or \
			   not is_walkable(Vector2i(current.x, next_row + 1), grid_map):
				continue
				
		# Check for horizontal movement
		elif direction.x != 0:
			var next_col = current.x + direction.x
			if not is_walkable(Vector2i(next_col, current.y), grid_map) or \
			   not is_walkable(Vector2i(next_col, current.y + 1), grid_map):
				continue
				
		# If all checks pass, add the neighbor
		if is_walkable(neighbor, grid_map) and neighbor not in closed_set:
			neighbors.append(neighbor)
	
	return neighbors as Array[Vector2i]

#func get_neighbors(current: Vector2i, grid_map, closed_set):
	#var neighbors = []
	#for direction in DIRECTIONS:
		#var neighbor = current + direction
		#
		## 대각선 이동을 할 때, 직선 이동이 모두 가능한지 확인
		#if abs(direction.x) == 1 and abs(direction.x) == 1:
			#var adjacent1 = Vector2i(current.x + direction.x, current.y)
			#var adjacent2 = Vector2i(current.x, current.y + direction.y)
			## 만약 직선 방향의 둘 중 하나라도 벽(장애물)이라면, 대각선 이동을 막습니다.
			#if not (is_walkable(adjacent1, grid_map) and is_walkable(adjacent2, grid_map)):
				#continue
		#if is_walkable(neighbor, grid_map) and neighbor not in closed_set:
			#neighbors.append(neighbor)
	#
	#return neighbors as Array[Vector2i]
				
func heuristic(node: Vector2i, goal: Vector2i):
	var dx = abs(node.x - goal.x)
	var dy = abs(node.y - goal.y)
	return 10 * (dx + dy) + (14 - 2 * 10) * min(dx, dy)

func is_walkable(node: Vector2i, grid_map):
	#맵 밖이나 벽이 아니라면 True
	return 0 <= node.x and node.x < GRID_SIZE[0] and 0 <= node.y and node.y < GRID_SIZE[1] and not grid_map[node]["wall"]

func print_grid(grid_map, path: Array[Vector2i]):
	var output = ""
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			if path and Vector2i(x, y) in path:
				output += "P"  # 경로가 지나가는 곳은 'P'로 표시
			elif grid_map[Vector2i(x, y)]["wall"]:
				output += "#"  # 장애물은 '#'으로 표시
			else:
				output += "."  # 이동 가능한 곳은 '.'로 표시
		output += "\n"
	print(output)

func take_damage(damage, direction):
	knuckback_timer = 0.02
	knuckback_direction = direction
	health -= damage
	health_bar.value = health
	if health <= 0:
		queue_free()
	animated_sprite.set_modulate(Color(1000, 1000, 1000))
	await get_tree().create_timer(0.15).timeout
	animated_sprite.set_modulate(Color(1, 1, 1))
		
func _on_attack_timer_timeout():
	can_attack = true

func _on_attack_range_area_2d_body_entered(body):
	player_in_attack_range = true

func _on_attack_range_area_2d_body_exited(body):
	player_in_attack_range = false

func _on_attack_area_2d_body_entered(body):
	if animated_sprite.scale.x == 1:
		body.take_damage(attack_power, 1)
	else:
		body.take_damage(attack_power, -1)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "attack":
		is_attacking = false
		animated_sprite.play("move")


func _on_detect_area_2d_body_entered(body):
	player = body
	animated_sprite.play("move")

func _on_detect_area_2d_body_exited(body):
	player = null
	animated_sprite.play("idle")


func _on_detect_close_area_2d_body_entered(body):
	is_close_to_player = true


func _on_detect_close_area_2d_body_exited(body):
	is_close_to_player = false
