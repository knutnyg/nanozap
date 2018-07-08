import Foundation
import UIKit
import RxSwift
import RxCocoa
import Result
import FontAwesome_swift

class InvoicesTableViewController: UITableViewController {
    private let disposeBag = DisposeBag()

    let loadInvoices = BehaviorSubject<Void>(value: ())
    let invoicesObs = BehaviorSubject<[Invoice]>(value: [])

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = nil
        self.tableView.register(InvoiceCell.self, forCellReuseIdentifier: "InvoiceCell")
        self.tableView.rowHeight = 50

        invoicesObs.asObservable()
                .observeOn(MainScheduler.instance)
                .bind(to: self.tableView.rx.items(
                        cellIdentifier: "InvoiceCell",
                        cellType: InvoiceCell.self
                )) { (row, invoice: Invoice, cell: InvoiceCell) in
                    let iconSize = CGSize(width: 30, height: 30)
                    let settled = UIImage.fontAwesomeIcon(name: .money, textColor: NanoColors.green, size: iconSize)
                    let unsettled = UIImage.fontAwesomeIcon(name: .money, textColor: NanoColors.gray, size: iconSize)

                    let attachment = NSTextAttachment()
                    attachment.image = invoice.settled ? settled : unsettled
                    let imageOffsetY: CGFloat = 0.0
                    attachment.bounds = CGRect(
                            x: 0,
                            y: imageOffsetY,
                            width: attachment.image!.size.width,
                            height: attachment.image!.size.height
                    )

                    let attachmentString = NSAttributedString(attachment: attachment)

                    let myString = NSMutableAttributedString(string: "")
                    myString.append(attachmentString)

                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium

                    cell.leftLabel?.attributedText = myString
                    cell.topLeftLabel?.text = "\(formatter.string(from: invoice.timestamp))"
                    cell.botRightLabel?.text = "Amount: \(invoice.amount)"
                    cell.botLeftLabel?.text = "\(invoice.description)"
                }
                .disposed(by: disposeBag)
        
        self.tableView.rx.modelSelected(Invoice.self)
                .map { (invoice: Invoice) in
                    let model = PaymentCreatedModel(
                            amount: invoice.amount,
                            description: invoice.description,
                            paymentHash: invoice.payreq,
                            rHash: invoice.rHash
                    )
                    return model
                }
                .map { model in
                    PaymentCreatedVC.make(model: model)
                }
                .map { vc in
                    Result<PaymentCreatedVC, AnyError>(value: vc)
                }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (result) in
                    //self.navigationController.pushViewController(nextViewController, animated: true)
                    switch (result) {
                    case .success(let view):
                        self.present(view, animated: true, completion: nil)
                    case .failure(let err):
                        print("load channel error", err)
                        displayError(message: "Error loading channel data.")
                    }

                }, onError: { err in
                    print("fatal error", err)
                    fatalError("observable died")
                })
                .disposed(by: disposeBag)

        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl

        loadInvoices
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .map { (_) in
                    self.getInvoices()
                }
                .flatMap { result -> Observable<[Invoice]> in
                    switch (result) {
                    case .success(let invoices):
                        return Observable.just(invoices)
                    case .failure(let error):
                        print("caught error", error)
                        return Observable.empty()
                    }
                }
                .bind(to: invoicesObs)
                .disposed(by: disposeBag)

        refreshControl.rx
                .controlEvent(.valueChanged)
                .map { [weak refreshControl] _ in
                    refreshControl?.isRefreshing ?? false
                }
                // do network activity in background thread
                .observeOn(AppState.userInitiatedBgScheduler)
                .filter { val in
                    val == true
                }
                .map { [unowned self] _ in
                    self.getInvoices()
                }
                // go back to main thread to touch UI
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onNext: { [weak self] result in
                            print("some refresh result")
                            switch (result) {
                            case .success(let invoices):
                                self?.invoicesObs.onNext(invoices)
                                refreshControl.endRefreshing()
                            case .failure(let error):
                                print("got error on refresh: ", error)
                                refreshControl.endRefreshing()
                                displayError(message: "Error refreshing invoices.")
                            }
                        },
                        onError: { (error) in
                            print("refreshcontrol died: ", error)
                            fatalError("refreshcontrol died!")
                        },
                        onCompleted: {
                            refreshControl.endRefreshing()
                        })
                .disposed(by: disposeBag)
    }

    private func getInvoices() -> Result<[Invoice], AnyError> {
        return Result(attempt: { () throws -> [Invoice] in try InvoiceService.shared.listInvoices() })
                .map { invoices in
                    invoices.sorted(by: { $0.timestamp > $1.timestamp })
                }
    }

    private func refreshInvoices() {
        loadInvoices.onNext(())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshInvoices()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        do {
            return try self.invoicesObs.value().count
        } catch {
            return 0
        }
    }
}
