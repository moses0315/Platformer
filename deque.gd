extends Node

class_name Deque

# 이중 연결 리스트 노드를 관리하기 위한 변수들입니다.
var head = null
var tail = null

# 노드를 나타내는 내부 구조
class DequeNode:
	var value
	var prev = null
	var next = null

	func _init(value):
		self.value = value

# 앞쪽에 값을 추가하는 함수
func appendleft(value):
	var new_node = DequeNode.new(value)
	if head == null:
		head = new_node
		tail = new_node
	else:
		new_node.next = head
		head.prev = new_node
		head = new_node

# 뒤쪽에서 값을 제거하고 반환하는 함수
func pop():
	if tail == null:
		return null
	var value = tail.value
	if head == tail:
		head = null
		tail = null
	else:
		tail = tail.prev
		tail.next = null
	return value

# 앞쪽에서 값을 제거하고 반환하는 함수
func pop_left():
	if head == null:
		return null
	var value = head.value
	if head == tail:
		head = null
		tail = null
	else:
		head = head.next
		head.prev = null
	return value

# Deque가 비어 있는지 확인하는 함수
func is_empty() -> bool:
	return head == null

# Deque를 반복할 수 있도록 하는 함수
func _iter_init():
	var current = head
	while current != null:
		await current.value
		current = current.next
