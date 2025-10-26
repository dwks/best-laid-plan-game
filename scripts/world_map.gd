extends Control

@onready var city_container = $CityContainer
@onready var info_panel = $InfoPanel
@onready var world_map_image = $MapContainer/WorldMapImage
@onready var map_background = $MapBackground

# Positions relative to the PNG map dimensions (2000 x 1171)
const CITY_POSITIONS = {
	"washington_dc": Vector2(420, 420),
	"san_francisco": Vector2(140, 440),
	"seattle": Vector2(120, 280),
	"new_york": Vector2(480, 430),
	"london": Vector2(850, 350),
	"beijing": Vector2(1600, 420),
	"shenzhen": Vector2(1620, 540),
	"singapore": Vector2(1540, 660),
	"tokyo": Vector2(1700, 470),
	"taipei": Vector2(1650, 550)
}

var city_buttons: Dictionary = {}

func _ready():
	GameManager.city_selected.connect(_on_city_selected)
	GameManager.year_changed.connect(_on_year_changed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	load_world_map()
	create_city_buttons()
	create_simulation_controls()
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
	# Try loading as a resource first (will use imported texture)
	var texture = load("res://map_assets/world-map-colored.png")
	if texture:
		world_map_image.texture = texture
		map_background.visible = false
		print("World map loaded successfully as resource")
		print("Texture size: ", texture.get_size())
	else:
		# Fallback: try loading the image directly
		var image = Image.new()
		var error = image.load("res://map_assets/world-map-colored.png")
		if error == OK:
			var tex = ImageTexture.create_from_image(image)
			world_map_image.texture = tex
			map_background.visible = false
			print("World map loaded successfully from file")
			print("Texture size: ", tex.get_size())
		else:
			print("Error: Could not load world map texture, error: ", error)
			print("File path: res://map_assets/world-map-colored.png")
			# Keep the blue background visible as fallback
			map_background.visible = true

func _on_viewport_size_changed():
	# Reposition city buttons when window is resized
	reposition_city_buttons()
	# Update map scale
	update_map_scale()

func reposition_city_buttons():
	var viewport_size = get_viewport_rect().size
	var map_size = Vector2(2000.0, 1171.0)
	
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
	var map_size = Vector2(2000.0, 1171.0)  # Size of the PNG map
	
	for city_id in CITY_POSITIONS.keys():
		var city_data = GameManager.get_city_data(city_id)
		if city_data.is_empty():
			continue
			
		var button = Button.new()
		button.custom_minimum_size = Vector2(100, 50)
		button.add_theme_font_size_override("font_size", 24)
		
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

func create_simulation_controls():
	# Create simulation control panel
	var control_panel = Panel.new()
	control_panel.position = Vector2(50, 50)
	control_panel.custom_minimum_size = Vector2(300, 150)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.5, 0.6, 1)
	control_panel.add_theme_stylebox_override("panel", style)
	
	# Year display
	var year_label = Label.new()
	year_label.position = Vector2(10, 10)
	year_label.text = "Year: 2024"
	year_label.add_theme_font_size_override("font_size", 18)
	control_panel.add_child(year_label)
	
	# Simulation speed control
	var speed_label = Label.new()
	speed_label.position = Vector2(10, 40)
	speed_label.text = "Speed: 1x"
	speed_label.add_theme_font_size_override("font_size", 14)
	control_panel.add_child(speed_label)
	
	# Play/Pause button
	var play_button = Button.new()
	play_button.position = Vector2(10, 70)
	play_button.custom_minimum_size = Vector2(80, 30)
	play_button.text = "Play"
	play_button.pressed.connect(_on_play_pause_pressed)
	control_panel.add_child(play_button)
	
	# Speed up button
	var speed_up_button = Button.new()
	speed_up_button.position = Vector2(100, 70)
	speed_up_button.custom_minimum_size = Vector2(60, 30)
	speed_up_button.text = "2x"
	speed_up_button.pressed.connect(func(): GameManager.simulation_speed = 2.0)
	control_panel.add_child(speed_up_button)
	
	# Speed down button
	var speed_down_button = Button.new()
	speed_down_button.position = Vector2(170, 70)
	speed_down_button.custom_minimum_size = Vector2(60, 30)
	speed_down_button.text = "0.5x"
	speed_down_button.pressed.connect(func(): GameManager.simulation_speed = 0.5)
	control_panel.add_child(speed_down_button)
	
	# Step button
	var step_button = Button.new()
	step_button.position = Vector2(240, 70)
	step_button.custom_minimum_size = Vector2(50, 30)
	step_button.text = "Step"
	step_button.pressed.connect(func(): GameManager.advance_year())
	control_panel.add_child(step_button)
	
	# Leading companies display
	var companies_label = Label.new()
	companies_label.position = Vector2(10, 110)
	companies_label.text = "Leading Companies:"
	companies_label.add_theme_font_size_override("font_size", 12)
	control_panel.add_child(companies_label)
	
	add_child(control_panel)
	
	# Create company comparison panel
	create_company_panel()

