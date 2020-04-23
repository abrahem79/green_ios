import Foundation
import UIKit
import PromiseKit
import RxSwift

protocol HWResolverProtocol {

    var connected: Bool { get }
    func xpubs(paths: [[Int]]) -> Observable<[String]>
    func signMessage(path: [Int], message: String) -> Observable<String>
    func signTransaction(tx: [String: Any], inputs: [[String: Any]], outputs: [[String: Any]],
                         transactions: [String: String], addressTypes: [String]) -> Observable<[String]>

    // Liquid calls
    func getBlindingKey(scriptHex: String) -> Observable<String?>
    func getSharedNonce(pubkey: String, scriptHex: String) -> Observable<String?>
    func signLiquidTransaction(inputs: [[String: Any]], outputs: [[String: Any]], transactions: [String: String], addressTypes: [String]) -> Observable<LiquidHWResult>

}
