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
			"policy_restrictions": "regulated",
			"ai_companies": ["Palo Alto Networks (Gov)"]
		},
		"san_francisco": {
			"name": "San Francisco",
			"population": 873_965,
			"policy_restrictions": "permissive",
			"ai_companies": ["OpenAI", "Anthropic", "Google AI"]
		},
		"seattle": {
			"name": "Seattle",
			"population": 749_256,
			"policy_restrictions": "moderate",
			"ai_companies": ["Microsoft AI", "Amazon AI Labs"]
		},
		"new_york": {
			"name": "New York",
			"population": 8_336_817,
			"policy_restrictions": "moderate",
			"ai_companies": ["Bloomberg AI"]
		},
		"london": {
			"name": "London",
			"population": 9_648_110,
			"policy_restrictions": "strict",
			"ai_companies": ["DeepMind"]
		},
		"beijing": {
			"name": "Beijing",
			"population": 21_542_000,
			"policy_restrictions": "state-controlled",
			"ai_companies": ["DeepSeek", "Alibaba AI (Qwen)", "Baidu AI"]
		},
		"shenzhen": {
			"name": "Shenzhen",
			"population": 17_600_000,
			"policy_restrictions": "permissive",
			"ai_companies": ["Huawei AI", "Tencent AI Lab"]
		},
		"singapore": {
			"name": "Singapore",
			"population": 5_686_000,
			"policy_restrictions": "moderate",
			"ai_companies": ["Grab AI"]
		},
		"tokyo": {
			"name": "Tokyo",
			"population": 13_515_271,
			"policy_restrictions": "permissive",
			"ai_companies": ["Sony AI", "Sakana AI"]
		},
		"taipei": {
			"name": "Taipei",
			"population": 2_646_000,
			"policy_restrictions": "moderate",
			"ai_companies": ["TSMC AI", "MediaTek AI"]
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
