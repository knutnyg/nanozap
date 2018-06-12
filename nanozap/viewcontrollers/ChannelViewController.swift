import Foundation
import UIKit

class ChannelViewController : UIViewController {
    var channel:Channel?

    @IBOutlet weak var channlIdLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let channel = self.channel {
            channlIdLabel.text = "\(channel.channelId)"
        }
    }

    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
