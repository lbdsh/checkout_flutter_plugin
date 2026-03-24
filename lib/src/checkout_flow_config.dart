import 'checkout_flow_environment.dart';

/// Configuration for the Checkout.com Flow component.
class CheckoutFlowConfig {
  /// The public API key from Checkout.com.
  final String publicKey;

  /// The payment session ID returned from the Payment Sessions API.
  final String paymentSessionId;

  /// The payment session token returned from the Payment Sessions API.
  final String paymentSessionToken;

  /// The payment session secret returned from the Payment Sessions API.
  final String paymentSessionSecret;

  /// The environment to use (sandbox or production).
  final CheckoutFlowEnvironment environment;

  const CheckoutFlowConfig({
    required this.publicKey,
    required this.paymentSessionId,
    required this.paymentSessionToken,
    required this.paymentSessionSecret,
    this.environment = CheckoutFlowEnvironment.sandbox,
  });

  /// Converts this configuration to a map for platform channel serialization.
  Map<String, dynamic> toMap() {
    return {
      'publicKey': publicKey,
      'paymentSessionId': paymentSessionId,
      'paymentSessionToken': paymentSessionToken,
      'paymentSessionSecret': paymentSessionSecret,
      'environment': environment.name,
    };
  }
}
