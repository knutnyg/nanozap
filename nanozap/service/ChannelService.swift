class ChannelService {
    let rpcmanager: RpcManager = RpcManager.shared

    public func getChannels() throws -> [Channel] {
        do {
            let res = try rpcmanager.client()!.listChannels(Lnrpc_ListChannelsRequest())
            return res.channels.map({ (lndChannel: Lnrpc_Channel) in
                return Channel(
                    active: lndChannel.active,
                    remotePubkey: lndChannel.remotePubkey,
                    channelPoint: lndChannel.channelPoint,
                    channelId: Int(lndChannel.chanID),
                    capacity: Int(lndChannel.capacity),
                    remoteBalance: Int(lndChannel.remoteBalance),
                    commitFee: Int(lndChannel.commitFee),
                    commitWeight: Int(lndChannel.commitWeight),
                    feePerKw: Int(lndChannel.feePerKw),
                    numUpdates: Int(lndChannel.numUpdates),
                    csvDelay: Int(lndChannel.csvDelay)
                )
            })
        } catch {
            print("Unexpected error: \(error).")
            throw RPCErrors.failedToFetchChannels
        }
    }
}
