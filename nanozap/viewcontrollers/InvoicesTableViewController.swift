import Foundation
import UIKit
import RxSwift
import RxCocoa
import Result
import FontAwesome_swift

func toInvoicData(vals: [Payable]) -> [InvoiceCellModel] {
    return vals.map { payable in
        switch (payable) {
        case .invoice(let invoice):
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

            return InvoiceCellModel(
                    leftVal: myString,
                    topLeftVal: "Amount: \(invoice.amount)",
                    botLeftVal: "\(invoice.description)",
                    botRightVal: "\(formatter.string(from: invoice.timestamp))"
            )
        case .payment(let payment):
            let icoSize = CGSize(width: 30, height: 30)
            let settled = UIImage.fontAwesomeIcon(name: .arrowCircleORight, textColor: NanoColors.red, size: icoSize)
            let unsettled = UIImage.fontAwesomeIcon(
                    name: .arrowCircleLeft,
                    textColor: NanoColors.green,
                    size: icoSize
            )

            let attachment = NSTextAttachment()
            attachment.image = payment.amount > 0 ? settled : unsettled
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

            return InvoiceCellModel(
                    leftVal: myString,
                    topLeftVal: "Amount: \(payment.amount)",
                    botLeftVal: "Fee: \(payment.fee)",
                    botRightVal: "\(formatter.string(from: payment.creationDate))"
            )
        }
    }
}

class InvoicesTableViewController: UITableViewController {
    private let disposeBag = DisposeBag()

    let loadInvoices = BehaviorSubject<Void>(value: ())
    let invoicesObs = BehaviorSubject<[Payable]>(value: [])

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = nil
        self.tableView.rowHeight = 60
        self.tableView.register(InvoiceCell.self, forCellReuseIdentifier: "InvoiceCell")
        self.tableView.rowHeight = 50

        invoicesObs.asObservable()
                .observeOn(MainScheduler.instance)
                .map { toInvoicData(vals: $0) }
                .bind(to: self.tableView.rx.items(
                        cellIdentifier: "InvoiceCell",
                        cellType: InvoiceCell.self
                )) { (row, aModel: InvoiceCellModel, cell: InvoiceCell) in
                    cell.update(model: aModel)
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
                .flatMap { [weak self] (_) in
                    self?.getInvoices() ?? Observable.empty()
                }
                .bind(to: invoicesObs)
                .disposed(by: disposeBag)

        enum LoadInvoicesResult {
            case loading()
            case done(res : [Payable])
            case failure(error : Error)
        }

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
                .flatMap { _ in
                    self.getInvoices()
                        .map { invs in LoadInvoicesResult.done(res: invs) }
                        .catchError { err in Observable.just(LoadInvoicesResult.failure(error: err)) }
                        .startWith(LoadInvoicesResult.loading())
                }
                // go back to main thread to touch UI
                .observeOn(MainScheduler.instance)
                .subscribe(
                        onNext: { [weak self] result in
                            print("some refresh result")
                            switch (result) {
                            case .loading:
                                // do nothing
                                print("loading")
                            case .done(let invoices):
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

    private func getInvoices() -> Observable<[Payable]> {
        return InvoiceService.shared.listPayables()
                .map { (values : [Payable]) in
                    return values.sorted(by: { (lhs, rhs) in
                        return lhs < rhs
                    })
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
