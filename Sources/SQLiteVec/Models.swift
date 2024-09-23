import CSQLiteVec
import Foundation

struct SQLiteVecError: Error {
    let code: Int32
    let message: String?

    init(code: Int32, message: String?) {
        self.code = code
        self.message = message
    }
}

extension SQLiteVecError: CustomStringConvertible {
    var description: String {
        if let message {
            "Error \(code): \(message)"
        } else {
            "Error \(code)"
        }
    }
}

extension SQLiteVecError: CustomDebugStringConvertible {
    var debugDescription: String {
        description
    }
}

extension SQLiteVecError {
    static let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]

    static func check(_ code: Int32, _ handle: OpaquePointer? = nil) throws {
        if successCodes.contains(code) {
            return
        }
        let message: String? = if let handle {
            String(cString: sqlite3_errmsg(handle))
        } else {
            nil
        }
        throw SQLiteVecError(code: code, message: message)
    }

    static func message(_ handle: OpaquePointer) -> String {
        String(cString: sqlite3_errmsg(handle))
    }
}

extension Data {
    var bytes: [UInt8] {
        [UInt8](self)
    }
}

public extension Data {
    func toArray<Element>() -> [Element] {
        withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> [Element] in
            let buffer = pointer.bindMemory(to: Element.self)
            return [Element](buffer)
        }
    }

    func toElement<Element>() -> Element {
        withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Element in
            pointer.load(as: Element.self)
        }
    }
}
