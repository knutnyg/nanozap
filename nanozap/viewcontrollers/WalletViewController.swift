import UIKit
import Foundation
import RxSwift
import RxCocoa
import SnapKit

class WalletViewController: UIViewController {
    var headerView: UIViewController!
    var introTextView: UITextView!

    var transactionsView: UITableView!
    var walletbalanceLabel: UILabel!

    var sendBTCButton: UIButton!
    var receiveBTCButton: UIButton!

    var payInvoiceButton: UIButton!
    var createInvoiceButton: UIButton!

    let headerColor = NanoColors.deepBlue

    let rpcmanager: RpcManager = RpcManager.shared
    let disposeBag = DisposeBag()

    let loadSubject = BehaviorSubject<Void>(value: ())

    let walletSubject = BehaviorSubject<WalletData>(value: WalletData.initWallet)
    let transactionsSubject = BehaviorSubject<[Transaction]>(value: WalletData.initWallet.txs)
    let balanceSubject = BehaviorSubject<WalletBalance>(value: WalletData.initWallet.balance)

    let txDateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        headerView = Header()
        introTextView = createTextBox(text: "This is your lightning wallet. You can interact with the blockchain though sending, receiving, opening and closing channels.")

        transactionsView = UITableView()
        transactionsView.register(UITableViewCell.self, forCellReuseIdentifier: "TransactionCell")
        transactionsView.translatesAutoresizingMaskIntoConstraints = false
        walletbalanceLabel = createLabel(text: "")
        walletbalanceLabel.textAlignment = .center

        payInvoiceButton = createButton(text: "Pay invoice")
        payInvoiceButton.addTarget(self, action: #selector(payInvoiceClicked), for: .touchUpInside)

        sendBTCButton = createButton(text: "Send BTC")
        receiveBTCButton = createButton(text: "Receive BTC")

        createInvoiceButton = createButton(text: "Create invoice")

        view.addSubview(headerView.view)
        view.addSubview(introTextView)
        view.addSubview(transactionsView)
        view.addSubview(walletbalanceLabel)
        view.addSubview(payInvoiceButton)
        view.addSubview(createInvoiceButton)
        view.addSubview(sendBTCButton)
        view.addSubview(receiveBTCButton)

        headerView.view.snp.makeConstraints { (make) in
            make.top.equalTo(self.view)
            make.centerX.equalTo(self.view)
            make.width.equalTo(self.view)
            make.height.equalTo(100)
        }

        introTextView.snp.makeConstraints({ (make) in
            make.top.equalTo(headerView.view.snp.bottom).offset(15)
            make.centerX.equalTo(self.view)
            make.height.equalTo(100)
            make.width.equalTo(self.view).inset(10)
        })

        walletbalanceLabel.snp.makeConstraints({(make) in
            make.top.equalTo(introTextView.snp.bottom).offset(15)
            make.centerX.equalTo(self.view)
            make.height.equalTo(30)
        })

        payInvoiceButton.snp.makeConstraints({(make) in
            make.top.equalTo(walletbalanceLabel.snp.bottom).offset(15)
            make.centerX.equalTo(self.view).offset(-100)
            make.height.equalTo(30)
        })

        createInvoiceButton.snp.makeConstraints({(make) in
            make.top.equalTo(payInvoiceButton.snp.bottom).offset(15)
            make.centerX.equalTo(payInvoiceButton.snp.centerX)
            make.height.equalTo(30)
        })

        sendBTCButton.snp.makeConstraints({(make) in
            make.top.equalTo(walletbalanceLabel.snp.bottom).offset(15)
            make.centerX.equalTo(self.view).offset(100)
            make.height.equalTo(30)
        })

        receiveBTCButton.snp.makeConstraints({(make) in
            make.top.equalTo(payInvoiceButton.snp.bottom).offset(15)
            make.centerX.equalTo(sendBTCButton.snp.centerX)
            make.height.equalTo(30)
        })

        transactionsView.snp.makeConstraints({(make) in
            make.top.equalTo(createInvoiceButton.snp.bottom).offset(15)
            make.width.equalTo(self.view)
            make.bottom.equalTo(self.view)
        })

        txDateFormatter.dateFormat = "MM.dd"

        loadSubject.asObservable()
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { (_) in
                    WalletService.shared.getWallet().retry(3)
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
                .do(onNext: { tx in print("selected tx=", tx.txHash) })
                .map { (tx) in
                    TransactionDetailViewModel(tx: tx)
                }
                .map { (model) in
                    TransactionDetailViewController.make(model: model)
                }
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
                    let firstDestination = tx.destination.first ?? ""
                    var destination = firstDestination
                    if firstDestination.count > 16 {
                        destination = destination.truncate(length: 16)
                    }
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
                    WalletService.shared.getWallet().retry(3)
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
                    self.walletbalanceLabel.text! = "Confirmed: \(data.balance.confirmedBalance) SAT"
                    refreshControl.endRefreshing()
                }, onError: { (error) in
                    print("got error on refresh: ", error)
                    refreshControl.endRefreshing()
                })
                .disposed(by: disposeBag)

        createInvoiceButton.rx.tap.asObservable()
                .map { _ in
                    true
                }
                .map { _ in
                    CreatePaymentViewController()
                }
                .subscribe(
                        onNext: { [weak self] val in
                            self?.present(val, animated: true, completion: nil)
                        },
                        onError: { error in
                            print("error handling tap", error)
                            fatalError("died handling tap")
                        }
                ).disposed(by: disposeBag)


    }

    @objc func payInvoiceClicked(sender: UIButton!) {
        var invoiceVC = PayInvoiceViewController()
        invoiceVC.modalPresentationStyle = .popover
        present(invoiceVC, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
