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
- Supports Android (Jetpack Compose) and iOS (SwiftUI via UIKit bridge)
- Sandbox and Production environments
- Typed result callbacks (success, error, cancelled, **tokenized**)
- Apple Pay and Google Pay support (managed by Flow)
- **Token-only mode** — tokenize the card without processing payment, for server-side payment control
- **Full theme customization** — all 12 color tokens, border radius, dark mode support (iOS & Android)
- **Component type selection** — full Flow or card-only mode
- **Locale support** — display form in user's language (it, de, fr, es, en, etc.)
- **Skeleton loading** — built-in loading animation while native component initializes
- **Dynamic height** — widget auto-resizes when validation errors appear
- **Transparent container** — payment form blends seamlessly with host app background (light & dark mode)
- iOS uses Swift Package Manager for the native Checkout.com SDK dependency

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| Android  | API 21 (5.0)   |
| iOS      | 15.0           |
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
  checkout_com_flow: ^2.0.0
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

The plugin uses Swift Package Manager to resolve the Checkout.com native SDK. No additional setup is needed if your project uses CocoaPods — the vendored xcframework is included.

If you encounter build issues on Xcode 16+, ensure the podspec includes `SWIFT_ENABLE_EXPLICIT_MODULES => NO` (already set in the published version).

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
  height: 420,
)
```

### 3. Dark mode theme

Use the built-in dark theme preset or customize individual colors:

```dart
CheckoutFlowWidget(
  config: CheckoutFlowConfig(
    publicKey: 'pk_sbox_xxx',
    paymentSessionId: 'ps_xxx',
    paymentSessionSecret: 'secret_xxx',
    // Use the dark theme preset
    theme: const CheckoutFlowTheme.dark(),
  ),
  onResult: _handleResult,
)
```

### 4. Custom theme

Customize every color and border radius:

```dart
CheckoutFlowWidget(
  config: CheckoutFlowConfig(
    publicKey: 'pk_sbox_xxx',
    paymentSessionId: 'ps_xxx',
    paymentSessionSecret: 'secret_xxx',
    theme: const CheckoutFlowTheme(
      actionColor: '#FF6B00',       // Pay button color
      backgroundColor: '#1A1A2E',   // Container background
      formBackgroundColor: '#2A2A3E', // Input fields background
      formBorderColor: '#4A4A5E',   // Input fields border
      primaryColor: '#FFFFFF',      // Primary text
      secondaryColor: '#9A9AAE',    // Placeholder text
      borderColor: '#3A3A4E',       // General borders
      inverseColor: '#1A1A2E',      // Text on action buttons
      outlineColor: '#6C6CFF',      // Focus ring
      errorColor: '#FF6B6B',        // Error messages
      successColor: '#4ADE80',      // Success state
      disabledColor: '#4A4A5E',     // Disabled elements
      borderButtonRadius: 12,       // Button corner radius
      borderFormRadius: 8,          // Input field corner radius
    ),
  ),
  onResult: _handleResult,
)
```

### 5. Token-only mode

Tokenize the card without processing payment — useful when you want to handle payment processing on your server:

```dart
CheckoutFlowWidget(
  config: CheckoutFlowConfig(
    publicKey: 'pk_sbox_xxx',
    paymentSessionId: 'ps_xxx',
    paymentSessionSecret: 'secret_xxx',
    componentType: CheckoutComponentType.card,
    tokenOnly: true,
  ),
  onResult: (result) {
    if (result is CheckoutFlowTokenized) {
      // Send token to your server for payment processing
      print('Token: ${result.token}');
      print('Type: ${result.type}');
      print('Scheme: ${result.preferredScheme}');
    }
  },
)
```

### 6. Locale support

Display the payment form in the user's language:

```dart
CheckoutFlowWidget(
  config: CheckoutFlowConfig(
    publicKey: 'pk_sbox_xxx',
    paymentSessionId: 'ps_xxx',
    paymentSessionSecret: 'secret_xxx',
    locale: 'it', // Italian
  ),
  onResult: _handleResult,
)
```

Supported locales: `en`, `it`, `de`, `fr`, `es`, `pt`, `nl`, `ar`, `da`, `el`, `fi`, `hi`, `id`, `ja`, `ms`, `nb`, `sv`, `th`, `vi`, `zh`.

### 7. Component type

Choose between the full Flow component or card-only mode:

```dart
// Card-only: shows just the card fields and Pay button (no radio selector)
CheckoutFlowWidget(
  config: CheckoutFlowConfig(
    publicKey: 'pk_sbox_xxx',
    paymentSessionId: 'ps_xxx',
    paymentSessionSecret: 'secret_xxx',
    componentType: CheckoutComponentType.card,
  ),
  onResult: _handleResult,
)
```

| Type | Description |
|------|-------------|
| `CheckoutComponentType.flow` | Full Flow UI with payment method selector (default) |
| `CheckoutComponentType.card` | Card-only fields with Pay button, no radio selector |

### 8. Handle the result

`CheckoutFlowResult` is a sealed class with four subtypes:

| Type | Fields | Description |
|------|--------|-------------|
| `CheckoutFlowSuccess` | `paymentId` | Synchronous payment completed |
| `CheckoutFlowTokenized` | `token`, `type`, `preferredScheme` | Card tokenized (token-only mode) |
| `CheckoutFlowError` | `errorCode`, `message` | Payment failed or initialization error |
| `CheckoutFlowCancelled` | — | User cancelled the payment |

### Asynchronous payments

Some payment methods (e.g. 3DS, redirects) complete asynchronously. In this case, Checkout.com sends a webhook notification with `data.metadata.cko_payment_session_id`, and the customer is redirected to your `success_url` or `failure_url`.

## API Reference

### CheckoutFlowConfig

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `publicKey` | `String` | Yes | — | Your Checkout.com public API key |
| `paymentSessionId` | `String` | Yes | — | Payment session ID from server |
| `paymentSessionToken` | `String?` | No | `null` | Payment session token (legacy, optional since SDK v1.6+) |
| `paymentSessionSecret` | `String` | Yes | — | Payment session secret from server |
| `environment` | `CheckoutFlowEnvironment` | No | `sandbox` | `sandbox` or `production` |
| `componentType` | `CheckoutComponentType` | No | `flow` | `flow` or `card` |
| `locale` | `String?` | No | `null` | Form language (e.g. `"it"`, `"de"`, `"fr"`) |
| `tokenOnly` | `bool` | No | `false` | If `true`, tokenizes card without processing payment |
| `theme` | `CheckoutFlowTheme?` | No | `null` | Custom theme (null = default light theme) |

### CheckoutFlowTheme

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `actionColor` | `String?` | `#0B5FFF` | Pay button and link color |
| `backgroundColor` | `String?` | `#FFFFFF` | Container background |
| `borderColor` | `String?` | SDK default | General border color |
| `disabledColor` | `String?` | SDK default | Disabled element color |
| `errorColor` | `String?` | SDK default | Error message color |
| `formBackgroundColor` | `String?` | `#FFFFFF` | Input field background |
| `formBorderColor` | `String?` | SDK default | Input field border |
| `inverseColor` | `String?` | `#FFFFFF` | Text on action buttons |
| `outlineColor` | `String?` | SDK default | Focus ring color |
| `primaryColor` | `String?` | `#000000` | Primary text color |
| `secondaryColor` | `String?` | SDK default | Placeholder/hint text |
| `successColor` | `String?` | SDK default | Success state color |
| `borderButtonRadius` | `double?` | `8` | Button corner radius |
| `borderFormRadius` | `double?` | `8` | Form field corner radius |

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

Ensure your deployment target is at least iOS 15.0 in your Xcode project settings.

### Xcode 16+ / Xcode 26 build errors

If you see `Unable to find module dependency: 'CheckoutComponentsSDK'`, this is related to Xcode's explicit module build feature. The plugin's podspec already sets `SWIFT_ENABLE_EXPLICIT_MODULES => NO` to work around this. If you still encounter issues, add the following to your `ios/Podfile`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_ENABLE_EXPLICIT_MODULES'] = 'NO'
    end
  end
end
```

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
