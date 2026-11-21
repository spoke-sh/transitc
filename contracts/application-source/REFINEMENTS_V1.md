# Bounded callable obligations v1

A guard or atomic procedure can declare ordered `REQUIRES` clauses before its
body and `ENSURES` clauses after it. Each clause has an explicit refusal code:

```sql
CREATE PROCEDURE Identity(amount BIGINT) RETURNS BIGINT
REQUIRES amount IS NOT NULL ELSE 'MissingAmount'
REQUIRES amount >= 1 AND amount <= 10 ELSE 'AmountBounds'
ENSURES result = amount ELSE 'ChangedAmount'
AS BEGIN ATOMIC RETURN amount; END;
```

The admitted terms are a scalar parameter `IS NOT NULL`, a BIGINT parameter
compared with a constant signed 64-bit integer, and equality/inequality between
scalar parameters of exactly matching type and nominal domain whose base type
admits equality. JSON and INTERVAL comparisons remain refused; JSON parameters
may use the non-nullness obligation. Postconditions
also admit `result`, which names the declared scalar return value. A parameter
named `result` is refused on contracted helpers to avoid ambiguity. Clauses may
conjoin at most 16 terms; each phase has at most 16 clauses. The clauses use
`ELSE 'code'`, with 1–128 UTF-8 bytes, and preserve declaration order.

This profile does not admit OR, arbitrary predicates, arithmetic inside a term,
resource observations, field paths, variable integer bounds or comparisons that
cross domains. Plain functions stay pure expressions and do not admit these
ordered validation clauses. Tags and whole-row presence use the separately
specified runtime MATCH and ONE/OPTIONAL rules.

Every admitted clause is a pending runtime obligation. Lowering evaluates call
arguments once in source order, emits preconditions, inlines the checked body,
captures its result once, then emits postconditions before the caller continues.
There is no theorem solver or speculative elimination. The native binder checks
physical operations and the source checker retains nominal equality. Unknown
bindings/types/predicate forms reject before publication. A validated clause
constrains that immutable call value only; it creates no persistent resource,
existence, transaction or authority fact.

Ordinary REQUIRE owns NULL behavior and refusal order. Argument evaluation errors
precede preconditions; body errors precede postconditions. A failed postcondition
inside an atomic caller rolls back the helper's staged writes/appends and the
caller's other staged effects. Inlining adds neither a transaction nor a privilege
grant. A later observation of mutable state needs its own ordinary runtime check.

`application-refinements` compares a source procedure with independently authored
SQL, including NULL, both integer bounds and a failed return after a staged
append. Independent typed comparisons cover local/imported calls, event order,
resources and negative controls. Allocation-failure and grammar/formatter checks
accompany the profile. These are bounded comparisons, not a proof of arbitrary
refinement implication or full compiler correctness.
