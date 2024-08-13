import CSQLiteVec
import Foundation

public func initialize() throws {
    try SQLiteVecError.check(
        CSQLiteVec.core_vec_init()
    )
}

let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
