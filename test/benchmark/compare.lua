--- Compares two benchmark runs captured from the engine output.
--- Runs on plain Lua (5.1+), outside Defold:
---
---   lua test/benchmark/compare.lua bench_develop.txt bench_shapes.txt

local CSV_BEGIN = "### BENCH CSV BEGIN"
local CSV_END = "### BENCH CSV END"


---Reads every CSV block in a file. A file may hold several runs of the same suite;
---for each case the best numbers across those runs win, because process to process
---noise only ever makes a case look slower.
---@param path string
---@return table<string, table<string, number>>
---@return string[] Case names in the order they appear
local function parse(path)
	local file = assert(io.open(path, "r"), "cannot open " .. path)
	local rows = {}
	local order = {}
	local header = nil
	local inside = false

	for line in file:lines() do
		-- The engine may prefix log lines, so match the marker anywhere
		if line:find(CSV_BEGIN, 1, true) then
			inside = true
			header = nil
		elseif line:find(CSV_END, 1, true) then
			inside = false
		elseif inside then
			-- The engine prefixes every print with something like "DEBUG:SCRIPT: "
			local payload = line:match("SCRIPT:%s*(.*)$") or line

			local fields = {}
			for field in (payload .. ","):gmatch("([^,]*),") do
				fields[#fields + 1] = field
			end

			if not header then
				header = fields
			elseif #fields == #header and fields[1] ~= "" then
				local name = fields[1]
				local row = rows[name]

				if not row then
					row = {}
					rows[name] = row
					order[#order + 1] = name
				end

				for index = 2, #header do
					local key = header[index]
					local value = tonumber(fields[index])
					if value and (not row[key] or value < row[key]) then
						row[key] = value
					end
				end
			end
		end
	end

	file:close()
	assert(#order > 0, "no benchmark CSV block found in " .. path)

	return rows, order
end


---@param base number|nil
---@param new number|nil
---@return string
local function format_delta(base, new)
	if not base or not new then
		return "n/a"
	end
	if base == 0 then
		return new == 0 and "0.0%" or "+inf"
	end

	local percent = (new - base) / base * 100
	return ("%+.1f%%"):format(percent)
end


---@param base number|nil
---@param new number|nil
---@return string
local function format_speedup(base, new)
	if not base or not new or new == 0 then
		return "n/a"
	end

	return ("%.2fx"):format(base / new)
end


local base_path = arg[1]
local new_path = arg[2]

if not base_path or not new_path then
	print("usage: lua test/benchmark/compare.lua <base_output> <new_output>")
	os.exit(1)
end

local base_rows, base_order = parse(base_path)
local new_rows = parse(new_path)

print(("base: %s"):format(base_path))
print(("new:  %s"):format(new_path))
print("")
-- Best of N is the primary metric: the slower samples carry whatever else the
-- machine was doing, so the fastest one is the most reproducible.
print(("%-42s %10s %10s %9s %8s %10s %10s %9s"):format(
	"CASE", "BEST base", "BEST new", "DELTA", "SPEEDUP", "ALLOC base", "ALLOC new", "DELTA"))
print(("-"):rep(116))

local missing = {}
for index = 1, #base_order do
	local name = base_order[index]
	local base = base_rows[name]
	local new = new_rows[name]

	if not new then
		missing[#missing + 1] = name
	else
		print(("%-42s %10.2f %10.2f %9s %8s %10.1f %10.1f %9s"):format(
			name,
			base.best_ms,
			new.best_ms,
			format_delta(base.best_ms, new.best_ms),
			format_speedup(base.best_ms, new.best_ms),
			base.alloc_kb,
			new.alloc_kb,
			format_delta(base.alloc_kb, new.alloc_kb)))
	end
end

if #missing > 0 then
	print("")
	print("missing in new run: " .. table.concat(missing, ", "))
end
