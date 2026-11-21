#!/bin/sh
# Run in an empty temporary directory with Git and transitc on PATH.
set -eu
compiler=${TRANSITC:-transitc}
mkdir library application
cat > library/build.transit <<'SQL'
CREATE PUBLIC MODULE Rows() AS BEGIN
  CREATE PUBLIC TABLE items (id BIGINT);
END;
SQL
git -C library init --quiet
git -C library add build.transit
git -C library -c user.name=Example -c user.email=example@example.invalid commit --quiet -m 'Pin example module'
revision=$(git -C library rev-parse HEAD)
repository=$(cd library && pwd -P)
cat > application/build.transit <<SQL
DEPENDENCY common FROM '$repository' REVISION '$revision';
IMPORT shared FROM PACKAGE common FILE 'build.transit';
CREATE TARGET default AS BEGIN
  USE shared.Rows();
END;
SQL
cd application
"$compiler" build --fetch
"$compiler" build --check
mv ../library ../library-unavailable
# The origin is now unavailable; the lock and verified cache suffice.
"$compiler" build --out reviewed
