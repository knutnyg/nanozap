import UIKit

class TransactionViewController : UIViewController {

    @IBOutlet weak var transactionIdLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    
    var transaction:Transaction?

    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let transaction = self.transaction {
            self.transactionIdLabel.text = transaction.destination
        }
    }
}
