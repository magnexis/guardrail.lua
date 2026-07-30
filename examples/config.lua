package.path = "src/?.lua;src/?/init.lua;" .. package.path
local guard = require("guardrail")
local config = guard.table({ host = guard.string({ non_empty = true }), port = guard.integer({ min = 1, max = 65535 }), debug = guard.optional(guard.boolean()) }):assert({ host = "127.0.0.1", port = 8080, debug = true })
print(config.host .. ":" .. config.port)
