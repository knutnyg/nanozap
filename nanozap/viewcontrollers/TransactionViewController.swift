import UIKit
import Foundation
import RxSwift
import RxCocoa

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
            self.transactionIdLabel.text = transaction.destination.first ?? "None"
        }
    }
}

struct TransactionDetailViewModel {
    let tx : Transaction
    let closeTap = PublishSubject<Void>()
}

class TransactionDetailView : UIView {
    let screenSize = UIScreen.main.bounds

    let disposeBag = DisposeBag()

    public lazy var closeButton: UIButton! = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = .white
        btn.setTitleColor(self.tintColor, for: .normal)
        btn.setTitle("Close", for: .normal)

        return btn
    }()

    public lazy var txIdLabel: UILabel! = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.backgroundColor = .white
        lbl.text = ""
        lbl.textColor = UIColor.darkText

        return lbl
    }()
    
    public lazy var txTimeLabel: UILabel! = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.backgroundColor = .white
        lbl.text = ""
        lbl.textColor = .darkText

        return lbl
    }()
    
    public lazy var txAmountLabel: UILabel! = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.backgroundColor = .white
        lbl.text = ""
        lbl.textColor = .darkText
        
        return lbl
    }()

    lazy var textField: UITextField! = {
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.borderStyle = .roundedRect
        view.textAlignment = .center
        view.text = "tester"

        return view
    }()

    var model : TransactionDetailViewModel!

    // This is also necessary when extending the superclass.
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") // or see Roman Sausarnes's answer
    }

    private override init(frame: CGRect) {
        super.init(frame: frame)
    }

    convenience init(frame: CGRect, model: TransactionDetailViewModel!) {
        self.init(frame: frame)
        self.model = model
        self.backgroundColor = UIColor.white
        self.addSubview(textField)
        self.addSubview(closeButton)
        self.addSubview(txIdLabel)
        self.addSubview(txTimeLabel)
        self.addSubview(txAmountLabel)

        self.setNeedsUpdateConstraints()
        self.closeButton.rx.tap.asObservable()
            .bind(to: self.model.closeTap)
            .disposed(by: disposeBag)

        var dest = self.model.tx.destination.first ?? ""
        dest = dest.truncate(length: 22)
        self.txIdLabel.text = "To: \(dest)"

        //let format = ISO8601DateFormatter()
        let format = DateFormatter()
        format.dateFormat = "YYYY.MM.dd HH:mm"
        let timestamp = format.string(from: self.model.tx.timestamp)
        self.txTimeLabel.text = "Date: \(timestamp)"
        
        let amount = self.model.tx.amount
        self.txAmountLabel.text = "Sat: \(amount)"
    }
    
    override func updateConstraints() {
        textFieldConstraints()
        closeButtonConstraints()
        labelConstraints(label: self.txIdLabel)
        txAmountConstraints()
        txDateConstraints()
        super.updateConstraints()
    }

    func closeButtonConstraints() {
        //closeButton:
        // Center Text Field Relative to Page View
        NSLayoutConstraint(
            item: self.closeButton,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1.0,
            constant: 0.0
        ).isActive = true
        
        // Set btn Width to be 30% of the Width of the Page View
        NSLayoutConstraint(
            item: self.closeButton,
            attribute: .width,
            relatedBy: .equal,
            toItem: self,
            attribute: .width,
            multiplier: 0.3,
            constant: 0.0
        ).isActive = true
        
        // Set button Y Position 10% up From the bottom of the Page View
        NSLayoutConstraint(
            item: self.closeButton,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self,
            attribute: .bottom,
            multiplier: 0.8,
            constant: 0.0
        ).isActive = true
    }

    func textFieldConstraints() {
//        // Center Text Field Relative to Page View
//        NSLayoutConstraint(
//                item: self.textField,
//                attribute: .centerX,
//                relatedBy: .equal,
//                toItem: self,
//                attribute: .centerX,
//                multiplier: 1.0,
//                constant: 0.0
//        ).isActive = true
//
//        // Set Text Field Width to be 80% of the Width of the Page View
//        NSLayoutConstraint(
//                item: self.textField,
//                attribute: .width,
//                relatedBy: .equal,
//                toItem: self,
//                attribute: .width,
//                multiplier: 0.8,
//                constant: 0.0
//        ).isActive = true
//
//        // Set Text Field Y Position 10% Down From the Top of the Page View
//        NSLayoutConstraint(
//                item: self.textField,
//                attribute: .top,
//                relatedBy: .equal,
//                toItem: self,
//                attribute: .bottom,
//                multiplier: 0.1,
//                constant: 0.0
//        ).isActive = true
    }

    func txAmountConstraints() {
        // Center Text Field Relative to Page View
        NSLayoutConstraint(
            item: self.txAmountLabel,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1.0,
            constant: 0.0
            ).isActive = true
        
        // Set Text Field Width to be 80% of the Width of the Page View
        NSLayoutConstraint(
            item: self.txAmountLabel,
            attribute: .width,
            relatedBy: .equal,
            toItem: self,
            attribute: .width,
            multiplier: 0.8,
            constant: 0.0
            ).isActive = true
        
        NSLayoutConstraint(
            item: self.txAmountLabel,
            attribute: .top,
            relatedBy: .equal,
            toItem: self.txIdLabel,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 10.0
            ).isActive = true
    }

    func txDateConstraints() {
        // Center Text Field Relative to Page View
        NSLayoutConstraint(
            item: self.txTimeLabel,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1.0,
            constant: 0.0
            ).isActive = true
        
        // Set Text Field Width to be 80% of the Width of the Page View
        NSLayoutConstraint(
            item: self.txTimeLabel,
            attribute: .width,
            relatedBy: .equal,
            toItem: self,
            attribute: .width,
            multiplier: 0.8,
            constant: 0.0
            ).isActive = true
        
        NSLayoutConstraint(
            item: self.txTimeLabel,
            attribute: .top,
            relatedBy: .equal,
            toItem: self.txAmountLabel,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 10.0
            ).isActive = true
    }

    func labelConstraints(label: UILabel!) {
        // Center Text Field Relative to Page View
        NSLayoutConstraint(
                item: label,
                attribute: .centerX,
                relatedBy: .equal,
                toItem: self,
                attribute: .centerX,
                multiplier: 1.0,
                constant: 0.0
        ).isActive = true

        // Set Text Field Width to be 80% of the Width of the Page View
        NSLayoutConstraint(
                item: label,
                attribute: .width,
                relatedBy: .equal,
                toItem: self,
                attribute: .width,
                multiplier: 0.8,
                constant: 0.0
        ).isActive = true

        // Set Y Position 30% Down From the Top of the Page View
        NSLayoutConstraint(
                item: label,
                attribute: .top,
                relatedBy: .equal,
                toItem: self,
                attribute: .bottom,
                multiplier: 0.3,
                constant: 0.0
        ).isActive = true
    }
}

