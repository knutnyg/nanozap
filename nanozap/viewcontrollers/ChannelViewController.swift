import Foundation
import UIKit

struct ChannelDetailModel {
    let channel : Channel
}

class ChannelViewController : UIViewController {
    var model:ChannelDetailModel?

    @IBOutlet weak var channlIdLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let model = self.model {
            let channel = model.channel
            channlIdLabel.text = "\(channel.channelId)"
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
