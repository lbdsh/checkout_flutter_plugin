## 1.4.0

- **New:** `tokenOnly` mode — set `tokenOnly: true` in `CheckoutFlowConfig` to tokenize the card without processing payment. Returns `CheckoutFlowTokenized` with the card token for server-side payment processing.
- **New:** `CheckoutFlowTokenized` result class with `token`, `type`, and `preferredScheme` fields.
- **iOS:** Uses `PaymentButtonAction.tokenization` and `onTokenized` callback when `tokenOnly` is enabled.
- **iOS/Android:** `tokenOnly` flag passed via platform channel.

## 1.3.1

- **Fix:** iOS height tracking now uses `sizeThatFits` with timer polling instead of KVO, reliably detecting SwiftUI content size changes (e.g. validation errors).
- **Fix:** Added `sizingOptions = .intrinsicContentSize` on iOS 16+ for accurate hosting controller sizing.
- **Fix:** iOS 15 compatibility preserved with availability check.

## 1.3.0

- **New:** Dynamic height — widget auto-resizes when content changes (e.g. validation errors appear), growing downward with smooth animation.
- **New:** `onHeightChanged` method channel from native iOS to report content height changes.
- **Dart:** Widget now uses `AnimatedSize` for smooth height transitions instead of fixed `SizedBox`.

## 1.2.0

- **New:** Locale support — pass `locale` parameter (e.g. `"it-IT"`, `"de-DE"`) to display the payment form in the user's language.
- **iOS/Android:** Locale forwarded to native SDK `Configuration`.

## 1.1.0

- **New:** Full theme customization via `CheckoutFlowTheme` — supports all 12 color tokens (`actionColor`, `backgroundColor`, `formBackgroundColor`, `primaryColor`, etc.) and border radius for buttons and form fields.
- **New:** Built-in dark mode preset with `CheckoutFlowTheme.dark()`.
- **New:** Component type selection via `CheckoutComponentType` — choose between `flow` (full payment method selector) or `card` (card-only fields with Pay button).
- **iOS:** Theme colors and border radius passed to native `DesignTokens` API.
- **Android:** Component type support (`ComponentName.Card` vs `ComponentName.Flow`).
- **Improved:** Error messages now include full error details instead of just `localizedDescription`.
- Updated README with theme customization examples, dark mode guide, and troubleshooting for Xcode 16+/26.

## 1.0.3

- **iOS:** Fixed Xcode 26 build by setting `SWIFT_ENABLE_EXPLICIT_MODULES => NO` in podspec.
- **iOS:** Vendored xcframework works correctly with CocoaPods on Xcode 26.

## 1.0.2

- Version bump for pub.dev publishing.

## 0.3.1

- **iOS:** Fixed Xcode 26 build with `BUILD_LIBRARY_FOR_DISTRIBUTION` xcconfig.
- **iOS:** Added SPM `Package.swift` for Swift Package Manager compatibility.
- **iOS:** Source files moved to SPM-compatible directory structure.

## 0.3.0

- **Breaking:** iOS now uses Swift Package Manager (SPM) instead of vendored xcframework for `CheckoutComponentsSDK`. This fixes build issues with Xcode 26 and explicit module builds.
- **iOS:** Removed vendored `CheckoutComponentsSDK.xcframework`. The SDK is now resolved via SPM from `https://github.com/checkout/checkout-ios-components`.
- **iOS:** Source files moved to SPM-compatible directory structure (`checkout_com_flow/Sources/checkout_com_flow/`).
- Requires Flutter 3.35+ with Swift Package Manager support enabled.

## 0.2.0

- **Breaking:** Updated to Checkout.com Components SDK v1.6.x (iOS and Android).
- **iOS:** Vendored `CheckoutComponentsSDK.xcframework` directly (no longer requires SPM or separate CocoaPods source). Minimum iOS raised to 15.0.
- **Android:** Added JitPack and Fingerprint Maven repositories for transitive dependencies. Added coroutines support for async `create()` API.
- **Dart:** `paymentSessionToken` is now optional (no longer required by native SDKs v1.6+).
- Updated native API calls to match SDK v1.6: `PaymentSession(id:, paymentSessionSecret:)` on iOS, `PaymentSessionResponse(id, secret)` on Android.

## 0.1.1

- Renamed package from `checkout_flow` to `checkout_com_flow`.
- Added disclaimer and liability sections to README.
- Added sponsors section.
- Updated repository links to GitHub.

## 0.1.0

- Initial release.
- Checkout.com Flow payment component as a Flutter widget.
- Android support via `checkout-android-components` SDK.
- iOS support via `CheckoutComponentsSDK`.
- Sandbox and Production environments.
- Typed result callbacks: `CheckoutFlowSuccess`, `CheckoutFlowError`, `CheckoutFlowCancelled`.
