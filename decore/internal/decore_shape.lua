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

---@type table<table, boolean> prefab_token -> true when opted out of caching
local opted_out = {}


---Return a token for "base plus this one new component key".
---Returns nil when caching is disabled, base is nil, opted out, or depth exceeded.
---@param base any|nil
---@param component_id string
---@return any|nil
function M.derive(base, component_id)
	if not M.enabled or not base or opted_out[base] then
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


---Opt a prefab token out of shape caching (and clear its derived entries).
---@param prefab_token table
function M.opt_out(prefab_token)
	opted_out[prefab_token] = true
end


---Allow a previously opted-out prefab token again.
---@param prefab_token table
function M.opt_in(prefab_token)
	opted_out[prefab_token] = nil
end


---@param prefab_token table
---@return boolean
function M.is_opted_out(prefab_token)
	return opted_out[prefab_token] == true
end


---Clear all derived tokens and opt-outs. Call when prefab/component packs change.
function M.clear()
	derived = {}
	depth = {}
	depth[M.EMPTY] = 0
	opted_out = {}
end


---Return a usable shape token for a prefab table, or nil if caching disabled / opted out.
---@param prefab table|nil
---@return any|nil
function M.token_for_prefab(prefab)
	if not M.enabled or not prefab or opted_out[prefab] then
		return nil
	end
	if not depth[prefab] then
		depth[prefab] = 0
	end
	return prefab
end


return M
