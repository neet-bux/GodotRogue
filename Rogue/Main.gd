extends Control
# Main.gd 
# The game logic and globals

# For now just testing algorithms

onready var terminal = $TileMap
var rng = RandomNumberGenerator.new()

func _ready():
	terminal.terminal_reset(80, 25, "curses_8x12")
	terminal.terminal_print(0, "Welcome to Rogue.\nn)ew game\nc)ontinue\no)ptions\nq)uit\ng)enerate")
	pass


# simple test function for drawing rooms / rects
func put_room(rect : Rect2) -> void:
	var x : int = int(rect.position.x)
	var y : int = int(rect.position.y)
	var w : int = int(rect.size.x)
	var h : int = int(rect.size.y)
	# use values after # for alternate style
	var mg : int = 250 #46
	var ulg : int = 218 #201 
	var blg : int = 192 #202
	var brg : int = 217 #188
	var urg : int = 191 #187
	var hg : int = 196 #205
	var vg : int = 179 #186
	for dx in range(1, w - 1):
		terminal.terminal_set_glyph(x + dx, y, hg)
		terminal.terminal_set_glyph(x + dx, y + h - 1, hg)
		for dy in range(1, h - 1):
			terminal.terminal_set_glyph(x + dx, y + dy, mg)
	for dy in range(1, h - 1):
		terminal.terminal_set_glyph(x, y + dy, vg)
		terminal.terminal_set_glyph(x + w - 1, y + dy, vg)
	terminal.terminal_set_glyph(x, y, ulg)
	terminal.terminal_set_glyph(x, y + h - 1, blg)
	terminal.terminal_set_glyph(x + w - 1, y, urg)
	terminal.terminal_set_glyph(x + w - 1, y + h - 1, brg)
	pass


func _unhandled_key_input(event):
	if event.pressed and not event.echo and event.scancode == KEY_G:
		var recs = RectSampler.new(rng)
		var rects = recs.sample_free(80, 23, 5, 4, 15, 7, 9)
		terminal.terminal_clear()
		for r in rects:
			put_room(r)
		terminal.terminal_print(24, "RectSampler + RNG")
		
		#var pdisc = PoissonSampler.new(rng)
		#var pts = pdisc.sample(80, 25, 10, 20, pdisc.NORM_EUCLIDEAN)
		var pts : PoolVector2Array
		for i in range(rects.size()):
			pts.append(rects[i].position + rects[i].size / 2)
		var relg = RelativeNeighbourGraph.new()
		var edges = relg.get_edges(pts, relg.NORM_MANHATTEN)
		update()
		yield(self, "draw")
		for i in range(pts.size()):
			draw_circle(pts[i] * terminal.cell_size, 3.0, Color(1.0, 0.0, 0.0))
			for j in edges[i]:
				draw_line(pts[i] * terminal.cell_size, pts[j] * terminal.cell_size, Color(0.0,1.0,0.0))
		 