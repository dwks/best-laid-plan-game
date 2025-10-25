# The Best-Laid Singularity Plan

A strategic simulation game built with Godot 4 that explores future world states based on AI policies.

## Overview

This game simulates how different policy decisions regarding artificial intelligence can shape the future of cities and nations. Players can click on cities on a world map to view detailed information about their AI adoption rates, policy restrictions, economic growth, and quality of life indicators.

## Credits

- World Map: [Simple SVG World Map](https://github.com/flekschas/simple-world-map) by Al MacDonald (CC BY-SA 3.0)

## Features

- Interactive world map with clickable cities
- City details including:
  - Population statistics
  - AI adoption rates
  - Policy restrictions
  - Economic growth metrics
  - Quality of life indicators
- Export support for:
  - Android
  - iOS
  - Web

## Project Structure

```
ai-game-1/
├── project.godot          # Main project configuration
├── export_presets.cfg     # Export settings for platforms
├── icon.svg              # Game icon
├── scenes/
│   └── main.tscn         # Main scene
├── scripts/
│   ├── game_manager.gd   # Singleton for game state
│   ├── world_map.gd      # World map controller
│   ├── city_button.gd    # City button script
│   └── info_panel.gd     # Info panel script
└── README.md             # This file
```

## Getting Started

### Prerequisites

- Godot 4.2 or later
- For Android export: Android SDK and templates
- For iOS export: macOS with Xcode
- For Web export: No additional requirements

### Running the Game

1. Open the project in Godot 4.2+
2. Click the "Run" button or press F5
3. The main scene will load with the world map
4. Click on any highlighted city button to view its details

### Current Cities

The game currently includes 4 cities:
- New York
- London
- Tokyo
- Beijing

## Exporting

### Web Export

1. Project → Export
2. Select "Web" preset
3. Click "Export Project"
4. Select output directory
5. Deploy the generated HTML file to a web server

### Android Export

1. Install Android export templates in Godot
2. Project → Export
3. Select "Android" preset
4. Configure your package name and app settings
5. Click "Export Project"
6. Install the APK on your Android device

### iOS Export

1. Have macOS with Xcode installed
2. Install iOS export templates in Godot
3. Project → Export
4. Select "iOS" preset
5. Configure bundle identifier and certificates
6. Click "Export Project"
7. Open the generated Xcode project and build

## Development Roadmap

- [ ] Add more cities to the map
- [ ] Implement policy decision system
- [ ] Add time progression and simulation logic
- [ ] Create event system for policy consequences
- [ ] Add visual indicators for AI adoption levels
- [ ] Implement save/load functionality
- [ ] Add statistics and graphs
- [ ] Create tutorial/onboarding flow

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]
