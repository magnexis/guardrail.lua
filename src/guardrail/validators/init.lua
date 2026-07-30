local schema = require("guardrail.schema")
local errors = require("guardrail.errors")
local path = require("guardrail.path")

local M = {}
local function ordered_keys(values)
  local keys = {}; for key in pairs(values) do keys[#keys + 1] = key end
  table.sort(keys, function(a, b)
    if type(a) == type(b) then return a < b end
    return type(a) < type(b)
  end)
  return keys
end
local function fail(ctx, code, message, expected, value)
  return schema.issue(ctx, { code = code, message = message, expected = expected, received = type(value), value = value })
end
local function primitive(kind, expected, options)
  options = options or {}
  return schema.new(kind, function(value, ctx)
    if type(value) ~= expected then return fail(ctx, "type_mismatch", "expected " .. kind .. ", received " .. type(value), kind, value) end
    return nil
  end, options, options)
end

function M.any() return schema.new("any", function() return nil end) end
function M.nil_value() return schema.new("nil", function(value, ctx) if value ~= nil then return fail(ctx, "type_mismatch", "expected nil, received " .. type(value), "nil", value) end end) end
function M.boolean(options) return primitive("boolean", "boolean", options) end
function M.function_value(options) return primitive("function", "function", options) end
function M.thread(options) return primitive("thread", "thread", options) end
function M.userdata(options) return primitive("userdata", "userdata", options) end
function M.string(options)
  options = options or {}
  return schema.new("string", function(value, ctx)
    if type(value) ~= "string" then return fail(ctx, "type_mismatch", "expected string, received " .. type(value), "string", value) end
    local length = #value
    if (options.non_empty and length == 0) or (options.min_length and length < options.min_length) or (options.max_length and length > options.max_length) or (options.exact_length and length ~= options.exact_length) then return fail(ctx, "constraint_failed", "string length constraint failed", "string", value) end
    if options.pattern and not value:match(options.pattern) then return fail(ctx, "constraint_failed", "string does not match required pattern", "string", value) end
  end, options, options)
end
local function numeric(kind, integer, options)
  options = options or {}
  return schema.new(kind, function(value, ctx)
    if type(value) ~= "number" or (integer and not schema.compat().is_integer(value)) then return fail(ctx, "type_mismatch", "expected " .. kind .. ", received " .. type(value), kind, value) end
    if options.finite and not schema.compat().is_finite(value) then return fail(ctx, "constraint_failed", "expected a finite number", kind, value) end
    if (options.min and value < options.min) or (options.max and value > options.max) or (options.exclusive_min and value <= options.exclusive_min) or (options.exclusive_max and value >= options.exclusive_max) or (options.positive and value <= 0) or (options.negative and value >= 0) or (options.non_negative and value < 0) then return fail(ctx, "constraint_failed", "number range constraint failed", kind, value) end
  end, options, options)
end
function M.number(options) return numeric("number", false, options) end
function M.integer(options) return numeric("integer", true, options) end
function M.literal(expected)
  return schema.new("literal", function(value, ctx)
    if value ~= expected or type(value) ~= type(expected) then return fail(ctx, "invalid_literal", "value does not match literal", tostring(expected), value) end
  end, { value = expected })
end
function M.enum(values)
  if type(values) ~= "table" then error("enum expects a table", 2) end
  return schema.new("enum", function(value, ctx)
    for _, expected in ipairs(values) do if value == expected and type(value) == type(expected) then return nil end end
    return fail(ctx, "invalid_enum_value", "value is not in enum", "enum", value)
  end, { values = values })
end
function M.optional(inner) local result = inner:optional(); return result end
function M.nullable(inner) return inner:nullable() end
function M.custom(name, callback)
  local descriptor = type(name) == "table" and name or { name = name, validate = callback }
  if type(descriptor.validate) ~= "function" then error("custom validator requires a validate function", 2) end
  return schema.new(descriptor.name or "custom", function(value, ctx)
    local ok, valid, message = pcall(descriptor.validate, value)
    if not ok then return fail(ctx, "custom_validation_failed", "custom validator raised an error", descriptor.name, value) end
    if not valid then return fail(ctx, "custom_validation_failed", message or ("custom validator '" .. (descriptor.name or "unnamed") .. "' failed"), descriptor.name, value) end
  end, {}, descriptor)
end
function M.union(items)
  return schema.new("union", function(value, ctx)
    local candidates = {}
    for _, item in ipairs(items) do
      local child = { path = ctx.path, depth = ctx.depth + 1, max_depth = ctx.max_depth, collect_all = false, errors = {}, active = ctx.active }
      if not item:_validate(value, child) then return nil end
      candidates[#candidates + 1] = child.errors[1]
    end
    return schema.issue(ctx, { code = "union_failed", message = "value did not match any union member", expected = "union", received = type(value), causes = candidates })
  end, { members = items })
end
function M.array(item, options)
  options = options or {}
  return schema.new("array", function(value, ctx)
    if type(value) ~= "table" then return fail(ctx, "type_mismatch", "expected array, received " .. type(value), "array", value) end
    if ctx.active[value] then return fail(ctx, "recursive_schema_error", "cyclic table encountered", "acyclic array", value) end
    ctx.active[value] = true
    local max, count = 0, 0
    for key in pairs(value) do if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then ctx.active[value] = nil; return fail(ctx, "type_mismatch", "array contains a non-array key", "array", value) end; if key > max then max = key end; count = count + 1 end
    if not options.allow_sparse and max ~= count then ctx.active[value] = nil; return fail(ctx, "constraint_failed", "sparse arrays are not allowed", "dense array", value) end
    if (options.min_length and count < options.min_length) or (options.max_length and count > options.max_length) then ctx.active[value] = nil; return fail(ctx, "constraint_failed", "array length constraint failed", "array", value) end
    local seen = {}
    for i = 1, max do if value[i] ~= nil then
      if options.unique and seen[value[i]] then ctx.active[value] = nil; return fail(ctx, "constraint_failed", "array values must be unique", "unique array", value) end
      seen[value[i]] = true; local err = item:_validate(value[i], schema.child(ctx, i)); if err then ctx.active[value] = nil; return err end
    end end
    ctx.active[value] = nil
  end, { item = item, min_length = options.min_length, max_length = options.max_length, unique = options.unique, allow_sparse = options.allow_sparse }, options)
end
function M.tuple(items)
  return schema.new("tuple", function(value, ctx)
    if type(value) ~= "table" then return fail(ctx, "type_mismatch", "expected tuple, received " .. type(value), "tuple", value) end
    for i, item in ipairs(items) do
      if value[i] == nil and not item._optional and not item._nullable then return schema.issue(schema.child(ctx, i), { code = "missing_field", message = "missing tuple value", expected = item.kind, received = "nil" }) end
      if value[i] ~= nil then local err = item:_validate(value[i], schema.child(ctx, i)); if err then return err end end
    end
  end, { items = items })
end
function M.map(key_schema, value_schema)
  return schema.new("map", function(value, ctx)
    if type(value) ~= "table" then return fail(ctx, "type_mismatch", "expected map, received " .. type(value), "map", value) end
    if ctx.active[value] then return fail(ctx, "recursive_schema_error", "cyclic table encountered", "acyclic map", value) end
    ctx.active[value] = true
    for key, item in pairs(value) do local err = key_schema:_validate(key, schema.child(ctx, key)) or value_schema:_validate(item, schema.child(ctx, key)); if err then ctx.active[value] = nil; return err end end
    ctx.active[value] = nil
  end, { key = key_schema, value = value_schema })
end
function M.table(fields, options)
  options = options or {}; if options.allow_unknown == nil then options.allow_unknown = false end
  local object = schema.new("table", function(value, ctx)
    if type(value) ~= "table" then return fail(ctx, "type_mismatch", "expected table, received " .. type(value), "table", value) end
    if ctx.active[value] then return fail(ctx, "recursive_schema_error", "cyclic table encountered", "acyclic table", value) end
    ctx.active[value] = true
    for _, key in ipairs(ordered_keys(fields)) do
      local field = fields[key]
      local item = rawget(value, key)
      if item == nil and options.require_all ~= false and not field._optional and not field._nullable then ctx.active[value] = nil; return schema.issue(schema.child(ctx, key), { code = "missing_field", message = "required field is missing", expected = field.kind, received = "nil" }) end
      if item ~= nil then local err = field:_validate(item, schema.child(ctx, key)); if err then ctx.active[value] = nil; return err end end
    end
    if not options.allow_unknown and not options.strip_unknown then for _, key in ipairs(ordered_keys(value)) do if fields[key] == nil then ctx.active[value] = nil; return schema.issue(schema.child(ctx, key), { code = "unknown_field", message = "unknown field", expected = "known field", received = type(value[key]) }) end end end
    ctx.active[value] = nil
  end, { fields = fields, allow_unknown = options.allow_unknown, strip_unknown = options.strip_unknown, require_all = options.require_all }, options)
  if options.strip_unknown then
    object = object:transform(function(value)
      local copy = {}; for key in pairs(fields) do copy[key] = rawget(value, key) end; return copy
    end)
  end
  return object
end
function M.lazy(factory)
  local resolved
  return schema.new("lazy", function(value, ctx)
    if not resolved then local ok, result = pcall(factory); if not ok or not schema.is_schema(result) then return fail(ctx, "recursive_schema_error", "lazy schema factory did not return a schema", "schema", value) end; resolved = result end
    return resolved:_validate(value, ctx)
  end)
end

return M
