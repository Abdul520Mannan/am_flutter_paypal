package com.am.am_flutter_paypal

import android.app.Activity
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.paypal.android.cardpayments.CardClient
import com.paypal.android.cardpayments.CardRequest
import com.paypal.android.cardpayments.model.Card
import com.paypal.android.core.CoreConfig
import com.paypal.android.core.Environment
import com.paypal.android.cardpayments.CardApproveOrderListener
import com.paypal.android.cardpayments.CardResult
import com.paypal.android.core.PayPalSDKError

/** AmFlutterPaypalPlugin */
class AmFlutterPaypalPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var cardClient: CardClient? = null
    private var mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "am_flutter_paypal")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val clientId = call.argument<String>("clientId")
                val environmentStr = call.argument<String>("environment")
                
                if (clientId == null || environmentStr == null) {
                    result.error("INVALID_ARGUMENTS", "ClientId or Environment is null", null)
                    return
                }

                val environment = if (environmentStr.equals("live", ignoreCase = true)) {
                    Environment.LIVE
                } else {
                    Environment.SANDBOX
                }

                val config = CoreConfig(clientId, environment = environment)
                activity?.let {
                    cardClient = CardClient(it, config)
                    result.success(true)
                } ?: run {
                    result.error("ACTIVITY_NULL", "Activity is not attached", null)
                }
            }
            "approveOrder" -> {
                val orderId = call.argument<String>("orderId")
                val cardMap = call.argument<Map<String, Any>>("card")

                if (orderId == null || cardMap == null) {
                    result.error("INVALID_ARGUMENTS", "OrderId or Card details missing", null)
                    return
                }

                val client = cardClient
                if (client == null) {
                    result.error("SDK_NOT_INITIALIZED", "Plugin not initialized", null)
                    return
                }

                val card = Card(
                    number = cardMap["cardNumber"] as String,
                    expirationMonth = cardMap["expirationMonth"] as String,
                    expirationYear = cardMap["expirationYear"] as String,
                    securityCode = cardMap["securityCode"] as String,
                    cardholderName = cardMap["cardholderName"] as? String ?: ""
                )

                val cardRequest = CardRequest(orderId, card)
                
                client.approveOrderListener = object : CardApproveOrderListener {
                    override fun onApproveOrderSuccess(cardResult: CardResult) {
                        val response = mutableMapOf<String, Any>()
                        response["success"] = true
                        response["orderId"] = cardResult.orderID
                        response["status"] = cardResult.status ?: "APPROVED"
                        // Payer ID might not be directly in CardResult but we return what we can
                        
                        sendResultOnMainThread(result, response)
                    }

                    override fun onApproveOrderFailure(error: PayPalSDKError) {
                        val response = mutableMapOf<String, Any>()
                        response["success"] = false
                        response["errorCode"] = error.code.toString()
                        response["message"] = error.errorDescription ?: "Unknown error"
                        
                        sendResultOnMainThread(result, response)
                    }

                    override fun onApproveOrderCanceled() {
                        val response = mutableMapOf<String, Any>()
                        response["success"] = false
                        response["errorCode"] = "USER_CANCELLED"
                        response["message"] = "The user cancelled the payment flow."
                        
                        sendResultOnMainThread(result, response)
                    }
                }

                client.approveOrder(activity!!, cardRequest)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun sendResultOnMainThread(result: Result, data: Map<String, Any>) {
        mainHandler.post {
            result.success(data)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        cardClient = null
    }

    // ActivityAware Implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
        cardClient = null
    }
}
