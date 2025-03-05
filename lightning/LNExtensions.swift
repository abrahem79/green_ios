import Foundation
import BreezSDK
import UIKit

extension UInt64 {
    public var satoshi: UInt64 { self / 1000 }
    public var milliSatoshi: UInt64 { self * 1000 }
}
extension Int64 {
    public var satoshi: Int64 { self / 1000 }
    public var milliSatoshi: Int64 { self * 1000 }
}

extension LnInvoice {
    public var amountSatoshi: UInt64? { amountMsat?.satoshi }
    public var isAmountLocked: Bool { amountMsat != nil }
    public var expireIn: TimeInterval { TimeInterval(timestamp + expiry) }
    public var expireInAsDate: Date { Date(timeIntervalSince1970: expireIn) }
    public var timeUntilExpiration: Double { Date().distance(to: expireInAsDate) }
    public var expiringInMinutes: Int? { Calendar.current.dateComponents([.minute], from: expireInAsDate, to: Date()).minute }
    public var isExpired: Bool { timeUntilExpiration < 0 }
    public func sendableSatoshi(userSatoshi: UInt64?) -> UInt64? {
        isAmountLocked ? amountSatoshi ?? 0 : userSatoshi
    }
    public func receiveAmountSatoshi(openingFeeParams: OpeningFeeParams?) -> UInt64 {
        (amountMsat?.satoshi ?? 0) - (openingFeeParams?.minMsat.satoshi ?? 0)
    }
}

extension OpenChannelFeeResponse {
    public var feeSatoshi: UInt64? { feeMsat?.satoshi }
}

extension LnUrlWithdrawRequestData {
    public var maxWithdrawableSatoshi: UInt64 { maxWithdrawable.satoshi }
    public var minWithdrawableSatoshi: UInt64 { minWithdrawable.satoshi }
}

extension LnUrlWithdrawRequestData {
    public var domain: String? { URL(string: callback)?.host }
}

extension LnUrlPayRequestData {
    public func sendableSatoshi(userSatoshi: UInt64?) -> UInt64? {
        isAmountLocked ? maxSendable : userSatoshi
    }
    public var isAmountLocked: Bool { minSendable == maxSendable }
    public var maxSendableSatoshi: UInt64 { maxSendable.satoshi }
    public var minSendableSatoshi: UInt64 { minSendable.satoshi }
    public var metadata: [[String]]? {
        let data = metadataStr.data(using: .utf8)
        return try? JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments) as? [[String]]
    }
}

extension NodeState {
    public var channelsBalanceSatoshi: UInt64 { channelsBalanceMsat.satoshi }
    public var onchainBalanceSatoshi: UInt64 { onchainBalanceMsat.satoshi }
    public var maxReceivableSatoshi: UInt64 { maxReceivableMsat.satoshi }
    public var inboundLiquiditySatoshi: UInt64 { totalInboundLiquidityMsats.satoshi }
    public var maxPaybleSatoshi: UInt64 { maxPayableMsat.satoshi }
    public var maxSinglePaymentAmountSatoshi: UInt64 { maxSinglePaymentAmountMsat.satoshi }
}

extension Payment {
    public var amountSatoshi: Int64 { Int64(amountMsat.satoshi) * ((paymentType == PaymentType.received) ? 1 : -1) }
}

extension Array<Array<String>>? {
    public var lnUrlPayDescription: String? {
        self?.first { "text/plain" == $0.first }?
            .last
    }
    public var lnUrlPayImage: UIImage? {
        guard let base64 = self?.first(where: { "image/png;base64" == $0.first })?.last else { return nil }
        return [base64]
            .compactMap { Data($0.utf8).base64EncodedData() }
            .compactMap { UIImage(data: $0) }
            .first
    }
}

extension String {
    public var errorMessage: String? {
        if #available(iOSApplicationExtension 16.0, *) {
            let txt = String(self.replacingOccurrences(of: "\\", with: "").utf8)
            if let startIndex = txt.ranges(of: "message: \"").last?.upperBound,
               let endIndex = txt.suffix(from: startIndex).firstIndex(of: "\"") {
                return String(txt[startIndex..<endIndex])
            }
        }
        return nil
    }
}

extension BreezEvent {
    
    public var description: String {
        switch self {
        case .newBlock(let block):
            return "newBlock \(block)"
        case .invoicePaid(details: let details):
            return "invoicePaid \(details.bolt11)"
        case .synced:
            return "synced"
        case .paymentSucceed(details: let details):
            return "paymentSucceed \(details)"
        case .paymentFailed(details: let details):
            return "paymentFailed \(details)"
        case .backupStarted:
            return "backupStarted"
        case .backupSucceeded:
            return "backupSucceeded"
        case .backupFailed(details: let details):
            return "backupFailed \(details)"
        case .reverseSwapUpdated(details: let details):
            return "reverseSwapUpdated \(details)"
        case .swapUpdated(details: let details):
            return "swapUpdated \(details)"
        }
    }
}
extension ReverseSwapStatus {
    public func description() -> String {
        switch self {
        case ReverseSwapStatus.`initial`: return "initial"
        case ReverseSwapStatus.`inProgress`: return "inProgress"
        case ReverseSwapStatus.`cancelled`: return "cancelled"
        case ReverseSwapStatus.`completedSeen`: return "completedSeen"
        case ReverseSwapStatus.`completedConfirmed`: return "completedConfirmed"
        }
    }
}
extension SwapStatus {
    public func description() -> String {
        switch self {
        case SwapStatus.`initial`: return "initial"
        case SwapStatus.`waitingConfirmation`: return "waitingConfirmation"
        case SwapStatus.`redeemable`: return "redeemable"
        case SwapStatus.`redeemed`: return "redeemed"
        case SwapStatus.`refundable`: return "refundable"
        case SwapStatus.`completed`: return "completed"
        }
    }
}
