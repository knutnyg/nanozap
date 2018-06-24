import Foundation
import UIKit
import RxSwift
import RxCocoa
import Result

class ChannelsTableViewController: UITableViewController {
    private let disposeBag = DisposeBag()

    let loadChannels = BehaviorSubject<Void>(value: ())
    let channelsObs = BehaviorSubject<[Channel]>(value: [])

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = nil

        channelsObs.asObservable()
                .observeOn(MainScheduler.instance)
                .bind(to: self.tableView.rx.items(
                        cellIdentifier: "ChannelCell",
                        cellType: ChannelCell.self
                )) { (row, channel, cell : ChannelCell) in
                    let cellColor : UIColor = channel.active ? NanoColors.green : NanoColors.gray

                    cell.topLeftLabel?.textColor = cellColor
                    cell.topLeftLabel?.text = "ID: \(channel.channelId)"
                    cell.botRightLabel?.text = "Fee: \(channel.feePerKw)"
                    cell.botLeftLabel?.text = "Sat: \(channel.localBalance)"
                }
                .disposed(by: disposeBag)

        self.tableView.rx.modelSelected(Channel.self)
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { (channel : Channel) in
                    ChannelService.shared.getNodeInfo(pubkey: channel.remotePubkey)
                        .retry(3)
                        .map { (node) in ChannelDetailModel(channel: channel, node: node) }
                }
                .map { (model) in ChannelViewController.make(model: model) }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (view) in
                    //self.navigationController.pushViewController(nextViewController, animated: true)
                    self.present(view, animated: true, completion: nil)
                }, onError: { err in
                    print("error", err)
                    //TODO: display some message
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
                .map { [refreshControl] _ in refreshControl.isRefreshing }
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .filter { val in val == true }
                .map { [unowned self] _ in self.getChannels() }
                .do(onNext: { (_) in
                    // since we are in another thread, we can sleep without locking the UI!
                    print("sleep 1")
                    sleep(1)
                })
                // go back to main thread to touch UI
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onNext: { [weak self] (result) in
                            print("some refresh result")
                            switch (result) {
                            case .success(let chans):
                                self?.channelsObs.onNext(chans)
                                refreshControl.endRefreshing()
                            case .failure(let error):
                                print("got error on refresh: ", error)
                                refreshControl.endRefreshing()
                            }
                        },
                        onError: { (error) in
                            print("got error on refresh: ", error)
                            refreshControl.endRefreshing()
                        },
                        onCompleted: {
                            refreshControl.endRefreshing()
                        })
                .disposed(by: disposeBag)
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
