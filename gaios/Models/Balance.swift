import Foundation

struct Balance: Codable {

    enum CodingKeys: String, CodingKey {
        case bits
        case btc
        case fiat
        case fiatCurrency = "fiat_currency"
        case fiatRate = "fiat_rate"
        case mbtc
        case satoshi
        case ubtc
        case sats
        case assetInfo = "asset_info"
        case asset
        case assetId = "asset_id"
    }

    let bits: String
    let btc: String
    let fiat: String?
    let fiatCurrency: String
    let fiatRate: String?
    let mbtc: String
    let satoshi: Int64
    let ubtc: String
    let sats: String
    let assetInfo: AssetInfo?
    var asset: [String: String]?
    var assetId: String?

    static var session: SessionManager? { WalletManager.current?.prominentSession }
    static var lbtc: String { AssetInfo.lbtcId }
    static var ltest: String { AssetInfo.ltestId }

    static func isBtc(_ assetId: String?) -> Bool {
        return [AssetInfo.btcId, AssetInfo.lbtcId, AssetInfo.testId, AssetInfo.ltestId].contains(assetId ?? "")
    }
    static func getAsset(_ assetId: String) -> AssetInfo? {
        return WalletManager.current?.registry.info(for: assetId)
    }

    static func from(details: [String: Any]) -> Balance? {
        if var res = try? session?.convertAmount(input: details) {
            res["asset_info"] = details["asset_info"]
            res["asset_id"] = details["asset_id"]
            if let data = try? JSONSerialization.data(withJSONObject: res, options: []),
               var balance = try? JSONDecoder().decode(Balance.self, from: data) {
                if let assetInfo = balance.assetInfo,
                   let value = res[assetInfo.assetId] as? String {
                    balance.asset = [assetInfo.assetId: value]
                }
                return balance
            }
        }
        return nil
    }

    static func fromFiat(_ fiat: String) -> Balance? {
        let details: [String: Any] = ["fiat": fiat]
        return Balance.from(details: details)
    }

    static func fromDenomination(_ value: String, assetId: String) -> Balance? {
        let denomination = session?.settings?.denomination.rawValue
        let details: [String: Any] = [denomination ?? Balance.session?.gdkNetwork.getFeeAsset() ?? "btc": value,
                                      "asset_id": assetId]
        return Balance.from(details: details)
    }

    static func fromValue(_ value: String, assetId: String) -> Balance? {
        var details: [String: Any] = [assetId: value,
                                      "asset_id": assetId]
        if let asset = getAsset(assetId), !isBtc(assetId) {
            details["asset_info"] = asset.encode()
        }
        return Balance.from(details: details)
    }

    static func fromSatoshi(_ satoshi: Any, assetId: String) -> Balance? {
        var details: [String: Any] = ["satoshi": satoshi,
                                      "asset_id": assetId]
        if let asset = getAsset(assetId), !isBtc(assetId) {
            details["asset_info"] = asset.encode()
        }
        return Balance.from(details: details)
    }

    static func fromSatoshi(_ satoshi: UInt64, assetId: String) -> Balance? {
        return Balance.fromSatoshi(Int64(satoshi), assetId: assetId)
    }

    func toFiat() -> (String, String) {
        let mainnet = AccountsManager.shared.current?.gdkNetwork?.mainnet
        if let asset = assetInfo, !["btc", Balance.lbtc, Balance.ltest].contains(asset.assetId) {
            return ("", "")
        } else {
            return (fiat?.localeFormattedString(2) ?? "n/a", mainnet ?? true ? fiatCurrency : "FIAT")
        }
    }

    func toDenom() -> (String, String) {
        let denomination = Balance.session?.settings?.denomination ?? .BTC
        let res = try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self), options: .allowFragments) as? [String: Any]
        let value = res![denomination.rawValue] as? String
        let network: NetworkSecurityCase = {
            switch assetId {
            case Balance.lbtc: return .liquidSS
            case Balance.ltest: return .testnetLiquidSS
            default: return Balance.session?.gdkNetwork.mainnet ?? true ? .bitcoinSS : .testnetSS
            }
        }()
        return (value?.localeFormattedString(Int(denomination.digits)) ?? "n/a", denomination.string(for: network.gdkNetwork!))
    }

    func toBTC() -> (String, String) {
        let denomination: DenominationType = .BTC
        let res = try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self), options: .allowFragments) as? [String: Any]
        let value = res![denomination.rawValue] as? String
        return (value?.localeFormattedString(Int(denomination.digits)) ?? "n/a", denomination.string(for: Balance.session?.gdkNetwork ?? getGdkNetwork("electrum-mainnet")))
    }

    func toAssetValue() -> (String, String) {
        return (asset?.first?.value.localeFormattedString(Int(assetInfo?.precision ?? 8)) ?? "n/a", assetInfo?.ticker ?? "n/a")
    }

    func toValue() -> (String, String) {
        if !Balance.isBtc(assetId) {
            return toAssetValue()
        } else {
            return toDenom()
        }
    }
}
