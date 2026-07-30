local path = require("guardrail.path")
local M = {}
function M.format(error, options)
  options = options or {}; if options.compact then return (error.contract and (error.contract .. ": ") or "") .. (error.path_string or path.format(error.path or {})) .. ": " .. error.message end
  local lines = { error.contract and ("Guardrail contract violation in " .. error.contract) or "Guardrail validation error" }
  if error.phase then lines[#lines + 1] = "  Phase: " .. error.phase end
  lines[#lines + 1] = "  Path: " .. (error.path_string or path.format(error.path or {}))
  if error.expected then lines[#lines + 1] = "  Expected: " .. tostring(error.expected) end
  if error.received then lines[#lines + 1] = "  Received: " .. tostring(error.received) end
  lines[#lines + 1] = "  Message: " .. error.message
  return table.concat(lines, "\n")
end
return M
