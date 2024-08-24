extends Node

class_name Stack

var stack : Array[Vector2i]

# 스택에 요소를 추가합니다.
func push(item):
	stack.append(item)
func _print():
	print(stack) 
# 스택에서 요소를 꺼내 반환합니다. 스택이 비어있으면 null을 반환합니다.
func pop():
	if stack.size() > 0:
		return stack.pop_back()
	return 0

# 스택이 비어있는지 확인합니다.
func is_empty():
	return stack.size() == 0

# 스택의 크기를 반환합니다.
func size():
	return stack.size()

# 스택을 초기화합니다.
func clear():
	stack.clear()
