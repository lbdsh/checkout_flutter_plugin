import 'checkout_flow_environment.dart';

/// The type of component to render.
enum CheckoutComponentType {
  /// Full Flow component with payment method selector (card, Apple Pay, etc.)
  flow,

  /// Card-only component — just the card fields and pay button, no radio.
  card,
}

/// Configuration for the Checkout.com Flow component.
class CheckoutFlowConfig {
  /// The public API key from Checkout.com.
  final String publicKey;

  /// The payment session ID returned from the Payment Sessions API.
  final String paymentSessionId;

  /// The payment session token returned from the Payment Sessions API.
  /// No longer required by native SDKs v1.6+. Kept for backwards compatibility.
  final String? paymentSessionToken;

  /// The payment session secret returned from the Payment Sessions API.
  final String paymentSessionSecret;

  /// The environment to use (sandbox or production).
  final CheckoutFlowEnvironment environment;

  /// The component type to render: flow (full) or card (card-only).
  final CheckoutComponentType componentType;

  /// Optional theme customization.
  final CheckoutFlowTheme? theme;

  const CheckoutFlowConfig({
    required this.publicKey,
    required this.paymentSessionId,
    this.paymentSessionToken,
    required this.paymentSessionSecret,
    this.environment = CheckoutFlowEnvironment.sandbox,
    this.componentType = CheckoutComponentType.flow,
    this.theme,
  });

  /// Converts this configuration to a map for platform channel serialization.
  Map<String, dynamic> toMap() {
    return {
      'publicKey': publicKey,
      'paymentSessionId': paymentSessionId,
      if (paymentSessionToken != null)
        'paymentSessionToken': paymentSessionToken,
      'paymentSessionSecret': paymentSessionSecret,
      'environment': environment.name,
      'componentType': componentType.name,
      if (theme != null) 'theme': theme!.toMap(),
    };
  }
}

/// Theme customization for the Checkout.com component.
/// All color values should be hex strings (e.g. "#1A1A2E", "#FF6B00").
class CheckoutFlowTheme {
  /// Primary action color (buttons, links).
  final String? actionColor;

  /// Background color of the component container.
  final String? backgroundColor;

  /// Border color.
  final String? borderColor;

  /// Disabled state color.
  final String? disabledColor;

  /// Error color.
  final String? errorColor;

  /// Form fields background color.
  final String? formBackgroundColor;

  /// Form fields border color.
  final String? formBorderColor;

  /// Inverse color (text on action buttons).
  final String? inverseColor;

  /// Outline/focus color.
  final String? outlineColor;

  /// Primary text color.
  final String? primaryColor;

  /// Secondary text color (placeholders, hints).
  final String? secondaryColor;

  /// Success color.
  final String? successColor;

  /// Border radius for buttons.
  final double? borderButtonRadius;

  /// Border radius for form fields.
  final double? borderFormRadius;

  const CheckoutFlowTheme({
    this.actionColor,
    this.backgroundColor,
    this.borderColor,
    this.disabledColor,
    this.errorColor,
    this.formBackgroundColor,
    this.formBorderColor,
    this.inverseColor,
    this.outlineColor,
    this.primaryColor,
    this.secondaryColor,
    this.successColor,
    this.borderButtonRadius,
    this.borderFormRadius,
  });

  /// Dark theme preset.
  const CheckoutFlowTheme.dark({
    this.actionColor = '#FFFFFF',
    this.backgroundColor = '#1A1A2E',
    this.borderColor = '#3A3A4E',
    this.disabledColor = '#4A4A5E',
    this.errorColor = '#FF6B6B',
    this.formBackgroundColor = '#2A2A3E',
    this.formBorderColor = '#4A4A5E',
    this.inverseColor = '#1A1A2E',
    this.outlineColor = '#6C6CFF',
    this.primaryColor = '#FFFFFF',
    this.secondaryColor = '#9A9AAE',
    this.successColor = '#4ADE80',
    this.borderButtonRadius = 12,
    this.borderFormRadius = 8,
  });

  Map<String, dynamic> toMap() {
    return {
      if (actionColor != null) 'actionColor': actionColor,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (borderColor != null) 'borderColor': borderColor,
      if (disabledColor != null) 'disabledColor': disabledColor,
      if (errorColor != null) 'errorColor': errorColor,
      if (formBackgroundColor != null) 'formBackgroundColor': formBackgroundColor,
      if (formBorderColor != null) 'formBorderColor': formBorderColor,
      if (inverseColor != null) 'inverseColor': inverseColor,
      if (outlineColor != null) 'outlineColor': outlineColor,
      if (primaryColor != null) 'primaryColor': primaryColor,
      if (secondaryColor != null) 'secondaryColor': secondaryColor,
      if (successColor != null) 'successColor': successColor,
      if (borderButtonRadius != null) 'borderButtonRadius': borderButtonRadius,
      if (borderFormRadius != null) 'borderFormRadius': borderFormRadius,
    };
  }
}
