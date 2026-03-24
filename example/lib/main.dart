import 'package:flutter/material.dart';
import 'package:checkout_com_flow/checkout_com_flow.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checkout Flow Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const PaymentPage(),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _status = 'Ready to pay';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Flow')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(
              child: CheckoutFlowWidget(
                config: const CheckoutFlowConfig(
                  // Replace these with values from your Payment Sessions API.
                  publicKey: 'pk_sbox_xxxxxxxxxx',
                  paymentSessionId: 'ps_xxxxxxxxxx',
                  paymentSessionToken: 'token_xxxxxxxxxx',
                  paymentSessionSecret: 'secret_xxxxxxxxxx',
                  environment: CheckoutFlowEnvironment.sandbox,
                ),
                onResult: (result) {
                  setState(() {
                    _status = switch (result) {
                      CheckoutFlowSuccess(paymentId: final id) =>
                        'Payment successful! ID: $id',
                      CheckoutFlowError(message: final msg) =>
                        'Payment error: $msg',
                      CheckoutFlowCancelled() => 'Payment cancelled',
                    };
                  });
                },
                onReady: () {
                  setState(() => _status = 'Flow component ready');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
