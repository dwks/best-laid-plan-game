extends Panel

func _ready():
	visible = false

func _on_city_selected(city_name: String):
	visible = true
	print("Info panel: ", city_name)
