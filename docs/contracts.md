# Contracts

`requires` receives original positional arguments. `ensures` receives `(results, args)`, each a packed table with an `n` field so nil values are retained. Contract failures are `GuardrailError` tables; errors raised by the wrapped function are preserved.
