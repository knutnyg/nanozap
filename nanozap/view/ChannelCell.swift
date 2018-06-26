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
        leftLabel = UILabel()
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        leftLabel.text = ""

        topLeftLabel = UILabel()
        topLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        topLeftLabel.text = "topLeft"
        
        botLeftLabel = UILabel()
        botLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        botLeftLabel.text = "bottomLeft"

        botRightLabel = UILabel()
        botRightLabel.translatesAutoresizingMaskIntoConstraints = false
        botRightLabel.text = "bottomRight"

        self.addSubview(leftLabel)
        self.addSubview(topLeftLabel)
        self.addSubview(botLeftLabel)
        self.addSubview(botRightLabel)

        let rowHeight = 50
        let rowWidth = 120
        leftLabel.snp.makeConstraints { make in
            make.height.width.equalTo(35)
            make.centerY.equalTo(self)
            make.left.equalTo(self.snp.left).offset(10)
        }
        topLeftLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftLabel.snp.right).offset(10)
            make.width.equalTo(rowWidth)
            make.height.equalTo(rowHeight)
            make.top.equalTo(self.snp.top).offset(20)
        }
        botLeftLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftLabel.snp.right).offset(20)
            make.width.equalTo(rowWidth)
            make.height.equalTo(rowHeight)
            make.bottom.equalTo(self.snp.bottom).offset(-10)
        }
        botRightLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self.snp.right).offset(-1)
            make.width.equalTo(rowWidth)
            make.height.equalTo(rowHeight)
            make.top.equalTo(botLeftLabel.snp.top)
            make.bottom.equalTo(self.snp.bottom).offset(-10)
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
