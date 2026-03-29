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
import com.paypal.android.cardpayments.Card
import com.paypal.android.corepayments.CoreConfig
import com.paypal.android.corepayments.Environment
import com.paypal.android.cardpayments.CardApproveOrderResult
import com.paypal.android.corepayments.PayPalSDKError

/** AmFlutterPaypalPlugin */
class AmFlutterPaypalPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var cardClient: CardClient? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var returnUrl: String? = null
    private var coreConfig: CoreConfig? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "am_flutter_paypal")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val clientId = call.argument<String>("clientId")
                val environmentStr = call.argument<String>("environment")
                returnUrl = call.argument<String>("returnUrl")
                
                if (clientId == null || environmentStr == null) {
                    result.error("INVALID_ARGUMENTS", "ClientId or Environment is null", null)
                    return
                }

                val environment = if (environmentStr.equals("live", ignoreCase = true)) {
                    Environment.LIVE
                } else {
                    Environment.SANDBOX
                }

                coreConfig = CoreConfig(clientId, environment = environment)
                
                activity?.let {
                    cardClient = CardClient(it, coreConfig!!)
                    result.success(true)
                } ?: run {
                    // We can still initialize coreConfig and wait for activity
                    result.success(true)
                }
            }

            "approveOrder" -> {
                val orderId = call.argument<String>("orderId")
                val cardMap = call.argument<Map<String, Any>>("card")

                if (orderId == null || cardMap == null) {
                    result.error("INVALID_ARGUMENTS", "OrderId or Card details missing", null)
                    return
                }

                val currentActivity = activity
                if (currentActivity == null) {
                    result.error("ACTIVITY_NULL", "Activity is not attached", null)
                    return
                }

                val config = coreConfig
                if (config == null) {
                    result.error("SDK_NOT_INITIALIZED", "Plugin not initialized (Config null)", null)
                    return
                }

                // Initialize client if not already done
                if (cardClient == null) {
                    cardClient = CardClient(currentActivity, config)
                }

                val returnUrlSafe = returnUrl
                if (returnUrlSafe == null) {
                    result.error("MISSING_RETURN_URL", "Return URL must be provided during initialization", null)
                    return
                }

                val card = Card(
                    number = cardMap["cardNumber"] as String,
                    expirationMonth = cardMap["expirationMonth"] as String,
                    expirationYear = cardMap["expirationYear"] as String,
                    securityCode = cardMap["securityCode"] as String
                )
                card.cardholderName = cardMap["cardholderName"] as? String ?: ""

                val cardRequest = CardRequest(orderId, card, returnUrlSafe)
                
                cardClient?.approveOrder(cardRequest) { approveOrderResult ->
                    when (approveOrderResult) {
                        is CardApproveOrderResult.Success -> {
                            val response = mapOf(
                                "success" to true,
                                "orderId" to approveOrderResult.orderId,
                                "status" to "APPROVED"
                            )
                            send(result, response)
                        }
                        is CardApproveOrderResult.Failure -> {
                            val error = approveOrderResult.error
                            val response = mapOf(
                                "success" to false,
                                "errorCode" to error.code.toString(),
                                "message" to (error.errorDescription ?: "Unknown error")
                            )
                            send(result, response)
                        }
                        is CardApproveOrderResult.AuthorizationRequired -> {
                            // This state is for 3DS or other required actions
                            val response = mapOf(
                                "success" to false,
                                "errorCode" to "AUTHORIZATION_REQUIRED",
                                "message" to "Additional authorization or 3DS is required."
                            )
                            send(result, response)
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun send(result: Result, data: Map<String, Any>) {
        mainHandler.post {
            result.success(data)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        // Re-initialize client if config already exists
        coreConfig?.let {
            cardClient = CardClient(binding.activity, it)
        }
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