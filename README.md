# am_flutter_paypal

> [!IMPORTANT]
> **DISCLAIMER**: This is an **UNOFFICIAL** community-driven Flutter plugin for PayPal Advanced Checkout. It is not developed, maintained, or supported by PayPal.

A secure Flutter plugin for PayPal Advanced Checkout integration (Approval Only). This plugin handles the secure entry and approval of card details using PayPal's native SDKs.

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

In your `android/app/src/main/AndroidManifest.xml`, add the following intent filter inside the `<activity>` tag that handles the PayPal return:

```xml
<intent-filter android:label="paypalpay">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.am.amflutterpaypal" android:host="paypalpay" />
</intent-filter>
```

> [!TIP]
> Make sure the `android:scheme` matches the `returnUrl` you pass during initialization.

### 3. iOS Setup

In your `ios/Runner/Info.plist`, add the URL Scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>paypalpay</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.am.amflutterpaypal</string>
        </array>
    </dict>
</array>
```

## Usage

### 1. Initialization

Initialize the SDK once with your Client ID and a unique return URL.

```dart
final bool initialized = await AmFlutterPaypal.initialize(
  clientId: "YOUR_PAYPAL_CLIENT_ID",
  environment: PayPalEnvironment.sandbox, // or PayPalEnvironment.live
  returnUrl: "com.am.amflutterpaypal://paypalpay",
);
```

### 2. Approve Order

Call your backend to get an `orderId`, then pass it to the plugin along with the `PayPalCard` details.

```dart
final card = PayPalCard(
  cardholderName: "John Doe",
  cardNumber: "1234567812345678",
  expirationMonth: "12",
  expirationYear: "2025",
  securityCode: "123",
  billingAddress: {
    "street": "123 Main St",
    "city": "San Jose",
    "state": "CA",
    "zip": "95131",
    "country": "US",
  },
);

final result = await AmFlutterPaypal.approveOrder(
  orderId: "ORDER_ID_FROM_BACKEND",
  card: card,
);

if (result.success) {
  print("Payment Approved! Order ID: ${result.orderId}");
  // Now call your backend to CAPTURE the payment using result.orderId
} else {
  print("Payment Failed: ${result.errorCode} - ${result.message}");
}
```

## Error Codes

| Error Code | Description |
|------------|-------------|
| `SDK_NOT_INITIALIZED` | `initialize` was not called or failed. |
| `PAYMENT_IN_PROGRESS` | Another payment approval is already active. |
| `PAYMENT_TIMEOUT` | No response from native SDK after 60 seconds. |
| `USER_CANCELLED` | User closed the payment/3DS UI. |
| `INVALID_ARGUMENTS` | Missing Order ID or card details. |
| `AUTHORIZATION_REQUIRED` | Additional authorization (like 3DS) was required but not completed. |
| `PLATFORM_ERROR` | An error occurred in the native Android or iOS layer. |

## Important Security Note

**Never** include your PayPal Secret Key in your Flutter code. Always use a secure backend to interact with PayPal's REST APIs for order creation and capture.
