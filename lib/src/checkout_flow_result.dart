/// Result of a Checkout.com Flow payment.
sealed class CheckoutFlowResult {
  const CheckoutFlowResult();
}

/// Payment completed successfully.
class CheckoutFlowSuccess extends CheckoutFlowResult {
  /// The payment ID returned by Checkout.com.
  final String paymentId;

  const CheckoutFlowSuccess({required this.paymentId});

  @override
  String toString() => 'CheckoutFlowSuccess(paymentId: $paymentId)';
}

/// Payment failed with an error.
class CheckoutFlowError extends CheckoutFlowResult {
  /// The error code, if available.
  final String? errorCode;

  /// A human-readable error message.
  final String message;

  const CheckoutFlowError({this.errorCode, required this.message});

  @override
  String toString() => 'CheckoutFlowError(errorCode: $errorCode, message: $message)';
}

/// Payment was cancelled by the user.
class CheckoutFlowCancelled extends CheckoutFlowResult {
  const CheckoutFlowCancelled();

  @override
  String toString() => 'CheckoutFlowCancelled()';
}
