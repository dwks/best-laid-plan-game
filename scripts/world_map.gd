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
var chart_panel_visible: bool = false

# Zoom and pan variables
var zoom_level: float = 1.0
var min_zoom: float = 1.0
var max_zoom: float = 3.0
var zoom_speed: float = 0.1
var camera_offset: Vector2 = Vector2.ZERO

# Click and drag variables
var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2.ZERO
var drag_start_camera_offset: Vector2 = Vector2.ZERO

# Touch gesture variables for mobile
var touch_points: Array = []
var last_touch_distance: float = 0.0
var last_zoom_level: float = 1.0
var is_two_finger_gesture: bool = false

# City selection tracking
var selected_city_button: Button = null
var button_clicked_this_frame: bool = false

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
	
	# Enable input processing for zoom
	set_process_input(true)

func _process(_delta):
	# Reset button click flag each frame
	button_clicked_this_frame = false

func _input(event):
	# Handle scroll wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out(event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging
				is_dragging = true
				drag_start_position = event.position
				drag_start_camera_offset = camera_offset
			else:
				# Stop dragging and check if we clicked on empty map area
				is_dragging = false
				# Use a small delay to let button clicks process first
				await get_tree().process_frame
				# Only deselect if no button was clicked this frame
				if not button_clicked_this_frame:
					# Clear selected city and hide info panel
					GameManager.selected_city = ""
					hide_info_panel()
	
	# Handle mouse movement for dragging
	elif event is InputEventMouseMotion and is_dragging:
		var drag_delta = event.position - drag_start_position
		camera_offset = drag_start_camera_offset + drag_delta
		apply_boundary_constraints()
		apply_zoom()
	
	# Handle touch input for mobile
	elif event is InputEventScreenTouch:
		if event.pressed:
			# Add touch point with index
			touch_points.append({"index": event.index, "position": event.position})
		else:
			# Store the release position for potential empty map click detection
			var release_position = event.position
			
			# Remove touch point by index
			for i in range(touch_points.size() - 1, -1, -1):
				if touch_points[i]["index"] == event.index:
					touch_points.remove_at(i)
					break
			
			# Check for empty map click when all touches are released
			if touch_points.size() == 0 and not is_two_finger_gesture:
				# Use a small delay to let button clicks process first
				await get_tree().process_frame
				# Only deselect if no button was clicked this frame
				if not button_clicked_this_frame:
					# Clear selected city and hide info panel
					GameManager.selected_city = ""
					hide_info_panel()
		
		# Reset touch gesture state when no touches
		if touch_points.size() == 0:
			last_touch_distance = 0.0
			is_dragging = false
			is_two_finger_gesture = false
	
	# Handle touch movement for mobile gestures
	elif event is InputEventScreenDrag:
		# Update touch point position by index
		for i in range(touch_points.size()):
			if touch_points[i]["index"] == event.index:
				touch_points[i]["position"] = event.position
				break
		
		# Handle two-finger pinch-to-zoom
		if touch_points.size() == 2:
			is_two_finger_gesture = true
			is_dragging = false  # Stop any single-finger dragging
			
			var distance = touch_points[0]["position"].distance_to(touch_points[1]["position"])
			if last_touch_distance > 0:
				var zoom_factor = distance / last_touch_distance
				var center_point = (touch_points[0]["position"] + touch_points[1]["position"]) / 2
				
				# More sensitive zoom thresholds
				if zoom_factor > 1.02:  # Zoom in threshold
					zoom_in(center_point, (zoom_factor - 1.0) * 2.0)
					last_touch_distance = distance
				elif zoom_factor < 0.98:  # Zoom out threshold
					zoom_out(center_point, (1.0 - zoom_factor) * 2.0)
					last_touch_distance = distance
			else:
				last_touch_distance = distance
		
		# Handle single-finger dragging (only when not doing two-finger gestures)
		elif touch_points.size() == 1 and not is_two_finger_gesture:
			if not is_dragging:
				is_dragging = true
				drag_start_position = event.position
				drag_start_camera_offset = camera_offset
			else:
				var drag_delta = event.position - drag_start_position
				camera_offset = drag_start_camera_offset + drag_delta
				apply_boundary_constraints()
				apply_zoom()
		
	
	# Handle pinch-to-zoom on mobile (fallback)
	elif event is InputEventMagnifyGesture:
		if event.factor > 1.0:
			zoom_in(event.position, event.factor - 1.0)
		elif event.factor < 1.0:
			zoom_out(event.position, 1.0 - event.factor)

