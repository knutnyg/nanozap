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

struct Payment: Equatable {
    let amount: Int64
    let fee: Int
    let path: [String]
    let paymentHash: String
    let paymentPreimage: String
    let creationDate: Date

    public static func ==(lhs: Payment, rhs: Payment) -> Bool {
        return lhs.amount == rhs.amount
                && lhs.fee == rhs.fee
                && lhs.path == rhs.path
                && lhs.paymentHash == rhs.paymentHash
                && lhs.creationDate == rhs.creationDate
                && lhs.paymentPreimage == rhs.paymentPreimage
    }
}

enum Payable: Comparable {
    case invoice(i: Invoice)
    case payment(p: Payment)

    public static func <(lhs: Payable, rhs: Payable) -> Bool {
        let timeA: Date = {
            switch (lhs) {
            case .payment(let pay):
                return pay.creationDate
            case .invoice(let inv):
                return inv.timestamp
            }
        }()

        let timeB: Date = {
            switch (rhs) {
            case .payment(let pay):
                return pay.creationDate
            case .invoice(let inv):
                return inv.timestamp
            }
        }()

        return timeA < timeB
    }

    public static func ==(lhs: Payable, rhs: Payable) -> Bool {
        let myTuple = (lhs, rhs)
        switch (myTuple) {
        case (.invoice(let lhi), .invoice(let rhi)):
            return lhi == rhi
        case (.payment(let lhi), .payment(let rhi)):
            return lhi == rhi
        case (_, _):
            return false
        }
    }
}

struct Invoice: Equatable {
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

    public static func ==(lhs: Invoice, rhs: Invoice) -> Bool {
        return lhs.timestamp == rhs.timestamp
                && lhs.payreq == rhs.payreq
                && lhs.settled == rhs.settled
                && lhs.rHash == rhs.rHash
                && lhs.description == rhs.description
                && lhs.amount == rhs.amount
                && lhs.expiry == rhs.expiry
    }

}
