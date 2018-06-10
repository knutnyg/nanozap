import Foundation

struct Transaction {
    let timestamp: Date
    let amount: Int
    let destination: String
    
    init(timestamp: Date, amount: Int, destination: String) {
        self.amount = amount
        self.timestamp = timestamp
        self.destination = destination
    }
}
