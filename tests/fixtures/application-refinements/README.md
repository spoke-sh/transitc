# Bounded callable obligations

`Bounded` accepts a non-null amount from 1 through 10 and requires its returned
value to equal that amount. Five isolated cases cover success, SQL NULL, both
bounds and refusal after a staged append. The two Streams must remain empty on
any refusal. `expected.sql` independently spells the ordinary ordered validation.

Run `transitc test -f tests/fixtures/application-refinements/build.transit`.
The integration runner also removes source before execution, compares hand SQL,
retains each request result and checks both Streams after restart. It preserves
the standard case/suite and installed observation deadlines.