func _is_click_on_city_button(click_position: Vector2) -> bool:
	# Check if the click position is within any city button's bounds
	# Return the topmost button that contains the click position
	var topmost_button = null
	var topmost_z_index = -1
	
	for city_id in city_buttons:
		var button = city_buttons[city_id]
		if button and button.visible:
			var button_rect = Rect2(button.position, button.custom_minimum_size)
			if button_rect.has_point(click_position):
				# Check if this button is on top (higher z-index or later in scene tree)
				var button_z_index = button.z_index
				if button_z_index > topmost_z_index:
					topmost_button = button
					topmost_z_index = button_z_index
	
	return topmost_button != null

func hide_info_panel():
	# Hide the info panel
	var info_panel = get_node("InfoPanel")
	if info_panel:
		info_panel.visible = false
	
	# Deselect all city buttons
	for button_id in city_buttons:
		var button = city_buttons[button_id]
		if button:
			button.button_pressed = false
			button.release_focus()  # Force button to lose focus
			button.queue_redraw()   # Force visual update
	
	selected_city_button = null

func zoom_in(mouse_position: Vector2, factor: float = zoom_speed):
	var old_zoom = zoom_level
	zoom_level = min(zoom_level + factor, max_zoom)
	
	if zoom_level != old_zoom:
		# Calculate zoom center relative to current map position
		var viewport_size = get_viewport_rect().size
		var texture_size = world_map_image.texture.get_size()
		var scale_x = viewport_size.x / texture_size.x
		var scale_y = viewport_size.y / texture_size.y
		
		# Calculate current map position in screen coordinates
		var current_map_size = Vector2(
			texture_size.x * scale_x * old_zoom,
			texture_size.y * scale_y * old_zoom
		)
		
		# Calculate zoom center relative to map
		var zoom_center_relative = (mouse_position - camera_offset) / old_zoom
		
		# Adjust camera offset to zoom towards the touch point
		var zoom_delta = zoom_level - old_zoom
		camera_offset -= zoom_center_relative * zoom_delta
		
		apply_zoom()

func zoom_out(mouse_position: Vector2, factor: float = zoom_speed):
	var old_zoom = zoom_level
	zoom_level = max(zoom_level - factor, min_zoom)
	
	if zoom_level != old_zoom:
		# Calculate zoom center relative to current map position
		var viewport_size = get_viewport_rect().size
		var texture_size = world_map_image.texture.get_size()
		var scale_x = viewport_size.x / texture_size.x
		var scale_y = viewport_size.y / texture_size.y
		
		# Calculate current map position in screen coordinates
		var current_map_size = Vector2(
			texture_size.x * scale_x * old_zoom,
			texture_size.y * scale_y * old_zoom
		)
		
		# Calculate zoom center relative to map
		var zoom_center_relative = (mouse_position - camera_offset) / old_zoom
		
		# Adjust camera offset to zoom towards the touch point
		var zoom_delta = old_zoom - zoom_level
		camera_offset += zoom_center_relative * zoom_delta
		
		apply_zoom()

func apply_zoom():
	# Apply zoom to the world map image
	if world_map_image:
		# Get the base scale from update_map_scale
		var viewport_size = get_viewport_rect().size
		var texture_size = world_map_image.texture.get_size()
		var scale_x = viewport_size.x / texture_size.x
		var scale_y = viewport_size.y / texture_size.y
		
		# Use individual scales to match window aspect ratio
		world_map_image.scale = Vector2(scale_x * zoom_level, scale_y * zoom_level)
		
		# Apply boundary constraints to camera offset
		apply_boundary_constraints()
		
		# Position map from top-left origin (same as buttons) and apply camera offset
		world_map_image.position = camera_offset
	
	# Update city button positions
	update_city_button_positions()

