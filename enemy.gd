extends CharacterBody2D

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

var current_id_path: Array[Vector2i]

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

func _physics_process(delta):
	match state:
		State.WANDERING:
			wander(delta)
		State.CHASING_FAR:
			chase_or_wander(delta)  # 추격하다가 떠돌아다니기 반복
		State.CHASING_CLOSE:
			chase_player(delta, speed_chasing_close)
	move_and_slide()

class PriorityQueue:
	var elements = []

	func is_empty() -> bool:
		return elements.size() == 0

	func push(item, priority):
		elements.append({"item": item, "priority": priority})
		_heapify_up(elements.size() - 1)

	func pop():
		if elements.size() == 1:
			return elements.pop_back()["item"]
		var root = elements[0]["item"]
		elements[0] = elements.pop_back()
		_heapify_down(0)
		return root

	func _heapify_up(index):
		while index > 0:
			var parent_index = int((index - 1) / 2)
			if elements[index]["priority"] >= elements[parent_index]["priority"]:
				break
			var temp = elements[index]
			elements[index] = elements[parent_index]
			elements[parent_index] = temp
			index = parent_index

	func _heapify_down(index):
		while index * 2 + 1 < elements.size():
			var child_index = index * 2 + 1
			if child_index + 1 < elements.size() and elements[child_index + 1]["priority"] < elements[child_index]["priority"]:
				child_index += 1
			if elements[index]["priority"] <= elements[child_index]["priority"]:
				break
			var temp = elements[index]
			elements[index] = elements[child_index]
			elements[child_index] = temp
			index = child_index


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

func get_neighbors(_position: Vector2i) -> Array:
	var neighbors = []
	var directions = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1),
		Vector2i(1, -1), Vector2i(-1, 1)
	]
	
	for direction in directions:
		var neighbor_position = _position + direction
		if neighbor_position.x >= 0 and neighbor_position.y >= 0 and neighbor_position.x <= 54 and neighbor_position.y <= 26:
			if grid_map[neighbor_position]["walkable"]:
				neighbors.append(neighbor_position)
	return neighbors

func heuristic_cost_estimate(start: Vector2i, goal: Vector2i) -> float:
	var D = 1
	var D2 = 1.4
	var dx = abs(goal.x - start.x)
	var dy = abs(goal.y - start.y)
	return D * (dx + dy) + (D2 - 2 * D) * min(dx, dy)

func a_star(start_position: Vector2i, goal_position: Vector2i) -> Array[Vector2i]:
	var open_set = PriorityQueue.new()
	open_set.push(start_position, 0)

	var came_from = {}
	var g_score = {}
	g_score[start_position] = 0

	while not open_set.is_empty():
		var current = open_set.pop()

		if current == goal_position:
			var total_path = [current] as Array[Vector2i]
			while came_from.has(current):
				current = came_from[current]
				total_path.insert(0, current)
			return total_path

		for neighbor in get_neighbors(current):
			var tentative_g_score = g_score.get(current, INF) + (1.4 if abs(current.x - neighbor.x) + abs(current.y - neighbor.y) == 2 else 1)

			if tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				var f_score = tentative_g_score + heuristic_cost_estimate(neighbor, goal_position)
				open_set.push(neighbor, f_score)

	return [] as Array[Vector2i]

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

func chase_player(delta, chase_speed):
	if player:
		var id_path = a_star(
			tile_map.local_to_map(global_position),
			tile_map.local_to_map(player.global_position)
		).slice(1)

		if id_path.is_empty() == false:
			current_id_path = id_path
	if current_id_path.is_empty():
		return

	var target_position = tile_map.map_to_local(current_id_path.front())
	velocity = (target_position - global_position).normalized() * chase_speed

	if global_position.distance_to(target_position) < 1.0:
		velocity = Vector2(0, 0)
		global_position = target_position
		current_id_path.pop_front()
		
func chase_or_wander(delta):
	if chase_timer.time_left > 0:
		chase_player(delta, speed_chasing_far)
	elif wander_timer.time_left > 0:
		wander(delta)

func _on_detect_area_2d_body_entered(body):
	player = body
	state = State.CHASING_FAR

func _on_detect_area_2d_body_exited(body):
	player = null
	current_id_path.clear()
	state = State.WANDERING
	needs_new_wander_path = true
	
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
