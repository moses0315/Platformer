extends Node

class_name MinHeap

var heap = []

func _init():
	heap = []

# 우선순위와 함께 아이템을 푸시할 수 있도록 수정된 push 메서드
func push(item, priority):
	heap.append({"item": item, "priority": priority})
	_heapify_up(heap.size() - 1)

# pop 메서드에서 우선순위가 가장 높은(작은) 아이템을 반환
func pop():
	var min_value = null

	if heap.size() > 1:
		_swap(0, heap.size() - 1)
		min_value = heap.pop_back()["item"]
		_heapify_down(0)
	elif heap.size() == 1:
		return heap.pop_back()["item"]
		
	return min_value

func _heapify_up(index):
	var parent_index = int((index - 1) / 2)
	while index > 0 and heap[index]["priority"] < heap[parent_index]["priority"]:
		_swap(index, parent_index)
		index = parent_index

func _heapify_down(index):
	var left_child_index = 2 * index + 1
	var right_child_index = 2 * index + 2
	var smallest = index

	if left_child_index < heap.size() and heap[left_child_index]["priority"] < heap[smallest]["priority"]:
		smallest = left_child_index
	if right_child_index < heap.size() and heap[right_child_index]["priority"] < heap[smallest]["priority"]:
		smallest = right_child_index

	if smallest != index:
		_swap(index, smallest)
		_heapify_down(smallest)

func _swap(i, j):
	var temp = heap[i]
	heap[i] = heap[j]
	heap[j] = temp

func is_empty():
	return heap.size() == 0
