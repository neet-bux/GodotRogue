class_name RogueGrid extends Reference
###### DEPRECATED #####
# File: RogueGrid.gd
#
# Responsibilies:
# 1. Keep track of the state of the dungeon level:
# scent, visibility, traps, doors, destroyed tiles
# but not items and creatures
#
# 2. Generate dungeon levels: 
# walls, floors, doors, traps, stairs
# but not creatures and items
#
#
# Current Algorithms Implemented:
# Grid-based Classic Rogue levels (TODO: mazes and corridors)

const GRID_WIDTH : int = 80
const GRID_HEIGHT : int = 20
const GRID_SIZE : int = GRID_WIDTH * GRID_HEIGHT
const CELL_SEEN : int = 1
const CELL_VISIBLE : int = 2

# ascii-symbol to display:
var glyph : PoolByteArray
# visibility state of tile (for player)
var sight : PoolByteArray
# Some monsters can/only hunt by scent.
# Player leaves behind a trail of smell in each tile walked into
# The trail goes from 255 (position of player) to 0 (no smell / unvisited tile)
# A monster will try to move in direction of increasing smell
# The smell in each tile will decrease by 1 (to a minimum of 0) each turn.
var scent : PoolByteArray 
var solid : PoolByteArray # Ghosts ignore collision, increase fear and drain mp
var fg_color : PoolColorArray
var bg_color : PoolColorArray
var depth : int = 0 #dungeon level

func _init():
	glyph.resize(GRID_SIZE)
	sight.resize(GRID_SIZE)
	scent.resize(GRID_SIZE)
	fg_color.resize(GRID_SIZE)
	bg_color.resize(GRID_SIZE)
	for i in range(GRID_SIZE):
		glyph.set(i, 0)
		sight.set(i, 0)
		scent.set(i, 0)
		fg_color.set(i, Color("ffffffff"))
		bg_color.set(i, Color("ff000000"))
	pass



func gen_dungeon_new() -> void:
	# This algorithm works suprisingly well,
	# though I still feel we could do better with the 
	# Room Grid (point sampling)
	# Step 1. Sample N random points, spaced decently.
	# Step 2. Build a Relative Neighbour Graph of these using 2-norm
	# Step 3. Replace edges with 1-tile wide corridoors
	# Step 4. Replace points with randomly sized rectangular rooms, 
	#         walls intersecting corridoors are made into doors.
	# Step 5. Place up and down stairs in different rooms,
	#         preferably rooms that are far away from each other.
	
	# Step 1.
	# Divide the 80x20 map into 5x4 cells,
	# i.e each cell is 16x5 tiles big.
	# mark cells as occupied with probability 33%
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var pos : PoolVector2Array
	for x in range(5):
		for y in range(4):
			if (rng.randf() <= 0.33):
				pos.append(Vector2(x, y))
	# Step 2.
	# Build a relative neighbour graph:
	# and edge between p, q exists iff
	# d(p, q) <= max{ d(p, r), d(q, r)} for all r != p, q
	# conversely, it does not exist if
	# d(p,q) > max{d(p, r), d(q, r)}
	print(pos)
	for p in pos:
		_room(int(p.x) * 16, int(p.y) * 5, 7 + randi() % 10, 4 + randi() % 2)
	for p in range(pos.size()):
		for q in range(p+1, pos.size()):
			var is_edge = true
			var d_pq = (pos[p] - pos[q]).length()
			for r in range(pos.size()):
				if r == p or r == q:
					continue
				var d_pr = (pos[p] - pos[r]).length()
				var d_qr = (pos[q] - pos[r]).length()
				if not (d_pq <= max(d_pr, d_qr)):
					is_edge = false
					break
			if is_edge:
				print(p, pos[p], "<->", q, pos[q])
				_corr(
				int(pos[p].x * 16 + 8), 
				int(pos[p].y * 5 + 2), 
				int(pos[q].x * 16 + 8), 
				int(pos[q].y * 5 + 2))
	

		
	pass


func _corr(x1 : int, y1 : int, x2 : int, y2 : int) -> void:
	if x1 <= x2:
		for x in range(x1, x2 + 1):
			glyph.set(x + y1 * GRID_WIDTH, 176)
		for y in range(min(y1,y2), max(y1,y2) + 1):
			glyph.set(x2 + y * GRID_WIDTH, 176)
	elif x2 > x1:
		for x in range(x2, x1 + 1): #smallest x left in loop
			glyph.set(x + y2 * GRID_WIDTH, 176) # y corresponds to smallest x
		for y in range(min(y1, y2), max(y1, y2) + 1):
			glyph.set(x1 + y * GRID_WIDTH, 176) # smallest x here
	pass

