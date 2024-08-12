import CSQLiteVec
import Foundation

enum SQLiteVecError: Error {
    static let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]

    case error(code: Int32)

    static func check(_ code: Int32) throws {
        if successCodes.contains(code) {
            return
        }
        throw SQLiteVecError.error(code: code)
    }
}
