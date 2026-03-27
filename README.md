# am_flutter_paypal

> [!IMPORTANT]
> **DISCLAIMER**: This is an **UNOFFICIAL** community-driven Flutter plugin for PayPal Advanced Checkout. It is not developed, maintained, or supported by PayPal.

A Flutter plugin for PayPal Advanced Checkout integration (Approval Only). This plugin handles the secure entry and approval of card details using PayPal's native SDKs.

Repository: [https://github.com/Abdul520Mannan/am_flutter_paypal](https://github.com/Abdul520Mannan/am_flutter_paypal)

## Security Architecture

This plugin follows a secure, backend-driven architecture:
1. **No Backend Secrets**: Client Secrets and API credentials never exist in the mobile app.
2. **Backend Order Creation**: Your server creates the PayPal Order using the Orders v2 API.
3. **Approval Only**: This plugin ONLY handles the `approveOrder` step.
4. **Backend Capture**: Your server captures the payment after the plugin returns a success status.

## Getting Started

### 1. Requirements

- **Android**: minSdk 24+
- **iOS**: iOS 14.0+

### 2. Android Setup

In your `android/build.gradle` (or `build.gradle.kts`):
```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### 3. iOS Setup

In your `ios/Podfile`:
```ruby
platform :ios, '14.0'
```

## Usage

### 1. Initialization

Initialize the SDK once at app startup or before the checkout screen.

```dart
final bool initialized = await AmFlutterPaypal.initialize(
  clientId: "YOUR_PAYPAL_CLIENT_ID",
  environment: PayPalEnvironment.sandbox, // or PayPalEnvironment.live
);
```

### 2. Approve Order

Call your backend to get an `orderId`, then pass it to the plugin.

```dart
final card = PayPalCard(
  cardholderName: "John Doe",
  cardNumber: "1234567812345678",
  expirationMonth: "12",
  expirationYear: "2025",
  securityCode: "123",
);

final result = await AmFlutterPaypal.approveOrder(
  orderId: "ORDER_ID_FROM_BACKEND",
  card: card,
);

if (result.success) {
  print("Payment Approved: ${result.orderId}");
  // Now call your backend to CAPTURE the payment
} else {
  print("Payment Failed: ${result.errorCode} - ${result.message}");
}
```

## Error Codes

| Error Code | Description |
|------------|-------------|
| `SDK_NOT_INITIALIZED` | `initialize` was not called successfully. |
| `PAYMENT_IN_PROGRESS` | Another payment approval is already active. |
| `PAYMENT_TIMEOUT` | No response from native SDK after 60 seconds. |
| `USER_CANCELLED` | User closed the payment/3DS UI. |
| `INVALID_ARGUMENTS` | Missing Order ID or card details. |

## Important Security Note

**Never** include your PayPal Secret Key in your Flutter code. Always use a secure backend to interact with PayPal's REST APIs for order creation and capture.
