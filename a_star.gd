extends Node



# A* 알고리즘을 사용하여 최단 경로를 찾는 함수
func a_star(start: Vector2i, goal: Vector2i, grid):
	var open_set = MinHeap.new()
	open_set.push([0, start])  # [f_score, start] 형태의 Array 사용

	var came_from = {}
	var g_score = {}
	var f_score = {}
	g_score[start] = 0
	f_score[start] = heuristic(start, goal)
	var closed_set = {}

	while not open_set.is_empty():
		var current = open_set.pop()[1]  # pop() 결과로 얻은 Array에서 노드 좌표를 가져옴


		if current == goal:
			return reconstruct_path(came_from, current)

		closed_set[current] = true
		
		for neighbor in get_neighbors(current, grid, closed_set):
			var tentative_g_score = g_score.get(current, INF) + movement_cost(current, neighbor)
			
			if not g_score.has(neighbor) or tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + heuristic(neighbor, goal)
				open_set.push([f_score[neighbor], neighbor])  # Array 사용

	
	return []

func movement_cost(node_a: Vector2i, node_b: Vector2i) -> int:
	if node_a.x != node_b.x and node_a.y != node_b.y:
		return 14
	else:
		return 10

func get_neighbors(node: Vector2i, grid, closed_set):
	var neighbors = []
	var directions = [
		Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0),
		Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)
	]

	for direction in directions:
		var neighbor = node + direction

		if abs(direction.x) == 1 and abs(direction.y) == 1:
			var adjacent1 = node + Vector2i(direction.x, 0)
			var adjacent2 = node + Vector2i(0, direction.y)

			if not (is_walkable(adjacent1, grid) and is_walkable(adjacent2, grid)):
				continue

		if is_walkable(neighbor, grid) and not closed_set.has(neighbor):
			neighbors.append(neighbor)

	return neighbors

func heuristic(node: Vector2i, goal: Vector2i) -> int:
	var dx = abs(node.x - goal.x)
	var dy = abs(node.y - goal.y)
	return 10 * (dx + dy) + (14 - 20) * min(dx, dy)

func reconstruct_path(came_from, current: Vector2i):
	var path = []
	path.append(current)

	while came_from.has(current):
		current = came_from[current]
		path.append(current)

	path.reverse()
	return path

func is_walkable(node: Vector2i, grid) -> bool:
	var x = int(node.x)
	var y = int(node.y)
	return x >= 0 and y >= 0 and x < grid.size() and y < grid[0].size() and grid[y][x] == 1

func print_grid(grid, path=[]):
	for y in range(grid.size()):
		var line = ""
		for x in range(grid[y].size()):
			if path.has(Vector2i(x, y)):
				line += "P "
			elif grid[y][x] == 1:
				line += ". "
			else:
				line += "# "
		print(line)
	print("")

# 사용 예시
func _ready():
	
	var grid = [
		[1, 1, 1, 1, 0],
		[1, 0, 0, 1, 1],
		[1, 1, 1, 1, 0],
		[1, 0, 1, 0, 1],
		[1, 1, 1, 1, 1]
	]

	var start = Vector2i(0, 0)
	var goal = Vector2i(4, 4)

	var path = a_star(start, goal, grid)
	print_grid(grid, path)
