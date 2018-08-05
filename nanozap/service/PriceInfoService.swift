import Foundation
import SwiftyJSON
import RxSwift

struct PriceInfo {
    let timestamp: Date
    let priceInEUR: Double
    let priceInUSD: Double
}

struct PriceInfoResult {
    let priceInfo: PriceInfo
}

class PriceInfoService {
    let urlString = URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json")!

    func getPriceInfo() -> Observable<PriceInfoResult> {
        return Observable.create { obs in
            let task = URLSession.shared.dataTask(with: self.urlString) { (data, response, error) in
                if error != nil {
                    print(error!)
                    obs.onError(error!)
                } else {
                    if let usableData = data {
                        do {
                            print("data: \(usableData)") //JSONSerialization
                            let json = try JSON(data: usableData)

                            guard
                                    let timestamp = json["time"]["updatedISO"].string,
                                    let eur = json["bpi"]["EUR"]["rate_float"].double,
                                    let usd = json["bpi"]["USD"]["rate_float"].double else {
                                obs.onError(RPCError.failedToParseResponse)
                                return
                            }

                            let data = PriceInfoResult(priceInfo: PriceInfo(
                                    timestamp: timestamp.dateFromISO8601 ?? Date(),
                                    priceInEUR: eur,
                                    priceInUSD: usd))

                            obs.onNext(data)
                            obs.onCompleted()
                        } catch let error {
                            obs.onError(error)
                        }
                    }
                }
            }
            task.resume()
            return Disposables.create()
        }

    }
}
