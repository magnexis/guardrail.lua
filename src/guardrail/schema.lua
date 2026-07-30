local errors = require("guardrail.errors")
local config = require("guardrail.config")
local compat = require("guardrail.compatibility")

local Schema = {}; Schema.__index = Schema
local function clone(schema)
  local result = {}; for key, value in pairs(schema) do result[key] = value end
  result._refinements = {}
  for i, value in ipairs(schema._refinements or {}) do result._refinements[i] = value end
  result._transforms = {}
  for i, value in ipairs(schema._transforms or {}) do result._transforms[i] = value end
  return setmetatable(result, Schema)
end
local function issue(ctx, fields)
  if ctx.collect_all and #ctx.errors >= ctx.max_errors then return nil end
  fields.path = fields.path or ctx.path
  local error = errors.new(fields)
  if ctx.collect_all then
    ctx.errors[#ctx.errors + 1] = error
    return nil
  end
  return error
end
local function run_callback(callback, value)
  local ok, valid, message = pcall(callback, value)
  if not ok then return false, "custom validator raised an error" end
  return valid, message
end

function Schema:_validate(value, ctx)
  if ctx.depth > ctx.max_depth then return issue(ctx, { code = "constraint_failed", message = "maximum validation depth exceeded", expected = self.kind, received = type(value) }) end
  if value == nil and (self._nullable or self._optional) then return nil end
  local error = self._validate_inner(value, ctx)
  if error and not ctx.collect_all then return error end
  if not ctx.skip_refinements then for _, refinement in ipairs(self._refinements) do
    local valid, message = run_callback(refinement.check, value)
    if not valid then
      error = issue(ctx, { code = refinement.code or "constraint_failed", message = message or refinement.message or "refinement failed", expected = self.kind, received = type(value) })
      if error then return error end
    end
  end end
  return nil
end

function Schema:validate(value, options)
  if not config.enabled() then return true end
  options = options or {}
  local ctx = { path = {}, depth = 0, max_depth = options.max_depth or config.get("max_depth"), collect_all = options.collect_all, errors = {}, max_errors = options.max_errors or config.get("max_errors"), active = {} }
  local error = self:_validate(value, ctx)
  if ctx.collect_all and #ctx.errors > 0 then return false, ctx.errors end
  if error then return false, error end
  return true
end
function Schema:is_valid(value) local ok = self:validate(value); return ok end
function Schema:parse(value, options)
  options = options or {}
  local ok, validation_error
  if #self._transforms > 0 then
    local ctx = { path = {}, depth = 0, max_depth = options.max_depth or config.get("max_depth"), collect_all = options.collect_all, errors = {}, max_errors = options.max_errors or config.get("max_errors"), active = {}, skip_refinements = true }
    validation_error = self:_validate(value, ctx)
    ok = not validation_error and (not ctx.collect_all or #ctx.errors == 0)
    if ctx.collect_all and #ctx.errors > 0 then validation_error = ctx.errors end
  else
    ok, validation_error = self:validate(value, options)
  end
  if not ok then return nil, validation_error end
  local result = value
  for _, transform in ipairs(self._transforms) do
    local success, transformed = pcall(transform, result)
    if not success then return nil, errors.new({ code = "constraint_failed", message = "transformation failed", expected = self.kind, received = type(result) }) end
    result = transformed
  end
  for _, refinement in ipairs(self._refinements) do
    local success, valid, message = pcall(refinement.check, result)
    if not success or not valid then return nil, errors.new({ code = refinement.code or "constraint_failed", message = message or refinement.message or "refinement failed", expected = self.kind, received = type(result) }) end
  end
  return result
end
function Schema:check(value, options) local result, error = self:parse(value, options); return error and { ok = false, error = error } or { ok = true, value = result } end
function Schema:assert(value, options)
  local result, validation_error = self:parse(value, options); if validation_error then error(validation_error, 0) end; return result
end
function Schema:optional() local result = clone(self); result._optional = true; return result end
function Schema:nullable() local result = clone(self); result._nullable = true; return result end
function Schema:or_else(other) return require("guardrail.validators").union({ self, other }) end
function Schema:refine(check, message)
  local result = clone(self); local refinement = type(check) == "table" and check or { check = check, message = message }
  if type(refinement.check) ~= "function" then error("refine expects a function or descriptor", 2) end
  result._refinements[#result._refinements + 1] = refinement; return result
end
function Schema:transform(fn) local result = clone(self); result._transforms[#result._transforms + 1] = fn; return result end
function Schema:describe()
  return { version = 1, kind = self.kind, optional = self._optional or false, nullable = self._nullable or false, constraints = self.constraints or {}, metadata = self.metadata or {} }
end

local M = {}
function M.new(kind, validate, constraints, metadata)
  return setmetatable({ kind = kind, _validate_inner = validate, constraints = constraints or {}, metadata = metadata or {}, _refinements = {}, _transforms = {} }, Schema)
end
function M.issue(ctx, fields) return issue(ctx, fields) end
function M.child(ctx, key)
  return { path = require("guardrail.path").append(ctx.path, key), depth = ctx.depth + 1, max_depth = ctx.max_depth, collect_all = ctx.collect_all, errors = ctx.errors, max_errors = ctx.max_errors, active = ctx.active, skip_refinements = ctx.skip_refinements }
end
function M.is_schema(value) return getmetatable(value) == Schema end
function M.compat() return compat end
return M
