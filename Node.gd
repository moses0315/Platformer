extends Node

var min_heap_class = preload("res://min_heap.gd")
var deque_class = preload("res://deque.gd")

var min_heap = min_heap_class.new()
var deque = deque_class.new()


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
	

	# Deque 인스턴스 생성

	
	# Deque의 앞쪽에 값 추가
	deque.appendleft(10)
	deque.appendleft(20)
	deque.appendleft(30)
	
	# Deque의 요소 반복
	print("Deque 요소 (앞에서 뒤로):")
	var a = await deque._iter_init()
	for value in a:
		print(value)  # 30, 20, 10 순서로 출력
	
	# 뒤쪽에서 값 제거
	var last_value = deque.pop()
	print("뒤쪽에서 제거한 값:", last_value)  # 10 출력
	
	# 앞쪽에서 값 제거
	var first_value = deque.pop_left()
	print("앞쪽에서 제거한 값:", first_value)  # 30 출력
	
	# Deque가 비어 있는지 확인
	if deque.is_empty():
		print("Deque가 비어 있습니다.")
	else:
		print("Deque에 요소가 남아 있습니다.")

	
	
	
