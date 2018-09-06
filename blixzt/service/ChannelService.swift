import RxSwift
import Result

protocol Channeler {
    func getChannels() throws -> [Channel]
}

class ChannelServiceMock: Channeler {
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
    let pubKey: String
    let alias: String
    let color: String
    let lastUpdate: Date
    let totalCapacity: Int64
    let numChannels: Int
}

struct CloseChannelResult {
    let txId: String
}

struct OpenChannelResult {
    let response: Lnrpc_ChannelPoint
}

struct ConnectToNodeResult {
    let response: Lnrpc_ConnectPeerResponse
}

struct ConnectedPeer {
    let pubkey: String
    let address: String
}

struct ConnectedPeersResult {
    let peers: [ConnectedPeer]
}

class ChannelService: Channeler {
    static let shared: ChannelService = ChannelService()

    let rpcmanager: RpcManager = RpcManager.shared

    func getChannels() throws -> [Channel] {
        return []
    }

    public func openChannel(nodePubKey: String, satPerByte: Int, amount: Int) -> Observable<OpenChannelResult> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {
                var request = Lnrpc_OpenChannelRequest()
                request.nodePubkeyString = nodePubKey
                request.satPerByte = Int64(satPerByte)
                request.localFundingAmount = Int64(amount)

                print("Trying to open channel")

                let res = Result(attempt: { () throws in try client.openChannelSync(request) })
                        .map { res in
                            OpenChannelResult(response: res)
                        }

                switch res {
                case .success(let value):
                    print("Open channel success! \(value.response.fundingTxid)")
                    obs.onNext(value)
                    obs.onCompleted()
                case .failure(let error):
                    print("Open channel failed..")
                    obs.onError(error)
                }
            } else {
                obs.onError(RPCError.unableToAccessClient)
            }

            return Disposables.create(with: { () in obs.onCompleted() })
        }
    }

    public func closeChannel(channel: Channel) -> Observable<CloseChannelResult> {
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

    public func getNodeInfo(pubkey: String) -> Observable<Result<LndNode, RPCError>> {
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

    public func connectedPeers() -> Observable<ConnectedPeersResult> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {

                var request = Lnrpc_ListPeersRequest()

                print("Trying to list peers")

                let res = Result(attempt: { () throws in try client.listPeers(request) })
                        .map { (res: Lnrpc_ListPeersResponse) in
                            ConnectedPeersResult(
                                    peers: res.peers.map { peer in
                                        ConnectedPeer(
                                                pubkey: peer.pubKey,
                                                address: peer.address
                                        )
                                    }
                            )
                        }

                switch res {
                case .success(let value):
                    obs.onNext(value)
                    obs.onCompleted()
                case .failure(let error):
                    obs.onError(error)
                }
            } else {
                obs.onError(RPCError.unableToAccessClient)
            }

            return Disposables.create(with: { () in obs.onCompleted() })
        }
    }

    public func connectToNode(node: (pubkey: String, host: String)) -> Observable<ConnectToNodeResult> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {
                var lnAddr = Lnrpc_LightningAddress()
                lnAddr.pubkey = node.pubkey
                lnAddr.host = node.host

                var request = Lnrpc_ConnectPeerRequest()
                request.addr = lnAddr

                print("Trying to connect to node")

                let res = Result(attempt: { () throws in try client.connectPeer(request) })
                        .map { res in
                            ConnectToNodeResult(response: res)
                        }

                switch res {
                case .success(let value):
                    print("Connection success!")
                    obs.onNext(value)
                    obs.onCompleted()
                case .failure(let error):
                    print("Connection failed..")
                    obs.onError(error)
                }
            } else {
                obs.onError(RPCError.unableToAccessClient)
            }

            return Disposables.create(with: { () in obs.onCompleted() })
        }
    }

//    public func getPendingChannels() throws -> [PendingChannel] {
//        return Observable.deferred {
//            if let res = try self.rpcmanager.client()?.pendingChannels(request: Lnrpc_PendingChannelsRequest) {
//
//                let pendingOpen = res.pendingOpenChannels.map({ (channel:Lnrpc_PendingChannelsResponse.PendingOpenChannel) in
//                    return PendingOpenChannel(channel.channel.)
//                })
//
//                let chans = res.channels.map({ (lndChannel: Lnrpc_Channel) in
//                    return Channel(
//                            active: lndChannel.active,
//                            remotePubkey: lndChannel.remotePubkey,
//                            channelPoint: lndChannel.channelPoint,
//                            channelId: Int(lndChannel.chanID),
//                            capacity: Int(lndChannel.capacity),
//                            remoteBalance: Int(lndChannel.remoteBalance),
//                            commitFee: Int(lndChannel.commitFee),
//                            commitWeight: Int(lndChannel.commitWeight),
//                            feePerKw: Int(lndChannel.feePerKw),
//                            numUpdates: Int(lndChannel.numUpdates),
//                            csvDelay: Int(lndChannel.csvDelay)
//                    )
//                })
//
//                return Observable.just(chans)
//            } else {
//                return Observable.error(RPCError.unableToAccessClient)
//            }
//        }
//    }

    public func listPendingChannels() -> Observable<[Channel]> {
        return Observable.of([Channel(active: false, remotePubkey: "pubkey", channelPoint: "point", channelId: 012, capacity: 500000, remoteBalance: 0, commitFee: 2000, commitWeight: 20, feePerKw: 2, numUpdates: 2, csvDelay: 4)])
    }

    public func listChannels() -> Observable<[ChannelE]> {
        let openChannels = self.listOpenChannels()
                .map { channels in
                    channels.map { chan in
                        ChannelE.active(chan)
                    }
                }

        let pendingChannels = self.listPendingChannels()
                .map { channels in
                    channels.map { chan in
                        ChannelE.pending(chan)
                    }
                }

        return Observable.zip(openChannels, pendingChannels) { (open, pending) in
            return [open, pending].flatMap{ $0 }
        }
    }

    public func listOpenChannels() -> Observable<[Channel]> {
        return Observable.create { obs in
            if let client = self.rpcmanager.client() {

                let result = Result(attempt: { () in try client.listChannels(Lnrpc_ListChannelsRequest()) })

                switch (result) {
                case .success(let res):
                    let channels = res.channels.map { (lnChan: Lnrpc_Channel) in
                        Channel(
                                active: lnChan.active,
                                remotePubkey: lnChan.remotePubkey,
                                channelPoint: lnChan.channelPoint,
                                channelId: Int(lnChan.chanID),
                                capacity: Int(lnChan.capacity),
                                remoteBalance: Int(lnChan.remoteBalance),
                                commitFee: Int(lnChan.commitFee),
                                commitWeight: Int(lnChan.commitWeight),
                                feePerKw: Int(lnChan.feePerKw),
                                numUpdates: Int(lnChan.numUpdates),
                                csvDelay: Int(lnChan.csvDelay)
                        )
                    }
                    obs.onNext(channels)
                    obs.onCompleted()
                case .failure(let error):
                    obs.onError(error)
                }
            } else {
                obs.onError(RPCError.unableToAccessClient)
            }
            return Disposables.create()
        }
    }
}
