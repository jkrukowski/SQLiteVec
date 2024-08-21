import CSQLiteVec
import Foundation

public actor Database {
    private var _handle: OpaquePointer?

    public init(_ location: Location = .inMemory, readonly: Bool = false) throws {
        let flags = readonly ? SQLITE_OPEN_READONLY : (SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE)
        try SQLiteVecError.check(
            sqlite3_open_v2(
                location.description,
                &_handle,
                flags | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_URI,
                nil
            )
        )
    }

    public func version() -> String? {
        do {
            let result = try query("SELECT vec_version() as version")
            guard let first = result.first, let value = first["version"] as? String else {
                return nil
            }
            return value
        } catch {
            return nil
        }
    }

    public func buildInfo() -> String? {
        do {
            let result = try query("SELECT vec_debug() as info")
            guard let first = result.first, let value = first["info"] as? String else {
                return nil
            }
            return value
        } catch {
            return nil
        }
    }

    public func execute(_ sql: String, params: [Any] = []) throws {
        let stmt = try prepare(sql, params: params)
        try execute(stmt)
    }

    public func query(_ sql: String, params: [Any] = []) throws -> [[String: Any]] {
        let stmt = try prepare(sql, params: params)
        return query(stmt)
    }

    private func prepare(_ sql: String, params: [Any]) throws -> OpaquePointer {
        var stmt: OpaquePointer?
        try SQLiteVecError.check(
            sqlite3_prepare_v2(_handle, sql, -1, &stmt, nil),
            _handle
        )
        let paramCount = Int(sqlite3_bind_parameter_count(stmt))
        guard paramCount == params.count else {
            fatalError("Failed to bind parameters, counts did not match, sql: \(paramCount), parameters: \(params.count)")
        }
        for (index, param) in params.enumerated() {
            let result: Int32
            switch param {
            case let value as String:
                result = sqlite3_bind_text(stmt, Int32(index + 1), value, -1, SQLITE_TRANSIENT)
            case let value as Data:
                let bytes = value.bytes
                result = sqlite3_bind_blob(stmt, Int32(index + 1), bytes, Int32(bytes.count), SQLITE_TRANSIENT)
            case let value as Bool:
                result = sqlite3_bind_int(stmt, Int32(index + 1), value ? 1 : 0)
            case let value as Double:
                result = sqlite3_bind_double(stmt, Int32(index + 1), value)
            case let value as Int:
                result = sqlite3_bind_int(stmt, Int32(index + 1), Int32(value))
            case let value as [Float]:
                result = sqlite3_bind_blob(stmt, Int32(index + 1), value, Int32(MemoryLayout<Float>.stride * value.count), SQLITE_STATIC)
            default:
                result = sqlite3_bind_null(stmt, Int32(index + 1))
            }
            try SQLiteVecError.check(result, _handle)
        }
        return stmt!
    }

    private func execute(_ stmt: OpaquePointer) throws {
        defer { sqlite3_finalize(stmt) }
        try SQLiteVecError.check(sqlite3_step(stmt))
    }

    private func query(_ stmt: OpaquePointer) -> [[String: Any]] {
        defer { sqlite3_finalize(stmt) }
        var rows = [[String: Any]]()
        var columnInfo: (names: [String], types: [Int32])?
        while sqlite3_step(stmt) == SQLITE_ROW {
            if columnInfo == nil {
                let columnCount = sqlite3_column_count(stmt)
                var names = [String]()
                var types = [Int32]()
                for index in 0 ..< columnCount {
                    names.append(String(cString: sqlite3_column_name(stmt, index)))
                    types.append(sqlite3_column_type(stmt, index))
                }
                columnInfo = (names, types)
            }
            if let columnInfo {
                var row = [String: Any]()
                for (index, value) in zip(columnInfo.names, columnInfo.types).enumerated() {
                    let (name, type) = value
                    if let value = columnValue(index: Int32(index), type: type, stmt: stmt) {
                        row[name] = value
                    }
                }
                rows.append(row)
            }
        }
        return rows
    }

    private func columnValue(index: Int32, type: Int32, stmt: OpaquePointer) -> Any? {
        switch type {
        case SQLITE_INTEGER:
            return Int(sqlite3_column_int64(stmt, index))
        case SQLITE_FLOAT:
            return sqlite3_column_double(stmt, index)
        case SQLITE_BLOB:
            if let bytes = sqlite3_column_blob(stmt, index) {
                let length = sqlite3_column_bytes(stmt, index)
                return Data(bytes: bytes, count: Int(length))
            } else {
                return Data()
            }
        case SQLITE_NULL:
            return nil
        default:
            return String(cString: UnsafePointer(sqlite3_column_text(stmt, index)))
        }
    }

    deinit {
        sqlite3_close(_handle)
    }
}

public extension Database {
    /// The location of a SQLite database.
    enum Location {
        /// An in-memory database (equivalent to `.uri(":memory:")`).
        ///
        /// See: <https://www.sqlite.org/inmemorydb.html#sharedmemdb>
        case inMemory

        /// A temporary, file-backed database (equivalent to `.uri("")`).
        ///
        /// See: <https://www.sqlite.org/inmemorydb.html#temp_db>
        case temporary

        /// A database located at the given URI filename (or path).
        ///
        /// See: <https://www.sqlite.org/uri.html>
        ///
        /// - Parameter filename: A URI filename
        case uri(String)

        public var description: String {
            switch self {
            case .inMemory:
                ":memory:"
            case .temporary:
                ""
            case let .uri(uri):
                uri
            }
        }
    }
}
