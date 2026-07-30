local M = {}

M.unpack = table.unpack or unpack
M.pack = table.pack or function(...)
  return { n = select("#", ...), ... }
end

function M.is_integer(value)
  if type(value) ~= "number" then return false end
  if math.type then return math.type(value) == "integer" end
  return value == math.floor(value)
end

function M.is_finite(value)
  return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function M.traceback(message, level)
  if debug and debug.traceback then return debug.traceback(message, (level or 1) + 1) end
  return message
end

return M
