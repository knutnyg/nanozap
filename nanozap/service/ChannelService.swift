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

struct ConnectedPeersResult {
    let response: Lnrpc_ListPeersResponse
    let peers: [String]
}

class ChannelService: Channeler {
    static let shared: ChannelService = ChannelService()

    let rpcmanager: RpcManager = RpcManager.shared

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
                            ConnectedPeersResult(response: res, peers: res.peers.map { peer in
                                peer.pubKey
                            })
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

    public func connectToNode(node: (pubkey:String, host:String)) -> Observable<ConnectToNodeResult> {
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
