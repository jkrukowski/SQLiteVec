# SQLiteVec

Swift bindings for [sqlite-vec](https://github.com/asg017/sqlite-vec)

## Installation

### Swift Package Manager

The [Swift Package Manager](https://www.swift.org/documentation/package-manager/) is a tool for managing the distribution of Swift code.

1. Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/jkrukowski/SQLiteVec", from: "0.0.2")
]
```

2. Build your project:

```sh
$ swift build
```

## Usage

```swift
import SQLiteVec

// initialize the library first
try SQLiteVec.initialize()

// example data
let data: [(index: Int, vector: [Float])] = [
    (1, [0.1, 0.1, 0.1, 0.1]),
    (2, [0.2, 0.2, 0.2, 0.2]),
    (3, [0.3, 0.3, 0.3, 0.3]),
    (4, [0.4, 0.4, 0.4, 0.4]),
    (5, [0.5, 0.5, 0.5, 0.5]),
]
let query: [Float] = [0.3, 0.3, 0.3, 0.3]

// create a database
let db = try Database(.inMemory)

// create a table and insert data
try await db.execute("CREATE VIRTUAL TABLE vec_items USING vec0(embedding float[4])")
for row in data {
    try await db.execute(
        """
            INSERT INTO vec_items(rowid, embedding) 
            VALUES (?, ?)
        """, 
        params: [row.index, row.vector]
    )
}

// query the embeddings
let result = try await db.query(
    """
        SELECT rowid, distance 
        FROM vec_items 
        WHERE embedding MATCH ? 
        ORDER BY distance 
        LIMIT 3
    """,
    params: [query]
)

// print the result
print(result)
```

It should print the following result:

```bash
[
    ["distance": 0.0, "rowid": 3],
    ["distance": 0.19999998807907104, "rowid": 4],
    ["distance": 0.20000001788139343, "rowid": 2]
]
```

## Testing

```bash
$ swift test
```

To test it on docker swift image run:

```bash
$ docker build -f DOCKERFILE -t linuxbuild . && docker run linuxbuild
```

## Acknowledgements

This project is based on and uses some of the code from:

- [SQLite.swift](https://github.com/stephencelis/SQLite.swift)
- [SQLiteDB](https://github.com/FahimF/SQLiteDB)