func apply_boundary_constraints():
	if not world_map_image or not world_map_image.texture:
		return
	
	var viewport_size = get_viewport_rect().size
	var texture_size = world_map_image.texture.get_size()
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	
	# Calculate scaled texture size using individual scales
	var scaled_texture_size = Vector2(
		texture_size.x * scale_x * zoom_level,
		texture_size.y * scale_y * zoom_level
	)
	
	# Calculate boundary limits
	var min_offset_x = viewport_size.x - scaled_texture_size.x
	var min_offset_y = viewport_size.y - scaled_texture_size.y
	
	# Constrain camera offset to keep map in view
	camera_offset.x = clamp(camera_offset.x, min_offset_x, 0)
	camera_offset.y = clamp(camera_offset.y, min_offset_y, 0)

func update_city_button_positions():
	# Update city button positions based on zoom and camera offset
	var viewport_size = get_viewport_rect().size
	var map_size = Vector2(2000.0, 1171.0)  # Size of the PNG map
	
	# Get the same scaling factors as the map
	var texture_size = world_map_image.texture.get_size()
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	
	for city_id in city_buttons:
		var button = city_buttons[city_id]
		if button:
			# Convert city position to texture coordinates
			var relative_x = CITY_POSITIONS[city_id].x / map_size.x
			var relative_y = CITY_POSITIONS[city_id].y / map_size.y
			
			# Apply the same scaling as the map (top-left origin)
			var scaled_position = Vector2(
				relative_x * texture_size.x * scale_x * zoom_level,
				relative_y * texture_size.y * scale_y * zoom_level
			)
			
			# Apply camera offset (same as map)
			var final_position = scaled_position + camera_offset
			
			button.position = final_position - button.custom_minimum_size / 2

func update_map_scale():
	if world_map_image.texture == null:
		return
	
	var texture_size = world_map_image.texture.get_size()
	
	# Set pivot offset to top-left (same as buttons)
	world_map_image.pivot_offset = Vector2.ZERO
	
	# Calculate individual scale factors to match window aspect ratio
	var viewport_size = get_viewport_rect().size
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	
	# Apply zoom using individual scales to match window aspect ratio
	world_map_image.scale = Vector2(scale_x * zoom_level, scale_y * zoom_level)
	
	# Apply boundary constraints to camera offset
	apply_boundary_constraints()
	
	# Position map from top-left origin (same as buttons) and apply camera offset
	world_map_image.position = camera_offset
	
	# Update city button positions
	update_city_button_positions()

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
	
	# Get the same scaling factors as the map
	var texture_size = world_map_image.texture.get_size()
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	
	for city_id in city_buttons:
		var button = city_buttons[city_id]
		# Convert city position to texture coordinates
		var relative_x = CITY_POSITIONS[city_id].x / map_size.x
		var relative_y = CITY_POSITIONS[city_id].y / map_size.y
		
		# Apply the same scaling as the map (top-left origin)
		var scaled_position = Vector2(
			relative_x * texture_size.x * scale_x * zoom_level,
			relative_y * texture_size.y * scale_y * zoom_level
		)
		
		# Apply camera offset (same as map)
		var final_position = scaled_position + camera_offset
		
		button.position = final_position - button.custom_minimum_size / 2

