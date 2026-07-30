rockspec_format = "3.0"
package = "guardrail"
version = "0.1.0-1"
source = { url = "git://github.com/magnexis/guardrail-lua", tag = "v0.1.0" }
description = {
  summary = "Runtime contracts and structured validation for Lua.",
  detailed = "A dependency-free runtime validation library for Lua 5.1 through 5.4 and LuaJIT.",
  homepage = "https://github.com/magnexis/guardrail-lua",
  license = "MIT"
}
dependencies = { "lua >= 5.1" }
build = { type = "builtin", modules = {
  ["guardrail"] = "src/guardrail/init.lua", ["guardrail.compatibility"] = "src/guardrail/compatibility.lua",
  ["guardrail.config"] = "src/guardrail/config.lua", ["guardrail.path"] = "src/guardrail/path.lua",
  ["guardrail.errors"] = "src/guardrail/errors.lua", ["guardrail.schema"] = "src/guardrail/schema.lua",
  ["guardrail.validators"] = "src/guardrail/validators/init.lua", ["guardrail.validators.primitive"] = "src/guardrail/validators/primitive.lua",
  ["guardrail.validators.string"] = "src/guardrail/validators/string.lua", ["guardrail.validators.number"] = "src/guardrail/validators/number.lua",
  ["guardrail.validators.table"] = "src/guardrail/validators/table.lua", ["guardrail.validators.array"] = "src/guardrail/validators/array.lua",
  ["guardrail.validators.tuple"] = "src/guardrail/validators/tuple.lua", ["guardrail.validators.map"] = "src/guardrail/validators/map.lua",
  ["guardrail.validators.union"] = "src/guardrail/validators/union.lua", ["guardrail.validators.literal"] = "src/guardrail/validators/literal.lua",
  ["guardrail.validators.enum"] = "src/guardrail/validators/enum.lua", ["guardrail.validators.custom"] = "src/guardrail/validators/custom.lua",
  ["guardrail.validators.lazy"] = "src/guardrail/validators/lazy.lua", ["guardrail.contract"] = "src/guardrail/contract.lua",
  ["guardrail.invariant"] = "src/guardrail/invariant.lua", ["guardrail.formatter"] = "src/guardrail/formatter.lua",
  ["guardrail.annotations"] = "src/guardrail/annotations.lua"
} }
test = { type = "command", command = "lua spec/run.lua" }
