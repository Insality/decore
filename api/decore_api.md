# decore API

> at decore/decore.lua

## Functions

- [new_world](#new_world)
- [on_message](#on_message)
- [system](#system)
- [processing_system](#processing_system)
- [sorted_system](#sorted_system)
- [sorted_processing_system](#sorted_processing_system)
- [register_entity](#register_entity)
- [register_entities](#register_entities)
- [unregister_entities](#unregister_entities)
- [create](#create)
- [create_prefab](#create_prefab)
- [register_component](#register_component)
- [register_components](#register_components)
- [unregister_components](#unregister_components)
- [create_component](#create_component)
- [apply_component](#apply_component)
- [apply_components](#apply_components)
- [get_entity_by_id](#get_entity_by_id)
- [find_entities](#find_entities)
- [print_loaded_packs_debug_info](#print_loaded_packs_debug_info)
- [print_loaded_systems_debug_info](#print_loaded_systems_debug_info)
- [set_logger](#set_logger)
- [get_logger](#get_logger)
- [render_properties_panel](#render_properties_panel)

## Fields

- [clamp](#clamp)
- [ecs](#ecs)



### new_world

---
```lua
decore.new_world(...)
```

Create a new world instance

- **Parameters:**
	- `...` *(...)*: vararg

- **Returns:**
	- `` *(world)*:

### on_message

---
```lua
decore.on_message(world, message_id, [message], [sender])
```

Add window event to the world event bus

- **Parameters:**
	- `world` *(world)*:  command_velocity.lua
	- `message_id` *(hash)*:
	- `[message]` *(table|nil)*:
	- `[sender]` *(url|nil)*:

### system

---
```lua
decore.system(system_module, system_id, [require_all_filters])
```

- **Parameters:**
	- `system_module` *(<T>)*: The module with system functions
	- `system_id` *(string)*: The system id
	- `[require_all_filters]` *(string|string[]|nil)*: The required components. Example: {"transform", "game_object"} or "transform". If nil - system will contain no entities

- **Returns:**
	- `` *(<T>)*:

### processing_system

---
```lua
decore.processing_system(system_module, system_id, [require_all_filters])
```

- **Parameters:**
	- `system_module` *(<T>)*: The module with system functions
	- `system_id` *(string)*: The system id
	- `[require_all_filters]` *(string|string[]|nil)*: The required components. Example: {"transform", "game_object"} or "transform"

- **Returns:**
	- `` *(<T>)*:

### sorted_system

---
```lua
decore.sorted_system(system_module, system_id, [require_all_filters])
```

- **Parameters:**
	- `system_module` *(<T>)*: The module with system functions
	- `system_id` *(string)*: The system id
	- `[require_all_filters]` *(string|string[]|nil)*: The required components. Example: {"transform", "game_object"} or "transform"

- **Returns:**
	- `` *(<T>)*:

### sorted_processing_system

---
```lua
decore.sorted_processing_system(system_module, system_id, [require_all_filters])
```

- **Parameters:**
	- `system_module` *(<T>)*: The module with system functions
	- `system_id` *(string)*: The system id
	- `[require_all_filters]` *(string|string[]|nil)*: The required components. Example: {"transform", "game_object"} or "transform"

- **Returns:**
	- `` *(<T>)*:

### register_entity

---
```lua
decore.register_entity(entity_id, entity_data, [pack_id])
```

Register entity to create it with `create_prefab` function

- **Parameters:**
	- `entity_id` *(string)*:
	- `entity_data` *(table)*:
	- `[pack_id]` *(string|nil)*: default "decore"

### register_entities

---
```lua
decore.register_entities(pack_id, entities)
```

Add entities pack to decore entities
If entities pack with same id already loaded, do nothing.
If the same id is used in different packs, the last one will be used in `create_prefab` function

- **Parameters:**
	- `pack_id` *(string)*:
	- `entities` *(table<string, table>)*:

### unregister_entities

---
```lua
decore.unregister_entities(pack_id)
```

Unload entities pack from decore entities

- **Parameters:**
	- `pack_id` *(string)*:

### create

---
```lua
decore.create([components])
```

Create new entity instance

- **Parameters:**
	- `[components]` *(table<string, any>)*:

- **Returns:**
	- `` *(entity)*:

### create_prefab

---
```lua
decore.create_prefab([prefab_id], [pack_id], [components])
```

Create new entity instance from prefab

- **Parameters:**
	- `[prefab_id]` *(string|hash|nil)*:
	- `[pack_id]` *(string|nil)*:
	- `[components]` *(table<string, any>|nil)*: additional components to merge with prefab

- **Returns:**
	- `` *(entity)*:

### register_component

---
```lua
decore.register_component(component_id, [component_data], [pack_id])
```

Register component to decore components

- **Parameters:**
	- `component_id` *(string)*:
	- `[component_data]` *(any)*:
	- `[pack_id]` *(string|nil)*: default "decore"

### register_components

---
```lua
decore.register_components(components_data)
```

Register components pack to decore components

- **Parameters:**
	- `components_data` *(decore.components_pack_data)*:  JSON file scheme for components data

- **Returns:**
	- `` *(boolean)*:

### unregister_components

---
```lua
decore.unregister_components(pack_id)
```

Unload components pack from decore components

- **Parameters:**
	- `pack_id` *(string)*:

### create_component

---
```lua
decore.create_component(component_id, [component_pack_id])
```

Return new component instance from prefab

- **Parameters:**
	- `component_id` *(string)*:
	- `[component_pack_id]` *(string|nil)*: if nil, use first found from latest loaded pack

- **Returns:**
	- `return` *(any)*: nil if component not found. False can be returned as a component value (check on nil instead of not)

### apply_component

---
```lua
decore.apply_component(entity, component_id, [component_data])
```

Add component to entity.
If component not exists, it will be created with default values
If component already exists, it will be merged with the new data
To refresh system filters, call world:addEntity(entity) after this function

- **Parameters:**
	- `entity` *(entity)*:
	- `component_id` *(string)*:
	- `[component_data]` *(any)*: if nil, create component with default values

- **Returns:**
	- `` *(entity)*:

### apply_components

---
```lua
decore.apply_components(entity, [components])
```

Add components to entity
To refresh system filters, call world:addEntity(entity) after this function

- **Parameters:**
	- `entity` *(entity)*:
	- `[components]` *(table<string, any>|nil)*:

- **Returns:**
	- `` *(entity)*:

### get_entity_by_id

---
```lua
decore.get_entity_by_id(world, id)
```

- **Parameters:**
	- `world` *(world)*:  command_velocity.lua
	- `id` *(number)*:

- **Returns:**
	- `` *(entity|nil)*:

### find_entities

---
```lua
decore.find_entities(world, component_id, [component_value])
```

Return all entities with component_id equal to component_value or all entities with component_id if component_value is nil.
It looks for component_id in entity and entityToChange tables

- **Parameters:**
	- `world` *(world)*:  command_velocity.lua
	- `component_id` *(string)*:
	- `[component_value]` *(any)*: if nil, return all entities with component_id

- **Returns:**
	- `` *(entity[])*:

### print_loaded_packs_debug_info

---
```lua
decore.print_loaded_packs_debug_info()
```

Log all loaded packs for entities, components and worlds

### print_loaded_systems_debug_info

---
```lua
decore.print_loaded_systems_debug_info(world)
```

Log all loaded systems

- **Parameters:**
	- `world` *(world)*:  command_velocity.lua

### set_logger

---
```lua
decore.set_logger([logger_instance])
```

- **Parameters:**
	- `[logger_instance]` *(table|decore.logger|nil)*:

### get_logger

---
```lua
decore.get_logger([name], [level])
```

- **Parameters:**
	- `[name]` *(string?)*:
	- `[level]` *(string|nil)*:

- **Returns:**
	- `` *(decore.logger)*:

### render_properties_panel

---
```lua
decore.render_properties_panel(world, druid, properties_panel)
```

- **Parameters:**
	- `world` *(world)*:  command_velocity.lua
	- `druid` *(druid.instance)*:
	- `properties_panel` *(druid.widget.properties_panel)*:


## Fields
<a name="clamp"></a>
- **clamp** (_function_)

<a name="ecs"></a>
- **ecs** (_tiny_ecs_)

