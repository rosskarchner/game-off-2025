# Game Off 2025 - Agent Development Guide

## Project Overview

**Game Off 2025** is an arcade-style action game built in Godot 4.5 inspired by the classic arcade game Joust. The player controls a flying character that uses flapping mechanics to navigate and engage in physics-based combat ("bonking") against enemy mobs.

### Game Concepts

- **Core Mechanic**: Arcade Joust-style flapping gameplay where the player controls flight through timed flaps
- **Combat**: Physics-based "bonking" system where collisions determine combat outcomes
- **World**: Procedurally generated map segments that stream infinitely as the player progresses
- **Enemies**: Various mob types (birds/gulls) with distinct behaviors and stats
- **Art**: Hand-crafted pixel art in the `art/` directory

## Project Structure

```
game-off-2025/
├── scenes/                          # Main game scenes and scripts
│   ├── player.gd                   # Player character controller (Joust-style movement)
│   ├── player.tscn                 # Player scene
│   ├── world.gd                    # World/level manager
│   ├── world.tscn                  # Main world scene
│   ├── mob.gd                      # Enemy mob behavior
│   ├── mob.tscn                    # Mob scene
│   ├── map_segment.gd              # Procedural map segment logic
│   ├── map_segment.tscn            # Map segment scene
│   ├── moving_gap.gd/tscn          # Hazardous gap obstacle
│   ├── wrapping_controller.gd      # Screen wrapping mechanics
│   └── layouts/                    # Map segment layouts
├── resources/                       # Game resources
│   ├── mob_definitions/            # Individual mob definition files
│   └── mob_definition.gd           # Mob definition class
├── art/                            # Pixel art assets
│   └── [various sprite sheets]
├── addons/                         # Godot plugins
│   └── mcp_server/                 # MCP server plugin (symlinked)
├── mob_definition_autoload.gd      # Generates mob definitions on startup
├── project.godot                   # Godot project configuration
└── README.md                       # Project documentation

```

## Technology Stack

- **Engine**: Godot 4.5
- **Scripting Language**: GDScript 2.0
- **Physics**: Godot's built-in 2D physics (CharacterBody2D, Area2D)
- **Input**: Godot's input action system (configurable via project.godot)
- **AI/Debugging**: MCP Server plugin for Claude integration

## Key Game Systems

### Player Movement (`scenes/player.gd`)

- **Flapping**: Space key triggers upward thrust with cooldown
- **Gravity**: Applies scaled gravity with terminal velocity
- **Horizontal Movement**: Smooth acceleration/deceleration with different ground/air physics
- **Ground Detection**: Uses RayCast2D to detect ground state
- **Animation**: State machine based on grounded/airborne and moving/still

### Mob System (`scenes/mob.gd`, `mob_definition_autoload.gd`)

- **Mob Definitions**: Data-driven mob types with configurable stats
- **Properties**: Max health, speed, flap strength, sprite variants
- **Behavior**: AI controls movement and flapping
- **Spawning**: Mobs generated from definition resources

### Map Generation (`scenes/map_segment.gd`, `scenes/world.gd`)

- **Procedural Segments**: World composed of stacked map segments
- **Layouts**: Pre-designed or procedural segment layouts
- **Streaming**: Segments load/unload as player progresses
- **Obstacles**: Moving gaps and hazards within segments

### Physics Layers

The project uses Godot's collision layer system:

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | STATIC | Static scenery, walls, platforms |
| 2 | PLAYER_PHYSICS | Player collision body |
| 3 | PLAYER_DETECTZONE | Player detection areas |
| 4 | MOB_PHYSICS | Enemy collision bodies |
| 5 | MOB_DETECTZONE | Enemy detection areas |
| 6 | MobBonkedArea | Area for mobs being hit |
| 7 | PlayerBonkingArea | Area for player attacking |
| 8 | PlayerBonkedArea | Area for player being hit |
| 9 | MobBonkingArea | Area for mobs attacking |

## Working with MCP Tools and Skills

### Available Godot MCP Tools

The project is configured with access to several MCP tools for development. Common tools include:

#### Scene Management
- `godot_scene_get_info()` - Get metadata about the current scene
- `godot_scene_get_tree()` - Retrieve the complete node tree
- `godot_scene_save()` - Save scene changes to disk
- `godot_scene_open()` - Switch to a different scene

#### Node Operations
- `godot_node_get_info()` - Inspect a specific node
- `godot_node_list_properties()` - See available properties on a node
- `godot_node_set_property()` - Modify node properties
- `godot_node_create()` - Add new nodes to the scene
- `godot_node_delete()` - Remove nodes
- `godot_node_rename()` - Rename nodes

