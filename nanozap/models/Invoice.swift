import Foundation

struct Invoice {
    let timestamp: Date
    let ammount: Int
    let description: String
    let expiry: Date
    let payreq: String
    
    init(timestamp: Date, ammount: Int, description: String, expiry: Date, payreq:String) {
        self.timestamp = timestamp
        self.ammount = ammount
        self.description = description
        self.expiry = expiry
        self.payreq = payreq
    }

}
