## 0.1.0

* **Initial feature-complete release** for PayPal Advanced Checkout integration.
* Added `initialize` method with support for Client ID, Environment (Sandbox/Live), and Return URL.
* Added `approveOrder` method for processing credit card payments natively.
* Introduced `PayPalCard` and `PayPalPaymentResult` models for structured data handling.
* Improved error handling with descriptive codes like `SDK_NOT_INITIALIZED`, `USER_CANCELLED`, and `PAYMENT_TIMEOUT`.
* Implemented a 60-second timeout for native payment flows.
* Updated standard return URL scheme to `com.am.amflutterpaypal`.
* Added comprehensive documentation and example project.
