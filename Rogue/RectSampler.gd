class_name RectSampler extends Reference
# RectSampler.gd
# Sample rects randomly in an area
# can sample using collision or from a grid
# or using a BSP tree.

const MAX_ATTEMPTS_PER_RECT : int = 10
var rng : RandomNumberGenerator

# NB: Godot's Rect2 have
# 	rect.end = rect.position + rect.size (can all be neg.)
# We restrict ourselves to positive coordinates only and iterate
# for x in range(rect.position.x, rect.end.x)
# equivalently:
# for dx in range(rect.size.x):
# 	rect.position.x + dx
# etc. same for y coordinate
# so it makes sense for terminal coordinates (0, 0, w-1, h-1)
func sample_free(map_width : int, map_height : int,
rect_min_width : int, rect_min_height : int, 
rect_max_width : int, rect_max_height : int,
max_rects : int) -> Array:
	assert(map_width > 0 and map_height > 0 and rect_min_width > 0 and 
	rect_min_height > 0 and rect_max_width > 0 and rect_max_height > 0 and
	max_rects > 0)
	var rects : Array = []
	for k in range(MAX_ATTEMPTS_PER_RECT * max_rects):
		var x : int = rng.randi_range(0, map_width - 1)
		var y : int = rng.randi_range(0, map_height - 1)
		var w : int = rng.randi_range(rect_min_width, rect_max_width)
		var h : int = rng.randi_range(rect_min_height, rect_max_height)
		#var dx = (x + w - 1) - (map_width - 1), minuses cancel
		var dx : int = x + w - map_width 
		var dy : int = y + h - map_height
		if dx > 0:
			x -= dx 
		if dy > 0:
			y -= dy
		var new_rect : Rect2 = Rect2(x, y, w, h)
		var is_far_away : bool = true
		for rect in rects:
			if new_rect.intersects(rect): #hmm.... subtracting 1,1 doesnt work
				is_far_away = false
				break
		if is_far_away:
			rects.append(new_rect)
			if rects.size() == max_rects:
				break
	return rects

func _init(rng : RandomNumberGenerator):
	self.rng = rng 
	pass

"""
func sample(width : int, height : int, cols : int, rows : int, 
max_points : int) -> void:
	var points : PoolByteArray = PoolByteArray([])
	var arr : BitMap = BitMap.new()
	arr.create(Vector2(cols, rows))
	while (points.size() < int(min(max_points, cols*rows))):
		pass
	pass
"""