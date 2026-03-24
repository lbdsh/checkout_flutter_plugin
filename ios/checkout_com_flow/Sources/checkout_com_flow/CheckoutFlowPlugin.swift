import Flutter
import UIKit

public class CheckoutFlowPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = CheckoutFlowViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "checkout_flow_view")
    }
}