# Generates a classic dungeon floor similar to that in Original Rogue.
# TODO: Implement mazes as alternative to rooms
# i.e. call  _maze(x, y, w, h) instead of _room(x, y, w, h)
func gen_rogue_dungeon() -> void:
	# 80x20 map is sectioned into 8x4 cells, which may contain rooms
	# so an isolated room has a maximum size of 10x5 tiles (8x3 with walls).
	var room_slots = [\
	[-1, -1, -1, -1, -1, -1, -1, -1],
	[-1, -1, -1, -1, -1, -1, -1, -1],
	[-1, -1, -1, -1, -1, -1, -1, -1],
	[-1, -1, -1, -1, -1, -1, -1, -1],
	]
	# randomly set 8 cells to be rooms (25% of space)
	var max_rooms: int = 11
	var room_pos : PoolVector2Array
	var room_size : PoolVector2Array
	var rng = RandomNumberGenerator.new() #so we can control seed
	rng.randomize()
	while(room_pos.size() < max_rooms):
		var x = rng.randi() % 8
		var y = rng.randi() % 4
		if (room_slots[y][x] == -1):
			room_slots[y][x] = room_pos.size()
			room_pos.append(Vector2(x, y))
			room_size.append(Vector2(1, 1))
	# Merge rooms that are adjacent
	# First merge along each row, from left to right
	for y in range(4):
		var current_room = -1
		for x in range(7):
			if room_slots[y][x] != -1:
				if current_room == -1:
					current_room = room_slots[y][x]
				if room_slots[y][x+1] != -1:
					room_slots[y][x+1] = current_room
					room_size[current_room].x += 1
				else:
					current_room = -1
	# now merge down if we can maintain a rectangle shape
	# i.e., if a room is N cells wide, then to merge downwards,
	# there must be a room N cells wide below it that aligns exactly
	# rooms in the row we are iterating over cannot be merged away
	# since we only merge down (eat up those rooms below us)
	# thus we keep track of exactly which onces to build easily here
	# in the previous iteration we merged rooms left to right
	# but rooms not in the first row can be merged with the row above
	# hence we couldnt keep track of it previously, as it might change here
	var rooms_to_build = []
	for y in range(3):
		var x = 0
		while(x < 8):
			var current_room = -1
			if room_slots[y][x] != -1:
				if current_room == -1:
					current_room = room_slots[y][x]
					rooms_to_build.append(current_room)
					var l = room_size[current_room].x
					var room_below = room_slots[y+1][x]
					if room_below != -1 and room_slots[y+1][x+l-1] == room_below \
					and room_size[room_below].x == l:
						for dx in range(l):
							room_slots[y+1][x+dx] = current_room
						room_size[current_room].y += 1
					x += l-1 #skip cells in the same room
			x += 1
	print(room_slots)
	print(room_size)
	print(rooms_to_build.size())
	# draw rooms that havent been merged away
	for room in rooms_to_build:
		_room(int(room_pos[room].x) * 10, int(room_pos[room].y) * 5, \
		int(room_size[room].x) * 10, int(room_size[room].y) * 5)
	pass

func _room(x0 : int, y0 : int, w : int, h : int) -> void:
	for x in range(x0 + 1, x0 + w - 1):
		glyph.set(x + y0 * GRID_WIDTH, 205)
		glyph.set(x + ((y0 + h - 1) * GRID_WIDTH), 205)
		for y in range(y0 + 1, y0 + h - 1): 
			glyph.set(x + y * GRID_WIDTH, 250)
	for y in range(y0 + 1, y0 + h - 1):
		glyph.set(x0 + y * GRID_WIDTH, 186)
		glyph.set((x0 + w - 1) + y * GRID_WIDTH, 186)
	glyph.set(x0 + y0 * GRID_WIDTH, 201)
	glyph.set((x0 + w - 1) + y0 * GRID_WIDTH, 187)
	glyph.set(x0 + (y0 + h - 1) * GRID_WIDTH, 200)
	glyph.set((x0 + w - 1) + (y0 + h - 1) * GRID_WIDTH, 188)
	pass

func generate() -> void:
	# this function should generate a dungeon approriate for the depth
	#gen_rogue_dungeon()
	gen_dungeon_new()
	pass