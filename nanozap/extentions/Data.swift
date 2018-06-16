import Foundation

extension Data {
    var bytes: [UInt8] {
        return withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            Array(UnsafeBufferPointer(start: bytes, count: count / MemoryLayout<UInt8>.stride))
        }
    }
}

extension Data {
    func hexString() -> String {
        return bytes.reduce("") { $0 + String(format: "%02x", UInt8($1)) }
    }
}
