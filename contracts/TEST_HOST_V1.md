# Compiled test host v1

Transit owns the [compiled-case contract](https://github.com/spoke-sh/transit/blob/main/contracts/TEST_HOST_V1.md)
and its executable schema in `transit-test-protocol`. The compiler and workspace
consume that package from their exact upstream source pin.

`transitc test` compiles the complete suite, schedules bounded cases, validates
runtime identities and terminal reports, enforces deadlines, joins child
processes and cleans up its disposable case directories. Transit executes only
compiled SQL and typed expectations through its native owners. The runtime has
no dependency on transitc or its source repositories.
