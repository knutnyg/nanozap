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

struct LndNode {
    let pubKey : String
    let alias : String
    let color : String
    let lastUpdate : Date
    let totalCapacity : Int64
    let numChannels : Int
}

class ChannelService : Channeler {
    static let shared: ChannelService = ChannelService()

    let rpcmanager: RpcManager = RpcManager.shared

    public func getPubkey(pubkey : String) -> Observable<LndNode?> {
        return Observable.deferred {
            var req = Lnrpc_NodeInfoRequest()
            req.pubKey = pubkey

            if let res = try self.rpcmanager.client()?.getNodeInfo(req) {
                if !res.hasNode {
                    return Observable.empty()
                } else {
                    let node = res.node
                    let lastUpdate = Date.init(timeIntervalSince1970: TimeInterval(node.lastUpdate))

                    let lndNode = LndNode(
                            pubKey: node.pubKey,
                            alias: node.alias,
                            color: node.color,
                            lastUpdate: lastUpdate,
                            totalCapacity: res.totalCapacity,
                            numChannels: Int(res.numChannels)
                    )
                    return Observable.just(lndNode)
                }
            } else {
                return Observable.error(RPCErrors.unableToAccessClient)
            }
        }
    }

    public func getChannelsRx() -> Observable<[Channel]> {
        return Observable.deferred {
            if let res = try self.rpcmanager.client()?.listChannels(Lnrpc_ListChannelsRequest()) {

                let chans = res.channels.map({ (lndChannel: Lnrpc_Channel) in
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

                return Observable.just(chans)
            } else {
                return Observable.error(RPCErrors.unableToAccessClient)
            }
        }
    }
    public func getChannels() throws -> [Channel] {
        do {
            if let res = try rpcmanager.client()?.listChannels(Lnrpc_ListChannelsRequest()) {
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
            } else {
                return []
            }
        } catch {
            print("Unexpected error: \(error).")
            throw RPCErrors.failedToFetchChannels
        }
    }
}
