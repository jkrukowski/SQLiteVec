import CSQLiteVec
import Foundation

/// A class representing a SQLite database with vectorization capabilities.
///
/// The `Database` class provides an interface to interact with a SQLite database,
/// including support for vector operations through the SQLite vectorization extension.
///
/// Example usage:
///
/// ```swift
/// import SQLiteVec
///
/// // initialize the library first
/// try SQLiteVec.initialize()
///
/// // example data
/// let data: [(index: Int, vector: [Float])] = [
///     (1, [0.1, 0.1, 0.1, 0.1]),
///     (2, [0.2, 0.2, 0.2, 0.2]),
///     (3, [0.3, 0.3, 0.3, 0.3]),
///     (4, [0.4, 0.4, 0.4, 0.4]),
///     (5, [0.5, 0.5, 0.5, 0.5]),
/// ]
/// let query: [Float] = [0.3, 0.3, 0.3, 0.3]
///
/// // create a database
/// let db = try Database(.inMemory)
///
/// // create a table and insert data
/// try await db.execute("CREATE VIRTUAL TABLE vec_items USING vec0(embedding float[4])")
/// for row in data {
///     try await db.execute(
///         """
///             INSERT INTO vec_items(rowid, embedding)
///             VALUES (?, ?)
///         """,
///         params: [row.index, row.vector]
///     )
/// }
///
/// // query the embeddings
/// let result = try await db.query(
///     """
///         SELECT rowid, distance
///         FROM vec_items
///         WHERE embedding MATCH ?
///         ORDER BY distance
///         LIMIT 3
///     """,
///     params: [query]
/// )
///
/// // print the result
/// print(result)
/// ```
///
/// It should print the following result:
///
/// ```bash
/// [
///     ["distance": 0.0, "rowid": 3],
///     ["distance": 0.19999998807907104, "rowid": 4],
///     ["distance": 0.20000001788139343, "rowid": 2]
/// ]
/// ```
///
/// This class provides methods for database operations such as executing SQL statements,
/// querying data, and accessing information about the SQLite vectorization extension.
public actor Database {
    private var _handle: OpaquePointer?

    /// Initializes a new Database instance.
    ///
    /// This initializer creates a new Database instance, opening or creating a SQLite database
    /// at the specified location with the given access mode.
    ///
    /// - Parameters:
    ///   - location: The location of the database. Defaults to `.inMemory`.
    ///   - readonly: A boolean indicating whether the database should be opened in read-only mode.
    ///               Defaults to `false`.
    ///
    /// - Throws: An error if the database cannot be opened or created.
    ///
    /// - Note: The database is opened with the SQLITE_OPEN_FULLMUTEX and SQLITE_OPEN_URI flags
    ///         in addition to the flags determined by the `readonly` parameter.
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

    /// Returns the version of the SQLite vectorization extension.
    ///
    /// This function queries the database to retrieve the version of the SQLite vectorization extension.
    ///
    /// - Returns: A string containing the version information, or `nil` if the version couldn't be retrieved.
    ///
    /// - Note: This function catches any errors internally and returns `nil` in case of failure.
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

    /// Returns build information about the SQLite vectorization extension.
    ///
    /// This function queries the database to retrieve debug information about the SQLite vectorization extension.
    ///
    /// - Returns: A string containing the build information, or `nil` if the information couldn't be retrieved.
    ///
    /// - Note: This function catches any errors internally and returns `nil` in case of failure.
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

    /// Executes a SQL statement.
    ///
    /// This function prepares and executes a SQL statement with optional parameters.
    ///
    /// - Parameters:
    ///   - sql: A string containing the SQL statement to execute.
    ///   - params: An array of parameters to bind to the SQL statement. Defaults to an empty array.
    ///
    /// - Throws: An error if the SQL statement preparation or execution fails.
    ///
    /// - Note: This function internally prepares the statement, binds the parameters, and then executes it.
    public func execute(_ sql: String, params: [Any] = []) throws {
        let stmt = try prepare(sql, params: params)
        try execute(stmt)
    }

    /// Executes a SQL query and returns the result as an array of dictionaries.
    ///
    /// This function prepares and executes a SQL query with optional parameters and returns the result set.
    ///
    /// - Parameters:
    ///   - sql: A string containing the SQL query to execute.
    ///   - params: An array of parameters to bind to the SQL query. Defaults to an empty array.
    ///
    /// - Returns: An array of dictionaries, where each dictionary represents a row in the result set.
    ///            The keys in the dictionary are column names, and the values are the corresponding data.
    ///
    /// - Throws: An error if the SQL query preparation or execution fails.
    ///
    /// - Note: This function internally prepares the statement, binds the parameters, and then executes it.
    ///         The result is fetched and returned as an array of dictionaries for easy manipulation.
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
