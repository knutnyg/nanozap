//
//  Data.swift
//  nanozap
//
//  Created by Knut Nygaard on 06/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation

extension Optional {
    /// Return the value of the Optional or the `default` parameter
    /// - param: The value to return if the optional is empty
    func or(_ other: Wrapped) -> Wrapped {
        switch self {
        case .none:
            return other
        case .some(let value):
            return value
        }
    }

    /// Returns the unwrapped value of the optional *or*
    /// the result of calling the closure `else`
    /// I.e. optional.or(else: {
    /// ... do a lot of stuff
    /// })
    func or(else: () -> Wrapped) -> Wrapped {
        return self ?? `else`()
    }

}

extension String {
    /*
     Truncates string to the specified length number of characters and appends an optional trailing string if longer.
     - Parameter length: Desired maximum lengths of a string
     - Parameter trailing: A 'String' that will be appended after the truncation.

     - Returns: 'String' object.
    */
    func truncate(length: Int, trailing: String = "…") -> String {
        return (self.count > length) ? self.prefix(length) + trailing : self
    }
}

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
