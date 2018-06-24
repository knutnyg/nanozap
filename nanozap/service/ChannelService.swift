import RxSwift
import Result

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

struct CloseChannelResult {
    let txId : String
}

class ChannelService : Channeler {
    static let shared: ChannelService = ChannelService()

    let rpcmanager: RpcManager = RpcManager.shared

    public func closeChannel(channel : Channel) -> Observable<CloseChannelResult> {
        return Observable.deferred {
            let parts = channel.channelPoint.split(separator: ":")
            let fundingTxId = String(parts[0])
            let outputIdx = UInt32(parts[1])
            
            var channelPoint = Lnrpc_ChannelPoint()
            channelPoint.fundingTxid = .fundingTxidStr(fundingTxId)
            channelPoint.outputIndex = outputIdx!
            
            var req = Lnrpc_CloseChannelRequest()
            req.force = !channel.active
            req.channelPoint = channelPoint
            req.satPerByte = 1
            // number of confirmation blocks
            req.targetConf = 6
            // set a much higher confirmation if we are force closing
            if req.force {
                req.targetConf = 192
            }
            
            //TODO: set a timeout in receive.
            if let res = try self.rpcmanager.client()?.closeChannel(req, completion: nil).receive() {
                if let update = res.update {
                    switch (update) {
                    case .closePending(let closepending):
                        let txId = closepending.txid.hexString()
                        
                        return Observable.just(CloseChannelResult(txId: txId))
                    case .confirmation(_):
                        return Observable.empty()
                    case .chanClose(let chanClosed):
                        let txId = chanClosed.closingTxid.hexString()

                        return Observable.just(CloseChannelResult(txId: txId))
                    }
                } else {
                    return Observable.error(RPCError.unableToAccessClient)
                }
            } else {
                return Observable.error(RPCError.unableToAccessClient)
            }
        }
    }
    
    public func getNodeInfo(pubkey : String) -> Observable<Result<LndNode, RPCError>> {
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
                    return Observable.just(Result(lndNode))
                }
            } else {
                return Observable.just(Result(error: RPCError.unableToAccessClient))
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
                return Observable.error(RPCError.unableToAccessClient)
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
            throw RPCError.failedToFetchChannels
        }
    }
}
