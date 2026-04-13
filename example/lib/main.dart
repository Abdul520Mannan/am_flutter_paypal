import 'package:flutter/material.dart';
import 'package:am_flutter_paypal/am_flutter_paypal.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Idle';
  bool _isInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initPayPal();
  }

  // Initialize the PayPal SDK ONCE (at app startup)
  Future<void> _initPayPal() async {
    final success = await AmFlutterPaypal.initialize(
      clientId: 'YOUR_SANDBOX_CLIENT_ID', // Replace with your real client ID
      environment: PayPalEnvironment.sandbox,
      returnUrl: 'com.am.amflutterpaypal://paypalpay',
    );
    if (mounted) {
      setState(() {
        _isInitialized = success;
        _status = success ? 'PayPal Initialized' : 'Initialization Failed';
      });
    }
  }

  // Simulate backend order creation (replace with your real backend call)
  Future<String?> _createOrderOnBackend(double amount) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-backend.com/api/paypal/create-order'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer YOUR_TOKEN'},
        body: jsonEncode({'amount': amount, 'currency': 'USD'}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['order_id'] as String?;
      } else {
        setState(() => _status = 'Order creation failed: ${response.body}');
        return null;
      }
    } catch (e) {
      setState(() => _status = 'Order creation error: $e');
      return null;
    }
  }

  // Simulate backend payment capture (replace with your real backend call)
  Future<bool> _capturePaymentOnBackend(String orderId) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-backend.com/api/paypal/capture-payment'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer YOUR_TOKEN'},
        body: jsonEncode({'order_id': orderId}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        setState(() => _status = 'Capture failed: ${response.body}');
        return false;
      }
    } catch (e) {
      setState(() => _status = 'Capture error: $e');
      return false;
    }
  }

  Future<void> _startPayment() async {
    if (!_isInitialized || _isProcessing) return;
    setState(() {
      _isProcessing = true;
      _status = 'Creating order on backend...';
    });

    // 1. Create order on backend
    final orderId = await _createOrderOnBackend(10.00); // Example amount
    if (orderId == null) {
      setState(() => _isProcessing = false);
      return;
    }

    setState(() => _status = 'Approving payment...');

    // 2. Collect card details (in production, use a secure form)
    final card = PayPalCard(
      cardholderName: 'John Doe',
      cardNumber: '4111111111111111', // Test card
      expirationMonth: '12',
      expirationYear: '2025',
      securityCode: '123',
      billingAddress: {'street': '123 Main St', 'city': 'San Jose', 'state': 'CA', 'zip': '95131', 'country': 'US'},
    );

    // 3. Approve order using the plugin
    final result = await AmFlutterPaypal.approveOrder(orderId: orderId, card: card);

    if (!result.success) {
      setState(() {
        _status = 'Payment Error: ${result.errorCode}\n${result.message}';
        _isProcessing = false;
      });
      return;
    }

    setState(() => _status = 'Capturing payment on backend...');

    // 4. Capture payment on backend
    final captured = await _capturePaymentOnBackend(orderId);
    setState(() {
      _isProcessing = false;
      if (captured) {
        _status = 'Payment Captured!\nOrder ID: $orderId';
      } else {
        _status = 'Payment approved, but capture failed.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('PayPal Approval Example'), backgroundColor: Colors.blueAccent),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payment, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: (_isInitialized && !_isProcessing) ? _startPayment : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Start PayPal Payment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
