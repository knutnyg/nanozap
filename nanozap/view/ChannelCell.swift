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
        botRightLabel.textAlignment = .right
        
        self.addSubview(leftLabel)
        self.addSubview(topLeftLabel)
        self.addSubview(botLeftLabel)
        self.addSubview(botRightLabel)

        let rowWidth = 240
        
        leftLabel.snp.makeConstraints { make in
            make.height.width.equalTo(35)
            make.centerY.equalTo(self)
            make.left.equalTo(self).offset(0)
        }
        topLeftLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftLabel.snp.right).offset(10)
            make.top.equalTo(self)
            make.width.equalTo(rowWidth)
        }
        botLeftLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftLabel.snp.right).offset(10)
            make.width.equalTo(rowWidth)
            make.bottom.equalTo(self)
        }
        
        botRightLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self.snp.right)
            make.width.equalTo(rowWidth/2)
            //make.top.equalTo(botLeftLabel.snp.top)
            make.bottom.equalTo(self).offset(0)
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
