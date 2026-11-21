# Ordinary SQL scalar boundaries

NUMERIC(38,9), JSON and INTERVAL use native Table descriptors and literal codecs.
The decimal exceeds floating-point integer precision; JSON retains that integer
and distinguishes JSON null from SQL NULL. Intervals preserve signed months, days
and nanoseconds, including each component's boundary. An independently authored
SQL oracle reorders JSON keys and spells NUMERIC as DECIMAL.

The compiled case compares exact typed values. Installed qualification also checks
neutral cell encodings and the decimal descriptor, source removal and restart.
The runner rejects decimal overflow/inexact scale, duplicate JSON keys and an
out-of-range interval component before publication. This does not add source
scalar parameters/domains, JSON extraction, interval ordering, ordered-program
representations or a new migration policy.
