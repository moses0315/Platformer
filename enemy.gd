extends CharacterBody2D

var min_heap_class = preload("res://min_heap.gd")

@export var prefers_left: bool = true

@onready var tile_map = $"../TileMap"
@onready var chase_timer = $ChaseTimer
@onready var wander_timer = $WanderTimer
@onready var wander_stop_timer = $WanderStopTimer

var is_chasing = false
var needs_new_wander_path: bool = true

enum State {
	WANDERING,
	CHASING_FAR,
	CHASING_CLOSE
}
var directions = [
	Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, -1),
	Vector2i(1, -1), Vector2i(-1, 1)
]
var current_id_path: Array[Vector2i]

var previous_player_grid_position = Vector2i(-1, -1)

var grid_map = {}
var tile_map_size: Vector2i
var tile_size : int
var player = null
var speed_wandering = 50
var speed_chasing_far = 100
var speed_chasing_close = 100

var state = State.WANDERING

func _ready():
	tile_size = tile_map.tile_set.tile_size.x
	setup_grid_from_tilemap(tile_map)
func _draw():
	# 경로가 비어있지 않을 때만 시각화
	if not current_id_path.is_empty():
		# 첫 번째 위치를 현재 캐릭터의 위치로 설정
		var previous_point = global_position

		# 경로를 따라 선을 그림
		for path_point in current_id_path:
			var target_position = tile_map.map_to_local(path_point)
			draw_line(previous_point, target_position, Color(1, 0, 0), 2)
			previous_point = target_position

func _physics_process(delta):
	match state:
		State.WANDERING:
			wander(delta)
		State.CHASING_FAR:
			chase_player(delta, speed_chasing_close)
			#chase_or_wander(delta)  # 추격하다가 떠돌아다니기 반복
		State.CHASING_CLOSE:
			chase_player(delta, speed_chasing_close)
	move_and_slide()


# A* 알고리즘 구현
func setup_grid_from_tilemap(tile_map):
	tile_map_size = Vector2i(880, 432)
	var used_rect = tile_map.get_used_rect()
	
	for x in range(used_rect.size.x):
		for y in range(used_rect.size.y):
			var tile_position = Vector2i(
				x + used_rect.position.x,
				y + used_rect.position.y
			)
			var tile_data = tile_map.get_cell_tile_data(0, tile_position)
			if tile_data == null or tile_data.get_custom_data("walkable") == true:
				grid_map[tile_position] = {"walkable": true}
			else:
				grid_map[tile_position] = {"walkable": false}


func heuristic(start: Vector2i, goal: Vector2i) -> float:
	var D = 1
	var D2 = 1.4
	var dx = abs(goal.x - start.x)
	var dy = abs(goal.y - start.y)
	return D * (dx + dy) + (D2 - 2 * D) * min(dx, dy)

func a_star(start_position: Vector2i, goal_position: Vector2i):
	var open_set = min_heap_class.new()
	open_set.push(start_position, 0)

	var came_from = {}
	var g_score = {start_position: 0}
	var closed_set = {}

	while not open_set.is_empty():
		var current = open_set.pop()

		if current == goal_position:
			var total_path = [current] as Array[Vector2i]
			while current in came_from:
				current = came_from[current]
				total_path.append(current)
			return total_path
			
		closed_set[current] = true

		#get neighbors
		var neighbors = []
		for direction in directions:
			var neighbor_position = current + direction
			if neighbor_position.x >= 0 and neighbor_position.y >= 0 \
			and neighbor_position.x <= 54 and neighbor_position.y <= 26 \
			and grid_map[neighbor_position]["walkable"] and neighbor_position:# not in closed_set:
				if abs(direction.x) == 1 and abs(direction.y) == 1:#대각선 이동이라면 
					var adjacent1 = Vector2i(current.x + direction.x, current.y)
					var adjacent2 = Vector2i(current.x, current.y + direction.y)
					if grid_map[adjacent1]["walkable"] and grid_map[adjacent2]["walkable"]:#직선 타일 두개 다 이동 가능이어야지 
						neighbors.append(neighbor_position)
				else:
					neighbors.append(neighbor_position)

		#check neighbors
		for neighbor in neighbors:
			var tentative_g_score = g_score.get(current, INF) + \
			(1.4 if abs(current.x - neighbor.x) + abs(current.y - neighbor.y) == 2 else 1)

			if tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				var f_score = tentative_g_score + heuristic(neighbor, goal_position)
				open_set.push(neighbor, f_score)

	#return [] as Array[Vector2i]

