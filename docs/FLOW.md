# Описание
Работаем по флоу
"хочу что-то добавить", ищу как это сделать тут
Если этого нет, дописываю.

# ECS

## Entities

## Systems

### Add new system
- Create a folder with system name in yout systems folder
- Copy a one of the system type ("template_system", "template_system..command or "template_system_event") to your folder
- Replace all TEMPLATE with your system name
- Register your system in game.script

### I want to add new entity

# Tiled

## Add new entity
- Prepare image for tiled placement, add in /tileset/images folder
- Open tiled tileset
- Press "plus", select icon, select image
- Add required components (`game_object`), transform is not required (autofilled)
- Add entity_id (prefab_id) in tileset class field
- Save project (export should me done automatically)

## My entity image have a offset
If your defold image matches not in center, you can adjust the offset in the tiled tilesets
- Open corresponding entity in tileset
- Open Tile Collision Editor
- Place Point object at new center of the image
-- Detiled uses first point object to calculate offset

## I want change the Z position of Tiled Layer
- Select layer
- Add custom number property "position_z" to layer
- This property will be used as Z position of the layer

# Hints & Solutions

## Tiled

### I want to draw pixel at object area
- Add entity add tiled with pixel image
- Place in level and resize as required
- Add this pixel.collection image as game object in assets
- Add this pixel.collection to spawner.collection
- Use factory_url of this pixel

## Game

### I want to add main game input system
- Add something like "system" tiled layer
- Add object (point) with name (only visual thing) and class name (prefab_id), ex "game_input"
- Open game entities.json, add new entity with prefab_id "game_input"
- Add "input" component and "game_input" component
- Make "game_input" system

### I want to add some logic to game
- Think about which system can make it and which data it requires
- Add component in tiled with default data
- Add components to objects or on new object
- Add new system

### I want to animate my object with panthera
- Add panthera component to the entity with animation path

## GUI

### I want to add new gui
- Create gui, gui_script, collection
- Add this collection to spawner as object
- Add entity in entities.json, add component to components.json
- Add new object element with class with name of prefab_id


### Create GUI
To pass data and callbacks between system and GUI we need to make a "gui bindings"

```lua
local bindings = require("gui.bindings")

-- GUI
function init(self)
	-- Store at game object key
	self.bindings = bindings.set({
		on_play_button = event.create(),
		set_color = event.create(),
	})
end

-- System
local bindings = require("gui.bindings")

---@param entity entity.gui
function M:onAdd(entity)
	-- Get bindings for current game object
	local bindings = bindings.get(entity.game_object.root)
	bindings.on_play_button:subscribe(self.on_play_button, self)

	bindings.set_color:trigger("red")
end
```
