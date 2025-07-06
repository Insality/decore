local evolved = require("decore.evolved")

---@class components: table<string, evolved.id>
return {
	dt = evolved.builder():name("dt"):default(0):spawn(),
}
