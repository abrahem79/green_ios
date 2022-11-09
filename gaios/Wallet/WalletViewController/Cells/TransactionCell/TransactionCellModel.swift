import Foundation
import UIKit

class TransactionCellModel {
    var tx: Transaction
    var blockHeight: UInt32
    var status: String?
    var date: String
    var icon = UIImage()
    var subaccount: WalletItem?
    var amounts = [(key: String, value: Int64)]()

    private let wm = WalletManager.current

    init(tx: Transaction, blockHeight: UInt32) {
        self.tx = tx
        self.blockHeight = blockHeight
        self.date = tx.date(dateStyle: .medium, timeStyle: .none)
        self.subaccount = wm?.subaccounts.filter { $0.hashValue == tx.subaccount }.first
        if let subaccount = self.subaccount {
            self.amounts = amounts(self.tx, subaccount)
        }
        let pending = TransactionCellModel.isPending(tx: tx, blockHeight: blockHeight)

        switch tx.type {
        case .redeposit:
            // For redeposits we show fees paid in btc
            self.status = pending ? "Redepositing" : "Redeposited"
            icon = UIImage(named: "ic_tx_received")!
        case .incoming:
            self.status = pending ? "Receiving" : "Received"
            icon = UIImage(named: "ic_tx_received")!
        case .outgoing:
            self.status = pending ? "Sending" : "Sent"
            icon = UIImage(named: "ic_tx_sent")!
        case .mixed:
            self.status = pending ? "Swaping" : "Swap"
        }
    }

    static func isPending(tx: Transaction, blockHeight: UInt32) -> Bool {
        if tx.blockHeight == 0 {
            return true
        } else if tx.isLiquid && blockHeight < tx.blockHeight + 1 {
            return true
        } else if !tx.isLiquid && blockHeight < tx.blockHeight + 5 {
            return true
        } else {
            return false
        }
    }

    func amounts(_ tx: Transaction, _ subaccount: WalletItem) -> [(key: String, value: Int64)] {
        var amounts = [(key: String, value: Int64)]()
        let feeAsset = subaccount.gdkNetwork.getFeeAsset()
        if tx.type == .redeposit {
            amounts = [(key: feeAsset, value: -1 * Int64(tx.fee))]
        } else {
            amounts = tx.assetamounts
            // remove L-BTC asset only if fee on outgoing transactions
            if tx.type == .some(.outgoing) || tx.type == .some(.mixed) {
                amounts = amounts.filter({ !($0.key == feeAsset && abs($0.value) == Int64(tx.fee)) })
            }
        }
        return amounts
    }
}
