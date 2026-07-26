---@diagnostic disable: undefined-field

return function()
	describe("Decore Shape", function()
		local shape
		local decore_data

		before(function()
			shape = require("decore.internal.decore_shape")
			decore_data = require("decore.internal.decore_data")
			decore_data.clear()
			shape.enabled = true
		end)

		after(function()
			shape.enabled = true
			decore_data.clear()
		end)

		it("Should return prefab itself as base token", function()
			local prefab = { health = {} }
			local token = shape.token_for_prefab(prefab)
			assert(token == prefab)
		end)

		it("Should derive stable tokens for the same key path", function()
			local base = shape.EMPTY
			local first = shape.derive(base, "a")
			local second = shape.derive(base, "a")
			assert(first ~= nil)
			assert(first == second)

			local with_b = shape.derive(first, "b")
			local with_b_again = shape.derive(first, "b")
			assert(with_b == with_b_again)
			assert(with_b ~= first)
		end)

		it("Should return nil when caching is disabled", function()
			shape.enabled = false
			assert(shape.token_for_prefab({}) == nil)
			assert(shape.derive(shape.EMPTY, "a") == nil)
		end)

		it("Should opt out and opt in prefab tokens", function()
			local prefab = { health = {} }
			shape.opt_out(prefab)
			assert(shape.is_opted_out(prefab) == true)
			assert(shape.token_for_prefab(prefab) == nil)
			assert(shape.derive(prefab, "mana") == nil)

			shape.opt_in(prefab)
			assert(shape.is_opted_out(prefab) == false)
			assert(shape.token_for_prefab(prefab) == prefab)
		end)

		it("Should stop deriving after max depth", function()
			local token = shape.EMPTY
			for index = 1, 8 do
				token = shape.derive(token, "k" .. index)
				assert(token ~= nil)
			end
			assert(shape.derive(token, "too_deep") == nil)
		end)

		it("Should clear derived tokens", function()
			local derived = shape.derive(shape.EMPTY, "clear_me")
			assert(derived ~= nil)
			shape.clear()
			local again = shape.derive(shape.EMPTY, "clear_me")
			assert(again ~= nil)
			assert(again ~= derived)
		end)
	end)
end
