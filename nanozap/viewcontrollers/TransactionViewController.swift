import UIKit
import Foundation
import RxSwift
import RxCocoa
import SnapKit

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
        self.addSubview(closeButton)
        self.addSubview(txIdLabel)
        self.addSubview(txTimeLabel)
        self.addSubview(txAmountLabel)

        let elementSpacing = 30
        txIdLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self).offset(150)
            make.left.equalTo(self).offset(elementSpacing)
            make.right.equalTo(self).offset(elementSpacing)
        }
        txAmountLabel.snp.makeConstraints { make in
            make.top.equalTo(txIdLabel).offset(elementSpacing)
            make.left.right.equalTo(txIdLabel)
        }
        txTimeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(txAmountLabel).offset(elementSpacing)
            make.left.right.equalTo(txIdLabel)
        }
        closeButton.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(self)
            make.top.equalTo(txTimeLabel).offset(2*elementSpacing)
            
        }
        
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
    
}

class TransactionDetailViewController : UIViewController, UITextFieldDelegate {
    private let disposeBag = DisposeBag()
    
    var model : TransactionDetailViewModel!
    var txView : TransactionDetailView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        model.closeTap
                .subscribe(onNext: { (_) in
                    print("tap")
                    self.dismiss(animated: true, completion: nil)
                })
                .disposed(by: disposeBag)
    }

    override func loadView() {
        super.loadView()
        if self.txView == nil {
            self.txView = TransactionDetailView(frame: CGRect.infinite, model: self.model)
        }
        self.view = self.txView
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
}
