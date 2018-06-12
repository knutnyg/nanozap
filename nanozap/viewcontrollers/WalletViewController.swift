import UIKit
import RxSwift
import RxCocoa

class WalletViewController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var transactionsView: UITableView!
    @IBOutlet weak var walletbalanceLabel: UILabel!
    
    let rpcmanager: RpcManager = RpcManager.shared
    let disposeBag = DisposeBag()

    let transactionsSubject = BehaviorSubject<[Transaction]>(value: [])

    let txDateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        txDateFormatter.dateFormat = "dd.MM"

        // TODO: find out why I have to do this:
        self.transactionsView.dataSource = nil

        //self.transactionsView.delegate = self
        //self.transactionsView.dataSource = self

        transactionsSubject.asObservable()
                .observeOn(MainScheduler.instance)
                .bind(to: self.transactionsView.rx.items(
                        cellIdentifier: "TransactionCell",
                        cellType: UITableViewCell.self
                )) { (row, tx, cell) in
                    let dato = self.txDateFormatter.string(from: tx.timestamp)
                    let destination = tx.destination.dropLast(tx.destination.count - 8)
                    let amount = tx.amount

                    cell.textLabel?.text = "\(dato) - \(destination)... - \(amount)"
                }
                .disposed(by: disposeBag)

        let refreshControl = UIRefreshControl()
        transactionsView.refreshControl = refreshControl

        refreshControl.rx
                .controlEvent(.valueChanged)
                .map { [refreshControl] _ in
                    refreshControl.isRefreshing
                }
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .filter { val in
                    val == true
                }
                .map { [unowned self] _ in
                    try self.getTransactionList()
                }
                .do(onNext: { (_) in
                    // since we are in another thread, we can sleep without locking the UI!
                    print("sleep 1")
                    sleep(1)
                })
                .catchError({ (error) -> Observable<[Transaction]> in
                    print("caught error", error)
                    return Observable.empty()
                })
                // go back to main thread to touch UI
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (txs) in
                    print("some refresh")
                    self.transactionsSubject.onNext(txs)
                    refreshControl.endRefreshing()
                }, onError: { (error) in
                    print("got error on refresh: ", error)
                    refreshControl.endRefreshing()
                })
                .disposed(by: disposeBag)
        
        reloadTxs()
    }

    func reloadTxs() {
        do {
            let res = try getBalance()
            walletbalanceLabel.text = String(format: "Balance: %ld", res)

            let txs = try getTransactionList()
            transactionsSubject.onNext(txs)
            
        } catch {
            print("Unexpected error: \(error).")
        }
    }

    func getBalance() throws -> Int {
        return try WalletService.shared.getBalance()
    }

    func getTransactionList() throws -> [Transaction] {
        return try WalletService.shared.listTransactions()
                .sorted(by: { $0.timestamp > $1.timestamp })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
