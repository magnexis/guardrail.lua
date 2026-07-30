# Release checklist

1. Update `guard.VERSION`, `CHANGELOG.md`, and `guardrail-<version>-1.rockspec` together.
2. Run `lua spec/run.lua` on supported Lua versions and LuaJIT.
3. Run `luarocks pack guardrail-<version>-1.rockspec` and inspect the archive contents.
4. Install the generated rock in a clean LuaRocks tree and rerun the test command.
5. Create an annotated `v<version>` tag, then publish only after confirming package name, repository URL, and license.

The LuaRocks package name is `guardrail`; the public module stays `require("guardrail")`. This avoids an invalid filename/package mismatch caused by treating `.lua` as part of the LuaRocks package identifier.