func _on_play_pause_pressed():
	if GameManager.is_simulation_running:
		GameManager.stop_simulation()
	else:
		GameManager.start_simulation()

func _on_year_changed(new_year: int):
	# Update year display
	var control_panel = get_node("Panel")
	if control_panel:
		var year_label = control_panel.get_child(0)
		if year_label:
			year_label.text = "Year: %d" % new_year
	
	# Update city buttons with new company data
	update_city_buttons()
	
	# Update company rankings panel
	update_company_panel()

func update_city_buttons():
	# Update city buttons to show current company capabilities
	for city_id in city_buttons:
		var button = city_buttons[city_id]
		var city_companies = GameManager.get_companies_by_city(city_id)
		
		if city_companies.size() > 0:
			var total_capability = 0.0
			for company in city_companies:
				total_capability += company.get_total_capability()
			
			# Color code buttons based on total AI capability
			var intensity = min(total_capability / 10000.0, 1.0)  # Normalize to 0-1
			var color = Color(0.2 + intensity * 0.6, 0.5 + intensity * 0.3, 0.8 + intensity * 0.2, 0.8)
			
			var style_normal = StyleBoxFlat.new()
			style_normal.bg_color = color
			style_normal.border_color = Color(0.4, 0.7, 1.0, 1.0)
			style_normal.border_width_left = 2
			style_normal.border_width_right = 2
			style_normal.border_width_top = 2
			style_normal.border_width_bottom = 2
			button.add_theme_stylebox_override("normal", style_normal)

func format_city_info(data: Dictionary) -> String:
	var city_id = ""
	for id in GameManager.world_state:
		if GameManager.world_state[id] == data:
			city_id = id
			break
	
	var info = """City: %s
Population: %s
Policy: %s
""" % [
	data.name,
	str(data.population),
	data.policy_restrictions
]
	
	# Add AI companies with capabilities
	var city_companies = GameManager.get_companies_by_city(city_id)
	if city_companies.size() > 0:
		info += "\nAI Companies:\n"
		for company in city_companies:
			info += "  • %s\n" % company.name
			info += "    %s\n" % company.get_capability_string()
			info += "    %s\n" % company.get_gpu_string()
			info += "    Total Capability: %.1f\n\n" % company.get_total_capability()
	
	return info

func create_company_panel():
	# Create a panel to show top companies and their capabilities
	var company_panel = Panel.new()
	company_panel.position = Vector2(50, 220)
	company_panel.custom_minimum_size = Vector2(400, 300)
	company_panel.name = "CompanyPanel"
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.5, 0.6, 1)
	company_panel.add_theme_stylebox_override("panel", style)
	
	# Title
	var title_label = Label.new()
	title_label.position = Vector2(10, 10)
	title_label.text = "AI Company Rankings"
	title_label.add_theme_font_size_override("font_size", 16)
	company_panel.add_child(title_label)
	
	# Company list
	var company_list = VBoxContainer.new()
	company_list.position = Vector2(10, 40)
	company_list.custom_minimum_size = Vector2(380, 250)
	company_panel.add_child(company_list)
	
	add_child(company_panel)
	update_company_panel()

func update_company_panel():
	var company_panel = get_node("CompanyPanel")
	if not company_panel:
		return
	
	var company_list = company_panel.get_child(1)
	if not company_list:
		return
	
	# Clear existing children
	for child in company_list.get_children():
		child.queue_free()
	
	# Get leading companies
	var leading_companies = GameManager.get_leading_companies()
	
	for i in range(leading_companies.size()):
		var company = leading_companies[i]
		var company_container = HBoxContainer.new()
		
		# Rank
		var rank_label = Label.new()
		rank_label.custom_minimum_size = Vector2(30, 0)
		rank_label.text = "%d." % (i + 1)
		rank_label.add_theme_font_size_override("font_size", 12)
		company_container.add_child(rank_label)
		
		# Company name
		var name_label = Label.new()
		name_label.custom_minimum_size = Vector2(120, 0)
		name_label.text = company.name
		name_label.add_theme_font_size_override("font_size", 12)
		company_container.add_child(name_label)
		
		# Capabilities
		var caps_label = Label.new()
		caps_label.text = "R:%.0f C:%.0f S:%.0f A:%.0f" % [
			company.get_capability(Company.CapabilityAxis.RESEARCH),
			company.get_capability(Company.CapabilityAxis.CODING),
			company.get_capability(Company.CapabilityAxis.SECURITY),
			company.get_capability(Company.CapabilityAxis.ALIGNMENT)
		]
		caps_label.add_theme_font_size_override("font_size", 10)
		company_container.add_child(caps_label)
		
		# Total capability
		var total_label = Label.new()
		total_label.text = "Total: %.0f" % company.get_total_capability()
		total_label.add_theme_font_size_override("font_size", 10)
		company_container.add_child(total_label)
		
		company_list.add_child(company_container)
