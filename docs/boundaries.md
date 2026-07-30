# Boundary validation

`validate_config`, `validate_plugin`, `validate_response`, and `validate_event` are validation helpers that add a `boundary` field to errors. They do not change schema semantics or silently transform data.

```lua
local ok, err = guard.validate_config(config_schema, config)
if not ok then return nil, guard.format_error(err) end
```
