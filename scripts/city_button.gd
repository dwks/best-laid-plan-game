extends Button

@export var city_name: String = ""
@export var position_x: float = 0.0
@export var position_y: float = 0.0

signal city_clicked(city_name: String)

func _ready():
	if city_name != "":
		text = city_name
		pressed.connect(_on_city_clicked)

func _on_city_clicked():
	city_clicked.emit(city_name)
	print("Clicked on city: ", city_name)

func _draw():
	# Draw a small highlight circle when hovering
	if is_hovered():
		draw_circle(Vector2(size.x/2, size.y/2), size.x/2 + 5, Color.YELLOW.lerp(Color.TRANSPARENT, 0.7))
