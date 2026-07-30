package.path = "src/?.lua;src/?/init.lua;" .. package.path
local guard = require("guardrail")
local schema = guard.table({ id = guard.integer({ positive = true }), tags = guard.array(guard.string()) })
local value = { id = 1, tags = { "lua", "validation" } }
local count = tonumber(arg[1]) or 100000
local started = os.clock(); for _ = 1, count do assert(schema:is_valid(value)) end
print(string.format("%d nested validations in %.3fs", count, os.clock() - started))
