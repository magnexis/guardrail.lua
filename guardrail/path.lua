local M = {}
function M.copy(path)
  local result = {}; for i = 1, #path do result[i] = path[i] end; return result
end
function M.append(path, segment)
  local result = M.copy(path); result[#result + 1] = segment; return result
end
function M.format(path)
  if #path == 0 then return "$" end
  local out = ""
  for i = 1, #path do
    local part = path[i]
    if type(part) == "number" then out = out .. "[" .. part .. "]"
    elseif out == "" then out = tostring(part)
    else out = out .. "." .. tostring(part) end
  end
  return out
end
return M
