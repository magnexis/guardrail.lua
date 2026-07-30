local compat = require("guardrail.compatibility")
local errors = require("guardrail.errors")
local config = require("guardrail.config")

local M = {}
local function violation(fields)
  fields.name = "GuardrailError"; fields.path = fields.path or {}
  return errors.new(fields)
end
local function check_callback(callback, ...)
  local ok, valid, message = pcall(callback, ...)
  if not ok then return false, "contract callback raised an error" end
  return valid, message
end
local function check_requires(requires, args, name)
  if not requires then return nil end
  if type(requires) == "function" then
    local valid, message = check_callback(requires, compat.unpack(args, 1, args.n))
    if not valid then return violation({ code = "precondition_failed", message = message or "precondition failed", contract = name, phase = "preconditions" }) end
  else
    for _, rule in ipairs(requires) do
      local valid, message = check_callback(rule.check, compat.unpack(args, 1, args.n))
      if not valid then return violation({ code = "precondition_failed", message = message or rule.message or rule.name or "precondition failed", contract = name, phase = "preconditions" }) end
    end
  end
end
function M.returns(items) return { _guardrail_returns = true, items = items } end
function M.contract(spec, fn)
  if type(spec) ~= "table" or type(fn) ~= "function" then error("contract expects a specification table and function", 2) end
  local argument_schemas = spec.args or {}
  local return_schemas = spec.returns and (spec.returns._guardrail_returns and spec.returns.items or { spec.returns })
  return function(...)
    if not config.enabled() or spec.enabled == false then return fn(...) end
    local args = compat.pack(...)
    for index, validator in ipairs(argument_schemas) do
      if args[index] == nil and validator._optional then
      elseif args[index] == nil and not validator._nullable then
        error(violation({ code = "invalid_argument", message = "missing required argument", contract = spec.name, phase = "arguments", argument_index = index, expected = validator.kind, received = "nil" }), 0)
      else
        local valid, err = validator:validate(args[index])
        if not valid then
          if type(err) == "table" and err[1] then err = err[1] end
          err.code = "invalid_argument"; err.contract = spec.name; err.phase = "arguments"; err.argument_index = index
          error(err, 0)
        end
      end
    end
    local precondition = check_requires(spec.requires, args, spec.name); if precondition then error(precondition, 0) end
    local results = compat.pack(fn(...))
    if return_schemas then for index, validator in ipairs(return_schemas) do
      if results[index] == nil and validator._optional then
      elseif results[index] == nil and not validator._nullable then error(violation({ code = "invalid_return_value", message = "missing required return value", contract = spec.name, phase = "returns", argument_index = index, expected = validator.kind, received = "nil" }), 0)
      else local valid, err = validator:validate(results[index]); if not valid then if err[1] then err = err[1] end; err.code = "invalid_return_value"; err.contract = spec.name; err.phase = "returns"; err.argument_index = index; error(err, 0) end end
    end end
    if spec.ensures then
      local valid, message = check_callback(spec.ensures, results, args)
      if not valid then error(violation({ code = "postcondition_failed", message = message or "postcondition failed", contract = spec.name, phase = "postconditions" }), 0) end
    end
    return compat.unpack(results, 1, results.n)
  end
end
return M
