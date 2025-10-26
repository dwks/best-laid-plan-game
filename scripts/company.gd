class_name Company
extends RefCounted

# AI Capability axes (4-dimensional array)
enum CapabilityAxis {
	RESEARCH,    # AI research and development
	CODING,      # Software development and automation
	SECURITY,    # Cybersecurity and hacking capabilities
	ALIGNMENT    # AI safety and alignment research
}

var name: String
var country: String
var city: String
var capabilities: Array[float] = [0.0, 0.0, 0.0, 0.0]  # 4D capability array
var gpu_count: int = 0
var gpu_growth_rate: float = 1.5  # Exponential growth multiplier per year
var base_capability: float = 1.0  # Base capability multiplier
var founded_year: int = 2024

# Company-specific modifiers
var research_focus: float = 1.0
var coding_focus: float = 1.0
var security_focus: float = 1.0
var alignment_focus: float = 1.0

func _init(company_name: String, company_country: String, company_city: String, 
		   initial_gpus: int = 0, year_founded: int = 2024):
	name = company_name
	country = company_country
	city = company_city
	gpu_count = initial_gpus
	founded_year = year_founded
	
	# Initialize capabilities based on founding year and GPU count
	update_capabilities()

func update_capabilities():
	# Calculate capabilities based on GPU count and time elapsed
	var years_elapsed = max(0, GameManager.year - founded_year)
	var gpu_multiplier = pow(gpu_growth_rate, years_elapsed)
	var effective_gpus = gpu_count * gpu_multiplier
	
	# Capabilities scale with GPU count and company focus
	capabilities[CapabilityAxis.RESEARCH] = effective_gpus * base_capability * research_focus * 0.1
	capabilities[CapabilityAxis.CODING] = effective_gpus * base_capability * coding_focus * 0.1
	capabilities[CapabilityAxis.SECURITY] = effective_gpus * base_capability * security_focus * 0.1
	capabilities[CapabilityAxis.ALIGNMENT] = effective_gpus * base_capability * alignment_focus * 0.1

func add_gpus(count: int):
	gpu_count += count
	update_capabilities()

func set_gpu_growth_rate(rate: float):
	gpu_growth_rate = rate

func set_capability_focus(axis: CapabilityAxis, focus: float):
	match axis:
		CapabilityAxis.RESEARCH:
			research_focus = focus
		CapabilityAxis.CODING:
			coding_focus = focus
		CapabilityAxis.SECURITY:
			security_focus = focus
		CapabilityAxis.ALIGNMENT:
			alignment_focus = focus
	update_capabilities()

func get_capability(axis: CapabilityAxis) -> float:
	return capabilities[axis]

func get_total_capability() -> float:
	return capabilities.reduce(func(acc, val): return acc + val, 0.0)

func get_capability_string() -> String:
	return "Research: %.1f | Coding: %.1f | Security: %.1f | Alignment: %.1f" % [
		capabilities[CapabilityAxis.RESEARCH],
		capabilities[CapabilityAxis.CODING],
		capabilities[CapabilityAxis.SECURITY],
		capabilities[CapabilityAxis.ALIGNMENT]
	]

func get_gpu_string() -> String:
	var years_elapsed = max(0, GameManager.year - founded_year)
	var effective_gpus = gpu_count * pow(gpu_growth_rate, years_elapsed)
	return "GPUs: %d (Effective: %.0f)" % [gpu_count, effective_gpus]
