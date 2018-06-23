import Foundation
import UIKit

struct Channel {
    let active:Bool
    let remotePubkey:String
    ///The outpoint (txid:index) of the funding transaction. With this value, Bob
    ///will be able to generate a signature for Alice's version of the commitment
    ///transaction.
    let channelPoint:String
    let channelId: Int
    let capacity: Int
    let remoteBalance: Int
    let localBalance: Int
    let commitFee: Int
    let commitWeight: Int
    let feePerKw: Int
    let numUpdates: Int
    let csvDelay: Int
    
    init(
        active:Bool,
        remotePubkey:String,
        channelPoint:String,
        channelId: Int,
        capacity: Int,
        remoteBalance: Int,
        commitFee: Int,
        commitWeight: Int,
        feePerKw: Int,
        numUpdates: Int,
        csvDelay: Int
    ) {
        self.active = active
        self.remotePubkey = remotePubkey
        self.channelPoint = channelPoint
        self.channelId = channelId
        self.capacity = capacity
        self.remoteBalance = remoteBalance
        self.commitFee = commitFee
        self.commitWeight = commitWeight
        self.feePerKw = feePerKw
        self.numUpdates = numUpdates
        self.csvDelay = csvDelay
        
        self.localBalance = max(capacity - remoteBalance - commitFee, 0)
    }
}
