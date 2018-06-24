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

    var channlIdLabel: UILabel!
    var dismissButton: UIButton!
    var heading: UILabel!
    var firstLine: UILabel!
    var secondLine: UILabel!
    var thirdLine: UILabel!
    var fourthLine: UILabel!
    var fifthLine: UILabel!
    var sixthLine: UILabel!
    var closeChannelBtn: UIButton!

    let closeChannelObs = PublishSubject<Channel>()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white

        channlIdLabel = createLabel(text: "")
        heading = createLabel(text: "")
        firstLine = createLabel(text: "")
        secondLine = createLabel(text: "")
        thirdLine = createLabel(text: "")
        fourthLine = createLabel(text: "")
        fifthLine = createLabel(text: "")
        sixthLine = createLabel(text: "")
        dismissButton = createButton(text: "dismiss")
        dismissButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        closeChannelBtn = createButton(text: "close")

        self.view.addSubview(channlIdLabel)
        self.view.addSubview(dismissButton)
        self.view.addSubview(heading)
        self.view.addSubview(firstLine)
        self.view.addSubview(secondLine)
        self.view.addSubview(thirdLine)
        self.view.addSubview(fourthLine)
        self.view.addSubview(fifthLine)
        self.view.addSubview(sixthLine)
        self.view.addSubview(closeChannelBtn)

        let views: [String:UIView] = [
            "channlIdLabel":channlIdLabel,
            "dismissButton":dismissButton,
            "heading":heading,
            "firstLine":firstLine,
            "secondLine":secondLine,
            "thirdLine":thirdLine,
            "fourthLine":fourthLine,
            "fifthLine":fifthLine,
            "sixthLine":sixthLine,
            "closeChannelBtn":closeChannelBtn
        ]

        setConstraints(views: views)
    }

    private func setConstraints(views: [String: UIView]) {
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-100-[channlIdLabel]-[heading]-[firstLine]-[secondLine]-[thirdLine]-[fourthLine]-[fifthLine]-[sixthLine]-[closeChannelBtn]-[dismissButton]",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[heading]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[firstLine]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[secondLine]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[thirdLine]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[fourthLine]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[sixthLine]-20-|",
                metrics: nil,
                views: views))

        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[closeChannelBtn]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[dismissButton]-20-|",
                metrics: nil,
                views: views))
    }


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

    @objc func dismiss(sender: UIButton!) {
        dismiss(animated: true, completion: nil)
    }

    public static func make(model: ChannelDetailModel) -> ChannelViewController {
        let chanView = ChannelViewController()
        chanView.model = model

        return chanView
    }
}
