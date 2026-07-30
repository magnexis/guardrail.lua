local M = { values = {
  mode = "development", include_values_in_errors = false, capture_tracebacks = false,
  max_depth = 100, max_errors = 50, inspect_metatables = false,
} }

function M.configure(options)
  if type(options) ~= "table" then error("guardrail.configure expects a table", 2) end
  for key, value in pairs(options) do M.values[key] = value end
  return M.values
end

function M.get(key) return M.values[key] end
function M.enabled() return M.values.mode ~= "disabled" end
function M.enable() M.values.mode = "development" end
function M.disable() M.values.mode = "disabled" end

return M
