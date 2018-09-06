import Foundation
import UIKit
import RxSwift
import RxCocoa
import Result
import FontAwesome_swift

enum LoadChannelsState {
    case loading()
    case done(res: [ChannelE])
    case failure(error: Error)
}

class ChannelsTableViewController: UITableViewController {
    private let disposeBag = DisposeBag()

    let loadChannels = BehaviorSubject<Void>(value: ())
    let channelsObs = BehaviorSubject<[ChannelE]>(value: [])

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = nil
        self.tableView.rowHeight = 60
        self.tableView.register(ChannelCell.self, forCellReuseIdentifier: "ChannelCell")
        self.tableView.rowHeight = 50

        channelsObs
                .asObservable()
                .observeOn(MainScheduler.instance)
                .bind(to: self.tableView.rx.items(
                        cellIdentifier: "ChannelCell",
                        cellType: ChannelCell.self
                )) { (row, channel: ChannelE, cell: ChannelCell) in
                    switch (channel) {
                    case .active(let openChannel):
                        let iconSize = CGSize(width: 30, height: 30)
                        let activeImage = UIImage.fontAwesomeIcon(name: .link, textColor: NanoColors.green, size: iconSize)
                        let inactiveImage = UIImage.fontAwesomeIcon(name: .link, textColor: NanoColors.gray, size: iconSize)

                        let attachment = NSTextAttachment()
                        attachment.image = openChannel.active ? activeImage : inactiveImage
                        let imageOffsetY: CGFloat = 0.0;
                        attachment.bounds = CGRect(x: 0, y: imageOffsetY, width: attachment.image!.size.width, height: attachment.image!.size.height)

                        let attachmentString = NSAttributedString(attachment: attachment)

                        let myString = NSMutableAttributedString(string: "")
                        myString.append(attachmentString)

                        //let myString1 = NSMutableAttributedString(string: "My label text")
                        //myString.append(myString1)

                        //let cellColor : UIColor = openChannel.active ? NanoColors.green : NanoColors.gray
                        //cell.topLeftLabel?.textColor = cellColor
                        cell.leftLabel?.attributedText = myString
                        cell.topLeftLabel?.text = "ID: \(openChannel.channelId)"
                        cell.botRightLabel?.text = "Fee: \(openChannel.feePerKw)"
                        cell.botLeftLabel?.text = "Sat: \(openChannel.localBalance)"

                    case .pending:
                        cell.topLeftLabel.text = "Pending.."
                    }
                }
                .disposed(by: disposeBag)

        self.tableView.rx.modelSelected(Channel.self)
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { (channel: Channel) in
                    self.getNodeInfo(channel.remotePubkey)
                            .map { result in
                                result.map { nodeinfo in
                                    ChannelDetailModel(channel: channel, node: nodeinfo)
                                }
                            }
                }
                .map { result in
                    result.map { model in
                        ChannelViewController.make(model: model)
                    }
                }
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
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { [weak self] (_) in
                    self?.getChannels() ?? Observable.empty()
                }
                .bind(to: channelsObs)
                .disposed(by: disposeBag)

        refreshControl.rx
                .controlEvent(.valueChanged)
                .map { [weak self] _ in
                    self?.refreshControl?.isRefreshing ?? false
                }
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .filter { val in
                    val == true
                }
                .flatMap { _ in
                    self.getChannels()
                            .map { chan in LoadChannelsState.done(res: chan) }
                            .catchError { err in Observable.just(LoadChannelsState.failure(error: err)) }
                            .startWith(LoadChannelsState.loading())
                }
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onNext: { [weak self] result in
                            print("some refresh result")
                            switch (result) {
                            case .loading:
                                // do nothing
                                print("loading")
                            case .done(let chan):
                                self?.channelsObs.onNext(chan)
                                self?.refreshControl?.endRefreshing()
                            case .failure(let error):
                                print("got error on refresh: ", error)
                                self?.refreshControl?.endRefreshing()
                                displayError(message: "Error refreshing invoices.")
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
                    let val: Result<LndNode, RPCError> = Result(error: RPCError.genericError(error: errors))
                    return Observable.just(val)
                }
    }

    private func getChannels() -> Observable<[ChannelE]> {
        return ChannelService.shared.listChannels()
                .map { (values: [ChannelE]) in
                    return values.sorted(by: { (lhs, rhs) in
                        return rhs < lhs
                    })
                }
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
