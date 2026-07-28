---Shape tokens for ECS system-membership cache.
---A token identifies the set of component keys on an entity.
---The prefab table itself is the base token; derive() builds derived tokens
---when apply_component introduces a new key.

local M = {}

---Global kill switch. When false, entities get no __shape and ECS falls back to full scan.
M.enabled = true

---Token for a prefab-less entity with no components yet.
M.EMPTY = {}

---Max derive depth before returning nil (uncached). Protects against
---pathological create() with many keys where pairs order varies.
local MAX_DERIVE_DEPTH = 8

---@type table<table, table<string, table>> base_token -> component_id -> derived_token
local derived = {}

---@type table<table, number> token -> derivation depth from a prefab/EMPTY root
local depth = {}
depth[M.EMPTY] = 0


---Return a token for "base plus this one new component key".
---Returns nil when caching is disabled, base is nil, or depth exceeded.
---@param base any|nil
---@param component_id string
---@return any|nil
function M.derive(base, component_id)
	if not M.enabled or not base then
		return nil
	end

	local d = depth[base] or 0
	if d >= MAX_DERIVE_DEPTH then
		return nil
	end

	local by_component = derived[base]
	if not by_component then
		by_component = {}
		derived[base] = by_component
	end

	local token = by_component[component_id]
	if token then
		return token
	end

	token = { base = base, key = component_id }
	by_component[component_id] = token
	depth[token] = d + 1
	return token
end


---Clear all derived tokens. Call when prefab/component packs change.
function M.clear()
	derived = {}
	depth = {}
	depth[M.EMPTY] = 0
end


---Return a usable shape token for a prefab table, or nil if caching disabled.
---@param prefab table|nil
---@return any|nil
function M.token_for_prefab(prefab)
	if not M.enabled or not prefab then
		return nil
	end
	if not depth[prefab] then
		depth[prefab] = 0
	end
	return prefab
end


return M
