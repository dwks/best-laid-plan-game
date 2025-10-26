# AI Game 1 - Company Capabilities System

This game has been modified to represent AI companies as actors with their own internal AI capabilities and GPU resources, inspired by the [AI 2027 scenario](https://ai-2027.com/).

## Key Features

### 4D AI Capability System
Each company has capabilities across four axes:
- **Research**: AI research and development capabilities
- **Coding**: Software development and automation capabilities  
- **Security**: Cybersecurity and hacking capabilities
- **Alignment**: AI safety and alignment research capabilities

### GPU Resource System
- Each company starts with a certain number of GPUs
- GPU count grows exponentially over time based on company-specific growth rates
- More GPUs = higher AI capabilities across all axes
- Growth rates vary by company (e.g., DeepCent grows at 2.2x, Sony AI at 1.4x)

### Company Instances
Based on the AI 2027 scenario, the game includes:

**US Companies:**
- **OpenBrain** (San Francisco) - Research-focused, aggressive growth (2.0x)
- **Anthropic** (San Francisco) - Alignment-focused, strong research
- **Google AI** (San Francisco) - Balanced research and coding
- **Microsoft AI** (Seattle) - Coding-focused with security expertise
- **DeepMind** (London) - Research and alignment focused

**Chinese Companies:**
- **DeepCent** (Beijing) - Very aggressive growth (2.2x), research and security focused
- **DeepSeek** (Beijing) - Research and coding capabilities
- **Alibaba AI/Qwen** (Beijing) - Coding-focused
- **Huawei AI** (Shenzhen) - Security-focused with strong research

**Other Companies:**
- **Sony AI** (Tokyo) - Moderate capabilities
- **TSMC AI** (Taipei) - Coding and research focused

### Time Progression System
- **Exponential Growth**: Capabilities grow exponentially as described in AI 2027
- **Breakthrough Events**: Random capability breakthroughs occur (10% chance per year)
- **Simulation Controls**: Play/pause, speed control (0.5x, 1x, 2x), step-by-step
- **Real-time Updates**: UI updates automatically as time progresses

### Visual Interface
- **City Buttons**: Color-coded based on total AI capability in each city
- **Company Rankings Panel**: Shows top 5 companies with their capabilities
- **Detailed Info Panel**: Displays company capabilities and GPU counts when selecting cities
- **Simulation Controls**: Easy-to-use play/pause and speed controls

## How It Works

1. **Initialization**: Companies start with different GPU counts and focus areas
2. **Time Progression**: Each year, companies gain more GPUs based on their growth rate
3. **Capability Calculation**: Capabilities = (GPU count × growth multiplier × focus area × base capability)
4. **Exponential Growth**: As described in AI 2027, capabilities grow exponentially over time
5. **Visual Feedback**: The interface shows real-time updates of company rankings and capabilities

## Usage

1. **Run the Game**: Launch the Godot project
2. **Start Simulation**: Click "Play" to begin time progression
3. **Adjust Speed**: Use 0.5x, 1x, or 2x speed controls
4. **Step Through**: Use "Step" to advance one year at a time
5. **Explore Cities**: Click on city buttons to see detailed company information
6. **Monitor Rankings**: Watch the company rankings panel for real-time updates

## Technical Implementation

- **Company Class**: `scripts/company.gd` - Core company logic with 4D capabilities
- **Game Manager**: `scripts/game_manager.gd` - Simulation logic and company management
- **World Map**: `scripts/world_map.gd` - UI updates and visualization
- **Exponential Growth**: Matches the AI 2027 scenario's exponential capability growth

The system accurately represents the exponential AI capability growth described in the AI 2027 scenario, where companies like OpenBrain and DeepCent race to develop increasingly powerful AI systems with growing GPU resources and capabilities.
