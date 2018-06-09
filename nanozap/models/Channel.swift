//
//  Channels.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation
import UIKit

struct Channel {
    let active:Bool
    let remote_pubkey:String
    let channel_point:String
    let channel_id: Int
    let capacity: Int
    let remote_balance: Int
    let local_balance: Int
    let commit_fee: Int
    let commit_weight: Int
    let fee_per_kw: Int
    let num_updates: Int
    let csv_delay: Int
    
    init(active:Bool, remote_pubkey:String, channel_point:String, channel_id: Int, capacity: Int, remote_balance: Int, commit_fee: Int, commit_weight: Int, fee_per_kw: Int, num_updates: Int,csv_delay: Int) {
        self.active = active
        self.remote_pubkey = remote_pubkey
        self.channel_point = channel_point
        self.channel_id = channel_id
        self.capacity = capacity
        self.remote_balance = remote_balance
        self.commit_fee = commit_fee
        self.commit_weight = commit_weight
        self.fee_per_kw = fee_per_kw
        self.num_updates = num_updates
        self.csv_delay = csv_delay
        
        self.local_balance = max(capacity - remote_balance - commit_fee, 0)
    }
}
