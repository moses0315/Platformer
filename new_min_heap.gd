extends Node

class_name MinHeap

var heap = []

func _init():
	heap = []

func push(value):
	heap.append(value)
	_heapify_up(heap.size() - 1)

func pop():
	var min_value = null
	if heap.size() > 1:
		_swap(0, heap.size() - 1)
		min_value = heap.pop_back()
		_heapify_down(0)
	elif heap.size() == 1:
		min_value = heap.pop_back()
	return min_value

func _heapify_up(index):
	var parent_index = int((index - 1) / 2)
	if index > 0 and heap[index] < heap[parent_index]:
		_swap(index, parent_index)
		_heapify_up(parent_index)

func _heapify_down(index):
	var left_child_index = 2 * index + 1
	var right_child_index = 2 * index + 2
	var smallest = index

	if left_child_index < heap.size() and heap[left_child_index] < heap[smallest]:
		smallest = left_child_index
	if right_child_index < heap.size() and heap[right_child_index] < heap[smallest]:
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
