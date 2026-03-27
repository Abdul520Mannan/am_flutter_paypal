/// Supported PayPal environments.
enum PayPalEnvironment {
  /// Sandbox environment for testing.
  sandbox,

  /// Live environment for production payments.
  live,
}

/// Represents the credit card details required for payment approval.
class PayPalCard {
  /// The cardholder's name as it appears on the card.
  final String cardholderName;

  /// The 13-19 digit card number.
  final String cardNumber;

  /// The expiration month in MM format.
  final String expirationMonth;

  /// The expiration year in YYYY format.
  final String expirationYear;

  /// The 3-4 digit security code.
  final String securityCode;

  /// Optional billing address if required by the merchant account.
  final Map<String, String>? billingAddress;

  const PayPalCard({
    required this.cardholderName,
    required this.cardNumber,
    required this.expirationMonth,
    required this.expirationYear,
    required this.securityCode,
    this.billingAddress,
  });

  /// Converts the card details to a map for native bridge communication.
  Map<String, dynamic> toJson() {
    return {
      'cardholderName': cardholderName,
      'cardNumber': cardNumber,
      'expirationMonth': expirationMonth,
      'expirationYear': expirationYear,
      'securityCode': securityCode,
      if (billingAddress != null) 'billingAddress': billingAddress,
    };
  }
}

/// Represents the result of a PayPal payment approval process.
class PayPalPaymentResult {
  /// Whether the payment was successfully approved.
  final bool success;

  /// The PayPal Order ID associated with this payment.
  final String? orderId;

  /// The Payer ID returned by PayPal after approval (if available).
  final String? payerId;

  /// The current status of the order (e.g., "APPROVED", "COMPLETED").
  final String? status;

  /// Detailed error code if the payment failed (e.g., "USER_CANCELLED", "SDK_NOT_INITIALIZED", "PAYMENT_TIMEOUT").
  final String? errorCode;

  /// A human-readable message explaining the result or error.
  final String? message;

  const PayPalPaymentResult({
    required this.success,
    this.orderId,
    this.payerId,
    this.status,
    this.errorCode,
    this.message,
  });

  /// Factory constructor to create a result from a native map response.
  factory PayPalPaymentResult.fromMap(Map<dynamic, dynamic> map) {
    return PayPalPaymentResult(
      success: map['success'] as bool? ?? false,
      orderId: map['orderId'] as String?,
      payerId: map['payerId'] as String?,
      status: map['status'] as String?,
      errorCode: map['errorCode'] as String?,
      message: map['message'] as String?,
    );
  }

  /// Convenience factory for timeout errors.
  factory PayPalPaymentResult.timeout() {
    return const PayPalPaymentResult(
      success: false,
      errorCode: 'PAYMENT_TIMEOUT',
      message: 'The payment approval process timed out after 60 seconds.',
    );
  }

  /// Convenience factory for initialization errors.
  factory PayPalPaymentResult.notInitialized() {
    return const PayPalPaymentResult(
      success: false,
      errorCode: 'SDK_NOT_INITIALIZED',
      message: 'PayPal SDK must be initialized before calling approveOrder.',
    );
  }

  /// Convenience factory for concurrency errors.
  factory PayPalPaymentResult.alreadyInProgress() {
    return const PayPalPaymentResult(
      success: false,
      errorCode: 'PAYMENT_IN_PROGRESS',
      message: 'A payment approval is already in progress.',
    );
  }

  @override
  String toString() {
    return 'PayPalPaymentResult(success: $success, orderId: $orderId, status: $status, errorCode: $errorCode, message: $message)';
  }
}
