import Foundation
import UIKit

class Header : UIViewController {

    var titleLabel:UILabel!
    var settingsButton:UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = NanoColors.blue
        self.view.translatesAutoresizingMaskIntoConstraints = false

        titleLabel = createLabel(text: "Nanozap", font: UIFont(name: "Verdana", size: 24)!)
        titleLabel.textColor = NanoColors.yellow

        let iconSize = CGSize(width: 30, height: 30)
        let iconColor = NanoColors.yellow

        let icon = UIImage.fontAwesomeIcon(name: .cog, textColor: iconColor, size: iconSize)
        settingsButton = createFAButton(icon: icon)
        settingsButton.addTarget(self, action: #selector(settingsPressed), for: .touchUpInside)

        view.addSubview(titleLabel)
        view.addSubview(settingsButton)

        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.snp.bottom).offset(-15)
            make.centerX.equalTo(self.view)
        }

        settingsButton.snp.makeConstraints { make in
            make.centerX.equalTo(self.view.snp.right).offset(-40)
            make.bottom.equalTo(self.view.snp.bottom).offset(-15)
        }
    }

    @objc func settingsPressed(sender: UIButton) {
        let settingsVC = AuthViewController()
        settingsVC.modalPresentationStyle = .popover
        present(settingsVC, animated: true, completion: nil)
    }
}
