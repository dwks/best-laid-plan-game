extends Node

signal city_selected(city_name: String)
signal year_changed(year: int)

var selected_city: String = ""
var world_state: Dictionary = {}
var year: int = 2024
var companies: Dictionary = {}
var simulation_speed: float = 1.0  # Years per second
var is_simulation_running: bool = false

func _ready():
	initialize_world()
	initialize_companies()
	setup_simulation_timer()

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

func initialize_companies():
	# Create companies based on AI 2027 scenario
	# US Companies
	companies["openbrain"] = Company.new("OpenBrain", "USA", "san_francisco", 10000, 2024)
	companies["openbrain"].set_capability_focus(Company.CapabilityAxis.RESEARCH, 2.0)
	companies["openbrain"].set_capability_focus(Company.CapabilityAxis.CODING, 1.5)
	companies["openbrain"].set_gpu_growth_rate(2.0)  # Aggressive growth
	
	companies["anthropic"] = Company.new("Anthropic", "USA", "san_francisco", 5000, 2024)
	companies["anthropic"].set_capability_focus(Company.CapabilityAxis.ALIGNMENT, 2.5)
	companies["anthropic"].set_capability_focus(Company.CapabilityAxis.RESEARCH, 1.8)
	companies["anthropic"].set_gpu_growth_rate(1.8)
	
	companies["google_ai"] = Company.new("Google AI", "USA", "san_francisco", 15000, 2024)
	companies["google_ai"].set_capability_focus(Company.CapabilityAxis.RESEARCH, 1.8)
	companies["google_ai"].set_capability_focus(Company.CapabilityAxis.CODING, 2.0)
	companies["google_ai"].set_gpu_growth_rate(1.7)
	
	companies["microsoft_ai"] = Company.new("Microsoft AI", "USA", "seattle", 12000, 2024)
	companies["microsoft_ai"].set_capability_focus(Company.CapabilityAxis.CODING, 2.2)
	companies["microsoft_ai"].set_capability_focus(Company.CapabilityAxis.SECURITY, 1.5)
	companies["microsoft_ai"].set_gpu_growth_rate(1.6)
	
	companies["deepmind"] = Company.new("DeepMind", "UK", "london", 8000, 2024)
	companies["deepmind"].set_capability_focus(Company.CapabilityAxis.RESEARCH, 2.2)
	companies["deepmind"].set_capability_focus(Company.CapabilityAxis.ALIGNMENT, 1.8)
	companies["deepmind"].set_gpu_growth_rate(1.5)
	
	# Chinese Companies
	companies["deepcent"] = Company.new("DeepCent", "China", "beijing", 20000, 2024)
	companies["deepcent"].set_capability_focus(Company.CapabilityAxis.RESEARCH, 2.5)
	companies["deepcent"].set_capability_focus(Company.CapabilityAxis.SECURITY, 2.0)
	companies["deepcent"].set_gpu_growth_rate(2.2)  # Very aggressive
	
	companies["deepseek"] = Company.new("DeepSeek", "China", "beijing", 12000, 2024)
	companies["deepseek"].set_capability_focus(Company.CapabilityAxis.RESEARCH, 2.0)
	companies["deepseek"].set_capability_focus(Company.CapabilityAxis.CODING, 1.8)
	companies["deepseek"].set_gpu_growth_rate(2.0)
	
	companies["alibaba_ai"] = Company.new("Alibaba AI (Qwen)", "China", "beijing", 10000, 2024)
	companies["alibaba_ai"].set_capability_focus(Company.CapabilityAxis.CODING, 2.0)
	companies["alibaba_ai"].set_capability_focus(Company.CapabilityAxis.RESEARCH, 1.5)
	companies["alibaba_ai"].set_gpu_growth_rate(1.8)
	
	companies["huawei_ai"] = Company.new("Huawei AI", "China", "shenzhen", 8000, 2024)
	companies["huawei_ai"].set_capability_focus(Company.CapabilityAxis.SECURITY, 2.5)
	companies["huawei_ai"].set_capability_focus(Company.CapabilityAxis.RESEARCH, 1.8)
	companies["huawei_ai"].set_gpu_growth_rate(1.9)
	
	# Other Companies
	companies["sony_ai"] = Company.new("Sony AI", "Japan", "tokyo", 3000, 2024)
	companies["sony_ai"].set_capability_focus(Company.CapabilityAxis.RESEARCH, 1.5)
	companies["sony_ai"].set_capability_focus(Company.CapabilityAxis.CODING, 1.3)
	companies["sony_ai"].set_gpu_growth_rate(1.4)
	
	companies["tsmc_ai"] = Company.new("TSMC AI", "Taiwan", "taipei", 5000, 2024)
	companies["tsmc_ai"].set_capability_focus(Company.CapabilityAxis.CODING, 1.8)
	companies["tsmc_ai"].set_capability_focus(Company.CapabilityAxis.RESEARCH, 1.6)
	companies["tsmc_ai"].set_gpu_growth_rate(1.6)

func setup_simulation_timer():
	var timer = Timer.new()
	timer.wait_time = 1.0 / simulation_speed
	timer.timeout.connect(_on_simulation_tick)
	timer.autostart = false
	add_child(timer)

func start_simulation():
	is_simulation_running = true
	get_node("Timer").start()

func stop_simulation():
	is_simulation_running = false
	get_node("Timer").stop()

func _on_simulation_tick():
	if is_simulation_running:
		advance_year()

func advance_year():
	year += 1
	year_changed.emit(year)
	update_world()

func update_world():
	# Update all company capabilities based on time progression
	for company_id in companies:
		var company = companies[company_id]
		company.update_capabilities()
	
	# Simulate exponential GPU growth and capability improvements
	simulate_ai_progress()

func simulate_ai_progress():
	# Simulate the exponential growth described in AI 2027
	# Each year, companies invest more in GPUs and capabilities
	
	for company_id in companies:
		var company = companies[company_id]
		
		# Add GPUs based on company's growth rate and current capabilities
		var years_elapsed = year - company.founded_year
		var growth_multiplier = pow(1.2, years_elapsed)  # 20% growth per year
		var new_gpus = int(company.gpu_count * 0.1 * growth_multiplier)
		
		if new_gpus > 0:
			company.add_gpus(new_gpus)
		
		# Capability breakthroughs happen randomly but more likely for leading companies
		if randf() < 0.1:  # 10% chance per year
			var breakthrough_axis = randi() % 4
			var breakthrough_amount = company.get_capability(breakthrough_axis) * 0.2
			company.capabilities[breakthrough_axis] += breakthrough_amount

func get_company_data(company_id: String) -> Company:
	if companies.has(company_id):
		return companies[company_id]
	return null

func get_companies_by_city(city_id: String) -> Array[Company]:
	var city_companies: Array[Company] = []
	for company_id in companies:
		var company = companies[company_id]
		if company.city == city_id:
			city_companies.append(company)
	return city_companies

func get_leading_companies() -> Array[Company]:
	var sorted_companies: Array[Company] = []
	for company_id in companies:
		sorted_companies.append(companies[company_id])
	
	sorted_companies.sort_custom(func(a, b): return a.get_total_capability() > b.get_total_capability())
	return sorted_companies.slice(0, 5)  # Top 5 companies
