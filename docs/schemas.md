# Schemas

Schemas are immutable values. Fluent calls return derived schemas. `table` rejects unknown keys by default; it does not strip or mutate values. Use `validate(value, { collect_all = true, max_errors = 50 })` to collect independent failures.
