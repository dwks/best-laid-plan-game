# AI Game 1 - Company Capabilities Demo
# This script demonstrates the AI company system with exponential growth

extends Node

func _ready():
	print("=== AI Company Capabilities Demo ===")
	print("Based on the AI 2027 scenario from https://ai-2027.com/")
	print()
	
	# Initialize the game manager
	var game_manager = GameManager.new()
	add_child(game_manager)
	
	# Wait a frame for initialization
	await get_tree().process_frame
	
	print("Initial state (2024):")
	print_company_rankings()
	
	print("\nSimulating 3 years of exponential growth...")
	
	# Simulate 3 years
	for year in range(3):
		game_manager.advance_year()
		print("\nYear %d:" % game_manager.year)
		print_company_rankings()
	
	print("\n=== Key Features ===")
	print("• 4D AI Capability System: Research, Coding, Security, Alignment")
	print("• Exponential GPU growth over time")
	print("• Company-specific focus areas and growth rates")
	print("• Real-time simulation with play/pause controls")
	print("• Visual representation of AI capabilities on world map")
	print("• Company rankings based on total capability")

func print_company_rankings():
	var leading_companies = GameManager.get_leading_companies()
	
	for i in range(min(5, leading_companies.size())):
		var company = leading_companies[i]
		print("%d. %s - Total: %.1f | %s" % [
			i + 1,
			company.name,
			company.get_total_capability(),
			company.get_capability_string()
		])