func set_random_target():
	var current_position = tile_map.local_to_map(global_position)
	var random_target = Vector2i(randi() % tile_map.get_used_rect().size.x, randi() % tile_map.get_used_rect().size.y)

	random_target.x = clamp(random_target.x, 0, tile_map.get_used_rect().size.x - 1)
	random_target.y = clamp(random_target.y, 0, tile_map.get_used_rect().size.y - 1)

func wander(delta):
	if needs_new_wander_path:
		current_id_path.clear()
		set_random_target()
		needs_new_wander_path = false
		
	if current_id_path.is_empty() == false:
		var next_point = current_id_path.front()
		if next_point != null:
			var target_position = tile_map.map_to_local(next_point)
			velocity = (target_position - global_position).normalized() * speed_wandering
			if global_position.distance_to(target_position) < 1.0:
				velocity = Vector2(0, 0)
				global_position = target_position
				current_id_path.pop_front()

	if current_id_path.is_empty():
		needs_new_wander_path = true
		if wander_stop_timer.is_stopped():
			wander_stop_timer.start()


func chase_player(delta, chase_speed):#플레이어의 위치를 장애물 위치로 파악해서 날라가는 거일수도
	# 최종 도착지점에 도달한 경우에만 새로운 경로를 계산
	if current_id_path.is_empty():
		# 플레이어의 현재 그리드 위치를 계산
		var current_player_grid_position = tile_map.local_to_map(player.global_position)

		# 경로를 재계산
		var id_path = a_star(
			tile_map.local_to_map(global_position),
			Vector2i(3, 3)#current_player_grid_position
		)
		id_path.pop_back()  # 현재 위치를 나타내는 맨 뒤 번째 노드를 제거

		# 경로가 유효하면 업데이트
		if not id_path.is_empty():
			current_id_path = id_path
	print(current_id_path)
	# 경로가 비어있다면 아무것도 하지 않음
	if current_id_path.is_empty():
		velocity = Vector2(0, 0)
		return

	# 현재 경로의 다음 목표 지점
	var target_position = tile_map.map_to_local(current_id_path.back())
	# 방향 설정
	velocity = (target_position - global_position).normalized() * chase_speed

	# 목표 위치에 도달했는지 확인 후 경로 업데이트
	if global_position.distance_to(target_position) < 1:
		global_position = target_position
		current_id_path.pop_back()


		# 최종 도착점에 도달했을 때, velocity를 0으로 설정
		if current_id_path.is_empty():
			velocity = Vector2(0, 0)
			return
	if not current_id_path.is_empty():
		# 방향 설정
		velocity = (target_position - global_position).normalized() * chase_speed

#func chase_player(delta, chase_speed):
	#if player:
		#var id_path = a_star(
			#tile_map.local_to_map(global_position),
			#tile_map.local_to_map(player.global_position)
		#).slice(1)
#
		#if id_path.is_empty() == false:
			#current_id_path = id_path
	#if current_id_path.is_empty():
		#return
#
	#var target_position = tile_map.map_to_local(current_id_path.front())
	#velocity = (target_position - global_position).normalized() * chase_speed
#
	#if global_position.distance_to(target_position) < 1.0:
		#velocity = Vector2(0, 0)
		#global_position = target_position
		#current_id_path.pop_front()
		
func chase_or_wander(delta):
	if chase_timer.time_left > 0:
		chase_player(delta, speed_chasing_far)
	elif wander_timer.time_left > 0:
		wander(delta)

func _on_detect_area_2d_body_entered(body):
	player = body
	state = State.CHASING_FAR

func _on_detect_area_2d_body_exited(body):
	pass
	#player = null
	#current_id_path.clear()
	#state = State.WANDERING
	#needs_new_wander_path = true
	
func _on_detect_close_area_2d_body_entered(body):
	state = State.CHASING_CLOSE

func _on_detect_close_area_2d_body_exited(body):
	state = State.CHASING_FAR

func _on_chase_timer_timeout():
	wander_timer.start()
	needs_new_wander_path = true
	
func _on_wander_timer_timeout():
	chase_timer.start()

func _on_wander_stop_timer_timeout():
	pass
