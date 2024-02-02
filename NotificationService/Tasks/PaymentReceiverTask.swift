//
//  ReceivePayment.swift
//  Breez Notification Service Extension
//
//  Created by Roei Erez on 03/01/2024.
//
import UserNotifications
import Combine
import os.log
import notify
import Foundation
import BreezSDK

class PaymentReceiverTask : SDKBackgroundTask {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private var logger: Logger
    private var receivedPayment: Payment? = nil
    
    init(logger: Logger, contentHandler: ((UNNotificationContent) -> Void)? = nil, bestAttemptContent: UNMutableNotificationContent? = nil) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = bestAttemptContent
        self.logger = logger
    }
    
    func start(breezSDK: BlockingBreezServices){}
    
    func onShutdown() {
        if let payment = receivedPayment {
            self.displayPushNotification(text: "Payment received")
        } else {
            self.displayPushNotification(text: "Receive payment failed")
        }
    }
    
    func onEvent(e: BreezEvent) {
        switch e {
        case .invoicePaid(details: let details):
            self.logger.info("Received payment. Bolt11: \(details.bolt11)\nPayment Hash:\(details.paymentHash)")
            receivedPayment = details.payment
            break
        case .synced:
            self.logger.info("got synced event")
            if self.receivedPayment != nil {
                self.onShutdown()
            }
            break
        default:
            break
        }
    }
    
    public func displayFailedPushNotification() {
        displayPushNotification(text: "Open wallet to receive a payment")
    }

    public func displayPushNotification(text: String) {
        self.logger.info("displayPushNotification \(text)")
        guard
            let contentHandler = contentHandler,
            let bestAttemptContent = bestAttemptContent
        else {
            return
        }
        bestAttemptContent.title = "Green Lightning"
        bestAttemptContent.body = text.localized
        contentHandler(bestAttemptContent)
    }
}
