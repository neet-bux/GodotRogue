class_name PoissonSampler extends Reference
# PoissonSampler.gd
# Samples random points in the plane a minimum distance apart

enum {
	NORM_EUCLIDEAN,
	NORM_MANHATTEN
	}
const MAX_TRIES : int = 30
var rng : RandomNumberGenerator

# NB: naive (slow) implementation
# NB!: uses random floats... though truncates to integers
# NB!!: may fail if you give it unreasonable constraints
func sample(width : int, height : int, radius : int, max_points : int, 
norm : int = NORM_EUCLIDEAN ) -> PoolVector2Array:
	assert(norm >= 0 and norm <= NORM_MANHATTEN)
	assert(width > 0 && height > 0 && radius > 0 && max_points > 0)
	var points : PoolVector2Array = PoolVector2Array([\
	Vector2(rng.randi_range(0, width - 1), rng.randi_range(0, height - 1))])
	if max_points == 1:
		return points
	var active : PoolIntArray = PoolIntArray([0])
	while(active.size() != 0):
		var idx_active : int = rng.randi_range(0, active.size() - 1)
		var idx_points : int = active[idx_active]
		var p : Vector2 = points[idx_points]
		for k in range(MAX_TRIES):
			var q : Vector2 = get_random_point_from(p, radius)
			if q.x < 0 or q.y < 0 or q.x > (width - 1) or q.y > (height - 1):
				continue
			var is_far_away : bool = true
			for idx in points.size():
				if idx == idx_points: # can skip p since q was gen. away from p
					continue
				var d_qr = get_distance(q, points[idx], norm)
				if d_qr <= radius:
					is_far_away = false
					break
			if is_far_away:
				points.append(q)
				active.append(points.size() - 1)
				if points.size() >= max_points:
					return points
			if k == MAX_TRIES - 1:
				active.remove(idx_active)
	return points

func get_random_point_from(p : Vector2, radius : int) -> Vector2:
	var dist : float = radius * rng.randf_range(1.0, 2.0)
	var angle : float = PI * rng.randf_range(0.0, 2.0)
	var q : Vector2 = Vector2(p.x, p.y) + dist * Vector2(cos(angle), sin(angle))
	q.x = int(q.x)
	q.y = int(q.y)
	return q

func get_distance(p : Vector2, q : Vector2, norm : int) -> int:
	match norm:
		NORM_MANHATTEN:
			return int(abs(p.x - q.x) + abs(p.y - q.y))
		NORM_EUCLIDEAN, _:
			return int((p-q).length())
	pass


func _init(rng : RandomNumberGenerator) -> void:
	self.rng = rng
	pass

"""

const EMPTY_CELL : int = -1
const MAX_ATTEMPTS : int = 30
var real_width : float
var real_height : float
var grid_width : int 
var grid_height : int
var grid_size : int
var min_distance : float
var cell_size : float 
var grid : PoolIntArray
var placed_points : PoolVector2Array
var active_list : PoolIntArray #list of indices into placed points
var rng : RandomNumberGenerator


func _init(width : float, height : float, radius: float):
	assert(width > 0 and height > 0 and radius > 0)
	rng = RandomNumberGenerator.new()
	rng.randomize()
	placed_points.resize(0)
	active_list.resize(0)
	real_width = width
	real_height = height
	min_distance = radius
	cell_size = min_distance / sqrt(2.0)
	grid_width = int(real_width / cell_size)
	grid_height = int(real_height / cell_size)
	grid_size = grid_width * grid_height
	grid.resize(grid_size)
	for i in range(grid_size):
		grid[i] = EMPTY_CELL
	_place_point(Vector2(
	rng.randf_range(0, cell_size * (grid_width - 1)),
	rng.randf_range(0, cell_size * (grid_height - 1))))
	print("PoissonDisc: seed = ", rng.seed)
	print("PoissonDisc: cell-size = ", cell_size)
	print("PoissonDisc: grid-coord-max = ", grid_width-1, ",", grid_height-1)
	print("PoissonDisc: min-dist = ", min_distance)
	print("PoissonDisc: seed-point = ", placed_points[0])
	pass

func _is_invalid_grid_point(gx : int, gy : int) -> bool:
	# Returns if grid point is out of bounds
	var invalid : bool = (gx < 0 or gy < 0) 
	or (gx > grid_width - 1 or gy > grid_height -1)
	return invalid

func _is_invalid_real_point(p : Vector2) -> bool:
	# returns if real point is out of bounds
	var invalid : bool = (p.x < 0 or p.x > ((grid_width - 1) * cell_size)) 
	or (p.y < 0 or p.y > ((grid_height - 1) * cell_size))
	return invalid

func _is_unplaceable_point(p : Vector2) -> bool:
	# Checks if valid point p is too close to other points
	var gx : int = int(p.x / cell_size)
	var gy : int = int(p.y / cell_size)
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var gx_n : int = gx + dx
			var gy_n : int = gy + dy
			if _is_invalid_grid_point(gx_n, gy_n):
				continue
			var cell = grid[gx_n + gy_n * grid_width]
			if cell != EMPTY_CELL:
				var q : Vector2 = placed_points[cell]
				var dist : float = (q-p).length()
				if dist < min_distance:
					return true
	return false
	
func _place_point(p : Vector2) -> void:
	# Places a valid point p in the grid
	var gx : int = int(p.x / cell_size)
	var gy : int = int(p.y / cell_size)
	placed_points.append(p)
	var idx : int = placed_points.size() - 1
	active_list.append(idx)
	grid[gx + gy * grid_width] = idx
	pass

func _random_position(p : Vector2) -> Vector2:
	# Returns a real point q at least min_distance away from real point p
	var r : float = rng.randf_range(min_distance, 2 * min_distance)
	var theta : float = rng.randf_range(0, 4 * PI)
	var q : Vector2 = p
	q.x += r * cos(theta)
	q.y += r * sin(theta)
	return q

func _sanity_check() -> void:
	# slow, use only for debug
	for i in range(placed_points.size()):
		for j in range(placed_points.size()):
			if i == j:
				continue 
			assert((placed_points[i] - placed_points[j]).length() >= min_distance)
	print("PoissonDisc: Sanity OK")
func sample(max_points : int) -> void:
	while(active_list.size() > 0):
		var active_idx = rng.randi() % active_list.size()
		var p = placed_points[active_list[active_idx]]
		var placed : bool = false
		for k in range(MAX_ATTEMPTS):
			var q = _random_position(p)
			if _is_invalid_real_point(q):
				continue
			if _is_unplaceable_point(q):
				continue
			_place_point(q)
			if placed_points.size() >= max_points:
				_sanity_check()
				print("PoissonDisc: SUCCESS generated maximum number of points.")
				return
		if not placed:
			active_list.remove(active_idx)
			print("PoissonDisc: failed to generate from point ", p)
	if placed_points.size() < max_points:
		print("PoissonDisc: FAILURE to generate maximum number of points.")
	_sanity_check()
	pass
"""
