package.path = "./?.lua;./?/init.lua;" .. package.path
local guard = require("guardrail")
local plugin = guard.table({ name = guard.string({ non_empty = true }), version = guard.string({ pattern = "^%d+%.%d+%.%d+$" }), setup = guard.function_value() })
assert(plugin:is_valid({ name = "example", version = "1.0.0", setup = function() end }))
