class_name PoissonSampler extends Reference
# PoissonSampler.gd
# Samples random points in the plane a minimum distance apart

enum {
	NORM_EUCLIDEAN,
	NORM_MANHATTEN
	}
const MAX_ATTEMPTS : int = 30
var rng : RandomNumberGenerator

# NB: naive (slow) implementation
# NB!: uses random floats... though truncates to integers
# NB!!: may fail if you give it unreasonable constraints
func sample(map_width : int, map_height : int, radius : int, max_points : int, 
norm : int = NORM_EUCLIDEAN ) -> PoolVector2Array:
	assert(norm >= 0 and norm <= NORM_MANHATTEN)
	assert(map_width > 0 and map_height > 0 and radius > 0 and max_points > 0)
	var points : PoolVector2Array = PoolVector2Array([\
	Vector2(rng.randi_range(0, map_width - 1), rng.randi_range(0, map_height - 1))])
	if max_points == 1:
		return points
	var active : PoolIntArray = PoolIntArray([0])
	while(active.size() != 0):
		var idx_active : int = rng.randi_range(0, active.size() - 1)
		var idx_points : int = active[idx_active]
		var p : Vector2 = points[idx_points]
		for k in range(MAX_ATTEMPTS):
			var q : Vector2 = get_random_point_from(p, radius)
			if q.x < 0 or q.y < 0 \
			or q.x > (map_width - 1) or q.y > (map_height - 1):
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
			if k == MAX_ATTEMPTS - 1:
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