extends Control
# Main.gd 
# The game logic and globals

onready var terminal = $TileMap

func _ready():
	terminal.terminal_reset(80, 25, "cp437_8x16_fixedsys")
	terminal.terminal_print(0, "Welcome to Rogue.\nn)ew game\nc)ontinue\nh)elp\nq)uit\ng)enerate")
	pass
	
var rng = RandomNumberGenerator.new()

func _unhandled_key_input(event):
	if event.pressed and not event.echo and event.scancode == KEY_G:
		var pdisc = PoissonSampler.new(rng)
		var pts = pdisc.sample(80, 25, 10, 20, pdisc.NORM_EUCLIDEAN)
		var relg = RelativeNeighbourGraph.new()
		var edges = relg.get_edges(pts, relg.NORM_EUCLIDEAN)
		update()
		yield(self, "draw")
		for i in range(pts.size()):
			draw_circle(pts[i] * Vector2(8, 16), 1.0, Color(1.0, 0.0, 0.0))
			for j in edges[i]:
				draw_line(pts[i] * Vector2(8, 16), pts[j] * Vector2(8, 16), Color(0.0,1.0,0.0))
				pass
