# Exact native numeric expressions

The compiled case and independent SQL compare DECIMAL_ADD with REJECT and
DECIMAL_RESCALE with HALF_EVEN, explicit output precision/scale and SQL NULL.
The installed scalar harness also checks Inexact and Overflow failures. These
are ordinary SQL functions; source arithmetic and implicit rescaling stay refused.
