---@diagnostic disable: undefined-field

return function()
	describe("Decore Event Bus", function()
		local decore ---@type decore
		local world ---@type world

		before(function()
			decore = require("decore.decore")
			world = decore.new_world()
		end)

		it("Should have event bus in world", function()
			assert(world.event_bus ~= nil)
			assert(world.event_bus.events ~= nil)
			assert(world.event_bus.stash ~= nil)
			assert(world.event_bus.events_by_entity ~= nil)
			assert(world.event_bus.stash_by_entity ~= nil)
			assert(world.event_bus.merge_callbacks ~= nil)
		end)

		it("Should trigger event and add to stash", function()
			world.event_bus:trigger("test_event", { data = "test" })
			local stash = world.event_bus:get_stash("test_event")
			assert(stash ~= nil)
			assert(#stash == 1)
			assert(stash[1] ~= nil)
			assert(stash[1].data == "test")
		end)

		it("Should trigger multiple events", function()
			world.event_bus:trigger("test_event", { data = 1 })
			world.event_bus:trigger("test_event", { data = 2 })
			world.event_bus:trigger("test_event", { data = 3 })
			local stash = world.event_bus:get_stash("test_event")
			assert(stash ~= nil)
			assert(#stash == 3)
			assert(stash[1] ~= nil)
			assert(stash[1].data == 1)
			assert(stash[2] ~= nil)
			assert(stash[2].data == 2)
			assert(stash[3] ~= nil)
			assert(stash[3].data == 3)
		end)

		it("Should trigger event with nil data", function()
			world.event_bus:trigger("test_event", nil)
			local stash = world.event_bus:get_stash("test_event")
			assert(stash ~= nil)
			assert(#stash == 1)
			assert(stash[1] == true)
		end)

		it("Should move stash to events", function()
			world.event_bus:trigger("test_event", { data = "test" })
			local stash_before = world.event_bus:get_stash("test_event")
			assert(#stash_before == 1)

			world.event_bus:stash_to_events()
			local stash_after = world.event_bus:get_stash("test_event")
			assert(stash_after == nil or #stash_after == 0)

			local events = world.event_bus:get_events("test_event")
			assert(events ~= nil)
			assert(#events == 1)
			assert(events[1].data == "test")
		end)

		it("Should process events with callback", function()
			world.event_bus:trigger("test_event", { data = "test" })
			world.event_bus:stash_to_events()

			local processed_data = nil
			world.event_bus:process("test_event", function(events)
				assert(events ~= nil)
				assert(events[1] ~= nil)
				processed_data = events[1].data
			end)
			assert(processed_data == "test")
		end)

		it("Should process events with context", function()
			world.event_bus:trigger("test_event", { data = "test" })
			world.event_bus:stash_to_events()

			local processed_data = nil
			local context = { value = 100 }
			world.event_bus:process("test_event", function(ctx, events)
				assert(events ~= nil)
				assert(events[1] ~= nil)
				processed_data = { context = ctx, data = events[1].data }
			end, context)
			assert(processed_data ~= nil)
			assert(processed_data.context.value == 100)
			assert(processed_data.data == "test")
		end)

		it("Should return events from process", function()
			world.event_bus:trigger("test_event", { data = "test" })
			world.event_bus:stash_to_events()

			local events = world.event_bus:process("test_event")
			assert(events ~= nil)
			assert(#events == 1)
			assert(events[1].data == "test")
		end)

		it("Should return nil when processing non-existent event", function()
			local events = world.event_bus:process("non_existent")
			assert(events == nil)
		end)

		it("Should clear events", function()
			world.event_bus:trigger("test_event", { data = "test" })
			world.event_bus:stash_to_events()
			world.event_bus:clear_events()

			local events = world.event_bus:get_events("test_event")
			assert(events == nil)
		end)

		it("Should handle events with entity", function()
			local entity = { id = 1 }
			world.event_bus:trigger("test_event", { entity = entity, data = "test" })
			world.event_bus:stash_to_events()

			local events = world.event_bus:get_events("test_event")
			assert(events ~= nil)
			assert(#events == 1)
			assert(events[1] ~= nil)
			assert(events[1].entity ~= nil)
			assert(events[1].entity.id == 1)
		end)

		it("Should handle events without entity", function()
			world.event_bus:trigger("test_event", { data = "test" })
			world.event_bus:stash_to_events()

			local events = world.event_bus:get_events("test_event")
			assert(#events == 1)
			assert(events[1].entity == nil)
		end)

		it("Should merge events with merge policy", function()
			local entity = { id = 1 }
			world.event_bus:set_merge_policy("test_event", function(new_event, events, entity_map)
				local entity_key = new_event.entity or "system"
				local existing_events = entity_map[entity_key]
				if existing_events and #existing_events > 0 then
					local last_event = existing_events[#existing_events]
					last_event.data = new_event.data
					return true
				end
				return false
			end)

			world.event_bus:trigger("test_event", { entity = entity, data = "first" })
			world.event_bus:trigger("test_event", { entity = entity, data = "second" })
			local stash = world.event_bus:get_stash("test_event")
			assert(stash ~= nil)
			assert(#stash == 1)
			assert(stash[1].data == "second")
		end)

		it("Should not merge when merge policy returns false", function()
			world.event_bus:set_merge_policy("test_event", function()
				return false
			end)

			world.event_bus:trigger("test_event", { data = "first" })
			world.event_bus:trigger("test_event", { data = "second" })
			local stash = world.event_bus:get_stash("test_event")
			assert(#stash == 2)
		end)

		it("Should handle multiple events with same entity", function()
			local entity1 = { id = 1 }
			local entity2 = { id = 2 }
			world.event_bus:trigger("test_event", { entity = entity1, data = "entity1" })
			world.event_bus:trigger("test_event", { entity = entity2, data = "entity2" })
			world.event_bus:trigger("test_event", { entity = entity1, data = "entity1_again" })
			world.event_bus:stash_to_events()

			local events = world.event_bus:get_events("test_event")
			assert(#events == 3)
		end)

		it("Should handle string and hash event names", function()
			world.event_bus:trigger("string_event", { data = "string" })
			local hash_event_name = hash("hash_event")
			world.event_bus:trigger(hash_event_name, { data = "hash" })
			world.event_bus:stash_to_events()

			local string_events = world.event_bus:get_events("string_event")
			local hash_events = world.event_bus:get_events(hash_event_name)
			assert(string_events ~= nil)
			assert(hash_events ~= nil)
			assert(string_events[1] ~= nil)
			assert(string_events[1].data == "string")
			assert(hash_events[1] ~= nil)
			assert(hash_events[1].data == "hash")
		end)

		it("Should work with world event bus", function()
			world.event_bus:trigger("world_event", { data = "world" })
			world:update(0)
			local events = world.event_bus:get_events("world_event")
			assert(events ~= nil)
			assert(#events == 1)
			assert(events[1] ~= nil)
			assert(events[1].data == "world")
		end)

		it("Should clear merge policy", function()
			world.event_bus:set_merge_policy("test_event", function(new_event, events, entity_map)
				if events and #events > 0 then
					events[#events].data = new_event.data
					return true
				end
				return false
			end)
			world.event_bus:trigger("test_event", { data = "first" })
			local stash_after_first = world.event_bus:get_stash("test_event")
			assert(stash_after_first ~= nil)
			assert(#stash_after_first == 1)

			world.event_bus:trigger("test_event", { data = "second" })
			local stash1 = world.event_bus:get_stash("test_event")
			assert(stash1 ~= nil)
			assert(#stash1 == 1)
			assert(stash1[1] ~= nil)
			assert(stash1[1].data == "second")

			world.event_bus:set_merge_policy("test_event", nil)
			assert(world.event_bus.merge_callbacks["test_event"] == nil)
			world.event_bus:stash_to_events()
			world.event_bus:clear_events()
			world.event_bus:trigger("test_event", { data = "third" })
			world.event_bus:trigger("test_event", { data = "fourth" })
			local stash2 = world.event_bus:get_stash("test_event")
			assert(stash2 ~= nil)
			assert(#stash2 == 2)
			assert(stash2[1] ~= nil)
			assert(stash2[1].data == "third")
			assert(stash2[2] ~= nil)
			assert(stash2[2].data == "fourth")
		end)

		it("Should handle empty stash after stash_to_events", function()
			world.event_bus:trigger("test_event", { data = "test" })
			world.event_bus:stash_to_events()
			world.event_bus:trigger("test_event", { data = "test2" })

			local stash = world.event_bus:get_stash("test_event")
			assert(stash ~= nil)
			assert(#stash == 1)
			assert(stash[1] ~= nil)
			assert(stash[1].data == "test2")

			local events = world.event_bus:get_events("test_event")
			assert(events ~= nil)
			assert(#events == 1)
			assert(events[1] ~= nil)
			assert(events[1].data == "test")
		end)
	end)
end
