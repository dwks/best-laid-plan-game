extends Node

signal city_selected(city_name: String)

var selected_city: String = ""
var world_state: Dictionary = {}
var year: int = 2024

func _ready():
	initialize_world()

func initialize_world():
	# Initialize basic world state
	world_state = {
		"new_york": {
			"name": "New York",
			"population": 8_336_817,
			"ai_adoption_rate": 0.35,
			"policy_restrictions": "moderate",
			"economic_growth": 2.5,
			"quality_of_life": 0.75
		},
		"london": {
			"name": "London",
			"population": 9_648_110,
			"ai_adoption_rate": 0.42,
			"policy_restrictions": "strict",
			"economic_growth": 1.8,
			"quality_of_life": 0.82
		},
		"tokyo": {
			"name": "Tokyo",
			"population": 13_515_271,
			"ai_adoption_rate": 0.58,
			"policy_restrictions": "permissive",
			"economic_growth": 3.2,
			"quality_of_life": 0.68
		},
		"beijing": {
			"name": "Beijing",
			"population": 21_542_000,
			"ai_adoption_rate": 0.72,
			"policy_restrictions": "state-controlled",
			"economic_growth": 4.1,
			"quality_of_life": 0.61
		}
	}

func select_city(city_name: String):
	if world_state.has(city_name):
		selected_city = city_name
		city_selected.emit(city_name)
		print("Selected city: ", city_name)

func get_city_data(city_name: String) -> Dictionary:
	if world_state.has(city_name):
		return world_state[city_name]
	return {}

func update_world():
	# This will simulate policy changes over time
	year += 1
	# TODO: Implement simulation logic
