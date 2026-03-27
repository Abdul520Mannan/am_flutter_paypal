import 'package:flutter/material.dart';
import 'package:am_flutter_paypal/am_flutter_paypal.dart';

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

  @override
  void initState() {
    super.initState();
    _initPayPal();
  }

  Future<void> _initPayPal() async {
    final success = await AmFlutterPaypal.initialize(
      clientId: 'YOUR_SANDBOX_CLIENT_ID', // Replace with real ID
      environment: PayPalEnvironment.sandbox,
    );
    if (mounted) {
      setState(() {
        _isInitialized = success;
        _status = success ? 'PayPal Initialized' : 'Initialization Failed';
      });
    }
  }

  Future<void> _startPayment() async {
    if (!_isInitialized) {
      _initPayPal();
      return;
    }

    setState(() {
      _status = 'Processing Payment...';
    });

    const card = PayPalCard(
      cardholderName: 'John Doe',
      cardNumber: '1111222233334444', // Dummy card
      expirationMonth: '12',
      expirationYear: '2025',
      securityCode: '123',
    );

    // In a real app, get this from your backend
    const dummyOrderId = '9AF4166299863452B'; 

    final result = await AmFlutterPaypal.approveOrder(
      orderId: dummyOrderId,
      card: card,
    );

    if (mounted) {
      setState(() {
        if (result.success) {
          _status = 'Payment Approved!\nOrder ID: ${result.orderId}';
        } else {
          _status = 'Payment Error: ${result.errorCode}\n${result.message}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PayPal Approval Plugin'),
          backgroundColor: Colors.blueAccent,
        ),
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
                  onPressed: _isInitialized ? _startPayment : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve Dummy Order'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
