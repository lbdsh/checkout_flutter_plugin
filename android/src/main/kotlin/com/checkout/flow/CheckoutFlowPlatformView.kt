package com.checkout.flow

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import com.checkout.components.core.CheckoutComponentsFactory
import com.checkout.components.interfaces.model.ComponentName
import com.checkout.components.interfaces.component.CheckoutComponentConfiguration
import com.checkout.components.interfaces.model.PaymentSessionResponse
import com.checkout.components.interfaces.Environment
import com.checkout.components.interfaces.component.ComponentCallback
import com.checkout.components.interfaces.error.CheckoutError
import com.checkout.components.interfaces.localisation.Locale as CkoLocale
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

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
            val paymentSessionSecret = params["paymentSessionSecret"] as? String
                ?: return invokeOnMain("onError", mapOf("errorCode" to "INVALID_PARAMS", "message" to "Missing paymentSessionSecret"))
            val envName = params["environment"] as? String ?: "sandbox"

            val environment = when (envName) {
                "production" -> Environment.PRODUCTION
                else -> Environment.SANDBOX
            }

            val localeStr = params["locale"] as? String
            val ckoLocale: CkoLocale? = when (localeStr?.take(2)?.lowercase()) {
                "it" -> CkoLocale.It
                "en" -> CkoLocale.En
                "de" -> CkoLocale.De
                "fr" -> CkoLocale.Fr
                "es" -> CkoLocale.Es
                "pt" -> CkoLocale.Pt
                "nl" -> CkoLocale.Nl
                "ar" -> CkoLocale.Ar
                "da" -> CkoLocale.Da
                "el" -> CkoLocale.El
                "fi" -> CkoLocale.Fi
                "hi" -> CkoLocale.Hi
                "id" -> CkoLocale.Id
                "ja" -> CkoLocale.Ja
                "ms" -> CkoLocale.Ms
                "nb" -> CkoLocale.Nb
                "sv" -> CkoLocale.Sv
                "th" -> CkoLocale.Th
                "vi" -> CkoLocale.Vi
                "zh" -> CkoLocale.Zh
                else -> null
            }

            val config = CheckoutComponentConfiguration(
                context = context,
                publicKey = publicKey,
                environment = environment,
                locale = ckoLocale,
                paymentSession = PaymentSessionResponse(
                    id = paymentSessionId,
                    secret = paymentSessionSecret
                ),
                componentCallback = ComponentCallback(
                    onSuccess = { _, paymentId ->
                        invokeOnMain("onSuccess", mapOf("paymentId" to paymentId))
                    },
                    onError = { _, error ->
                        invokeOnMain("onError", mapOf(
                            "errorCode" to "PAYMENT_ERROR",
                            "message" to (error.message ?: "Payment error")
                        ))
                    }
                )
            )

            CoroutineScope(Dispatchers.Main).launch {
                try {
                    val checkoutComponents = CheckoutComponentsFactory(config).create()
                    val flow = checkoutComponents.create(ComponentName.Flow)

                    flow.provideView(containerView)
                    invokeOnMain("onReady", null)
                } catch (e: Exception) {
                    invokeOnMain(
                        "onError",
                        mapOf("errorCode" to "INIT_ERROR", "message" to (e.message ?: "Checkout initialization error"))
                    )
                }
            }
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
