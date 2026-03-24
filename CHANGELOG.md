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
