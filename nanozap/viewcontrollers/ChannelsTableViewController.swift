import Foundation
import UIKit
import RxSwift
import RxCocoa

class ChannelsTableViewController: UITableViewController {
    private let disposeBag = DisposeBag()

    var channels:[Channel] = []
    let loadChannels = BehaviorSubject<Void>(value: ())
    let channelsObs = BehaviorSubject<[Channel]>(value: [])

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: find out why I have to do this:
        self.tableView.dataSource = nil

        channelsObs.asObservable()
            .observeOn(MainScheduler.instance)
            .bind(to: self.tableView.rx.items(cellIdentifier: "LabelCell", cellType: UITableViewCell.self))
                { (row, channel, cell) in
                    //cell.textLabel?.text = "\(element) @ row \(row)"
                    cell.textLabel?.text = "ID: \(channel.channelId) $: \(channel.localBalance)"
                }
            .disposed(by: disposeBag)

        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl
        
        loadChannels
            // do network activity in background thread
            .observeOn(AppState.userInitiatedBgScheduler)
            .map { (_) throws in
                return try self.getChannels()
            }
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
                .subscribe(onNext: { (channels) in print("some refresh")
                    self.channels = channels
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
        let channels =  try channelService.getChannels()
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
        return self.channels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
        
        cell.textLabel?.text = "ID: \(channels[indexPath.row].channelId) $: \(channels[indexPath.row].localBalance)"

        return cell
    }
    
}
