---@diagnostic disable: undefined-field

return function()
	describe("Decore Event Bus", function()
		local decore ---@type decore
		local world ---@type world
		local bus

		before(function()
			decore = require("decore.decore")
			world = decore.new_world()
			bus = world.event
		end)

		it("Should have event bus in world", function()
			assert(bus ~= nil)
			assert(world.event == bus)
			assert(world.event_bus == bus) -- deprecated alias
			assert(bus.events ~= nil)
			assert(bus.stash ~= nil)
			assert(bus.event_entities ~= nil)
			assert(bus.stash_entities ~= nil)
			assert(bus.merge_callbacks ~= nil)
		end)

		it("Should trigger event with data only", function()
			bus:trigger("test_event", nil, { value = "test" })
			local stash = bus:get_stash("test_event")
			assert(stash ~= nil)
			assert(#stash == 1)
			assert(stash[1].value == "test")
			assert(bus:get_stash_entities("test_event")[1] == bus.NO_ENTITY)
		end)

		it("Should trigger entity event without data and without alloc payload", function()
			local entity = { id = 1 }
			bus:trigger("died", entity)
			local stash = bus:get_stash("died")
			local entities = bus:get_stash_entities("died")
			assert(#stash == 1)
			assert(stash[1] == bus.NO_DATA)
			assert(entities[1] == entity)
		end)

		it("Should trigger global signal without entity or data", function()
			bus:trigger("wave_start")
			local stash = bus:get_stash("wave_start")
			assert(#stash == 1)
			assert(stash[1] == bus.NO_DATA)
			assert(bus:get_stash_entities("wave_start")[1] == bus.NO_ENTITY)
		end)

		it("Should trigger multiple events", function()
			bus:trigger("test_event", nil, 1)
			bus:trigger("test_event", nil, 2)
			bus:trigger("test_event", nil, 3)
			local stash = bus:get_stash("test_event")
			assert(#stash == 3)
			assert(stash[1] == 1)
			assert(stash[2] == 2)
			assert(stash[3] == 3)
		end)

		it("Should move stash to events", function()
			bus:trigger("test_event", nil, { value = "test" })
			assert(#bus:get_stash("test_event") == 1)

			bus:stash_to_events()
			local stash_after = bus:get_stash("test_event")
			assert(stash_after == nil or #stash_after == 0)

			local events = bus:get_events("test_event")
			assert(#events == 1)
			assert(events[1].value == "test")
		end)

		it("Should process once per event with entity and data", function()
			local entity = { id = 7 }
			bus:trigger("test_event", entity, { value = 1 })
			bus:trigger("test_event", entity, { value = 2 })
			bus:stash_to_events()

			local seen = {}
			bus:process("test_event", function(e, data)
				seen[#seen + 1] = { entity = e, value = data.value }
			end)
			assert(#seen == 2)
			assert(seen[1].entity == entity)
			assert(seen[1].value == 1)
			assert(seen[2].value == 2)
		end)

		it("Should process with context", function()
			local entity = { id = 1 }
			bus:trigger("test_event", entity, "a")
			bus:trigger("test_event", nil, "b")
			bus:stash_to_events()

			local context = { prefix = "x" }
			local seen = {}
			bus:process("test_event", function(ctx, e, data)
				seen[#seen + 1] = { ctx = ctx, entity = e, data = data }
			end, context)

			assert(#seen == 2)
			assert(seen[1].ctx == context)
			assert(seen[1].entity == entity)
			assert(seen[1].data == "a")
			assert(seen[2].entity == nil)
			assert(seen[2].data == "b")
		end)

		it("Should expose parallel entity and data arrays", function()
			local entity = { id = 1 }
			bus:trigger("test_event", entity, "one")
			bus:trigger("test_event", nil, "two")
			bus:stash_to_events()

			local datas = bus:get_events("test_event")
			local entities = bus:get_event_entities("test_event")
			assert(#datas == 2)
			assert(entities[1] == entity)
			assert(datas[1] == "one")
			assert(bus.decode_entity(entities[2]) == nil)
			assert(datas[2] == "two")
		end)

		it("Should return nil when processing non-existent event", function()
			assert(bus:process("non_existent") == nil)
		end)

		it("Should clear events", function()
			bus:trigger("test_event", nil, "test")
			bus:stash_to_events()
			bus:clear_events()
			assert(bus:get_events("test_event") == nil)
		end)

		it("Should merge events with merge policy by entity", function()
			local entity = { id = 1 }
			bus:set_merge_policy("test_event", function(e, data, datas, entity_map)
				local existing = entity_map[e]
				if existing and #existing > 0 then
					existing[#existing] = data
					datas[#datas] = data
					return true
				end
				return false
			end)

			bus:trigger("test_event", entity, "first")
			bus:trigger("test_event", entity, "second")
			local stash = bus:get_stash("test_event")
			assert(#stash == 1)
			assert(stash[1] == "second")
		end)

		it("Should not merge when merge policy returns false", function()
			bus:set_merge_policy("test_event", function()
				return false
			end)

			bus:trigger("test_event", nil, "first")
			bus:trigger("test_event", nil, "second")
			assert(#bus:get_stash("test_event") == 2)
		end)

		it("Should keep separate events for different entities", function()
			local entity1 = { id = 1 }
			local entity2 = { id = 2 }
			bus:trigger("test_event", entity1, "a")
			bus:trigger("test_event", entity2, "b")
			bus:trigger("test_event", entity1, "c")
			bus:stash_to_events()

			local entities = bus:get_event_entities("test_event")
			local datas = bus:get_events("test_event")
			assert(#datas == 3)
			assert(entities[1] == entity1)
			assert(entities[2] == entity2)
			assert(entities[3] == entity1)
		end)

		it("Should handle string and hash event names", function()
			bus:trigger("string_event", nil, "string")
			local hash_event_name = hash("hash_event")
			bus:trigger(hash_event_name, nil, "hash")
			bus:stash_to_events()

			assert(bus:get_events("string_event")[1] == "string")
			assert(bus:get_events(hash_event_name)[1] == "hash")
		end)

		it("Should expose queued events after world update postWrap", function()
			bus:trigger("world_event", nil, "world")
			world:update(0)
			local events = bus:get_events("world_event")
			assert(#events == 1)
			assert(events[1] == "world")
		end)

		it("Should clear merge policy", function()
			bus:set_merge_policy("test_event", function(e, data, datas, entity_map)
				if datas and #datas > 0 then
					datas[#datas] = data
					local key = e or "system"
					entity_map[key][#entity_map[key]] = data
					return true
				end
				return false
			end)
			bus:trigger("test_event", nil, "first")
			bus:trigger("test_event", nil, "second")
			assert(#bus:get_stash("test_event") == 1)
			assert(bus:get_stash("test_event")[1] == "second")

			bus:set_merge_policy("test_event", nil)
			bus:stash_to_events()
			bus:clear_events()
			bus:trigger("test_event", nil, "third")
			bus:trigger("test_event", nil, "fourth")
			assert(#bus:get_stash("test_event") == 2)
		end)

		it("Should keep next-frame stash separate after stash_to_events", function()
			bus:trigger("test_event", nil, "test")
			bus:stash_to_events()
			bus:trigger("test_event", nil, "test2")

			assert(#bus:get_stash("test_event") == 1)
			assert(bus:get_stash("test_event")[1] == "test2")
			assert(bus:get_events("test_event")[1] == "test")
		end)

		it("Should decode nil data in process for signal events", function()
			local entity = { id = 1 }
			bus:trigger("died", entity)
			bus:stash_to_events()

			local got_entity, got_data = nil, "unset"
			bus:process("died", function(e, data)
				got_entity = e
				got_data = data
			end)
			assert(got_entity == entity)
			assert(got_data == nil)
		end)
	end)
end
