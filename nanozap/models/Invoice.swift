//
//  Invoice.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation

struct Invoice {
    let timestamp: Date
    let ammount: Int
    let description: String
    let expiry: Date
    
    init(timestamp: Date, ammount: Int, description: String, expiry: Date) {
        self.timestamp = timestamp
        self.ammount = ammount
        self.description = description
        self.expiry = expiry
    }

}
