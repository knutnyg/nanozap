import Foundation
import UIKit
import QRCodeReader
import RxSwift
import SnapKit

enum OpenChannelActions {
    case connectToNode(nodeRaw: String)
    case openChannel(nodeAddr: String)
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

enum OpenChannelViewState {
    case newNode(String)
    case peers([String])
    case channelOpened
    case initial
}

class OpenChannelViewController: UIViewController, QRCodeReaderViewControllerDelegate {

    let actions = PublishSubject<OpenChannelActions>()
    let uiActions = PublishSubject<OpenChannelEvents>()
    let model = BehaviorSubject<OpenChannelViewState>(value: .initial)
    let disposeBag = DisposeBag()

    var scanButton: UIButton!
    var openButton: UIButton!
    var dismissButton: UIButton!
    var nodeIdLabel: UILabel!

    var confirmOpen: UIAlertController!

    var peers: [String] = []

    override func loadView() {
        super.loadView()

        view.backgroundColor = UIColor.white

        scanButton = createButton(text: "Scan")
        openButton = createButton(text: "Open Channel")
        dismissButton = createButton(text: "Dismiss")
        nodeIdLabel = createLabel(text: "")

        view.addSubview(scanButton)
        view.addSubview(openButton)
        view.addSubview(dismissButton)
        view.addSubview(nodeIdLabel)

        scanButton.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(200)
            make.centerX.equalTo(self.view)
        }

        openButton.snp.makeConstraints { make in
            make.top.equalTo(scanButton.snp.bottom).offset(50)
            make.centerX.equalTo(self.view)
        }

        nodeIdLabel.snp.makeConstraints { make in
            make.top.equalTo(openButton.snp.bottom).offset(50)
            make.centerX.equalTo(self.view)
        }

        dismissButton.snp.makeConstraints { make in
            make.top.equalTo(nodeIdLabel.snp.bottom).offset(50)
            make.centerX.equalTo(self.view)
        }

        connectScanButton()
        connectOpenButton()
        connectDismissButton()

        uiActions
                .subscribe(onNext: { event in
                    switch (event) {
                    case .startScan: self.present(self.readerVC, animated: true)
                    case .startOpening: self.present(self.confirmOpen!, animated: true)
                    case .displaySuccess(let msg): displaySuccess(message: msg)
                    case .displayFailure(let msg): displayError(message: msg)
                    }
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
                                    displayError(message: "Failure :(")
                                    return Observable.empty()
                                }
                                .map { res in
                                    .peersFetched(result: res)
                                }

                    case .connectToNode(let raw):
                        let pubkey = raw.components(separatedBy: "@").first ?? ""
                        let hostname = raw.components(separatedBy: "@").last ?? ""

                        if self.peers.contains(pubkey) {
                            print("We are already connected to node: \(pubkey)")
                            return Observable.of(OpenChannelActionResponses.nodeConnected(nodeAddr: pubkey))
                        }

                        return ChannelService.shared.connectToNode(pubkey: pubkey, host: hostname)
                                .retry(3)
                                .catchError { error in
                                    print(error)
                                    self.uiActions.onNext(.displayFailure(message: "failed to connect to node."))
                                    return Observable.empty()
                                }
                                .map { res in
                                    OpenChannelActionResponses.nodeConnected(nodeAddr: pubkey)
                                }
                    case .openChannel(let nodeAddr):
                        return ChannelService.shared.openChannel(nodeAddr: nodeAddr, satPerByte: 1)
                                .retry(3)
                                .catchError { error in
                                    print(error)
                                    self.uiActions.onNext(.displayFailure(message: "failed to open channel."))
                                    return Observable.empty()
                                }
                                .map { res in
                                    OpenChannelActionResponses.channelOpened(result: res)
                                }
                    }
                }

                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (res: OpenChannelActionResponses) in
                    switch (res) {
                    case .peersFetched(let res):
                        self.model.onNext(.peers(res.peers))
                    case .channelOpened:
                        self.uiActions.onNext(.displaySuccess(message: "Channel opened!"))
                        self.model.onNext(.channelOpened)
                    case .nodeConnected(let nodeAddr):
                        self.model.onNext(.newNode(nodeAddr))
                        self.uiActions.onNext(.displaySuccess(message: "Connected!"))
                    }

                })
                .disposed(by: disposeBag)

        model
                .asObservable()
                .subscribe(onNext: { (state: OpenChannelViewState) in
                    switch (state) {
                    case .initial: self.openButton.isEnabled = false
                    case .newNode(let addr):
                        self.setupConfirm(nodePubKey: addr)
                        self.nodeIdLabel.text = addr
                        self.openButton.isEnabled = true
                    case .peers(let peers): self.peers = peers
                    case .channelOpened: self.openButton.isEnabled = false
                    }
                })
                .disposed(by: disposeBag)

        actions.onNext(.fetchPeers)
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

    private func setupConfirm(nodePubKey: String) {
        let alert = UIAlertController(
                title: "Open Channel?",
                message: "Confirm opening channel",
                preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.actions.onNext(.openChannel(nodeAddr: nodePubKey))
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        self.confirmOpen = alert
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
        actions.onNext(.connectToNode(nodeRaw: result.value))
        dismiss(animated: true)
    }

    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        dismiss(animated: true)
    }

}
