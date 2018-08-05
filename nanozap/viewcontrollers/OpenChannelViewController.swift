import Foundation
import UIKit
import QRCodeReader
import RxSwift
import SnapKit

enum OpenChannelActions {
    case connectToNode
    case openChannel(nodeAddr: String, numSat: Int, capacity: Int)
    case openChannel2
    case fetchPeers
}

enum OpenChannelEvents {
    case startScan
    case startOpening
    case displaySuccess(message: String)
    case displayFailure(message: String)
}

enum OpenChannelActionResponses {
    case channelOpened(result: OpenChannelResult)
    case nodeConnected(nodeAddr: String)
    case peersFetched(result: ConnectedPeersResult)
}

enum StateChanges {
    case numSatChanged(Int)
    case localCapChanged(Int)
    case qrScanned(String)
    case peersFetched([ConnectedPeer])
    case channelOpened
}

struct OpenChannelViewState {
    let peers: [ConnectedPeer]?
    let numSats: Int
    let localCapacity: Int
    let node: (pubkey: String, host: String)?

    func toString() {
        print("State: Peers: \(peers) sats: \(numSats) cap: \(localCapacity) node: \(node?.pubkey)@\(node?.host)")
    }

    func new(
            peers: [ConnectedPeer]? = nil,
            numSats: Int? = nil,
            localCapacity: Int? = nil,
            node: (pubkey: String, host: String)? = nil
    ) -> OpenChannelViewState {
        return OpenChannelViewState(
                peers: peers ?? self.peers,
                numSats: numSats ?? self.numSats,
                localCapacity: localCapacity ?? self.localCapacity,
                node: node ?? self.node
        )
    }
}

class OpenChannelViewController: UIViewController, QRCodeReaderViewControllerDelegate {

    let actions = PublishSubject<OpenChannelActions>()
    let uiActions = PublishSubject<OpenChannelEvents>()
    let disposeBag = DisposeBag()
    let state = BehaviorSubject<OpenChannelViewState>(
            value: OpenChannelViewState(
                    peers: nil,
                    numSats: 1,
                    localCapacity: 0,
                    node: nil
            )
    )

    let stateChange = PublishSubject<StateChanges>()

    var scanButton: UIButton!
    var openButton: UIButton!
    var dismissButton: UIButton!
    var nodePubKey: UILabel!
    var nodeHost: UILabel!

    var satPreLabel = createLabel(text: "Fee:")
    var satPostLabel = createLabel(text: "sat / byte")
    var connectedToNode = createLabel(text: "")
    var satSlider: UISlider!
    var capacity: UITextField!

    override func loadView() {
        super.loadView()

        view.backgroundColor = UIColor.white

        scanButton = createButton(text: "Scan")
        openButton = createButton(text: "Open Channel")
        dismissButton = createButton(text: "Dismiss")
        nodePubKey = createLabel(text: "", font: NanoFonts.paragraphSmall)
        nodeHost = createLabel(text: "", font: NanoFonts.paragraph)
        capacity = createTextField(placeholder: "local capacity")
        capacity.keyboardType = .numberPad

        satSlider = UISlider()
        satSlider.translatesAutoresizingMaskIntoConstraints = false
        satSlider.minimumValue = 1
        satSlider.maximumValue = 50

        view.addSubview(scanButton)
        view.addSubview(connectedToNode)
        view.addSubview(openButton)
        view.addSubview(dismissButton)
        view.addSubview(nodePubKey)
        view.addSubview(nodeHost)
        view.addSubview(satSlider)
        view.addSubview(satPreLabel)
        view.addSubview(satPostLabel)
        view.addSubview(capacity)

        addConstraints()

        connectScanButton()
        connectOpenButton()
        connectDismissButton()
        connectSlider()
        connectCapacity()

        uiActions
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { event in
                    switch (event) {
                    case .startScan: self.present(self.readerVC, animated: true)
                    case .startOpening: self.present(self.getConfimer(), animated: true)
                    case .displaySuccess(let msg): displaySuccess(message: msg)
                    case .displayFailure(let msg): displayError(message: msg)
                    }
                })
                .disposed(by: disposeBag)

