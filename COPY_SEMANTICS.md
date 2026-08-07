# How values are instantiated

Decore distinguishes three kinds of values:

| Kind | Example |
| --- | --- |
| Scalar | `100`, `"player"`, `true`, `false` |
| Plain table | `{ x = 1, y = 2 }` |
| Object | `setmetatable({}, MT)` — event, promise, class instance |
| Mutable userdata | `vmath.vector3`, `vmath.vector4`, `vmath.quat`, `vmath.matrix4` |

## On spawn

`decore.create` and `decore.create_prefab` build an entity from registered data. Copying is intentionally shallow — only what you are likely to write into becomes private:

| Where the value sits | What the entity gets |
| --- | --- |
| The component itself (`entity.health`) | new table, private to the entity |
| Nested inside a component (`entity.health.range`) | **the same table by reference** as in the prefab data |
| Object — as a component or as a direct field of one | full deep copy, private to the entity |
| Mutable userdata — same positions | new value via its copy constructor, private to the entity |
| Scalar | assigned as is |

Two entities from one prefab always have separate components, but share the nested tables inside them — until something is written through the decore API.

## On override

`decore.create(components)`, `decore.create_prefab(id, pack, components)` and `decore.apply_component` merge data into the entity:

- **scalar** — assigned as is;
- **plain table** — merged field by field. Every nested table along the written path is copied first, so an override never reaches the prefab data or other entities;
- **object** — **replaces** the whole component and is taken **as is, by reference**: you still hold it and may have subscribed to it already. Fields that came from the prefab are dropped;
- if the component default is a scalar and you pass a table, the default is dropped.

```lua
decore.register_entity("orc", { health = { value = 100, armor = 5 } })

local orc = decore.create_prefab("orc", nil, { health = { value = 50 } })
-- orc.health.value == 50, orc.health.armor == 5
```

```lua
local signal = make_signal() -- any table with a metatable
signal:subscribe(on_orc_died)

local orc = decore.create_prefab("orc", nil, { death_signal = signal })
-- orc.death_signal == signal, the subscription is still on it
```

Decore copies only when it materializes a prototype — a registered component default, prefab data, a child descriptor. What you hand over at the call site is never copied.

## Objects

A table with a metatable is treated as an object: it is never merged field by field, because that would share its inner state (nested state tables, subscriber lists, ...) between entities. An object coming from a prototype is copied whole; an object you pass at the call site is taken by reference.

- the copy is deep and cycle-safe, the metatable itself is kept (shared, not copied);
- aliases inside the object survive: if the object reaches the same inner table through two fields, so does the copy — through a single copy of that table;
- identity is preserved **inside** one object only. The same object placed into two components — or into two fields — is copied twice and the copies are independent. Keep an object in one place and reach it from there.

## Rules of thumb

1. Write through `decore.apply_component`. A direct write into a nested table (`entity.health.range.max = 10`) hits data shared with the prefab and with other entities.
2. Keep component fields flat — that is both the fastest and the safest layout.
3. Do not put live objects into prefab data unless every entity really should get a copy of that exact state.

## vmath values

`vmath.vector3` and friends are userdata, not tables, so they would otherwise be shared like scalars — one vector for every entity of a prefab. Decore copies them through their own copy constructor, in the same positions where an object is copied: as a component or as a direct field of one.

The rule about sources holds here too: a vector coming from prefab data or a component default is copied per entity, a vector you pass at the call site is taken as is.

Flat numbers (`position_x`, `position_y`) are still cheaper — no allocation per spawn — but nothing breaks if you use vmath.

## Known limits

- Only mutable vmath types are copied. `hash`, `url`, `vmath.vector` (arbitrary length) and userdata from native extensions stay shared by reference — `hash` and `url` because copying them makes no sense, the rest because there is no known copy constructor for them.
- An object or a vector nested deeper than a direct field of a component belongs to a shared subtree and is shared along with it.