#### Script Management
- `godot_script_get_from_node()` - Check which script is attached to a node
- `godot_script_attach_to_node()` - Attach/detach scripts
- `godot_script_read_source()` - Read GDScript file contents

#### Project Exploration
- `godot_project_list_files()` - Find files in the project
- `godot_project_get_setting()` - Read project settings
- `godot_project_set_setting()` - Modify project settings
- `godot_input_list_actions()` - See configured input actions

#### Resource Management
- `godot_resource_list_types()` - See what resources can be created
- `godot_resource_list_files()` - Find resources in the project
- `godot_resource_get_properties()` - Inspect resource properties
- `godot_resource_set_property()` - Modify resource values
- `godot_resource_create()` - Create new resource files

#### Gameplay Testing
- `godot_game_play_scene()` - Start playing the current scene
- `godot_game_stop_scene()` - Stop gameplay
- `godot_game_get_screenshot()` - Capture gameplay screenshot
- `godot_input_send_action()` - Simulate player input

#### Debugging
- `godot_lsp_get_errors()` - Check for script errors
- `godot_editor_get_output()` - Read the editor output log
- `godot_dap_*` - Debug adapter tools for runtime debugging

### Available Skills

#### `developing-godot-games`

This skill provides guidance on:
- GDScript coding best practices
- Godot project organization and architecture
- Node composition patterns
- Static typing and code quality
- Game development patterns specific to Godot

**When to use**: When you need architectural advice, design reviews, or help understanding Godot patterns. Invoke with:
```
/skill-builder developing-godot-games
```

### Common Development Workflows

#### Adding a New Mob Type

1. **Read** the `mob_definition_autoload.gd` to understand the mob definition structure
2. **Modify** `mob_definition_autoload.gd` to add new definitions in the `generate_mob_definitions()` function
3. **Test** by running the game and watching mob spawn
4. **Use MCP tools**:
   - `godot_project_list_files(directory: "res://resources/mob_definitions")` to verify resources created
   - `godot_resource_get_properties(path: "res://resources/mob_definitions/my_mob.tres")` to inspect values

#### Adjusting Player Mechanics

1. **Read** `scenes/player.gd` to understand current constants
2. **Edit** physics constants (FLAP_FORCE, MAX_SPEED, GRAVITY_SCALE, etc.)
3. **Test** with:
   - `godot_game_play_scene(enable_runtime_api: true)` to start playing
   - `godot_input_send_action("ui_accept")` to simulate flaps
   - `godot_game_get_screenshot()` to see results

#### Modifying Map Segments

1. **Use** `godot_scene_open(path: "res://scenes/map_segment.tscn")` to open the scene
2. **Explore** with `godot_scene_get_tree()` to see the structure
3. **Edit** nodes with `godot_node_set_property()` or make visual changes
4. **Save** with `godot_scene_save()`

#### Finding and Fixing Errors

1. **Check** for errors: `godot_lsp_get_errors()`
2. **Read** the problematic file with standard Read tool
3. **Fix** the code with standard Edit tool
4. **Verify** errors are gone with another `godot_lsp_get_errors()` call

## Common Patterns

### Input Handling

The game uses Godot's input action system. Current actions:
- `ui_accept` - Jump/flap
- `ui_left` - Move left
- `ui_right` - Move right

Check available actions with: `godot_input_list_actions()`

### GDScript Style

The project uses:
- Type annotations: `func _ready() -> void:`
- Comments for non-obvious logic
- PascalCase for class/node names
- UPPER_CASE for constants
- Enum for named constants

### Scene Composition

Nodes are organized hierarchically:
- Root scene (World) instantiates map segments
- Map segments contain obstacles and spawn points
- Player/mobs are CharacterBody2D with Area2D children for detection

## Tips for Agents

1. **Always read before editing**: Use the Read tool to understand code before making changes
2. **Use the developing-godot-games skill**: For architecture questions or when unsure about patterns
3. **Test incrementally**: Use `godot_game_play_scene()` frequently to verify changes
4. **Check the LSP**: Run `godot_lsp_get_errors()` to catch mistakes early
5. **Explore the structure first**: Use `godot_project_list_files()` and `godot_scene_get_tree()` to understand layout
6. **Reference the physics layers**: When adding new interactive elements, check the layer configuration
7. **Use resources for data**: Leverage `mob_definition.gd` pattern for data-driven design

## Resources

- [Godot 4.5 Documentation](https://docs.godotengine.org/en/stable/)
- [GDScript Language Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- [Godot Physics](https://docs.godotengine.org/en/stable/tutorials/physics/index.html)
- Game Off 2025 - A game jam hosted by GitHub
