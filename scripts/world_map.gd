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
var company_panel_visible: bool = false

func _ready():
	# Wait for GameManager to be ready before connecting signals
	await get_tree().process_frame
	GameManager.city_selected.connect(_on_city_selected)
	GameManager.year_changed.connect(_on_year_changed)
	GameManager.time_changed.connect(_on_time_changed)
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
	control_panel.custom_minimum_size = Vector2(500, 120)
	control_panel.name = "SimulationControlPanel"
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.5, 0.6, 1)
	control_panel.add_theme_stylebox_override("panel", style)
	
	# Date/Time display
	var datetime_label = Label.new()
	datetime_label.position = Vector2(10, 10)
	datetime_label.text = format_datetime()
	datetime_label.add_theme_font_size_override("font_size", 18)
	control_panel.add_child(datetime_label)
	
	# Speed display
	var speed_label = Label.new()
	speed_label.position = Vector2(10, 35)
	speed_label.text = "speed: 1mo"
	speed_label.add_theme_font_size_override("font_size", 14)
	control_panel.add_child(speed_label)
	
	# Speed buttons
	var speed_1mo_button = Button.new()
	speed_1mo_button.position = Vector2(10, 60)
	speed_1mo_button.custom_minimum_size = Vector2(60, 25)
	speed_1mo_button.text = "1mo"
	speed_1mo_button.pressed.connect(_on_speed_month)
	control_panel.add_child(speed_1mo_button)
	
	var speed_1w_button = Button.new()
	speed_1w_button.position = Vector2(80, 60)
	speed_1w_button.custom_minimum_size = Vector2(60, 25)
	speed_1w_button.text = "1w"
	speed_1w_button.pressed.connect(_on_speed_week)
	control_panel.add_child(speed_1w_button)
	
	var speed_1d_button = Button.new()
	speed_1d_button.position = Vector2(150, 60)
	speed_1d_button.custom_minimum_size = Vector2(60, 25)
	speed_1d_button.text = "1d"
	speed_1d_button.pressed.connect(_on_speed_day)
	control_panel.add_child(speed_1d_button)
	
	var speed_1m_button = Button.new()
	speed_1m_button.position = Vector2(220, 60)
	speed_1m_button.custom_minimum_size = Vector2(60, 25)
	speed_1m_button.text = "1m"
	speed_1m_button.pressed.connect(_on_speed_minute)
	control_panel.add_child(speed_1m_button)
	
	# Play/Stop button
	var play_button = Button.new()
	play_button.position = Vector2(300, 60)
	play_button.custom_minimum_size = Vector2(80, 25)
	play_button.text = "Play"
	play_button.pressed.connect(_on_play_pause_pressed)
	control_panel.add_child(play_button)
	
	# Step button
	var step_button = Button.new()
	step_button.position = Vector2(390, 60)
	step_button.custom_minimum_size = Vector2(50, 25)
	step_button.text = "Step"
	step_button.pressed.connect(_on_step_pressed)
	control_panel.add_child(step_button)
	
	# Show/Hide Rankings button
	var rankings_button = Button.new()
	rankings_button.position = Vector2(450, 60)
	rankings_button.custom_minimum_size = Vector2(120, 25)
	rankings_button.text = "Show Rankings"
	rankings_button.pressed.connect(_on_leaderboard_toggle)
	control_panel.add_child(rankings_button)
	
	add_child(control_panel)
	
	# Create company comparison panel
	create_company_panel()

func _on_step_pressed():
	GameManager.step_time()

func _on_speed_month():
	GameManager.set_time_unit("month")
	update_speed_display()

func _on_speed_week():
	GameManager.set_time_unit("week")
	update_speed_display()

func _on_speed_day():
	GameManager.set_time_unit("day")
	update_speed_display()

func _on_speed_minute():
	GameManager.set_time_unit("minute")
	update_speed_display()

func update_speed_display():
	var control_panel = get_node("SimulationControlPanel")
	if control_panel:
		var speed_label = control_panel.get_child(1)
		if speed_label:
			speed_label.text = "speed: 1" + GameManager.time_unit

func format_datetime() -> String:
	var month_name = get_month_name(GameManager.month)
	var am_pm = "AM" if GameManager.hour < 12 else "PM"
	var display_hour = GameManager.hour
	if display_hour == 0:
		display_hour = 12
	elif display_hour > 12:
		display_hour -= 12
	
	return "%s %d %d %d:%02d%s" % [
		month_name,
		GameManager.day,
		GameManager.year,
		display_hour,
		GameManager.minute,
		am_pm
	]

func _on_play_pause_pressed():
	if GameManager.is_simulation_running:
		GameManager.stop_simulation()
		update_play_button_text()
	else:
		GameManager.start_simulation()
		update_play_button_text()

