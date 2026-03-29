import Flutter
import UIKit
import PayPalCardPayments
import PayPalCorePayments

public class AmFlutterPaypalPlugin: NSObject, FlutterPlugin {
    private var cardClient: CardClient?
    private var channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "am_flutter_paypal", binaryMessenger: registrar.messenger())
        let instance = AmFlutterPaypalPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            guard let args = call.arguments as? [String: Any],
                  let clientId = args["clientId"] as? String,
                  let environmentStr = args["environment"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "ClientId or Environment is missing", details: nil))
                return
            }

            let environment: Environment = (environmentStr.lowercased() == "live") ? .live : .sandbox
            let config = CoreConfig(clientID: clientId, environment: environment)
            self.cardClient = CardClient(config: config)
            // Note: returnUrl is mainly used on Android SDK 2.x, 
            // on iOS it's traditionally handled via the App's URL Scheme.
            result(true)

        case "approveOrder":
            guard let args = call.arguments as? [String: Any],
                  let orderId = args["orderId"] as? String,
                  let cardMap = args["card"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "OrderId or Card details missing", details: nil))
                return
            }

            guard let client = self.cardClient else {
                result(FlutterError(code: "SDK_NOT_INITIALIZED", message: "Plugin not initialized", details: nil))
                return
            }

            let card = Card(
                number: cardMap["cardNumber"] as? String ?? "",
                expirationMonth: cardMap["expirationMonth"] as? String ?? "",
                expirationYear: cardMap["expirationYear"] as? String ?? "",
                securityCode: cardMap["securityCode"] as? String ?? ""
            )
            card.cardholderName = cardMap["cardholderName"] as? String

            let cardRequest = CardRequest(orderID: orderId, card: card)
            
            client.delegate = self
            
            // Start the approval flow
            client.approveOrder(request: cardRequest)
            
            // Note: We don't return here yet, the delegate handles it.
            // But we need to keep track of the result callback if needed.
            // In this simple implementation, we assume only one call at a time which we guard in Dart.
            self.pendingResult = result

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private var pendingResult: FlutterResult?

    private func sendResponse(_ response: [String: Any]) {
        DispatchQueue.main.async {
            self.pendingResult?(response)
            self.pendingResult = nil
        }
    }
}

extension AmFlutterPaypalPlugin: CardDelegate {
    public func card(_ cardClient: CardClient, didFinishWithResult result: CardResult) {
        var response: [String: Any] = [:]
        response["success"] = true
        response["orderId"] = result.orderID
        response["status"] = result.status
        // Additional metadata could be added here
        sendResponse(response)
    }

    public func card(_ cardClient: CardClient, didFinishWithError error: CoreSDKError) {
        var response: [String: Any] = [:]
        response["success"] = false
        response["errorCode"] = String(error.code)
        response["message"] = error.errorDescription
        sendResponse(response)
    }

    public func cardDidCancel(_ cardClient: CardClient) {
        var response: [String: Any] = [:]
        response["success"] = false
        response["errorCode"] = "USER_CANCELLED"
        response["message"] = "The user cancelled the payment flow."
        sendResponse(response)
    }

    public func cardThreeDSecureWillAppear(_ cardClient: CardClient) {
        // Optional: Notify Flutter that 3DS UI is appearing
    }

    public func cardThreeDSecureDidFinish(_ cardClient: CardClient) {
        // Optional: Notify Flutter that 3DS UI finished
    }
}
