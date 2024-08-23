extends Node

class_name MinHeap

var heap = []

func _init():
	heap = []

func insert(value):
	heap.append(value)
	_sift_up(heap.size() - 1)

func pop() -> int:
	if heap.size() == 0:
		push_error("Heap is empty")
		return 0
	
	if heap.size() == 1:
		return heap.pop_back()
	
	var root_value = heap[0]
	heap[0] = heap.pop_back()
	_sift_down(0)
	return root_value

func peek() -> int:
	if heap.size() == 0:
		push_error("Heap is empty")
		return 0
	
	return heap[0]

func _sift_up(index):
	var parent_index = int((index - 1) / 2)
	if index > 0 and heap[index] < heap[parent_index]:
		_swap(index, parent_index)
		_sift_up(parent_index)

func _sift_down(index):
	var left_child_index = 2 * index + 1
	var right_child_index = 2 * index + 2
	var smallest = index

	if left_child_index < heap.size() and heap[left_child_index] < heap[smallest]:
		smallest = left_child_index
	
	if right_child_index < heap.size() and heap[right_child_index] < heap[smallest]:
		smallest = right_child_index

	if smallest != index:
		_swap(index, smallest)
		_sift_down(smallest)

func _swap(i, j):
	var temp = heap[i]
	heap[i] = heap[j]
	heap[j] = temp

