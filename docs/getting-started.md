# Getting started

Install the rock with LuaRocks, require `guardrail`, define a schema, then use `assert` at a trusted boundary. Prefer `validate` where an application should recover and format the returned error for a user or log.

```lua
local guard = require("guardrail")
local port = guard.integer({ min = 1, max = 65535 })
local ok, err = port:validate(8080)
```

Use `parse` only when an explicitly declared transformation is needed. `strip_unknown` returns a shallow new table; it never changes the caller's table.
