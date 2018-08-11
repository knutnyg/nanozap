import Foundation

struct Transaction {
    let txHash: String
    let timestamp: Date
    let numConfirmations: Int
    let blockHash: String
    let blockHeight: Int
    let amount: Int
    let totalFees: Int
    let destination: [String]

}
