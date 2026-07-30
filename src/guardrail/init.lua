local config = require("guardrail.config")
local validators = require("guardrail.validators")
local contracts = require("guardrail.contract")
local invariants = require("guardrail.invariant")
local errors = require("guardrail.errors")
local formatter = require("guardrail.formatter")

local guard = { VERSION = "0.1.0" }
for name, value in pairs(validators) do guard[name] = value end
guard.contract = contracts.contract
guard.returns = contracts.returns
guard.invariant = invariants.invariant
guard.with_invariant = invariants.with_invariant
guard.with_invariants = invariants.with_invariants
guard.configure = config.configure
guard.enable = config.enable
guard.disable = config.disable
function guard.with_disabled(fn)
  local previous = config.get("mode"); config.disable()
  local results = require("guardrail.compatibility").pack(pcall(fn)); config.configure({ mode = previous })
  if not results[1] then error(results[2], 0) end
  table.remove(results, 1); results.n = results.n - 1
  return require("guardrail.compatibility").unpack(results, 1, results.n)
end
guard.is_error = errors.is_error
guard.error_to_table = function(err) return errors.is_error(err) and err:to_table() or err end
guard.format_error = formatter.format
guard.describe = function(value) return value:describe() end
local function boundary(kind, validator, value)
  local ok, err = validator:validate(value)
  if not ok then if err[1] then err = err[1] end; err.boundary = kind end
  return ok, err
end
guard.validate_config = function(s, v) return boundary("config", s, v) end
guard.validate_plugin = function(s, v) return boundary("plugin", s, v) end
guard.validate_response = function(s, v) return boundary("response", s, v) end
guard.validate_event = function(s, v) return boundary("event", s, v) end
guard.annotations = require("guardrail.annotations")
return guard
