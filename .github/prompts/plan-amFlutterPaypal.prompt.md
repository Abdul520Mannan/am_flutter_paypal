## am_flutter_paypal

DISCLAIMER:
This is an unofficial, community-driven Flutter plugin for PayPal Advanced Checkout (Card Approval Only). It is not developed, maintained, or supported by PayPal.

A secure Flutter plugin for PayPal card payments using native Android and iOS SDKs.

This plugin handles only:

SDK initialization
Secure card data submission via native SDK
Payment approval (including 3DS / authentication)
Native error and status reporting

It does NOT:

Create PayPal orders
Capture payments
Store or manage PayPal secrets
Expose any backend logic
## 🔌 Plugin Scope

This plugin is a thin native wrapper over PayPal mobile SDKs.

It is responsible only for:

✔ Native SDK initialization
✔ Card-based payment approval
✔ 3DS authentication handling
✔ Returning payment result to Flutter

It does NOT include:

❌ Backend APIs
❌ Order creation
❌ Payment capture
❌ Business logic

## 🏗 Architecture & Payment Flow

This plugin is designed for a secure backend-driven payment system.

Payment Flow
Flutter Card Form
   ↓
Backend API → Create Order
   ↓
Returns Order ID
   ↓
am_flutter_paypal → approveOrder()
   ↓
PayPal Native SDK (Android / iOS)
   ↓
3DS / Authentication
   ↓
Approval Success
   ↓
Backend API → Capture Payment
Responsibilities
Backend
Create PayPal Order (Orders v2 API)
Capture payment after approval
Plugin
Handles approval only via native SDK
Manages 3DS flow
Returns result to Flutter
## 🚀 Getting Started
Requirements
Android: minSdk 24+
iOS: iOS 14.0+
## 🤖 Android Setup

Add this inside your AndroidManifest.xml activity:

<intent-filter android:label="paypalpay">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.am.amflutterpaypal" android:host="paypalpay" />
</intent-filter>

⚠️ Ensure the scheme matches the returnUrl used in initialization.

## 🍏 iOS Setup

Add URL scheme in Info.plist:

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
## ⚙️ Usage
Step 1 — Initialize SDK (once only)
final bool initialized = await AmFlutterPaypal.initialize(
  clientId: "YOUR_PAYPAL_CLIENT_ID",
  environment: PayPalEnvironment.sandbox, // or live
  returnUrl: "com.am.amflutterpaypal://paypalpay",
);
Step 2 — Create Order (Backend call)
final response = await http.post(
  Uri.parse("https://your-backend.com/api/paypal/create-order"),
  headers: {
    "Content-Type": "application/json",
    "Authorization": "Bearer YOUR_TOKEN",
  },
  body: jsonEncode({
    "amount": amount,
    "currency": "USD",
  }),
);

final orderId = jsonDecode(response.body)["order_id"];

Step 3 — Approve Payment
final card = PayPalCard(
  cardholderName: "John Doe",
  cardNumber: "4111111111111111",
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
  orderId: orderId,
  card: card,
);
Step 4 — Capture Payment (Backend)
final response = await http.post(
  Uri.parse("https://your-backend.com/api/paypal/capture-payment"),
  headers: {
    "Content-Type": "application/json",
    "Authorization": "Bearer YOUR_TOKEN",
  },
  body: jsonEncode({
    "payment_id": result.paymentId,
  }),
);

final captured = jsonDecode(response.body)["payment_id"];

⚠️ Show success UI only after capture succeeds

## 💡 Best Practices
Initialize SDK once only (app startup)
Never initialize on every payment click
Disable button during payment processing
Always capture payment after approval
Use live environment only in production
Prevent duplicate payment requests
## 🔐 Security
Card data is never stored or logged
All sensitive operations handled by native PayPal SDK
No PayPal secrets exist in this plugin
Backend must handle:
Order creation
Payment capture
3DS authentication handled natively
## ⚠️ Error Codes
Code	Description
SDK_NOT_INITIALIZED	Plugin not initialized
PAYMENT_IN_PROGRESS	Another payment is active
PAYMENT_TIMEOUT	Approval timed out
USER_CANCELLED	User cancelled payment
INVALID_ARGUMENTS	Missing/invalid data
ACTIVITY_NULL	Android activity not available
MISSING_RETURN_URL	Return URL missing
AUTHORIZATION_REQUIRED	3DS required
UNKNOWN_ERROR	Unexpected native error
## 🚀 Production Checklist
 Live PayPal client ID configured
 Backend order creation API ready
 Backend capture API ready
 Sandbox end-to-end testing completed
 3DS authentication tested
 Cancellation handling tested
 Timeout handling tested
 Duplicate payment prevention tested
## 📦 Repository

GitHub:
https://github.com/Abdul520Mannan/am_flutter_paypal

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributions

Contributions are welcome via pull requests or issues.