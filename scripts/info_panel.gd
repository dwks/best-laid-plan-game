extends Panel

func _ready():
	visible = true  # Start visible so we can see it
	GameManager.city_selected.connect(_on_city_selected)

func _on_city_selected(city_name: String):
	visible = true
	print("Info panel showing city: ", city_name)
