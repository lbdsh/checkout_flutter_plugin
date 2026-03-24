# checkout_flow

A Flutter plugin that integrates [Checkout.com Flow](https://www.checkout.com/docs/payments/accept-payments) payment components for Android and iOS.

Flow provides a pre-built, customizable payment UI that handles card payments, Apple Pay, Google Pay, and other payment methods — all managed by Checkout.com.

## Features

- Native Checkout.com Flow UI embedded as a Flutter widget
- Supports Android (Jetpack Views) and iOS (UIKit)
- Sandbox and Production environments
- Typed result callbacks (success, error, cancelled)
- Apple Pay and Google Pay support (managed by Flow)

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| Android  | API 21 (5.0)   |
| iOS      | 13.0           |
| Flutter  | 3.10.0         |
| Dart     | 3.0.0          |

### API Key Scopes

Your Checkout.com public key must have these scopes enabled:

- `payment-sessions:pay`
- `vault-tokenization`

Your secret key (server-side only) must have:

- `payment-sessions`

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  checkout_flow: ^0.1.0
```

Then run:

```bash
flutter pub get
```

### Android Setup

Ensure `mavenCentral()` is in your project-level `build.gradle` repositories:

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### iOS Setup

Run `pod install` in the `ios/` directory:

```bash
cd ios && pod install
```

## Usage

### 1. Create a Payment Session (server-side)

Call the Checkout.com [Payment Sessions API](https://www.checkout.com/docs/payments/accept-payments) from your backend:

```bash
curl -X POST https://api.checkout.com/payment-sessions \
  -H "Authorization: Bearer sk_sbox_xxx" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000,
    "currency": "GBP",
    "reference": "ORD-123",
    "display_name": "My Shop",
    "billing": { "address": { "country": "GB" } },
    "customer": { "name": "Jane Doe", "email": "jane@example.com" },
    "success_url": "https://example.com/success",
    "failure_url": "https://example.com/failure"
  }'
```

The response contains `id`, `paymentSessionToken`, and `paymentSessionSecret`.

### 2. Render the Flow widget

```dart
import 'package:checkout_flow/checkout_flow.dart';

CheckoutFlowWidget(
  config: CheckoutFlowConfig(
    publicKey: 'pk_sbox_xxx',
    paymentSessionId: 'ps_xxx',
    paymentSessionToken: 'token_xxx',
    paymentSessionSecret: 'secret_xxx',
    environment: CheckoutFlowEnvironment.sandbox,
  ),
  onResult: (result) {
    switch (result) {
      case CheckoutFlowSuccess(:final paymentId):
        print('Payment successful: $paymentId');
      case CheckoutFlowError(:final message):
        print('Payment error: $message');
      case CheckoutFlowCancelled():
        print('Payment cancelled');
    }
  },
  onReady: () {
    print('Flow component is ready');
  },
  height: 500, // optional, defaults to 400
)
```

### 3. Handle the result

`CheckoutFlowResult` is a sealed class with three subtypes:

| Type | Fields | Description |
|------|--------|-------------|
| `CheckoutFlowSuccess` | `paymentId` | Synchronous payment completed |
| `CheckoutFlowError` | `errorCode`, `message` | Payment failed or initialization error |
| `CheckoutFlowCancelled` | — | User cancelled the payment |

### Asynchronous payments

Some payment methods (e.g. 3DS, redirects) complete asynchronously. In this case, Checkout.com sends a webhook notification with `data.metadata.cko_payment_session_id`, and the customer is redirected to your `success_url` or `failure_url`.

## API Reference

### CheckoutFlowConfig

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `publicKey` | `String` | Yes | Your Checkout.com public API key |
| `paymentSessionId` | `String` | Yes | Payment session ID from server |
| `paymentSessionToken` | `String` | Yes | Payment session token from server |
| `paymentSessionSecret` | `String` | Yes | Payment session secret from server |
| `environment` | `CheckoutFlowEnvironment` | No | `sandbox` (default) or `production` |

### CheckoutFlowWidget

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `config` | `CheckoutFlowConfig` | Yes | Payment session configuration |
| `onResult` | `ValueChanged<CheckoutFlowResult>` | Yes | Callback for payment results |
| `onReady` | `VoidCallback?` | No | Called when Flow UI is rendered |
| `height` | `double?` | No | Widget height (default: 400) |

### CheckoutFlowEnvironment

| Value | Description |
|-------|-------------|
| `sandbox` | Test environment |
| `production` | Live environment |

## Troubleshooting

### Flow component not available

If you receive a `CheckoutFlowError` with code `UNAVAILABLE`, check that:
- Your public key has the correct scopes
- The payment session was created correctly
- The currency/country combination is supported

### Build errors on Android

Ensure your `minSdkVersion` is at least 21 and `compileSdkVersion` is at least 34.

### Build errors on iOS

Ensure your deployment target is at least iOS 13.0 in your Xcode project settings.

## License

MIT License. See [LICENSE](LICENSE) for details.
