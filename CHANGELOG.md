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
