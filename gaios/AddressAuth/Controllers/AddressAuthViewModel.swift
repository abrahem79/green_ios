import Foundation
import UIKit

import gdk

class AddressAuthViewModel {

    var listCellModelsFilter: [AddressAuthCellModel] = []
    private var listCellModels: [AddressAuthCellModel] = []
    
    var wallet: WalletItem
    
    init(wallet: WalletItem) {
        self.wallet = wallet
    }

    func load() async throws {
        let params = GetPreviousAddressesParams(subaccount: Int(wallet.pointer), lastPointer: nil)
        let res = try await wallet.session?.getPreviousAddresses(params)
        listCellModels = res?.list.compactMap { AddressAuthCellModel(address: $0.address ?? "", tx: $0.txCount  ?? 0) } ?? []
        listCellModelsFilter = listCellModels
    }

    func search(_ txt: String?) {
        listCellModelsFilter = []
        listCellModels.forEach {
            if let txt = txt, txt.count > 0 {
                if ($0.address).lowercased().contains(txt.lowercased()) {
                    listCellModelsFilter.append($0)
                }
            } else {
                listCellModelsFilter.append($0)
            }
        }
    }
}
