package com.checkout.flow

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.checkout.components.core.CheckoutComponentsFactory
import com.checkout.components.interfaces.model.ComponentName
import com.checkout.components.interfaces.component.CheckoutComponentConfiguration
import com.checkout.components.interfaces.model.PaymentSessionResponse
import com.checkout.components.interfaces.Environment
import com.checkout.components.interfaces.component.ComponentCallback
import com.checkout.components.interfaces.localisation.Locale as CkoLocale
import com.checkout.components.interfaces.uicustomisation.designtoken.ColorTokens
import com.checkout.components.interfaces.uicustomisation.designtoken.DesignTokens
import com.checkout.components.interfaces.uicustomisation.BorderRadius
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
    private var lastReportedHeight = 0
    private val containerView = FrameLayout(context).apply {
        layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        )
    }
    private val mainHandler = Handler(Looper.getMainLooper())
    private val TAG = "CheckoutFlow"

    init {
        // Monitor height changes and report to Flutter
        containerView.addOnLayoutChangeListener { _, _, top, _, bottom, _, _, _, _ ->
            val heightPx = bottom - top
            val density = context.resources.displayMetrics.density
            val heightDp = (heightPx / density).toInt()
            if (heightDp > 0 && heightDp != lastReportedHeight) {
                lastReportedHeight = heightDp
                Log.d(TAG, "Height changed: ${heightDp}dp")
                invokeOnMain("onHeightChanged", mapOf("height" to heightDp.toDouble()))
            }
        }
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

            // Parse style colors from params
            val styleMap = params["style"] as? Map<String, Any?>
            val appearance = if (styleMap != null) {
                val colorTokens = ColorTokens(
                    colorAction = parseColor(styleMap["actionColor"] as? String),
                    colorBackground = parseColor(styleMap["backgroundColor"] as? String),
                    colorPrimary = parseColor(styleMap["primaryColor"] as? String),
                    colorFormBackground = parseColor(styleMap["formBackgroundColor"] as? String),
                    colorFormBorder = parseColor(styleMap["formBorderColor"] as? String),
                    colorBorder = parseColor(styleMap["borderColor"] as? String),
                    colorError = parseColor(styleMap["errorColor"] as? String),
                    colorSuccess = parseColor(styleMap["successColor"] as? String),
                )
                val borderFormRadius = (styleMap["borderFormRadius"] as? Number)?.toInt()
                val borderButtonRadius = (styleMap["borderButtonRadius"] as? Number)?.toInt()
                DesignTokens(
                    colorTokens,
                    emptyMap(),
                    if (borderFormRadius != null) BorderRadius(borderFormRadius) else BorderRadius(),
                    if (borderButtonRadius != null) BorderRadius(borderButtonRadius) else BorderRadius(),
                )
            } else null

            val config = CheckoutComponentConfiguration(
                context = context,
                publicKey = publicKey,
                environment = environment,
                locale = ckoLocale,
                appearance = appearance,
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
                    Log.d(TAG, "Creating CheckoutComponentsFactory...")
                    val checkoutComponents = CheckoutComponentsFactory(config).create()
                    Log.d(TAG, "Factory created, creating Flow component...")
                    val flow = checkoutComponents.create(ComponentName.Flow)
                    Log.d(TAG, "Flow component created, providing view...")

                    val renderedView = flow.provideView(containerView)
                    Log.d(TAG, "View provided, renderedView=$renderedView, container children: ${containerView.childCount}")

                    if (containerView.childCount == 0 && renderedView != null && renderedView !== containerView) {
                        containerView.addView(renderedView, ViewGroup.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT
                        ))
                        Log.d(TAG, "Manually added renderedView to container")
                    }
                    invokeOnMain("onReady", null)
                } catch (e: Exception) {
                    Log.e(TAG, "Error initializing checkout: ${e.message}", e)
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

    /**
     * Parse hex color string (#RRGGBB or #AARRGGBB) to Compose Color Long.
     * Falls back to 0 (transparent) if null/invalid.
     */
    private fun parseColor(hex: String?): Long {
        if (hex == null) return 0xFF000000L // default black
        return try {
            val clean = hex.removePrefix("#")
            val argb = when (clean.length) {
                6 -> "FF$clean"
                8 -> clean
                else -> "FF000000"
            }
            java.lang.Long.parseUnsignedLong(argb, 16)
        } catch (e: Exception) {
            0xFF000000L
        }
    }

    override fun getView(): View = containerView

    override fun dispose() {}
}
