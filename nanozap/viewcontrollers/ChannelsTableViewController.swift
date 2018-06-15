import Foundation
import UIKit
import RxSwift
import RxCocoa

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
                    let cellColor : UIColor = channel.active ? .green : .gray

                    cell.topLeftLabel?.textColor = cellColor
                    cell.topLeftLabel?.text = "ID: \(channel.channelId)"
                    cell.botRightLabel?.text = "Fee: \(channel.feePerKw)"
                    cell.botLeftLabel?.text = "Sat: \(channel.localBalance)"
                }
                .disposed(by: disposeBag)

        self.tableView.rx.modelSelected(Channel.self)
                .map { (channel) in ChannelDetailModel(channel: channel) }
                .map { (model) in ChannelViewController.make(model: model) }
                .subscribe(onNext: { (view) in
                    self.present(view, animated: true, completion: nil)
                })
                .disposed(by: disposeBag)

        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl
        
        loadChannels
            // do network activity in background thread
            .observeOn(AppState.userInitiatedBgScheduler)
            .map { (_) throws in
                return try self.getChannels()
            }
            .catchError({ (error) -> Observable<[Channel]> in
                print("caught error", error)
                return Observable.empty()
            })
            .bind(to: channelsObs)
            .disposed(by: disposeBag)
        
        refreshControl.rx
                .controlEvent(.valueChanged)
                .map { [refreshControl] _ in refreshControl.isRefreshing }
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .filter { val in val == true }
                .map { [unowned self] _ in try self.getChannels() }
                .do(onNext: { (_) in
                    // since we are in another thread, we can sleep without locking the UI!
                    print("sleep 1")
                    sleep(1)
                } )
                // go back to main thread to touch UI
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (channels) in
                    print("some refresh")
                    self.channelsObs.onNext(channels)
                    refreshControl.endRefreshing()
                }, onError: { (error) in
                    print("got error on refresh: ", error)
                    refreshControl.endRefreshing()
                })
                .disposed(by: disposeBag)
    }

    private func getChannels() throws -> [Channel] {
        let channelService = ChannelService()
        let channels = try channelService.getChannels()
                .sorted(by: { $0.localBalance > $1.localBalance })

        return channels
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
