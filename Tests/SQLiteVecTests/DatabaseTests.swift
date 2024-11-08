import XCTest

@testable import SQLiteVec

final class DatabaseTests: XCTestCase {
    private let accuracy: Double = 0.000001

    override func setUpWithError() throws {
        try super.setUpWithError()
        try SQLiteVec.initialize()
    }

    func testVersionAndBuildInfo() async throws {
        let db = try Database(.inMemory)
        let version = await db.version()
        XCTAssertNotNil(version, "version should not be nil")
        let buildInfo = await db.buildInfo()
        XCTAssertNotNil(buildInfo, "buildInfo should not be nil")
    }

    func testSimpleQuery() async throws {
        let db = try Database(.inMemory)
        try await db.execute(
            """
            CREATE TABLE users (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE
            )
            """
        )
        try await db.execute("INSERT INTO users(id, name) VALUES (?, ?)", params: [1, "John"])
        try await db.execute("INSERT INTO users(id, name) VALUES (?, ?)", params: [2, "Jane"])
        try await db.execute("INSERT INTO users(id, name) VALUES (?, ?)", params: [3, "Jim"])

        let result = try await db.query("SELECT * FROM users WHERE name = ?", params: ["Jane"])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0]["id"] as? Int, 2)
        XCTAssertEqual(result[0]["name"] as? String, "Jane")
    }

    func testSubQuery() async throws {
        let db = try Database(.inMemory)
        try await db.execute(
            """
            CREATE TABLE users (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE
            )
            """
        )
        try await db.execute("INSERT INTO users(id, name) VALUES (?, ?)", params: [1, "John"])
        try await db.execute("INSERT INTO users(id, name) VALUES (?, ?)", params: [2, "Jane"])
        try await db.execute("INSERT INTO users(id, name) VALUES (?, ?)", params: [3, "Jim"])

        let result = try await db.query(
            """
                SELECT * FROM (
                    SELECT * FROM users
                    WHERE name LIKE 'J%'
                ) as sub WHERE sub.id = ?
            """,
            params: [2]
        )
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0]["id"] as? Int, 2)
        XCTAssertEqual(result[0]["name"] as? String, "Jane")
    }

    func testQuantizeBinary() async throws {
        let db = try Database(.inMemory)
        let result = try await db.query(
            """
                SELECT vec_quantize_binary(?) as quantized_vector
            """,
            params: [[-0.73, -0.80, 0.12, -0.73, 0.79, -0.11, 0.23, 0.97] as [Float]]
        )
        XCTAssertEqual(result.count, 1)
        let data = try XCTUnwrap(result[0]["quantized_vector"] as? Data)
        XCTAssertEqual(data.bytes, [212])
    }

    func testVectorInit() async throws {
        let db = try Database(.inMemory)
        let result1 = try await db.query(
            """
                SELECT vec_int8(?) as result
            """,
            params: [
                [0, 1, 2, 3, 4] as [Int8]
            ]
        )
        let data1 = try XCTUnwrap(result1[0]["result"] as? Data)
        let array1: [Int8] = data1.toArray()
        XCTAssertEqual(array1, [0, 1, 2, 3, 4])

        let result2 = try await db.query(
            """
                SELECT vec_bit(?) as result
            """,
            params: [
                [false, false, false, true, true] as [Bool]
            ]
        )
        let data2 = try XCTUnwrap(result2[0]["result"] as? Data)
        let array2: [Bool] = data2.toArray()
        XCTAssertEqual(array2, [false, false, false, true, true])

        let result3 = try await db.query(
            """
                SELECT vec_f32(?) as result
            """,
            params: [
                [0, 1, 2, 3, 4] as [Float]
            ]
        )
        let data3 = try XCTUnwrap(result3[0]["result"] as? Data)
        let array3: [Float] = data3.toArray()
        XCTAssertEqual(array3, [0, 1, 2, 3, 4], accuracy: Float(accuracy))
    }

    func testVectorAddFloat() async throws {
        let db = try Database(.inMemory)
        let result = try await db.query(
            """
                SELECT vec_add(?, ?) as result
            """,
            params: [
                [-0.73, -0.80, 0.12, -0.73, 0.79, -0.11, 0.23, 0.97] as [Float],
                [0.97, -0.73, 0.79, -0.11, 0.23, -0.73, -0.80, 0.12] as [Float],
            ]
        )
        XCTAssertEqual(result.count, 1)
        let data = try XCTUnwrap(result[0]["result"] as? Data)
        let array: [Float] = data.toArray()
        XCTAssertEqual(
            array, [0.24000001, -1.53, 0.91, -0.84000003, 1.02, -0.84000003, -0.57, 1.09],
            accuracy: Float(accuracy)
        )
    }

    func testVectorAddInt8() async throws {
        let db = try Database(.inMemory)
        let result = try await db.query(
            """
                SELECT vec_add(vec_int8(?), vec_int8(?)) as result
            """,
            params: [
                [0, 1, 2, 3] as [Int8],
                [5, 6, 7, 8] as [Int8],
            ]
        )
        XCTAssertEqual(result.count, 1)
        let data = try XCTUnwrap(result[0]["result"] as? Data)
        let array: [Int8] = data.toArray()
        XCTAssertEqual(array, [5, 7, 9, 11])
    }

    func testVectorSubFloat() async throws {
        let db = try Database(.inMemory)
        let result = try await db.query(
            """
                SELECT vec_sub(?, ?) as result
            """,
            params: [
                [-0.73, -0.80, 0.12, -0.73, 0.79, -0.11, 0.23, 0.97] as [Float],
                [0.97, -0.73, 0.79, -0.11, 0.23, -0.73, -0.80, 0.12] as [Float],
            ]
        )
        XCTAssertEqual(result.count, 1)
        let data = try XCTUnwrap(result[0]["result"] as? Data)
        let array: [Float] = data.toArray()
        XCTAssertEqual(
            array, [-1.7, -0.06999999, -0.67, -0.62, 0.56, 0.62, 1.03, 0.85],
            accuracy: Float(accuracy)
        )
    }

    func testVectorSubInt8() async throws {
        let db = try Database(.inMemory)
        let result = try await db.query(
            """
                SELECT vec_sub(vec_int8(?), vec_int8(?)) as result
            """,
            params: [
                [0, 1, 2, 3] as [Int8],
                [9, 3, 8, 0] as [Int8],
            ]
        )
        XCTAssertEqual(result.count, 1)
        let data = try XCTUnwrap(result[0]["result"] as? Data)
        let array: [Int8] = data.toArray()
        XCTAssertEqual(array, [-9, -2, -6, 3])
    }

    func testEmbeddingDistanceQuery() async throws {
        let data: [(index: Int, vector: [Float])] = [
            (1, [0.1, 0.1, 0.1, 0.1]),
            (2, [0.2, 0.2, 0.2, 0.2]),
            (3, [0.3, 0.3, 0.3, 0.3]),
            (4, [0.4, 0.4, 0.4, 0.4]),
            (5, [0.5, 0.5, 0.5, 0.5]),
        ]
        let query: [Float] = [0.3, 0.3, 0.3, 0.3]
        let db = try Database(.inMemory)
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

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0]["distance"] as! Double, 0.0000000, accuracy: accuracy)
        XCTAssertEqual(result[0]["rowid"] as? Int, 3)
        XCTAssertEqual(result[1]["distance"] as! Double, 0.1999999, accuracy: accuracy)
        XCTAssertEqual(result[1]["rowid"] as? Int, 4)
        XCTAssertEqual(result[2]["distance"] as! Double, 0.2000000, accuracy: accuracy)
        XCTAssertEqual(result[2]["rowid"] as? Int, 2)
    }
}
