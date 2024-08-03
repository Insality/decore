# Components

## Create new component

The all components with all default values should be declared in the `components` data structure in the `components.json` file.

```json
{
	"pack_id": "core",
	"components": {
		"transform": {
			"position_x": 0,
			"position_y": 0,
			"position_z": 0,
			"scale_x": 1,
			"scale_y": 1,
			"scale_z": 1,
		},
	}
}
```

When it's done, you can create a new component with `decore.create_component`

```lua
local transform = decore.create_component("transform")

print(transform.position_x) -- 0
print(transform.scale_x) -- 1
```

Usually, you don't create components directly, but you create entities with components.

When you create a new entity, all components with default values will be created. Then all entities components will be updated with the values from the `entities` data structure in the `entities.json` file.

```json
{
	"pack_id": "core",
	"entities": {
		"player": {
			"transform": {"position_x": 100, "position_y": 100},
		},
	}
}
```

```lua
local player = decore.create_entity("player")

print(player.transform.position_x) -- 100
print(player.transform.position_y) -- 100
print(player.transform.scale_x) -- 1
print(player.transform.scale_y) -- 1
```
