import UIKit
import Foundation
import RxSwift
import RxCocoa
import SnapKit

enum WalletUIActions {
    case wallet(walletData: WalletData)
    case openDeposit(DepositViewController)
    case openChannel
    case openCreateInvoice
    case selectedTx(Transaction)
    case failure(Error)
    case loading
}

class WalletViewController: UIViewController {
    var headerView: UIView!
    var transactionsView: UITableView!
    var walletbalanceLabel: UILabel!
    var priceInfoLabel: UILabel!
    var payInvoiceButton: UIButton!
    var createInvoiceButton: UIButton!
    var openChannelButton: UIButton!
    let depositCoinsButton = createButton(text: "Deposit")

    let headerColor = NanoColors.deepBlue

    let rpcmanager: RpcManager = RpcManager.shared
    let disposeBag = DisposeBag()

    let loadSubject = BehaviorSubject<Void>(value: ())

    let transactionsSubject = BehaviorSubject<[Transaction]>(value: WalletData.initWallet.txs)

    let uiActions = PublishSubject<WalletUIActions>()

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

        priceInfoLabel = createLabel(text: "")
        priceInfoLabel.textAlignment = .center

        payInvoiceButton = createButton(text: "Pay invoice")
        payInvoiceButton.addTarget(self, action: #selector(payInvoiceClicked), for: .touchUpInside)

        createInvoiceButton = createButton(text: "Create invoice")
        openChannelButton = createButton(text: "Open Channel")

        view.addSubview(headerView)
        view.addSubview(transactionsView)
        view.addSubview(walletbalanceLabel)
        view.addSubview(priceInfoLabel)
        view.addSubview(payInvoiceButton)
        view.addSubview(createInvoiceButton)
        view.addSubview(depositCoinsButton)
        view.addSubview(openChannelButton)

        headerView.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view.snp.top)
            make.height.equalTo(100)
            make.width.equalTo(self.view)
        }

        walletbalanceLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.width.equalTo(self.view).inset(20)
            make.top.equalTo(headerView.snp.bottom).offset(100)
        }

        priceInfoLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.width.equalTo(self.view).inset(20)
            make.top.equalTo(walletbalanceLabel.snp.bottom).offset(8)
        }

        payInvoiceButton.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(priceInfoLabel.snp.bottom).offset(8)
        }

        createInvoiceButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.payInvoiceButton).offset(30)
            make.centerX.equalTo(self.view)
        }

        depositCoinsButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.createInvoiceButton).offset(30)
            make.centerX.equalTo(self.view)
        }

        openChannelButton.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(createInvoiceButton.snp.bottom).offset(40)
        }

        transactionsView.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(openChannelButton.snp.bottom).offset(100)
            make.bottom.equalTo(self.view).inset(80)
            make.width.equalTo(self.view)
        }

        let refreshControl = UIRefreshControl()
        transactionsView.refreshControl = refreshControl

        txDateFormatter.dateFormat = "MM.dd"

        headerView.backgroundColor = headerColor

        loadSubject.asObservable()
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .flatMap { (_) in
                    WalletService.shared.getWallet().retry(3)
                            .retry(3)
                            .map { walletData in
                                WalletUIActions.wallet(walletData: walletData)
                            }
                            .startWith(WalletUIActions.loading)
                            .catchError { error in
                                return Observable.just(WalletUIActions.failure(error))
                            }
                }
                .bind(to: uiActions)
                .disposed(by: disposeBag)

        openChannelButton.rx.tap
                .asObservable()
                .map { _ in
                    WalletUIActions.openChannel
                }
                .bind(to: uiActions)
                .disposed(by: disposeBag)

        uiActions.asObservable()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (action: WalletUIActions) in
                    switch (action) {
                    case .wallet(let data):
                        self?.priceInfoLabel.text = "Bitcoin price: \(data.priceInfo.priceInEUR) Euro"
                        self?.transactionsSubject.onNext(data.txs)
                        self?.walletbalanceLabel.text = "\(data.balance.confirmedBalance)"
                        refreshControl.endRefreshing()
                    case .openDeposit(let vc):
                        self?.present(vc, animated: true, completion: nil)
                    case .openChannel:
                        let vc = OpenChannelViewController()
                        self?.present(vc, animated: true)
                    case .openCreateInvoice:
                        let vc = CreatePaymentViewController()
                        self?.present(vc, animated: true, completion: nil)
                    case .failure(let error):
                        refreshControl.endRefreshing()
                        displayError(message: "Error loading wallet data: \(error)")
                    case .loading:
                        refreshControl.beginRefreshing()
                    case .selectedTx(let tx):
                        let model = TransactionDetailViewModel(tx: tx)
                        let view = TransactionDetailViewController.make(model: model)
                        self?.present(view, animated: true, completion: nil)
                    }
                })
                .disposed(by: self.disposeBag)

        depositCoinsButton.rx.tap.asObservable()
                .map { _ in
                    DepositViewController()
                }
                .map {
                    .openDeposit($0)
                }
                .bind(to: uiActions)
                .disposed(by: disposeBag)

        transactionsView.rx
                .modelSelected(Transaction.self)
                .asObservable()
                .observeOn(AppState.userInitiatedBgScheduler)
                .do(onNext: { tx in print("selected tx=", tx.txHash) })
                .map { tx in
                    WalletUIActions.selectedTx(tx)
                }
                .bind(to: uiActions)
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
                    WalletService.shared.getWallet()
                            .retry(3)
                            .map { walletData in
                                WalletUIActions.wallet(walletData: walletData)
                            }
                            .startWith(WalletUIActions.loading)
                            .catchError { error in
                                return Observable.just(WalletUIActions.failure(error))
                            }
                }
                .bind(to: uiActions)
                .disposed(by: disposeBag)

        createInvoiceButton.rx.tap.asObservable()
                .map { _ in
                    WalletUIActions.openCreateInvoice
                }
                .bind(to: uiActions)
                .disposed(by: disposeBag)
    }

    @objc func payInvoiceClicked(sender: UIButton!) {
        let invoiceVC = PayInvoiceViewController()
        invoiceVC.modalPresentationStyle = .popover
        present(invoiceVC, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
