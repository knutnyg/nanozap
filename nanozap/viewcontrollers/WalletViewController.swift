import UIKit
import RxSwift
import RxCocoa

class WalletViewController: UIViewController {
    @IBOutlet weak var transactionsView: UITableView!
    @IBOutlet weak var walletbalanceLabel: UILabel!

    let rpcmanager: RpcManager = RpcManager.shared
    let disposeBag = DisposeBag()

    let loadSubject = BehaviorSubject<Void>(value: ())

    let walletSubject = BehaviorSubject<WalletData>(value: WalletData.initWallet)
    let transactionsSubject = BehaviorSubject<[Transaction]>(value: WalletData.initWallet.txs)
    let balanceSubject = BehaviorSubject<WalletBalance>(value: WalletData.initWallet.balance)

    let txDateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        txDateFormatter.dateFormat = "dd.MM"

        loadSubject.asObservable()
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { (_) in
                    WalletService.shared.getData()
                        .retry(3)
                }
                .catchError({ (error) -> Observable<WalletData> in
                    print("caught error", error)
                    return Observable.empty()
                })
                .bind(to: walletSubject)
                .disposed(by: disposeBag)

        walletSubject.asObservable()
                .subscribe(onNext: { (data) in
                    self.transactionsSubject.onNext(data.txs)
                    self.balanceSubject.onNext(data.balance)
                })
                .disposed(by: disposeBag)

        balanceSubject.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (bal) in
                self.walletbalanceLabel.text! = "\(bal.confirmedBalance)"
            })
            .disposed(by: disposeBag)

        transactionsView.rx
            .modelSelected(Transaction.self)
            .asObservable()
            .observeOn(AppState.userInitiatedBgScheduler)
            .map({ (tx) in
                print("selected tx=", tx.destination)
                let model = TransactionDetailViewModel(tx: tx)
                let view = TransactionDetailViewController.make(model: model)
                return view
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (view) in
                self.present(view, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
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
                .filter { val in
                    val == true
                }
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { (_) in
                    WalletService.shared.getData().retry(3)
                }
                .catchError({ (error) -> Observable<WalletData> in
                    print("caught error", error)
                    return Observable.empty()
                })
                // go back to main thread to touch UI
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (data) in
                    print("some refresh")
                    self.transactionsSubject.onNext(data.txs)
                    self.walletbalanceLabel.text! = "reload \(data.balance.confirmedBalance)"
                    refreshControl.endRefreshing()
                }, onError: { (error) in
                    print("got error on refresh: ", error)
                    refreshControl.endRefreshing()
                })
                .disposed(by: disposeBag)

    }

//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        self.performSegue(withIdentifier: "TransactionView", sender: self)
//    }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let vcc = segue.destination as? TransactionViewController {
//            let indexPath = self.transactionsView.indexPathForSelectedRow
//            vcc.transaction = try! self.transactionsSubject.value()[indexPath!.row]
//
//        }
//        super.prepare(for: segue, sender: sender)
//    }
//

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
