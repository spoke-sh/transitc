# Programs in compile-time variant arms

The selected Machine constructor emits only `machine_route`. The unselected Site
arm is nevertheless bound and checked, including its nominal writes and control
statements. Scalar holes use type-only inputs during checking; emitted SQL has
only the original Queue fields and concrete scalar literals.

The helper in the Queue predicate deliberately ignores its argument; the helper
inside the atomic body evaluates its argument once. Both argument paths still
check the declared nominal type. The unit and grammar suites reject a swapped
Table in the unselected arm, unsupported nominal arithmetic, wrong physical
values, forged internal input fields and control of an unknown program. Allocation
failure coverage includes temporary catalog construction.