class TransactionDetailViewController : UIViewController, UITextFieldDelegate {
    private let disposeBag = DisposeBag()
    
    var model : TransactionDetailViewModel!
    var txView : TransactionDetailView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.view.backgroundColor = UIColor.green
//        if model == nil {
//            self.model = TransactionDetailViewModel()
//        }
//        let frame = CGRect(x:0, y:0, width:self.view.frame.size.width, height:self.view.frame.size.height)
//        self.txView = TransactionDetailView(frame: frame)
//        self.view.addSubview(txView!)
//

        model.closeTap
                .subscribe(onNext: { (_) in
                    print("tap")
                    self.dismiss(animated: true, completion: nil)
                })
                .disposed(by: disposeBag)

        self.view.setNeedsUpdateConstraints()
        //txView!.textField.delegate = self
        // AutoLayout
        //txView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
    }

    override func loadView() {
        //super.loadView()
        if self.txView == nil {
            self.txView = TransactionDetailView(frame: CGRect.infinite, model: self.model)
        }
        self.view = self.txView
    }

//    static func makeMemeDetailVC(meme: Meme) -> MemeDetailVC {
//        let newViewController = UIStoryboard(name: "Main", bundle: nil)
//            .instantiateViewControllerWithIdentifier("IdentifierOfYouViewController") as! MemeDetailVC
//
//        newViewController.meme = meme
//
//        return newViewController
//    }

//    override func updateViewConstraints() {
//        super.updateViewConstraints()
//    }

    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Dismisses the Keyboard by making the text field resign
        // first responder
        textField.resignFirstResponder()

        // returns false. Instead of adding a line break, the text
        // field resigns
        return false
    }

    // This allows you to initialise your custom UIViewController without a nib or bundle.
    convenience init(model : TransactionDetailViewModel) {
        self.init(nibName:nil, bundle:nil)
        self.model = model
    }

    // This is also necessary when extending the superclass.
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") // or see Roman Sausarnes's answer
    }

    // This extends the superclass:
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        //tap = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    public static func make(model: TransactionDetailViewModel) -> TransactionDetailViewController {
        let mvc = TransactionDetailViewController(model: model)
        return mvc
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
