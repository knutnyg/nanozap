import Foundation
import UIKit

struct ChannelCellModel {
    let channel : Channel
}

class ChannelCell : UITableViewCell {
    var topLeftLabel : UILabel!
    var botLeftLabel : UILabel!
    var botRightLabel : UILabel!
    
    var model : ChannelCellModel?

    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: "ChannelCell")
        topLeftLabel = UILabel()
        topLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        topLeftLabel.text = "topLeft"

        botLeftLabel = UILabel()
        botLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        botLeftLabel.text = "bottomLeft"

        botRightLabel = UILabel()
        botRightLabel.translatesAutoresizingMaskIntoConstraints = false
        botRightLabel.text = "bottomRight"

        self.addSubview(topLeftLabel)
        self.addSubview(botLeftLabel)
        self.addSubview(botRightLabel)

        let views: [String: UIView] = [
            "topLeftLabel":topLeftLabel,
            "botLeftLabel":botLeftLabel,
            "botRightLabel": botRightLabel
        ]

        self.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-[topLeftLabel(20)]-10-[botLeftLabel(20)]-|",
                metrics: nil,
                views: views))
        self.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-[topLeftLabel]-10-[botRightLabel(20)]-|",
                metrics: nil,
                views: views))
        self.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-5-[topLeftLabel]-5-|",
                metrics: nil,
                views: views))
        self.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-5-[botLeftLabel]-5-[botRightLabel]-5-|",
                metrics: nil,
                views: views))
    }

    public static func make(model: ChannelCellModel) -> ChannelCell {
        let cell = ChannelCell()
        cell.model = model
        return cell
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
