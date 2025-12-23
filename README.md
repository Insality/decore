![](media/logo.png)

[![GitHub release (latest by date)](https://img.shields.io/github/v/tag/insality/decore?style=for-the-badge&label=Release)](https://github.com/Insality/decore/tags)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/insality/decore/ci_workflow.yml?style=for-the-badge)](https://github.com/Insality/decore/actions)
[![codecov](https://img.shields.io/codecov/c/github/Insality/decore?style=for-the-badge)](https://codecov.io/gh/Insality/decore)

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)


# Decore

**Decore** - a Defold library for managing ECS game entities and components in a data-driven way. The ECS is based on [tiny ECS](https://github.com/bakpakin/tiny-ecs) library.

The API of Tiny ECS is unchanged, so you can get familiar with it first and then use Decore. Decore provides an architecture for your game with additional features, tools and examples.

## Features

* **Entity Management**: Register, create and manage game entities
* **Component Management**: Add, remove and update entity components
* **Easy Integration**: Simple setup and integration with Defold projects

## Setup

Add in your `game.project` dependencies:
```
https://github.com/Insality/decore/archive/refs/tags/3.zip
```

### Library Size

> **Note:** The library size is calculated based on the build report per platform

| Platform         | Library Size |
| ---------------- | ------------ |
| HTML5            | **11.86 KB**  |
| Desktop / Mobile | **19.17 KB**  |


### Basic Usage

```lua
local decore = require("decore.decore")

function init(self)
	local world = decore.new_world(
		require("system.input.system_input").create(),
		require("system.transform.system_transform").create(),
		require("system.game_object.system_game_object").create(),
	)

	decore.register_entities("game", {
		["player"] = require("entity.player.player_entity")
	})

	world:addEntity(decore.create_prefab("player"))
end

function update(self, dt)
	self.world:update(dt)
end

function on_input(self, action_id, action)
	-- Systems can be accessed via world, if registered
	-- Example: https://github.com/Insality/asset-store/blob/main/system/Insality/input/input_command.lua
	return self.world.input:on_input(action_id, action)
end

function final(self)
	self.world:clearEntities()
	self.world:clearSystems()
end
```

## Examples
Look at next examples to get more information about how to use the library:
- [System examples](https://github.com/Insality/asset-store/tree/main/system/Insality) - System examples
- [Entity example](https://github.com/Insality/cosmic-dash-jam-2025/blob/main/entity/player/player_entity.lua) - Entity example
- [Shooting Circles](https://github.com/Insality/shooting_circles) - Game Example
- [Cosmic Dash](https://github.com/Insality/cosmic-dash-jam-2025) - Game Example


## Quick API Reference

```lua
local decore = require("decore.decore")

-- Create new world instance
decore.new_world(...)

-- Create new system instance
decore.system(system_module, system_id, [require_all_filters])
decore.processing_system(system_module, system_id, [require_all_filters])
decore.sorted_system(system_module, system_id, [require_all_filters])
decore.sorted_processing_system(system_module, system_id, [require_all_filters])

-- Register entity to create it with `create_prefab` function
decore.register_entity(entity_id, entity_data, [pack_id])
decore.register_entities(pack_id, entities)
decore.unregister_entities(pack_id)

-- Create new entity instance
decore.create([components])
decore.create_prefab([prefab_id], [pack_id], [components])

-- Register component to decore components
decore.register_component(component_id, [component_data], [pack_id])
decore.register_components(components_data)
decore.unregister_components(pack_id)

-- Create new component instance
decore.create_component(component_id, [component_pack_id])
decore.apply_component(entity, component_id, [component_data])
decore.apply_components(entity, [components])

-- Find entities
decore.find_entities(world, component_id, [component_value])

-- Debug functions
decore.print_loaded_packs_debug_info()
decore.print_loaded_systems_debug_info(world)

-- Logging
decore.set_logger([logger_instance])
decore.get_logger([name], [level])
```

## Use Cases

Read the [Use Cases](USE_CASES.md) file to see several examples of how to use the this module in your Defold game development projects.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Issues and suggestions

If you have any issues, questions or suggestions please [create an issue](https://github.com/Insality/decore/issues).

## Changelog

<details>

### **V1**
	- Initial release

### **V2**
	- Reworked API and internal structure
	- Updated documentation

### **V3**
	- Updated event bus system for better performance
	- Update documentation

</details>

## ❤️ Support project ❤️

Your donation helps me stay engaged in creating valuable projects for **Defold**. If you appreciate what I'm doing, please consider supporting me!

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)
