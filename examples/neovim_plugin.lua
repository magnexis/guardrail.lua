-- This works in Neovim because the core has no runtime dependencies.
package.path = "./?.lua;./?/init.lua;" .. package.path
local guard = require("guardrail")
local setup_options = guard.table({ enabled = guard.optional(guard.boolean()), timeout = guard.optional(guard.integer({ min = 1 })) })
return function(options) return setup_options:assert(options or {}) end
