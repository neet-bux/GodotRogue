class_name RelativeNeighbourGraph extends Reference
# RelativeNeighBourGraph.gd
# builds an RNG from given points.

enum {
	NORM_EUCLIDEAN,
	NORM_MANHATTEN
	}

# NB: naive (slow) implementation, use integers
# Returns an array where at each index i is an array containing indices {j}
# such that {i,{j}} are relative neighbour edges.
# Does not double count.
func get_edges(points : PoolVector2Array, norm : int = NORM_EUCLIDEAN) -> Array:
	assert(norm >= 0 and norm <= NORM_MANHATTEN)
	var arr : Array = []
	arr.resize(points.size())
	for i in range(arr.size()):
		arr[i] = []
	if points.size() == 1:
		return arr
	elif points.size() == 2:
		arr[0].append(1)
		return arr
	for p in range(points.size()):
		for q in range(p + 1, points.size()):
			var d_pq : int = get_distance(points[p], points[q], norm)
			var is_closer : bool = true
			for r in range(points.size()):
				if r == p or r == q:
					continue
				var d_pr : int = get_distance(points[p], points[r], norm)
				var d_qr : int = get_distance(points[q], points[r], norm)
				if d_pq > int(max(d_pr, d_qr)):
					is_closer = false 
					break
			if is_closer:
				arr[p].append(q)
	return arr

func get_distance(p : Vector2, q : Vector2, norm : int) -> int:
	match norm:
		NORM_MANHATTEN:
			return int(abs(p.x - q.x) + abs(p.y - q.y))
		NORM_EUCLIDEAN, _:
			return int((p-q).length())
	pass