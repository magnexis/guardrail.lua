# Security

Guardrail is designed for defensive validation, not sandboxing. It does not execute validated values or call `__tostring` while constructing normal errors. Input values are excluded from serialized errors by default.

For untrusted input, keep `max_depth` and `max_errors` bounded, use exact table schemas, and avoid custom validators that execute untrusted callbacks. Validation cannot protect against resource exhaustion caused before Lua receives a value, hostile runtime extensions, or unsafe behavior in an application callback.

Report security concerns privately to the repository maintainers rather than opening a public issue.