func update_play_button_text():
	var control_panel = get_node("SimulationControlPanel")
	if control_panel:
		var play_button = control_panel.get_child(6)
		if play_button:
			play_button.text = "Stop" if GameManager.is_simulation_running else "Play"

func _on_leaderboard_toggle():
	company_panel_visible = !company_panel_visible
	var company_panel = get_node("CompanyPanel")
	if company_panel:
		company_panel.visible = company_panel_visible
	
	# Update button text
	var control_panel = get_node("SimulationControlPanel")
	if control_panel:
		var rankings_button = control_panel.get_child(8)
		if rankings_button:
			rankings_button.text = "Hide Rankings" if company_panel_visible else "Show Rankings"

func _on_year_changed(new_year: int):
	# Update year display
	var control_panel = get_node("SimulationControlPanel")
	if control_panel:
		var year_label = control_panel.get_child(0)
		if year_label:
			year_label.text = get_month_name(GameManager.month) + " " + str(new_year)
	
	# Update city buttons with new company data
	update_city_buttons()
	
	# Update company rankings panel
	update_company_panel()
	
	# Update info panel if a city is selected
	if GameManager.selected_city != "":
		update_info_panel(GameManager.selected_city)

func _on_time_changed(year: int, month: int, day: int, hour: int, minute: int):
	# Update datetime display
	var control_panel = get_node("SimulationControlPanel")
	if control_panel:
		var datetime_label = control_panel.get_child(0)
		if datetime_label:
			datetime_label.text = format_datetime()
		
		# Update speed display
		var speed_label = control_panel.get_child(1)
		if speed_label:
			speed_label.text = "speed: 1" + GameManager.time_unit
		
		# Update play button text
		update_play_button_text()
	
	# Update city buttons with new company data
	update_city_buttons()
	
	# Update company rankings panel
	update_company_panel()
	
	# Update info panel if a city is selected
	if GameManager.selected_city != "":
		update_info_panel(GameManager.selected_city)

func get_month_name(month_num: int) -> String:
	var months = ["January", "February", "March", "April", "May", "June",
				  "July", "August", "September", "October", "November", "December"]
	return months[month_num - 1]

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
	
	var info = "%s\nPopulation: %s\nPolicy: %s\n" % [
		data.name,
		str(data.population),
		data.policy_restrictions
	]
	
	# Add AI companies with simplified info
	var city_companies = GameManager.get_companies_by_city(city_id)
	if city_companies.size() > 0:
		info += "\nAI Companies:\n"
		
		# Sort companies by total capability
		city_companies.sort_custom(func(a, b): return a.get_total_capability() > b.get_total_capability())
		
		for i in range(min(3, city_companies.size())):  # Show only top 3 companies
			var company = city_companies[i]
			info += "%d. %s\n" % [i + 1, company.name]
			info += "   Total: %.0f | GPUs: %d\n" % [company.get_total_capability(), company.gpu_count]
		
		if city_companies.size() > 3:
			info += "... and %d more\n" % (city_companies.size() - 3)
	else:
		info += "\nNo AI companies here.\n"
	
	return info

func create_company_panel():
	# Create a panel to show top companies and their capabilities
	var company_panel = Panel.new()
	company_panel.position = Vector2(50, 220)
	company_panel.custom_minimum_size = Vector2(500, 400)
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
	company_list.custom_minimum_size = Vector2(480, 350)
	company_panel.add_child(company_list)
	
	add_child(company_panel)
	company_panel.visible = false  # Hidden by default
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
		rank_label.add_theme_font_size_override("font_size", 16)
		company_container.add_child(rank_label)
		
		# Company name
		var name_label = Label.new()
		name_label.custom_minimum_size = Vector2(120, 0)
		name_label.text = company.name
		name_label.add_theme_font_size_override("font_size", 16)
		company_container.add_child(name_label)
		
		# Capabilities
		var caps_label = Label.new()
		caps_label.text = "R:%.0f C:%.0f S:%.0f A:%.0f" % [
			company.get_capability(Company.CapabilityAxis.RESEARCH),
			company.get_capability(Company.CapabilityAxis.CODING),
			company.get_capability(Company.CapabilityAxis.SECURITY),
			company.get_capability(Company.CapabilityAxis.ALIGNMENT)
		]
		caps_label.add_theme_font_size_override("font_size", 14)
		company_container.add_child(caps_label)
		
		# Total capability
		var total_label = Label.new()
		total_label.text = "Total: %.0f" % company.get_total_capability()
		total_label.add_theme_font_size_override("font_size", 14)
		company_container.add_child(total_label)
		
		company_list.add_child(company_container)
