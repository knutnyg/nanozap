import Foundation

struct Invoice {
    let timestamp: Date
    let amount: Int
    let description: String
    let expiry: Date
    let payreq: String
    let settled: Bool

    init(timestamp: Date, amount: Int, description: String, expiry: Date, payreq: String, settled: Bool) {
        self.timestamp = timestamp
        self.amount = amount
        self.description = description
        self.expiry = expiry
        self.payreq = payreq
        self.settled = settled
    }
}
