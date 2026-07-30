# Architecture

`src/guardrail/init.lua` is the intentional public surface. The dependency-free core separates schema mechanics, validators, contracts, invariants, errors, formatting, and compatibility. Validators share a context carrying path, active-table cycle tracking, depth, and collection limits. Optional annotation writing is isolated in `guardrail.annotations`.

The source layout follows the conventional LuaRocks `src/` structure. Individual validator import paths are available for tooling, while `require("guardrail")` remains the supported application API.
