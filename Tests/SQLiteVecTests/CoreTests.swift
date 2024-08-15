import XCTest
@testable import SQLiteVec

final class CoreTests: XCTestCase {
    func testInitialize() throws {
        try XCTAssertNoThrow(SQLiteVec.initialize(), "Initializing should not throw")
    }
}
