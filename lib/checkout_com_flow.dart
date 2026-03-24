/// Flutter plugin for Checkout.com Flow payment components.
///
/// Provides [CheckoutFlowWidget] to embed the native Checkout.com Flow UI
/// for accepting payments on Android and iOS.
///
/// ## Quick Start
///
/// ```dart
/// CheckoutFlowWidget(
///   config: CheckoutFlowConfig(
///     publicKey: 'pk_sbox_xxx',
///     paymentSessionId: 'ps_xxx',
///     paymentSessionToken: 'token_xxx',
///     paymentSessionSecret: 'secret_xxx',
///   ),
///   onResult: (result) {
///     switch (result) {
///       case CheckoutFlowSuccess(:final paymentId):
///         print('Paid: $paymentId');
///       case CheckoutFlowError(:final message):
///         print('Error: $message');
///       case CheckoutFlowCancelled():
///         print('Cancelled');
///     }
///   },
/// )
/// ```
library;

export 'src/checkout_flow_config.dart';
export 'src/checkout_flow_environment.dart';
export 'src/checkout_flow_result.dart';
export 'src/checkout_flow_widget.dart';
