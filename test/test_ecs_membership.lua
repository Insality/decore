---@diagnostic disable: undefined-field

---Tests for shape-backed system membership and dispatch-list behaviour.
return function()
	describe("ECS Membership", function()
		local decore ---@type decore
		local decore_data
		local world ---@type world

		before(function()
			decore = require("decore.decore")
			decore_data = require("decore.internal.decore_data")
			decore_data.clear()
			decore.set_logger(nil)
			decore.shape.enabled = true
			world = decore.new_world()
		end)

		after(function()
			decore.shape.enabled = true
			decore_data.clear()
		end)

		local function refresh()
			world:refresh()
			world:refresh()
		end

		local function membership_matches_filter(system)
			local expected = 0
			for index = 1, #world.entities do
				if system.filter(system, world.entities[index]) then
					expected = expected + 1
				end
			end
			return #system.entities == expected
		end

		it("Should cache shape systems for prefab entities", function()
			decore.register_component("health", { value = 100 })
			decore.register_component("mana", { value = 50 })
			decore.register_entity("mob", {
				health = { value = 100 },
				mana = { value = 50 },
			})

			local added = 0
			local system = decore.system({
				onAdd = function()
					added = added + 1
				end,
			}, "health_system", "health")
			world:addSystem(system)
			refresh()

			local a = decore.create_prefab("mob")
			local b = decore.create_prefab("mob")
			assert(a.__shape ~= nil)
			assert(a.__shape == b.__shape)

			world:addEntity(a)
			world:addEntity(b)
			refresh()

			assert(added == 2)
			assert(#system.entities == 2)
			assert(membership_matches_filter(system))
			assert(world.shapeSystems[a.__shape] ~= nil)
		end)

		it("Should refilter when component is applied and entity is re-added", function()
			decore.register_component("health", { value = 100 })
			decore.register_component("tag", { value = 1 })

			local system = decore.system({}, "tag_system", "tag")
			world:addSystem(system)
			refresh()

			local entity = decore.create({ health = {} })
			world:addEntity(entity)
			refresh()
			assert(#system.entities == 0)

			decore.apply_component(entity, "tag")
			world:addEntity(entity)
			refresh()

			assert(#system.entities == 1)
			assert(system.entities[1] == entity)
			assert(membership_matches_filter(system))
		end)

		it("Should drop membership after remove_component and re-add", function()
			decore.register_component("health", { value = 100 })

			local system = decore.system({}, "health_system", "health")
			world:addSystem(system)
			refresh()

			local entity = decore.create({ health = { value = 10 } })
			world:addEntity(entity)
			refresh()
			assert(#system.entities == 1)

			decore.remove_component(entity, "health")
			assert(entity.health == nil)
			assert(entity.__shape == nil)

			world:addEntity(entity)
			refresh()
			assert(#system.entities == 0)
			assert(membership_matches_filter(system))
		end)

		it("Should invalidate shapeSystems when systems change", function()
			decore.register_component("health", { value = 100 })
			decore.register_entity("mob", { health = { value = 1 } })

			local entity = decore.create_prefab("mob")
			world:addEntity(entity)
			refresh()

			local shape = entity.__shape
			assert(shape ~= nil)
			assert(world.shapeSystems[shape] ~= nil)

			local system = decore.system({}, "health_system", "health")
			world:addSystem(system)
			refresh()

			-- System set changed: cache is dropped and rebuilt lazily on next add
			assert(world.shapeSystems[shape] == nil)
			assert(#system.entities == 1)
			assert(membership_matches_filter(system))

			local second = decore.create_prefab("mob")
			world:addEntity(second)
			refresh()
			assert(world.shapeSystems[second.__shape] ~= nil)
			assert(#system.entities == 2)
		end)

		it("Should keep onAdd and onRemove callbacks with shape path", function()
			decore.register_component("health", { value = 100 })
			decore.register_entity("mob", { health = { value = 1 } })

			local added = {}
			local removed = {}
			local system = decore.system({
				onAdd = function(_, entity)
					added[#added + 1] = entity
				end,
				onRemove = function(_, entity)
					removed[#removed + 1] = entity
				end,
			}, "health_system", "health")
			world:addSystem(system)
			refresh()

			local entity = decore.create_prefab("mob")
			world:addEntity(entity)
			refresh()
			assert(#added == 1)
			assert(added[1] == entity)

			world:removeEntity(entity)
			refresh()
			assert(#removed == 1)
			assert(removed[1] == entity)
			assert(#system.entities == 0)
		end)

		it("Should precompute dispatch lists for update callbacks", function()
			local updated = 0
			local fixed = 0
			local late = 0
			local wrapped = 0

			world:add(
				decore.system({
					update = function()
						updated = updated + 1
					end,
				}, "with_update", nil),
				decore.system({
					fixed_update = function()
						fixed = fixed + 1
					end,
					late_update = function()
						late = late + 1
					end,
				}, "with_fixed_late", nil),
				decore.system({
					preWrap = function()
						wrapped = wrapped + 1
					end,
					postWrap = function()
						wrapped = wrapped + 1
					end,
				}, "with_wrap", nil),
				decore.system({}, "reactive_only", nil)
			)
			refresh()

			assert(#world.systemsUpdate >= 1)
			assert(#world.systemsFixedUpdate >= 1)
			assert(#world.systemsLateUpdate >= 1)
			assert(#world.systemsPreWrap >= 1)
			assert(#world.systemsPostWrap >= 1)

			world:update(1 / 60)
			world:fixed_update(1 / 60)
			world:late_update(1 / 60)

			assert(updated == 1)
			assert(fixed == 1)
			assert(late == 1)
			assert(wrapped == 2)
		end)

		it("Should match full scan when shape validation is enabled", function()
			decore.ecs.setShapeValidation(true)
			decore.register_component("health", { value = 100 })
			decore.register_entity("mob", { health = { value = 1 } })

			local system = decore.system({}, "health_system", "health")
			world:addSystem(system)
			refresh()

			local entity = decore.create_prefab("mob")
			world:addEntity(entity)
			refresh()

			assert(membership_matches_filter(system))
			decore.ecs.setShapeValidation(false)
		end)
	end)
end
