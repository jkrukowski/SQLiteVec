#!/bin/bash

# download sqlite amalgamation

curl -o sqlite-amalgamation.zip https://www.sqlite.org/2024/sqlite-amalgamation-3470000.zip
unzip sqlite-amalgamation.zip
cp sqlite-amalgamation-3470000/sqlite3.c Sources/CSQLiteVec/
cp sqlite-amalgamation-3470000/sqlite3.h Sources/CSQLiteVec/include/
cp sqlite-amalgamation-3470000/sqlite3ext.h Sources/CSQLiteVec/include/
rm -rf sqlite-amalgamation-3470000
rm sqlite-amalgamation.zip

# download sqlite-vec amalgamation

curl -o sqlite-vec-amalgamation.zip -L https://github.com/asg017/sqlite-vec/releases/download/v0.1.3/sqlite-vec-0.1.3-amalgamation.zip
unzip sqlite-vec-amalgamation.zip
mv sqlite-vec.c Sources/CSQLiteVec/
mv sqlite-vec.h Sources/CSQLiteVec/include/
rm sqlite-vec-amalgamation.zip
