extends Panel

func _ready():
	visible = false  # Start hidden
	GameManager.city_selected.connect(_on_city_selected)

func _on_city_selected(city_name: String):
	if city_name == "":
		visible = false
		return
	visible = true
	print("Info panel showing city: ", city_name)
