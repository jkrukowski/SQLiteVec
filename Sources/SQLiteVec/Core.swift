import CSQLiteVec
import Foundation

/// Initializes the SQLiteVec library.
///
/// This function must be called before using any other SQLiteVec functions.
/// It sets up the necessary internal state for the library to function correctly.
///
/// - Throws: An error of type `SQLiteVecError` if initialization fails.
public func initialize() throws {
    try SQLiteVecError.check(
        CSQLiteVec.core_vec_init()
    )
}

let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
