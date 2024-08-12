import CSQLiteVec
import Foundation

public func initialize() throws {
    try SQLiteVecError.check(
        CSQLiteVec.core_vec_init()
    )
}
