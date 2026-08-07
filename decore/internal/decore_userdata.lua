---Copying of mutable Defold userdata.
---vmath values are userdata and not tables, so without help they would be shared between
---entities like scalars: one vector3 for every instance of a prefab.
---Immutable userdata (hash, url) and types without a copy constructor (vmath.vector,
---native extension types) are absent here on purpose and stay shared by reference.

local M = {}

---@type { is: fun(value: any): boolean, copy: fun(value: any): any }[]
local COPIERS = {}

-- `types` and `vmath` are Defold globals, so outside the engine there is nothing to copy
if types and vmath then
	-- Ordered by how often the type shows up in component data
	COPIERS = {
		{ is = types.is_vector3, copy = vmath.vector3 },
		{ is = types.is_quat, copy = vmath.quat },
		{ is = types.is_vector4, copy = vmath.vector4 },
		{ is = types.is_matrix4, copy = vmath.matrix4 },
	}
end


---Return a private copy of mutable Defold userdata, or the value itself when it is safe
---to share. Call only with values already known to be userdata.
---@param value any
---@return any
function M.copy(value)
	for index = 1, #COPIERS do
		local copier = COPIERS[index]
		if copier.is(value) then
			return copier.copy(value)
		end
	end

	return value
end


return M