func create_city_buttons():
	# Get the viewport size to scale positions relative to window
	var viewport_size = get_viewport_rect().size
	var map_size = Vector2(2000.0, 1171.0)  # Size of the PNG map
	
	# Get the same scaling factors as the map
	var texture_size = world_map_image.texture.get_size()
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	
	for city_id in CITY_POSITIONS.keys():
		var city_data = GameManager.get_city_data(city_id)
		if city_data.is_empty():
			continue
			
		var button = Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(100, 50)
		button.add_theme_font_size_override("font_size", 24)
		
		# Convert city position to texture coordinates
		var relative_x = CITY_POSITIONS[city_id].x / map_size.x
		var relative_y = CITY_POSITIONS[city_id].y / map_size.y
		
		# Apply the same scaling as the map (top-left origin)
		var scaled_position = Vector2(
			relative_x * texture_size.x * scale_x * zoom_level,
			relative_y * texture_size.y * scale_y * zoom_level
		)
		
		# Apply camera offset (same as map)
		var final_position = scaled_position + camera_offset
		
		button.position = final_position - button.custom_minimum_size / 2
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

		var style_pressed = StyleBoxFlat.new()
		style_pressed.bg_color = Color(0.4, 0.7, 1.0, 0.9)  # Brighter blue
		style_pressed.border_color = Color(1.0, 1.0, 1.0, 1.0)  # White border
		style_pressed.border_width_left = 3
		style_pressed.border_width_right = 3
		style_pressed.border_width_top = 3
		style_pressed.border_width_bottom = 3
		button.add_theme_stylebox_override("pressed", style_pressed)
		
		button.pressed.connect(func(): GameManager.select_city(city_id))
		city_container.add_child(button)
		city_buttons[city_id] = button

func _on_city_selected(city_name: String):
	# Mark that a button was clicked this frame
	button_clicked_this_frame = true
	
	# Deselect all city buttons first
	for button_id in city_buttons:
		var button = city_buttons[button_id]
		if button:
			button.button_pressed = false
	
	# Select the new city button
	if city_buttons.has(city_name):
		var button = city_buttons[city_name]
		if button:
			button.button_pressed = true
			selected_city_button = button
	
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
	control_panel.custom_minimum_size = Vector2(700, 120)
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
	
	# Show/Hide Chart button
	var chart_button = Button.new()
	chart_button.position = Vector2(580, 60)
	chart_button.custom_minimum_size = Vector2(100, 25)
	chart_button.text = "Show Chart"
	chart_button.pressed.connect(_on_chart_toggle)
	control_panel.add_child(chart_button)
	
	add_child(control_panel)
	
	# Create company comparison panel
	create_company_panel()
	
	# Create chart panel
	create_chart_panel()

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
		var rankings_button = control_panel.get_child(8)  # 9th child (0-indexed) - rankings button
		if rankings_button:
			rankings_button.text = "Hide Rankings" if company_panel_visible else "Show Rankings"

func _on_chart_toggle():
	chart_panel_visible = !chart_panel_visible
	var chart_panel = get_node("ChartPanel")
	if chart_panel:
		chart_panel.visible = chart_panel_visible
	
	# Update button text
	var control_panel = get_node("SimulationControlPanel")
	if control_panel:
		var chart_button = control_panel.get_child(9)  # 10th child (0-indexed) - chart button
		if chart_button:
			chart_button.text = "Hide Chart" if chart_panel_visible else "Show Chart"

func create_chart_panel():
	# Create a panel to show company capability charts
	var chart_panel = Panel.new()
	chart_panel.position = Vector2(50, 180)
	chart_panel.custom_minimum_size = Vector2(600, 400)
	chart_panel.name = "ChartPanel"
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.5, 0.6, 1)
	chart_panel.add_theme_stylebox_override("panel", style)
	
	# Title
	var title_label = Label.new()
	title_label.position = Vector2(10, 10)
	title_label.text = "AI Company Capability Growth Over Time"
	title_label.add_theme_font_size_override("font_size", 16)
	chart_panel.add_child(title_label)
	
	# Chart area
	var chart_area = Control.new()
	chart_area.position = Vector2(10, 40)
	chart_area.custom_minimum_size = Vector2(580, 350)
	chart_area.name = "ChartArea"
	chart_panel.add_child(chart_area)
	
	add_child(chart_panel)
	chart_panel.visible = false  # Hidden by default
	update_chart()

