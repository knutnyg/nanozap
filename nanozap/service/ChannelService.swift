//
//  ChannelService.swift
//  nanozap
//
//  Created by Knut Nygaard on 09/06/2018.
//  Copyright © 2018 Knut Nygaard. All rights reserved.
//

import Foundation

class ChannelService {
    
    let rpcmanager:RpcManager = RpcManager.shared
    let client:Lnrpc_LightningServiceClient
    
    public func getChannels() throws -> [Channel] {
        do {
            let res = try client.listChannels(Lnrpc_ListChannelsRequest())
            return res.channels.map({(lndChannel:Lnrpc_Channel) in
                return Channel(active: lndChannel.active, remote_pubkey: lndChannel.remotePubkey, channel_point: lndChannel.channelPoint, channel_id: Int(lndChannel.chanID), capacity: Int(lndChannel.capacity), remote_balance: Int(lndChannel.remoteBalance), commit_fee: Int(lndChannel.commitFee), commit_weight: Int(lndChannel.commitWeight), fee_per_kw: Int(lndChannel.feePerKw), num_updates: Int(lndChannel.numUpdates), csv_delay: Int(lndChannel.csvDelay))
            })
        } catch {
            print("Unexpected error: \(error).")
            throw RPCErrors.failedToFetchChannels
        }
    }
    
    init() throws {
        guard let client = rpcmanager.client
            else {
                throw RPCErrors.unableToAccessClient
        }
        self.client = client
    }
}
