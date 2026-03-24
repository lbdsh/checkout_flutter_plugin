import Flutter
import UIKit
import SwiftUI
import CheckoutComponentsSDK

class CheckoutFlowPlatformView: NSObject, FlutterPlatformView {
    private let containerView: UIView
    private let channel: FlutterMethodChannel
    private var hostingController: UIViewController?

    init(
        frame: CGRect,
        viewId: Int64,
        messenger: FlutterBinaryMessenger,
        args: [String: Any]
    ) {
        self.containerView = UIView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "checkout_flow_view_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()
        setupFlow(args: args)
    }

    func view() -> UIView {
        return containerView
    }

    private func setupFlow(args: [String: Any]) {
        guard let publicKey = args["publicKey"] as? String,
              let paymentSessionId = args["paymentSessionId"] as? String,
              let paymentSessionSecret = args["paymentSessionSecret"] as? String else {
            channel.invokeMethod("onError", arguments: [
                "errorCode": "INVALID_PARAMS",
                "message": "Missing required payment session parameters"
            ])
            return
        }

        let envName = args["environment"] as? String ?? "sandbox"
        let environment: CheckoutComponents.Environment = envName == "production"
            ? .production
            : .sandbox

        let componentType = args["componentType"] as? String ?? "flow"

        // Build DesignTokens from theme map
        let designTokens = Self.buildDesignTokens(from: args["theme"] as? [String: Any])

        let paymentSession = PaymentSession(
            id: paymentSessionId,
            paymentSessionSecret: paymentSessionSecret
        )

        Task { @MainActor in
            do {
                let configuration = try await CheckoutComponents.Configuration(
                    paymentSession: paymentSession,
                    publicKey: publicKey,
                    environment: environment,
                    appearance: designTokens,
                    callbacks: .init(
                        onSuccess: { [weak self] _, paymentID in
                            DispatchQueue.main.async {
                                self?.channel.invokeMethod("onSuccess", arguments: [
                                    "paymentId": paymentID
                                ])
                            }
                        },
                        onError: { [weak self] error in
                            DispatchQueue.main.async {
                                self?.channel.invokeMethod("onError", arguments: [
                                    "errorCode": "PAYMENT_ERROR",
                                    "message": "\(error)"
                                ])
                            }
                        }
                    )
                )

                let checkoutComponents = try CheckoutComponents(configuration: configuration)

                let component: any CheckoutComponents.Describable & CheckoutComponents.Renderable & CheckoutComponents.Submittable & CheckoutComponents.Tokenizable

                if componentType == "card" {
                    component = try checkoutComponents.create(.card(showPayButton: true))
                } else {
                    component = try checkoutComponents.create(.flow())
                }

                if component.isAvailable {
                    let swiftUIView = component.render()
                    let hosting = UIHostingController(rootView: swiftUIView)
                    self.hostingController = hosting
                    hosting.view.translatesAutoresizingMaskIntoConstraints = false
                    hosting.view.backgroundColor = .clear

                    self.containerView.addSubview(hosting.view)
                    NSLayoutConstraint.activate([
                        hosting.view.topAnchor.constraint(equalTo: self.containerView.topAnchor),
                        hosting.view.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
                        hosting.view.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor),
                        hosting.view.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
                    ])

                    self.channel.invokeMethod("onReady", arguments: nil)
                } else {
                    self.channel.invokeMethod("onError", arguments: [
                        "errorCode": "UNAVAILABLE",
                        "message": "Component is not available"
                    ])
                }
            } catch {
                self.channel.invokeMethod("onError", arguments: [
                    "errorCode": "INIT_ERROR",
                    "message": "\(error)"
                ])
            }
        }
    }

    // MARK: - Design Tokens

    private static func buildDesignTokens(from themeMap: [String: Any]?) -> CheckoutComponents.DesignTokens {
        guard let themeMap = themeMap else { return .init() }

        let colorTokens = CheckoutComponents.ColorTokens(
            action: color(from: themeMap, key: "actionColor", fallback: .brightBlue),
            background: color(from: themeMap, key: "backgroundColor", fallback: .white),
            border: color(from: themeMap, key: "borderColor", fallback: .softGray),
            disabled: color(from: themeMap, key: "disabledColor", fallback: .brightGray),
            error: color(from: themeMap, key: "errorColor", fallback: .deepRed),
            formBackground: color(from: themeMap, key: "formBackgroundColor", fallback: .white),
            formBorder: color(from: themeMap, key: "formBorderColor", fallback: .mediumGray),
            inverse: color(from: themeMap, key: "inverseColor", fallback: .white),
            outline: color(from: themeMap, key: "outlineColor", fallback: .lightBlue),
            primary: color(from: themeMap, key: "primaryColor", fallback: .black),
            secondary: color(from: themeMap, key: "secondaryColor", fallback: .lightGray),
            success: color(from: themeMap, key: "successColor", fallback: .checkoutGreen)
        )

        var borderButtonRadius = CheckoutComponents.BorderRadius(radius: 8)
        var borderFormRadius = CheckoutComponents.BorderRadius(radius: 8)
        if let btnRadius = themeMap["borderButtonRadius"] as? Double {
            borderButtonRadius = CheckoutComponents.BorderRadius(radius: btnRadius)
        }
        if let formRadius = themeMap["borderFormRadius"] as? Double {
            borderFormRadius = CheckoutComponents.BorderRadius(radius: formRadius)
        }

        return CheckoutComponents.DesignTokens(
            colorTokensMain: colorTokens,
            borderButtonRadius: borderButtonRadius,
            borderFormRadius: borderFormRadius
        )
    }

    private static func color(from map: [String: Any], key: String, fallback: Color) -> Color {
        guard let hex = map[key] as? String else { return fallback }
        return Color(hex: hex)
    }
}

// MARK: - Color hex helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
