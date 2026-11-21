# Exact callable module arguments

Two explicitly named instances use an imported procedure through a module argument
and a nested procedure call. Both implementations declare exactly the same Table
INSERT and Stream PRODUCE operations and the same pre/postconditions; effect
order in the signature is immaterial. All resource bindings are explicit.

`expected.sql` independently expands one instance. The integration journey
compares both generated instances, ordered refusals, returning-helper rollback,
restart and current-rights denial after removing the source tree. The isolated
suite focuses on one imported returning callable and its Stream rollback; the
installed journey retains both Table and Stream effects and nested calls. It
retains the standard 30-second case and five-minute suite budgets.
