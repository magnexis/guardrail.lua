local path = require("guardrail.path")
local config = require("guardrail.config")
local Error = {}; Error.__index = Error

function Error:__tostring() return self.message end
function Error:to_table()
  local result = {}
  for key, value in pairs(self) do
    if key ~= "value" or config.get("include_values_in_errors") then result[key] = value end
  end
  result.path = path.copy(self.path or {}); result.path_string = path.format(result.path)
  return result
end

local M = {}
function M.new(fields)
  fields = fields or {}; fields.name = "GuardrailError"; fields.path = fields.path or {}
  fields.path_string = path.format(fields.path)
  if config.get("capture_tracebacks") and not fields.traceback then fields.traceback = debug and debug.traceback and debug.traceback("", 3) or nil end
  return setmetatable(fields, Error)
end
function M.is_error(value) return getmetatable(value) == Error end
return M
