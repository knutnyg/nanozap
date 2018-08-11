import Foundation
import UIKit
import RxSwift
import RxCocoa
import Result
import FontAwesome_swift

class ChannelsTableViewController: UITableViewController {
    private let disposeBag = DisposeBag()

    let loadChannels = BehaviorSubject<Void>(value: ())
    let channelsObs = BehaviorSubject<[Channel]>(value: [])

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = nil
        self.tableView.rowHeight = 60
        self.tableView.register(ChannelCell.self, forCellReuseIdentifier: "ChannelCell")
        self.tableView.rowHeight = 50

        channelsObs.asObservable()
                .observeOn(MainScheduler.instance)
                .bind(to: self.tableView.rx.items(
                        cellIdentifier: "ChannelCell",
                        cellType: ChannelCell.self
                )) { (row, channel, cell : ChannelCell) in
                    let iconSize = CGSize(width: 30, height: 30)
                    let activeImage = UIImage.fontAwesomeIcon(name: .link, textColor: NanoColors.green, size: iconSize)
                    let inactiveImage = UIImage.fontAwesomeIcon(name: .link, textColor: NanoColors.gray, size: iconSize)
                    
                    let attachment = NSTextAttachment()
                    attachment.image = channel.active ? activeImage : inactiveImage
                    let imageOffsetY:CGFloat = 0.0;
                    attachment.bounds = CGRect(x: 0, y: imageOffsetY, width: attachment.image!.size.width, height: attachment.image!.size.height)

                    let attachmentString = NSAttributedString(attachment: attachment)

                    let myString = NSMutableAttributedString(string: "")
                    myString.append(attachmentString)
                    
                    //let myString1 = NSMutableAttributedString(string: "My label text")
                    //myString.append(myString1)

                    //let cellColor : UIColor = channel.active ? NanoColors.green : NanoColors.gray
                    //cell.topLeftLabel?.textColor = cellColor
                    cell.leftLabel?.attributedText = myString
                    cell.topLeftLabel?.text = "ID: \(channel.channelId)"
                    cell.botRightLabel?.text = "Fee: \(channel.feePerKw)"
                    cell.botLeftLabel?.text = "Sat: \(channel.localBalance)"
                }
                .disposed(by: disposeBag)

        self.tableView.rx.modelSelected(Channel.self)
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { (channel : Channel) in
                    self.getNodeInfo(channel.remotePubkey)
                        .map { result in result.map { nodeinfo in
                            ChannelDetailModel(channel: channel, node: nodeinfo)
                         } }
                }
                .map { result in result.map { model in ChannelViewController.make(model: model) } }
                //.map { (model) in ChannelViewController.make(model: model) }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (result) in
                    //self.navigationController.pushViewController(nextViewController, animated: true)
                    switch (result) {
                    case .success(let view):
                        self.present(view, animated: true, completion: nil)
                    case .failure(let err):
                        print("load channel error", err)
                        displayError(message: "Error loading channel data.")
                    }
                    
                }, onError: { err in
                    print("fatal error", err)
                    fatalError("observable died")
                })
                .disposed(by: disposeBag)

        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl

        loadChannels
            // do network activity in background thread
            .observeOn(AppState.userInitiatedBgScheduler)
            .map { (_) in self.getChannels() }
            .flatMap { result -> Observable<[Channel]> in
                switch (result) {
                case .success(let chans):
                    return Observable.just(chans)
                case .failure(let error):
                    print("caught error", error)
                    return Observable.empty()
                }
            }
            .bind(to: channelsObs)
            .disposed(by: disposeBag)

        refreshControl.rx
                .controlEvent(.valueChanged)
                .map { [weak refreshControl] _ in refreshControl?.isRefreshing ?? false }
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .filter { val in val == true }
                .map { [unowned self] _ in self.getChannels() }
                // go back to main thread to touch UI
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onNext: { [weak self] result in
                            print("some refresh result")
                            switch (result) {
                            case .success(let chans):
                                self?.channelsObs.onNext(chans)
                                refreshControl.endRefreshing()
                            case .failure(let error):
                                print("got error on refresh: ", error)
                                refreshControl.endRefreshing()
                                displayError(message: "Error refreshing channels.")
                            }
                        },
                        onError: { (error) in
                            print("refreshcontrol died: ", error)
                            fatalError("refreshcontrol died!")
                        },
                        onCompleted: {
                            refreshControl.endRefreshing()
                        })
                .disposed(by: disposeBag)
    }

    private func getNodeInfo(_ pubkey: String) -> Observable<Result<LndNode, RPCError>> {
        return ChannelService.shared
                .getNodeInfo(pubkey: pubkey)
                .retry(3)
                //.map { (node) in ChannelDetailModel(channel: channel, node: node) }
                //.map { model -> Result<LndNode, RPCError> in Result(value: model) }
                .catchError { (errors) in
                    let val : Result<LndNode, RPCError> = Result(error: RPCError.genericError(error: errors))
                    return Observable.just(val)
                }
    }

    private func getChannels() -> Result<[Channel], AnyError> {
        return Result(attempt: { () throws -> [Channel] in try ChannelService.shared.getChannels() } )
            .map { chans in chans.sorted(by: { $0.localBalance > $1.localBalance }) }
    }

    private func refreshChannels() {
        loadChannels.onNext(())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshChannels()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        do {
            return try self.channelsObs.value().count
        } catch {
            return 0
        }
    }
}
