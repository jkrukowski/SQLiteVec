#!/bin/bash

# Configurable versions
SQLITE_VERSION=3510000
SQLITE_YEAR=2025
SQLITE_VEC_VERSION=0.1.9

# download sqlite amalgamation

curl -o sqlite-amalgamation.zip https://www.sqlite.org/${SQLITE_YEAR}/sqlite-amalgamation-${SQLITE_VERSION}.zip
unzip -q sqlite-amalgamation.zip
SQLITE_DIR=$(unzip -l sqlite-amalgamation.zip | grep -m1 "sqlite-amalgamation-" | awk '{print $4}' | cut -d/ -f1)
cp ${SQLITE_DIR}/sqlite3.c Sources/CSQLiteVec/
cp ${SQLITE_DIR}/sqlite3.h Sources/CSQLiteVec/include/
cp ${SQLITE_DIR}/sqlite3ext.h Sources/CSQLiteVec/include/
rm -rf ${SQLITE_DIR}
rm sqlite-amalgamation.zip

# download sqlite-vec amalgamation

curl -o sqlite-vec-amalgamation.zip -L https://github.com/asg017/sqlite-vec/releases/download/v${SQLITE_VEC_VERSION}/sqlite-vec-${SQLITE_VEC_VERSION}-amalgamation.zip
unzip -q sqlite-vec-amalgamation.zip
mv sqlite-vec.c Sources/CSQLiteVec/
mv sqlite-vec.h Sources/CSQLiteVec/include/
rm sqlite-vec-amalgamation.zip
