![](media/logo.png)

[![GitHub release (latest by date)](https://img.shields.io/github/v/tag/insality/decore?style=for-the-badge&label=Release)](https://github.com/Insality/decore/tags)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/insality/decore/ci_workflow.yml?style=for-the-badge)](https://github.com/Insality/decore/actions)
[![codecov](https://img.shields.io/codecov/c/github/Insality/decore?style=for-the-badge)](https://codecov.io/gh/Insality/decore)

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)


# Disclaimer

The library in development stage. May be not fully tested and README may be not full. If you have any questions, please, create an issue.


# Decore

**Decore** - a Defold library for managing ECS game entities, components, and worlds in a data-driven way. It provides functionality for loading and unloading packs of entities, components, and worlds, as well as creating individual entities, components, and worlds.


## Features

* **Entity Management**: Load and unload packs of entities, and create individual entities.
* **Component Management**: Load and unload packs of components, and create individual components.
* **World Management**: Load and unload packs of worlds, and create individual worlds.


### [Dependency](https://www.defold.com/manuals/libraries/)

Open your `game.project` file and add the following line to the dependencies field under the project section:

**[Decore](https://github.com/Insality/decore/archive/refs/tags/1.zip)**

```
https://github.com/Insality/decore/archive/refs/tags/1.zip
```

After that, select `Project ▸ Fetch Libraries` to update [library dependencies]((https://defold.com/manuals/libraries/#setting-up-library-dependencies)). This happens automatically whenever you open a project so you will only need to do this if the dependencies change without re-opening the project.

### Library Size

> **Note:** The library size is calculated based on the build report per platform

| Platform         | Library Size |
| ---------------- | ------------ |
| HTML5            | **1.96 KB**  |
| Desktop / Mobile | **3.35 KB**  |

## Setup

### Defold versions

Decore requires Defold `1.6.4` or later, due the usage of json "nil" parsing.

### Loading ECS data packs

Decore can load ECS data packs from JSON files or tables. The data packs are used to define entities, components, and worlds.

```lua
local decore = require("decore.decore")

function init(self)
	decore.register_components("/resources/ecs/components.json")
	decore.register_entities("/resources/ecs/entities.json")
	decore.register_worlds("/resources/ecs/worlds.json")
end
```


### Create packs

#### Components

The components pack is a JSON file with the following structure.

- `pack_id`: The ID of the pack. Should be unique. If the pack already exists, it will be overwritten.
- `components`: A table of components. Each component has an `id` field, which is the ID of the component. And contains default data fields for the component.

```json
{
	"pack_id": "core",

	"components": {
		"id": "",
		"prefab_id": false,
		"pack_id": false,
		"name": false,

		"transform": {
			"position_x": 0,
			"position_y": 0,
			"position_z": 0,
			"size_x": 1,
			"size_y": 1,
			"size_z": 1,
			"scale_x": 1,
			"scale_y": 1,
			"scale_z": 1,
			"rotation": 0
		},

		"game_object": {
			"factory_url": ""
		},
}
```

#### Entities

The entities pack is a JSON file with the following structure.

- `pack_id`: The ID of the pack. Should be unique. If the pack already exists, it will be overwritten.
- `entities`: A table of entities. Each entity has an `id` field, which is the ID of the entity. And contains components fields for the entity. This fields will be applied to the entity, overriding the default values from the components.

```json
{
	"pack_id": "core",

	"entities": {
		"player": {
			"transform": {},
			"game_object": {
				"factory_url": "/spawner/spawner#player"
			},
			"player_movement": {}
		},
		"enemy": {
			"transform": {},
			"game_object": {
				"factory_url": "/spawner/spawner#enemy"
			},
			"enemy_movement": {}
		},
		"dot": {
			"transform": {},
			"game_object": {
				"factory_url": "/spawner/spawner#dot"
			}
		},
	}
}
```

#### Worlds

The worlds pack is a JSON file with the following structure:
- `pack_id`: The ID of the pack. Should be unique. If the pack already exists, it will be overwritten.
- `worlds`: A table of worlds. Each world has an `id` field, which is the ID of the world. And contains entities fields for the world. This fields will be added to the world.


```json
{
	"pack_id": "core",

	"worlds": {
		"grid": {
			"entities": [
				{
					"prefab_id": "dot",
					"components": {
						"transform": { "position_x": 0, "position_y": 0 }
					}
				},
				{
					"prefab_id": "dot",
					"components": {
						"transform": { "position_x": 1, "position_y": 0 }
					}
				},
				{
					"prefab_id": "dot",
					"components": {
						"transform": { "position_x": 0, "position_y": 1 }
					}
				},
				{
					"prefab_id": "dot",
					"components": {
						"transform": { "position_x": 1, "position_y": 1 }
					}
				}
			]
		},

		"main": {
			"included_worlds": [ "grid" ],
			"entities": [
				{
					"name": "player",
					"components": {
						"transform": { "position_x": 0, "position_y": 0 }
					}
				}
			]
		}
	}
}
```

## Basic Usage

Here's a basic example of how to use the Decore library:

```lua
local decore = require("decore.decore")

---@param self userdata
function init(self)
	-- Create a new ECS world
	self.world = decore.world()

	-- Load world and add entities from them to the world
	local entities = decore.load_world("main")
	for index = 1, #entities do
		self.world:addEntity(entities[index])
	end

	-- Create a new entity
	local entity = decore.create_entity("player")
	self.world:addEntity(entity)

	-- Create a component to add to the entity
	local player_movement = decore.create_component("player_movement")
	decore.apply_component(entity, "player_movement", player_movement)
	-- Refresh entity to update the system's filters
	self.world:addEntity(player_movement)
end

---@param self userdata
---@param dt number
function update(self, dt)
	self.world:update(dt)
end
```

## Game Example

Look at [Shooting Circles](https://github.com/Insality/shooting_circles) game example to see how to use the Decore library in a real game project.


## API Reference

### Quick API Reference

```lua
decore.set_logger(logger_instance)
decore.get_logger(name, level)
decore.world()
decore.register_entities(entities_data_or_path)
decore.unregister_entities(pack_id)
decore.create_entity(prefab_id, pack_id)
decore.register_component(component_id, component_data, pack_id)
decore.register_components(components_data_or_path)
decore.unregister_components(pack_id)
decore.create_component(component_id, component_pack_id)
decore.apply_component(entity, component_id, component_data)
decore.apply_components(entity, components)
decore.register_worlds(world_data_or_path)
decore.unregister_worlds(pack_id)
decore.create_world(world_id, world_pack_id)
decore.get_entity_by_id(world, id)
decore.get_entities_with_name(world, entity_name)
decore.get_entities_with_tiled_id(world, tiled_id)
decore.get_entities_by_prefab_id(world, prefab_id)
decore.find_entities_by_component_value(world, component_id, component_value)
decore.is_alive(system, entity)
decore.unload_all()
decore.print_loaded_packs_debug_info()
```

### API Reference

Read the [API Reference](API_REFERENCE.md) file to see the full API documentation for the module.


## Use Cases

Read the [Use Cases](USE_CASES.md) file to see several examples of how to use the this module in your Defold game development projects.


## License

The **tiny-ecs** lua library by `bakpakin`: https://github.com/bakpakin/tiny-ecs

This project is licensed under the MIT License - see the LICENSE file for details.


## Issues and suggestions

If you have any issues, questions or suggestions please [create an issue](https://github.com/Insality/decore/issues).


## ❤️ Support project ❤️

Your donation helps me stay engaged in creating valuable projects for **Defold**. If you appreciate what I'm doing, please consider supporting me!

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)
