import RxSwift

protocol Channeler {
    func getChannels() throws -> [Channel]
}

class ChannelServiceMock : Channeler {
    static var count = 0

    func getChannels() throws -> [Channel] {
        let nextCount = ChannelServiceMock.count + 1
        ChannelServiceMock.count = nextCount
        print("nextCount", nextCount)
        return [
            Channel(
                    active: true,
                    remotePubkey: "somekey",
                    channelPoint: "",
                    channelId: nextCount,
                    capacity: 3,
                    remoteBalance: 4,
                    commitFee: 5,
                    commitWeight: 6,
                    feePerKw: 7,
                    numUpdates: 8,
                    csvDelay: 9
            )
        ]
    }
}

class ChannelService : Channeler {
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
