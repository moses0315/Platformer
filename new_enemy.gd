extends CharacterBody2D

var min_heap_class = preload("res://new_min_heap.gd")
@onready var player = $"../Player"
@onready var tile_map = $"../TileMap"
var goal
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
const GRID_SIZE = Vector2i(48, 27)
const TILE_SIZE = 16

func _ready():
	goal = tile_map.local_to_map(player.global_position)
	set_grid_map(tile_map)
	
func _physics_process(delta):
	move(speed)
	move_and_slide()

func move(speed):
	if path.is_empty():#첫번째에만 실행
		#var start = Vector2i(43, 25)  # 시작점
		#var goal = Vector2i(3, 3) # 목표점
		#path = a_star(start, goal, grid_map)
		var start = tile_map.local_to_map(global_position)
		goal = tile_map.local_to_map(player.global_position)
		path = a_star(start, goal, grid_map)
		current_path = path.slice(1)#path를 복사, 시작점도 경로에 포함되므로 첫번째 경로를 삭제
		
		print_grid(grid_map, path)
		
	if goal != tile_map.local_to_map(player.global_position):#플레이어 위치 바뀌면 path 초기화
		path = []
		return
	elif current_path.is_empty():#도착했으면 종료
		path = []
		return

	var next_target = tile_map.map_to_local(current_path.front())
	velocity = (next_target - global_position).normalized() * speed

	if global_position.distance_to(next_target) < 1.0:
		velocity = Vector2(0, 0)
		global_position = next_target
		current_path.pop_front()
		
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
	
func a_star(start: Vector2i, goal: Vector2i, grid_map):
	var open_set = min_heap_class.new()
	open_set.push([0, start])
	
	var came_from = {}
	var g_score = {start: 0}
	var f_score = {start: heuristic(start, goal)}
	
	var closed_set = {}

	while not open_set.is_empty():
		var current = open_set.pop()[1]

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
		for neighbor in get_heighbors(current, grid_map, closed_set):
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
				
		

func get_heighbors(current: Vector2i, grid_map, closed_set):
	var neighbors = []
	for direction in DIRECTIONS:
		var neighbor = current + direction
		
		# 대각선 이동을 할 때, 직선 이동이 모두 가능한지 확인
		if abs(direction.x) == 1 and abs(direction.x) == 1:
			var adjacent1 = Vector2i(current.x + direction.x, current.y)
			var adjacent2 = Vector2i(current.x, current.y + direction.y)
			# 만약 직선 방향의 둘 중 하나라도 벽(장애물)이라면, 대각선 이동을 막습니다.
			if not (is_walkable(adjacent1, grid_map) and is_walkable(adjacent2, grid_map)):
				continue
		if is_walkable(neighbor, grid_map) and neighbor not in closed_set:
			neighbors.append(neighbor)
	
	return neighbors as Array[Vector2i]
				
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
