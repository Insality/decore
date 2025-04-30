# decore API

> at /decore/decore.lua

## Functions

- [world](#world)
- [system](#system)
- [processing_system](#processing_system)
- [sorted_system](#sorted_system)
- [sorted_processing_system](#sorted_processing_system)
- [on_input](#on_input)
- [on_message](#on_message)
- [final](#final)
- [register_entity](#register_entity)
- [register_entities](#register_entities)
- [unregister_entities](#unregister_entities)
- [create_entity](#create_entity)
- [register_component](#register_component)
- [register_components](#register_components)
- [unregister_components](#unregister_components)
- [create_component](#create_component)
- [apply_component](#apply_component)
- [apply_components](#apply_components)
- [get_entity_by_id](#get_entity_by_id)
- [find_entities_by_component_value](#find_entities_by_component_value)
- [is_alive](#is_alive)
- [print_loaded_packs_debug_info](#print_loaded_packs_debug_info)
- [print_loaded_systems_debug_info](#print_loaded_systems_debug_info)
- [parse_command](#parse_command)
- [call_command](#call_command)
- [set_logger](#set_logger)
- [get_logger](#get_logger)

## Fields

- [clamp](#clamp)
- [ecs](#ecs)
- [last_world](#last_world)
- [logger](#logger)



### world

---
```lua
decore.world(...)
```

Create a new world instance

- **Parameters:**
	- `...` *(...)*: vararg

- **Returns:**
	- `` *(world)*:

### system

---
```lua
decore.system(system_module, system_id, [require_all_filters])
```

- **Parameters:**
	- `system_module` *(<T>)*: The module with system functions
	- `system_id` *(string)*: The system id
	- `[require_all_filters]` *(string|string[]|nil)*: The required components. Example: {"transform", "game_object"} or "transform"

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

### on_input

---
```lua
decore.on_input(world, action_id, action)
```

Add input event to the world queue

- **Parameters:**
	- `world` *(world)*:  command_velocity.lua
	- `action_id` *(hash)*:
	- `action` *(action)*:  This one should be a part of Defold annotations

- **Returns:**
	- `` *(boolean)*:

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

### final

---
```lua
decore.final([world])
```

- **Parameters:**
	- `[world]` *(any)*:

### register_entity

---
```lua
decore.register_entity(entity_id, entity_data, [pack_id])
```

Register entity to decore entities

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
If the same id is used in different packs, the last one will be used in M.create_entity

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

### create_entity

---
```lua
decore.create_entity([prefab_id], [pack_id], [data])
```

Create entity instance from prefab

- **Parameters:**
	- `[prefab_id]` *(string|hash|nil)*:
	- `[pack_id]` *(string|nil)*:
	- `[data]` *(table|nil)*: additional data to merge with prefab

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
decore.register_components(components_data_or_path)
```

Register components pack to decore components

- **Parameters:**
	- `components_data_or_path` *(string|decore.components_pack_data)*: if string, load data from JSON file from custom resources

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

### find_entities_by_component_value

---
```lua
decore.find_entities_by_component_value(world, component_id, [component_value])
```

Return all entities with component_id equal to component_value or all entities with component_id if component_value is nil.
It looks for component_id in entity and entityToChange tables

- **Parameters:**
	- `world` *(world)*:  command_velocity.lua
	- `component_id` *(string)*:
	- `[component_value]` *(any)*: if nil, return all entities with component_id

- **Returns:**
	- `` *(entity[])*:

### is_alive

---
```lua
decore.is_alive(world_or_system, entity)
```

Return if entity is alive in the system

- **Parameters:**
	- `world_or_system` *(system|world)*: If world, return if entity is alive in the world, if system, return if entity is alive in the system
	- `entity` *(entity)*: The entity to check

- **Returns:**
	- `is_alive` *(boolean)*: Is entity exists in the system or in the world

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

### parse_command

---
```lua
decore.parse_command(command)
```

Grab a command in text format to provide a way to call functions from the system

- **Parameters:**
	- `command` *(string)*: Example: "system_name.function_name, arg1, arg2". Separators can be: " ", "," and "\n"

- **Returns:**
	- `` *(any[])*:

### call_command

---
```lua
decore.call_command(world, [command])
```

Call command from params array. Example: {"system_name", "function_name", "arg1", "arg2", ...}

- **Parameters:**
	- `world` *(world)*:  command_velocity.lua
	- `[command]` *(any[])*: Example: [ "command_debug", "toggle_profiler", true ],

### set_logger

---
```lua
decore.set_logger([logger_instance])
```

- **Parameters:**
	- `[logger_instance]` *(table|decore.logger|nil)*: Logger interface

### get_logger

---
```lua
decore.get_logger(name, [level])
```

- **Parameters:**
	- `name` *(string)*:
	- `[level]` *(string|nil)*:

- **Returns:**
	- `` *(decore.logger)*:


## Fields
<a name="clamp"></a>
- **clamp** (_function_)

<a name="ecs"></a>
- **ecs** (_table_)

<a name="last_world"></a>
- **last_world** (_nil_):  command_velocity.lua

<a name="logger"></a>
- **logger** (_decore.logger_): Logger interface

