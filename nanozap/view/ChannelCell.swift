import Foundation
import UIKit

struct ChannelCellModel {
    let channel : Channel
}

class ChannelCell : UITableViewCell {
    @IBOutlet var topLeftLabel : UILabel?
    @IBOutlet var botLeftLabel : UILabel?
    @IBOutlet var botRightLabel : UILabel?
    
    var model : ChannelCellModel?
    
    public static func make(model: ChannelCellModel) -> ChannelCell {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let cell: ChannelCell = storyBoard.instantiateViewController(
                withIdentifier: "ChannelCell"
        ) as! ChannelCell
        cell.model = model
        
        return cell
    }
    
}
