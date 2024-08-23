extends Node

var min_heap_class = preload("res://min_heap.gd")

var min_heap = min_heap_class.new()



# Called when the node enters the scene tree for the first time.
func _ready():
	min_heap.insert(3)
	min_heap.insert(1)
	min_heap.insert(6)
	min_heap.insert(5)
	min_heap.insert(2)
	min_heap.insert(4)

	print("Min Heap: ", min_heap.heap)  # 출력: Min Heap: [1, 2, 4, 5, 3, 6]

	var min_value = min_heap.pop()
	print("Pop: ", min_value)  # 출력: Pop: 1
	print("Min Heap after pop: ", min_heap.heap)  # 출력: Min Heap after pop: [2, 3, 4, 5, 6]
