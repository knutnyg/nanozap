import Foundation
import UIKit
import RxSwift
import RxCocoa

struct ChannelDetailModel {
    let channel: Channel
    let node: LndNode?
}

enum CloseChannelChoice {
    case yes(channel: Channel)
    case nevermind
}

class ChannelViewController: UIViewController {
    let disposeBag = DisposeBag()

    var model: ChannelDetailModel?

    @IBOutlet weak var channlIdLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var heading: UILabel!
    @IBOutlet weak var firstLine: UILabel!
    @IBOutlet weak var secondLine: UILabel!
    @IBOutlet weak var thirdLine: UILabel!
    @IBOutlet weak var fourthLine: UILabel!
    @IBOutlet weak var fifthLine: UILabel!
    @IBOutlet weak var sixthLine: UILabel!
    @IBOutlet weak var closeChannelBtn: UIButton!

    let closeChannelObs = PublishSubject<Channel>()

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        closeChannelBtn.layer.cornerRadius = 5
//        closeChannelBtn.layer.borderWidth = 1

        if let model = self.model {
            let channel = model.channel
            let state = model.channel.active ? "Active" : "Inactive"
            let node = model.node
            let alias = node.map { n in n.alias }.or("")
            let chanCount = node.map { n in "\(n.numChannels)" }.or("")
            let cap = node.map { n in "\(n.totalCapacity)" }.or("")
            let remoteKey = node.map { n in n.pubKey }.or("")
            let lastUpdated = node.map { n in ISO8601DateFormatter().string(from: n.lastUpdate) }.or("")

            channlIdLabel.text = "ChannelId: \(channel.channelId)"
            heading.textColor = heading.tintColor
            heading.text = "Node Info"
            firstLine.text = "State: \(state)"
            secondLine.text = "Alias: \(alias)"
            thirdLine.text = "Channels: \(chanCount)"
            fourthLine.text = "Total capacity: \(cap)"
            fifthLine.text = "Pub: \(remoteKey)"
            sixthLine.text = "LastUpdate: \(lastUpdated)"
        }

        let closeChannelsResults: Observable<CloseChannelChoice> = self.closeChannelBtn.rx.tap.asObservable()
                .map { _ in
                    self.model!.channel
                }
                .flatMap { channel in
                    return Observable.create { [weak self] sub in
                        guard let `self` = self else {
                            sub.onCompleted()
                            return Disposables.create()
                        }

                        let alert = UIAlertController(
                                title: "Closing channel",
                                message: "Sure you want to close channel?",
                                preferredStyle: .actionSheet
                        )
                        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                            print("Yes was clicked")
                            sub.onNext(.yes(channel: channel))
                            sub.onCompleted()
                        }))
                        alert.addAction(UIAlertAction(title: "Nevermind", style: .default, handler: { _ in
                            print("Nevermind was clicked")
                            sub.onNext(.nevermind)
                            sub.onCompleted()
                        }))

                        self.present(alert, animated: true)

                        return Disposables.create {
                            alert.dismiss(animated: true, completion: nil)
                        }
                    }
                }

        closeChannelsResults
                .observeOn(AppState.userInitiatedBgScheduler)
                .map { (val: CloseChannelChoice) -> Channel? in
                    switch (val) {
                    case .yes(let channel):
                        return channel
                    case .nevermind:
                        return nil
                    }
                }
                .flatMap { (channel: Channel?) -> Observable<CloseChannelResult> in
                    if let chan = channel {
                        return ChannelService.shared.closeChannel(channel: chan)
                    } else {
                        return Observable.empty()
                    }
                }
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onNext: { [weak self] res in
                            // maybe we were already gone by this time, so exit:
                            guard let `self` = self else {
                                return
                            }

                            print("closing res: \(res)")
                            self.firstLine?.text = "State: Closing..."
                        }
                        //, onError: , onCompleted: , onDisposed: ,
                )
                .disposed(by: self.disposeBag)
        
    }

    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    public static func make(model: ChannelDetailModel) -> ChannelViewController {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)

        let chanView: ChannelViewController = storyBoard.instantiateViewController(
                withIdentifier: "ChannelViewController"
        ) as! ChannelViewController
        chanView.model = model

        return chanView
    }
}
