#include <vector>
#include <dmsdk/sdk.h>
#include <math.h>

// List of entity references in Lua registry
static std::vector<int> entities;


// Add entity to system
static int add_entity(lua_State* L) {
	// Stack: { entity }
	DM_LUA_STACK_CHECK(L, 0);

	luaL_checktype(L, 1, LUA_TTABLE);

	// Create a reference to the entity and store it
	lua_pushvalue(L, 1);
	int ref = luaL_ref(L, LUA_REGISTRYINDEX);
	entities.push_back(ref);

	return 0;
};


// Remove entity from system
static int remove_entity(lua_State* L) {
	// Stack: { entity }
	DM_LUA_STACK_CHECK(L, 0);

	luaL_checktype(L, 1, LUA_TTABLE);

	// Find and remove the entity reference
	bool found = false;
	for (auto it = entities.begin(); it != entities.end(); ++it) {
		lua_rawgeti(L, LUA_REGISTRYINDEX, *it);
		if (lua_rawequal(L, -1, 1)) {
			luaL_unref(L, LUA_REGISTRYINDEX, *it);
			entities.erase(it);
			found = true;
			lua_pop(L, 1);
			break;
		}
		lua_pop(L, 1);
	}
	if (!found) {
		dmLogWarning("Entity not found in system.");
	}

	return 0;
};


// Update entities
static int update(lua_State* L) {
	// Stack: { dt }
	DM_LUA_STACK_CHECK(L, 0);

	// Increase velocity by 1:1 for each entity
	// velocity placed in entity.velocity.x and entity.velocity.y
	for (auto it = entities.begin(); it != entities.end(); ++it) {
		lua_rawgeti(L, LUA_REGISTRYINDEX, *it); // Push entity
		lua_getfield(L, -1, "velocity");        // Push velocity

		// Update velocity.x
		lua_getfield(L, -1, "x");               // Push velocity.x
		lua_pushnumber(L, lua_tonumber(L, -1) + 1); // Push x + 1
		lua_setfield(L, -3, "x");               // Set velocity.x
		lua_pop(L, 1);                          // Pop old x

		// Update velocity.y
		lua_getfield(L, -1, "y");               // Push velocity.y
		lua_pushnumber(L, lua_tonumber(L, -1) + 1); // Push y + 1
		lua_setfield(L, -3, "y");               // Set velocity.y
		lua_pop(L, 1);                          // Pop old y

		lua_pop(L, 2); // Pop velocity and entity
	}

	return 0;
}


// Functions exposed to Lua
static const luaL_Reg Module_methods[] = {
	{"add_entity", add_entity},
	{"remove_entity", remove_entity},
	{"update", update},
	{0, 0}
};


static dmExtension::Result Initialize(dmExtension::Params* params) {
	lua_State* L = params->m_L;
	int top = lua_gettop(L);

	luaL_register(L, "c_system_boid", Module_methods);
	lua_pop(L, 1);

	assert(top == lua_gettop(L));
	return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(c_system_boid, "c_system_boid", 0, 0, Initialize, 0, 0, 0)