func update_chart():
	var chart_panel = get_node("ChartPanel")
	if not chart_panel or not chart_panel.visible:
		return
	
	var chart_area = chart_panel.get_node("ChartArea")
	if not chart_area:
		return
	
	# Clear previous chart
	for child in chart_area.get_children():
		child.queue_free()
	
	var historical_data = GameManager.get_historical_data()
	var time_points = GameManager.get_time_points()
	
	if time_points.size() < 2:
		var no_data_label = Label.new()
		no_data_label.position = Vector2(50, 50)
		no_data_label.text = "Not enough data to display chart"
		no_data_label.add_theme_font_size_override("font_size", 14)
		chart_area.add_child(no_data_label)
		return
	
	# Find min/max values for scaling
	var min_time = time_points[0]
	var max_time = time_points[-1]
	var min_value = 0.0
	var max_value = 0.0
	
	for company_id in historical_data:
		var data = historical_data[company_id]
		for value in data:
			max_value = max(max_value, value)
	
	# Define colors for different companies
	var company_colors = {
		"openbrain": Color(1.0, 0.2, 0.2),      # Red
		"deepcent": Color(0.4, 0.6, 1.0),        # Bright Blue
		"google_ai": Color(0.2, 1.0, 0.2),      # Green
		"microsoft_ai": Color(1.0, 0.5, 0.0),   # Orange
		"anthropic": Color(1.0, 0.0, 1.0),      # Magenta
		"deepmind": Color(0.0, 1.0, 1.0),       # Cyan
		"huawei_ai": Color(1.0, 1.0, 0.0),      # Yellow
		"deepseek": Color(0.5, 0.5, 0.5),       # Gray
		"alibaba_ai": Color(0.8, 0.4, 0.0),     # Brown
		"tsmc_ai": Color(0.4, 0.8, 0.4)         # Light Green
	}
	
	# Draw chart lines for each company
	var chart_width = 580
	var chart_height = 350
	var margin = 40
	
	for company_id in historical_data:
		var data = historical_data[company_id]
		if data.size() < 2:
			continue
		
		var color = company_colors.get(company_id, Color.WHITE)
		
		# Draw line segments
		for i in range(data.size() - 1):
			var x1 = margin + (time_points[i] - min_time) / (max_time - min_time) * (chart_width - 2 * margin)
			var y1 = margin + (1.0 - (data[i] - min_value) / (max_value - min_value)) * (chart_height - 2 * margin)
			var x2 = margin + (time_points[i + 1] - min_time) / (max_time - min_time) * (chart_width - 2 * margin)
			var y2 = margin + (1.0 - (data[i + 1] - min_value) / (max_value - min_value)) * (chart_height - 2 * margin)
			
			var line = Line2D.new()
			line.add_point(Vector2(x1, y1))
			line.add_point(Vector2(x2, y2))
			line.default_color = color
			line.width = 2.0
			chart_area.add_child(line)
	
	# Add axis labels
	var x_label = Label.new()
	x_label.position = Vector2(chart_width / 2 - 50, chart_height - 20)
	x_label.text = "Time (Days from 2024)"
	x_label.add_theme_font_size_override("font_size", 12)
	chart_area.add_child(x_label)
	
	var y_label = Label.new()
	y_label.position = Vector2(5, chart_height / 2 - 20)
	y_label.text = "Total Capability"
	y_label.add_theme_font_size_override("font_size", 12)
	y_label.rotation = -PI / 2
	chart_area.add_child(y_label)
	
	# Add legend
	var legend_y = 10
	for company_id in historical_data:
		if company_id in company_colors:
			var company = GameManager.get_company_data(company_id)
			if company:
				var legend_item = Label.new()
				legend_item.position = Vector2(chart_width - 150, legend_y)
				legend_item.text = company.name
				legend_item.add_theme_font_size_override("font_size", 10)
				legend_item.add_theme_color_override("font_color", company_colors[company_id])
				chart_area.add_child(legend_item)
				legend_y += 15

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
	
	# Update chart if visible
	update_chart()
	
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
