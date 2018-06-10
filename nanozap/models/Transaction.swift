//
//  Transaction.swift
//  nanozap
//
//  Created by Knut Nygaard on 10/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

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
