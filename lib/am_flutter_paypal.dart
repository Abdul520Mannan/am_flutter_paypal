import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'models.dart';

export 'models.dart';

/// A Flutter plugin for PayPal Advanced Checkout integration (Approval Only).
class AmFlutterPaypal {
  static const MethodChannel _channel = MethodChannel('am_flutter_paypal');

  static bool _isInitialized = false;
  static bool _isProcessing = false;
  static String? _returnUrl;

  /// Initializes the PayPal SDK with your [clientId] and [environment].
  ///
  /// This must be called before [approveOrder].
  /// If already initialized, it returns true immediately without re-initializing.
  static Future<bool> initialize({
    required String clientId,
    required PayPalEnvironment environment,
    String? returnUrl,
  }) async {
    if (_isInitialized && _returnUrl == returnUrl) return true;

    try {
      final bool? success = await _channel.invokeMethod<bool>('initialize', {
        'clientId': clientId,
        'environment': environment.name,
        'returnUrl': returnUrl,
      });
      if (success == true) {
        _isInitialized = true;
        _returnUrl = returnUrl;
      }
      return _isInitialized;
    } on PlatformException catch (e) {
      debugPrint('PayPal SDK Initialization Error: ${e.message}');
      return false;
    }
  }

  /// Approves a PayPal payment using an existing [orderId] and [card] details.
  ///
  /// Throws [PayPalPaymentResult.notInitialized] if the SDK is not setup.
  /// Throws [PayPalPaymentResult.alreadyInProgress] if another payment is active.
  /// Implements a 60-second timeout returning [PayPalPaymentResult.timeout].
  static Future<PayPalPaymentResult> approveOrder({
    required String orderId,
    required PayPalCard card,
  }) async {
    if (!_isInitialized) {
      return PayPalPaymentResult.notInitialized();
    }

    if (_isProcessing) {
      return PayPalPaymentResult.alreadyInProgress();
    }

    _isProcessing = true;

    try {
      // Create a completer to handle the 60s timeout
      final completer = Completer<PayPalPaymentResult>();
      
      Timer(const Duration(seconds: 60), () {
        if (!completer.isCompleted) {
          _isProcessing = false;
          completer.complete(PayPalPaymentResult.timeout());
        }
      });

      _channel.invokeMethod('approveOrder', {
        'orderId': orderId,
        'card': card.toJson(),
      }).then((result) {
        if (!completer.isCompleted) {
          _isProcessing = false;
          if (result != null && result is Map) {
            completer.complete(PayPalPaymentResult.fromMap(result));
          } else {
            completer.complete(const PayPalPaymentResult(
              success: false,
              errorCode: 'UNKNOWN_ERROR',
              message: 'Native SDK returned an unexpected response format.',
            ));
          }
        }
      }).catchError((error) {
        if (!completer.isCompleted) {
          _isProcessing = false;
          if (error is PlatformException) {
            completer.complete(PayPalPaymentResult(
              success: false,
              errorCode: error.code,
              message: error.message,
            ));
          } else {
            completer.complete(PayPalPaymentResult(
              success: false,
              errorCode: 'PLATFORM_ERROR',
              message: error.toString(),
            ));
          }
        }
      });

      return await completer.future;
    } catch (e) {
      _isProcessing = false;
      return PayPalPaymentResult(
        success: false,
        errorCode: 'FATAL_ERROR',
        message: e.toString(),
      );
    }
  }
}
