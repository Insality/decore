# Project Structure

Decore Assistant can create all of this structure automatically

## Systems

- /system/systems.lua
Contains all used in game systems

### System

All sytems placed in /systems/{SYSTEM_NAME} folder

System structure:
- system_{system_name}.lua - System file
- command_{system_name}.lua - Commands to interact with the system outside via world
- test_{system_name}.lua - Test file to test the system, should be runned from test bootstrap (/test/test.collection)
- entity_{system_name}.lua - Entity definition if needed for the system
- /test/test_{system_name}.collection - Collection to run in as a bootstrap to run the system
- /test/test_{system_name}.gui - Gui to test system.
- /test/test_{system_name}.gui_script - Gui script to test system


## Entities

- /entity/entities.lua
Contains all used in game entities

### Entity

All entities placed in /entity/{ENTITY_NAME} folder

Entity GO/Collection structure:
- entity_{entity_name}.lua - Entity file
- {entity_name}_panthera.lua - Panthera file if exists
- {entity_name}.collection - Collection file to spawn (or *.go file)
- system_{entity_name}.lua - System file to control entity if it's relative only to entity
- command_{entity_name}.lua - System file to control entity if it's relative only to entity
- test_{entity_name}.lua - Test file to test the system entity, should be runned from test bootstrap (/test/test.collection)
- /test/test_{entity_name}.collection - Collection to run in as a bootstrap to run the entity
- /test/test_{entity_name}.script - Script to test entity

Entity GUI/Widget structure:
- {entity_name}.lua - Druid Widget
- {entity_name}.gui - Gui file
- system_{entity_name}.lua - System file to control entity if it's relative only to entity
- /test/test_{entity_name}.collection - Collection to run in as a bootstrap to run the entity
- /test/test_{entity_name}.gui - Gui to test entity
- /test/test_{entity_name}.gui_script - Gui script to test entity
