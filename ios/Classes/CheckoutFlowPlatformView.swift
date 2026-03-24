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
              let paymentSessionToken = args["paymentSessionToken"] as? String,
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

        let paymentSession = CheckoutComponents.PaymentSessionResponse(
            id: paymentSessionId,
            paymentSessionToken: paymentSessionToken,
            paymentSessionSecret: paymentSessionSecret
        )

        Task { @MainActor in
            do {
                let configuration = try await CheckoutComponents.Configuration(
                    paymentSession: paymentSession,
                    publicKey: publicKey,
                    environment: environment,
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
                                    "message": error.localizedDescription
                                ])
                            }
                        }
                    )
                )

                let checkoutComponents = try CheckoutComponents(configuration: configuration)
                let flowComponent = try checkoutComponents.create(.flow())

                if flowComponent.isAvailable {
                    // The SDK provides a SwiftUI view via render().
                    // Wrap it in a UIHostingController to embed in UIKit.
                    let swiftUIView = flowComponent.render()
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
                        "message": "Flow component is not available"
                    ])
                }
            } catch {
                self.channel.invokeMethod("onError", arguments: [
                    "errorCode": "INIT_ERROR",
                    "message": error.localizedDescription
                ])
            }
        }
    }
}
