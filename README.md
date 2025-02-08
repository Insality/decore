![](media/logo.png)

[![GitHub release (latest by date)](https://img.shields.io/github/v/tag/insality/decore?style=for-the-badge&label=Release)](https://github.com/Insality/decore/tags)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/insality/decore/ci_workflow.yml?style=for-the-badge)](https://github.com/Insality/decore/actions)
[![codecov](https://img.shields.io/codecov/c/github/Insality/decore?style=for-the-badge)](https://codecov.io/gh/Insality/decore)

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)


# Disclaimer

The library in development stage. May be not fully tested and README may be not full. If you have any questions, please, create an issue.


# Decore

**Decore** - a Defold library for managing ECS game entities and components in a data-driven way. It provides functionality for creating and managing game entities with their components.

## Features

* **Entity Management**: Create and manage game entities
* **Component Management**: Add, remove and update entity components
* **Easy Integration**: Simple setup and integration with Defold projects

## Installation

Add in your `game.project` dependencies:
```
https://github.com/Insality/decore/archive/refs/tags/1.zip
```

## Basic Usage

Here's a basic example of how to use the Decore library:

```lua
local decore = require("decore.decore")

function init(self)
    -- Create a new entity
    local entity = decore.create_entity("player")

    -- Add a component to the entity
    local movement = decore.create_component("movement")
    decore.apply_component(entity, "movement", movement)
end
```

## Quick API Reference

```lua
-- Entity Management
decore.create_entity(prefab_id)
decore.get_entity_by_id(world, id)
decore.get_entities_with_name(world, entity_name)
decore.get_entities_by_prefab_id(world, prefab_id)

-- Component Management
decore.create_component(component_id)
decore.apply_component(entity, component_id, component_data)
decore.apply_components(entity, components)
```

## Game Example

Look at [Shooting Circles](https://github.com/Insality/shooting_circles) game example to see how to use the Decore library in a real game project.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Issues and suggestions

If you have any issues, questions or suggestions please [create an issue](https://github.com/Insality/decore/issues).

## ❤️ Support project ❤️

Your donation helps me stay engaged in creating valuable projects for **Defold**. If you appreciate what I'm doing, please consider supporting me!

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)
