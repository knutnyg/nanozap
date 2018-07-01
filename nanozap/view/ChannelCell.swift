import Foundation
import UIKit
import SnapKit

struct ChannelCellModel {
    let channel : Channel
}

class ChannelCell : UITableViewCell {
    var leftLabel : UILabel!
    var topLeftLabel : UILabel!
    var botLeftLabel : UILabel!
    var botRightLabel : UILabel!
    
    var model : ChannelCellModel?

    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: "ChannelCell")

        leftLabel = createLabel(text: "")
        topLeftLabel = createLabel(text: "topLeft", font: UIFont(name: "Helvetica", size: 14)!)
        botLeftLabel = createLabel(text: "bottomLeft")
        botRightLabel = createLabel(text: "bottomRight")

        self.addSubview(leftLabel)
        self.addSubview(topLeftLabel)
        self.addSubview(botLeftLabel)
        self.addSubview(botRightLabel)

        let rowWidth = 120
        let topBottomMargin = 7

        leftLabel.snp.makeConstraints { make in
            make.height.width.equalTo(35)
            make.centerY.equalTo(self)
            make.left.equalTo(self.snp.left).offset(10)
        }
        topLeftLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftLabel.snp.right).offset(10)
            make.height.equalTo(15)
            make.top.equalTo(self.snp.top).offset(topBottomMargin)
        }
        botLeftLabel.snp.makeConstraints { (make) in
            make.left.equalTo(topLeftLabel.snp.left)
            make.width.equalTo(rowWidth)
            make.height.equalTo(15)
            make.bottom.equalTo(self.snp.bottom).offset(-topBottomMargin)
        }
        botRightLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self.snp.right).offset(-1)
            make.width.equalTo(rowWidth)
            make.height.equalTo(15)
            make.bottom.equalTo(self.snp.bottom).offset(-topBottomMargin)
        }
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
