extends Node

signal city_selected(city_name: String)

var selected_city: String = ""
var world_state: Dictionary = {}
var year: int = 2024

func _ready():
	initialize_world()

func initialize_world():
	# Initialize world state with AI and tech hub cities
	world_state = {
		"washington_dc": {
			"name": "Washington DC",
			"population": 692_683,
			"ai_adoption_rate": 0.55,
			"policy_restrictions": "regulated",
			"economic_growth": 2.1,
			"quality_of_life": 0.78
		},
		"san_francisco": {
			"name": "San Francisco",
			"population": 873_965,
			"ai_adoption_rate": 0.85,
			"policy_restrictions": "permissive",
			"economic_growth": 4.5,
			"quality_of_life": 0.65
		},
		"seattle": {
			"name": "Seattle",
			"population": 749_256,
			"ai_adoption_rate": 0.78,
			"policy_restrictions": "moderate",
			"economic_growth": 3.8,
			"quality_of_life": 0.72
		},
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
		"beijing": {
			"name": "Beijing",
			"population": 21_542_000,
			"ai_adoption_rate": 0.72,
			"policy_restrictions": "state-controlled",
			"economic_growth": 4.1,
			"quality_of_life": 0.61
		},
		"shenzhen": {
			"name": "Shenzhen",
			"population": 17_600_000,
			"ai_adoption_rate": 0.88,
			"policy_restrictions": "permissive",
			"economic_growth": 5.2,
			"quality_of_life": 0.55
		},
		"singapore": {
			"name": "Singapore",
			"population": 5_686_000,
			"ai_adoption_rate": 0.65,
			"policy_restrictions": "moderate",
			"economic_growth": 3.9,
			"quality_of_life": 0.89
		},
		"tokyo": {
			"name": "Tokyo",
			"population": 13_515_271,
			"ai_adoption_rate": 0.58,
			"policy_restrictions": "permissive",
			"economic_growth": 3.2,
			"quality_of_life": 0.68
		},
		"taipei": {
			"name": "Taipei",
			"population": 2_646_000,
			"ai_adoption_rate": 0.75,
			"policy_restrictions": "moderate",
			"economic_growth": 4.3,
			"quality_of_life": 0.73
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
