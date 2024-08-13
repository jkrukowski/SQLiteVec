import XCTest
@testable import SQLiteVec

final class DatabaseTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        try SQLiteVec.initialize()
    }

    func testSimpleQuery() async throws {
        let db = try Database(.inMemory)
        try await db.execute("""
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
}
