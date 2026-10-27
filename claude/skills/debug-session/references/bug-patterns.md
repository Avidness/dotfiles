# Where subtle bugs hide

Check these when the obvious bugs are fixed. Planted-bug exercises nearly always include several.

## Numbers and money
- Floats for money; `round()` / `toFixed()` before summing; rounding per line vs per total
- Integer division, truncation, `parseInt` without radix, `"10" > "9"` string comparison
- Sign errors: discounts, refunds, credits, debit/credit direction

## Boundaries
- `<` vs `<=` on limits, lengths, quantities; off-by-one in loops, slices, pagination (page 0 vs 1, last page)
- Empty list, single item, null/None/undefined, zero, negative, very large values
- Inclusive vs exclusive date ranges

## Time
- Naive vs timezone-aware datetimes; local time vs UTC; DST changes
- `new Date("2024-01-02")` parsed as UTC, displayed in local time
- Expiry checks with the wrong comparison

## Async and state
- Missing `await`; promises not awaited in loops (`forEach(async ...)`)
- Race conditions on read-then-write (check balance, then update)
- Shared mutable state between requests; caches never invalidated
- Python mutable default arguments (`def f(x=[])`)

## Errors
- Swallowed exceptions (`except: pass`, empty `catch`)
- Errors logged but a success response returned
- Wrong HTTP status (200 on error, 500 for bad input, 404 vs 403)

## Logic
- Wrong operator (`and`/`or`, `&&`/`||`), inverted condition, early `return` skipping work
- Copy-paste bugs: the second branch uses the first branch's variable
- JS: `==` vs `===`, `sort()` without a numeric comparator, `this` binding
- Python: `is` vs `==`, shadowed names, generator consumed twice

## Security
- Missing auth or ownership checks on one route
- String-built SQL, unescaped HTML, path traversal in file names
- Secrets in code or logs

## Data
- Missing transaction around multi-row writes; partial updates on error
- Unique constraints missing; duplicates allowed
- Case or whitespace differences in lookups (emails, codes)
