# Performance

Successful validation avoids error formatting and tracebacks. Measure your actual schemas using `lua benchmarks/basic.lua`; contract validation adds calls proportional to the number of declared arguments and returns.
