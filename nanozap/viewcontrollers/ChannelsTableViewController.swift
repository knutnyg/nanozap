import Foundation
import UIKit
import RxSwift
import RxCocoa

class ChannelsTableViewController: UITableViewController {
    private let disposeBag = DisposeBag()

    var channels:[Channel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl

        refreshControl.rx
                .controlEvent(.valueChanged)
                .do(onNext: { () in print("refresh asdf") })
                .map { [refreshControl] _ in refreshControl.isRefreshing }

                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .filter { val in val == true }
                .map { [unowned self] _ in try self.getChannels() }
                .do(onNext: { (_) in
                    print("sleep 1")
                    sleep(1)
                } )

                // go back to main thread to touch UI
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (channels) in print("some refresh")
                    self.channels = channels
                    refreshControl.endRefreshing()
                }, onError: { (error) in
                    print("got error on refresh: ", error)
                    refreshControl.endRefreshing()
                })
                .disposed(by: disposeBag)

        refreshChannels()
    }

    private func getChannels() throws -> [Channel] {
        let channelService = ChannelServiceMock()
        let channels =  try channelService.getChannels()
                .sorted(by: { $0.localBalance > $1.localBalance })

        return channels
    }

    private func refreshChannels() {
        do {
            self.channels = try getChannels()
        } catch {
            print("Unexpected error: \(error).")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshChannels()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
        
        cell.textLabel?.text = "ID: \(channels[indexPath.row].channelId) $: \(channels[indexPath.row].localBalance)"
        
        return cell
    }
    
}
