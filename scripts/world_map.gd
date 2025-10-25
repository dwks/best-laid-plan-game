extends Control

@onready var city_container = $CityContainer
@onready var info_panel = $InfoPanel

const CITY_POSITIONS = {
	"new_york": Vector2(200, 180),
	"london": Vector2(500, 150),
	"tokyo": Vector2(900, 200),
	"beijing": Vector2(850, 180)
}

var city_buttons: Dictionary = {}

func _ready():
	GameManager.city_selected.connect(_on_city_selected)
	create_city_buttons()

func create_city_buttons():
	for city_id in CITY_POSITIONS.keys():
		var city_data = GameManager.get_city_data(city_id)
		if city_data.is_empty():
			continue
			
		var button = Button.new()
		button.custom_minimum_size = Vector2(100, 50)
		button.position = CITY_POSITIONS[city_id] - button.custom_minimum_size / 2
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
