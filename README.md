# guardrail.lua

<p align="center">
  <img src="assets/guardrail-logo.png" width="220" alt="guardrail.lua logo: a protective rail and validation checkmark" />
</p>

<p align="center">Runtime contracts and structured validation for Lua.</p>

<p align="center">
  <a href="https://github.com/magnexis/guardrail.lua/actions/workflows/test.yml"><img src="https://github.com/magnexis/guardrail.lua/actions/workflows/test.yml/badge.svg" alt="CI status" /></a>
  <a href="https://luarocks.org/modules/magnexis/guardrail"><img src="https://img.shields.io/luarocks/v/magnexis/guardrail?label=LuaRocks" alt="LuaRocks version" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-3b82f6.svg" alt="MIT license" /></a>
  <a href="https://www.lua.org/"><img src="https://img.shields.io/badge/Lua-5.1--5.4%20%7C%20LuaJIT-000080.svg" alt="Lua 5.1 through 5.4 and LuaJIT" /></a>
</p>

[![CI](https://github.com/magnexis/guardrail.lua/actions/workflows/test.yml/badge.svg)](https://github.com/magnexis/guardrail.lua/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Lua 5.1–5.4](https://img.shields.io/badge/Lua-5.1--5.4%20%7C%20LuaJIT-blue.svg)](https://www.lua.org/)

Runtime contracts and structured validation for Lua.

```lua
local guard = require("guardrail")

local withdraw = guard.contract({
  name = "withdraw",
  args = { guard.table({ balance = guard.number({ min = 0 }) }), guard.number({ positive = true }) },
  requires = function(account, amount) return account.balance >= amount, "insufficient funds" end,
  returns = guard.number({ min = 0 })
}, function(account, amount)
  account.balance = account.balance - amount
  return account.balance
end)
```

## Installation

```sh
luarocks install guardrail
```

For a checkout, run `luarocks make guardrail-scm-1.rockspec`. Source lives under `guardrail`; LuaRocks installs it as `guardrail`. Release metadata is in `guardrail-0.1.0-1.rockspec`; see [RELEASE.md](RELEASE.md).

The official package page is [LuaRocks: magnexis/guardrail](https://luarocks.org/modules/magnexis/guardrail).

## Why guardrail?

Lua's flexibility is a feature. Guardrail adds explicit checks where flexibility meets untrusted input or important state: configuration, plugin APIs, network responses, mutable state, and public function boundaries. It is dependency-free, installs no globals, and is not a static type system.

Use it to validate data with nested error paths, preserve multiple returns in contracts, protect state mutations with invariants, and generate LuaLS/EmmyLua annotations from reusable schemas.

## Schemas

Use `is_valid`, `validate`, `parse`, `check`, or `assert` on every schema. `validate` returns `true`, or `false, GuardrailError`; validation never changes its input.

```lua
local user = guard.table({
  id = guard.integer({ positive = true }),
  username = guard.string({ min_length = 3, max_length = 30, pattern = "^[%w_]+$" }),
  email = guard.optional(guard.string()),
  role = guard.enum({ "admin", "member", "guest" })
})

local ok, err = user:validate({ id = 1, username = "magnexis", role = "member" })
```

Available constructors: `any`, `nil_value`, `boolean`, `string`, `number`, `integer`, `function_value`, `thread`, `userdata`, `literal`, `enum`, `array`, `tuple`, `map`, `table`, `union`, `custom`, and `lazy`.

| Need | API |
| --- | --- |
| Validate without throwing | `schema:validate(value)` |
| Parse an explicit transformation | `schema:parse(value)` |
| Throw a structured error | `schema:assert(value)` |
| Collect independent errors | `schema:validate(value, { collect_all = true })` |
| Describe a schema | `guard.describe(schema)` |

Optional fields may be omitted from a table schema. Nullable values accept an explicit `nil`; in ordinary Lua tables that is indistinguishable from an absent key, so nullable is chiefly useful in contracts and tuples. Use `schema:optional()`, `schema:nullable()`, or their `guard` helpers. Compose unions with `guard.union({...})` or `schema:or_else(other)`.

Tables reject unknown fields by default. Set `{ allow_unknown = true }` to allow them, or `{ strip_unknown = true }` to return a shallow copy containing only declared fields from `parse`/`assert`. Arrays reject sparse and non-numeric tables by default; pass `{ allow_sparse = true }` when needed.

## Contracts and invariants

Contracts validate arguments, preconditions, returns, and postconditions. Multiple returns require `guard.returns({ ... })` and preserve nils.

```lua
local divide = guard.contract({
  name = "divide",
  args = { guard.number(), guard.number():refine(function(v) return v ~= 0 end, "divisor cannot be zero") },
  returns = guard.returns({ guard.number(), guard.optional(guard.string()) })
}, function(a, b) return a / b, nil end)

local balance = guard.invariant({ name = "non_negative", check = function(a) return a.balance >= 0 end })
guard.with_invariant(balance, account, function() account.balance = account.balance - 5 end)
```

Application errors raised by wrapped functions are intentionally preserved, not converted into contract errors.

## Errors and configuration

Errors are tables with stable `code`, `message`, `path`, `path_string`, `expected`, and `received` fields. Use `guard.format_error(err)` for a readable diagnostic or `guard.error_to_table(err)` for serialization. Values are not included by default.

```lua
guard.configure({ mode = "production", max_depth = 100, max_errors = 50, include_values_in_errors = false })
guard.disable() -- bypasses contracts and schema validation globally
guard.with_disabled(function() end)
```

`disabled` mode is process-global and should not be toggled around concurrently running coroutines.

## Boundary validation

Named boundary helpers add a `boundary` field to failures without changing validation behavior.

```lua
local ok, err = guard.validate_config(config_schema, config)
if not ok then return nil, guard.format_error(err, { compact = true }) end
```

## Transformations

Validation never mutates input. Transformations are opt-in through `parse` or `assert`; they run before refinements. `{ strip_unknown = true }` creates a shallow object containing only declared fields.

```lua
local name = guard.string()
  :transform(function(value) return value:match("^%s*(.-)%s*$") end)
  :refine(function(value) return #value >= 3 end, "name is too short")

local normalized, err = name:parse("  Ada  ")
```

## Tooling

`guard.describe(schema)` provides versioned introspection. Generate LuaLS/EmmyLua text with `require("guardrail.annotations").generate("User", user_schema)`, then write it with `write_file`. Boundary helpers (`validate_config`, `validate_plugin`, `validate_response`, and `validate_event`) attach context without changing validation behavior.

## Compatibility and security

The runtime core has no dependencies and targets Lua 5.1–5.4 and LuaJIT 2.x. It avoids invoking values or `__tostring` during validation, detects active table cycles, and enforces a validation-depth limit. Validate untrusted data with bounded schemas and avoid enabling value previews for secrets.

## Development

Run `lua spec/run.lua` locally. Lint both rockspecs with `luarocks lint guardrail-scm-1.rockspec` and `luarocks lint guardrail-0.1.0-1.rockspec`. See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), and [RELEASE.md](RELEASE.md). Licensed under [MIT](LICENSE).
