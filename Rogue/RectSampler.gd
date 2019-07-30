class_name RectSampler extends Reference
# RectSampler.gd
# Sample rects randomly in an area
# can sample using collision or from a grid
# not implemented yet


func sample(width : int, height : int, cols : int, rows : int, 
max_points : int) -> void:
	var points : PoolByteArray = PoolByteArray([])
	var arr : BitMap = BitMap.new()
	arr.create(Vector2(cols, rows))
	while (points.size() < int(min(max_points, cols*rows))):
		pass
	pass