import Foundation
import UIKit
import SnapKit

struct InvoiceCellModel {
    let payable : Payable
    
    let leftVal : NSMutableAttributedString
    let topLeftVal : String
    let botLeftVal : String
    let botRightVal : String
}

class InvoiceCell : UITableViewCell {
    let leftLabel = createLabel(text: "")
    let topLeftLabel = createLabel(text: "topLeft", font: UIFont(name: "Helvetica", size: 14)!)
    let botLeftLabel = createLabel(text: "bottomLeft", font: UIFont(name: "Helvetica", size: 14)!)
    let botRightLabel = createLabel(text: "bottomRight")

    var model: InvoiceCellModel?

//    convenience init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//        self.init(style: .default, reuseIdentifier: "InvoiceCell")
//}

    override func layoutSubviews() {
        super.layoutSubviews()

        //leftLabel = createLabel(text: "")
        //topLeftLabel = createLabel(text: "topLeft", font: UIFont(name: "Helvetica", size: 14)!)
        //botLeftLabel = createLabel(text: "bottomLeft", font: UIFont(name: "Helvetica", size: 14)!)
        //botRightLabel = createLabel(text: "bottomRight")

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

    public func update(model: InvoiceCellModel) {
        self.model = model

        self.leftLabel.attributedText = model.leftVal
        self.topLeftLabel.text = model.topLeftVal
        self.botLeftLabel.text = model.botLeftVal
        self.botRightLabel.text = model.botRightVal
    }

}
