package com.checkout.flow

import io.flutter.embedding.engine.plugins.FlutterPlugin

class CheckoutFlowPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding.platformViewRegistry.registerViewFactory(
            "checkout_flow_view",
            CheckoutFlowViewFactory(binding.binaryMessenger)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
