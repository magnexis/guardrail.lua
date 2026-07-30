package.path = "./?.lua;./?/init.lua;" .. package.path
local guard = require("guardrail")
local response = guard.table({ status = guard.integer({ min = 200, max = 299 }), body = guard.map(guard.string(), guard.any()) })
local ok, err = guard.validate_response(response, { status = 200, body = { request_id = "abc" } })
assert(ok, err and guard.format_error(err))
