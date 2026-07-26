---Benchmark harness for decore.
---Prints a human readable table and a machine readable CSV block, so results
---captured on two branches can be diffed with test/benchmark/compare.lua.
---@diagnostic disable: undefined-global

local M = {}

local DEFAULT_RUNS = 5
local CSV_BEGIN = "### BENCH CSV BEGIN"
local CSV_END = "### BENCH CSV END"

---@type fun(): number Time in seconds
local now = (socket and socket.gettime) or os.clock

---@class benchmark.case
---@field name string Unique case name, used as the key when comparing runs
---@field group string|nil Section header, printed when it changes
---@field ops number|nil Logical operations per run, enables the per-op columns
---@field runs number|nil Timed repetitions, defaults to 5
---@field setup fun(): any|nil Untimed, returns the context passed to run/teardown
---@field run fun(ctx: any) The timed body
---@field check fun(ctx: any)|nil Asserts the run did the expected work, called once
---@field teardown fun(ctx: any)|nil Untimed cleanup

---@class benchmark.result
---@field name string
---@field group string|nil
---@field ops number
---@field best_ms number
---@field median_ms number
---@field mean_ms number
---@field alloc_kb number Bytes allocated during run, GC disabled
---@field retained_kb number Memory still held after run, GC collected
---@field samples number[] Every timed run, in order

---@type benchmark.case[]
local cases = {}

---Print the individual samples of every case, useful when a case looks noisy
M.verbose = false


