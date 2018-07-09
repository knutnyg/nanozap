import Foundation
import UIKit

struct DecodedInvoice {
    let timestamp: Date
    let amount: Int
    let description: String
    let expiry: Date
    let payreq: String
    let settled: Bool
}

struct Invoice {
    let timestamp: Date
    let amount: Int
    let description: String
    let expiry: Date
    let payreq: String
    let settled: Bool
    let rHash: Data

    init(
            timestamp: Date,
            amount: Int,
            description: String,
            expiry: Date,
            payreq: String,
            settled: Bool,
            rHash: Data
    ) {
        self.timestamp = timestamp
        self.amount = amount
        self.description = description
        self.expiry = expiry
        self.payreq = payreq
        self.settled = settled
        self.rHash = rHash
    }
}

struct PayableInvoice {
    let payreq: String
    let amount: Int

    init(payreq: String, amount: Int) {
        self.payreq = payreq
        self.amount = amount
    }
}
