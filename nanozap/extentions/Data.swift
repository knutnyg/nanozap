//
//  Data.swift
//  nanozap
//
//  Created by Knut Nygaard on 06/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation

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