---@param case benchmark.case
function M.add(case)
	cases[#cases + 1] = case
end


---@param values number[]
---@return number
local function median(values)
	local sorted = {}
	for index = 1, #values do
		sorted[index] = values[index]
	end
	table.sort(sorted)

	local count = #sorted
	if count % 2 == 1 then
		return sorted[(count + 1) / 2]
	end

	return (sorted[count / 2] + sorted[count / 2 + 1]) / 2
end


---@param case benchmark.case
---@return number[] Milliseconds per run
local function measure_time(case)
	local samples = {}

	for index = 1, (case.runs or DEFAULT_RUNS) do
		local ctx = case.setup and case.setup()
		collectgarbage("collect")
		collectgarbage("collect")

		local started = now()
		case.run(ctx)
		samples[index] = (now() - started) * 1000

		if case.teardown then
			case.teardown(ctx)
		end
	end

	return samples
end


---GC is stopped so the counter delta is gross allocation instead of net growth.
---
---The JIT is disabled and flushed first: LuaJIT allocates compiled traces from the
---same pool that `collectgarbage("count")` reports, and which traces it decides to
---compile differs from process to process. Leaving it on made this number swing by
---more than 10x between two runs of identical code.
---@param case benchmark.case
---@return number allocated_kb
---@return number retained_kb
local function measure_memory(case)
	local ctx = case.setup and case.setup()

	if jit then
		jit.off()
		jit.flush()
	end

	collectgarbage("collect")
	collectgarbage("collect")

	local before = collectgarbage("count")
	collectgarbage("stop")
	case.run(ctx)
	local allocated_kb = collectgarbage("count") - before

	collectgarbage("restart")
	collectgarbage("collect")
	collectgarbage("collect")
	local retained_kb = collectgarbage("count") - before

	if jit then
		jit.on()
	end

	if case.teardown then
		case.teardown(ctx)
	end

	return allocated_kb, retained_kb
end


---@param case benchmark.case
---@return benchmark.result
local function measure(case)
	-- Warmup passes: let the JIT compile the hot paths and fill any lazily built
	-- caches, so the first timed run is not an outlier
	for pass = 1, 2 do
		local warmup_ctx = case.setup and case.setup()
		case.run(warmup_ctx)
		if pass == 1 and case.check then
			case.check(warmup_ctx)
		end
		if case.teardown then
			case.teardown(warmup_ctx)
		end
	end

	local samples = measure_time(case)
	local allocated_kb, retained_kb = measure_memory(case)

	local total = 0
	local best = samples[1]
	for index = 1, #samples do
		total = total + samples[index]
		if samples[index] < best then
			best = samples[index]
		end
	end

	return {
		name = case.name,
		group = case.group,
		ops = case.ops or 1,
		best_ms = best,
		median_ms = median(samples),
		mean_ms = total / #samples,
		alloc_kb = allocated_kb,
		retained_kb = retained_kb,
		samples = samples,
	}
end


local HEADER_FORMAT = "%-44s %8s %9s %9s %8s %9s %10s %9s %9s"
local ROW_FORMAT = "%-44s %8d %9.2f %9.2f %7.0f%% %9.3f %10.1f %9.1f %9.1f"


---How far the slowest timed run was above the fastest one. A high spread means the
---timing of that case is dominated by machine noise and should not be read closely.
---@param result benchmark.result
---@return number percent
local function spread(result)
	local worst = result.samples[1]
	for index = 1, #result.samples do
		if result.samples[index] > worst then
			worst = result.samples[index]
		end
	end

	return (worst - result.best_ms) / result.best_ms * 100
end


---@param results benchmark.result[]
local function print_table(results)
	print("")
	print(HEADER_FORMAT:format(
		"CASE", "OPS", "BEST ms", "MED ms", "SPREAD", "us/op", "ALLOC KB", "B/op", "HELD KB"))
	print(("-"):rep(125))

	local group = nil
	for index = 1, #results do
		local result = results[index]
		if result.group ~= group then
			group = result.group
			print(("[%s]"):format(tostring(group)))
		end

		print(ROW_FORMAT:format(
			result.name,
			result.ops,
			result.best_ms,
			result.median_ms,
			spread(result),
			result.best_ms * 1000 / result.ops,
			result.alloc_kb,
			result.alloc_kb * 1024 / result.ops,
			result.retained_kb))
	end
end


---@param results benchmark.result[]
local function print_csv(results)
	print("")
	print(CSV_BEGIN)
	print("name,ops,best_ms,median_ms,mean_ms,us_per_op,alloc_kb,bytes_per_op,retained_kb")

	for index = 1, #results do
		local result = results[index]
		print(("%s,%d,%.4f,%.4f,%.4f,%.4f,%.2f,%.2f,%.2f"):format(
			result.name,
			result.ops,
			result.best_ms,
			result.median_ms,
			result.mean_ms,
			result.best_ms * 1000 / result.ops,
			result.alloc_kb,
			result.alloc_kb * 1024 / result.ops,
			result.retained_kb))
	end

	print(CSV_END)
end


---Numbers are only comparable between runs on the same runtime, and the JIT state
---in particular changes them by an order of magnitude, so record it.
local function print_environment()
	local engine = sys.get_engine_info()
	local info = sys.get_sys_info()

	print(("engine:  %s (%s), debug: %s"):format(engine.version, engine.engine_sha1, tostring(engine.is_debug)))
	print(("system:  %s %s"):format(info.system_name, info.system_version))

	if jit then
		print(("runtime: %s, jit %s"):format(jit.version, jit.status() and "ON" or "OFF"))
	else
		print(("runtime: %s, no jit"):format(_VERSION))
	end
end


---Run every registered case and print the report.
---@param pattern string|nil Lua pattern to filter case names
---@return benchmark.result[]
function M.run(pattern)
	print("")
	print_environment()
	print("")
	print(("Running %d benchmark cases"):format(#cases))

	local results = {}
	for index = 1, #cases do
		local case = cases[index]
		if not pattern or case.name:match(pattern) then
			print(("  [%d/%d] %s"):format(index, #cases, case.name))

			local result = measure(case)
			results[#results + 1] = result

			if M.verbose then
				local samples = {}
				for sample_index = 1, #result.samples do
					samples[sample_index] = ("%.2f"):format(result.samples[sample_index])
				end

				-- A heap that keeps growing from case to case means something is
				-- leaking, and every later case is measured against a bigger heap
				collectgarbage("collect")
				collectgarbage("collect")
				print(("          samples ms: %s | heap %.0f KB"):format(
					table.concat(samples, " "), collectgarbage("count")))
			end
		end
	end

	print_table(results)
	print_csv(results)

	return results
end


return M
