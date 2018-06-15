import Foundation
import UIKit

struct ChannelDetailModel {
    let channel : Channel
    let node : LndNode?
}

class ChannelViewController : UIViewController {
    var model:ChannelDetailModel?

    @IBOutlet weak var channlIdLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var firstLine: UILabel!
    @IBOutlet weak var secondLine: UILabel!
    @IBOutlet weak var thirdLine: UILabel!
    @IBOutlet weak var fourthLine: UILabel!
    @IBOutlet weak var fifthLine: UILabel!
    @IBOutlet weak var sixthLine: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let model = self.model {
            let channel = model.channel
            let state = model.channel.active ? "Active" : "Inactive"
            let node = model.node
            let alias = node.map { n in n.alias }.or("")
            let chanCount = node.map { n in "\(n.numChannels)" }.or("")
            let cap = node.map { n in "\(n.totalCapacity)" }.or("")
            let remoteKey = node.map { n in n.pubKey }.or("")
            let GMT = TimeZone(abbreviation: "GMT")!
            let lastUpdated = node.map { n in ISO8601DateFormatter.string(from: n.lastUpdate, timeZone: GMT) }.or("")
            channlIdLabel.text = "ChannelId: \(channel.channelId)"
            firstLine.text = "State: \(state)"
            secondLine.text = "Alias: \(alias)"
            thirdLine.text = "Channels: \(chanCount)"
            fourthLine.text = "Total capacity: \(cap)"
            fifthLine.text = "Pub: \(remoteKey)"
            sixthLine.text = "LastUpdate: \(lastUpdated)"
        }
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
