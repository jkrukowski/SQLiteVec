import XCTest

@testable import SQLiteVec

final class CoreTests: XCTestCase {
    func testInitialize() throws {
        try XCTAssertNoThrow(SQLiteVec.initialize(), "Initializing should not throw")
    }

    func testLoadedExtensions() async throws {
        try SQLiteVec.initialize()
        let db = try Database(.inMemory)
        let result = try await db.query("PRAGMA module_list")
        let extensionNames = result.compactMap { $0["name"] as? String }

        XCTAssertTrue(extensionNames.contains("vec_each"), "vec_each should be loaded")
        XCTAssertTrue(extensionNames.contains("vec0"), "vec0 should be loaded")
    }
}
