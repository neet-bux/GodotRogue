class_name Terminal extends TileMap
# Terminal.gd 
# Responsible for pushing ascii graphics on screen
# To-do: make it so you can add it programatically instead of having it in scene
var width : int
var height : int
var attribute_image : Image
var attribute_texture : ImageTexture

const DEFAULT_ATTRIBUTE : Color = Color8(0xd1, 0xe1, 0xd1, 0)

func terminal_reset(width : int, height : int, tileset_file : String = "") -> void:
	self.width =  width 
	self.height = height
	if attribute_image == null:
		attribute_image = Image.new()
	if attribute_texture == null:
		attribute_texture = ImageTexture.new()
		material.set_shader_param("attributes", attribute_texture)
	attribute_image.create(width, height, false, Image.FORMAT_RGBA8)
	attribute_image.fill(DEFAULT_ATTRIBUTE)
	attribute_texture.create_from_image(attribute_image, 0)
	for x in range(width):
		for y in range(height):
			terminal_set_glyph(x, y, 32)
	if ResourceLoader.exists(tileset_file + ".tres", "TileSet"):
		tile_set = load(tileset_file + ".tres")
		cell_size = tile_set.tile_get_region(0).size
	OS.set_window_size(Vector2(width, height) * cell_size)
	OS.center_window()
	pass

func terminal_refresh_colors_and_attributes() -> void:
	attribute_texture.set_data(attribute_image)
	pass

func terminal_set_glyph(x : int, y : int, glyph : int) -> void:
	set_cell(x, y, glyph)
	pass

func terminal_clear() -> void:
	for x in range(width):
		for y in range(height):
			set_cell(x, y, 32)
	attribute_image.fill(DEFAULT_ATTRIBUTE)
	terminal_refresh_colors_and_attributes()
	pass

func terminal_set_foreground(x : int, y : int, color : Color) -> void:
	attribute_image.lock()
	var attribute = attribute_image.get_pixel(x, y)
	attribute.r8 = (attribute.r8 & 0x0f) | (color.r8 >> 4) << 4
	attribute.g8 = (attribute.g8 & 0x0f) | (color.g8 >> 4) << 4
	attribute.b8 = (attribute.b8 & 0x0f) | (color.b8 >> 4) << 4
	attribute_image.set_pixel(x, y, attribute)
	attribute_image.lock()
	pass

func terminal_set_background(x : int, y : int, color : Color) -> void:
	attribute_image.lock()
	var attribute = attribute_image.get_pixel(x, y)
	attribute.r8 = (attribute.r8 & 0xf0) | (color.r8 >> 4)
	attribute.g8 = (attribute.g8 & 0xf0) | (color.g8 >> 4)
	attribute.b8 = (attribute.b8 & 0xf0) | (color.b8 >> 4)
	attribute_image.set_pixel(x, y, attribute)
	attribute_image.lock()
	pass

func terminal_set_attribute(x : int, y : int, a : int) -> void:
	attribute_image.lock()
	var attribute = attribute_image.get_pixel(x, y)
	attribute.a8 = a
	attribute_image.set_pixel(x, y, attribute)
	attribute_image.unlock()
	pass

func terminal_print(y : int, s : String) -> void:
	var ss : PoolStringArray = s.split("\n")
	for s in ss:
		var c : PoolByteArray = s.to_ascii()
		var n : int = int(min(width, c.size()))
		for x in range(n):
			terminal_set_glyph(x, y, c[x])
		y += 1
	pass