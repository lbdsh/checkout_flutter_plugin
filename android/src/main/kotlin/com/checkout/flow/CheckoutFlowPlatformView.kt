package com.checkout.flow

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import com.checkout.components.core.CheckoutComponentsFactory
import com.checkout.components.core.ComponentName
import com.checkout.components.core.CheckoutComponentConfiguration
import com.checkout.components.core.PaymentSessionResponse
import com.checkout.components.core.Environment
import com.checkout.components.core.ComponentCallback
import com.checkout.components.core.error.CheckoutError
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class CheckoutFlowPlatformView(
    private val context: Context,
    viewId: Int,
    messenger: BinaryMessenger,
    private val params: Map<String, Any?>
) : PlatformView {

    private val channel = MethodChannel(messenger, "checkout_flow_view_$viewId")
    private val containerView = FrameLayout(context)
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        setupFlow()
    }

    private fun invokeOnMain(method: String, arguments: Any?) {
        mainHandler.post {
            channel.invokeMethod(method, arguments)
        }
    }

    private fun setupFlow() {
        try {
            val publicKey = params["publicKey"] as? String
                ?: return invokeOnMain("onError", mapOf("errorCode" to "INVALID_PARAMS", "message" to "Missing publicKey"))
            val paymentSessionId = params["paymentSessionId"] as? String
                ?: return invokeOnMain("onError", mapOf("errorCode" to "INVALID_PARAMS", "message" to "Missing paymentSessionId"))
            val paymentSessionToken = params["paymentSessionToken"] as? String
                ?: return invokeOnMain("onError", mapOf("errorCode" to "INVALID_PARAMS", "message" to "Missing paymentSessionToken"))
            val paymentSessionSecret = params["paymentSessionSecret"] as? String
                ?: return invokeOnMain("onError", mapOf("errorCode" to "INVALID_PARAMS", "message" to "Missing paymentSessionSecret"))
            val envName = params["environment"] as? String ?: "sandbox"

            val environment = when (envName) {
                "production" -> Environment.PRODUCTION
                else -> Environment.SANDBOX
            }

            val config = CheckoutComponentConfiguration(
                context = context,
                paymentSession = PaymentSessionResponse(
                    id = paymentSessionId,
                    paymentSessionToken = paymentSessionToken,
                    paymentSessionSecret = paymentSessionSecret
                ),
                publicKey = publicKey,
                environment = environment,
                componentCallback = ComponentCallback(
                    onSuccess = { _, paymentId ->
                        invokeOnMain("onSuccess", mapOf("paymentId" to paymentId))
                    }
                )
            )

            val checkoutComponents = CheckoutComponentsFactory(config).create()
            val flow = checkoutComponents.create(ComponentName.Flow)

            if (flow.isAvailable) {
                flow.provideView(containerView)
                invokeOnMain("onReady", null)
            } else {
                invokeOnMain(
                    "onError",
                    mapOf("errorCode" to "UNAVAILABLE", "message" to "Flow component is not available")
                )
            }
        } catch (e: CheckoutError) {
            invokeOnMain(
                "onError",
                mapOf("errorCode" to "INIT_ERROR", "message" to (e.message ?: "Checkout initialization error"))
            )
        } catch (e: Exception) {
            invokeOnMain(
                "onError",
                mapOf("errorCode" to "UNKNOWN", "message" to (e.message ?: "Unknown error"))
            )
        }
    }

    override fun getView(): View = containerView

    override fun dispose() {}
}
