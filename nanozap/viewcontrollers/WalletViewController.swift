import UIKit
import Foundation
import RxSwift
import RxCocoa
import SnapKit

class WalletViewController: UIViewController {
    var headerView: UIView!
    var transactionsView: UITableView!
    var walletbalanceLabel: UILabel!
    var payInvoiceButton: UIButton!
    var createInvoiceButton: UIButton!
    var openChannelButton: UIButton!

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

        headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor.cyan
        transactionsView = UITableView()
        transactionsView.register(UITableViewCell.self, forCellReuseIdentifier: "TransactionCell")
        transactionsView.translatesAutoresizingMaskIntoConstraints = false
        walletbalanceLabel = createLabel(text: "")
        walletbalanceLabel.textAlignment = .center

        payInvoiceButton = createButton(text: "Pay invoice")
        payInvoiceButton.addTarget(self, action: #selector(payInvoiceClicked), for: .touchUpInside)

        createInvoiceButton = createButton(text: "Create invoice")
        openChannelButton = createButton(text: "Open Channel")

        view.addSubview(headerView)
        view.addSubview(transactionsView)
        view.addSubview(walletbalanceLabel)
        view.addSubview(payInvoiceButton)
        view.addSubview(createInvoiceButton)
        view.addSubview(openChannelButton)

        createInvoiceButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.payInvoiceButton).offset(30)
            make.centerX.equalTo(self.payInvoiceButton)
        }
        let views: [String: UIView] = [
            "headerView": headerView,
            "transactionsView": transactionsView,
            "payInvoiceButton": payInvoiceButton,
            "createInvoiceButton": createInvoiceButton,
            "walletbalanceLabel": walletbalanceLabel,
            "openChannelButton": openChannelButton
        ]

        setConstraints(views: views)

        txDateFormatter.dateFormat = "MM.dd"

        headerView.backgroundColor = headerColor

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

        openChannelButton.rx.tap
                .asObservable()
                .subscribe(onNext: { _ in
                    let vc = OpenChannelViewController()
                    self.present(vc, animated: true)
                })

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

    private func setConstraints(views: [String: UIView]) {
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-0-[headerView(100)]-100-[walletbalanceLabel(40)]-[payInvoiceButton]-40-[openChannelButton]-100-[transactionsView]-0-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[walletbalanceLabel]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[payInvoiceButton]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-20-[openChannelButton]-20-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-0-[headerView]-0-|",
                metrics: nil,
                views: views))
        view.addConstraints(NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-10-[transactionsView]-10-|",
                metrics: nil,
                views: views))
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
