local M = {}
local function type_for(schema)
  local kinds = { ["nil"] = "nil", boolean = "boolean", string = "string", number = "number", integer = "integer", ["function"] = "fun(...): ...", thread = "thread", userdata = "userdata", any = "any" }
  if kinds[schema.kind] then return kinds[schema.kind] end
  if schema.kind == "literal" then return string.format("%q", schema.constraints.value) end
  if schema.kind == "enum" then local out = {}; for i, v in ipairs(schema.constraints.values) do out[i] = type(v) == "string" and string.format("%q", v) or tostring(v) end; return table.concat(out, "|") end
  if schema.kind == "array" then return type_for(schema.constraints.item or schema.constraints.value or schema) .. "[]" end
  return schema.kind == "table" and "table" or "any"
end
function M.generate(name, object)
  local lines = { "---@class " .. name }
  local fields = object.constraints.fields or object.fields or {}
  for key, child in pairs(fields) do lines[#lines + 1] = "---@field " .. tostring(key) .. (child._optional and "? " or " ") .. type_for(child) end
  return table.concat(lines, "\n")
end
function M.write_file(filename, definitions)
  local file, err = io.open(filename, "w"); if not file then return nil, err end
  file:write(type(definitions) == "table" and table.concat(definitions, "\n\n") or definitions); file:close(); return true
end
return M
