local errors = require("guardrail.errors")
local compat = require("guardrail.compatibility")
local M = {}
local Invariant = {}; Invariant.__index = Invariant
function Invariant:validate(value)
  local ok, valid, message = pcall(self.check, value)
  if not ok or not valid then return false, errors.new({ code = "invariant_failed", message = message or self.message or "invariant failed", expected = self.name, received = type(value) }) end
  return true
end
function Invariant:assert(value) local ok, err = self:validate(value); if not ok then error(err, 0) end; return value end
function M.invariant(spec)
  if type(spec) ~= "table" or type(spec.check) ~= "function" then error("invariant requires a check function", 2) end
  return setmetatable(spec, Invariant)
end
function M.with_invariants(invariants, state, operation, options)
  options = options or {}; if options.before ~= false then for _, invariant in ipairs(invariants) do invariant:assert(state) end end
  local results = compat.pack(operation())
  if options.after ~= false then for _, invariant in ipairs(invariants) do invariant:assert(state) end end
  return compat.unpack(results, 1, results.n)
end
function M.with_invariant(invariant, state, operation, options) return M.with_invariants({ invariant }, state, operation, options) end
return M