        Observable<Int>
                .timer(0, period: 5, scheduler: AppState.bgScheduler)
                .subscribe(onNext: { _ in
                    self.actions.onNext(.fetchPeers)
                })
                .disposed(by: disposeBag)

        actions
                .asObservable()
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { (action: OpenChannelActions) -> Observable<OpenChannelActionResponses> in
                    switch (action) {
                    case .fetchPeers:
                        return ChannelService.shared.connectedPeers()
                                .retry(3)
                                .catchError { error in
                                    print(error)
                                    return Observable.empty()
                                }
                                .map { res in
                                    .peersFetched(result: res)
                                }

                    case .connectToNode:
                        let state = try self.state.value()
                        guard let node = state.node, let peers = state.peers else {
                            print("Missing data")
                            return Observable.empty()
                        }

                        let alreadyConnected = peers.contains { $0.pubkey == node.pubkey }
                        if alreadyConnected {
                            print("We are already connected to node: \(node.pubkey)")
                            return Observable.of(OpenChannelActionResponses.nodeConnected(nodeAddr: node.pubkey))
                        }

                        return ChannelService.shared.connectToNode(node: node)
                                .retry(3)
                                .catchError { error in
                                    print(error)
                                    return Observable.empty()
                                }
                                .map { res in
                                    OpenChannelActionResponses.nodeConnected(nodeAddr: node.pubkey)
                                }
                    case .openChannel2:
                        let model = try self.state.value()
                        guard let node = model.node else {
                            print("Cannot open channel: No node")
                            return Observable.empty()
                        }

                        return ChannelService.shared.openChannel(nodePubKey: node.pubkey, satPerByte: model.numSats, amount: model.localCapacity)
                                .retry(3)
                                .catchError { error in
                                    print(error)
                                    self.uiActions.onNext(.displayFailure(message: "failed to open channel."))
                                    return Observable.empty()
                                }
                                .map { res in
                                    OpenChannelActionResponses.channelOpened(result: res)
                                }
                    case .openChannel: return Observable.empty()
                    }
                }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (res: OpenChannelActionResponses) in
                    switch (res) {
                    case .peersFetched(let res):
                        self.stateChange.onNext(.peersFetched(res.peers))
                    case .channelOpened:
                        self.uiActions.onNext(.displaySuccess(message: "Channel opened!"))
                        self.stateChange.onNext(.channelOpened)
                    case .nodeConnected(let nodeAddr): print(nodeAddr)

                    }

                })
                .disposed(by: disposeBag)

        stateChange
                .asObservable()
                .subscribe(onNext: { (change: StateChanges) in
                    do {
                        let oldState = try self.state.value()

                        switch (change) {
                        case .qrScanned(let raw):
                            let split = raw.components(separatedBy: "@")
                            let pubKey = split.first ?? ""
                            let host = split.last ?? ""

                            self.state.onNext(oldState.new(node: (pubKey, host)))
                        case .numSatChanged(let sats):
                            self.state.onNext(oldState.new(numSats: sats))
                        case .localCapChanged(let cap):
                            self.state.onNext(oldState.new(localCapacity: cap))
                        case .peersFetched(let peers):
                            self.state.onNext(oldState.new(peers: peers))
                        case .channelOpened: break
                        }
                    } catch {
                        error
                        print(error)
                    }
                })
                .disposed(by: disposeBag)

        state
                .asObservable()
                .subscribe(onNext: { (newState: OpenChannelViewState) in
                    print("New state: \(newState)")

                    self.satPostLabel.text = "\(newState.numSats) sat / byte"

                    if let node = newState.node, let peers = newState.peers {
                        let alreadyConnected = peers.contains { $0.pubkey == node.pubkey }
                        if (alreadyConnected) {
                            self.connectedToNode.text = "Connected: ✅"
                            self.openButton.isEnabled = true
                        } else {
                            self.connectedToNode.text = "Connected: ❌"
                            self.openButton.isEnabled = false
                            self.actions.onNext(.connectToNode)
                        }
                    }
                })
                .disposed(by: disposeBag)
    }

    private func addConstraints() {
        connectedToNode.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(150)
            make.right.equalTo(self.view.snp.right).offset(-30)
        }

        scanButton.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(200)
            make.centerX.equalTo(self.view)
        }

        nodePubKey.snp.makeConstraints { make in
            make.top.equalTo(scanButton.snp.bottom).offset(30)
            make.left.equalTo(self.view).offset(50)
        }

        nodeHost.snp.makeConstraints { make in
            make.top.equalTo(nodePubKey).offset(30)
            make.left.equalTo(self.view).offset(50)
        }

        satSlider.snp.makeConstraints { make in
            make.top.equalTo(nodeHost.snp.bottom).offset(50)
            make.centerX.equalTo(self.view)
            make.width.equalTo(150)
        }

        satPreLabel.snp.makeConstraints { make in
            make.centerY.equalTo(satSlider.snp.centerY)
            make.right.equalTo(satSlider.snp.left).offset(-30)
        }

        satPostLabel.snp.makeConstraints { make in
            make.centerY.equalTo(satSlider.snp.centerY)
            make.right.equalTo(satSlider.snp.right).offset(30)
        }

        capacity.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(satSlider.snp.bottom).offset(30)
        }

        openButton.snp.makeConstraints { make in
            make.top.equalTo(capacity.snp.bottom).offset(50)
            make.centerX.equalTo(self.view)
        }

        dismissButton.snp.makeConstraints { make in
            make.top.equalTo(openButton.snp.bottom).offset(50)
            make.centerX.equalTo(self.view)
        }
    }

    private func connectCapacity() {
        capacity.rx.text.asObservable()
                .debounce(1, scheduler: MainScheduler.instance)
                .subscribe(onNext: { val in
                    if let capacity = Int(val ?? "0") {
                        self.stateChange.onNext(.localCapChanged(capacity))
                    }
                })
                .disposed(by: disposeBag)
    }

    private func connectSlider() {
        satSlider.rx.value.asObservable()
                .throttle(0.1, scheduler: MainScheduler.instance)
                .subscribe(onNext: { val in
                    self.stateChange.onNext(.numSatChanged(Int(val)))
                })
                .disposed(by: disposeBag)
    }

    private func connectScanButton() {
        scanButton.rx.tap
                .asObservable()
                .observeOn(AppState.userInitiatedBgScheduler)
                .subscribe(onNext: { _ in
                    self.uiActions.onNext(OpenChannelEvents.startScan)
                })
                .disposed(by: disposeBag)
    }

    private func connectOpenButton() {
        openButton.rx.tap
                .asObservable()
                .observeOn(AppState.userInitiatedBgScheduler)
                .subscribe(onNext: { _ in
                    self.uiActions.onNext(OpenChannelEvents.startOpening)
                })
                .disposed(by: disposeBag)
    }

    private func connectDismissButton() {
        dismissButton.rx.tap
                .asObservable()
                .subscribe(onNext: { _ in
                    self.dismiss(animated: true)
                })
                .disposed(by: disposeBag)
    }

    private func getConfimer() -> UIAlertController {
        var message: String
        do {
            let state = try self.state.value()
            message = "A typical transaction is 250 bytes. Fees will be approximately \(state.numSats * 250) sat"
        } catch (let error) {
            print(error)
            message = "A typical transaction is 250 bytes. Fees will be approximately ? sat"
        }

        let alert = UIAlertController(
                title: "Confirm opening channel",
                message: message,
                preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.actions.onNext(.openChannel2)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))

        return alert
    }

    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        let vc = QRCodeReaderViewController(builder: builder)
        vc.delegate = self
        return vc
    }()

    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        stateChange.onNext(.qrScanned(result.value))
        dismiss(animated: true)
    }

    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        dismiss(animated: true)
    }

    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        capacity.endEditing(true)
    }

}
