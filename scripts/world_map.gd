extends Control

@onready var city_container = $CityContainer
@onready var info_panel = $InfoPanel
@onready var world_map_image = $MapContainer/WorldMapImage
@onready var map_background = $MapBackground

# Positions relative to the actual map dimensions (784.077 x 458.627, viewBox starts at 30.767, 241.591)
const CITY_POSITIONS = {
	"new_york": Vector2(250, 320),   # North America - approximate position
	"london": Vector2(450, 250),     # Europe
	"tokyo": Vector2(700, 320),      # East Asia
	"beijing": Vector2(650, 290)     # East Asia
}

var city_buttons: Dictionary = {}

func _ready():
	GameManager.city_selected.connect(_on_city_selected)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	load_world_map()
	create_city_buttons()
	update_map_scale()

func update_map_scale():
	if world_map_image.texture == null:
		return
	
	var texture_size = world_map_image.texture.get_size()
	
	# Set the pivot offset to scale from the center of the texture
	world_map_image.pivot_offset = texture_size / 2.0
	
	# Calculate the scale factor to fill the viewport
	var viewport_size = get_viewport_rect().size
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	
	# Set the scale
	world_map_image.scale = Vector2(scale_x, scale_y)

func load_world_map():
	# Load the PNG image directly from file
	var image = Image.new()
	var error = image.load("res://map_assets/world-map-colored.png")
	if error == OK:
		var texture = ImageTexture.create_from_image(image)
		world_map_image.texture = texture
		map_background.visible = false
		print("World map loaded successfully")
		print("Texture size: ", texture.get_size())
	else:
		print("Warning: Could not load world map texture, error: ", error)

func _on_viewport_size_changed():
	# Reposition city buttons when window is resized
	reposition_city_buttons()
	# Update map scale
	update_map_scale()

func reposition_city_buttons():
	var viewport_size = get_viewport_rect().size
	var map_size = Vector2(784.077, 458.627)
	
	for city_id in city_buttons:
		var button = city_buttons[city_id]
		var relative_x = CITY_POSITIONS[city_id].x / map_size.x
		var relative_y = CITY_POSITIONS[city_id].y / map_size.y
		var scaled_position = Vector2(
			relative_x * viewport_size.x,
			relative_y * viewport_size.y
		)
		button.position = scaled_position - button.custom_minimum_size / 2

func create_city_buttons():
	# Get the viewport size to scale positions relative to window
	var viewport_size = get_viewport_rect().size
	var map_size = Vector2(784.077, 458.627)  # Size of the SVG map
	
	for city_id in CITY_POSITIONS.keys():
		var city_data = GameManager.get_city_data(city_id)
		if city_data.is_empty():
			continue
			
		var button = Button.new()
		button.custom_minimum_size = Vector2(100, 50)
		
		# Scale positions based on window size
		var relative_x = CITY_POSITIONS[city_id].x / map_size.x
		var relative_y = CITY_POSITIONS[city_id].y / map_size.y
		var scaled_position = Vector2(
			relative_x * viewport_size.x,
			relative_y * viewport_size.y
		)
		
		button.position = scaled_position - button.custom_minimum_size / 2
		button.text = city_data.name
		button.flat = true
		
		# Style the button
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.2, 0.5, 0.8, 0.7)
		style_normal.border_color = Color(0.4, 0.7, 1.0, 1.0)
		style_normal.border_width_left = 2
		style_normal.border_width_right = 2
		style_normal.border_width_top = 2
		style_normal.border_width_bottom = 2
		button.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.3, 0.6, 0.9, 0.9)
		style_hover.border_color = Color(0.5, 0.8, 1.0, 1.0)
		style_hover.border_width_left = 2
		style_hover.border_width_right = 2
		style_hover.border_width_top = 2
		style_hover.border_width_bottom = 2
		button.add_theme_stylebox_override("hover", style_hover)
		
		button.pressed.connect(func(): GameManager.select_city(city_id))
		city_container.add_child(button)
		city_buttons[city_id] = button

func _on_city_selected(city_name: String):
	update_info_panel(city_name)

func update_info_panel(city_name: String):
	var city_data = GameManager.get_city_data(city_name)
	if city_data.is_empty():
		return
	
	# Update the info panel with city data
	if info_panel:
		var label = info_panel.get_node_or_null("InfoLabel")
		if label:
			label.text = format_city_info(city_data)

func format_city_info(data: Dictionary) -> String:
	return """City: %s
Population: %s
AI Adoption: %d%%
Policy: %s
Economic Growth: %.1f%%
Quality of Life: %.0f%%
""" % [
	data.name,
	str(data.population),
	(data.ai_adoption_rate * 100) as int,
	data.policy_restrictions,
	data.economic_growth,
	(data.quality_of_life * 100)
]
