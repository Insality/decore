# Introduction to Decore

Decore is a data-driven layer for Defold on top of [tiny-ecs](https://github.com/bakpakin/tiny-ecs).
You describe **prefabs** (component tables), write **systems** that own rules, and drive the frame with `world:update(dt)`.

This page is the mental model. For the full function list see [README](README.md) and [api/decore_api.md](api/decore_api.md).

---

## Core ideas

| Concept | In Decore |
|--------|-----------|
| **World** | One ECS instance: entities, systems, `world.event` |
| **Entity** | A Lua table. Keys are component ids (`transform`, `health`, …) |
| **Component** | A value on that table (usually a subtable, sometimes a scalar) |
| **Prefab** | A registered component map you spawn with `create_prefab` |
| **System** | Code that runs each frame over a filtered set of entities |
| **Event** | Same-frame / next-`postWrap` messages via `world.event` |

Filters match on **component presence** (and reject lists), not on field values.
Prefer `decore.create_prefab` / `apply_component` / `remove_component` so shape caches stay valid.

---

## Bootstrap

Typical game script flow:

```lua
local decore = require("decore.decore")

function init(self)
	-- 1) Create world with systems — order is frame order
	--    (component defaults usually register at require time inside system modules)
	self.world = decore.new_world(
		require("system.input.input_system").create(),
		require("system.transform.transform_system").create(),
		require("system.game_object.game_object_system").create(),
		require("system.health.health_system").create()
	)

	-- 2) Register prefab packs
	decore.register_entities("game", {
		player = require("entity.player.player_entity"),
		enemy = require("entity.enemy.enemy_entity"),
	})

	-- 3) Spawn
	self.world:addEntity(decore.create_prefab("player"))
end

function update(self, dt)
	self.world:update(dt)
end

function final(self)
	self.world:clearEntities()
	self.world:clearSystems()
end
```

`decore.new_world(...)` always includes internal systems (entity id / look-ups, event queue).
Your systems are appended in the order you pass them.

Suggested load order in a real project:

1. Bootstrap script
2. `new_world` + system list
3. `register_entities` / component packs
4. Scene loads data → spawns prefabs
5. Systems talk over `world.event` and commands; visuals sync from state

---

## Prefabs (entities)

A prefab is a plain table: **component id → initial data**.

```lua
-- entity/player/player_entity.lua
return {
	transform = {
		position_x = 0,
		position_y = 0,
	},
	game_object = {
		factory_url = "/factories#player",
		is_factory = true,
	},
	health = { value = 100 },
}
```

Register and spawn:

```lua
decore.register_entities("game", {
	player = require("entity.player.player_entity"),
})

local e = decore.create_prefab("player", nil, {
	-- optional overrides merged on top
	transform = { position_x = 120, position_y = 40 },
})
world:addEntity(e)
```

Register defaults for components you invent:

```lua
decore.register_component("health", { value = 100 })
```

Usually call this from the system module that owns the component (at file load).

**Child entities:** prefabs may declare `child_instancies` (spawned by the internal Decore system). Use when a prefab owns nested instances; otherwise keep prefabs flat.

---

## Systems

Most projects use `decore.system`:

```lua
local decore = require("decore.decore")

decore.register_component("health", { value = 100 })

local M = {}

function M.create()
	-- filter: entities that have "health" (omit filter for a global system)
	return decore.system(M, "health", "health")
end

function M:onAdd(entity)
	-- entity just matched this filter
end

function M:update(dt)
	for index = 1, #self.entities do
		local entity = self.entities[index]
		-- mutate gameplay state here
	end
end

function M:postWrap()
	-- react to world.event after the main update
end

return M
```

### Lifecycle (what to implement)

| Callback | When |
|----------|------|
| `onAddToWorld` / `onRemoveFromWorld` | System enters / leaves the world |
| `onAdd` / `onRemove` / `onModify` | Entity joins / leaves / changes for this filter |
| `preWrap` → `update` → `postWrap` | Every frame (postWrap runs after all updates) |
| `late_update` | After `update` (same `world.speed` scaling) |
| `fixed_update` | Fixed step, if you use it |

### System kinds

| Factory | Use when |
|---------|----------|
| `decore.system` | Default. Custom `update`, you iterate `self.entities` |
| `decore.processing_system` | Per-entity `process(entity, dt)` instead of `update` |
| `decore.sorted_system` | Need a sorted entity list |
| `decore.sorted_processing_system` | Sorted + `process` |

In practice most game code stays on `decore.system`.

### Order

Systems run in registration order. A useful default:

**core** (input, transform, time) → **rules** (combat, AI, spawn) → **visuals** (game_object, VFX, UI sync) → **windows**

Put producers before consumers when they share the same frame’s events.

---

## Events (`world.event`)

Queued messages between systems. Prefer this over reaching into another system’s internals.

```lua
-- emit (no table alloc when data is omitted)
world.event:trigger("died", entity)
world.event:trigger("wave_start")
world.event:trigger("hit", entity, { dmg = 3 })

-- consume (usually in postWrap)
world.event:process("hit", function(entity, data)
	-- data is nil if the trigger had no payload
end, self)
-- with context: callback(self, entity, data)
```

**Lifecycle:** `trigger` writes to a stash; the internal event system promotes stash → current events in `postWrap` (it runs early because it is added first). Same-frame `postWrap` consumers can see events triggered during that frame’s `update`.

---

## Commands (recommended project pattern)

Decore does not require commands, but they scale well:

- `*_system.lua` — owns filter, state, events
- `*_command.lua` — public API; callers `require` this module

The system registers itself with the command (usually in `create()` via `command.register(self)`).
Callers use the command module only — not system refs, and not `world.some_command`.

Commands are feature entry points: they may orchestrate systems, widgets, or animations, and are not a 1:1 wrap of every system method.

---

## Suggested project layout

Decore is path-agnostic. A layout that works well for Defold games:

| Path | Role |
|------|------|
| `system/` | Shared systems + commands; one list defines frame order |
| `entity/` | Prefabs (`*_entity.lua`) and feature-local systems |
| `game/` | Scenes, balance, content data |
| `widget/` | UI only (layout, input chrome) — no gameplay spawns |

**Rules of thumb**

- Extend by **adding** modules / prefabs / registry entries, not by growing god-systems.
- Prefer data (prefab fields, tables, JSON) over special-case branches.
- Systems mutate state; visuals reflect it.
- Keep animations cancellable / trackable; store handles (on the entity if the anim belongs to one).
- UI widgets talk through events / `set_*` — they should not own combat or spawning.

---

## Lookups

```lua
local e = decore.get_entity_by_id(world, id)
local list = decore.find_entities(world, "health")
```

Prefer keeping references from spawn time or events when you can; lookups are for glue code.

---

## Minimal checklist for a new feature

1. `register_component` for any new component id
2. Prefab in `entity/<name>/<name>_entity.lua` + `register_entities`
3. System with `M.create()` → `decore.system(M, id, filter?)`
4. Add `.create()` to the world system list in the right order
5. Spawn with `world:addEntity(decore.create_prefab(...))`
6. Cross-system talk via `world.event` and/or a commands

---

## Next

- [USE_CASES.md](USE_CASES.md) — small patterns (global world module, …)
- [README.md](README.md) — setup, API summary, changelog / migrations
- Examples: [Cosmic Dash](https://github.com/Insality/cosmic-dash-jam-2025), [Shooting Circles](https://github.com/Insality/shooting_circles), [Robo Dance](https://github.com/Insality/robo-dance-jam-2026)
