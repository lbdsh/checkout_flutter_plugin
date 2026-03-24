# checkout_com_flow

A Flutter plugin that integrates [Checkout.com Flow](https://www.checkout.com/docs/payments/accept-payments) payment components for Android and iOS.

Flow provides a pre-built, customizable payment UI that handles card payments, Apple Pay, Google Pay, and other payment methods — all managed by Checkout.com.

---

> **DISCLAIMER — UNOFFICIAL PLUGIN**
>
> This package is **NOT** an official Checkout.com product. It is an independent, community-driven project and is **not affiliated with, endorsed by, sponsored by, or in any way officially connected to Checkout.com** or any of its subsidiaries or affiliates.
>
> The official Checkout.com website can be found at [https://www.checkout.com](https://www.checkout.com).
>
> For any questions, issues, or support regarding Checkout.com products and services, please contact Checkout.com directly:
>
> - **Documentation:** [https://www.checkout.com/docs](https://www.checkout.com/docs)
> - **Support:** [https://www.checkout.com/contact-us](https://www.checkout.com/contact-us)
>
> The names "Checkout.com", "Flow", and any related trademarks are the property of their respective owners.

---

## Warranty & Liability

**THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT.**

**IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.**

The authors of this plugin:

- Make **no guarantees** about the correctness, reliability, or security of this software.
- Accept **no responsibility** for any financial loss, data breach, or other damages resulting from the use of this plugin.
- Provide **no warranty** that this plugin will be compatible with current or future versions of the Checkout.com APIs or SDKs.
- Offer **no official support** — issues may be filed on the repository, but responses are on a best-effort basis.

**By using this plugin, you acknowledge that you do so entirely at your own risk.**

For production payment processing, always refer to the [official Checkout.com documentation](https://www.checkout.com/docs) and consider using the official native SDKs directly.

---

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
  checkout_com_flow: ^0.1.0
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
import 'package:checkout_com_flow/checkout_com_flow.dart';

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

## Contributing

Contributions are welcome! Please note that this is a community project — it is not maintained by Checkout.com. Before submitting a pull request, ensure your changes work on both Android and iOS.

## Sponsors

This project is made possible thanks to the support of:

- **[LBD](https://www.lbdsh.com)** — Digital solutions & software development
- **[Transfeero](https://www.transfeero.com)** — Global transfer and mobility platform

Interested in sponsoring this project? [Get in touch](https://github.com/lbdsh/checkout_flutter_plugin/issues).

## License

MIT License. See [LICENSE](LICENSE) for details.

---

*This project is not affiliated with Checkout.com. All trademarks belong to their respective owners.*
